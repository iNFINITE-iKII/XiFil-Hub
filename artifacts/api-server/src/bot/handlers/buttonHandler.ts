import {
  ButtonInteraction,
  EmbedBuilder,
  GuildMember,
  ModalBuilder,
  TextInputBuilder,
  TextInputStyle,
  ActionRowBuilder,
  ModalSubmitInteraction,
} from "discord.js";
import { randomUUID } from "crypto";
import {
  getWhitelistUser,
  getUserKeys,
  getByKey,
  setVipRoleAssigned,
  getLastHwidReset,
  logHwidReset,
  resetHwidAndIncrementCount,
} from "../database.js";
import { statusEmoji, durationLabel } from "../utils.js";
import { logger } from "../../lib/logger.js";

const LUA_SCRIPT = `loadstring(game:HttpGet("https://xifil-hub-production.up.railway.app/api/lua/loader?game=soul_iron"))()`;

const PERIOD_MS: Record<string, number> = {
  DAILY: 24 * 60 * 60 * 1000,
  WEEKLY: 7 * 24 * 60 * 60 * 1000,
  MONTHLY: 30 * 24 * 60 * 60 * 1000,
  UNLIMITED: 0,
};

const PERIOD_LABEL: Record<string, string> = {
  DAILY: "Per Hari",
  WEEKLY: "Per Minggu",
  MONTHLY: "Per Bulan",
  UNLIMITED: "Tanpa Cooldown",
};

export async function handleButton(interaction: ButtonInteraction): Promise<void> {
  const { customId } = interaction;

  if (customId === "get_role_vip") {
    await handleGetRoleVip(interaction);
  } else if (customId === "get_key") {
    await handleGetKey(interaction);
  } else if (customId === "reset_hwid") {
    await handleResetHwidButton(interaction);
  } else if (customId === "get_script") {
    await handleGetScript(interaction);
  }
}

// ─── Whitelist Check Helper ────────────────────────────────────────────────

async function requireWhitelist(interaction: ButtonInteraction): Promise<boolean> {
  const entry = await getWhitelistUser(interaction.user.id);
  if (!entry) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Tidak Terdaftar di Whitelist")
          .setDescription(
            "Fitur ini memerlukan whitelist VIP.\nHubungi admin untuk mendaftarkan akun kamu."
          )
          .setTimestamp(),
      ],
    });
    return false;
  }
  return true;
}

// ─── Get Role VIP ─────────────────────────────────────────────────────────

async function handleGetRoleVip(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  if (!(await requireWhitelist(interaction))) return;

  const entry = await getWhitelistUser(interaction.user.id);

  const guild = interaction.guild;
  if (!guild) {
    await interaction.editReply({ content: "Perintah ini hanya bisa digunakan di server." });
    return;
  }

  const vipRoleName = process.env["VIP_ROLE_NAME"] ?? "VIP";
  const vipRole = guild.roles.cache.find((r) => r.name === vipRoleName);

  if (!vipRole) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Role Tidak Ditemukan")
          .setDescription(
            `Role **${vipRoleName}** tidak ada di server.\nMinta admin buat role dengan nama itu.`
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  const member = interaction.member as GuildMember;

  if (member.roles.cache.has(vipRole.id)) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("⚠️ Sudah Punya Role VIP")
          .setDescription(`Kamu sudah memiliki role **${vipRoleName}**!`)
          .setTimestamp(),
      ],
    });
    return;
  }

  try {
    await member.roles.add(vipRole, "Whitelist VIP claim via panel");
    await setVipRoleAssigned(interaction.user.id);

    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x00c853)
          .setTitle("🎖️ Role VIP Berhasil Diklaim!")
          .setDescription(
            `Selamat <@${interaction.user.id}>! Kamu mendapatkan role **${vipRoleName}**.\n\nGunakan tombol **Get Key** untuk mengambil license key kamu.`
          )
          .addFields({ name: "Jumlah Key", value: `${entry!.key_count} key`, inline: true })
          .setFooter({ text: "License Manager" })
          .setTimestamp(),
      ],
    });
  } catch (err) {
    logger.error({ err }, "Failed to assign VIP role");
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Gagal Memberikan Role")
          .setDescription(
            "Bot tidak bisa memberikan role.\nPastikan posisi role bot berada **di atas** role VIP di pengaturan server."
          )
          .setTimestamp(),
      ],
    });
  }
}

// ─── Get Key ──────────────────────────────────────────────────────────────

async function handleGetKey(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  if (!(await requireWhitelist(interaction))) return;

  const userKeys = await getUserKeys(interaction.user.id);

  if (userKeys.length === 0) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("🔑 Tidak Ada Key")
          .setDescription("Kamu belum memiliki key yang terdaftar.\nHubungi admin.")
          .setTimestamp(),
      ],
    });
    return;
  }

  const fields: { name: string; value: string; inline: boolean }[] = [];
  for (const uk of userKeys.slice(0, 10)) {
    const license = await getByKey(uk.license_key);
    if (!license) continue;

    let expiryText = "Permanent ♾️";
    if (license.duration_type !== "PERMANENT" && license.expires_at) {
      const now = Date.now();
      expiryText = now > license.expires_at ? "❌ Expired" : `<t:${Math.floor(license.expires_at / 1000)}:R>`;
    } else if (license.status === "UNUSED") {
      expiryText = "⏳ Belum diaktifkan";
    }

    fields.push({
      name: `${statusEmoji(license.status)} \`${uk.license_key}\``,
      value: `**Status:** ${license.status} • **Tipe:** ${durationLabel(license.duration_type, license.duration_value)}\n**Expired:** ${expiryText}`,
      inline: false,
    });
  }

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle(`🔑 Key Kamu (${userKeys.length} key)`)
        .setDescription("Berikut license key yang terdaftar untuk akun kamu:")
        .addFields(fields)
        .setFooter({ text: "License Manager • Jaga kerahasiaan key kamu!" })
        .setTimestamp(),
    ],
  });
}

// ─── Reset HWID (Modal trigger) ───────────────────────────────────────────

async function handleResetHwidButton(interaction: ButtonInteraction): Promise<void> {
  const modal = new ModalBuilder()
    .setCustomId("reset_hwid_modal")
    .setTitle("🔄 Reset HWID");

  const keyInput = new TextInputBuilder()
    .setCustomId("hwid_key_input")
    .setLabel("Masukkan License Key kamu")
    .setStyle(TextInputStyle.Short)
    .setRequired(true)
    .setPlaceholder("XXXX-XXXX-XXXX-XXXX")
    .setMinLength(19)
    .setMaxLength(19);

  const row = new ActionRowBuilder<TextInputBuilder>().addComponents(keyInput);
  modal.addComponents(row);

  await interaction.showModal(modal);
}

// ─── Reset HWID Modal Submit ──────────────────────────────────────────────

export async function handleResetHwidModal(interaction: ModalSubmitInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const entry = await getWhitelistUser(interaction.user.id);
  if (!entry) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Tidak Terdaftar di Whitelist")
          .setDescription("Fitur ini memerlukan whitelist VIP.\nHubungi admin.")
          .setTimestamp(),
      ],
    });
    return;
  }

  const key = interaction.fields.getTextInputValue("hwid_key_input").trim().toUpperCase();
  const license = await getByKey(key);

  if (!license) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Key Tidak Ditemukan")
          .setDescription("License key tidak ada di database.")
          .setTimestamp(),
      ],
    });
    return;
  }

  if (license.status === "REVOKED") {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Key Dicabut")
          .setDescription("Key ini sudah dicabut oleh admin.")
          .setTimestamp(),
      ],
    });
    return;
  }

  if (!license.hwid_hash) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("⚠️ Tidak Ada HWID")
          .setDescription("Key ini belum terikat ke perangkat manapun.")
          .setTimestamp(),
      ],
    });
    return;
  }

  const userKeys = await getUserKeys(interaction.user.id);
  const ownsKey = userKeys.some((uk) => uk.license_key === key);

  if (!ownsKey) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Bukan Key Milikmu")
          .setDescription("Kamu hanya bisa reset HWID untuk key yang kamu miliki sendiri.")
          .setTimestamp(),
      ],
    });
    return;
  }

  if (license.max_hwid_resets !== -1 && license.hwid_reset_count >= license.max_hwid_resets) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Batas Reset Tercapai")
          .setDescription(
            `Key ini sudah mencapai batas maksimal **${license.max_hwid_resets}x** reset HWID.\nHubungi admin untuk bantuan.`
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  const period = license.hwid_reset_period ?? "WEEKLY";
  const periodMs = PERIOD_MS[period] ?? PERIOD_MS["WEEKLY"]!;

  if (periodMs > 0) {
    const lastReset = await getLastHwidReset(interaction.user.id, key);
    const now = Date.now();

    if (lastReset) {
      const nextResetTime = lastReset.reset_at + periodMs;
      if (now < nextResetTime) {
        await interaction.editReply({
          embeds: [
            new EmbedBuilder()
              .setColor(0xff6d00)
              .setTitle("⏳ Cooldown Aktif")
              .setDescription(
                `Kamu bisa reset HWID lagi pada <t:${Math.floor(nextResetTime / 1000)}:F> (<t:${Math.floor(nextResetTime / 1000)}:R>).\n\n**Periode:** ${PERIOD_LABEL[period] ?? period}`
              )
              .setTimestamp(),
          ],
        });
        return;
      }
    }
  }

  const now = Date.now();
  await resetHwidAndIncrementCount(key);
  await logHwidReset({
    id: randomUUID(),
    discordUserId: interaction.user.id,
    licenseKey: key,
    resetAt: now,
  });

  const resetsDone = license.hwid_reset_count + 1;
  const maxLabel = license.max_hwid_resets === -1 ? "∞" : String(license.max_hwid_resets);

  let nextResetText = "Kapan saja (tanpa cooldown)";
  if (periodMs > 0) {
    nextResetText = `<t:${Math.floor((now + periodMs) / 1000)}:R>`;
  }

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ HWID Berhasil Direset")
        .setDescription("Key kamu bisa diaktifkan di perangkat baru sekarang.")
        .addFields(
          { name: "Key", value: `\`${key}\``, inline: false },
          { name: "Total Reset", value: `${resetsDone}/${maxLabel}`, inline: true },
          { name: "Reset Berikutnya", value: nextResetText, inline: true }
        )
        .setFooter({ text: `License Manager • Periode: ${PERIOD_LABEL[period] ?? period}` })
        .setTimestamp(),
    ],
  });
}

// ─── Get Script ───────────────────────────────────────────────────────────

async function handleGetScript(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x5865f2)
        .setTitle("📜 Script Roblox")
        .setDescription("Salin script di bawah ini dan jalankan di executor Roblox kamu:")
        .addFields({
          name: "Script",
          value: `\`\`\`lua\n${LUA_SCRIPT}\n\`\`\``,
          inline: false,
        })
        .setFooter({ text: "License Manager • Jangan bagikan script ini ke orang lain!" })
        .setTimestamp(),
    ],
  });
}

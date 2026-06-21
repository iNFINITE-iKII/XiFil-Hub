import { ButtonInteraction, EmbedBuilder, GuildMember } from "discord.js";
import { getWhitelistUser, getUserKeys, getByKey, setVipRoleAssigned } from "../database.js";
import { censorKey, statusEmoji, durationLabel } from "../utils.js";
import { logger } from "../../lib/logger.js";

const LUA_SCRIPT = `loadstring(game:HttpGet("https://xifil-hub-production.up.railway.app/api/lua/loader?game=soul_iron"))()`;

export async function handleButton(interaction: ButtonInteraction): Promise<void> {
  const { customId } = interaction;

  if (customId === "get_role_vip") {
    await handleGetRoleVip(interaction);
  } else if (customId === "get_key") {
    await handleGetKey(interaction);
  } else if (customId === "get_script") {
    await handleGetScript(interaction);
  }
}

async function handleGetRoleVip(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const entry = await getWhitelistUser(interaction.user.id);

  if (!entry) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Tidak Terdaftar")
          .setDescription(
            "Kamu belum terdaftar di whitelist VIP.\nHubungi admin untuk mendaftarkan akun kamu."
          )
          .setTimestamp(),
      ],
    });
    return;
  }

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
            `Role **${vipRoleName}** tidak ada di server ini.\nMinta admin untuk membuat role dengan nama tersebut.`
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  const member = interaction.member as GuildMember;
  const alreadyHasRole = member.roles.cache.has(vipRole.id);

  if (alreadyHasRole) {
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
            `Selamat <@${interaction.user.id}>! Kamu telah mendapatkan role **${vipRoleName}**.\n\nGunakan tombol **Get Key** untuk mengambil license key kamu.`
          )
          .addFields({ name: "Jumlah Key", value: `${entry.key_count} key`, inline: true })
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
            "Bot tidak bisa memberikan role. Pastikan role bot berada **di atas** role VIP di pengaturan server."
          )
          .setTimestamp(),
      ],
    });
  }
}

async function handleGetKey(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const userKeys = await getUserKeys(interaction.user.id);

  if (userKeys.length === 0) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("🔑 Tidak Ada Key")
          .setDescription(
            "Kamu belum memiliki key yang terdaftar.\nHubungi admin untuk mendapatkan key."
          )
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
      if (now > license.expires_at) {
        expiryText = "❌ Expired";
      } else {
        expiryText = `<t:${Math.floor(license.expires_at / 1000)}:R>`;
      }
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
        .setDescription("Berikut adalah license key yang terdaftar untuk akunmu:")
        .addFields(fields)
        .setFooter({ text: "License Manager • Jaga kerahasiaan key kamu!" })
        .setTimestamp(),
    ],
  });
}

async function handleGetScript(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const vipRoleName = process.env["VIP_ROLE_NAME"] ?? "VIP";
  const member = interaction.member as GuildMember;
  const isVip = member?.roles?.cache?.some((r) => r.name === vipRoleName) ?? false;

  if (!isVip) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Akses Ditolak")
          .setDescription(
            `Script hanya bisa diakses oleh member dengan role **${vipRoleName}**.\n\nKlaim role VIP terlebih dahulu melalui tombol **Get Role VIP**.`
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x5865f2)
        .setTitle("📜 Script VIP")
        .setDescription(
          "Salin script di bawah ini dan jalankan di executor Roblox kamu:"
        )
        .addFields({
          name: "Script",
          value: `\`\`\`lua\n${LUA_SCRIPT}\n\`\`\``,
          inline: false,
        })
        .setFooter({ text: "License Manager • Jangan bagikan script ini!" })
        .setTimestamp(),
    ],
  });
}

import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
  GuildMember,
} from "discord.js";
import { randomUUID } from "crypto";
import {
  getByKey,
  resetHwid,
  resetHwidAndIncrementCount,
  getUserKeys,
  getLastHwidReset,
  logHwidReset,
} from "../database.js";
import { censorKey } from "../utils.js";

const SEVEN_DAYS_MS = 7 * 24 * 60 * 60 * 1000;

export const data = new SlashCommandBuilder()
  .setName("resethwid")
  .setDescription("Reset HWID binding — allows key to activate on a new device")
  .addStringOption((opt) =>
    opt.setName("key").setDescription("The license key").setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const key = (interaction.options.get("key")?.value as string).trim().toUpperCase();
  const isAdmin = interaction.memberPermissions?.has(PermissionFlagsBits.Administrator) ?? false;
  const vipRoleName = process.env["VIP_ROLE_NAME"] ?? "VIP";
  const member = interaction.member as GuildMember;
  const isVip = member?.roles?.cache?.some((r) => r.name === vipRoleName) ?? false;

  if (!isAdmin && !isVip) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Akses Ditolak")
          .setDescription("Kamu butuh role **Administrator** atau **VIP** untuk menggunakan perintah ini.")
          .setTimestamp(),
      ],
    });
    return;
  }

  const license = await getByKey(key);

  if (!license) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Key Tidak Ditemukan")
          .setDescription("License key ini tidak ada di database.")
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
          .setTitle("❌ Key Sudah Dicabut")
          .setDescription("Tidak bisa memodifikasi key yang sudah dicabut.")
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

  if (isAdmin) {
    await resetHwid(key);
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x00c853)
          .setTitle("✅ HWID Direset (Admin)")
          .setDescription(
            `HWID binding dihapus dari \`${censorKey(key)}\`. Aktivasi berikutnya akan mengikat ke perangkat baru.`
          )
          .addFields({ name: "Admin", value: `<@${interaction.user.id}>`, inline: true })
          .setFooter({ text: "License Manager" })
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
          .setDescription("Kamu hanya bisa reset HWID untuk key yang dimiliki sendiri.")
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
            `Key ini hanya boleh direset HWID maksimal **${license.max_hwid_resets}x** dan sudah habis.\nHubungi admin untuk bantuan.`
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  const lastReset = await getLastHwidReset(interaction.user.id, key);
  const now = Date.now();

  if (lastReset) {
    const nextResetTime = lastReset.reset_at + SEVEN_DAYS_MS;
    if (now < nextResetTime) {
      await interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0xff6d00)
            .setTitle("⏳ Cooldown Aktif")
            .setDescription(
              `Kamu bisa reset HWID lagi pada <t:${Math.floor(nextResetTime / 1000)}:F> (<t:${Math.floor(nextResetTime / 1000)}:R>).\n\nVIP hanya bisa reset **1x per 7 hari**.`
            )
            .setTimestamp(),
        ],
      });
      return;
    }
  }

  await resetHwidAndIncrementCount(key);
  await logHwidReset({
    id: randomUUID(),
    discordUserId: interaction.user.id,
    licenseKey: key,
    resetAt: now,
  });

  const resetsDone = license.hwid_reset_count + 1;
  const maxLabel = license.max_hwid_resets === -1 ? "Unlimited" : `${resetsDone}/${license.max_hwid_resets}`;

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ HWID Berhasil Direset")
        .setDescription(
          `HWID binding dihapus dari \`${censorKey(key)}\`. Key kamu bisa diaktifkan di perangkat baru.`
        )
        .addFields(
          { name: "Total Reset", value: maxLabel, inline: true },
          { name: "Reset Berikutnya", value: `<t:${Math.floor((now + SEVEN_DAYS_MS) / 1000)}:R>`, inline: true }
        )
        .setFooter({ text: "License Manager • VIP: 1x reset per 7 hari" })
        .setTimestamp(),
    ],
  });
}

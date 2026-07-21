import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getUserKeys, getByKey, getKeyOwner } from "../database.js";
import { statusEmoji, durationLabel } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("userkey")
  .setDescription("Cek key milik user atau cek pemilik sebuah key — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addUserOption((opt) =>
    opt.setName("user").setDescription("Lihat semua key milik user ini").setRequired(false)
  )
  .addStringOption((opt) =>
    opt.setName("key").setDescription("Cek siapa pemilik key ini").setRequired(false)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const targetUser = interaction.options.getUser("user");
  const targetKey = interaction.options.get("key")?.value as string | undefined;

  if (!targetUser && !targetKey) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("⚠️ Parameter Diperlukan")
          .setDescription("Masukkan `user` atau `key` untuk dicari.")
          .setTimestamp(),
      ],
    });
    return;
  }

  // ─── By User ──────────────────────────────────────────────────────────────
  if (targetUser) {
    const userKeys = await getUserKeys(targetUser.id);

    if (userKeys.length === 0) {
      await interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0x2196f3)
            .setTitle("🔑 Key User")
            .setDescription(`<@${targetUser.id}> tidak memiliki key yang terdaftar.`)
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
      if (license.expires_at) {
        expiryText = `<t:${Math.floor(license.expires_at / 1000)}:R>`;
      } else if (license.status === "UNUSED") {
        expiryText = "⏳ Belum diaktifkan";
      }

      fields.push({
        name: `${statusEmoji(license.status)} \`${uk.license_key}\``,
        value: `**Status:** ${license.status} • **Tipe:** ${durationLabel(license.duration_type, license.duration_value)}\n**Expired:** ${expiryText} • **HWID Reset:** ${license.hwid_reset_count}/${license.max_hwid_resets === -1 ? "∞" : license.max_hwid_resets}`,
        inline: false,
      });
    }

    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x2196f3)
          .setTitle(`🔑 Keys milik ${targetUser.username} (${userKeys.length} key)`)
          .setDescription(`<@${targetUser.id}>`)
          .addFields(fields)
          .setFooter({ text: `License Manager • Key ditampilkan penuh (Admin view)` })
          .setTimestamp(),
      ],
    });
    return;
  }

  // ─── By Key ───────────────────────────────────────────────────────────────
  if (targetKey) {
    const key = targetKey.trim().toUpperCase();
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

    const owner = await getKeyOwner(key);

    const periodLabel: Record<string, string> = {
      DAILY: "Per Hari",
      WEEKLY: "Per Minggu",
      MONTHLY: "Per Bulan",
      UNLIMITED: "Tanpa Cooldown",
    };

    let expiryText = "Permanent ♾️";
    if (license.duration_type !== "PERMANENT" && license.expires_at) {
      expiryText = `<t:${Math.floor(license.expires_at / 1000)}:F> (<t:${Math.floor(license.expires_at / 1000)}:R>)`;
    } else if (license.status === "UNUSED") {
      expiryText = "⏳ Belum diaktifkan";
    }

    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x2196f3)
          .setTitle("🔍 Info Key (Admin View)")
          .addFields(
            { name: "Key (Full)", value: `\`${key}\``, inline: false },
            { name: "Status", value: `${statusEmoji(license.status)} ${license.status}`, inline: true },
            { name: "Tipe", value: durationLabel(license.duration_type, license.duration_value), inline: true },
            { name: "Pemilik", value: owner ? `<@${owner.discord_user_id}>` : "❌ Tidak ada pemilik", inline: true },
            { name: "Dibuat oleh", value: `<@${license.issuer_discord_id}>`, inline: true },
            { name: "Max Reset HWID", value: `${license.hwid_reset_count}/${license.max_hwid_resets === -1 ? "∞" : license.max_hwid_resets} • ${periodLabel[license.hwid_reset_period] ?? license.hwid_reset_period}`, inline: true },
            { name: "Expired", value: expiryText, inline: false }
          )
          .setFooter({ text: "License Manager • Admin View" })
          .setTimestamp(),
      ],
    });
  }
}

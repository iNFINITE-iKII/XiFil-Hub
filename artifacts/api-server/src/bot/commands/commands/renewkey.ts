import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getByKey, renewLicense } from "../database.js";
import { getDurationMs, censorKey, durationLabel } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("renewkey")
  .setDescription("Perpanjang atau ubah durasi sebuah key (termasuk yang expired) — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt.setName("key").setDescription("License key yang akan diperpanjang").setRequired(true)
  )
  .addStringOption((opt) =>
    opt
      .setName("type")
      .setDescription("Tipe durasi baru")
      .setRequired(true)
      .addChoices(
        { name: "Permanent (Selamanya)", value: "PERMANENT" },
        { name: "Per Jam", value: "HOURLY" },
        { name: "Per Hari", value: "DAILY" },
        { name: "Per Minggu", value: "WEEKLY" }
      )
  )
  .addIntegerOption((opt) =>
    opt
      .setName("duration")
      .setDescription("Nilai durasi (contoh: 7 untuk 7 hari). Abaikan untuk PERMANENT.")
      .setRequired(false)
      .setMinValue(1)
      .setMaxValue(9999)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const key = (interaction.options.getString("key", true)).trim().toUpperCase();
  const type = interaction.options.getString("type", true);
  const duration = interaction.options.getInteger("duration") ?? 1;

  if (type !== "PERMANENT" && !interaction.options.getInteger("duration")) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Parameter Kurang")
          .setDescription("Masukkan `duration` untuk tipe non-PERMANENT.")
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
          .setTitle("❌ Key Sudah Direvoke")
          .setDescription("Tidak bisa memperpanjang key yang sudah direvoke.")
          .setTimestamp(),
      ],
    });
    return;
  }

  const now = Date.now();
  const durationMs = type === "PERMANENT" ? null : getDurationMs(type, duration);
  const newExpiresAt = durationMs !== null ? now + durationMs : null;
  const newStatus =
    license.status === "UNUSED" ? "UNUSED" : type === "PERMANENT" ? "ACTIVE" : "ACTIVE";

  await renewLicense(key, type, duration, newExpiresAt, newStatus);

  const oldLabel = durationLabel(license.duration_type, license.duration_value);
  const newLabel = durationLabel(type, duration);

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ Key Diperpanjang")
        .setDescription(`License \`${censorKey(key)}\` berhasil diperbarui.`)
        .addFields(
          { name: "Sebelumnya", value: oldLabel, inline: true },
          { name: "Sekarang", value: newLabel, inline: true },
          {
            name: "Expired Baru",
            value: newExpiresAt
              ? `<t:${Math.floor(newExpiresAt / 1000)}:F>`
              : "Permanent ♾️",
            inline: false,
          },
          { name: "Oleh Admin", value: `<@${interaction.user.id}>`, inline: true }
        )
        .setTimestamp(),
    ],
  });
}

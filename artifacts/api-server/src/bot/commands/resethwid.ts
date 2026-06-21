import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getByKey, resetHwid } from "../database.js";
import { censorKey } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("resethwid")
  .setDescription("Reset HWID binding untuk sebuah key — Admin only. User pakai tombol di /panel")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt.setName("key").setDescription("The license key").setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const key = (interaction.options.get("key")?.value as string).trim().toUpperCase();
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
}

import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { cleanupOldKeys } from "../database.js";

export const data = new SlashCommandBuilder()
  .setName("cleanup")
  .setDescription("Hapus key expired/revoked yang sudah lama dari database — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addIntegerOption((opt) =>
    opt
      .setName("days")
      .setDescription("Hapus key yang sudah lebih dari X hari (default: 30 hari)")
      .setRequired(false)
      .setMinValue(1)
      .setMaxValue(365)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const days = interaction.options.getInteger("days") ?? 30;
  const cutoffMs = Date.now() - days * 24 * 60 * 60 * 1000;

  const deletedCount = await cleanupOldKeys(cutoffMs);

  if (deletedCount === 0) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("🧹 Tidak Ada yang Dihapus")
          .setDescription(
            `Tidak ada key EXPIRED atau REVOKED yang lebih dari **${days} hari** yang ditemukan.`
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("🧹 Cleanup Selesai")
        .setDescription(`**${deletedCount}** key EXPIRED/REVOKED yang lebih dari **${days} hari** telah dihapus dari database.`)
        .addFields({
          name: "Oleh Admin",
          value: `<@${interaction.user.id}>`,
          inline: true,
        })
        .setTimestamp(),
    ],
  });
}

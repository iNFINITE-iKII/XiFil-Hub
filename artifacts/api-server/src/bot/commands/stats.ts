import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getLicenseStats, getAllWhitelist } from "../database.js";

export const data = new SlashCommandBuilder()
  .setName("stats")
  .setDescription("Lihat statistik global semua key dan whitelist — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator);

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const stats = await getLicenseStats();
  const whitelist = await getAllWhitelist();
  const vipCount = whitelist.filter((w) => w.vip_role_assigned).length;

  const embed = new EmbedBuilder()
    .setColor(0x5865f2)
    .setTitle("📊 Statistik XiFil Hub")
    .addFields(
      {
        name: "🔑 License Keys",
        value: [
          `🟢 **Active:** ${stats.active}`,
          `🔵 **Unused:** ${stats.unused}`,
          `🟠 **Expired:** ${stats.expired}`,
          `🔴 **Revoked:** ${stats.revoked}`,
          `📦 **Total:** ${stats.total}`,
        ].join("\n"),
        inline: true,
      },
      {
        name: "🎖️ Whitelist VIP",
        value: [
          `👥 **Total Member:** ${whitelist.length}`,
          `✅ **Sudah Klaim VIP:** ${vipCount}`,
          `⏳ **Belum Klaim:** ${whitelist.length - vipCount}`,
        ].join("\n"),
        inline: true,
      }
    )
    .setFooter({ text: "License Manager • XiFil Hub" })
    .setTimestamp();

  await interaction.editReply({ embeds: [embed] });
}

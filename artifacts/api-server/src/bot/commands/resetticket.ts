import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getPendingTicket, removePendingTicket } from "../database.js";
import { safeDefer } from "../utils/safeDefer.js";

export const data = new SlashCommandBuilder()
  .setName("resetticket")
  .setDescription("Reset status tiket user yang tersangkut — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addUserOption((opt) =>
    opt.setName("user").setDescription("User yang tiketnya ingin di-reset").setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  if (!await safeDefer(interaction)) return;

  const target = interaction.options.getUser("user", true);
  const pending = await getPendingTicket(target.id).catch(() => null);

  if (!pending) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff9800)
          .setTitle("ℹ️ Tidak Ada Tiket Tersangkut")
          .setDescription(`<@${target.id}> tidak memiliki pending ticket yang tersangkut.`)
          .setTimestamp(),
      ],
    });
    return;
  }

  await removePendingTicket(target.id);

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x43a047)
        .setTitle("✅ Tiket Berhasil Di-reset")
        .setDescription(`Pending ticket milik <@${target.id}> telah dihapus.`)
        .addFields(
          { name: "👤 User", value: `<@${target.id}> (\`${target.username}\`)`, inline: true },
          { name: "📌 Channel ID lama", value: `\`${pending.channel_id}\``, inline: true },
          { name: "🕐 Dibuat", value: `<t:${Math.floor(Number(pending.created_at) / 1000)}:F>`, inline: false },
          { name: "🔧 Di-reset oleh", value: `<@${interaction.user.id}>`, inline: true },
        )
        .setFooter({ text: "User sekarang bisa membuat tiket baru" })
        .setTimestamp(),
    ],
  });
}

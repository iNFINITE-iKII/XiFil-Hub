import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  TextChannel,
} from "discord.js";
import { buildPanelEmbed, buildPanelRows } from "../utils/panelBuilder.js";

export const data = new SlashCommandBuilder()
  .setName("panel")
  .setDescription("Kirim panel ke channel ini — Admin only")
  .setDefaultMemberPermissions(0);

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const rows = buildPanelRows();
  await (interaction.channel as TextChannel).send({ embeds: [buildPanelEmbed()], components: rows });

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ Panel Dikirim")
        .setDescription("Panel telah dikirim ke channel ini.")
        .setTimestamp(),
    ],
  });
}

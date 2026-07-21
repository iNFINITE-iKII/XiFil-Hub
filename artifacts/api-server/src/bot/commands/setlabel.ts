import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getByKey, setKeyLabel } from "../database.js";
import { censorKey } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("setlabel")
  .setDescription("Tambahkan catatan/label ke sebuah key — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt.setName("key").setDescription("License key yang akan diberi label").setRequired(true)
  )
  .addStringOption((opt) =>
    opt
      .setName("label")
      .setDescription("Catatan untuk key ini (kosongkan untuk hapus label)")
      .setRequired(false)
      .setMaxLength(100)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const key = (interaction.options.getString("key", true)).trim().toUpperCase();
  const label = interaction.options.getString("label") ?? null;

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

  await setKeyLabel(key, label);

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle(label ? "🏷️ Label Diset" : "🏷️ Label Dihapus")
        .addFields(
          { name: "Key", value: `\`${censorKey(key)}\``, inline: true },
          { name: "Label", value: label ? `\`${label}\`` : "*Dihapus*", inline: true }
        )
        .setTimestamp(),
    ],
  });
}

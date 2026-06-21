import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getByKey, setMaxHwidResets } from "../database.js";
import { censorKey } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("setmaxhwid")
  .setDescription("Set batas maksimal reset HWID untuk sebuah key (Admin only)")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt.setName("key").setDescription("License key yang akan diubah").setRequired(true)
  )
  .addIntegerOption((opt) =>
    opt
      .setName("max")
      .setDescription("Jumlah maksimal reset (-1 = unlimited)")
      .setRequired(true)
      .setMinValue(-1)
      .setMaxValue(999)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const key = (interaction.options.get("key")?.value as string).trim().toUpperCase();
  const max = interaction.options.get("max")?.value as number;

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

  await setMaxHwidResets(key, max);

  const maxLabel = max === -1 ? "**Unlimited** (tidak ada batas)" : `**${max}x**`;

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ Max HWID Reset Diset")
        .setDescription(`Batas reset HWID untuk key \`${censorKey(key)}\` telah diubah.`)
        .addFields(
          { name: "Batas Reset", value: maxLabel, inline: true },
          { name: "Reset Sudah Dilakukan", value: `${license.hwid_reset_count}x`, inline: true },
          { name: "Admin", value: `<@${interaction.user.id}>`, inline: true }
        )
        .setFooter({ text: "License Manager" })
        .setTimestamp(),
    ],
  });
}

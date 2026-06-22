import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getByKey, getKeyOwner, deleteLicense } from "../database.js";
import { durationLabel, statusEmoji } from "../utils.js";

export const data = new SlashCommandBuilder()
  .setName("deletekey")
  .setDescription("Hapus license key dari database sepenuhnya — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt.setName("key").setDescription("License key yang akan dihapus").setRequired(true)
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

  const owner = await getKeyOwner(key);

  await deleteLicense(key);

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0xd50000)
        .setTitle("🗑️ Key Dihapus Permanen")
        .setDescription(`License key \`${key}\` telah **dihapus sepenuhnya** dari database.`)
        .addFields(
          { name: "Key", value: `\`${key}\``, inline: false },
          { name: "Tipe", value: durationLabel(license.duration_type, license.duration_value), inline: true },
          { name: "Status Sebelumnya", value: `${statusEmoji(license.status)} ${license.status}`, inline: true },
          { name: "Pemilik", value: owner ? `<@${owner.discord_user_id}>` : "Tidak ada", inline: true },
          { name: "Dihapus oleh", value: `<@${interaction.user.id}>`, inline: true }
        )
        .setFooter({ text: "License Manager • Aksi ini tidak dapat dibatalkan" })
        .setTimestamp(),
    ],
  });
}

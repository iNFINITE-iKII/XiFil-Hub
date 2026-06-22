import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";
import { getByKey, getKeyOwner, transferKey } from "../database.js";

export const data = new SlashCommandBuilder()
  .setName("transferkey")
  .setDescription("Pindahkan kepemilikan key ke user lain — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addStringOption((opt) =>
    opt.setName("key").setDescription("License key yang akan dipindah").setRequired(true)
  )
  .addUserOption((opt) =>
    opt.setName("to").setDescription("User penerima key").setRequired(true)
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const key = (interaction.options.getString("key", true)).trim().toUpperCase();
  const toUser = interaction.options.getUser("to", true);

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

  const currentOwner = await getKeyOwner(key);
  await transferKey(key, toUser.id);

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ Key Berhasil Dipindahkan")
        .addFields(
          { name: "Key", value: `\`${key}\``, inline: false },
          {
            name: "Pemilik Lama",
            value: currentOwner ? `<@${currentOwner.discord_user_id}>` : "Tidak ada",
            inline: true,
          },
          { name: "Pemilik Baru", value: `<@${toUser.id}>`, inline: true },
          { name: "Oleh Admin", value: `<@${interaction.user.id}>`, inline: true }
        )
        .setTimestamp(),
    ],
  });
}

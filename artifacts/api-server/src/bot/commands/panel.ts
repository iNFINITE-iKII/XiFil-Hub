import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
  PermissionFlagsBits,
} from "discord.js";

export const data = new SlashCommandBuilder()
  .setName("panel")
  .setDescription("Kirim panel VIP dengan tombol interaktif ke channel ini (Admin only)")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator);

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const embed = new EmbedBuilder()
    .setColor(0x5865f2)
    .setTitle("🌟 Panel VIP — License Manager")
    .setDescription(
      "Selamat datang! Kamu bisa menggunakan tombol di bawah untuk:\n\n" +
      "🎖️ **Get Role VIP** — Klaim role VIP jika kamu sudah terdaftar di whitelist\n" +
      "🔑 **Get Key** — Ambil license key milikmu\n" +
      "📜 **Get Script** — Dapatkan script (khusus VIP)"
    )
    .setFooter({ text: "License Manager • Semua aksi bersifat privat" })
    .setTimestamp();

  const row = new ActionRowBuilder<ButtonBuilder>().addComponents(
    new ButtonBuilder()
      .setCustomId("get_role_vip")
      .setLabel("Get Role VIP")
      .setEmoji("🎖️")
      .setStyle(ButtonStyle.Primary),
    new ButtonBuilder()
      .setCustomId("get_key")
      .setLabel("Get Key")
      .setEmoji("🔑")
      .setStyle(ButtonStyle.Success),
    new ButtonBuilder()
      .setCustomId("get_script")
      .setLabel("Get Script")
      .setEmoji("📜")
      .setStyle(ButtonStyle.Secondary)
  );

  await interaction.channel!.send({ embeds: [embed], components: [row] });

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ Panel Dikirim")
        .setDescription("Panel VIP telah dikirim ke channel ini.")
        .setTimestamp(),
    ],
  });
}

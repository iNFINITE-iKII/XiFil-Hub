import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
} from "discord.js";

export const data = new SlashCommandBuilder()
  .setName("panel")
  .setDescription("Kirim panel VIP ke channel ini — Admin only")
  .setDefaultMemberPermissions(0);

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const embed = new EmbedBuilder()
    .setColor(0x5865f2)
    .setTitle("🌟 Panel VIP — License Manager")
    .setDescription(
      "Gunakan tombol di bawah untuk mengakses fitur member:\n\n" +
      "🎖️ **Get Role VIP** — Klaim role VIP (perlu whitelist)\n" +
      "🔑 **Get Key** — Lihat license key kamu (perlu whitelist)\n" +
      "🔄 **Reset HWID** — Reset HWID key kamu (perlu whitelist)\n" +
      "📜 **Get Script** — Dapatkan script Roblox (semua orang)"
    )
    .setFooter({ text: "License Manager • Semua aksi bersifat privat (hanya kamu yang bisa lihat)" })
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
      .setCustomId("reset_hwid")
      .setLabel("Reset HWID")
      .setEmoji("🔄")
      .setStyle(ButtonStyle.Danger),
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

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
    .setTitle("🌟 Panel VIP — XiFil Hub")
    .setDescription(
      "Gunakan tombol di bawah untuk mengakses fitur member:\n\n" +
      "🎖️ **Get Role VIP** — Klaim role VIP (perlu whitelist)\n" +
      "🔑 **Get Key** — Lihat license key kamu (perlu whitelist)\n" +
      "🔄 **Reset HWID** — Reset HWID key kamu (perlu whitelist)\n" +
      "🔍 **Cek HWID** — Lihat HWID yang terikat ke key kamu\n" +
      "🎟️ **Request Akses** — Minta akses VIP ke admin\n" +
      "📜 **Get Script** — Dapatkan script Roblox (semua orang)"
    )
    .setFooter({ text: "XiFil Hub • License Manager • Semua aksi bersifat privat" })
    .setTimestamp();

  const row1 = new ActionRowBuilder<ButtonBuilder>().addComponents(
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
      .setStyle(ButtonStyle.Danger)
  );

  const row2 = new ActionRowBuilder<ButtonBuilder>().addComponents(
    new ButtonBuilder()
      .setCustomId("cek_hwid")
      .setLabel("Cek HWID")
      .setEmoji("🔍")
      .setStyle(ButtonStyle.Secondary),
    new ButtonBuilder()
      .setCustomId("request_akses_vip")
      .setLabel("Request Akses")
      .setEmoji("🎟️")
      .setStyle(ButtonStyle.Primary),
    new ButtonBuilder()
      .setCustomId("get_script")
      .setLabel("Get Script")
      .setEmoji("📜")
      .setStyle(ButtonStyle.Secondary)
  );

  await interaction.channel!.send({ embeds: [embed], components: [row1, row2] });

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

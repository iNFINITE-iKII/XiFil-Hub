import {
  EmbedBuilder,
  ActionRowBuilder,
  ButtonBuilder,
  ButtonStyle,
} from "discord.js";

export function buildPanelEmbed(): EmbedBuilder {
  return new EmbedBuilder()
    .setColor(0x5865f2)
    .setTitle("🌟 Panel XiFil Hub")
    .setDescription(
      "Gunakan tombol di bawah untuk mengakses fitur:\n\n" +
      "🎁 **Get Trial Key** — Coba gratis selama **6 Jam** (1x per akun, siapa saja)\n" +
      "💎 **Buy PREMIUM** — Buat ticket untuk beli akses **Permanent/Lifetime**\n\n" +
      "─────────────── Member Only ───────────────\n" +
      "🎖️ **Get Role VIP** — Klaim role **PREMIUM** (perlu key Lifetime/Permanent aktif)\n" +
      "🔑 **Get Key** — Lihat license key kamu\n" +
      "🔄 **Reset HWID** — Reset HWID key kamu\n" +
      "🔍 **Cek HWID** — Lihat status HWID key kamu\n" +
      "📜 **Get Script** — Dapatkan script Roblox"
    )
    .setFooter({ text: "XiFil Hub • License Manager • Semua aksi bersifat privat" })
    .setTimestamp();
}

export function buildPanelRows(): ActionRowBuilder<ButtonBuilder>[] {
  const row1 = new ActionRowBuilder<ButtonBuilder>().addComponents(
    new ButtonBuilder()
      .setCustomId("get_trial_key")
      .setLabel("Get Trial Key")
      .setEmoji("🎁")
      .setStyle(ButtonStyle.Success),
    new ButtonBuilder()
      .setCustomId("buy_premium")
      .setLabel("Buy PREMIUM")
      .setEmoji("💎")
      .setStyle(ButtonStyle.Primary),
    new ButtonBuilder()
      .setCustomId("get_script")
      .setLabel("Get Script")
      .setEmoji("📜")
      .setStyle(ButtonStyle.Secondary)
  );

  const row2 = new ActionRowBuilder<ButtonBuilder>().addComponents(
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
      .setCustomId("cek_hwid")
      .setLabel("Cek HWID")
      .setEmoji("🔍")
      .setStyle(ButtonStyle.Secondary)
  );

  return [row1, row2];
}

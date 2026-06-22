import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
} from "discord.js";

const COMMANDS = [
  {
    category: "🔑 Manajemen Key",
    items: [
      {
        cmd: "/genkey",
        usage: "`[type] [duration] [amount]`",
        desc: "Generate 1–50 license key baru. `type`: PERMANENT/HOURLY/DAILY/WEEKLY. `duration`: nilai waktu. `amount`: jumlah key.",
      },
      {
        cmd: "/checkkey",
        usage: "`[key]`",
        desc: "Cek detail lengkap sebuah key: status, HWID, expired, jumlah reset.",
      },
      {
        cmd: "/revoke",
        usage: "`[key]`",
        desc: "Cabut key secara permanen. Key tidak bisa digunakan lagi.",
      },
      {
        cmd: "/deletekey",
        usage: "`[key]`",
        desc: "Hapus key dari database sepenuhnya (termasuk data user & reset log).",
      },
      {
        cmd: "/renewkey",
        usage: "`[key] [type] [duration]`",
        desc: "Perpanjang atau ubah durasi key, termasuk yang sudah expired.",
      },
      {
        cmd: "/setlabel",
        usage: "`[key] [label?]`",
        desc: "Tambahkan catatan ke key. Kosongkan `label` untuk hapus catatan.",
      },
      {
        cmd: "/cleanup",
        usage: "`[days?]`",
        desc: "Hapus semua key EXPIRED/REVOKED yang lebih dari X hari (default: 30 hari).",
      },
    ],
  },
  {
    category: "🖥️ HWID",
    items: [
      {
        cmd: "/sethwid",
        usage: "`[key] [hwid]`",
        desc: "Set HWID ke key secara manual (admin override).",
      },
      {
        cmd: "/resethwid",
        usage: "`[key]`",
        desc: "Reset HWID binding key (admin, tanpa batas). User pakai tombol di /panel.",
      },
      {
        cmd: "/setmaxhwid",
        usage: "`[key] [max] [period?]`",
        desc: "Set batas reset HWID user. `max`: jumlah (-1 = unlimited). `period`: DAILY/WEEKLY/MONTHLY/UNLIMITED.",
      },
    ],
  },
  {
    category: "🎖️ Whitelist VIP",
    items: [
      {
        cmd: "/whitelist add",
        usage: "`[user] [key_count] [type?] [duration?]`",
        desc: "Tambah user ke whitelist + auto-generate key untuk mereka.",
      },
      {
        cmd: "/whitelist remove",
        usage: "`[user]`",
        desc: "Hapus user dari whitelist. Role VIP dicabut + semua key dihapus otomatis.",
      },
      {
        cmd: "/whitelist list",
        usage: "*(tidak ada parameter)*",
        desc: "Tampilkan semua user yang ada di whitelist VIP.",
      },
    ],
  },
  {
    category: "🔍 Informasi",
    items: [
      {
        cmd: "/userkey",
        usage: "`[user?] [key?]`",
        desc: "Cek key milik user, atau cari siapa pemilik sebuah key. Isi salah satu.",
      },
      {
        cmd: "/stats",
        usage: "*(tidak ada parameter)*",
        desc: "Tampilkan statistik global: jumlah key per status + data whitelist.",
      },
      {
        cmd: "/transferkey",
        usage: "`[key] [to]`",
        desc: "Pindahkan kepemilikan key dari satu user ke user lain.",
      },
    ],
  },
  {
    category: "📋 Panel & Lainnya",
    items: [
      {
        cmd: "/panel",
        usage: "*(tidak ada parameter)*",
        desc: "Kirim panel VIP interaktif ke channel ini. User klik tombol untuk klaim role, ambil key, dll.",
      },
      {
        cmd: "/help",
        usage: "*(tidak ada parameter)*",
        desc: "Tampilkan daftar semua command dan fungsinya (yang sedang kamu baca ini).",
      },
    ],
  },
];

export const data = new SlashCommandBuilder()
  .setName("help")
  .setDescription("Lihat semua command bot beserta fungsinya — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator);

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const embeds = COMMANDS.map((cat) => {
    const fields = cat.items.map((item) => ({
      name: `${item.cmd} ${item.usage}`,
      value: item.desc,
      inline: false,
    }));

    return new EmbedBuilder()
      .setColor(0x5865f2)
      .setTitle(cat.category)
      .addFields(fields);
  });

  const header = new EmbedBuilder()
    .setColor(0x5865f2)
    .setTitle("📖 XiFil Hub — Daftar Command Bot")
    .setDescription(
      "Semua command di bawah ini hanya bisa dilihat dan digunakan oleh **Administrator**.\n" +
      "User biasa menggunakan tombol di channel `#panel-vip`.\n\u200b"
    )
    .setFooter({ text: "XiFil Hub • License Manager" })
    .setTimestamp();

  await interaction.editReply({ embeds: [header, ...embeds] });
}

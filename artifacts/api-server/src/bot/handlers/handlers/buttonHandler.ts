import {
  ButtonInteraction,
  EmbedBuilder,
  GuildMember,
  ModalBuilder,
  TextInputBuilder,
  TextInputStyle,
  ActionRowBuilder,
  ModalSubmitInteraction,
  TextChannel,
  ButtonBuilder,
  ButtonStyle,
} from "discord.js";
import { randomUUID } from "crypto";
import {
  getWhitelistUser,
  getUserKeys,
  getByKey,
  setVipRoleAssigned,
  getLastHwidReset,
  logHwidReset,
  resetHwidAndIncrementCount,
  addToWhitelist,
  assignKeyToUser,
  insertLicenses,
  getPendingTicket,
  addPendingTicket,
  removePendingTicket,
} from "../database.js";
import { generateLicenseKey, statusEmoji, durationLabel, getDurationMs } from "../utils.js";
import {
  logHwidReset as discordLogHwidReset,
  logWhitelistAdd,
  logTicketRequest,
  logTicketApproved,
  logTicketRejected,
} from "../../lib/discordLogger.js";
import { logger } from "../../lib/logger.js";

const LUA_SCRIPT = `loadstring(game:HttpGet("https://xifil-hub-production.up.railway.app/api/lua/loader?game=soul_iron"))()`;

const PERIOD_MS: Record<string, number> = {
  DAILY: 24 * 60 * 60 * 1000,
  WEEKLY: 7 * 24 * 60 * 60 * 1000,
  MONTHLY: 30 * 24 * 60 * 60 * 1000,
  UNLIMITED: 0,
};

const PERIOD_LABEL: Record<string, string> = {
  DAILY: "Per Hari",
  WEEKLY: "Per Minggu",
  MONTHLY: "Per Bulan",
  UNLIMITED: "Tanpa Cooldown",
};

// ─── Main router ──────────────────────────────────────────────────────────

export async function handleButton(interaction: ButtonInteraction): Promise<void> {
  const { customId } = interaction;

  if (customId === "get_role_vip") {
    await handleGetRoleVip(interaction);
  } else if (customId === "get_key") {
    await handleGetKey(interaction);
  } else if (customId === "reset_hwid") {
    await handleResetHwidButton(interaction);
  } else if (customId === "cek_hwid") {
    await handleCekHwid(interaction);
  } else if (customId === "request_akses_vip") {
    await handleRequestAksesVip(interaction);
  } else if (customId === "get_script") {
    await handleGetScript(interaction);
  } else if (customId.startsWith("approve_ticket_")) {
    await handleApproveTicketButton(interaction);
  } else if (customId.startsWith("reject_ticket_")) {
    await handleRejectTicket(interaction);
  }
}

// ─── Whitelist check helper ────────────────────────────────────────────────

async function requireWhitelist(interaction: ButtonInteraction): Promise<boolean> {
  const entry = await getWhitelistUser(interaction.user.id);
  if (!entry) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Akses Ditolak")
          .setDescription(
            "Fitur ini hanya tersedia untuk member yang terdaftar di whitelist VIP.\n" +
            "Ajukan permohonan melalui tombol **Request Akses** atau hubungi Administrator."
          )
          .setTimestamp(),
      ],
    });
    return false;
  }
  return true;
}

// ─── Get Role VIP ─────────────────────────────────────────────────────────

async function handleGetRoleVip(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  if (!(await requireWhitelist(interaction))) return;

  const entry = await getWhitelistUser(interaction.user.id);
  const guild = interaction.guild;
  if (!guild) {
    await interaction.editReply({ content: "Perintah ini hanya dapat digunakan di dalam server." });
    return;
  }

  const vipRoleName = process.env["VIP_ROLE_NAME"] ?? "VIP";
  const vipRole = guild.roles.cache.find((r) => r.name === vipRoleName);

  if (!vipRole) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Konfigurasi Role Tidak Ditemukan")
          .setDescription(
            `Role **${vipRoleName}** belum tersedia di server ini.\n` +
            "Mohon hubungi Administrator untuk menyelesaikan konfigurasi."
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  const member = interaction.member as GuildMember;
  if (member.roles.cache.has(vipRole.id)) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("ℹ️ Role Sudah Aktif")
          .setDescription(`Anda sudah memiliki role **${vipRoleName}**.`)
          .setTimestamp(),
      ],
    });
    return;
  }

  try {
    await member.roles.add(vipRole, "Whitelist VIP claim via panel");
    await setVipRoleAssigned(interaction.user.id);

    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x00c853)
          .setTitle("🎖️ Role VIP Berhasil Diklaim")
          .setDescription(
            `Selamat <@${interaction.user.id}>! Role **${vipRoleName}** telah berhasil diberikan.\n\n` +
            "Gunakan tombol **Get Key** untuk mengambil license key Anda."
          )
          .addFields({ name: "Total Key Terdaftar", value: `${entry!.key_count} key`, inline: true })
          .setFooter({ text: "XiFil Hub • License Manager" })
          .setTimestamp(),
      ],
    });
  } catch (err) {
    logger.error({ err }, "Failed to assign VIP role");
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Gagal Memberikan Role")
          .setDescription(
            "Bot tidak memiliki izin untuk memberikan role ini.\n" +
            "Pastikan posisi role bot berada **di atas** role VIP di pengaturan server."
          )
          .setTimestamp(),
      ],
    });
  }
}

// ─── Get Key ──────────────────────────────────────────────────────────────

async function handleGetKey(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  if (!(await requireWhitelist(interaction))) return;

  const userKeys = await getUserKeys(interaction.user.id);

  if (userKeys.length === 0) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("🔑 Belum Ada Key Terdaftar")
          .setDescription(
            "Saat ini Anda belum memiliki license key yang terdaftar.\n" +
            "Hubungi Administrator untuk mendapatkan key."
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  const fields: { name: string; value: string; inline: boolean }[] = [];
  for (const uk of userKeys.slice(0, 10)) {
    const license = await getByKey(uk.license_key);
    if (!license) continue;

    let expiryText = "Permanent ♾️";
    if (license.duration_type !== "PERMANENT" && license.expires_at) {
      const now = Date.now();
      expiryText = now > license.expires_at ? "❌ Expired" : `<t:${Math.floor(license.expires_at / 1000)}:R>`;
    } else if (license.status === "UNUSED") {
      expiryText = "⏳ Belum diaktifkan";
    }

    fields.push({
      name: `${statusEmoji(license.status)} ${license.status} • ${durationLabel(license.duration_type, license.duration_value)}`,
      value:
        `**Key:** ${uk.license_key}\n` +
        `**Berlaku hingga:** ${expiryText}` +
        (license.label ? `\n📝 *${license.label}*` : ""),
      inline: false,
    });
  }

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle(`🔑 License Key Anda (${userKeys.length} key)`)
        .setDescription("Berikut adalah license key yang terdaftar pada akun Anda:")
        .addFields(fields)
        .setFooter({ text: "XiFil Hub • Jaga kerahasiaan key Anda dan jangan bagikan kepada siapapun." })
        .setTimestamp(),
    ],
  });
}

// ─── Reset HWID Button → Modal ────────────────────────────────────────────

async function handleResetHwidButton(interaction: ButtonInteraction): Promise<void> {
  const modal = new ModalBuilder().setCustomId("reset_hwid_modal").setTitle("🔄 Reset HWID");
  const keyInput = new TextInputBuilder()
    .setCustomId("hwid_key_input")
    .setLabel("Masukkan License Key Anda")
    .setStyle(TextInputStyle.Short)
    .setRequired(true)
    .setPlaceholder("XXXX-XXXX-XXXX-XXXX")
    .setMinLength(19)
    .setMaxLength(19);
  modal.addComponents(new ActionRowBuilder<TextInputBuilder>().addComponents(keyInput));
  await interaction.showModal(modal);
}

// ─── Reset HWID Modal Submit ──────────────────────────────────────────────

export async function handleResetHwidModal(interaction: ModalSubmitInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const entry = await getWhitelistUser(interaction.user.id);
  if (!entry) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Akses Ditolak")
          .setDescription("Fitur ini hanya tersedia untuk member whitelist VIP.")
          .setTimestamp(),
      ],
    });
    return;
  }

  const key = interaction.fields.getTextInputValue("hwid_key_input").trim().toUpperCase();
  const license = await getByKey(key);

  if (!license) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder().setColor(0xd50000).setTitle("❌ Key Tidak Ditemukan")
          .setDescription("License key yang Anda masukkan tidak terdaftar di sistem.").setTimestamp(),
      ],
    });
    return;
  }

  if (license.status === "REVOKED") {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder().setColor(0xd50000).setTitle("❌ Key Telah Dinonaktifkan")
          .setDescription("Key ini telah dicabut oleh Administrator.").setTimestamp(),
      ],
    });
    return;
  }

  if (!license.hwid_hash) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder().setColor(0xff6d00).setTitle("ℹ️ HWID Belum Terikat")
          .setDescription("Key ini belum terikat ke perangkat manapun.").setTimestamp(),
      ],
    });
    return;
  }

  const userKeys = await getUserKeys(interaction.user.id);
  if (!userKeys.some((uk) => uk.license_key === key)) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Akses Ditolak")
          .setDescription("Anda hanya dapat mereset HWID untuk key yang terdaftar atas nama Anda.")
          .setTimestamp(),
      ],
    });
    return;
  }

  if (license.max_hwid_resets !== -1 && license.hwid_reset_count >= license.max_hwid_resets) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Batas Reset Tercapai")
          .setDescription(
            `Key ini telah mencapai batas maksimal reset HWID (**${license.max_hwid_resets}x**).\n` +
            "Hubungi Administrator untuk bantuan lebih lanjut."
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  const period = license.hwid_reset_period ?? "WEEKLY";
  const periodMs = PERIOD_MS[period] ?? PERIOD_MS["WEEKLY"]!;

  if (periodMs > 0) {
    const lastReset = await getLastHwidReset(interaction.user.id, key);
    const now = Date.now();
    if (lastReset) {
      const nextResetTime = lastReset.reset_at + periodMs;
      if (now < nextResetTime) {
        await interaction.editReply({
          embeds: [
            new EmbedBuilder()
              .setColor(0xff6d00)
              .setTitle("⏳ Cooldown Aktif")
              .setDescription(
                `Anda dapat melakukan reset HWID kembali pada <t:${Math.floor(nextResetTime / 1000)}:F> (<t:${Math.floor(nextResetTime / 1000)}:R>).\n\n` +
                `**Periode Reset:** ${PERIOD_LABEL[period] ?? period}`
              )
              .setTimestamp(),
          ],
        });
        return;
      }
    }
  }

  const now = Date.now();
  await resetHwidAndIncrementCount(key);
  await logHwidReset({ id: randomUUID(), discordUserId: interaction.user.id, licenseKey: key, resetAt: now });
  await discordLogHwidReset(key, interaction.user.id, false);

  const resetsDone = license.hwid_reset_count + 1;
  const maxLabel = license.max_hwid_resets === -1 ? "∞" : String(license.max_hwid_resets);
  const nextResetText = periodMs > 0 ? `<t:${Math.floor((now + periodMs) / 1000)}:R>` : "Kapan saja";

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ HWID Berhasil Direset")
        .setDescription("Key Anda kini dapat diaktifkan pada perangkat baru.")
        .addFields(
          { name: "Key", value: `\`${key}\``, inline: false },
          { name: "Total Reset", value: `${resetsDone} / ${maxLabel}`, inline: true },
          { name: "Reset Berikutnya", value: nextResetText, inline: true }
        )
        .setFooter({ text: `XiFil Hub • Periode: ${PERIOD_LABEL[period] ?? period}` })
        .setTimestamp(),
    ],
  });
}

// ─── Cek HWID ─────────────────────────────────────────────────────────────

async function handleCekHwid(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  if (!(await requireWhitelist(interaction))) return;

  const userKeys = await getUserKeys(interaction.user.id);
  if (userKeys.length === 0) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder().setColor(0xff6d00).setTitle("🔍 Belum Ada Key")
          .setDescription("Anda belum memiliki key yang terdaftar.").setTimestamp(),
      ],
    });
    return;
  }

  const fields: { name: string; value: string; inline: boolean }[] = [];
  for (const uk of userKeys.slice(0, 10)) {
    const license = await getByKey(uk.license_key);
    if (!license) continue;
    const hwidText = license.hwid_hash ? `🔒 \`${license.hwid_hash.substring(0, 20)}...\`` : "🔓 Belum terikat";
    fields.push({
      name: `${statusEmoji(license.status)} \`${uk.license_key}\``,
      value:
        `**HWID:** ${hwidText}\n` +
        `**Reset:** ${license.hwid_reset_count} / ${license.max_hwid_resets === -1 ? "∞" : license.max_hwid_resets} • ${PERIOD_LABEL[license.hwid_reset_period] ?? license.hwid_reset_period}`,
      inline: false,
    });
  }

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x2196f3)
        .setTitle("🔍 Status HWID Key Anda")
        .addFields(fields)
        .setFooter({ text: "XiFil Hub • HWID dipotong untuk keamanan" })
        .setTimestamp(),
    ],
  });
}

// ─── Request Akses VIP ────────────────────────────────────────────────────

async function handleRequestAksesVip(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  // Already whitelisted
  const existing = await getWhitelistUser(interaction.user.id);
  if (existing) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("ℹ️ Akun Sudah Terdaftar")
          .setDescription(
            "Akun Anda sudah terdaftar sebagai member VIP.\n" +
            "Gunakan tombol **Get Key** atau **Get Role VIP** untuk melanjutkan."
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  // Already has pending ticket
  const pending = await getPendingTicket(interaction.user.id);
  if (pending) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff9800)
          .setTitle("⏳ Permohonan Sedang Diproses")
          .setDescription(
            "Permohonan akses VIP Anda saat ini **sedang dalam proses peninjauan** oleh tim Administrator XiFil Hub.\n\n" +
            "Harap menunggu dengan sabar — Anda akan dihubungi melalui **Direct Message** setelah keputusan diberikan.\n\n" +
            "Jika membutuhkan bantuan segera, silakan menghubungi Administrator secara langsung di channel yang tersedia."
          )
          .setFooter({ text: "XiFil Hub • Mohon tidak mengirim ulang permohonan" })
          .setTimestamp(),
      ],
    });
    return;
  }

  const guild = interaction.guild;
  if (!guild) {
    await interaction.editReply({ content: "Perintah ini hanya dapat digunakan di dalam server." });
    return;
  }

  // Find #req-ticket channel (admin-only)
  const reqChannel = guild.channels.cache.find(
    (ch) => ch.isTextBased() && ch.name.toLowerCase().includes("req-ticket")
  ) as TextChannel | undefined;

  if (!reqChannel) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Sistem Permohonan Tidak Tersedia")
          .setDescription(
            "Sistem permohonan akses sedang tidak tersedia.\n" +
            "Silakan menghubungi Administrator secara langsung untuk mengajukan permohonan VIP."
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  const ticketEmbed = new EmbedBuilder()
    .setColor(0xff9800)
    .setTitle("🎟️ Permohonan Akses VIP Baru")
    .setDescription(
      `Pengguna <@${interaction.user.id}> mengajukan permohonan akses VIP.\n\n` +
      "Silakan tinjau permohonan ini dan pilih tindakan yang sesuai."
    )
    .addFields(
      { name: "👤 Pengguna", value: `<@${interaction.user.id}>`, inline: true },
      { name: "🏷️ Username", value: `\`${interaction.user.username}\``, inline: true },
      { name: "🆔 User ID", value: `\`${interaction.user.id}\``, inline: true },
      { name: "📅 Waktu", value: `<t:${Math.floor(Date.now() / 1000)}:F>`, inline: false }
    )
    .setFooter({ text: "XiFil Hub • Admin Only — req-ticket" })
    .setTimestamp();

  const ticketRow = new ActionRowBuilder<ButtonBuilder>().addComponents(
    new ButtonBuilder()
      .setCustomId(`approve_ticket_${interaction.user.id}`)
      .setLabel("Setujui Permohonan")
      .setEmoji("✅")
      .setStyle(ButtonStyle.Success),
    new ButtonBuilder()
      .setCustomId(`reject_ticket_${interaction.user.id}`)
      .setLabel("Tolak Permohonan")
      .setEmoji("❌")
      .setStyle(ButtonStyle.Danger)
  );

  const ticketMsg = await reqChannel.send({ embeds: [ticketEmbed], components: [ticketRow] });

  await addPendingTicket({
    discordUserId: interaction.user.id,
    channelId: reqChannel.id,
    messageId: ticketMsg.id,
    createdAt: Date.now(),
  });

  await logTicketRequest(interaction.user.id, interaction.user.username);

  // DM user confirmation
  try {
    await interaction.user.send({
      embeds: [
        new EmbedBuilder()
          .setColor(0x5865f2)
          .setTitle("🎟️ Permohonan Akses VIP Diterima")
          .setDescription(
            `Halo **${interaction.user.username}**!\n\n` +
            "Permohonan akses VIP Anda di **XiFil Hub** telah berhasil diterima oleh sistem kami.\n\n" +
            "Tim Administrator kami akan segera meninjau permohonan Anda. " +
            "Anda akan mendapatkan notifikasi melalui pesan ini setelah keputusan diberikan.\n\n" +
            "Mohon untuk tidak mengirim ulang permohonan selama proses peninjauan berlangsung."
          )
          .setFooter({ text: "XiFil Hub • License Manager" })
          .setTimestamp(),
      ],
    });
  } catch { /* DM might be blocked */ }

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ Permohonan Berhasil Dikirim")
        .setDescription(
          "Permohonan akses VIP Anda telah berhasil diteruskan kepada tim Administrator XiFil Hub.\n\n" +
          "Anda akan mendapatkan notifikasi melalui **Direct Message** setelah proses peninjauan selesai.\n" +
          "Mohon untuk bersabar dan tidak mengirim ulang permohonan."
        )
        .setFooter({ text: "XiFil Hub • Terima kasih telah bergabung" })
        .setTimestamp(),
    ],
  });
}

// ─── Approve Ticket → Show Modal ──────────────────────────────────────────

async function handleApproveTicketButton(interaction: ButtonInteraction): Promise<void> {
  const member = interaction.member as GuildMember;
  if (!member.permissions.has("Administrator")) {
    await interaction.reply({ content: "❌ Hanya Administrator yang dapat melakukan tindakan ini.", ephemeral: true });
    return;
  }

  const targetUserId = interaction.customId.replace("approve_ticket_", "");

  const modal = new ModalBuilder()
    .setCustomId(`approve_ticket_modal_${targetUserId}`)
    .setTitle("✅ Setujui Permohonan VIP");

  const giveKeyInput = new TextInputBuilder()
    .setCustomId("give_key")
    .setLabel("Berikan Key? (ya / tidak) — Default: tidak")
    .setStyle(TextInputStyle.Short)
    .setRequired(false)
    .setPlaceholder("ya / tidak")
    .setValue("tidak")
    .setMaxLength(5);

  const keyTypeInput = new TextInputBuilder()
    .setCustomId("key_type")
    .setLabel("Tipe Key (abaikan jika tidak beri key)")
    .setStyle(TextInputStyle.Short)
    .setRequired(false)
    .setPlaceholder("PERMANENT / DAILY / WEEKLY / HOURLY")
    .setValue("PERMANENT")
    .setMaxLength(10);

  const durationInput = new TextInputBuilder()
    .setCustomId("key_duration")
    .setLabel("Durasi (angka, abaikan jika PERMANENT)")
    .setStyle(TextInputStyle.Short)
    .setRequired(false)
    .setPlaceholder("Contoh: 7")
    .setValue("1")
    .setMaxLength(4);

  const countInput = new TextInputBuilder()
    .setCustomId("key_count")
    .setLabel("Jumlah Key (abaikan jika tidak beri key)")
    .setStyle(TextInputStyle.Short)
    .setRequired(false)
    .setPlaceholder("Contoh: 1")
    .setValue("1")
    .setMaxLength(2);

  modal.addComponents(
    new ActionRowBuilder<TextInputBuilder>().addComponents(giveKeyInput),
    new ActionRowBuilder<TextInputBuilder>().addComponents(keyTypeInput),
    new ActionRowBuilder<TextInputBuilder>().addComponents(durationInput),
    new ActionRowBuilder<TextInputBuilder>().addComponents(countInput)
  );

  await interaction.showModal(modal);
}

// ─── Approve Ticket Modal Submit ──────────────────────────────────────────

export async function handleApproveTicketModal(interaction: ModalSubmitInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const targetUserId = interaction.customId.replace("approve_ticket_modal_", "");

  const giveKeyRaw = interaction.fields.getTextInputValue("give_key").trim().toLowerCase();
  const giveKey = giveKeyRaw === "ya" || giveKeyRaw === "y" || giveKeyRaw === "yes";

  const keyTypeRaw = (interaction.fields.getTextInputValue("key_type").trim().toUpperCase()) || "PERMANENT";
  const keyType = ["PERMANENT", "DAILY", "WEEKLY", "HOURLY"].includes(keyTypeRaw) ? keyTypeRaw : "PERMANENT";
  const durationRaw = parseInt(interaction.fields.getTextInputValue("key_duration").trim()) || 1;
  const keyCount = Math.min(Math.max(parseInt(interaction.fields.getTextInputValue("key_count").trim()) || 1, 1), 10);

  const now = Date.now();

  // Whitelist user
  const existing = await getWhitelistUser(targetUserId);
  await addToWhitelist({
    id: existing?.id ?? randomUUID(),
    discordUserId: targetUserId,
    discordUsername: targetUserId,
    keyCount: giveKey ? keyCount : 0,
    addedBy: interaction.user.id,
    addedAt: now,
  });

  const generatedKeys: string[] = [];

  if (giveKey) {
    const duration = keyType === "PERMANENT" ? 0 : durationRaw;
    const licenseEntries = [];
    for (let i = 0; i < keyCount; i++) {
      let key = generateLicenseKey();
      let attempts = 0;
      while (await getByKey(key)) {
        key = generateLicenseKey();
        if (++attempts > 20) throw new Error("Key collision");
      }
      generatedKeys.push(key);
      licenseEntries.push({
        id: randomUUID(),
        licenseKey: key,
        durationType: keyType,
        durationValue: duration,
        issuerDiscordId: interaction.user.id,
        createdAt: now,
        maxHwidResets: 1,
        hwidResetPeriod: "WEEKLY",
      });
    }
    await insertLicenses(licenseEntries);
    for (const key of generatedKeys) {
      await assignKeyToUser({ id: randomUUID(), discordUserId: targetUserId, licenseKey: key, assignedAt: now });
    }
  }

  // Save pending ticket data BEFORE removing it from DB
  const pendingTicket = await getPendingTicket(targetUserId).catch(() => null);

  // Try to assign VIP role
  try {
    const guild = interaction.guild!;
    const vipRoleName = process.env["VIP_ROLE_NAME"] ?? "VIP";
    const vipRole = guild.roles.cache.find((r) => r.name === vipRoleName);
    const targetMember = await guild.members.fetch(targetUserId).catch(() => null);
    if (targetMember && vipRole) {
      await targetMember.roles.add(vipRole, "Ticket approved by admin");
    }
  } catch { /* best-effort */ }

  // Remove pending ticket
  await removePendingTicket(targetUserId);
  await logTicketApproved(targetUserId, interaction.user.id);
  await logWhitelistAdd(targetUserId, giveKey ? keyCount : 0, interaction.user.id);

  // DM user
  try {
    const targetUser = await interaction.client.users.fetch(targetUserId).catch(() => null);
    if (targetUser) {
      if (giveKey && generatedKeys.length > 0) {
        const keyBlock = generatedKeys.map((k) => `\`${k}\``).join("\n");
        await targetUser.send({
          embeds: [
            new EmbedBuilder()
              .setColor(0x00c853)
              .setTitle("✅ Permohonan VIP Disetujui")
              .setDescription(
                `Selamat **${targetUser.username}**! 🎉\n\n` +
                "Permohonan akses VIP Anda di **XiFil Hub** telah resmi disetujui oleh Administrator.\n\n" +
                "Berikut adalah license key yang telah disiapkan untuk Anda:"
              )
              .addFields(
                { name: "🔑 License Key", value: keyBlock, inline: false },
                { name: "📋 Tipe", value: durationLabel(keyType, durationRaw), inline: true },
                { name: "⚠️ Penting", value: "Jaga kerahasiaan key Anda. Jangan bagikan kepada siapapun.", inline: false }
              )
              .setFooter({ text: "XiFil Hub • License Manager" })
              .setTimestamp(),
          ],
        });
      } else {
        await targetUser.send({
          embeds: [
            new EmbedBuilder()
              .setColor(0x00c853)
              .setTitle("✅ Permohonan VIP Disetujui")
              .setDescription(
                `Selamat **${targetUser.username}**! 🎉\n\n` +
                "Permohonan akses VIP Anda di **XiFil Hub** telah resmi disetujui oleh Administrator.\n\n" +
                "Silakan kunjungi channel **#panel-vip** dan klik tombol **Get Key** untuk mengambil license key Anda, " +
                "atau klik **Get Role VIP** untuk mendapatkan role VIP Anda."
              )
              .setFooter({ text: "XiFil Hub • License Manager" })
              .setTimestamp(),
          ],
        });
      }
    }
  } catch { /* DM might be blocked */ }

  // Edit the original ticket message to mark as approved (remove buttons)
  // Uses data saved before removePendingTicket was called
  try {
    if (pendingTicket) {
      const ch = interaction.guild?.channels.cache.get(pendingTicket.channel_id) as TextChannel | undefined;
      if (ch) {
        const msg = await ch.messages.fetch(pendingTicket.message_id).catch(() => null);
        if (msg) {
          await msg.edit({
            embeds: [
              ...msg.embeds,
              new EmbedBuilder()
                .setColor(0x00c853)
                .setDescription(`✅ **Disetujui** oleh <@${interaction.user.id}> • <t:${Math.floor(Date.now() / 1000)}:R>`)
                .toJSON() as Parameters<typeof msg.edit>[0]["embeds"] extends Array<infer T> ? T : never,
            ],
            components: [],
          });
        }
      }
    }
  } catch { /* best-effort */ }

  const keyInfo = giveKey
    ? `**${keyCount} key** (${durationLabel(keyType, durationRaw)}) diberikan`
    : "Tidak ada key diberikan — user diarahkan ke Get Key di panel";

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ Permohonan Berhasil Disetujui")
        .setDescription(`Permohonan dari <@${targetUserId}> telah disetujui.`)
        .addFields(
          { name: "Key", value: keyInfo, inline: false },
          { name: "Notifikasi DM", value: "Terkirim ke user", inline: true },
          { name: "Oleh Admin", value: `<@${interaction.user.id}>`, inline: true }
        )
        .setTimestamp(),
    ],
  });
}

// ─── Reject Ticket ────────────────────────────────────────────────────────

async function handleRejectTicket(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const member = interaction.member as GuildMember;
  if (!member.permissions.has("Administrator")) {
    await interaction.editReply({ content: "❌ Hanya Administrator yang dapat melakukan tindakan ini." });
    return;
  }

  const targetUserId = interaction.customId.replace("reject_ticket_", "");

  // Save pending ticket data BEFORE removing it from DB
  const pendingTicket = await getPendingTicket(targetUserId).catch(() => null);

  await removePendingTicket(targetUserId);
  await logTicketRejected(targetUserId, interaction.user.id);

  // DM user
  try {
    const targetUser = await interaction.client.users.fetch(targetUserId).catch(() => null);
    if (targetUser) {
      await targetUser.send({
        embeds: [
          new EmbedBuilder()
            .setColor(0xd50000)
            .setTitle("❌ Permohonan VIP Tidak Dapat Disetujui")
            .setDescription(
              `Halo **${targetUser.username}**,\n\n` +
              "Mohon maaf, permohonan akses VIP Anda di **XiFil Hub** tidak dapat kami setujui saat ini.\n\n" +
              "Jika Anda memiliki pertanyaan lebih lanjut atau ingin mengajukan permohonan kembali, " +
              "silakan menghubungi Administrator XiFil Hub secara langsung."
            )
            .setFooter({ text: "XiFil Hub • License Manager" })
            .setTimestamp(),
        ],
      });
    }
  } catch { /* DM might be blocked */ }

  // Edit original ticket message using stored channel_id + message_id (reliable)
  try {
    if (pendingTicket) {
      const ch = interaction.guild?.channels.cache.get(pendingTicket.channel_id) as TextChannel | undefined;
      if (ch) {
        const msg = await ch.messages.fetch(pendingTicket.message_id).catch(() => null);
        if (msg) {
          await msg.edit({
            embeds: [
              ...msg.embeds,
              new EmbedBuilder()
                .setColor(0xd50000)
                .setDescription(`❌ **Ditolak** oleh <@${interaction.user.id}> • <t:${Math.floor(Date.now() / 1000)}:R>`)
                .toJSON() as Parameters<typeof msg.edit>[0]["embeds"] extends Array<infer T> ? T : never,
            ],
            components: [],
          });
        }
      }
    }
  } catch { /* best-effort */ }

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0xd50000)
        .setTitle("❌ Permohonan Ditolak")
        .setDescription(`Permohonan dari <@${targetUserId}> telah ditolak. Notifikasi DM telah dikirimkan kepada user.`)
        .addFields({ name: "Oleh Admin", value: `<@${interaction.user.id}>`, inline: true })
        .setTimestamp(),
    ],
  });
}

// ─── Get Script ───────────────────────────────────────────────────────────

async function handleGetScript(interaction: ButtonInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x5865f2)
        .setTitle("📜 Script Roblox — XiFil Hub")
        .setDescription("Salin script berikut dan jalankan melalui executor Roblox Anda:")
        .addFields({
          name: "Executor Script",
          value: LUA_SCRIPT,
          inline: false,
        })
        .setFooter({ text: "XiFil Hub • Jangan bagikan script ini kepada siapapun." })
        .setTimestamp(),
    ],
  });
}

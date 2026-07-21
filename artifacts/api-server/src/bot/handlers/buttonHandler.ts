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
  ChannelType,
  OverwriteType,
  PermissionFlagsBits,
  CategoryChannel,
} from "discord.js";
import { randomUUID } from "crypto";
import {
  getWhitelistUser,
  getUserKeys,
  getByKey,
  setVipRoleAssigned,
  getLastHwidReset,
  logHwidReset,
  resetHwid,
  addToWhitelist,
  assignKeyToUser,
  insertLicenses,
  getPendingTicket,
  addPendingTicket,
  removePendingTicket,
  userHasPremiumKey,
  getTrialKeyClaim,
  saveTrialKeyClaim,
} from "../database.js";
import { generateLicenseKey, statusEmoji, durationLabel, getDurationMs } from "../utils.js";
import { tryGrantPremiumRole } from "../utils/premiumRole.js";
import {
  logHwidReset as discordLogHwidReset,
  logWhitelistAdd,
  logTicketRequest,
  logTicketApproved,
  logTicketRejected,
} from "../../lib/discordLogger.js";
import { logger } from "../../lib/logger.js";
import { safeDefer } from "../utils/safeDefer.js";

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
  } else if (customId === "get_trial_key") {
    await handleGetTrialKey(interaction);
  } else if (customId === "buy_premium") {
    await handleBuyPremium(interaction);
  } else if (customId === "get_script") {
    await handleGetScript(interaction);
  } else if (customId.startsWith("approve_ticket_")) {
    await handleApproveTicketButton(interaction);
  } else if (customId.startsWith("reject_ticket_")) {
    await handleRejectTicket(interaction);
  } else if (customId.startsWith("close_ticket_")) {
    await handleCloseTicket(interaction);
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
            "Gunakan tombol **💎 Buy PREMIUM** untuk mengajukan permohonan, atau hubungi Administrator."
          )
          .setTimestamp(),
      ],
    });
    return false;
  }
  return true;
}

// ─── Get Role PREMIUM ─────────────────────────────────────────────────────

async function handleGetRoleVip(interaction: ButtonInteraction): Promise<void> {
  if (!await safeDefer(interaction)) return;

  if (!(await requireWhitelist(interaction))) return;

  const entry = await getWhitelistUser(interaction.user.id);
  const guild = interaction.guild;
  if (!guild) {
    await interaction.editReply({ content: "Perintah ini hanya dapat digunakan di dalam server." });
    return;
  }

  // Check if user has a valid PERMANENT key
  const hasPremiumKey = await userHasPremiumKey(interaction.user.id);
  if (!hasPremiumKey) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Key Premium Tidak Ditemukan")
          .setDescription(
            "Role **PREMIUM** hanya dapat diperoleh oleh member yang memiliki\n" +
            "**Key Type: Lifetime / Permanent** yang masih aktif.\n\n" +
            "Key sementara (Daily, Weekly, Hourly) **tidak memenuhi syarat**.\n\n" +
            "Hubungi Administrator jika kamu merasa ini adalah kesalahan."
          )
          .setFooter({ text: "XiFil Hub • License Manager" })
          .setTimestamp(),
      ],
    });
    return;
  }

  const premiumRoleName = process.env["PREMIUM_ROLE_NAME"] ?? "PREMIUM";
  const premiumRole = guild.roles.cache.find((r) => r.name === premiumRoleName);

  if (!premiumRole) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Konfigurasi Role Tidak Ditemukan")
          .setDescription(
            `Role **${premiumRoleName}** belum tersedia di server ini.\n` +
            "Mohon hubungi Administrator untuk menyelesaikan konfigurasi.\n\n" +
            `*(Atur env var \`PREMIUM_ROLE_NAME\` jika nama role berbeda)*`
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  const member = interaction.member as GuildMember;
  if (member.roles.cache.has(premiumRole.id)) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("ℹ️ Role Sudah Aktif")
          .setDescription(`Anda sudah memiliki role **${premiumRoleName}**. ✨`)
          .setFooter({ text: "XiFil Hub • License Manager" })
          .setTimestamp(),
      ],
    });
    return;
  }

  try {
    await member.roles.add(premiumRole, "Permanent key holder — PREMIUM claim via panel");
    await setVipRoleAssigned(interaction.user.id);

    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x00c853)
          .setTitle("💎 Role PREMIUM Berhasil Diklaim!")
          .setDescription(
            `Selamat <@${interaction.user.id}>! Role **${premiumRoleName}** telah berhasil diberikan.\n\n` +
            "Kamu memiliki key **Lifetime/Permanent** yang terverifikasi. 🎉\n\n" +
            "Gunakan tombol **Get Key** untuk mengambil license key Anda."
          )
          .addFields(
            { name: "Total Key Terdaftar", value: `${entry!.key_count} key`, inline: true },
            { name: "Tipe Akses", value: "💎 Lifetime / Permanent", inline: true }
          )
          .setFooter({ text: "XiFil Hub • License Manager" })
          .setTimestamp(),
      ],
    });
  } catch (err) {
    logger.error({ err }, "Failed to assign PREMIUM role");
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Gagal Memberikan Role")
          .setDescription(
            "Bot tidak memiliki izin untuk memberikan role ini.\n" +
            `Pastikan posisi role bot berada **di atas** role **${premiumRoleName}** di pengaturan server.`
          )
          .setTimestamp(),
      ],
    });
  }
}

// ─── Get Key ──────────────────────────────────────────────────────────────

async function handleGetKey(interaction: ButtonInteraction): Promise<void> {
  if (!await safeDefer(interaction)) return;

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
  if (!await safeDefer(interaction)) return;

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
  await resetHwid(key);
  await logHwidReset({ id: randomUUID(), discordUserId: interaction.user.id, licenseKey: key, resetAt: now });
  await discordLogHwidReset(key, interaction.user.id, false);

  const nextResetText = periodMs > 0 ? `<t:${Math.floor((now + periodMs) / 1000)}:R>` : "Kapan saja";

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("✅ HWID Berhasil Direset")
        .setDescription("Key Anda kini dapat diaktifkan pada perangkat baru.")
        .addFields(
          { name: "Key", value: `\`${key}\``, inline: false },
          { name: "Reset Berikutnya", value: nextResetText, inline: true }
        )
        .setFooter({ text: `XiFil Hub • Cooldown: ${PERIOD_LABEL[period] ?? period}` })
        .setTimestamp(),
    ],
  });
}

// ─── Cek HWID ─────────────────────────────────────────────────────────────

async function handleCekHwid(interaction: ButtonInteraction): Promise<void> {
  if (!await safeDefer(interaction)) return;

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
        `**Cooldown Reset:** ${PERIOD_LABEL[license.hwid_reset_period] ?? license.hwid_reset_period}`,
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

// ─── Get Trial Key ────────────────────────────────────────────────────────

const TRIAL_DURATION_HOURS = 6;

async function handleGetTrialKey(interaction: ButtonInteraction): Promise<void> {
  if (!await safeDefer(interaction)) return;

  // Check if already claimed
  const existing = await getTrialKeyClaim(interaction.user.id);
  if (existing) {
    const expiryMs = existing.claimed_at + TRIAL_DURATION_HOURS * 60 * 60 * 1000;
    const now = Date.now();
    const isExpired = now > expiryMs;

    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("⚠️ Trial Key Sudah Diklaim")
          .setDescription(
            "Kamu hanya bisa mendapatkan **1 Trial Key** per akun.\n\n" +
            `**Key Trial:** \`${existing.license_key}\`\n` +
            `**Diklaim:** <t:${Math.floor(existing.claimed_at / 1000)}:R>\n` +
            `**Status:** ${isExpired ? "🔴 Sudah Expired" : `🟢 Aktif hingga <t:${Math.floor(expiryMs / 1000)}:R>`}\n\n` +
            "Ingin akses **Permanent**? Gunakan tombol **💎 Buy PREMIUM**."
          )
          .setFooter({ text: "XiFil Hub • Trial berlaku 6 jam" })
          .setTimestamp(),
      ],
    });
    return;
  }

  // Generate trial key
  const now = Date.now();
  let trialKey = generateLicenseKey();
  let attempts = 0;
  while (await getByKey(trialKey)) {
    trialKey = generateLicenseKey();
    if (++attempts > 20) {
      await interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0xd50000)
            .setTitle("❌ Gagal Generate Key")
            .setDescription("Terjadi error saat membuat trial key. Coba lagi beberapa saat.")
            .setTimestamp(),
        ],
      });
      return;
    }
  }

  // Insert license (HOURLY × 6)
  await insertLicenses([{
    id: randomUUID(),
    licenseKey: trialKey,
    durationType: "HOURLY",
    durationValue: TRIAL_DURATION_HOURS,
    issuerDiscordId: "SYSTEM",
    createdAt: now,
    maxHwidResets: 0,
    hwidResetPeriod: "WEEKLY",
  }]);

  // Assign key to user
  await assignKeyToUser({
    id: randomUUID(),
    discordUserId: interaction.user.id,
    licenseKey: trialKey,
    assignedAt: now,
  });

  // Record claim (prevents double-claim)
  await saveTrialKeyClaim(interaction.user.id, trialKey, now);

  const expiryAfterActivation = `<t:${Math.floor((now + TRIAL_DURATION_HOURS * 60 * 60 * 1000) / 1000)}:R>`;

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x00c853)
        .setTitle("🎁 Trial Key Berhasil!")
        .setDescription(
          `Halo <@${interaction.user.id}>! Berikut adalah **Trial Key** kamu:\n\n` +
          `**🔑 Key:** \`${trialKey}\`\n\n` +
          "⚠️ **Penting:**\n" +
          `▸ Durasi: **${TRIAL_DURATION_HOURS} Jam** (timer mulai saat pertama kali diaktifkan)\n` +
          "▸ Key ini hanya untuk **1 perangkat** (tidak bisa reset HWID)\n" +
          "▸ Setiap akun hanya bisa klaim **1x** trial key\n\n" +
          "Suka dengan produk kami? Gunakan **💎 Buy PREMIUM** untuk akses permanen!"
        )
        .addFields(
          { name: "⏱️ Durasi", value: `${TRIAL_DURATION_HOURS} Jam`, inline: true },
          { name: "📅 Expired setelah aktivasi", value: expiryAfterActivation, inline: true },
        )
        .setFooter({ text: "XiFil Hub • Jaga kerahasiaan key kamu!" })
        .setTimestamp(),
    ],
  });
}

// ─── Buy PREMIUM ──────────────────────────────────────────────────────────

async function handleBuyPremium(interaction: ButtonInteraction): Promise<void> {
  if (!await safeDefer(interaction)) return;

  // Already whitelisted with a permanent key
  const existing = await getWhitelistUser(interaction.user.id);
  if (existing) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("ℹ️ Akun Sudah Terdaftar")
          .setDescription(
            "Akun kamu sudah terdaftar sebagai member.\n" +
            "Gunakan tombol **🎖️ Get Role VIP** untuk klaim role PREMIUM, atau **🔑 Get Key** untuk melihat key kamu."
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  // Already has a pending ticket
  const pending = await getPendingTicket(interaction.user.id);
  if (pending) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xff9800)
          .setTitle("⏳ Ticket Sedang Diproses")
          .setDescription(
            "Permintaan **Buy PREMIUM** kamu sedang **dalam proses peninjauan** oleh Admin.\n\n" +
            "Kamu akan mendapatkan notifikasi via **Direct Message** setelah diproses.\n\n" +
            "Mohon jangan mengirim ticket duplikat."
          )
          .setFooter({ text: "XiFil Hub • Mohon sabar menunggu" })
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

  // Create a private ticket channel visible only to the buyer + staff.
  // Server Administrators automatically see every channel regardless of
  // overwrites, so denying @everyone + allowing the buyer is enough to make
  // this a true 1-on-1 (buyer <-> admin) space. An optional staff role
  // (TICKET_STAFF_ROLE_ID) can be granted access too, for helpers who don't
  // hold the Administrator permission.
  const isSnowflake = (v: string) => /^\d{17,20}$/.test(v);
  const DEFAULT_TICKET_CATEGORY_ID = "1525372028826161204";
  const rawCategoryId = process.env["TICKET_CATEGORY_ID"]?.trim() || DEFAULT_TICKET_CATEGORY_ID;
  const ticketCategoryId = rawCategoryId && isSnowflake(rawCategoryId) ? rawCategoryId : undefined;
  if (rawCategoryId && !ticketCategoryId) {
    logger.warn({ rawCategoryId }, "TICKET_CATEGORY_ID bukan snowflake yang valid — diabaikan");
  }
  const rawStaffRoleId = process.env["TICKET_STAFF_ROLE_ID"]?.trim();
  const ticketStaffRoleId = rawStaffRoleId && isSnowflake(rawStaffRoleId) ? rawStaffRoleId : undefined;
  if (rawStaffRoleId && !ticketStaffRoleId) {
    logger.warn({ rawStaffRoleId }, "TICKET_STAFF_ROLE_ID bukan snowflake yang valid — diabaikan");
  }
  const rawLogChannelId = process.env["TICKET_CHANNEL_ID"]?.trim();
  const ticketLogChannelId = rawLogChannelId && isSnowflake(rawLogChannelId) ? rawLogChannelId : undefined;

  const safeName = interaction.user.username
    .toLowerCase()
    .replace(/[^a-z0-9-]/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 80) || "user";

  // Cari atau buat kategori untuk tiket
  let parentCategory: CategoryChannel | undefined;
  if (ticketCategoryId) {
    // Pakai kategori yang dikonfigurasi via env var
    try {
      const fetchedParent = guild.channels.cache.get(ticketCategoryId) ?? (await guild.channels.fetch(ticketCategoryId));
      if (fetchedParent?.type === ChannelType.GuildCategory) parentCategory = fetchedParent as CategoryChannel;
      else logger.warn({ ticketCategoryId }, "TICKET_CATEGORY_ID bukan kategori — diabaikan");
    } catch (err) {
      logger.warn({ err, ticketCategoryId, guildId: guild.id }, "TICKET_CATEGORY_ID gagal di-fetch — akan cari/buat kategori otomatis");
    }
  }
  if (!parentCategory) {
    // Tidak ada env var atau gagal fetch — cari kategori "Tickets" yang sudah ada
    const existing = guild.channels.cache.find(
      (c) => c.type === ChannelType.GuildCategory && c.name.toLowerCase() === "tickets"
    ) as CategoryChannel | undefined;
    if (existing) {
      parentCategory = existing;
    } else {
      // Buat kategori baru "Tickets" dengan permission dasar
      try {
        parentCategory = await guild.channels.create({
          name: "Tickets",
          type: ChannelType.GuildCategory,
          permissionOverwrites: [
            // Sembunyikan dari semua member biasa
            { id: guild.roles.everyone.id, type: OverwriteType.Role, deny: [PermissionFlagsBits.ViewChannel] },
            // Bot selalu bisa akses
            { id: interaction.client.user.id, type: OverwriteType.Member, allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.SendMessages, PermissionFlagsBits.ManageChannels, PermissionFlagsBits.EmbedLinks, PermissionFlagsBits.ReadMessageHistory] },
            // Staff role bisa lihat SEMUA tiket di kategori ini lewat inheritance
            ...(ticketStaffRoleId
              ? [{ id: ticketStaffRoleId, type: OverwriteType.Role, allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.SendMessages, PermissionFlagsBits.ReadMessageHistory, PermissionFlagsBits.ManageMessages] }]
              : []),
          ],
        }) as CategoryChannel;
        logger.info({ categoryId: parentCategory.id, guildId: guild.id }, "Kategori 'Tickets' dibuat otomatis");
      } catch (err) {
        logger.warn({ err, guildId: guild.id }, "Gagal membuat kategori 'Tickets' — tiket dibuat tanpa kategori");
      }
    }
  }

  // Pastikan kategori yang sudah ada juga punya permission staff role yang benar
  if (parentCategory && ticketStaffRoleId) {
    try {
      await parentCategory.permissionOverwrites.edit(ticketStaffRoleId, {
        ViewChannel: true,
        SendMessages: true,
        ReadMessageHistory: true,
        ManageMessages: true,
      });
      await parentCategory.permissionOverwrites.edit(interaction.client.user.id, {
        ViewChannel: true,
        SendMessages: true,
        ManageChannels: true,
        EmbedLinks: true,
        ReadMessageHistory: true,
      });
    } catch (err) {
      logger.warn({ err, guildId: guild.id }, "Gagal update permission kategori Tickets");
    }
  }

  // Cari atau buat channel log admin di dalam kategori Tickets
  let resolvedLogChannel: TextChannel | null = null;
  if (ticketLogChannelId) {
    try {
      const ch = (guild.channels.cache.get(ticketLogChannelId) ??
        await guild.channels.fetch(ticketLogChannelId).catch(() => null)) as TextChannel | null;
      if (ch?.isTextBased()) resolvedLogChannel = ch;
    } catch { /* best-effort */ }
  }
  if (!resolvedLogChannel && parentCategory) {
    // Cari channel "ticket-log" yang sudah ada di dalam kategori
    const existing = parentCategory.children.cache.find(
      (c) => c.type === ChannelType.GuildText && c.name.toLowerCase() === "ticket-log"
    ) as TextChannel | undefined;
    if (existing) {
      resolvedLogChannel = existing;
    } else {
      // Buat channel "ticket-log" baru di dalam kategori Tickets — khusus admin
      try {
        resolvedLogChannel = await guild.channels.create({
          name: "ticket-log",
          type: ChannelType.GuildText,
          parent: parentCategory.id,
          topic: "Log notifikasi ticket Buy PREMIUM — Admin only",
          permissionOverwrites: [
            { id: guild.roles.everyone.id, type: OverwriteType.Role, deny: [PermissionFlagsBits.ViewChannel] },
            { id: interaction.client.user.id, type: OverwriteType.Member, allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.SendMessages, PermissionFlagsBits.EmbedLinks] },
            ...(ticketStaffRoleId
              ? [{ id: ticketStaffRoleId, type: OverwriteType.Role, allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.SendMessages, PermissionFlagsBits.ReadMessageHistory] }]
              : []),
          ],
        }) as TextChannel;
        logger.info({ channelId: resolvedLogChannel.id, guildId: guild.id }, "Channel 'ticket-log' dibuat otomatis di dalam kategori Tickets");
      } catch (err) {
        logger.warn({ err, guildId: guild.id }, "Gagal membuat channel 'ticket-log'");
      }
    }
  }

  let reqChannel: TextChannel | undefined;
  try {
    reqChannel = await guild.channels.create({
      name: `ticket-${safeName}`,
      type: ChannelType.GuildText,
      parent: parentCategory?.id,
      topic: `Ticket Buy PREMIUM dari ${interaction.user.username} (${interaction.user.id})`,
      permissionOverwrites: [
        { id: guild.roles.everyone.id, type: OverwriteType.Role, deny: [PermissionFlagsBits.ViewChannel] },
        {
          id: interaction.user.id,
          type: OverwriteType.Member,
          allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.SendMessages, PermissionFlagsBits.ReadMessageHistory, PermissionFlagsBits.AttachFiles],
        },
        {
          id: interaction.client.user.id,
          type: OverwriteType.Member,
          allow: [PermissionFlagsBits.ViewChannel, PermissionFlagsBits.SendMessages, PermissionFlagsBits.ManageChannels, PermissionFlagsBits.EmbedLinks, PermissionFlagsBits.ReadMessageHistory],
        },
        // Staff role TIDAK perlu di sini — sudah di-allow di level kategori (inheritance)
      ],
    });
  } catch (err) {
    const errCode = (err as any)?.code;
    const errMsg = (err as any)?.message ?? String(err);
    logger.error(
      { err, errCode, errMsg, guildId: guild.id, userId: interaction.user.id },
      `Buy PREMIUM: guild.channels.create failed [code=${errCode}] ${errMsg}`
    );
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Sistem Ticket Tidak Tersedia")
          .setDescription(
            "Sistem ticket sedang tidak tersedia.\n" +
            "Silakan hubungi **Administrator** secara langsung untuk membeli PREMIUM."
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  const ticketEmbed = new EmbedBuilder()
    .setColor(0x5865f2)
    .setTitle("💎 Permintaan Buy PREMIUM")
    .setDescription(
      `Pengguna <@${interaction.user.id}> ingin membeli akses **PREMIUM**.\n\n` +
      "Silakan tinjau dan hubungi user ini untuk proses pembayaran & pemberian key."
    )
    .addFields(
      { name: "👤 Pengguna", value: `<@${interaction.user.id}>`, inline: true },
      { name: "🏷️ Username", value: `\`${interaction.user.username}\``, inline: true },
      { name: "🆔 User ID", value: `\`${interaction.user.id}\``, inline: true },
      { name: "📅 Waktu", value: `<t:${Math.floor(Date.now() / 1000)}:F>`, inline: false },
      { name: "🎁 Trial", value: (await getTrialKeyClaim(interaction.user.id)) ? "✅ Sudah pernah trial" : "❌ Belum trial", inline: true },
    )
    .setFooter({ text: "XiFil Hub • Admin Only — Buy PREMIUM Ticket" })
    .setTimestamp();

  const ticketRow = new ActionRowBuilder<ButtonBuilder>().addComponents(
    new ButtonBuilder()
      .setCustomId(`approve_ticket_${interaction.user.id}`)
      .setLabel("Setujui & Beri Key")
      .setEmoji("✅")
      .setStyle(ButtonStyle.Success),
    new ButtonBuilder()
      .setCustomId(`reject_ticket_${interaction.user.id}`)
      .setLabel("Tolak")
      .setEmoji("❌")
      .setStyle(ButtonStyle.Danger),
    new ButtonBuilder()
      .setCustomId(`close_ticket_${interaction.user.id}`)
      .setLabel("Tutup Ticket")
      .setEmoji("🔒")
      .setStyle(ButtonStyle.Secondary)
  );

  const ticketMsg = await reqChannel.send({
    content: `<@${interaction.user.id}>`,
    embeds: [ticketEmbed],
    components: [ticketRow],
  });

  await addPendingTicket({
    discordUserId: interaction.user.id,
    channelId: reqChannel.id,
    messageId: ticketMsg.id,
    createdAt: Date.now(),
  });

  await logTicketRequest(interaction.user.id, interaction.user.username);

  // Best-effort ping di channel log admin (ticket-log atau TICKET_CHANNEL_ID)
  if (resolvedLogChannel) {
    try {
      await resolvedLogChannel.send({
        embeds: [
          new EmbedBuilder()
            .setColor(0x5865f2)
            .setDescription(`💎 Ticket baru dari <@${interaction.user.id}> dibuka di <#${reqChannel.id}>`)
            .setTimestamp(),
        ],
      });
    } catch { /* best-effort, not required for the ticket to work */ }
  }

  // DM user confirmation
  try {
    await interaction.user.send({
      embeds: [
        new EmbedBuilder()
          .setColor(0x5865f2)
          .setTitle("💎 Ticket Buy PREMIUM Diterima")
          .setDescription(
            `Halo **${interaction.user.username}**! 👋\n\n` +
            "Ticket **Buy PREMIUM** kamu di **XiFil Hub** telah berhasil dikirim ke Admin.\n\n" +
            "Admin akan segera menghubungi kamu untuk proses selanjutnya.\n" +
            "Kamu akan dapat notifikasi via DM setelah diproses.\n\n" +
            "Mohon jangan kirim ticket duplikat."
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
        .setTitle("✅ Ticket Berhasil Dikirim!")
        .setDescription(
          `Channel ticket privat kamu telah dibuat: <#${reqChannel.id}>\n\n` +
          "Hanya kamu dan Admin yang bisa melihat channel tersebut.\n" +
          "Kamu juga akan mendapat notifikasi via **Direct Message** setelah diproses.\n" +
          "Harap bersabar dan jangan mengirim ulang ticket."
        )
        .setFooter({ text: "XiFil Hub • Terima kasih sudah berminat!" })
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
  if (!await safeDefer(interaction)) return;

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

  // Try to assign VIP role and auto-grant PREMIUM if key is PERMANENT
  try {
    const guild = interaction.guild!;
    const vipRoleName = process.env["VIP_ROLE_NAME"] ?? "VIP";
    const vipRole = guild.roles.cache.find((r) => r.name === vipRoleName);
    const targetMember = await guild.members.fetch(targetUserId).catch(() => null);
    if (targetMember && vipRole) {
      await targetMember.roles.add(vipRole, "Ticket approved by admin");
    }
    // Auto-grant PREMIUM if a PERMANENT key was given
    if (giveKey && keyType === "PERMANENT") {
      await tryGrantPremiumRole(guild, targetUserId);
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

  // Edit the original ticket message to mark as approved, keep a Close
  // Ticket button so the admin can clean up the private channel afterward.
  // Uses data saved before removePendingTicket was called
  try {
    if (pendingTicket) {
      const ch = (interaction.guild?.channels.cache.get(pendingTicket.channel_id) ??
        (await interaction.guild?.channels.fetch(pendingTicket.channel_id).catch(() => null))) as TextChannel | undefined;
      if (ch) {
        const msg = await ch.messages.fetch(pendingTicket.message_id).catch(() => null);
        if (msg) {
          await msg.edit({
            embeds: [
              ...msg.embeds,
              new EmbedBuilder()
                .setColor(0x00c853)
                .setDescription(`✅ **Disetujui** oleh <@${interaction.user.id}> • <t:${Math.floor(Date.now() / 1000)}:R>`),
            ] as unknown as typeof msg.embeds,
            components: [
              new ActionRowBuilder<ButtonBuilder>().addComponents(
                new ButtonBuilder()
                  .setCustomId(`close_ticket_${targetUserId}`)
                  .setLabel("Tutup Ticket")
                  .setEmoji("🔒")
                  .setStyle(ButtonStyle.Secondary)
              ),
            ],
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
  if (!await safeDefer(interaction)) return;

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

  // Edit original ticket message using stored channel_id + message_id
  // (reliable), keep a Close Ticket button so the admin can clean up the
  // private channel afterward.
  try {
    if (pendingTicket) {
      const ch = (interaction.guild?.channels.cache.get(pendingTicket.channel_id) ??
        (await interaction.guild?.channels.fetch(pendingTicket.channel_id).catch(() => null))) as TextChannel | undefined;
      if (ch) {
        const msg = await ch.messages.fetch(pendingTicket.message_id).catch(() => null);
        if (msg) {
          await msg.edit({
            embeds: [
              ...msg.embeds,
              new EmbedBuilder()
                .setColor(0xd50000)
                .setDescription(`❌ **Ditolak** oleh <@${interaction.user.id}> • <t:${Math.floor(Date.now() / 1000)}:R>`),
            ] as unknown as typeof msg.embeds,
            components: [
              new ActionRowBuilder<ButtonBuilder>().addComponents(
                new ButtonBuilder()
                  .setCustomId(`close_ticket_${targetUserId}`)
                  .setLabel("Tutup Ticket")
                  .setEmoji("🔒")
                  .setStyle(ButtonStyle.Secondary)
              ),
            ],
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

// ─── Close Ticket ─────────────────────────────────────────────────────────

async function handleCloseTicket(interaction: ButtonInteraction): Promise<void> {
  const member = interaction.member as GuildMember;
  if (!member.permissions.has("Administrator")) {
    await interaction.reply({ content: "❌ Hanya Administrator yang dapat menutup ticket.", ephemeral: true });
    return;
  }

  // Ambil userId dari customId: "close_ticket_{userId}"
  const targetUserId = interaction.customId.replace("close_ticket_", "");

  // Hapus pending ticket agar user bisa membuat tiket baru
  try {
    await removePendingTicket(targetUserId);
  } catch (err) {
    logger.warn({ err, targetUserId }, "handleCloseTicket: gagal hapus pending ticket");
  }

  await interaction.reply({
    embeds: [
      new EmbedBuilder()
        .setColor(0x9e9e9e)
        .setDescription(`🔒 Ticket ini akan ditutup oleh <@${interaction.user.id}> dalam 5 detik...`)
        .setTimestamp(),
    ],
  });

  const channel = interaction.channel;
  setTimeout(() => {
    if (channel && "delete" in channel) {
      channel.delete(`Ticket closed by ${interaction.user.username}`).catch((err) => {
        logger.warn({ err, channelId: channel.id }, "Failed to delete closed ticket channel");
      });
    }
  }, 5000);
}

// ─── Get Script ───────────────────────────────────────────────────────────

async function handleGetScript(interaction: ButtonInteraction): Promise<void> {
  if (!await safeDefer(interaction)) return;

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

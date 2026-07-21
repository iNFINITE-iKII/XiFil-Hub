import {
  SlashCommandBuilder,
  ChatInputCommandInteraction,
  EmbedBuilder,
  PermissionFlagsBits,
  GuildMember,
} from "discord.js";
import { randomUUID } from "crypto";
import {
  getWhitelistUser,
  addToWhitelist,
  removeFromWhitelist,
  getAllWhitelist,
  assignKeyToUser,
  insertLicenses,
  getByKey,
  removeAllUserKeysAndLicenses,
} from "../database.js";
import { generateLicenseKey, durationLabel } from "../utils.js";
import { logWhitelistAdd, logWhitelistRemove } from "../../lib/discordLogger.js";
import { logger } from "../../lib/logger.js";
import { tryGrantPremiumRole, tryRevokePremiumRole, premiumRoleResultField } from "../utils/premiumRole.js";

export const data = new SlashCommandBuilder()
  .setName("whitelist")
  .setDescription("Kelola whitelist VIP — Admin only")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator)
  .addSubcommand((sub) =>
    sub
      .setName("add")
      .setDescription("Tambahkan user ke whitelist VIP dan beri keys")
      .addUserOption((opt) =>
        opt.setName("user").setDescription("User Discord yang akan di-whitelist").setRequired(true)
      )
      .addIntegerOption((opt) =>
        opt
          .setName("key_count")
          .setDescription("Jumlah key yang diberikan ke user")
          .setRequired(true)
          .setMinValue(1)
          .setMaxValue(50)
      )
      .addStringOption((opt) =>
        opt
          .setName("type")
          .setDescription("Tipe key yang akan di-generate (default: PERMANENT)")
          .setRequired(false)
          .addChoices(
            { name: "Permanent (Selamanya)", value: "PERMANENT" },
            { name: "Per Jam", value: "HOURLY" },
            { name: "Per Hari", value: "DAILY" },
            { name: "Per Minggu", value: "WEEKLY" }
          )
      )
      .addIntegerOption((opt) =>
        opt
          .setName("duration")
          .setDescription("Durasi (contoh: 7 untuk 7 hari). Diabaikan untuk PERMANENT.")
          .setRequired(false)
          .setMinValue(1)
          .setMaxValue(9999)
      )
  )
  .addSubcommand((sub) =>
    sub
      .setName("remove")
      .setDescription("Hapus user dari whitelist VIP (role & key otomatis dihapus)")
      .addUserOption((opt) =>
        opt.setName("user").setDescription("User yang akan dihapus dari whitelist").setRequired(true)
      )
  )
  .addSubcommand((sub) =>
    sub.setName("list").setDescription("Lihat semua user yang ada di whitelist VIP")
  );

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  await interaction.deferReply({ ephemeral: true });

  const sub = interaction.options.getSubcommand();

  // ─── ADD ─────────────────────────────────────────────────────────────────
  if (sub === "add") {
    const target = interaction.options.getUser("user", true);
    const keyCount = interaction.options.getInteger("key_count", true);
    const keyType = (interaction.options.getString("type") ?? "PERMANENT").toUpperCase();
    const duration = interaction.options.getInteger("duration") ?? 1;

    if (keyType !== "PERMANENT" && !interaction.options.getInteger("duration")) {
      await interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0xd50000)
            .setTitle("❌ Parameter Kurang")
            .setDescription("Kamu harus mengisi `duration` untuk tipe key non-PERMANENT.")
            .setTimestamp(),
        ],
      });
      return;
    }

    const now = Date.now();
    const generatedKeys: string[] = [];
    const licenseEntries: Array<{
      id: string;
      licenseKey: string;
      durationType: string;
      durationValue: number;
      issuerDiscordId: string;
      createdAt: number;
    }> = [];

    for (let i = 0; i < keyCount; i++) {
      let key: string;
      let attempts = 0;
      do {
        key = generateLicenseKey();
        attempts++;
        if (attempts > 30) throw new Error("Key collision, coba lagi.");
      } while (await getByKey(key));

      generatedKeys.push(key);
      licenseEntries.push({
        id: randomUUID(),
        licenseKey: key,
        durationType: keyType,
        durationValue: keyType === "PERMANENT" ? 0 : duration,
        issuerDiscordId: interaction.user.id,
        createdAt: now,
      });
    }

    await insertLicenses(licenseEntries);

    for (const key of generatedKeys) {
      await assignKeyToUser({
        id: randomUUID(),
        discordUserId: target.id,
        licenseKey: key,
        assignedAt: now,
      });
    }

    const existing = await getWhitelistUser(target.id);
    await addToWhitelist({
      id: existing?.id ?? randomUUID(),
      discordUserId: target.id,
      discordUsername: target.username,
      keyCount: keyCount,
      addedBy: interaction.user.id,
      addedAt: now,
    });

    await logWhitelistAdd(target.id, keyCount, interaction.user.id);

    // Auto-grant PREMIUM role if key type is PERMANENT
    let premiumResult: Parameters<typeof premiumRoleResultField>[0] = "not_eligible";
    if (keyType === "PERMANENT" && interaction.guild) {
      premiumResult = await tryGrantPremiumRole(interaction.guild, target.id);
    }

    const keyBlock = generatedKeys.map((k) => `\`${k}\``).join("\n");
    const typeLabel = durationLabel(keyType, duration);

    const replyEmbed = new EmbedBuilder()
      .setColor(0x00c853)
      .setTitle("✅ Whitelist Berhasil")
      .setDescription(`<@${target.id}> telah ditambahkan ke whitelist VIP.`)
      .addFields(
        { name: "Tipe Key", value: typeLabel, inline: true },
        { name: "Jumlah Key", value: `${keyCount}`, inline: true },
        { name: "Ditambahkan oleh", value: `<@${interaction.user.id}>`, inline: true },
        { name: "Keys yang Digenerate", value: keyBlock },
        premiumRoleResultField(premiumResult),
      )
      .setFooter({ text: "License Manager • Role PREMIUM otomatis jika key Permanent" })
      .setTimestamp();

    await interaction.editReply({ embeds: [replyEmbed] });
    return;
  }

  // ─── REMOVE ───────────────────────────────────────────────────────────────
  if (sub === "remove") {
    const target = interaction.options.getUser("user", true);

    const entry = await getWhitelistUser(target.id);
    if (!entry) {
      await interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0xff6d00)
            .setTitle("⚠️ Tidak Ditemukan")
            .setDescription(`<@${target.id}> tidak ada di whitelist VIP.`)
            .setTimestamp(),
        ],
      });
      return;
    }

    const deletedKeys = await removeAllUserKeysAndLicenses(target.id);
    await removeFromWhitelist(target.id);
    await logWhitelistRemove(target.id, deletedKeys.length, interaction.user.id);

    let vipRoleStatus = "Tidak diproses";
    let premiumRoleStatus = "Tidak diproses";
    const guild = interaction.guild;
    if (guild) {
      try {
        const member = await guild.members.fetch(target.id).catch(() => null);
        if (member) {
          // Remove VIP role
          const vipRoleName = process.env["VIP_ROLE_NAME"] ?? "VIP";
          const vipRole = guild.roles.cache.find((r) => r.name === vipRoleName);
          if (vipRole && (member as GuildMember).roles.cache.has(vipRole.id)) {
            await (member as GuildMember).roles.remove(vipRole, "Removed from VIP whitelist");
            vipRoleStatus = "✅ Role VIP dicabut";
          } else {
            vipRoleStatus = "ℹ️ Tidak punya role VIP";
          }

          // Auto-revoke PREMIUM role
          const revokeResult = await tryRevokePremiumRole(guild, target.id);
          const revokeLabel: Record<string, string> = {
            removed: "💎 Role PREMIUM dicabut",
            did_not_have: "ℹ️ Tidak punya role PREMIUM",
            role_not_found: "⚠️ Role PREMIUM tidak ada di server",
            user_not_found: "⚠️ User tidak ada di server",
            error: "❌ Gagal mencabut role PREMIUM",
          };
          premiumRoleStatus = revokeLabel[revokeResult] ?? revokeResult;
        } else {
          vipRoleStatus = "⚠️ User tidak ada di server";
          premiumRoleStatus = "⚠️ User tidak ada di server";
        }
      } catch (err) {
        logger.error({ err }, "Failed to remove roles on whitelist remove");
        vipRoleStatus = "❌ Gagal mencabut role";
        premiumRoleStatus = "❌ Gagal mencabut role";
      }
    }

    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("🗑️ Whitelist Dihapus")
          .setDescription(`<@${target.id}> telah dihapus dari whitelist VIP.`)
          .addFields(
            { name: "Keys Dihapus", value: `${deletedKeys.length} key dihapus`, inline: true },
            { name: "Dihapus oleh", value: `<@${interaction.user.id}>`, inline: true },
            { name: "Status Role VIP", value: vipRoleStatus, inline: false },
            { name: "Status Role PREMIUM", value: premiumRoleStatus, inline: false },
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  // ─── LIST ────────────────────────────────────────────────────────────────
  if (sub === "list") {
    const list = await getAllWhitelist();

    if (list.length === 0) {
      await interaction.editReply({
        embeds: [
          new EmbedBuilder()
            .setColor(0x2196f3)
            .setTitle("📋 Whitelist VIP")
            .setDescription("Belum ada user yang di-whitelist.")
            .setTimestamp(),
        ],
      });
      return;
    }

    const rows = list
      .slice(0, 25)
      .map(
        (e, i) =>
          `**${i + 1}.** <@${e.discord_user_id}> — **${e.key_count}** key — VIP: ${e.vip_role_assigned ? "✅" : "❌"}`
      )
      .join("\n");

    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x2196f3)
          .setTitle(`📋 Whitelist VIP (${list.length} user)`)
          .setDescription(rows)
          .setFooter({ text: "License Manager" })
          .setTimestamp(),
      ],
    });
  }
}

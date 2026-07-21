import {
  SlashCommandBuilder,
  PermissionFlagsBits,
  ChatInputCommandInteraction,
  EmbedBuilder,
  GuildMember,
} from "discord.js";
import { getAllPremiumEligibleUserIds } from "../database.js";
import { logger } from "../../lib/logger.js";

export const data = new SlashCommandBuilder()
  .setName("syncpremium")
  .setDescription("Hapus role PREMIUM dari semua user yang tidak memiliki key Lifetime/Permanent")
  .setDefaultMemberPermissions(PermissionFlagsBits.Administrator);

export async function execute(interaction: ChatInputCommandInteraction): Promise<void> {
  if (!await safeDefer(interaction)) return;

  const guild = interaction.guild;
  if (!guild) {
    await interaction.editReply({ content: "Perintah ini hanya dapat digunakan di dalam server." });
    return;
  }

  const premiumRoleName = process.env["PREMIUM_ROLE_NAME"] ?? "PREMIUM";
  const premiumRole = guild.roles.cache.find((r) => r.name === premiumRoleName);

  if (!premiumRole) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Role Tidak Ditemukan")
          .setDescription(
            `Role **${premiumRoleName}** tidak ditemukan di server ini.\n` +
            "Pastikan role sudah dibuat atau atur env var `PREMIUM_ROLE_NAME` dengan nama yang benar."
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  await interaction.editReply({
    embeds: [
      new EmbedBuilder()
        .setColor(0xff6d00)
        .setTitle("⏳ Sedang Memproses...")
        .setDescription("Mengambil data member dan memverifikasi key premium. Harap tunggu...")
        .setTimestamp(),
    ],
  });

  // Fetch all guild members to get fresh role data
  let allMembers: GuildMember[];
  try {
    const fetched = await guild.members.fetch();
    allMembers = [...fetched.values()];
  } catch (err) {
    logger.error({ err }, "syncpremium: failed to fetch guild members");
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0xd50000)
          .setTitle("❌ Gagal Mengambil Data Member")
          .setDescription(
            "Bot tidak dapat mengambil daftar member server.\n" +
            "Pastikan bot memiliki permission **Server Members Intent** yang aktif di Discord Developer Portal."
          )
          .setTimestamp(),
      ],
    });
    return;
  }

  // Find all members who currently have the PREMIUM role
  const membersWithPremium = allMembers.filter((m) => m.roles.cache.has(premiumRole.id));

  if (membersWithPremium.length === 0) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x2196f3)
          .setTitle("ℹ️ Tidak Ada Member PREMIUM")
          .setDescription(`Tidak ada member yang memiliki role **${premiumRoleName}** saat ini.`)
          .setFooter({ text: "XiFil Hub • Sync Premium" })
          .setTimestamp(),
      ],
    });
    return;
  }

  // Get all eligible user IDs from DB (have valid PERMANENT key)
  const eligibleIds = new Set(await getAllPremiumEligibleUserIds());

  // Determine who should be stripped
  const toStrip = membersWithPremium.filter((m) => !eligibleIds.has(m.id));
  const toKeep = membersWithPremium.filter((m) => eligibleIds.has(m.id));

  if (toStrip.length === 0) {
    await interaction.editReply({
      embeds: [
        new EmbedBuilder()
          .setColor(0x00c853)
          .setTitle("✅ Semua Member PREMIUM Valid")
          .setDescription(
            `Seluruh **${membersWithPremium.length} member** dengan role **${premiumRoleName}** memiliki key Lifetime/Permanent yang valid.\n` +
            "Tidak ada role yang perlu dihapus. ✨"
          )
          .setFooter({ text: "XiFil Hub • Sync Premium" })
          .setTimestamp(),
      ],
    });
    return;
  }

  // Strip role from ineligible members
  const stripped: string[] = [];
  const failed: string[] = [];

  for (const member of toStrip) {
    try {
      await member.roles.remove(premiumRole, "syncpremium: tidak memiliki key Lifetime/Permanent yang valid");
      stripped.push(member.id);
      logger.info({ userId: member.id, tag: member.user.tag }, "syncpremium: removed PREMIUM role");
    } catch (err) {
      failed.push(member.id);
      logger.error({ err, userId: member.id }, "syncpremium: failed to remove role");
    }
  }

  const strippedList = stripped.length > 0
    ? stripped.map((id) => `<@${id}>`).join(", ")
    : "—";

  const failedList = failed.length > 0
    ? failed.map((id) => `<@${id}>`).join(", ")
    : "—";

  const resultEmbed = new EmbedBuilder()
    .setColor(stripped.length > 0 ? 0x00c853 : 0xff6d00)
    .setTitle("🔄 Sync PREMIUM Selesai")
    .setDescription(
      `Proses sinkronisasi role **${premiumRoleName}** telah selesai.\n` +
      "Member yang **tidak memiliki key Lifetime/Permanent aktif** telah dihapus rolenya."
    )
    .addFields(
      {
        name: "📊 Ringkasan",
        value:
          `▸ Total member dengan role PREMIUM: **${membersWithPremium.length}**\n` +
          `▸ Member eligible (dipertahankan): **${toKeep.length}**\n` +
          `▸ Role dihapus: **${stripped.length}**\n` +
          `▸ Gagal dihapus: **${failed.length}**`,
        inline: false,
      }
    )
    .setFooter({ text: `XiFil Hub • Sync Premium • Dieksekusi oleh ${interaction.user.tag}` })
    .setTimestamp();

  if (stripped.length > 0) {
    resultEmbed.addFields({
      name: `❌ Role Dihapus (${stripped.length})`,
      value: strippedList.length > 1024 ? `${stripped.length} member (terlalu banyak untuk ditampilkan)` : strippedList,
      inline: false,
    });
  }

  if (failed.length > 0) {
    resultEmbed.addFields({
      name: `⚠️ Gagal Dihapus (${failed.length})`,
      value: failedList.length > 1024
        ? `${failed.length} member (periksa permission bot)`
        : `${failedList}\n\n*Pastikan role bot berada di atas role **${premiumRoleName}**.*`,
      inline: false,
    });
  }

  await interaction.editReply({ embeds: [resultEmbed] });
}

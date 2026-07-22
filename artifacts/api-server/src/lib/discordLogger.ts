import { EmbedBuilder, TextChannel } from "discord.js";
import { getClient } from "../bot/clientRef.js";

const LOG_CHANNEL_KEYWORDS = ["log-aktivitas", "log aktivitas", "log_aktivitas"];

function findLogChannel(): TextChannel | null {
  const client = getClient();
  if (!client) return null;

  for (const guild of client.guilds.cache.values()) {
    for (const channel of guild.channels.cache.values()) {
      if (
        channel.isTextBased() &&
        LOG_CHANNEL_KEYWORDS.some((kw) => channel.name.toLowerCase().includes(kw))
      ) {
        return channel as TextChannel;
      }
    }
  }
  return null;
}

export async function logActivity(embed: EmbedBuilder): Promise<void> {
  try {
    const channel = findLogChannel();
    if (!channel) return;
    await channel.send({ embeds: [embed] });
  } catch {
    // Logging should never crash the main flow
  }
}

export async function logKeyActivated(licenseKey: string, hwid: string): Promise<void> {
  await logActivity(
    new EmbedBuilder()
      .setColor(0x00c853)
      .setTitle("🟢 Key Diaktifkan")
      .addFields(
        { name: "Key", value: `\`${licenseKey}\``, inline: true },
        { name: "HWID", value: `\`${hwid.substring(0, 24)}...\``, inline: true }
      )
      .setTimestamp()
  );
}

export async function logKeyExpired(licenseKey: string): Promise<void> {
  await logActivity(
    new EmbedBuilder()
      .setColor(0xff6d00)
      .setTitle("🟠 Key Expired")
      .addFields({ name: "Key", value: `\`${licenseKey}\``, inline: true })
      .setTimestamp()
  );
}

export async function logHwidMismatch(licenseKey: string): Promise<void> {
  await logActivity(
    new EmbedBuilder()
      .setColor(0xd50000)
      .setTitle("⚠️ HWID Mismatch")
      .setDescription("Ada percobaan aktivasi dengan HWID yang salah.")
      .addFields({ name: "Key", value: `\`${licenseKey}\``, inline: true })
      .setTimestamp()
  );
}

export async function logRevoke(licenseKey: string, adminId: string): Promise<void> {
  await logActivity(
    new EmbedBuilder()
      .setColor(0xd50000)
      .setTitle("🔴 Key Direvoke")
      .addFields(
        { name: "Key", value: `\`${licenseKey}\``, inline: true },
        { name: "Oleh Admin", value: `<@${adminId}>`, inline: true }
      )
      .setTimestamp()
  );
}

export async function logHwidReset(
  licenseKey: string,
  userId: string,
  isAdmin: boolean
): Promise<void> {
  await logActivity(
    new EmbedBuilder()
      .setColor(0x2196f3)
      .setTitle("🔄 HWID Direset")
      .addFields(
        { name: "Key", value: `\`${licenseKey}\``, inline: true },
        { name: isAdmin ? "Admin" : "User", value: `<@${userId}>`, inline: true }
      )
      .setTimestamp()
  );
}

export async function logWhitelistAdd(
  targetId: string,
  keyCount: number,
  adminId: string
): Promise<void> {
  await logActivity(
    new EmbedBuilder()
      .setColor(0x00c853)
      .setTitle("✅ Whitelist Ditambah")
      .addFields(
        { name: "User", value: `<@${targetId}>`, inline: true },
        { name: "Jumlah Key", value: `${keyCount}`, inline: true },
        { name: "Oleh Admin", value: `<@${adminId}>`, inline: true }
      )
      .setTimestamp()
  );
}

export async function logWhitelistRemove(
  targetId: string,
  deletedKeys: number,
  adminId: string
): Promise<void> {
  await logActivity(
    new EmbedBuilder()
      .setColor(0xd50000)
      .setTitle("🗑️ Whitelist Dihapus")
      .addFields(
        { name: "User", value: `<@${targetId}>`, inline: true },
        { name: "Key Dihapus", value: `${deletedKeys}`, inline: true },
        { name: "Oleh Admin", value: `<@${adminId}>`, inline: true }
      )
      .setTimestamp()
  );
}

export async function logTicketRequest(userId: string, username: string): Promise<void> {
  await logActivity(
    new EmbedBuilder()
      .setColor(0xff9800)
      .setTitle("🎟️ Request Akses VIP Baru")
      .addFields(
        { name: "User", value: `<@${userId}> (${username})`, inline: true }
      )
      .setTimestamp()
  );
}

export async function logTicketApproved(
  targetId: string,
  adminId: string
): Promise<void> {
  await logActivity(
    new EmbedBuilder()
      .setColor(0x00c853)
      .setTitle("✅ Ticket Disetujui")
      .addFields(
        { name: "User", value: `<@${targetId}>`, inline: true },
        { name: "Oleh Admin", value: `<@${adminId}>`, inline: true }
      )
      .setTimestamp()
  );
}

export async function logTicketRejected(
  targetId: string,
  adminId: string
): Promise<void> {
  await logActivity(
    new EmbedBuilder()
      .setColor(0xd50000)
      .setTitle("❌ Ticket Ditolak")
      .addFields(
        { name: "User", value: `<@${targetId}>`, inline: true },
        { name: "Oleh Admin", value: `<@${adminId}>`, inline: true }
      )
      .setTimestamp()
  );
}

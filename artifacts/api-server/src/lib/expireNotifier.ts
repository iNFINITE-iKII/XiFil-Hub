import { EmbedBuilder } from "discord.js";
import { getClient } from "../bot/clientRef.js";
import { getExpiringKeys, markNotifiedExpire } from "../bot/database.js";
import { logger } from "./logger.js";

const THREE_DAYS_MS = 3 * 24 * 60 * 60 * 1000;
const CHECK_INTERVAL_MS = 60 * 60 * 1000; // setiap 1 jam

export function startExpireNotifier(): void {
  setInterval(checkExpiring, CHECK_INTERVAL_MS);
  logger.info("Expire notifier started (checks every 1 hour)");
}

async function checkExpiring(): Promise<void> {
  try {
    const client = getClient();
    if (!client) return;

    const now = Date.now();
    const cutoff = now + THREE_DAYS_MS;

    const expiring = await getExpiringKeys(now, cutoff);
    if (expiring.length === 0) return;

    logger.info({ count: expiring.length }, "Sending expire notifications");

    for (const item of expiring) {
      try {
        const user = await client.users.fetch(item.discord_user_id).catch(() => null);
        if (!user) continue;

        const hoursLeft = Math.floor((item.expires_at - now) / (60 * 60 * 1000));
        const daysLeft = Math.floor(hoursLeft / 24);
        const timeLabel =
          daysLeft >= 1 ? `${daysLeft} hari lagi` : `${hoursLeft} jam lagi`;

        const embed = new EmbedBuilder()
          .setColor(0xff6d00)
          .setTitle("⏳ License Key Hampir Expired!")
          .setDescription(
            `Hai <@${item.discord_user_id}>!\n\nSalah satu license key kamu akan expired segera. Hubungi admin untuk perpanjangan.`
          )
          .addFields(
            { name: "Key", value: `\`${item.license_key}\``, inline: true },
            { name: "Expired", value: `<t:${Math.floor(item.expires_at / 1000)}:F>`, inline: true },
            { name: "Sisa Waktu", value: `⚠️ **${timeLabel}**`, inline: true }
          )
          .setFooter({ text: "XiFil Hub • License Manager" })
          .setTimestamp();

        await user.send({ embeds: [embed] });
        await markNotifiedExpire(item.license_key);
      } catch {
        // DM mungkin diblok user, tidak masalah
      }
    }
  } catch (err) {
    logger.error({ err }, "Expire notifier error");
  }
}

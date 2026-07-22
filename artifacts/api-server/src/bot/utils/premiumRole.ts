import { Guild, GuildMember, EmbedBuilder } from "discord.js";
import { userHasPremiumKey } from "../database.js";
import { logger } from "../../lib/logger.js";

/**
 * Automatically grants the PREMIUM role to a guild member if they own
 * at least one valid PERMANENT key (ACTIVE or UNUSED).
 *
 * Call this after any PERMANENT key is assigned to a user.
 * Safe to call repeatedly — skips silently if role already assigned or not found.
 *
 * @returns "granted" | "already_has" | "not_eligible" | "role_not_found" | "user_not_found" | "error"
 */
export async function tryGrantPremiumRole(
  guild: Guild,
  userId: string
): Promise<"granted" | "already_has" | "not_eligible" | "role_not_found" | "user_not_found" | "error"> {
  try {
    const eligible = await userHasPremiumKey(userId);
    if (!eligible) return "not_eligible";

    const premiumRoleName = process.env["PREMIUM_ROLE_NAME"] ?? "PREMIUM";
    const premiumRole = guild.roles.cache.find((r) => r.name === premiumRoleName);
    if (!premiumRole) {
      logger.warn({ premiumRoleName }, "tryGrantPremiumRole: PREMIUM role not found in guild");
      return "role_not_found";
    }

    const member = await guild.members.fetch(userId).catch(() => null) as GuildMember | null;
    if (!member) return "user_not_found";

    if (member.roles.cache.has(premiumRole.id)) return "already_has";

    await member.roles.add(premiumRole, "Auto-grant: user received a Permanent key");
    logger.info({ userId, premiumRoleName }, "Auto-granted PREMIUM role");
    return "granted";
  } catch (err) {
    logger.error({ err, userId }, "tryGrantPremiumRole: unexpected error");
    return "error";
  }
}

/**
 * Removes the PREMIUM role from a guild member.
 * Call this when a user's last valid PERMANENT key is removed/revoked.
 *
 * @returns "removed" | "did_not_have" | "role_not_found" | "user_not_found" | "error"
 */
export async function tryRevokePremiumRole(
  guild: Guild,
  userId: string
): Promise<"removed" | "did_not_have" | "role_not_found" | "user_not_found" | "error"> {
  try {
    const premiumRoleName = process.env["PREMIUM_ROLE_NAME"] ?? "PREMIUM";
    const premiumRole = guild.roles.cache.find((r) => r.name === premiumRoleName);
    if (!premiumRole) return "role_not_found";

    const member = await guild.members.fetch(userId).catch(() => null) as GuildMember | null;
    if (!member) return "user_not_found";

    if (!member.roles.cache.has(premiumRole.id)) return "did_not_have";

    await member.roles.remove(premiumRole, "Auto-revoke: user's Permanent keys removed from system");
    logger.info({ userId, premiumRoleName }, "Auto-revoked PREMIUM role");
    return "removed";
  } catch (err) {
    logger.error({ err, userId }, "tryRevokePremiumRole: unexpected error");
    return "error";
  }
}

/** Build a small inline field to show the auto-grant result in an admin embed. */
export function premiumRoleResultField(result: ReturnType<typeof tryGrantPremiumRole> extends Promise<infer R> ? R : never): { name: string; value: string; inline: boolean } {
  const label: Record<string, string> = {
    granted: "💎 Role PREMIUM otomatis diberikan",
    already_has: "💎 Sudah memiliki role PREMIUM",
    not_eligible: "— (key bukan tipe Permanent)",
    role_not_found: "⚠️ Role PREMIUM tidak ditemukan di server",
    user_not_found: "⚠️ User tidak ada di server (role tidak bisa diberikan)",
    error: "⚠️ Gagal memberikan role PREMIUM",
  };
  return {
    name: "💎 Role PREMIUM",
    value: label[result] ?? result,
    inline: false,
  };
}

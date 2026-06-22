import postgres from "postgres";
import { randomUUID } from "crypto";

const connectionString = process.env["DATABASE_URL"];
if (!connectionString) {
  throw new Error("DATABASE_URL environment variable is required but was not provided.");
}

export const sql = postgres(connectionString, {
  ssl: process.env["NODE_ENV"] === "production" ? "require" : false,
  max: 10,
  idle_timeout: 30,
  types: {
    bigint: {
      to: 20,
      from: [20],
      serialize: (x: number) => String(x),
      parse: (x: string) => Number(x),
    },
  },
});

export interface License {
  id: string;
  license_key: string;
  duration_type: "PERMANENT" | "HOURLY" | "DAILY" | "WEEKLY";
  duration_value: number;
  status: "UNUSED" | "ACTIVE" | "EXPIRED" | "REVOKED";
  hwid_hash: string | null;
  expires_at: number | null;
  issuer_discord_id: string;
  created_at: number;
  max_hwid_resets: number;
  hwid_reset_count: number;
  hwid_reset_period: "DAILY" | "WEEKLY" | "MONTHLY" | "UNLIMITED";
  label: string | null;
  notified_expire: boolean;
  max_hwid_count: number;
}

export interface LicenseHwid {
  id: string;
  license_key: string;
  hwid_hash: string;
  bound_at: number;
}

export interface WhitelistEntry {
  id: string;
  discord_user_id: string;
  discord_username: string;
  key_count: number;
  vip_role_assigned: boolean;
  added_by: string;
  added_at: number;
}

export interface UserKey {
  id: string;
  discord_user_id: string;
  license_key: string;
  assigned_at: number;
}

export interface HwidResetLog {
  id: string;
  discord_user_id: string;
  license_key: string;
  reset_at: number;
}

export interface PendingTicket {
  discord_user_id: string;
  channel_id: string;
  message_id: string;
  created_at: number;
}

export interface LicenseStats {
  total: number;
  active: number;
  unused: number;
  expired: number;
  revoked: number;
}

export interface ExpiringKeyRow {
  license_key: string;
  expires_at: number;
  discord_user_id: string;
}

export async function initDb(): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS licenses (
      id TEXT PRIMARY KEY,
      license_key TEXT UNIQUE NOT NULL,
      duration_type TEXT NOT NULL,
      duration_value INTEGER NOT NULL,
      status TEXT NOT NULL DEFAULT 'UNUSED',
      hwid_hash TEXT DEFAULT NULL,
      expires_at BIGINT DEFAULT NULL,
      issuer_discord_id TEXT NOT NULL,
      created_at BIGINT NOT NULL,
      max_hwid_resets INT DEFAULT 1,
      hwid_reset_count INT DEFAULT 0,
      hwid_reset_period TEXT DEFAULT 'WEEKLY',
      label TEXT DEFAULT NULL,
      notified_expire BOOLEAN DEFAULT FALSE,
      max_hwid_count INT DEFAULT 1
    )
  `;
  await sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS max_hwid_resets INT DEFAULT 1`;
  await sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS hwid_reset_count INT DEFAULT 0`;
  await sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS hwid_reset_period TEXT DEFAULT 'WEEKLY'`;
  await sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS label TEXT DEFAULT NULL`;
  await sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS notified_expire BOOLEAN DEFAULT FALSE`;
  await sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS max_hwid_count INT DEFAULT 1`;
  await sql`CREATE INDEX IF NOT EXISTS idx_license_key ON licenses(license_key)`;

  await sql`
    CREATE TABLE IF NOT EXISTS license_hwids (
      id TEXT PRIMARY KEY,
      license_key TEXT NOT NULL,
      hwid_hash TEXT NOT NULL,
      bound_at BIGINT NOT NULL,
      UNIQUE(license_key, hwid_hash)
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_license_hwids_key ON license_hwids(license_key)`;

  await sql`
    CREATE TABLE IF NOT EXISTS whitelist (
      id TEXT PRIMARY KEY,
      discord_user_id TEXT UNIQUE NOT NULL,
      discord_username TEXT NOT NULL,
      key_count INT NOT NULL DEFAULT 1,
      vip_role_assigned BOOLEAN NOT NULL DEFAULT FALSE,
      added_by TEXT NOT NULL,
      added_at BIGINT NOT NULL
    )
  `;

  await sql`
    CREATE TABLE IF NOT EXISTS user_keys (
      id TEXT PRIMARY KEY,
      discord_user_id TEXT NOT NULL,
      license_key TEXT NOT NULL,
      assigned_at BIGINT NOT NULL,
      UNIQUE(discord_user_id, license_key)
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_user_keys_user ON user_keys(discord_user_id)`;

  await sql`
    CREATE TABLE IF NOT EXISTS hwid_reset_log (
      id TEXT PRIMARY KEY,
      discord_user_id TEXT NOT NULL,
      license_key TEXT NOT NULL,
      reset_at BIGINT NOT NULL
    )
  `;
  await sql`CREATE INDEX IF NOT EXISTS idx_hwid_reset_user ON hwid_reset_log(discord_user_id, license_key)`;

  await sql`
    CREATE TABLE IF NOT EXISTS pending_tickets (
      discord_user_id TEXT PRIMARY KEY,
      channel_id TEXT NOT NULL,
      message_id TEXT NOT NULL,
      created_at BIGINT NOT NULL
    )
  `;
}

// ─── License functions ─────────────────────────────────────────────────────

export async function getByKey(licenseKey: string): Promise<License | null> {
  const rows = await sql<License[]>`SELECT * FROM licenses WHERE license_key = ${licenseKey}`;
  return rows[0] ?? null;
}

export async function insertLicenses(
  entries: Array<{
    id: string;
    licenseKey: string;
    durationType: string;
    durationValue: number;
    issuerDiscordId: string;
    createdAt: number;
    maxHwidResets?: number;
    hwidResetPeriod?: string;
  }>
): Promise<void> {
  await sql.begin(async (tx) => {
    for (const e of entries) {
      const maxResets = e.maxHwidResets ?? 1;
      const period = e.hwidResetPeriod ?? "WEEKLY";
      await tx`
        INSERT INTO licenses (id, license_key, duration_type, duration_value, issuer_discord_id, created_at, max_hwid_resets, hwid_reset_period)
        VALUES (${e.id}, ${e.licenseKey}, ${e.durationType}, ${e.durationValue}, ${e.issuerDiscordId}, ${e.createdAt}, ${maxResets}, ${period})
      `;
    }
  });
}

export async function activateLicense(hwidHash: string, expiresAt: number | null, licenseKey: string): Promise<void> {
  await sql`UPDATE licenses SET status = 'ACTIVE', hwid_hash = ${hwidHash}, expires_at = ${expiresAt} WHERE license_key = ${licenseKey}`;
}

export async function setHwid(hwidHash: string, licenseKey: string): Promise<void> {
  await sql`UPDATE licenses SET hwid_hash = ${hwidHash} WHERE license_key = ${licenseKey}`;
}

export async function resetHwid(licenseKey: string): Promise<void> {
  await sql.begin(async (tx) => {
    await tx`UPDATE licenses SET hwid_hash = NULL WHERE license_key = ${licenseKey}`;
    await tx`DELETE FROM license_hwids WHERE license_key = ${licenseKey}`;
  });
}

export async function resetHwidAndIncrementCount(licenseKey: string): Promise<void> {
  await sql.begin(async (tx) => {
    await tx`UPDATE licenses SET hwid_hash = NULL, hwid_reset_count = hwid_reset_count + 1 WHERE license_key = ${licenseKey}`;
    await tx`DELETE FROM license_hwids WHERE license_key = ${licenseKey}`;
  });
}

export async function revokeLicense(licenseKey: string): Promise<void> {
  await sql`UPDATE licenses SET status = 'REVOKED' WHERE license_key = ${licenseKey}`;
}

export async function expireLicense(licenseKey: string): Promise<void> {
  await sql`UPDATE licenses SET status = 'EXPIRED' WHERE license_key = ${licenseKey}`;
}

export async function setMaxHwidResets(licenseKey: string, maxResets: number, period: string): Promise<void> {
  await sql`UPDATE licenses SET max_hwid_resets = ${maxResets}, hwid_reset_period = ${period} WHERE license_key = ${licenseKey}`;
}

export async function setKeyLabel(licenseKey: string, label: string | null): Promise<void> {
  await sql`UPDATE licenses SET label = ${label} WHERE license_key = ${licenseKey}`;
}

export async function renewLicense(licenseKey: string, durationType: string, durationValue: number, expiresAt: number | null, status: string): Promise<void> {
  await sql`
    UPDATE licenses
    SET duration_type = ${durationType}, duration_value = ${durationValue},
        expires_at = ${expiresAt}, status = ${status}, notified_expire = FALSE
    WHERE license_key = ${licenseKey}
  `;
}

export async function deleteLicense(licenseKey: string): Promise<void> {
  await sql.begin(async (tx) => {
    await tx`DELETE FROM license_hwids WHERE license_key = ${licenseKey}`;
    await tx`DELETE FROM hwid_reset_log WHERE license_key = ${licenseKey}`;
    await tx`DELETE FROM user_keys WHERE license_key = ${licenseKey}`;
    await tx`DELETE FROM licenses WHERE license_key = ${licenseKey}`;
  });
}

// ─── Multi-HWID functions ──────────────────────────────────────────────────

export async function getHwidsForKey(licenseKey: string): Promise<LicenseHwid[]> {
  return sql<LicenseHwid[]>`SELECT * FROM license_hwids WHERE license_key = ${licenseKey} ORDER BY bound_at ASC`;
}

export async function addHwidToKey(licenseKey: string, hwidHash: string): Promise<void> {
  await sql`
    INSERT INTO license_hwids (id, license_key, hwid_hash, bound_at)
    VALUES (${randomUUID()}, ${licenseKey}, ${hwidHash}, ${Date.now()})
    ON CONFLICT (license_key, hwid_hash) DO NOTHING
  `;
}

export async function setMaxHwidCount(licenseKey: string, maxCount: number): Promise<void> {
  await sql`UPDATE licenses SET max_hwid_count = ${maxCount} WHERE license_key = ${licenseKey}`;
}

export async function setLicenseActive(licenseKey: string, expiresAt: number | null): Promise<void> {
  await sql`UPDATE licenses SET status = 'ACTIVE', expires_at = ${expiresAt} WHERE license_key = ${licenseKey}`;
}

export async function getLicenseStats(): Promise<LicenseStats> {
  const rows = await sql<Array<{ total: string; active: string; unused: string; expired: string; revoked: string }>>`
    SELECT
      COUNT(*)::text AS total,
      COUNT(*) FILTER (WHERE status = 'ACTIVE')::text AS active,
      COUNT(*) FILTER (WHERE status = 'UNUSED')::text AS unused,
      COUNT(*) FILTER (WHERE status = 'EXPIRED')::text AS expired,
      COUNT(*) FILTER (WHERE status = 'REVOKED')::text AS revoked
    FROM licenses
  `;
  const r = rows[0]!;
  return { total: Number(r.total), active: Number(r.active), unused: Number(r.unused), expired: Number(r.expired), revoked: Number(r.revoked) };
}

export async function getExpiringKeys(now: number, cutoff: number): Promise<ExpiringKeyRow[]> {
  return sql<ExpiringKeyRow[]>`
    SELECT l.license_key, l.expires_at, uk.discord_user_id
    FROM licenses l
    JOIN user_keys uk ON uk.license_key = l.license_key
    WHERE l.status = 'ACTIVE' AND l.expires_at IS NOT NULL
      AND l.expires_at > ${now} AND l.expires_at < ${cutoff} AND l.notified_expire = FALSE
  `;
}

export async function markNotifiedExpire(licenseKey: string): Promise<void> {
  await sql`UPDATE licenses SET notified_expire = TRUE WHERE license_key = ${licenseKey}`;
}

export async function cleanupOldKeys(cutoffCreatedAt: number): Promise<number> {
  const keys = await sql<{ license_key: string }[]>`
    SELECT license_key FROM licenses WHERE status IN ('EXPIRED', 'REVOKED') AND created_at < ${cutoffCreatedAt}
  `;
  if (keys.length === 0) return 0;
  await sql.begin(async (tx) => {
    for (const { license_key } of keys) {
      await tx`DELETE FROM hwid_reset_log WHERE license_key = ${license_key}`;
      await tx`DELETE FROM user_keys WHERE license_key = ${license_key}`;
      await tx`DELETE FROM licenses WHERE license_key = ${license_key}`;
    }
  });
  return keys.length;
}

// ─── Whitelist functions ───────────────────────────────────────────────────

export async function getWhitelistUser(discordUserId: string): Promise<WhitelistEntry | null> {
  const rows = await sql<WhitelistEntry[]>`SELECT * FROM whitelist WHERE discord_user_id = ${discordUserId}`;
  return rows[0] ?? null;
}

export async function addToWhitelist(entry: { id: string; discordUserId: string; discordUsername: string; keyCount: number; addedBy: string; addedAt: number }): Promise<void> {
  await sql`
    INSERT INTO whitelist (id, discord_user_id, discord_username, key_count, added_by, added_at)
    VALUES (${entry.id}, ${entry.discordUserId}, ${entry.discordUsername}, ${entry.keyCount}, ${entry.addedBy}, ${entry.addedAt})
    ON CONFLICT (discord_user_id) DO UPDATE SET
      discord_username = ${entry.discordUsername},
      key_count = whitelist.key_count + ${entry.keyCount},
      added_by = ${entry.addedBy},
      added_at = ${entry.addedAt}
  `;
}

export async function removeFromWhitelist(discordUserId: string): Promise<boolean> {
  const result = await sql`DELETE FROM whitelist WHERE discord_user_id = ${discordUserId}`;
  return (result.count ?? 0) > 0;
}

export async function getAllWhitelist(): Promise<WhitelistEntry[]> {
  return sql<WhitelistEntry[]>`SELECT * FROM whitelist ORDER BY added_at DESC`;
}

export async function setVipRoleAssigned(discordUserId: string): Promise<void> {
  await sql`UPDATE whitelist SET vip_role_assigned = TRUE WHERE discord_user_id = ${discordUserId}`;
}

export async function removeAllUserKeysAndLicenses(discordUserId: string): Promise<string[]> {
  const userKeys = await sql<UserKey[]>`SELECT * FROM user_keys WHERE discord_user_id = ${discordUserId}`;
  const licenseKeys = userKeys.map((uk) => uk.license_key);
  await sql.begin(async (tx) => {
    for (const key of licenseKeys) {
      await tx`DELETE FROM hwid_reset_log WHERE license_key = ${key}`;
      await tx`DELETE FROM licenses WHERE license_key = ${key}`;
    }
    await tx`DELETE FROM user_keys WHERE discord_user_id = ${discordUserId}`;
  });
  return licenseKeys;
}

// ─── User Keys functions ───────────────────────────────────────────────────

export async function getUserKeys(discordUserId: string): Promise<UserKey[]> {
  return sql<UserKey[]>`SELECT * FROM user_keys WHERE discord_user_id = ${discordUserId} ORDER BY assigned_at ASC`;
}

export async function assignKeyToUser(entry: { id: string; discordUserId: string; licenseKey: string; assignedAt: number }): Promise<void> {
  await sql`
    INSERT INTO user_keys (id, discord_user_id, license_key, assigned_at)
    VALUES (${entry.id}, ${entry.discordUserId}, ${entry.licenseKey}, ${entry.assignedAt})
    ON CONFLICT (discord_user_id, license_key) DO NOTHING
  `;
}

export async function getKeyOwner(licenseKey: string): Promise<UserKey | null> {
  const rows = await sql<UserKey[]>`SELECT * FROM user_keys WHERE license_key = ${licenseKey}`;
  return rows[0] ?? null;
}

export async function transferKey(licenseKey: string, newUserId: string): Promise<void> {
  await sql`UPDATE user_keys SET discord_user_id = ${newUserId} WHERE license_key = ${licenseKey}`;
}

// ─── HWID Reset Log functions ──────────────────────────────────────────────

export async function getLastHwidReset(discordUserId: string, licenseKey: string): Promise<HwidResetLog | null> {
  const rows = await sql<HwidResetLog[]>`
    SELECT * FROM hwid_reset_log
    WHERE discord_user_id = ${discordUserId} AND license_key = ${licenseKey}
    ORDER BY reset_at DESC LIMIT 1
  `;
  return rows[0] ?? null;
}

export async function logHwidReset(entry: { id: string; discordUserId: string; licenseKey: string; resetAt: number }): Promise<void> {
  await sql`
    INSERT INTO hwid_reset_log (id, discord_user_id, license_key, reset_at)
    VALUES (${entry.id}, ${entry.discordUserId}, ${entry.licenseKey}, ${entry.resetAt})
  `;
}

// ─── Pending Tickets ───────────────────────────────────────────────────────

export async function getPendingTicket(discordUserId: string): Promise<PendingTicket | null> {
  const rows = await sql<PendingTicket[]>`SELECT * FROM pending_tickets WHERE discord_user_id = ${discordUserId}`;
  return rows[0] ?? null;
}

export async function addPendingTicket(entry: { discordUserId: string; channelId: string; messageId: string; createdAt: number }): Promise<void> {
  await sql`
    INSERT INTO pending_tickets (discord_user_id, channel_id, message_id, created_at)
    VALUES (${entry.discordUserId}, ${entry.channelId}, ${entry.messageId}, ${entry.createdAt})
    ON CONFLICT (discord_user_id) DO UPDATE SET channel_id = ${entry.channelId}, message_id = ${entry.messageId}, created_at = ${entry.createdAt}
  `;
}

export async function removePendingTicket(discordUserId: string): Promise<void> {
  await sql`DELETE FROM pending_tickets WHERE discord_user_id = ${discordUserId}`;
}

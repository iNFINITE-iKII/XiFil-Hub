import { randomUUID } from "crypto";
import { db } from "@workspace/db";
import {
  licensesTable,
  licenseHwidsTable,
  botWhitelistTable,
  userKeysTable,
  hwidResetLogTable,
  pendingTicketsTable,
  trialKeyClaimsTable,
} from "@workspace/db";
import { eq, and, inArray, sql, desc, gt, lt, isNotNull } from "drizzle-orm";

// ─── Re-exported types (same shape as before — command files unchanged) ────
export type { License } from "@workspace/db";
export type { LicenseHwid } from "@workspace/db";
export type { WhitelistEntry } from "@workspace/db";
export type { UserKey } from "@workspace/db";
export type { HwidResetLog } from "@workspace/db";
export type { PendingTicket } from "@workspace/db";
export type { TrialKeyClaim } from "@workspace/db";

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

// ─── Database initialisation (idempotent DDL) ─────────────────────────────
export async function initDb(): Promise<void> {
  await db.execute(sql`
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
      max_hwid_count INT DEFAULT 3
    )
  `);
  await db.execute(sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS max_hwid_resets INT DEFAULT 1`);
  await db.execute(sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS hwid_reset_count INT DEFAULT 0`);
  await db.execute(sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS hwid_reset_period TEXT DEFAULT 'WEEKLY'`);
  await db.execute(sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS label TEXT DEFAULT NULL`);
  await db.execute(sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS notified_expire BOOLEAN DEFAULT FALSE`);
  await db.execute(sql`ALTER TABLE licenses ADD COLUMN IF NOT EXISTS max_hwid_count INT DEFAULT 3`);
  await db.execute(sql`CREATE INDEX IF NOT EXISTS idx_license_key ON licenses(license_key)`);

  await db.execute(sql`
    CREATE TABLE IF NOT EXISTS license_hwids (
      id TEXT PRIMARY KEY,
      license_key TEXT NOT NULL,
      hwid_hash TEXT NOT NULL,
      bound_at BIGINT NOT NULL,
      UNIQUE(license_key, hwid_hash)
    )
  `);
  await db.execute(sql`CREATE INDEX IF NOT EXISTS idx_license_hwids_key ON license_hwids(license_key)`);

  await db.execute(sql`
    CREATE TABLE IF NOT EXISTS whitelist (
      id TEXT PRIMARY KEY,
      discord_user_id TEXT UNIQUE NOT NULL,
      discord_username TEXT NOT NULL,
      key_count INT NOT NULL DEFAULT 1,
      vip_role_assigned BOOLEAN NOT NULL DEFAULT FALSE,
      added_by TEXT NOT NULL,
      added_at BIGINT NOT NULL
    )
  `);

  await db.execute(sql`
    CREATE TABLE IF NOT EXISTS user_keys (
      id TEXT PRIMARY KEY,
      discord_user_id TEXT NOT NULL,
      license_key TEXT NOT NULL,
      assigned_at BIGINT NOT NULL,
      UNIQUE(discord_user_id, license_key)
    )
  `);
  await db.execute(sql`CREATE INDEX IF NOT EXISTS idx_user_keys_user ON user_keys(discord_user_id)`);

  await db.execute(sql`
    CREATE TABLE IF NOT EXISTS hwid_reset_log (
      id TEXT PRIMARY KEY,
      discord_user_id TEXT NOT NULL,
      license_key TEXT NOT NULL,
      reset_at BIGINT NOT NULL
    )
  `);
  await db.execute(sql`CREATE INDEX IF NOT EXISTS idx_hwid_reset_user ON hwid_reset_log(discord_user_id, license_key)`);

  await db.execute(sql`
    CREATE TABLE IF NOT EXISTS pending_tickets (
      discord_user_id TEXT PRIMARY KEY,
      channel_id TEXT NOT NULL,
      message_id TEXT NOT NULL,
      created_at BIGINT NOT NULL
    )
  `);

  await db.execute(sql`
    CREATE TABLE IF NOT EXISTS trial_key_claims (
      discord_user_id TEXT PRIMARY KEY,
      license_key TEXT NOT NULL,
      claimed_at BIGINT NOT NULL
    )
  `);
}

// ─── License functions ─────────────────────────────────────────────────────

export async function getByKey(licenseKey: string) {
  const rows = await db
    .select()
    .from(licensesTable)
    .where(eq(licensesTable.license_key, licenseKey))
    .limit(1);
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
    maxHwidCount?: number;
  }>
): Promise<void> {
  await db.transaction(async (tx) => {
    for (const e of entries) {
      const maxResets = e.maxHwidResets ?? 1;
      const period = e.hwidResetPeriod ?? "WEEKLY";
      const maxHwidCount = e.maxHwidCount ?? (e.durationType === "PERMANENT" ? 3 : 1);
      await tx.insert(licensesTable).values({
        id: e.id,
        license_key: e.licenseKey,
        duration_type: e.durationType,
        duration_value: e.durationValue,
        issuer_discord_id: e.issuerDiscordId,
        created_at: e.createdAt,
        max_hwid_resets: maxResets,
        hwid_reset_period: period,
        max_hwid_count: maxHwidCount,
      });
    }
  });
}

export async function activateLicense(
  hwidHash: string,
  expiresAt: number | null,
  licenseKey: string
): Promise<void> {
  await db
    .update(licensesTable)
    .set({ status: "ACTIVE", hwid_hash: hwidHash, expires_at: expiresAt })
    .where(eq(licensesTable.license_key, licenseKey));
}

export async function setHwid(hwidHash: string, licenseKey: string): Promise<void> {
  await db
    .update(licensesTable)
    .set({ hwid_hash: hwidHash })
    .where(eq(licensesTable.license_key, licenseKey));
}

export async function resetHwid(licenseKey: string): Promise<void> {
  await db.transaction(async (tx) => {
    await tx
      .update(licensesTable)
      .set({ hwid_hash: null })
      .where(eq(licensesTable.license_key, licenseKey));
    await tx
      .delete(licenseHwidsTable)
      .where(eq(licenseHwidsTable.license_key, licenseKey));
  });
}

export async function resetHwidAndIncrementCount(licenseKey: string): Promise<void> {
  await db.transaction(async (tx) => {
    await tx
      .update(licensesTable)
      .set({
        hwid_hash: null,
        hwid_reset_count: sql`${licensesTable.hwid_reset_count} + 1`,
      })
      .where(eq(licensesTable.license_key, licenseKey));
    await tx
      .delete(licenseHwidsTable)
      .where(eq(licenseHwidsTable.license_key, licenseKey));
  });
}

export async function revokeLicense(licenseKey: string): Promise<void> {
  await db
    .update(licensesTable)
    .set({ status: "REVOKED" })
    .where(eq(licensesTable.license_key, licenseKey));
}

export async function expireLicense(licenseKey: string): Promise<void> {
  await db
    .update(licensesTable)
    .set({ status: "EXPIRED" })
    .where(eq(licensesTable.license_key, licenseKey));
}

export async function setMaxHwidResets(
  licenseKey: string,
  maxResets: number,
  period: string
): Promise<void> {
  await db
    .update(licensesTable)
    .set({ max_hwid_resets: maxResets, hwid_reset_period: period })
    .where(eq(licensesTable.license_key, licenseKey));
}

export async function setKeyLabel(licenseKey: string, label: string | null): Promise<void> {
  await db
    .update(licensesTable)
    .set({ label })
    .where(eq(licensesTable.license_key, licenseKey));
}

export async function renewLicense(
  licenseKey: string,
  durationType: string,
  durationValue: number,
  expiresAt: number | null,
  status: string
): Promise<void> {
  await db
    .update(licensesTable)
    .set({
      duration_type: durationType,
      duration_value: durationValue,
      expires_at: expiresAt,
      status,
      notified_expire: false,
    })
    .where(eq(licensesTable.license_key, licenseKey));
}

export async function deleteLicense(licenseKey: string): Promise<void> {
  await db.transaction(async (tx) => {
    await tx.delete(licenseHwidsTable).where(eq(licenseHwidsTable.license_key, licenseKey));
    await tx.delete(hwidResetLogTable).where(eq(hwidResetLogTable.license_key, licenseKey));
    await tx.delete(userKeysTable).where(eq(userKeysTable.license_key, licenseKey));
    await tx.delete(licensesTable).where(eq(licensesTable.license_key, licenseKey));
  });
}

// ─── Multi-HWID functions ──────────────────────────────────────────────────

export async function getHwidsForKey(licenseKey: string) {
  return db
    .select()
    .from(licenseHwidsTable)
    .where(eq(licenseHwidsTable.license_key, licenseKey))
    .orderBy(licenseHwidsTable.bound_at);
}

export async function addHwidToKey(licenseKey: string, hwidHash: string): Promise<void> {
  await db
    .insert(licenseHwidsTable)
    .values({
      id: randomUUID(),
      license_key: licenseKey,
      hwid_hash: hwidHash,
      bound_at: Date.now(),
    })
    .onConflictDoNothing();
}

export async function setMaxHwidCount(licenseKey: string, maxCount: number): Promise<void> {
  await db
    .update(licensesTable)
    .set({ max_hwid_count: maxCount })
    .where(eq(licensesTable.license_key, licenseKey));
}

export async function setLicenseActive(licenseKey: string, expiresAt: number | null): Promise<void> {
  await db
    .update(licensesTable)
    .set({ status: "ACTIVE", expires_at: expiresAt })
    .where(eq(licensesTable.license_key, licenseKey));
}

export async function getLicenseStats(): Promise<LicenseStats> {
  const result = await db
    .select({
      total: sql<number>`COUNT(*)::int`,
      active: sql<number>`COUNT(*) FILTER (WHERE ${licensesTable.status} = 'ACTIVE')::int`,
      unused: sql<number>`COUNT(*) FILTER (WHERE ${licensesTable.status} = 'UNUSED')::int`,
      expired: sql<number>`COUNT(*) FILTER (WHERE ${licensesTable.status} = 'EXPIRED')::int`,
      revoked: sql<number>`COUNT(*) FILTER (WHERE ${licensesTable.status} = 'REVOKED')::int`,
    })
    .from(licensesTable);
  const r = result[0]!;
  return {
    total: r.total,
    active: r.active,
    unused: r.unused,
    expired: r.expired,
    revoked: r.revoked,
  };
}

export async function getExpiringKeys(now: number, cutoff: number): Promise<ExpiringKeyRow[]> {
  const rows = await db
    .select({
      license_key: licensesTable.license_key,
      expires_at: licensesTable.expires_at,
      discord_user_id: userKeysTable.discord_user_id,
    })
    .from(licensesTable)
    .innerJoin(userKeysTable, eq(userKeysTable.license_key, licensesTable.license_key))
    .where(
      and(
        eq(licensesTable.status, "ACTIVE"),
        isNotNull(licensesTable.expires_at),
        gt(licensesTable.expires_at, now),
        lt(licensesTable.expires_at, cutoff),
        eq(licensesTable.notified_expire, false)
      )
    );
  return rows as ExpiringKeyRow[];
}

export async function markNotifiedExpire(licenseKey: string): Promise<void> {
  await db
    .update(licensesTable)
    .set({ notified_expire: true })
    .where(eq(licensesTable.license_key, licenseKey));
}

export async function cleanupOldKeys(cutoffCreatedAt: number): Promise<number> {
  const keys = await db
    .select({ license_key: licensesTable.license_key })
    .from(licensesTable)
    .where(
      and(
        inArray(licensesTable.status, ["EXPIRED", "REVOKED"]),
        lt(licensesTable.created_at, cutoffCreatedAt)
      )
    );
  if (keys.length === 0) return 0;
  const keyList = keys.map((k) => k.license_key);
  await db.transaction(async (tx) => {
    await tx.delete(hwidResetLogTable).where(inArray(hwidResetLogTable.license_key, keyList));
    await tx.delete(userKeysTable).where(inArray(userKeysTable.license_key, keyList));
    await tx.delete(licensesTable).where(inArray(licensesTable.license_key, keyList));
  });
  return keys.length;
}

// ─── Whitelist functions ───────────────────────────────────────────────────

export async function getWhitelistUser(discordUserId: string) {
  const rows = await db
    .select()
    .from(botWhitelistTable)
    .where(eq(botWhitelistTable.discord_user_id, discordUserId))
    .limit(1);
  return rows[0] ?? null;
}

export async function addToWhitelist(entry: {
  id: string;
  discordUserId: string;
  discordUsername: string;
  keyCount: number;
  addedBy: string;
  addedAt: number;
}): Promise<void> {
  await db
    .insert(botWhitelistTable)
    .values({
      id: entry.id,
      discord_user_id: entry.discordUserId,
      discord_username: entry.discordUsername,
      key_count: entry.keyCount,
      added_by: entry.addedBy,
      added_at: entry.addedAt,
    })
    .onConflictDoUpdate({
      target: botWhitelistTable.discord_user_id,
      set: {
        discord_username: entry.discordUsername,
        key_count: sql`${botWhitelistTable.key_count} + ${entry.keyCount}`,
        added_by: entry.addedBy,
        added_at: entry.addedAt,
      },
    });
}

export async function removeFromWhitelist(discordUserId: string): Promise<boolean> {
  const result = await db
    .delete(botWhitelistTable)
    .where(eq(botWhitelistTable.discord_user_id, discordUserId));
  return (result.rowCount ?? 0) > 0;
}

export async function getAllWhitelist() {
  return db
    .select()
    .from(botWhitelistTable)
    .orderBy(desc(botWhitelistTable.added_at));
}

export async function setVipRoleAssigned(discordUserId: string): Promise<void> {
  await db
    .update(botWhitelistTable)
    .set({ vip_role_assigned: true })
    .where(eq(botWhitelistTable.discord_user_id, discordUserId));
}

export async function removeAllUserKeysAndLicenses(discordUserId: string): Promise<string[]> {
  const userKeyRows = await db
    .select({ license_key: userKeysTable.license_key })
    .from(userKeysTable)
    .where(eq(userKeysTable.discord_user_id, discordUserId));
  const licenseKeys = userKeyRows.map((uk) => uk.license_key);
  if (licenseKeys.length > 0) {
    await db.transaction(async (tx) => {
      await tx.delete(hwidResetLogTable).where(inArray(hwidResetLogTable.license_key, licenseKeys));
      await tx.delete(licenseHwidsTable).where(inArray(licenseHwidsTable.license_key, licenseKeys));
      await tx.delete(licensesTable).where(inArray(licensesTable.license_key, licenseKeys));
    });
  }
  await db.delete(userKeysTable).where(eq(userKeysTable.discord_user_id, discordUserId));
  return licenseKeys;
}

// ─── User Keys functions ───────────────────────────────────────────────────

export async function getUserKeys(discordUserId: string) {
  return db
    .select()
    .from(userKeysTable)
    .where(eq(userKeysTable.discord_user_id, discordUserId))
    .orderBy(userKeysTable.assigned_at);
}

export async function assignKeyToUser(entry: {
  id: string;
  discordUserId: string;
  licenseKey: string;
  assignedAt: number;
}): Promise<void> {
  await db
    .insert(userKeysTable)
    .values({
      id: entry.id,
      discord_user_id: entry.discordUserId,
      license_key: entry.licenseKey,
      assigned_at: entry.assignedAt,
    })
    .onConflictDoNothing();
}

export async function getKeyOwner(licenseKey: string) {
  const rows = await db
    .select()
    .from(userKeysTable)
    .where(eq(userKeysTable.license_key, licenseKey))
    .limit(1);
  return rows[0] ?? null;
}

export async function transferKey(licenseKey: string, newUserId: string): Promise<void> {
  await db
    .update(userKeysTable)
    .set({ discord_user_id: newUserId })
    .where(eq(userKeysTable.license_key, licenseKey));
}

// ─── HWID Reset Log functions ──────────────────────────────────────────────

export async function getLastHwidReset(discordUserId: string, licenseKey: string) {
  const rows = await db
    .select()
    .from(hwidResetLogTable)
    .where(
      and(
        eq(hwidResetLogTable.discord_user_id, discordUserId),
        eq(hwidResetLogTable.license_key, licenseKey)
      )
    )
    .orderBy(desc(hwidResetLogTable.reset_at))
    .limit(1);
  return rows[0] ?? null;
}

export async function logHwidReset(entry: {
  id: string;
  discordUserId: string;
  licenseKey: string;
  resetAt: number;
}): Promise<void> {
  await db.insert(hwidResetLogTable).values({
    id: entry.id,
    discord_user_id: entry.discordUserId,
    license_key: entry.licenseKey,
    reset_at: entry.resetAt,
  });
}

// ─── Pending Tickets ───────────────────────────────────────────────────────

export async function getPendingTicket(discordUserId: string) {
  const rows = await db
    .select()
    .from(pendingTicketsTable)
    .where(eq(pendingTicketsTable.discord_user_id, discordUserId))
    .limit(1);
  return rows[0] ?? null;
}

export async function addPendingTicket(entry: {
  discordUserId: string;
  channelId: string;
  messageId: string;
  createdAt: number;
}): Promise<void> {
  await db
    .insert(pendingTicketsTable)
    .values({
      discord_user_id: entry.discordUserId,
      channel_id: entry.channelId,
      message_id: entry.messageId,
      created_at: entry.createdAt,
    })
    .onConflictDoUpdate({
      target: pendingTicketsTable.discord_user_id,
      set: {
        channel_id: entry.channelId,
        message_id: entry.messageId,
        created_at: entry.createdAt,
      },
    });
}

export async function removePendingTicket(discordUserId: string): Promise<void> {
  await db
    .delete(pendingTicketsTable)
    .where(eq(pendingTicketsTable.discord_user_id, discordUserId));
}

// ─── Trial Key functions ───────────────────────────────────────────────────

export async function getTrialKeyClaim(discordUserId: string) {
  const rows = await db
    .select()
    .from(trialKeyClaimsTable)
    .where(eq(trialKeyClaimsTable.discord_user_id, discordUserId))
    .limit(1);
  return rows[0] ?? null;
}

export async function saveTrialKeyClaim(
  discordUserId: string,
  licenseKey: string,
  claimedAt: number
): Promise<void> {
  await db
    .insert(trialKeyClaimsTable)
    .values({
      discord_user_id: discordUserId,
      license_key: licenseKey,
      claimed_at: claimedAt,
    })
    .onConflictDoNothing();
}

// ─── Premium key functions ─────────────────────────────────────────────────

export async function userHasPremiumKey(discordUserId: string): Promise<boolean> {
  const result = await db
    .select({ count: sql<number>`COUNT(*)::int` })
    .from(userKeysTable)
    .innerJoin(licensesTable, eq(licensesTable.license_key, userKeysTable.license_key))
    .where(
      and(
        eq(userKeysTable.discord_user_id, discordUserId),
        eq(licensesTable.duration_type, "PERMANENT"),
        inArray(licensesTable.status, ["ACTIVE", "UNUSED"])
      )
    );
  return (result[0]?.count ?? 0) > 0;
}

export async function getAllPremiumEligibleUserIds(): Promise<string[]> {
  const rows = await db
    .selectDistinct({ discord_user_id: userKeysTable.discord_user_id })
    .from(userKeysTable)
    .innerJoin(licensesTable, eq(licensesTable.license_key, userKeysTable.license_key))
    .where(
      and(
        eq(licensesTable.duration_type, "PERMANENT"),
        inArray(licensesTable.status, ["ACTIVE", "UNUSED"])
      )
    );
  return rows.map((r) => r.discord_user_id);
}

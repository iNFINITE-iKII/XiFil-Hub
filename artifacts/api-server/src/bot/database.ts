import postgres from "postgres";

const connectionString = process.env["DATABASE_URL"];
if (!connectionString) {
  throw new Error("DATABASE_URL environment variable is required but was not provided.");
}

export const sql = postgres(connectionString, {
  ssl: "require",
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
      created_at BIGINT NOT NULL
    )
  `;
  await sql`
    CREATE INDEX IF NOT EXISTS idx_license_key ON licenses(license_key)
  `;
}

export async function getByKey(licenseKey: string): Promise<License | null> {
  const rows = await sql<License[]>`
    SELECT * FROM licenses WHERE license_key = ${licenseKey}
  `;
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
  }>
): Promise<void> {
  await sql.begin(async (tx) => {
    for (const e of entries) {
      await tx`
        INSERT INTO licenses (id, license_key, duration_type, duration_value, issuer_discord_id, created_at)
        VALUES (${e.id}, ${e.licenseKey}, ${e.durationType}, ${e.durationValue}, ${e.issuerDiscordId}, ${e.createdAt})
      `;
    }
  });
}

export async function activateLicense(
  hwidHash: string,
  expiresAt: number | null,
  licenseKey: string
): Promise<void> {
  await sql`
    UPDATE licenses SET status = 'ACTIVE', hwid_hash = ${hwidHash}, expires_at = ${expiresAt}
    WHERE license_key = ${licenseKey}
  `;
}

export async function setHwid(hwidHash: string, licenseKey: string): Promise<void> {
  await sql`
    UPDATE licenses SET hwid_hash = ${hwidHash} WHERE license_key = ${licenseKey}
  `;
}

export async function resetHwid(licenseKey: string): Promise<void> {
  await sql`
    UPDATE licenses SET hwid_hash = NULL WHERE license_key = ${licenseKey}
  `;
}

export async function revokeLicense(licenseKey: string): Promise<void> {
  await sql`
    UPDATE licenses SET status = 'REVOKED' WHERE license_key = ${licenseKey}
  `;
}

export async function expireLicense(licenseKey: string): Promise<void> {
  await sql`
    UPDATE licenses SET status = 'EXPIRED' WHERE license_key = ${licenseKey}
  `;
}

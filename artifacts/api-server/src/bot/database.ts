import BetterSqlite3 from "better-sqlite3";
import { mkdirSync } from "fs";
import path from "path";

const dataDir = path.join(process.cwd(), "data");
mkdirSync(dataDir, { recursive: true });

export const db = new BetterSqlite3(path.join(dataDir, "licenses.db"));
db.pragma("journal_mode = WAL");

db.exec(`
  CREATE TABLE IF NOT EXISTS licenses (
    id TEXT PRIMARY KEY,
    license_key TEXT UNIQUE NOT NULL,
    duration_type TEXT NOT NULL,
    duration_value INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'UNUSED',
    hwid_hash TEXT DEFAULT NULL,
    expires_at INTEGER DEFAULT NULL,
    issuer_discord_id TEXT NOT NULL,
    created_at INTEGER NOT NULL
  );
  CREATE INDEX IF NOT EXISTS idx_license_key ON licenses(license_key);
`);

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

export const stmtGetByKey = db.prepare<[string], License>(
  "SELECT * FROM licenses WHERE license_key = ?"
);

export const stmtInsert = db.prepare<
  [string, string, string, number, string, number]
>(
  `INSERT INTO licenses (id, license_key, duration_type, duration_value, issuer_discord_id, created_at)
   VALUES (?, ?, ?, ?, ?, ?)`
);

export const stmtActivate = db.prepare<[string, number, string]>(
  `UPDATE licenses SET status = 'ACTIVE', hwid_hash = ?, expires_at = ? WHERE license_key = ?`
);

export const stmtSetHwid = db.prepare<[string, string]>(
  "UPDATE licenses SET hwid_hash = ? WHERE license_key = ?"
);

export const stmtResetHwid = db.prepare<[string]>(
  "UPDATE licenses SET hwid_hash = NULL WHERE license_key = ?"
);

export const stmtRevoke = db.prepare<[string]>(
  "UPDATE licenses SET status = 'REVOKED' WHERE license_key = ?"
);

export const stmtExpire = db.prepare<[string]>(
  "UPDATE licenses SET status = 'EXPIRED' WHERE license_key = ?"
);

import pg from "pg";
const { Pool } = pg;
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const migrations = [
  // licenses table (main table)
  `CREATE TABLE IF NOT EXISTS licenses (
    id TEXT PRIMARY KEY,
    license_key TEXT NOT NULL UNIQUE,
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
  )`,

  // license_hwids table
  `CREATE TABLE IF NOT EXISTS license_hwids (
    id TEXT PRIMARY KEY,
    license_key TEXT NOT NULL,
    hwid_hash TEXT NOT NULL,
    bound_at BIGINT NOT NULL,
    UNIQUE (license_key, hwid_hash)
  )`,

  // whitelist table
  `CREATE TABLE IF NOT EXISTS whitelist (
    id TEXT PRIMARY KEY,
    discord_user_id TEXT NOT NULL UNIQUE,
    discord_username TEXT NOT NULL,
    key_count INTEGER NOT NULL DEFAULT 1,
    vip_role_assigned BOOLEAN NOT NULL DEFAULT FALSE,
    added_by TEXT NOT NULL,
    added_at BIGINT NOT NULL
  )`,

  // user_keys table
  `CREATE TABLE IF NOT EXISTS user_keys (
    id TEXT PRIMARY KEY,
    discord_user_id TEXT NOT NULL,
    license_key TEXT NOT NULL,
    assigned_at BIGINT NOT NULL,
    UNIQUE (discord_user_id, license_key)
  )`,

  // hwid_reset_log table
  `CREATE TABLE IF NOT EXISTS hwid_reset_log (
    id TEXT PRIMARY KEY,
    discord_user_id TEXT NOT NULL,
    license_key TEXT NOT NULL,
    reset_at BIGINT NOT NULL
  )`,

  // pending_tickets table
  `CREATE TABLE IF NOT EXISTS pending_tickets (
    discord_user_id TEXT PRIMARY KEY,
    channel_id TEXT NOT NULL,
    message_id TEXT NOT NULL,
    created_at BIGINT NOT NULL
  )`,

  // trial_key_claims table
  `CREATE TABLE IF NOT EXISTS trial_key_claims (
    discord_user_id TEXT PRIMARY KEY,
    license_key TEXT NOT NULL,
    claimed_at BIGINT NOT NULL
  )`,

  // users table
  `CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    discord_id TEXT NOT NULL UNIQUE,
    username TEXT NOT NULL,
    avatar TEXT,
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
  )`,

  // games table
  `CREATE TABLE IF NOT EXISTS games (
    id SERIAL PRIMARY KEY,
    slug TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
  )`,
];

try {
  for (const sql of migrations) {
    await pool.query(sql);
    console.log("✅", sql.trim().split('\n')[0].substring(0, 70));
  }
  console.log("\n🎉 All tables created successfully! Database is ready.");
} catch (err) {
  console.error("❌ Migration failed:", err.message);
  process.exit(1);
} finally {
  await pool.end();
}

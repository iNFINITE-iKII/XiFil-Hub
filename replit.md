# XiFil Hub

Bot Discord untuk manajemen lisensi game, dengan REST API untuk verifikasi key dari script Lua.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — jalankan API server + Discord bot (port 8080)
- `pnpm run typecheck` — full typecheck seluruh package
- `pnpm run build` — typecheck + build semua package
- `pnpm --filter @workspace/db run push` — push DB schema ke Neon PostgreSQL
- `pnpm --filter @workspace/db run push-force` — push DB schema (force, skip prompt)

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- API: Express 5
- DB: PostgreSQL (Neon) + Drizzle ORM, menggunakan `NEON_DATABASE_URL`
- Bot: Discord.js v14
- Logging: Pino
- Build: esbuild (ESM bundle)

## Where things live

- `artifacts/api-server/src/bot/` — Discord bot (commands, events, handlers, utils)
- `artifacts/api-server/src/routes/` — Express routes (keys, admin, auth, games, lua, loader, license)
- `artifacts/api-server/src/lib/` — Logger, Discord logger, expire notifier
- `artifacts/api-server/lua/` — Lua scripts untuk game
- `lib/db/src/schema/` — Drizzle schema (licenses, users, games, hwids, whitelist, tickets, dll)
- `lib/api-spec/openapi.yaml` — OpenAPI spec

## Architecture Decisions

- Bot dan API server berjalan dalam satu proses Node.js (satu workflow)
- Database diinisialisasi dengan DDL idempotent (`CREATE TABLE IF NOT EXISTS`) + `ALTER TABLE ADD COLUMN IF NOT EXISTS` untuk migrasi incremental
- `NEON_DATABASE_URL` digunakan sebagai satu-satunya koneksi database (bukan `DATABASE_URL`)
- Slash commands didaftarkan ke guild spesifik saat bot `ready` (bukan global, lebih cepat)
- `safeDefer` wrapper menangani Discord error 10062 (expired interaction) tanpa crash

## Product

- Generate, revoke, renew, transfer, dan cek lisensi key via Discord slash commands
- HWID binding dan reset management
- Panel ticket Discord untuk support
- VIP/Premium role sync otomatis
- Expire notifier: notifikasi Discord ke user saat key hampir habis
- REST API untuk loader Lua script (verifikasi key dari dalam game)
- Admin panel via Discord commands

## User Preferences

- Bot menggunakan Neon PostgreSQL (`NEON_DATABASE_URL`)
- Semua response bot dalam Bahasa Indonesia

## Gotchas

- `NEON_DATABASE_URL` harus di-set sebagai secret, bukan env var biasa
- Setelah menambah schema baru, jalankan `pnpm --filter @workspace/db run push`
- `discord.js` v14: event `ready` deprecated, gunakan `clientReady`
- Static frontend dicari di `artifacts/xifil-hub/dist/public` (opsional, 404 ditangani gracefully)

## Secrets Required

- `NEON_DATABASE_URL` — Neon PostgreSQL connection string
- `DISCORD_BOT_TOKEN` — Discord bot token
- `DISCORD_CLIENT_SECRET` — Discord OAuth2 client secret
- `SESSION_SECRET` — Express session secret

## Env Vars (non-secret)

- `DISCORD_CLIENT_ID` — Discord application client ID
- `DISCORD_GUILD_ID` — Discord server/guild ID
- `TICKET_CHANNEL_ID` — Channel ID untuk ticket panel
- `TICKET_STAFF_ROLE_ID` — Role ID untuk staff ticket
- `VIP_ROLE_NAME` — Nama role VIP (default: PREMIUM)
- `MAIN_SCRIPT_URL` — URL Lua script utama
- `NODE_ENV` — production / development

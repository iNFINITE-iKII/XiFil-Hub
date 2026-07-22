---
name: XiFil Hub Bot Setup
description: Key decisions and quirks for the XiFil Hub Discord bot + API server project
---

# XiFil Hub Bot

## Database
- Uses `NEON_DATABASE_URL` (not `DATABASE_URL` which is runtime-managed by Replit)
- `lib/db/src/index.ts` reads `NEON_DATABASE_URL` for the pg Pool
- `drizzle.config.ts` also reads `NEON_DATABASE_URL`
- Schema initialized in `initDb()` with idempotent DDL (CREATE TABLE IF NOT EXISTS + ALTER TABLE ADD COLUMN IF NOT EXISTS)

**Why:** Neon PostgreSQL is the chosen DB provider; Replit runtime manages DATABASE_URL for its own Replit DB which is not used here.

**How to apply:** Never use DATABASE_URL for this project. Push schema with `pnpm --filter @workspace/db run push`.

## Bot Architecture
- Bot and API run in a single Node.js process (one workflow: `artifacts/api-server: API Server`)
- Slash commands registered to guild on ready (not global) for instant updates
- `safeDefer` util in `src/bot/utils/safeDefer.ts` handles Discord error 10062 (expired interaction)
- `clientRef.ts` holds singleton Discord Client for access from routes

**Why:** Single process is simpler to operate on Railway/Replit; guild commands update instantly vs 1hr for global.

## Session
- Uses connect-pg-simple + express-session with Neon pool
- Table `session` auto-created by `createTableIfMissing: true`
- SESSION_SECRET must be set as a Replit secret

## File Layout
- Bot code: `artifacts/api-server/src/bot/`
- Commands: `artifacts/api-server/src/bot/commands/` (19 commands)
- Lua scripts: `artifacts/api-server/lua/games/`
- All schemas exported from `lib/db/src/schema/index.ts`

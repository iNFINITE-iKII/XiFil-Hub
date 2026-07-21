# XiFil Hub

API server + Discord bot untuk manajemen license key Roblox script dengan sistem whitelist, HWID binding, dan key management.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the API server (port 8080)
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)

## Required Environment Variables

- `DATABASE_URL` — Postgres connection string
- `SESSION_SECRET` — Secret for express-session
- `DISCORD_BOT_TOKEN` — Discord bot token
- `DISCORD_CLIENT_ID` — Discord application client ID
- `DISCORD_GUILD_ID` — Target Discord guild/server ID
- `VIP_ROLE_NAME` — Name of the VIP role (default: "VIP")
- `PREMIUM_ROLE_NAME` — Name of the Premium role (default: "PREMIUM")

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- API: Express 5
- DB: PostgreSQL + Drizzle ORM
- Discord: discord.js v14
- Validation: Zod (`zod/v4`), `drizzle-zod`
- API codegen: Orval (from OpenAPI spec)
- Build: esbuild (ESM bundle)

## Where things live

- `artifacts/api-server/src/bot/` — Discord bot (commands, events, handlers)
- `artifacts/api-server/src/routes/` — Express API routes
- `artifacts/api-server/src/bot/database.ts` — Bot's raw SQL database layer (postgres)
- `artifacts/api-server/src/lib/` — discordLogger, expireNotifier
- `artifacts/api-server/lua/` — Lua scripts served to Roblox clients
- `lib/db/src/schema/` — Drizzle ORM schema (users, games tables)

## Architecture decisions

- Bot uses its own raw `postgres` connection (`bot/database.ts`) for license/whitelist tables — separate from Drizzle ORM used for users/games tables.
- Interaction error 10062 (Unknown interaction / expired token) is handled gracefully in `interactionCreate.ts` — bot logs a warning and skips the response attempt instead of throwing.
- HWID reset cooldown enforced per-user per-key with configurable period (DAILY/WEEKLY/MONTHLY/UNLIMITED).
- Expire notifier runs every hour via `setInterval` after bot ready.

## Gotchas

- Bot won't start without `DISCORD_BOT_TOKEN` set — this is intentional and logged as a warning.
- Discord interaction tokens expire after **3 seconds** — `deferReply` must be the very first call in every command execute function.
- The `bot/database.ts` uses raw `postgres` (sql tagged template), not Drizzle ORM.

## User preferences

_Populate as you build — explicit user instructions worth remembering across sessions._

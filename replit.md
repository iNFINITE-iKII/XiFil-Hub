# Discord DRM License Bot

A Discord bot + REST API for managing software license keys with HWID locking, temporal licenses, and professional slash commands.

## Run & Operate

- `PORT=8000 pnpm --filter @workspace/api-server run dev` — run the API server + Discord bot (port 8000)
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- Required env: `DISCORD_BOT_TOKEN`, `DISCORD_CLIENT_ID`, `DISCORD_GUILD_ID`

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- Discord: discord.js v14 (slash commands, ephemeral responses, EmbedBuilder)
- Database: SQLite via better-sqlite3 (stored at `data/licenses.db`)
- API: Express 5 + express-rate-limit
- Build: esbuild (CJS bundle)

## Where things live

- `artifacts/api-server/src/bot/` — Discord bot (commands, events, database, utils)
- `artifacts/api-server/src/bot/commands/` — Slash commands (genkey, checkkey, sethwid, resethwid, revoke)
- `artifacts/api-server/src/bot/database.ts` — SQLite schema + prepared statements
- `artifacts/api-server/src/routes/license.ts` — REST API: `POST /api/license/activate`
- `data/licenses.db` — SQLite database (created at runtime)

## Architecture decisions

- **Lazy expiry**: `expires_at` is NULL when key is created; timer starts only on first API activation call
- **HWID Lock**: First activation binds the device hash; subsequent calls verify the same hash
- **Ephemeral responses**: All bot command responses are ephemeral (only visible to the executor)
- **Guild commands**: Slash commands registered per-guild on bot startup (instant propagation)
- **Separate process model**: Bot and Express API run in the same Node.js process

## Product

### Slash Commands (Admin only unless noted)
- `/genkey [type] [duration] [amount]` — Generate 1–50 cryptographically secure license keys
- `/checkkey [key]` — View key status, HWID binding, and countdown timer (all roles)
- `/sethwid [key] [hwid]` — Manually bind HWID (admin override)
- `/resethwid [key]` — Reset HWID — Admin: always; VIP: 1x per 7 days (own keys only)
- `/setmaxhwid [key] [max]` — Set max HWID reset limit per key (-1 = unlimited)
- `/revoke [key]` — Permanently block a key
- `/whitelist add [user] [key_count]` — Whitelist user + auto-generate PERMANENT keys for them
- `/whitelist remove [user]` — Remove user from whitelist
- `/whitelist list` — View all whitelisted users
- `/userkey [user]` — See all keys owned by a user
- `/userkey [key]` — See who owns a specific key
- `/panel` — Post interactive VIP panel with buttons to current channel
- `POST /api/license/activate` — Client software calls this to activate/verify a license

### Panel Buttons (posted via /panel)
- 🎖️ **Get Role VIP** — Checks whitelist, assigns VIP role automatically
- 🔑 **Get Key** — Shows user their assigned license keys (ephemeral)
- 📜 **Get Script** — Shows Roblox loadstring script (VIP only, ephemeral)

### VIP Features
- VIP can use `/resethwid` on their own keys (1x per 7 days cooldown)
- VIP can click Get Role, Get Key, Get Script buttons in panel

## Environment Variables

- `DISCORD_BOT_TOKEN`, `DISCORD_CLIENT_ID`, `DISCORD_GUILD_ID` — Discord bot credentials
- `VIP_ROLE_NAME` — Name of the VIP Discord role (default: `VIP`)

## REST API

```
POST /api/license/activate
Body: { "license_key": "XXXX-XXXX-XXXX-XXXX", "hwid": "sha256-hash-of-hardware" }

Responses:
  200 ACTIVATED   — First activation (hwid bound, timer starts)
  200 AUTHORIZED  — Valid key + matching HWID
  401 EXPIRED     — License has expired
  403 REVOKED     — Key has been revoked by admin
  403 HWID_MISMATCH — Wrong device
  404 NOT_FOUND   — Key doesn't exist
  429 RATE_LIMITED — Too many requests (10/min limit)
```

## Setup (first time)

1. Go to Discord Developer Portal → Your App → OAuth2 → URL Generator
2. Select scopes: `bot` + `applications.commands`
3. Select permissions: `Administrator`
4. Use the generated URL to invite the bot to your server
5. Set env secrets: `DISCORD_BOT_TOKEN`, `DISCORD_CLIENT_ID`, `DISCORD_GUILD_ID`
6. Bot auto-registers slash commands on startup

## User preferences

_Populate as you build — explicit user instructions worth remembering across sessions._

## Gotchas

- better-sqlite3 must be in `onlyBuiltDependencies` in pnpm-workspace.yaml (native module)
- discord.js must be in `external` list in build.mjs (complex ESM package)
- Slash commands only appear after bot is in the guild AND has `applications.commands` scope
- `CommandInteraction` doesn't have `.options` in discord.js v14 — use `ChatInputCommandInteraction`

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details

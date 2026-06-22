---
name: Soul Iron Module System
description: Architecture of the XIFIL Hub PRO Lua script — module separation, ctx pattern, new EngineConfig keys, and key bug fixes implemented.
---

## Module Loading Pattern
- Each module receives shared `ctx` table via `...` argument
- Loading order MUST be: core → combat → farm → background → gui
- Route: `GET /api/lua/module/soul_iron/:name` (added to lua.ts)
- Security: both `:game` and `:name` sanitized + path.startsWith(LUA_DIR) check

## New EngineConfig Keys (vs old)
| Old | New |
|---|---|
| AutoFarmMonster | AutoFarm (master) + FarmMonster (sub) |
| AutoSearchMonster | AutoFind |
| AutoChestActive | FarmChest |
| AutoEggActive | FarmEgg |

## Key Bug Fixes
1. **Non-blocking search**: `triggerSearch()` uses `task.spawn` + `ctx._searchInterrupt` flag; farm loop calls it and immediately continues
2. **115s stall removed**: `idleWaitInterruptable(120, shouldBreak, ...)` polls every 5s with interrupt check
3. **Victory detection**: `pGui.DescendantAdded` event (not per-frame polling); calls `ctx.OnVictoryDetected` callback
4. **Egg Phase 1 fix**: CFrame to egg + `task.defer(fireproximityprompt)` simultaneously (no sequential blocking)
5. **xpcall wraps farm loop**: errors caught, AutoFarm disabled cleanly, GUI notified via `ctx.GUI_OnFarmDisabled`

## GUI New Features
- 7 color themes: Cyan/Red/Purple/Gold/Green/Emerald/RGB (RGB = RunService heartbeat hue loop)
- Transparency slider in Settings tab (0–88%)
- Gesture open: "Slide" (drag right >55px from float btn) or "Click" toggle
- Resizable window: drag handle at bottom-right corner (440–720 × 380–560)
- Farm sub-targets: 3 pill buttons (Monster/Chest/Egg) shown in Farm tab
- RuntimeMaid stored in `getgenv().XiFilRuntimeMaid` for cleanup on re-execution

## ctx Callbacks (decoupled circular deps)
- `ctx.OnVictoryDetected` — set by farm.lua, called by combat.lua event
- `ctx.GUI_OnFarmDisabled` — set by gui.lua, called by DisableAutoFarm in farm.lua

**Why:** Direct references between modules would create circular dependencies. Callbacks decouple them cleanly.

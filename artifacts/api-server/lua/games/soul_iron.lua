--------------------------------------------------------------------------------
-- XIFIL Hub PRO // Iron Soul V5 — Orchestrator
-- Memuat semua modul secara berurutan via HTTP
-- URL loadstring: loadstring(game:HttpGet("https://xifil-hub-production.up.railway.app/api/lua/loader?game=soul_iron"))()
--------------------------------------------------------------------------------

local BASE = "https://xifil-hub-production.up.railway.app"

-- Shared context table — setiap modul menerima dan mengisi tabel ini
local ctx = {}

-- Helper: load & execute module, pass ctx sebagai argument
local function loadMod(name)
    local url = BASE .. "/api/lua/module/soul_iron/" .. name
    local ok, result = pcall(function()
        local fn = loadstring(game:HttpGet(url, true))
        if not fn then error("loadstring nil for: " .. name) end
        fn(ctx)
    end)
    if not ok then
        -- Tampilkan error di output dan lanjutkan (jangan crash script)
        warn("[XiFil] Gagal memuat modul '" .. name .. "': " .. tostring(result))
    end
end

-- ── Load modules dalam urutan yang benar ──────────────────────────────────────
-- 1. Core: Services, EngineConfig, Maid, Notify, ConfigSystem
loadMod("core")

-- 2. Combat: CombatEngine, Navigation (fixed bugs), victory detection
loadMod("combat")

-- 3. Farm: startFarmLoop (new priority system + egg fix + non-blocking search)
loadMod("farm")

-- 4. Background: Auto Skill, Weapon Switch, Auto Buy, Forge hook
loadMod("background")

-- 5. GUI: Full redesign (themes, transparency, gesture, resize, multi-select)
loadMod("gui")

-- ── Done ──────────────────────────────────────────────────────────────────────
print("[XiFil] Semua modul berhasil dimuat.")

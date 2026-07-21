--------------------------------------------------------------------------------
--// ui/tab_farm.lua — S17 Tab 1: Main Farm
--------------------------------------------------------------------------------
local H               = getgenv().Hub
local EngineConfig    = H.EngineConfig
local WORLD_NAMES     = H.WORLD_NAMES
local POSITION_MODES  = H.POSITION_MODES
local GameLists       = H.GameLists
local startFarmLoop   = H.startFarmLoop
local checkVictoryUi  = H.checkVictoryUi
local DisableAutoFarm = H.DisableAutoFarm
local CombatEngine    = H.CombatEngine
local CustomNotify    = H.CustomNotify
local CreateTab         = H.CreateTab
local CreateSection     = H.CreateSection
local CreateToggleUI    = H.CreateToggleUI
local CreateCycleUI     = H.CreateCycleUI
local CreateDropdownUI  = H.CreateDropdownUI
local CreateButton      = H.CreateButton
local CreateInputUI     = H.CreateInputUI
local CreateMultiCheckUI = H.CreateMultiCheckUI

-- [S17] TAB 1 — MAIN FARM
--------------------------------------------------------------------------------
local MainFarmPage = CreateTab("🏠 Farm", "tabFarm")

CreateSection(MainFarmPage, "World", "secWorld")
_G.WorldDropdown = CreateCycleUI(MainFarmPage, "🌍 World", WORLD_NAMES, EngineConfig.SelectedWorld, function(v)
    EngineConfig.SelectedWorld = v
end)

CreateSection(MainFarmPage, "Farm Engine Control", "secFarmEngine")

_G.AutoFarmToggle = CreateToggleUI(MainFarmPage, "🌾 Auto Farm", EngineConfig.AutoFarmActive, function(v)
    EngineConfig.AutoFarmActive = v
    if v then
        if checkVictoryUi() then task.spawn(function() DisableAutoFarm("Victory aktif.") end)
        else task.spawn(startFarmLoop) end
    end
end, "lblAutoFarm")
-- Daftarkan ke combat.lua agar DisableAutoFarm bisa reset toggle lewat H.SetToggleControl
if H.SetToggleControl then H.SetToggleControl(_G.AutoFarmToggle) end

local _farmTargetApis = CreateMultiCheckUI(
    MainFarmPage,
    "Auto Farm Target  (aktif saat Auto Farm ON)",
    {"🗡️ Monster", "📦 Chest", "🥚 Egg"},
    {EngineConfig.FarmTargetMonster, EngineConfig.FarmTargetChest, EngineConfig.FarmTargetEgg},
    {
        function(v) EngineConfig.FarmTargetMonster = v end,
        function(v) EngineConfig.FarmTargetChest = v end,
        function(v) EngineConfig.FarmTargetEgg = v end,
    }
)
_G.TargetMonsterToggle = _farmTargetApis[1]
_G.TargetChestToggle   = _farmTargetApis[2]
_G.TargetEggToggle     = _farmTargetApis[3]

CreateSection(MainFarmPage, "Metode & Posisi Gerakan", "secMethodPos")
_G.FarmMethodDropdown   = CreateCycleUI(MainFarmPage, "Metode", {"CFrame","Lerp"}, EngineConfig.FarmMethod, function(v) EngineConfig.FarmMethod = v end)
_G.FarmPositionDropdown = CreateDropdownUI(MainFarmPage, "Posisi Farm", POSITION_MODES, EngineConfig.FarmPosition, function(v) EngineConfig.FarmPosition = v end, "lblPosition")

CreateSection(MainFarmPage, "Skill Config", "secSkillCfg")

_G.AutoAttackOnlyToggle = CreateToggleUI(MainFarmPage, "⚡ Kill Aura", EngineConfig.AutoAttackOnly, function(v) EngineConfig.AutoAttackOnly = v end, "lblKillAura")
_G.AutoSkillToggle      = CreateToggleUI(MainFarmPage, "🎯 Enable Auto Skill", EngineConfig.AutoSkillActive, function(v)
    EngineConfig.AutoSkillActive = v; if v then CustomNotify("⚔️ SKILL","Auto Skill AKTIF!",2) end
end, "lblAutoSkill")

local _skillApis = CreateMultiCheckUI(
    MainFarmPage,
    "Skill Aktif  (bisa pilih lebih dari 1)",
    {"Skill 1","Skill 2","Skill U","Skill Scroll"},
    {EngineConfig.SkillActive1, EngineConfig.SkillActive2, EngineConfig.SkillActiveU, EngineConfig.SkillActiveAW},
    {
        function(v) EngineConfig.SkillActive1  = v end,
        function(v) EngineConfig.SkillActive2  = v end,
        function(v) EngineConfig.SkillActiveU  = v end,
        function(v) EngineConfig.SkillActiveAW = v end,
    }
)
_G.SkillActive1Toggle  = _skillApis[1]
_G.SkillActive2Toggle  = _skillApis[2]
_G.SkillActiveUToggle  = _skillApis[3]
_G.SkillActiveAWToggle = _skillApis[4]

CreateSection(MainFarmPage, "Weapon Switcher", "secWeapon")
_G.AutoSwitchToggle = CreateToggleUI(MainFarmPage, "🎒 Auto Weapon Switcher (3s)", EngineConfig.AutoWeaponSwitchActive, function(v)
    EngineConfig.AutoWeaponSwitchActive = v; if v then CustomNotify("🎒 WEAPON","Switcher AKTIF!",2) end
end, "lblWeaponSwitch")

CreateSection(MainFarmPage, "Terbang (Fly)", "secFly")
_G.FlyToggle = CreateToggleUI(MainFarmPage, "✈️ Terbang", EngineConfig.FlyActive, function(v)
    EngineConfig.FlyActive = v
    if v then
        CustomNotify("✈️ FLY", "Fly AKTIF!  Joystick/WASD = gerak · Arahkan kamera atas/bawah = naik/turun", 5)
    else
        CustomNotify("✈️ FLY", "Fly dimatikan.", 2)
    end
end, "lblFly")

CreateInputUI(MainFarmPage, "⚡ Kecepatan Terbang", tostring(EngineConfig.FlySpeed), function(v)
    local n = tonumber(v)
    if n and n > 0 then
        EngineConfig.FlySpeed = n
        CustomNotify("✈️ FLY", "Speed diubah ke " .. n, 2)
    end
end, "lblFlySpeed")

CreateSection(MainFarmPage, "Utilities", "secUtils")
_G.ReplayToggle = CreateToggleUI(MainFarmPage, "🔄 Auto Play Again", EngineConfig.AutoReplayActive, function(v) EngineConfig.AutoReplayActive = v end, "lblAutoReplay")

-- Auto Return to Lobby
-- • Auto Replay ON + Auto Return ON → Replay dulu, 30 detik kemudian BackLobby
-- • Auto Return ON saja              → Langsung BackLobby setelah Settlement
_G.AutoReturnLobbyToggle = CreateToggleUI(MainFarmPage, "🏠 Auto Return to Lobby", EngineConfig.AutoReturnLobbyActive, function(v)
    EngineConfig.AutoReturnLobbyActive = v
    if v then
        if EngineConfig.AutoReplayActive then
            CustomNotify("🏠 RETURN+REPLAY","Replay → 30 detik → kembali lobby",3)
        else
            CustomNotify("🏠 AUTO RETURN","Akan otomatis kembali lobby saat ronde selesai",3)
        end
    end
end, "lblAutoReturn")

-- Autoexec code: tunggu game siap dulu sebelum load script.
-- Xeno (dan banyak executor) jalankan autoexec SEBELUM game:IsLoaded() true,
-- sehingga HttpGet gagal dan LocalPlayer nil. Loop repeat+task.wait ini fix itu.
local _AUTOEXEC_CODE = [[
    repeat task.wait(1) until game:IsLoaded() and game.Players.LocalPlayer
    loadstring(game:HttpGet("https://xifil-hub-production.up.railway.app/api/lua/loader?game=soul_iron_beta", true))()
]]

-- Deteksi queue_on_teleport secara lazy (saat dipanggil, bukan saat load),
-- supaya tidak terlewat jika executor inject fungsinya belakangan.
-- Tambahkan namespace xeno untuk Xeno PC.
local function _getQueueOnTeleport()
    return queue_on_teleport
        or queueonteleport
        or (syn  and syn.queue_on_teleport)
        or (xeno and xeno.queue_on_teleport)
end

-- Persistent auto-exec: many executors (Wave, Coco, Xeno, Script-Ware, Potassium,
-- etc.) auto-run every file placed in a workspace folder literally named
-- "autoexec" on EVERY game join — including after fully closing and reopening
-- Roblox. This is what makes "auto execute" survive a full restart, whereas
-- queue_on_teleport ONLY survives a teleport/server-hop within the same
-- still-open Roblox client. Without this, the toggle only ever worked for
-- server hops, never for "reopen Roblox" — which is what most users mean by
-- "auto execute tidak berfungsi".
local _AUTOEXEC_FOLDER = "autoexec"
local _AUTOEXEC_FILE   = _AUTOEXEC_FOLDER .. "/XiFilHub_SoulIronBeta.lua"
local _hasFileApi = isfolder and makefolder and writefile and isfile and delfile

local function _writeAutoExecFile()
    if not _hasFileApi then return false end
    local ok = pcall(function()
        if not isfolder(_AUTOEXEC_FOLDER) then makefolder(_AUTOEXEC_FOLDER) end
        writefile(_AUTOEXEC_FILE, _AUTOEXEC_CODE)
    end)
    return ok
end

local function _removeAutoExecFile()
    if not _hasFileApi then return end
    pcall(function()
        if isfile(_AUTOEXEC_FILE) then delfile(_AUTOEXEC_FILE) end
    end)
end

_G.AutoExecuteToggle = CreateToggleUI(MainFarmPage, "⚡ Auto Exec on Server Hop/Rejoin", EngineConfig.AutoExecuteOnRejoin, function(state)
    EngineConfig.AutoExecuteOnRejoin = state
    if state then
        local queuedHop  = false
        local savedToDisk = _writeAutoExecFile()

        local queueFn = _getQueueOnTeleport()
        if queueFn then
            pcall(queueFn, _AUTOEXEC_CODE)
            queuedHop = true
        end

        if queuedHop and savedToDisk then
            CustomNotify("⚡ AUTO EXEC AKTIF","Aktif untuk pindah server & buka ulang Roblox.",4)
        elseif queuedHop then
            CustomNotify("⚡ AUTO EXEC AKTIF (Sebagian)","Aktif saat pindah server. Executor tidak mendukung auto-exec folder, jadi TIDAK aktif setelah Roblox ditutup penuh.",5)
        elseif savedToDisk then
            CustomNotify("⚡ AUTO EXEC AKTIF","Aktif saat buka ulang Roblox. Executor tidak mendukung queue_on_teleport, jadi TIDAK aktif saat pindah server.",5)
        else
            CustomNotify("❌ GAGAL","Executor kamu tidak mendukung queue_on_teleport maupun folder autoexec.",5)
        end
    else
        _removeAutoExecFile()
        CustomNotify("⚠️ INFO","Auto Execute dimatikan.",3)
    end
end, "lblAutoExec")


--------------------------------------------------------------------------------

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
local CreateMultiCheckUI            = H.CreateMultiCheckUI
local CreateScrollableMultiSelectUI = H.CreateScrollableMultiSelectUI

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
-- Weapon: menentukan berapa kali BaseAttack di-fire ulang (Heavy=3x, Bow=6x).
-- Terpisah dari Hit Multiplier (tab Vector) — lihat GetWeaponAttackLoops() di farm.lua.
_G.WeaponDropdown = CreateDropdownUI(MainFarmPage, "🗡️ Weapon", {"Heavy","Bow"}, EngineConfig.SelectedWeapon, function(v) EngineConfig.SelectedWeapon = v end, "lblWeapon")
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

CreateSection(MainFarmPage, "Buff Card", "secBuffCard")

_G.BuffCardToggle = CreateToggleUI(MainFarmPage, "🃏 Auto Buff Card", EngineConfig.BuffCardActive, function(v)
    EngineConfig.BuffCardActive = v
    if v and H.BuffCard_FireNow then task.spawn(H.BuffCard_FireNow) end
end, "lblBuffCard")

local _buffCardNames = {
    "Skill Cooldown",  "Dash Cooldown",   "Critical Damage",
    "Critical Chance", "Healing",          "Frost",
    "Base Attack",     "Dash Speed",       "Attack",
    "Coroside",        "Methyais",         "Movement Speed",
    "MAX Health",
}
H.BuffCardNames = _buffCardNames   -- dipakai ui_sync untuk :SetValue per item

local _buffCardStates, _buffCardCallbacks = {}, {}
for i, name in ipairs(_buffCardNames) do
    _buffCardStates[i]    = EngineConfig.BuffCardEnabled[name] or false
    _buffCardCallbacks[i] = function(v)
        EngineConfig.BuffCardEnabled[name] = v
        if EngineConfig.BuffCardActive and H.BuffCard_FireNow then
            task.spawn(H.BuffCard_FireNow)
        end
    end
end
_G.BuffCardMultiSelect = CreateScrollableMultiSelectUI(
    MainFarmPage,
    "Pilih Buff Card  (bisa lebih dari 1)",
    _buffCardNames, _buffCardStates, _buffCardCallbacks,
    "lblBuffCardSelect"
)

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
    loadstring(game:HttpGet("https://xifil-hub-production.up.railway.app/api/lua/loader?game=soul_iron", true))()
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
local _AUTOEXEC_FILE   = _AUTOEXEC_FOLDER .. "/XiFilHub_SoulIron.lua"
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

-- ── Discord Webhook ────────────────────────────────────────────────────────
CreateSection(MainFarmPage, "📡 Discord Webhook", "secWebhook")

_G.WebhookToggle = CreateToggleUI(MainFarmPage, "📡 Kirim Notif Dungeon ke Discord",
    EngineConfig.WebhookActive, function(v)
        EngineConfig.WebhookActive = v
        if v then
            CustomNotify("📡 WEBHOOK", "Notifikasi Discord diaktifkan.", 3)
        else
            CustomNotify("📡 WEBHOOK", "Notifikasi Discord dimatikan.", 2)
        end
    end, "lblWebhookActive")

-- Full-width URL input — lebih lebar dari CreateInputUI standar (URL panjang)
local _whRow = Instance.new("Frame", MainFarmPage)
_whRow.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
_whRow.BackgroundTransparency = 0.2
_whRow.Size = UDim2.new(1, 0, 0, 60)
_whRow.BorderSizePixel = 0
Instance.new("UICorner", _whRow).CornerRadius = UDim.new(0, 10)

local _whLbl = Instance.new("TextLabel", _whRow)
_whLbl.BackgroundTransparency = 1
_whLbl.Position = UDim2.new(0, 12, 0, 5)
_whLbl.Size = UDim2.new(1, -24, 0, 16)
_whLbl.Font = Enum.Font.GothamMedium
_whLbl.Text = "🔗 Webhook URL"
_whLbl.TextColor3 = Color3.fromRGB(210, 210, 210)
_whLbl.TextSize = 10
_whLbl.TextXAlignment = Enum.TextXAlignment.Left
H.RegisterTranslation("lblWebhookUrl", _whLbl, "Text")

local _whBoxBG = Instance.new("Frame", _whRow)
_whBoxBG.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
_whBoxBG.Position = UDim2.new(0, 8, 0, 26)
_whBoxBG.Size = UDim2.new(1, -16, 0, 26)
_whBoxBG.BorderSizePixel = 0
Instance.new("UICorner", _whBoxBG).CornerRadius = UDim.new(0, 6)

local _whStroke = Instance.new("UIStroke", _whBoxBG)
_whStroke.Color = Color3.fromRGB(50, 50, 60)
_whStroke.Thickness = 1

local _whBox = Instance.new("TextBox", _whBoxBG)
_whBox.BackgroundTransparency = 1
_whBox.Size = UDim2.new(1, -8, 1, 0)
_whBox.Position = UDim2.new(0, 4, 0, 0)
_whBox.Font = Enum.Font.GothamMedium
_whBox.Text = EngineConfig.WebhookUrl or ""
_whBox.PlaceholderText = "https://discord.com/api/webhooks/..."
_whBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
_whBox.TextColor3 = Color3.fromRGB(200, 200, 200)
_whBox.TextSize = 10
_whBox.TextXAlignment = Enum.TextXAlignment.Left
_whBox.ClearTextOnFocus = false
_whBox.TextTruncate = Enum.TextTruncate.AtEnd

_whBox.Focused:Connect(function()
    _whStroke.Color = H.CurrentThemePrimary or Color3.fromRGB(0, 200, 255)
end)
_whBox.FocusLost:Connect(function()
    _whStroke.Color = Color3.fromRGB(50, 50, 60)
    EngineConfig.WebhookUrl = _whBox.Text
end)

-- Expose SetValue agar ui_sync bisa sinkronkan tampilan saat config di-load
_G.WebhookUrlInput = {
    SetValue = function(_, v)
        _whBox.Text = tostring(v or "")
        EngineConfig.WebhookUrl = _whBox.Text
    end
}

-- Webhook listener: mendengarkan event settlement dungeon selesai
local _wh_HttpService = game:GetService("HttpService")
local _wh_requestFn   = request or http_request
    or (http  and http.request)
    or (syn   and syn.request)
    or nil

task.spawn(function()
    -- WaitForChild dengan timeout agar tidak hang selamanya bila path tidak ada
    local ok, WindowEvent = pcall(function()
        return game:GetService("ReplicatedStorage")
            :WaitForChild("Framework",  15)
            :WaitForChild("Systems",    15)
            :WaitForChild("GUILib",     15)
            :WaitForChild("WindowUtil", 15)
            :WaitForChild("RemoteEvent",15)
    end)
    if not ok or not WindowEvent then return end

    WindowEvent.OnClientEvent:Connect(function(action, screenName, data)
        -- Guard: toggle harus ON dan event harus settlement screen
        if not EngineConfig.WebhookActive then return end
        if not (action == "Open" and screenName == "ScreenSettlement"
                and type(data) == "table") then return end

        local url = EngineConfig.WebhookUrl or ""
        if url == "" then
            CustomNotify("📡 WEBHOOK", "URL webhook belum diisi!", 4)
            return
        end
        if not _wh_requestFn then
            CustomNotify("📡 WEBHOOK", "Executor tidak mendukung HTTP request.", 4)
            return
        end

        local isVictory = data.Victory
        local embedTitle = isVictory and "🎉 Dungeon Cleared (VICTORY)"
                                      or "💀 Dungeon Failed (DEFEAT)"
        local embedColor = isVictory and 0x00FF00 or 0xFF0000

        -- Susun teks reward
        local rewardsText = ""
        if type(data.Rewards) == "table" then
            for itemName, itemData in pairs(data.Rewards) do
                local count = (type(itemData) == "table" and itemData.Count) or 0
                rewardsText = rewardsText .. "- " .. count .. "x " .. tostring(itemName) .. "\n"
            end
        end
        if rewardsText == "" then rewardsText = "Tidak ada drop." end

        local payload = {
            embeds = {{
                title  = embedTitle,
                color  = embedColor,
                fields = {
                    { name = "⚔️ Kills",        value = tostring(data.Kills   or 0), inline = true  },
                    { name = "⏳ Waktu (s)",     value = tostring(data.EndTime or 0), inline = true  },
                    { name = "🍀 Luck Mult",     value = tostring(data.Luck    or 0), inline = true  },
                    { name = "🎁 Rewards",       value = rewardsText,                 inline = false },
                },
                footer    = { text = "XiFil Hub — Auto-Farm Report" },
                timestamp = DateTime.now():ToIsoDate(),
            }}
        }

        local encOk, jsonData = pcall(_wh_HttpService.JSONEncode, _wh_HttpService, payload)
        if not encOk then return end

        local sendOk = pcall(_wh_requestFn, {
            Url     = url,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = jsonData,
        })
        if sendOk then
            CustomNotify("📡 WEBHOOK", isVictory and "✅ Report Victory terkirim!" or "📨 Report Defeat terkirim!", 3)
        end
    end)
end)

--------------------------------------------------------------------------------

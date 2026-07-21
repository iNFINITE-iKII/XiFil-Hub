--------------------------------------------------------------------------------
--// ui/tab_vector.lua — S18 Tab 2: Vector Config
--------------------------------------------------------------------------------
local H              = getgenv().Hub
local EngineConfig   = H.EngineConfig
local GameLists      = H.GameLists
local CombatEngine   = H.CombatEngine
local Workspace      = H.Workspace
local CustomNotify   = H.CustomNotify
local CreateTab         = H.CreateTab
local CreateSection     = H.CreateSection
local CreateToggleUI    = H.CreateToggleUI
local CreateCycleUI     = H.CreateCycleUI
local CreateInputUI     = H.CreateInputUI
local CreateButton      = H.CreateButton

-- [S18] TAB 2 — VECTOR CONFIG
--------------------------------------------------------------------------------
local VectorPage = CreateTab("⚙️ Vector", "tabVector")

CreateSection(VectorPage, "Target Selector", "secTargetSel")
local NormalDropdown = CreateCycleUI(VectorPage, "Normal Mob", GameLists.NormalNPCs, "None", function(v)
    EngineConfig.SelectedNormalNpcId = (v ~= "None") and v or nil
end, "lblWeaponSwitch")
local BossDropdown = CreateCycleUI(VectorPage, "Boss Mob", GameLists.BossNPCs, "None", function(v)
    EngineConfig.SelectedBossNpcId = (v ~= "None") and v or nil
end, "lblAutoExec")
CreateButton(VectorPage, "🔄 Scan Map Targets", function()
    local normalIds, bossIds = {"None"}, {"None"}
    local ef = Workspace:FindFirstChild("EnemyNpc")
    if ef then
        local cn, cb = {}, {}
        for _, m in ipairs(ef:GetChildren()) do
            local id = CombatEngine.GetNpcId(m)
            if id and id ~= "" then
                if CombatEngine.GetLevelType(m) == "boss" then
                    if not cb[id] then cb[id] = true; table.insert(bossIds, id) end
                else
                    if not cn[id] then cn[id] = true; table.insert(normalIds, id) end
                end
            end
        end
    end
    GameLists.NormalNPCs = normalIds; GameLists.BossNPCs = bossIds
    NormalDropdown:SetValues(normalIds); BossDropdown:SetValues(bossIds)
    CustomNotify("Scan","Target disinkronkan.",2)
end, "btnScanMap")

-- ── Dodge Dragon ──────────────────────────────────────────────────────────
CreateSection(VectorPage, "🐉 Dodge Dragon", "secDodgeDragon")

_G.DodgeDragonToggle = CreateToggleUI(VectorPage, "🐉 Dodge Dragon (Skill Bom)",
    EngineConfig.DodgeDragonActive, function(v)
        EngineConfig.DodgeDragonActive = v
        if v then
            CustomNotify("🐉 DODGE", "Dodge Dragon aktif — mendeteksi Skill Bom.", 3)
        else
            CustomNotify("🐉 DODGE", "Dodge Dragon dimatikan.", 2)
        end
    end, "lblDodgeDragon")

-- Listener RedShow: deteksi BombRed lalu ubah radius → 100 selama 2 detik
task.spawn(function()
    -- Coba require GameEnum untuk dapat nilai BombRed yang akurat
    local _bombRedVal = nil
    local enumOk, GameEnum = pcall(function()
        return require(game:GetService("ReplicatedStorage")
            :WaitForChild("Enum",     10)
            :WaitForChild("GameEnum", 10))
    end)
    if enumOk and type(GameEnum) == "table"
       and GameEnum.SkillSkinBase then
        _bombRedVal = GameEnum.SkillSkinBase.BombRed
    end

    -- Tunggu folder RedShow muncul di Workspace
    local RedShow = game:GetService("Workspace"):WaitForChild("RedShow", 30)
    if not RedShow then return end

    local _dodging = false  -- flag cegah tumpang tindih

    RedShow.ChildAdded:Connect(function(bar)
        -- Guard: Dodge Dragon ON + Auto Farm ON + tidak sedang dodge
        if not EngineConfig.DodgeDragonActive then return end
        if not EngineConfig.AutoFarmActive     then return end
        if _dodging then return end

        task.defer(function()
            -- Filter hanya BombRed (jika enum berhasil di-require)
            local skin = bar:GetAttribute("Skin")
            if _bombRedVal ~= nil and skin ~= _bombRedVal then return end

            -- Hitung berapa banyak BombRed aktif di RedShow sekarang
            local count = 0
            for _, child in ipairs(RedShow:GetChildren()) do
                local s = child:GetAttribute("Skin")
                if _bombRedVal == nil or s == _bombRedVal then
                    count = count + 1
                end
            end
            if count <= 3 then return end  -- butuh lebih dari 3

            -- ── DODGE ─────────────────────────────────────────
            _dodging = true
            local prevRadius = EngineConfig.OrbitRadius
            EngineConfig.OrbitRadius = 100
            if _G.RadiusInput then _G.RadiusInput:SetValue(100) end
            CustomNotify("🐉 DODGE DRAGON", "Skill Bom! Radius → 100 (4s)", 2)

            task.wait(4)

            EngineConfig.OrbitRadius = prevRadius
            if _G.RadiusInput then _G.RadiusInput:SetValue(prevRadius) end
            _dodging = false
        end)
    end)
end)

CreateSection(VectorPage, "Dodge Boss", "secDodgeBoss")
_G.RadiusInput = CreateInputUI(VectorPage, "Orbit Radius", EngineConfig.OrbitRadius, true, function(v) EngineConfig.OrbitRadius = tonumber(v) or 12 end)
CreateButton(VectorPage, "🎯 Dodge Boss Skil (20)",  function() EngineConfig.OrbitRadius = 20;  _G.RadiusInput:SetValue(20)  end, "btnDodge20")
CreateButton(VectorPage, "🎯 Dodge Boss Skil(200)", function() EngineConfig.OrbitRadius = 200; _G.RadiusInput:SetValue(200) end, "btnDodge200")

CreateSection(VectorPage, "Reset Lock", "secResetLock")
_G.ResetLockW4Input = CreateInputUI(VectorPage, "Reset Lock W4 - Tartarus (s)", EngineConfig.ResetLockW4, true, function(v)
    EngineConfig.ResetLockW4 = tonumber(v) or 2
end)
_G.ResetLockW5Input = CreateInputUI(VectorPage, "Reset Lock W5 - Endless Tower (s)", EngineConfig.ResetLockW5, true, function(v)
    EngineConfig.ResetLockW5 = tonumber(v) or 3
end)

CreateSection(VectorPage, "Kinematic System Parameters", "secKinematic")
_G.HeightInput       = CreateInputUI(VectorPage, "Height Normal Target (Y)", EngineConfig.StandHeight,        true,  function(v) EngineConfig.StandHeight        = tonumber(v) or 20    end)
_G.BossHeightInput   = CreateInputUI(VectorPage, "Height Boss Target (Y)",   EngineConfig.BossHeight,         true,  function(v) EngineConfig.BossHeight          = tonumber(v) or 25    end)
_G.SpeedInput        = CreateInputUI(VectorPage, "Orbit Speed",              EngineConfig.OrbitSpeed,         true,  function(v) EngineConfig.OrbitSpeed          = tonumber(v) or 5     end)
_G.DelayInput        = CreateInputUI(VectorPage, "CFrame Delay",             EngineConfig.CFrameDelay,        false, function(v) EngineConfig.CFrameDelay         = tonumber(v) or 0.001 end)
_G.MultiplierInput   = CreateInputUI(VectorPage, "Hit Multiplier",           EngineConfig.HitMultiplier,      true,  function(v) EngineConfig.HitMultiplier       = tonumber(v) or 1     end)
_G.LerpAlphaInput    = CreateInputUI(VectorPage, "Lerp Alpha (0–1)",         EngineConfig.LerpAlpha,          false, function(v) EngineConfig.LerpAlpha           = math.clamp(tonumber(v) or 0.3, 0.01, 1) end)
_G.SkillCooldownInput= CreateInputUI(VectorPage, "Skill Cooldown (s)",       EngineConfig.SkillCooldownDelay, false, function(v) EngineConfig.SkillCooldownDelay  = tonumber(v) or 0.5   end)
_G.ETHoverYInput     = CreateInputUI(VectorPage, "Endless Tower Hover Y",    EngineConfig.EndlessTowerHoverY, false, function(v) EngineConfig.EndlessTowerHoverY   = tonumber(v) or 35    end)


--------------------------------------------------------------------------------

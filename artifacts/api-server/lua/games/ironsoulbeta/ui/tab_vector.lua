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

CreateSection(VectorPage, "Dodge Boss", "secDodgeBoss")
_G.RadiusInput = CreateInputUI(VectorPage, "Orbit Radius", EngineConfig.OrbitRadius, true, function(v) EngineConfig.OrbitRadius = tonumber(v) or 12 end)
CreateButton(VectorPage, "🎯 Dodge Boss Skil (20)",  function() EngineConfig.OrbitRadius = 20;  _G.RadiusInput:SetValue(20)  end, "btnDodge20")
CreateButton(VectorPage, "🎯 Dodge Boss Skil(200)", function() EngineConfig.OrbitRadius = 200; _G.RadiusInput:SetValue(200) end, "btnDodge200")

CreateSection(VectorPage, "Reset Lock — Endless Tower", "secResetLock")
_G.ETResetLockInput = CreateInputUI(VectorPage, "Reset Lock Delay (s)", EngineConfig.EndlessTowerResetLock, true, function(v)
    EngineConfig.EndlessTowerResetLock = tonumber(v) or 5
end)

CreateSection(VectorPage, "Kinematic System Parameters", "secKinematic")
_G.HeightInput       = CreateInputUI(VectorPage, "Height Normal Target (Y)", EngineConfig.StandHeight,        true,  function(v) EngineConfig.StandHeight        = tonumber(v) or 20    end)
_G.BossHeightInput   = CreateInputUI(VectorPage, "Height Boss Target (Y)",   EngineConfig.BossHeight,         true,  function(v) EngineConfig.BossHeight          = tonumber(v) or 25    end)
_G.SpeedInput        = CreateInputUI(VectorPage, "Orbit Speed",              EngineConfig.OrbitSpeed,         true,  function(v) EngineConfig.OrbitSpeed          = tonumber(v) or 5     end)
_G.DelayInput        = CreateInputUI(VectorPage, "CFrame Delay",             EngineConfig.CFrameDelay,        false, function(v) EngineConfig.CFrameDelay         = tonumber(v) or 0.001 end)
_G.MultiplierInput   = CreateInputUI(VectorPage, "Hit Multiplier",           EngineConfig.HitMultiplier,      true,  function(v) EngineConfig.HitMultiplier       = tonumber(v) or 1     end)
_G.LerpAlphaInput    = CreateInputUI(VectorPage, "Lerp Alpha (0–1)",         EngineConfig.LerpAlpha,          false, function(v) EngineConfig.LerpAlpha           = math.clamp(tonumber(v) or 0.3, 0.01, 1) end)
_G.SkillCooldownInput= CreateInputUI(VectorPage, "Skill Cooldown (s)",       EngineConfig.SkillCooldownDelay, false, function(v) EngineConfig.SkillCooldownDelay  = tonumber(v) or 0.5   end)


--------------------------------------------------------------------------------

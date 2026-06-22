--------------------------------------------------------------------------------
-- [MODULE] farm.lua — XIFIL Hub PRO
-- New farm loop: Chest → Egg → Monster → Find (non-blocking search)
-- Egg fix: Phase1 = CFrame + proximity simultaneously, Phase2 = orbit
--------------------------------------------------------------------------------
local ctx = ...
local Services          = ctx.Services
local EngineConfig      = ctx.EngineConfig
local LocalPlayer       = ctx.LocalPlayer
local Workspace         = ctx.Workspace
local PlayerActionRE    = ctx.PlayerActionRE
local GameRoundRE       = ctx.GameRoundRE
local CombatEngine      = ctx.CombatEngine
local Navigation        = ctx.Navigation
local GetPositionCFrame = ctx.GetPositionCFrame
local ApplyMovement     = ctx.ApplyMovement
local anyActiveTargetExists = ctx.anyActiveTargetExists
local CustomNotify      = ctx.CustomNotify
local WORLD_INDEX       = ctx.WORLD_INDEX

-- ── Search state flags ────────────────────────────────────────────────────────
ctx._searchRunning   = false
ctx._searchInterrupt = false

-- ── DisableAutoFarm ───────────────────────────────────────────────────────────
local function DisableAutoFarm(reason)
    if not EngineConfig.AutoFarm then return end
    EngineConfig.AutoFarm=false
    ctx._searchInterrupt=true
    -- Notify GUI to update toggle visually
    if ctx.GUI_OnFarmDisabled then ctx.GUI_OnFarmDisabled() end
    CustomNotify("🚨 FARM OFF",reason,4)
    if reason:find("Victory") then
        task.spawn(function()
            if not EngineConfig.AutoReplayActive then return end
            task.wait(1.0)
            pcall(function() GameRoundRE:FireServer("VotePlayAgain") end)
            CustomNotify("🔄 REPLAY","Sinyal dikirim!",3)
        end)
    end
end
ctx.DisableAutoFarm = DisableAutoFarm

-- Victory callback (registered here, called by combat.lua event)
ctx.OnVictoryDetected = function()
    DisableAutoFarm("Victory Screen Detected")
end

-- ── Non-blocking search trigger ───────────────────────────────────────────────
local function triggerSearch(myHRP, myHum)
    if ctx._searchRunning then return end
    ctx._searchInterrupt=false
    ctx._searchRunning=true
    task.spawn(function()
        local worldIdx=WORLD_INDEX[EngineConfig.SelectedWorld] or 1
        pcall(function()
            if     worldIdx==1 then Navigation.SearchWorld1(myHRP,myHum)
            elseif worldIdx==2 then Navigation.SearchWorld2(myHRP,myHum)
            elseif worldIdx==3 then Navigation.SearchWorld3(myHRP,myHum)
            end
        end)
        ctx._searchRunning=false
        ctx._searchInterrupt=false
    end)
end

-- ── HRP validity guard ────────────────────────────────────────────────────────
local function isHRPValid(hrp)
    return hrp and hrp.Parent and hrp.Parent==LocalPlayer.Character
end

-- ── Main Farm Loop ────────────────────────────────────────────────────────────
local _farmLoopRunning=false

local function startFarmLoop()
    if _farmLoopRunning then return end
    _farmLoopRunning=true

    xpcall(function()
        while EngineConfig.AutoFarm do

            -- Victory check (cached, no polling)
            if ctx._victoryDetected then
                DisableAutoFarm("Victory Screen Detected"); break
            end

            local char=LocalPlayer.Character
            local myHRP=char and char:FindFirstChild("HumanoidRootPart")
            local myHum=char and char:FindFirstChildOfClass("Humanoid")
            if not myHRP or not myHum then task.wait(0.1); continue end

            -- ── Cache targets once per iteration (efficient) ──────────────────
            local chests   = EngineConfig.FarmChest   and CombatEngine.GetValidChests()   or {}
            local egg      = EngineConfig.FarmEgg     and Workspace:FindFirstChild("DragonEgg") or nil
            local monsters = EngineConfig.FarmMonster and CombatEngine.GetValidMonsters() or {}

            local hasTarget = (#chests>0) or (egg~=nil) or (#monsters>0)

            -- Interrupt any running search if a target just appeared
            if hasTarget and ctx._searchRunning then ctx._searchInterrupt=true end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITAS 1 — CHEST
            -- ════════════════════════════════════════════════════════════════
            if EngineConfig.FarmChest and #chests>0 then
                ctx._searchInterrupt=true
                myHum.PlatformStand=true
                EngineConfig.IsLockDelay=false
                local chestRoot=chests[1].Root
                if chestRoot and chestRoot:IsA("BasePart") then
                    local targetCF=GetPositionCFrame(chestRoot.Position,EngineConfig.FarmPosition)
                    ApplyMovement(myHRP,targetCF)
                    local atkCF=chestRoot.CFrame
                    for _=1,EngineConfig.HitMultiplier do
                        task.defer(function()
                            pcall(function() PlayerActionRE:FireServer("SkillAction","BaseAttack",3,atkCF) end)
                        end)
                    end
                    task.wait(EngineConfig.CFrameDelay)
                else
                    Services.RunService.Heartbeat:Wait()
                end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITAS 2 — EGG  (fixed: Phase1 = TP + proximity simultaneously)
            -- ════════════════════════════════════════════════════════════════
            elseif EngineConfig.FarmEgg and egg then
                ctx._searchInterrupt=true
                EngineConfig.IsLockDelay=false
                local ok,eggCF=pcall(function() return egg:GetPivot() end)
                if ok and eggCF then
                    local eggPos=eggCF.Position
                    myHum.PlatformStand=true

                    -- FASE 1: CFrame ke posisi di atas egg + fire proximity BERSAMAAN
                    CombatEngine.ResetPhysics(myHRP)
                    myHRP.CFrame=CFrame.new(eggPos+Vector3.new(0,3,0),eggPos)
                    -- Proximity di-defer → jalan di frame yang sama, tanpa blocking
                    task.defer(function()
                        pcall(function()
                            for _,obj in ipairs(egg:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then fireproximityprompt(obj) end
                            end
                        end)
                    end)
                    task.wait(0.05)

                    -- FASE 2: Orbit egg (sama persis seperti chest & monster)
                    local dropCF=GetPositionCFrame(eggPos,EngineConfig.FarmPosition)
                    ApplyMovement(myHRP,dropCF)
                    task.wait(EngineConfig.CFrameDelay)
                else
                    Services.RunService.Heartbeat:Wait()
                end

            -- ════════════════════════════════════════════════════════════════
            -- PRIORITAS 3 — MONSTER
            -- ════════════════════════════════════════════════════════════════
            elseif EngineConfig.FarmMonster and #monsters>0 then
                ctx._searchInterrupt=true
                EngineConfig.IsLockDelay=false
                myHum.PlatformStand=true
                local target=monsters[1]
                local tPart=target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)
                local tHum =target and target:FindFirstChildOfClass("Humanoid")
                if tPart and isHRPValid(myHRP) and (not tHum or tHum.Health>0) then
                    local isBoss=CombatEngine.GetLevelType(target)=="boss"
                    local savedH=EngineConfig.StandHeight
                    if isBoss then EngineConfig.StandHeight=EngineConfig.BossHeight end
                    local targetCF=GetPositionCFrame(tPart.Position,EngineConfig.FarmPosition)
                    EngineConfig.StandHeight=savedH
                    ApplyMovement(myHRP,targetCF)
                    local tCF=tPart.CFrame
                    for _=1,EngineConfig.HitMultiplier do
                        task.defer(function()
                            pcall(function() PlayerActionRE:FireServer("SkillAction","BaseAttack",3,tCF) end)
                        end)
                    end
                    task.wait(EngineConfig.CFrameDelay)
                else
                    Services.RunService.Heartbeat:Wait()
                end

            -- ════════════════════════════════════════════════════════════════
            -- TIDAK ADA TARGET: Trigger Find (non-blocking)
            -- ════════════════════════════════════════════════════════════════
            elseif EngineConfig.AutoFind then
                myHum.PlatformStand=false
                CombatEngine.ResetPhysics(myHRP)
                -- triggerSearch hanya spawn jika belum running → tidak tumpang tindih
                triggerSearch(myHRP,myHum)
                task.wait(0.1)

            -- ════════════════════════════════════════════════════════════════
            -- AutoFind OFF: idle saja
            -- ════════════════════════════════════════════════════════════════
            else
                myHum.PlatformStand=false
                CombatEngine.ResetPhysics(myHRP)
                task.wait(0.1)
            end
        end
    end, function(e)
        CustomNotify("⚠️ FARM ERROR",tostring(e):sub(1,80),5)
        EngineConfig.AutoFarm=false
        if ctx.GUI_OnFarmDisabled then ctx.GUI_OnFarmDisabled() end
    end)

    -- ── Cleanup ───────────────────────────────────────────────────────────────
    _farmLoopRunning         = false
    ctx._searchRunning       = false
    ctx._searchInterrupt     = true
    EngineConfig.IsLockDelay = false
    pcall(function()
        local char=LocalPlayer.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand=false end
    end)
end
ctx.startFarmLoop = startFarmLoop

-- ── Auto Attack Only (Kill Aura) — always-running loop ────────────────────────
task.spawn(function()
    while true do
        task.wait(math.max(EngineConfig.CFrameDelay,0.05))
        if EngineConfig.AutoAttackOnly then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _=1,EngineConfig.HitMultiplier do
                    task.defer(function()
                        pcall(function() PlayerActionRE:FireServer("SkillAction","BaseAttack",3,hrp.CFrame) end)
                    end)
                end
            end
        end
    end
end)

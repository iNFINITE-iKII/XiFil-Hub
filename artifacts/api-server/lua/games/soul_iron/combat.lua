--------------------------------------------------------------------------------
-- [MODULE] combat.lua — XIFIL Hub PRO
-- CombatEngine, Navigation (fixed: non-blocking + _searchInterrupt)
-- Victory detection via event cache (no per-frame polling)
--------------------------------------------------------------------------------
local ctx = ...
local Services      = ctx.Services
local EngineConfig  = ctx.EngineConfig
local LocalPlayer   = ctx.LocalPlayer
local Workspace     = ctx.Workspace
local TweenService  = ctx.TweenService
local RuntimeMaid   = ctx.RuntimeMaid
local CustomNotify  = ctx.CustomNotify
local WORLD_INDEX   = ctx.WORLD_INDEX

-- ── Position & Movement ───────────────────────────────────────────────────────
local function GetPositionCFrame(targetPos, posMode)
    local r=EngineConfig.OrbitRadius; local h=EngineConfig.StandHeight
    local angle=tick()*EngineConfig.OrbitSpeed
    if posMode=="Orbit Atas" then
        return CFrame.new(targetPos+Vector3.new(math.cos(angle)*r,h,math.sin(angle)*r),targetPos)
    elseif posMode=="Orbit Bawah" then
        return CFrame.new(targetPos+Vector3.new(math.cos(angle)*r,-h,math.sin(angle)*r),targetPos)
    elseif posMode=="Orbit Samping" then
        return CFrame.new(targetPos+Vector3.new(math.cos(angle)*r,0,math.sin(angle)*r),targetPos)
    elseif posMode=="Diam Atas" then
        return CFrame.new(targetPos+Vector3.new(0,h,0))
    elseif posMode=="Diam Bawah" then
        return CFrame.new(targetPos-Vector3.new(0,h,0))
    elseif posMode=="Depan Target" then
        return CFrame.new(targetPos+Vector3.new(r,0,0))
    elseif posMode=="Belakang Target" then
        return CFrame.new(targetPos+Vector3.new(-r,0,0))
    elseif posMode=="Acak" then
        local ra=math.random()*math.pi*2
        return CFrame.new(targetPos+Vector3.new(math.cos(ra)*r,h,math.sin(ra)*r),targetPos)
    end
    return CFrame.new(targetPos+Vector3.new(math.cos(angle)*r,h,math.sin(angle)*r),targetPos)
end
ctx.GetPositionCFrame = GetPositionCFrame

local function ApplyMovement(hrp, targetCF)
    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
    if EngineConfig.FarmMethod=="Lerp" then
        hrp.CFrame=hrp.CFrame:Lerp(targetCF,math.clamp(EngineConfig.LerpAlpha,0.01,1))
    else
        hrp.CFrame=targetCF
    end
end
ctx.ApplyMovement = ApplyMovement

-- ── CombatEngine ──────────────────────────────────────────────────────────────
local CombatEngine = {}
ctx.CombatEngine = CombatEngine

function CombatEngine.ResetPhysics(hrp)
    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
end

function CombatEngine.InterruptableStall(duration, condFn)
    local elapsed=0
    while elapsed<duration do
        if condFn() then return true end
        elapsed=elapsed+Services.RunService.Heartbeat:Wait()
    end; return false
end

function CombatEngine.GetLevelType(monster)
    local attr=monster:GetAttribute("LevelType")
    if attr then return tostring(attr):lower() end
    local obj=monster:FindFirstChild("LevelType")
    if obj and (obj:IsA("StringValue") or obj:IsA("IntValue")) then return tostring(obj.Value):lower() end
    if monster:FindFirstChild("BossTag") or string.lower(monster.Name):find("boss") then return "boss" end
    return "normal"
end

function CombatEngine.GetNpcId(monster)
    local attr=monster:GetAttribute("NpcId"); if attr then return tostring(attr) end
    local obj=monster:FindFirstChild("NpcId")
    if obj and (obj:IsA("StringValue") or obj:IsA("IntValue") or obj:IsA("NumberValue")) then return tostring(obj.Value) end
    return monster.Name
end

function CombatEngine.GetValidChests()
    local chests={}
    for _,obj in ipairs(Workspace:GetChildren()) do
        if obj.Name:find("Chest") then
            local root=obj:FindFirstChild("Root") or obj:FindFirstChild("Part") or (obj:IsA("Model") and obj.PrimaryPart)
            if root then table.insert(chests,{Object=obj,Root=root}) end
        end
    end; return chests
end

function CombatEngine.GetValidMonsters()
    local ef=Workspace:FindFirstChild("EnemyNpc"); if not ef then return {} end
    local normal,priority={},{}
    for _,monster in ipairs(ef:GetChildren()) do
        local hrp=monster:FindFirstChild("HumanoidRootPart")
        local hum=monster:FindFirstChildOfClass("Humanoid")
        if hrp and (not hum or hum.Health>0) then
            local npcId=CombatEngine.GetNpcId(monster)
            if (EngineConfig.SelectedNormalNpcId and npcId==EngineConfig.SelectedNormalNpcId)
            or (EngineConfig.SelectedBossNpcId   and npcId==EngineConfig.SelectedBossNpcId) then
                table.insert(priority,1,monster)
            elseif CombatEngine.GetLevelType(monster)=="boss" then
                table.insert(priority,monster)
            else
                table.insert(normal,monster)
            end
        end
    end
    return #priority>0 and priority or normal
end

-- ── Victory Detection (event-based cache — zero per-frame cost) ───────────────
ctx._victoryDetected = false

local function isVictoryText(obj)
    if not obj or not obj:IsA("TextLabel") then return false end
    if not obj.Visible or obj.AbsoluteSize.X==0 or obj.TextTransparency>=1 then return false end
    local t=obj.Text:upper()
    if (obj.Name=="FirstClear" and t:find("FIRST CLEAR")) or (obj.Name=="Text" and t:find("VICTORY")) then
        local cur=obj.Parent
        while cur and not cur:IsA("ScreenGui") do
            if cur:IsA("GuiObject") and not cur.Visible then return false end
            cur=cur.Parent
        end
        local p=obj.Parent
        if p and (p.Name=="RoundCompleted" or p.Name=="BTN" or p.Name=="Victory") then return true end
    end; return false
end

local pGui=LocalPlayer:WaitForChild("PlayerGui")
local uiConn=pGui.DescendantAdded:Connect(function(desc)
    task.wait(0.2)
    if isVictoryText(desc) then
        ctx._victoryDetected=true
        if ctx.OnVictoryDetected then ctx.OnVictoryDetected() end
    end
end)
local uiConnR=pGui.DescendantRemoving:Connect(function(desc)
    if isVictoryText(desc) then ctx._victoryDetected=false end
end)
RuntimeMaid:GiveTask(uiConn); RuntimeMaid:GiveTask(uiConnR)

-- ── anyActiveTargetExists (uses new EngineConfig keys) ────────────────────────
local function anyActiveTargetExists()
    if not EngineConfig.AutoFarm then return false end
    if EngineConfig.FarmChest   and #CombatEngine.GetValidChests()>0 then return true end
    if EngineConfig.FarmEgg     and Workspace:FindFirstChild("DragonEgg") then return true end
    if EngineConfig.FarmMonster and #CombatEngine.GetValidMonsters()>0 then return true end
    return false
end
ctx.anyActiveTargetExists = anyActiveTargetExists

-- ── Navigation Engine ─────────────────────────────────────────────────────────
local Navigation = {}
ctx.Navigation = Navigation

function Navigation.GetPortalRootCFrame(portalInstance)
    if not portalInstance then return nil end
    local root=portalInstance:FindFirstChild("Root")
    if root and root:IsA("BasePart") then return root.CFrame end
    if portalInstance:IsA("Model") then
        return portalInstance.PrimaryPart and portalInstance.PrimaryPart.CFrame or portalInstance:GetPivot()
    elseif portalInstance:IsA("BasePart") then
        return portalInstance.CFrame
    end
    return nil
end

function Navigation.GetSingleClosestPortal(portalName, myPosition, worldIdx)
    local roundDoor=Workspace:FindFirstChild("RoundDoor"); if not roundDoor then return nil end
    local closestCF=nil; local shortest=math.huge
    local activeIdx=worldIdx or (WORLD_INDEX[EngineConfig.SelectedWorld] or 1)
    for _,obj in ipairs(roundDoor:GetChildren()) do
        local isMatch=false
        if activeIdx==3 then
            if string.match(obj.Name,"^Portal%d+_%d+$") or string.match(obj.Name,"^%d+_%d+$") then isMatch=true end
        else
            if obj.Name:lower()==portalName:lower() then isMatch=true end
        end
        if isMatch then
            local cf=Navigation.GetPortalRootCFrame(obj)
            if cf then
                local d=(myPosition-cf.Position).Magnitude
                if d<shortest then shortest=d; closestCF=cf end
            end
        end
    end
    return closestCF
end

function Navigation.GetClosestObject(folderName, objectName, myPosition)
    local folder=Workspace:FindFirstChild(folderName) or (folderName=="Workspace" and Workspace)
    if not folder then return nil end
    local closest=nil; local shortest=math.huge
    for _,obj in ipairs(folder:GetChildren()) do
        if obj.Name==objectName or obj.Name:lower():find(objectName:lower(),1,true) then
            local cf=obj:IsA("Model") and obj:GetPivot() or (obj:IsA("BasePart") and obj.CFrame)
            if cf then
                local d=(myPosition-cf.Position).Magnitude
                if d<shortest then shortest=d; closest=obj end
            end
        end
    end
    return closest
end

-- ── Search break condition factory (uses ctx._searchInterrupt) ────────────────
local function makeShouldBreak(worldIdx)
    return function()
        return ctx._searchInterrupt
            or ctx._victoryDetected
            or not EngineConfig.AutoFarm
            or not EngineConfig.AutoFind
            or anyActiveTargetExists()
            or (WORLD_INDEX[EngineConfig.SelectedWorld] ~= worldIdx)
    end
end

-- Shared idle wait helper (replaces 115s monolithic stall)
local function idleWaitInterruptable(maxSecs, shouldBreak, myHRP, idleCF)
    local waited=0
    while waited<maxSecs and not shouldBreak() do
        local done=CombatEngine.InterruptableStall(5, function()
            if shouldBreak() then return true end
            if myHRP and myHRP.Parent and idleCF then
                CombatEngine.ResetPhysics(myHRP)
                myHRP.CFrame=idleCF
            end
        end)
        if done then break end
        waited=waited+5
    end
end

-- ── SearchWorld1 (Starless Forest) ────────────────────────────────────────────
function Navigation.SearchWorld1(myHRP, myHum)
    if WORLD_INDEX[EngineConfig.SelectedWorld]~=1 then return end
    local shouldBreak=makeShouldBreak(1)
    if shouldBreak() then return end
    myHum.PlatformStand=true

    -- Use Door anchor (dynamic instanced world position)
    local door=Navigation.GetClosestObject("RoundDoor","Door",myHRP.Position)
    if door then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame=door:IsA("Model") and door:GetPivot() or door.CFrame
        if CombatEngine.InterruptableStall(0.5,shouldBreak) then myHum.PlatformStand=false; return end
    end

    local centerPos=myHRP.Position
    local steps=50
    local orbitTiers={50,150,250}

    for _,radius in ipairs(orbitTiers) do
        if shouldBreak() then break end
        local lastCF=nil
        for i=1,steps do
            if shouldBreak() then break end
            local angle=(i/steps)*(math.pi*2)
            local pos=centerPos+Vector3.new(math.cos(angle)*radius,0,math.sin(angle)*radius)
            CombatEngine.ResetPhysics(myHRP)
            lastCF=CFrame.new(pos,centerPos); myHRP.CFrame=lastCF
            Services.RunService.Heartbeat:Wait()
        end
        if lastCF and not shouldBreak() then
            CombatEngine.InterruptableStall(2,function()
                if shouldBreak() then return true end
                CombatEngine.ResetPhysics(myHRP); myHRP.CFrame=lastCF
            end)
        end
    end
    if shouldBreak() then myHum.PlatformStand=false; return end

    -- Portal approach
    local portal=Navigation.GetClosestObject("RoundDoor","Portal",myHRP.Position)
        or Navigation.GetClosestObject("Workspace","Portal",myHRP.Position)
    if portal and not shouldBreak() then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame=portal:IsA("Model") and portal:GetPivot() or portal.CFrame
        local pCF=myHRP.CFrame
        CombatEngine.InterruptableStall(3,function()
            if shouldBreak() then return true end
            CombatEngine.ResetPhysics(myHRP); myHRP.CFrame=pCF
        end)
    end

    -- Interruptable idle (max 120s, polling every 5s — replaces 115s monolithic stall)
    if not shouldBreak() then
        idleWaitInterruptable(120,shouldBreak,myHRP,myHRP.CFrame)
    end
    myHum.PlatformStand=false
end

-- ── SearchWorld2 (Frozen Valley) ──────────────────────────────────────────────
function Navigation.SearchWorld2(myHRP, myHum)
    if WORLD_INDEX[EngineConfig.SelectedWorld]~=2 then return end
    local shouldBreak=makeShouldBreak(2)
    EngineConfig.IsLockDelay=true; myHum.PlatformStand=true

    if CombatEngine.InterruptableStall(3,shouldBreak) then EngineConfig.IsLockDelay=false; myHum.PlatformStand=false; return end

    local pdCF=Navigation.GetSingleClosestPortal("PortalD",myHRP.Position,2)
    if pdCF and not shouldBreak() then CombatEngine.ResetPhysics(myHRP); myHRP.CFrame=pdCF; task.wait(0.1) end
    if CombatEngine.InterruptableStall(3,shouldBreak) then EngineConfig.IsLockDelay=false; myHum.PlatformStand=false; return end

    local pCF=Navigation.GetSingleClosestPortal("Portal",myHRP.Position,2)
    if pCF and not shouldBreak() then CombatEngine.ResetPhysics(myHRP); myHRP.CFrame=pCF; task.wait(0.1) end
    if CombatEngine.InterruptableStall(3,shouldBreak) then EngineConfig.IsLockDelay=false; myHum.PlatformStand=false; return end

    EngineConfig.IsLockDelay=false
    if not shouldBreak() then
        EngineConfig.IsLockDelay=true
        idleWaitInterruptable(120,shouldBreak,myHRP,nil)
        EngineConfig.IsLockDelay=false
    end
    myHum.PlatformStand=false
end

-- ── SearchWorld3 (Oathlost Castle) ────────────────────────────────────────────
function Navigation.SearchWorld3(myHRP, myHum)
    if WORLD_INDEX[EngineConfig.SelectedWorld]~=3 then return end
    local shouldBreak=makeShouldBreak(3)
    EngineConfig.IsLockDelay=true; myHum.PlatformStand=true

    if CombatEngine.InterruptableStall(3,shouldBreak) then EngineConfig.IsLockDelay=false; myHum.PlatformStand=false; return end

    local pCF=Navigation.GetSingleClosestPortal("Portal",myHRP.Position,3)
    if pCF and not shouldBreak() then CombatEngine.ResetPhysics(myHRP); myHRP.CFrame=pCF; task.wait(0.1) end
    if CombatEngine.InterruptableStall(3,shouldBreak) then EngineConfig.IsLockDelay=false; myHum.PlatformStand=false; return end

    EngineConfig.IsLockDelay=false
    if not shouldBreak() then
        EngineConfig.IsLockDelay=true
        idleWaitInterruptable(120,shouldBreak,myHRP,nil)
        EngineConfig.IsLockDelay=false
    end
    myHum.PlatformStand=false
end

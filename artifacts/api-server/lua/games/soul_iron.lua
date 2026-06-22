--------------------------------------------------------------------------------
--// XIFIL PRO — REFACTORED V3
--
-- STRUKTUR FILE (cari dengan Ctrl+F):
--  [S01] SERVICES & REMOTES
--  [S02] ENGINE CONFIG & KONSTANTA
--  [S03] MAID
--  [S04] NOTIFICATION ENGINE
--  [S05] CONFIG SYSTEM
--  [S06] COMBAT ENGINE & HELPER POSISI
--  [S07] NAVIGATION ENGINE (pencarian monster per World)
--  [S08] FARM LOOP
--  [S09] BACKGROUND LOOPS
--  [S10] GUI COMPONENT BUILDER
--  [S11] TAB SYSTEM
--  [S12] TAB 1 — MAIN FARM
--  [S13] TAB 2 — VECTOR CONFIG
--  [S14] TAB 3 — PROFILE
--  [S15] TAB 4 — SELL
--  [S16] TAB 5 — ROOM HUB
--  [S17] TAB 6 — AUTO BUY
--  [S18] TAB 7 — FORGE & UTILITIES
--  [S19] SYNC ALL VISUAL UI
--  [S20] FLOATING TOGGLE BUTTON
--  [S21] INISIALISASI
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- [S01] SERVICES & REMOTES
--------------------------------------------------------------------------------
local Services = setmetatable({}, {
    __index = function(self, key)
        local s = game:GetService(key)
        if s then self[key] = s end; return s
    end
})

local LocalPlayer  = Services.Players.LocalPlayer
local Workspace    = Services.Workspace
local TweenService = Services.TweenService

local RS = Services.ReplicatedStorage
local _Remotes  = RS:WaitForChild("Remotes", 10)
local _FW       = RS:WaitForChild("Framework", 10)
local _Gameplay = _FW and _FW:WaitForChild("Gameplay", 10)
local _Features = _FW and _FW:WaitForChild("Features", 10)
local _EqSys    = _Gameplay and _Gameplay:WaitForChild("EquipmentSystem", 10)
local _MatUtil  = _EqSys and _EqSys:WaitForChild("MaterialUtil", 10)
local _WP       = _Gameplay and _Gameplay:WaitForChild("WorldPlace", 10)
local _WU       = _WP and _WP:WaitForChild("WorldUtil", 10)
local _ForgeSys = _Features and _Features:WaitForChild("ForgeSystem", 10)

local PlayerActionRE = _Remotes and _Remotes:WaitForChild("PlayerActionRE", 10)
local GameRoundRE    = _Remotes and _Remotes:WaitForChild("GameRoundRE", 10)
local GameMatchRE    = _Remotes and _Remotes:WaitForChild("GameMatchRE", 10)
local EquipmentRE    = _EqSys and _EqSys:WaitForChild("EquipmentRE", 10)
local ForgeRF        = _ForgeSys and _ForgeSys:WaitForChild("ForgeRF", 10)
local MaterialRE     = _MatUtil and _MatUtil:WaitForChild("RemoteEvent", 10)
local WorldPlaceRE   = _WU and _WU:WaitForChild("RemoteEvent", 10)


--------------------------------------------------------------------------------
-- [S02] ENGINE CONFIG & KONSTANTA
--------------------------------------------------------------------------------

-- Nama world di Farm (display)
local WORLD_NAMES = { "Starless Forest", "Frozen Valley", "Oathlost Castle" }
-- Index internal (1/2/3)
local WORLD_INDEX = { ["Starless Forest"]=1, ["Frozen Valley"]=2, ["Oathlost Castle"]=3 }

-- Posisi farm
local POSITION_MODES = {
    "Orbit Atas", "Orbit Bawah", "Orbit Samping",
    "Diam Atas",  "Diam Bawah",  "Depan Target",
    "Belakang Target", "Acak",
}

-- Preset skill
local SKILL_PRESETS = {
    "Semua (1+2+U)",
    "Skill1 Saja",
    "Skill2 Saja",
    "SkillU Saja",
    "Skill1 + Skill2",
    "Skill1 + SkillU",
    "Skill2 + SkillU",
}

-- Nama world Room (display → internal key)
local ROOM_WORLD_DISPLAY = {
    "Starless Forest", "Frozen Valley", "Oathlost Castle",
    "Cave of Crystal", "Cave of Runes", "Abandoned Courtyard",
}
local ROOM_WORLD_KEY = {
    ["Starless Forest"]     = "World1",
    ["Frozen Valley"]       = "World2",
    ["Oathlost Castle"]     = "World3",
    ["Cave of Crystal"]     = "Cave1",
    ["Cave of Runes"]       = "Cave2",
    ["Abandoned Courtyard"] = "Cave3",
}
-- Apakah world ini Cave?
local function isCaveWorld(displayName)
    return displayName == "Cave of Crystal"
        or displayName == "Cave of Runes"
        or displayName == "Abandoned Courtyard"
end

-- Nama mode
local MODE_NAMES = {
    [1]="Trial", [2]="Challenge", [3]="Penitent", [4]="Torment", [5]="Inferno",
    [6]="Trial", [7]="Challenge", [8]="Penitent", [9]="Torment",[10]="Inferno",
}
local function getModeLabel(n) return n.." - "..(MODE_NAMES[n] or tostring(n)) end

local EngineConfig = {
    -- == FARM TOGGLE ==
    AutoFarmMonster   = false,
    AutoSearchMonster = false,  -- pencarian/navigasi monster (terpisah dari attack)
    AutoAttackOnly    = false,
    AutoEggActive     = false,
    AutoReplayActive  = false,
    SelectedWorld     = "Starless Forest",

    -- == TOGGLE CHEST & EGG ==
    AutoChestActive   = false,  -- fokus chest, abaikan enemy

    -- == METODE & POSISI ==
    FarmMethod   = "CFrame",
    FarmPosition = "Orbit Atas",
    LerpAlpha    = 0.3,

    -- == PARAMETER GERAK ==
    StandHeight   = 20,
    BossHeight    = 25,
    OrbitRadius   = 12,
    OrbitSpeed    = 5,
    CFrameDelay   = 0.001,
    HitMultiplier = 1,
    IsLockDelay   = false,

    -- == SKILL ==
    AutoSkillActive    = false,
    SkillPreset        = "Semua (1+2+U)",
    SkillCooldownDelay = 0.5,

    -- == WEAPON ==
    AutoWeaponSwitchActive = false,

    -- == TARGET ==
    SelectedNormalNpcId = nil,
    SelectedBossNpcId   = nil,

    -- == SELL ==
    SellCategory       = "All",
    AutoSellStaticList = {},

    -- == AUTO BUY ==
    AutoBuyActive     = false,
    AutoBuyTargetList = {},

    -- == ROOM HUB ==
    RoomWorldDisplay = "Starless Forest",
    RoomModeType     = "Normal",     -- "Normal" | "Hell"
    RoomMode         = 1,
    RoomPlayers      = 4,
    RoomTarget       = "Room1",

    -- == FORGE (nilai tetap 1, tidak ada UI) ==
    ForgeQTEBase          = 1,
    ForgeQTEMultiplier    = 1,
    ForgeFinishBase       = 1,
    ForgeFinishMultiplier = 1,
    ForgeResultBase       = 1,
    ForgeResultMultiplier = 1,

    -- == SYSTEM GUARD ==
    AntiAFKActive    = false,
    AntiPausedActive = false,
    AutoExecuteOnRejoin  = false,
}

local GameLists = { NormalNPCs = {"None"}, BossNPCs = {"None"} }


--------------------------------------------------------------------------------
-- [S03] MAID
--------------------------------------------------------------------------------
local Maid = {}; Maid.__index = Maid
function Maid.new() return setmetatable({tasks={}}, Maid) end
function Maid:GiveTask(t) table.insert(self.tasks, t); return t end
function Maid:DoCleaning()
    for _, item in ipairs(self.tasks) do
        if type(item)=="function" then item()
        elseif typeof(item)=="RBXScriptConnection" then item:Disconnect()
        elseif type(item)=="table" and item.Destroy then item:Destroy() end
    end
    table.clear(self.tasks)
end
local RuntimeMaid = Maid.new()


--------------------------------------------------------------------------------
-- [S04] NOTIFICATION ENGINE
--------------------------------------------------------------------------------
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name="XiFil_Notif"; NotifGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
NotifGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; NotifGui.ResetOnSpawn=false
RuntimeMaid:GiveTask(NotifGui)

local NC = Instance.new("Frame")
NC.Name="Container"; NC.Parent=NotifGui; NC.BackgroundTransparency=1
NC.Size=UDim2.new(0,260,1,-120); NC.Position=UDim2.new(1,-280,0,0); NC.ZIndex=99999
local NL = Instance.new("UIListLayout",NC)
NL.SortOrder=Enum.SortOrder.LayoutOrder; NL.Padding=UDim.new(0,10)
NL.VerticalAlignment=Enum.VerticalAlignment.Bottom; NL.HorizontalAlignment=Enum.HorizontalAlignment.Right

local function CustomNotify(title, text, duration)
    duration = duration or 3
    local W = Instance.new("Frame"); W.Parent=NC; W.BackgroundTransparency=1; W.Size=UDim2.new(0,260,0,60)
    local NF = Instance.new("Frame"); NF.Parent=W; NF.BackgroundColor3=Color3.fromRGB(20,20,27)
    NF.Size=UDim2.new(1,0,1,0); NF.Position=UDim2.new(1,50,0,0); NF.BackgroundTransparency=1
    Instance.new("UICorner",NF).CornerRadius=UDim.new(0,6)
    local Stroke=Instance.new("UIStroke",NF); Stroke.Color=Color3.fromRGB(96,205,255); Stroke.Thickness=1.2; Stroke.Transparency=1
    local Accent=Instance.new("Frame",NF); Accent.BackgroundColor3=Color3.fromRGB(96,205,255)
    Accent.Size=UDim2.new(0,3,0,0); Accent.Position=UDim2.new(0,12,0.5,0); Accent.AnchorPoint=Vector2.new(0,0.5)
    Accent.BackgroundTransparency=1; Instance.new("UICorner",Accent).CornerRadius=UDim.new(1,0)
    local TL=Instance.new("TextLabel",NF); TL.BackgroundTransparency=1; TL.Size=UDim2.new(1,-34,0,20); TL.Position=UDim2.new(0,24,0,10)
    TL.Font=Enum.Font.GothamBold; TL.Text=string.upper(title); TL.TextColor3=Color3.fromRGB(96,205,255); TL.TextSize=12; TL.TextXAlignment=Enum.TextXAlignment.Left; TL.TextTransparency=1
    local BL=Instance.new("TextLabel",NF); BL.BackgroundTransparency=1; BL.Size=UDim2.new(1,-34,0,20); BL.Position=UDim2.new(0,24,0,30)
    BL.Font=Enum.Font.Gotham; BL.Text=text; BL.TextColor3=Color3.fromRGB(200,200,200); BL.TextSize=11; BL.TextXAlignment=Enum.TextXAlignment.Left; BL.TextTransparency=1
    local ti=TweenInfo.new(0.4,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
    TweenService:Create(NF,ti,{Position=UDim2.new(0,0,0,0),BackgroundTransparency=0.1}):Play()
    TweenService:Create(Stroke,ti,{Transparency=0}):Play()
    TweenService:Create(TL,ti,{TextTransparency=0}):Play()
    TweenService:Create(BL,ti,{TextTransparency=0}):Play()
    TweenService:Create(Accent,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,3,1,-24),BackgroundTransparency=0}):Play()
    task.delay(duration,function()
        local to=TweenInfo.new(0.4,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
        TweenService:Create(NF,to,{Position=UDim2.new(1,50,0,0),BackgroundTransparency=1}):Play()
        TweenService:Create(Stroke,to,{Transparency=1}):Play()
        TweenService:Create(TL,to,{TextTransparency=1}):Play()
        TweenService:Create(BL,to,{TextTransparency=1}):Play()
        TweenService:Create(W,to,{Size=UDim2.new(0,260,0,0)}):Play()
        task.wait(0.4); W:Destroy()
    end)
end


--------------------------------------------------------------------------------
-- [S05] CONFIG SYSTEM
--------------------------------------------------------------------------------
local HttpService = Services.HttpService
local FOLDER_NAME = "XiFilPro_Configs"
if not isfolder(FOLDER_NAME) then pcall(makefolder,FOLDER_NAME) end

local ConfigSystem = {}
function ConfigSystem.GetAutoLoadPointer()
    local p=FOLDER_NAME.."/autoload_pointer.txt"
    if isfile(p) then local ok,c=pcall(readfile,p); if ok and c then return c end end
    return "None"
end
function ConfigSystem.SaveAutoLoadPointer(n) pcall(writefile,FOLDER_NAME.."/autoload_pointer.txt",tostring(n)) end
function ConfigSystem.GetConfigList()
    local list={"None"}; local ok,files=pcall(listfiles,FOLDER_NAME)
    if ok and files then for _,f in ipairs(files) do
        local n=f:match("([^\\/]+)%.json$")
        if n and n~="autoload_pointer" then table.insert(list,n) end
    end end; return list
end
function ConfigSystem.SaveNew(name)
    if name=="" or name=="None" then return false,"Nama tidak valid!" end
    local ok,encoded=pcall(HttpService.JSONEncode,HttpService,EngineConfig)
    if not ok then return false,"Gagal encode." end
    if pcall(writefile,FOLDER_NAME.."/"..name..".json",encoded) then return true else return false,"I/O Error." end
end
function ConfigSystem.OverwriteExisting(name) return ConfigSystem.SaveNew(name) end
function ConfigSystem.Load(name,callback)
    if name=="None" then return false end
    local path=FOLDER_NAME.."/"..name..".json"
    if isfile(path) then
        local rok,content=pcall(readfile,path)
        if rok and content then
            local dok,data=pcall(HttpService.JSONDecode,HttpService,content)
            if dok and type(data)=="table" then
                for k,v in pairs(data) do if EngineConfig[k]~=nil then EngineConfig[k]=v end end
                if callback then callback() end; return true
            end
        end
    end; return false
end
function ConfigSystem.Delete(name)
    if name=="None" then return false end
    local p=FOLDER_NAME.."/"..name..".json"
    if isfile(p) then return pcall(delfile,p) end; return false
end
function ConfigSystem.ExecuteAutoLoad(callback)
    local target=ConfigSystem.GetAutoLoadPointer()
    if target and target~="None" then
        task.spawn(function()
            task.wait(0.5)
            if ConfigSystem.Load(target,callback) then CustomNotify("⚡ AUTOLOAD","Profil: "..target,3) end
        end)
    end
end


--------------------------------------------------------------------------------
-- [S06] COMBAT ENGINE & HELPER POSISI
--------------------------------------------------------------------------------

-- Hitung CFrame tujuan berdasarkan mode posisi
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

-- Terapkan gerakan: CFrame langsung atau Lerp
local function ApplyMovement(hrp, targetCF)
    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
    if EngineConfig.FarmMethod=="Lerp" then
        hrp.CFrame=hrp.CFrame:Lerp(targetCF,math.clamp(EngineConfig.LerpAlpha,0.01,1))
    else
        hrp.CFrame=targetCF
    end
end

local CombatEngine = {}
function CombatEngine.ResetPhysics(hrp)
    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
end
function CombatEngine.InterruptableStall(duration,conditionCheck)
    local elapsed=0
    while elapsed<duration do
        if conditionCheck() then return true end
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
function CombatEngine.TargetsExistGlobal()
    return #CombatEngine.GetValidChests()>0 or #CombatEngine.GetValidMonsters()>0
end

-- Victory UI
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
local function checkVictoryUi()
    local pGui=LocalPlayer:FindFirstChild("PlayerGui"); if not pGui then return false end
    for _,desc in ipairs(pGui:GetDescendants()) do if isVictoryText(desc) then return true end end
    return false
end

local ToggleControl=nil

local function FireReplayRemote()
    if not EngineConfig.AutoReplayActive then return end
    task.wait(1.0)
    local ok,err=pcall(function() GameRoundRE:FireServer("VotePlayAgain") end)
    if ok then CustomNotify("🔄 REPLAY","Sinyal dikirim!",3)
    else CustomNotify("⚠️ REPLAY ERROR","Gagal: "..tostring(err),3) end
end

local function DisableAutoFarm(reason)
    if not EngineConfig.AutoFarmMonster then return end
    EngineConfig.AutoFarmMonster=false
    if ToggleControl and ToggleControl.SetValue then ToggleControl:SetValue(false)
    elseif _G.FarmMonsterToggle and _G.FarmMonsterToggle.SetValue then _G.FarmMonsterToggle:SetValue(false) end
    CustomNotify("🚨 FARM OFF",reason,4)
    if reason:find("Victory") then task.spawn(FireReplayRemote) end
end

local uiConn=LocalPlayer:WaitForChild("PlayerGui").DescendantAdded:Connect(function(desc)
    task.wait(0.2); if isVictoryText(desc) then DisableAutoFarm("Victory Screen Detected") end
end)
RuntimeMaid:GiveTask(uiConn)


-------------------------------------------------------------------------------
-- [S07] NAVIGATION ENGINE (MODERN FRAMEWORK)
-- Logika navigasi diambil dari MODERN Object-Oriented Framework,
-- diadaptasi penuh untuk sistem nama world dan toggle XiFil Pro V3.
-- World 1 = Starless Forest (idx 1), World 2 = Frozen Valley (idx 2), World 3 = Oathlost Castle (idx 3)
--------------------------------------------------------------------------------
local Navigation = {}

-- Fungsi ini menggunakan pendekatan deterministik.
-- Sistem mengutamakan part fisik bernama "Root" yang berada di permukaan tanah.
-- Jika tidak ditemukan, fallback aman menggunakan GetPivot() dijalankan.
function Navigation.GetPortalRootCFrame(portalInstance)
    if not portalInstance then return nil end

    -- Mencari komponen fisik detektor ground-level secara langsung
    local root = portalInstance:FindFirstChild("Root")
    if root and root:IsA("BasePart") then
        return root.CFrame
    end

    -- Fallback aman untuk mempertahankan kompatibilitas model umum
    if portalInstance:IsA("Model") then
        return portalInstance.PrimaryPart and portalInstance.PrimaryPart.CFrame or portalInstance:GetPivot()
    elseif portalInstance:IsA("BasePart") then
        return portalInstance.CFrame
    end
    return nil
end

-- Menambahkan penanganan aman terhadap parameter worldIdx.
-- Menerapkan perbandingan string secara ketat (==) pada World 1 & 2 untuk mencegah salah target
-- ke objek dekoratif langit, serta mempertahankan pencocokan pola khusus untuk World 3.
function Navigation.GetSingleClosestPortal(portalName, myPosition, worldIdx)
    local roundDoor = Workspace:FindFirstChild("RoundDoor")
    if not roundDoor then return nil end

    local closestPortalRoot = nil
    local shortestDistance = math.huge
    local children = roundDoor:GetChildren()

    -- Penapisan aman untuk mengantisipasi nilai parameter kosong (nil)
    local activeIdx = worldIdx or (WORLD_INDEX[EngineConfig.SelectedWorld] or 1)

    for i = 1, #children do
        local obj = children[i]
        local isMatch = false

        if activeIdx == 3 then
            -- Mempertahankan pola penamaan dinamis untuk World 3 (Oathlost Castle)
            if string.match(obj.Name, "^Portal%d+_%d+$") or string.match(obj.Name, "^%d+_%d+$") then
                isMatch = true
            end
        else
            -- Menggunakan kesetaraan ketat untuk World 1 dan World 2 demi keamanan spasial
            if obj.Name:lower() == portalName:lower() then
                isMatch = true
            end
        end

        if isMatch then
            local cf = Navigation.GetPortalRootCFrame(obj)
            if cf then
                local distance = (myPosition - cf.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPortalRoot = cf
                end
            end
        end
    end
    return closestPortalRoot
end

function Navigation.GetClosestObject(folderName, objectName, myPosition)
    local folder = Workspace:FindFirstChild(folderName) or (folderName == "Workspace" and Workspace)
    if not folder then return nil end

    local closest = nil
    local shortestDistance = math.huge
    local children = folder:GetChildren()

    for i = 1, #children do
        local obj = children[i]
        if obj.Name == objectName or obj.Name:lower():find(objectName:lower()) then
            local cf = obj:IsA("Model") and obj:GetPivot() or (obj:IsA("BasePart") and obj.CFrame)
            if cf then
                local distance = (myPosition - cf.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closest = obj
                end
            end
        end
    end
    return closest
end

-- Cek: apakah ada target aktif sekarang? (chest/egg/monster berdasarkan toggle yang ON)
local function anyActiveTargetExists()
    if (EngineConfig.AutoChestActive or EngineConfig.AutoFarmMonster) and #CombatEngine.GetValidChests()>0 then return true end
    if EngineConfig.AutoEggActive and Workspace:FindFirstChild("DragonEgg") then return true end
    if EngineConfig.AutoFarmMonster and #CombatEngine.GetValidMonsters()>0 then return true end
    -- Pencarian berhenti jika ada chest/egg/monster apapun (agar tidak jalan sia-sia)
    if EngineConfig.AutoSearchMonster and (#CombatEngine.GetValidChests()>0 or Workspace:FindFirstChild("DragonEgg") or #CombatEngine.GetValidMonsters()>0) then return true end
    return false
end

-- ── World 1 (Starless Forest): orbit 3 tier 50/150/250, lalu cari portal, lalu idle ──
function Navigation.SearchWorld1(myHRP, myHum)
    -- [INSTANT CHECK] Jika saat dipanggil ternyata world sudah berubah, langsung batalkan!
    if WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then return end

    myHum.PlatformStand = true
    print("[SYSTEM W1] Room vacant! Searching fallback nodes...")

    local door = Navigation.GetClosestObject("RoundDoor", "Door", myHRP.Position)
    if door then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = door:IsA("Model") and door:GetPivot() or door.CFrame

        local interrupted = CombatEngine.InterruptableStall(0.5, function()
            -- Interrupsi ditambahkan pengecekan SelectedWorld
            return not EngineConfig.AutoSearchMonster or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1
        end)
        if interrupted or anyActiveTargetExists() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then
            myHum.PlatformStand = false; return
        end
    end

    local centerPosition = myHRP.Position
    local steps = 50
    local orbitTiers = {50, 150, 250}

    for tierIndex, currentRadius in ipairs(orbitTiers) do
        if anyActiveTargetExists() or not EngineConfig.AutoSearchMonster or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then break end
        print("[SYSTEM W1] Executing Orbit Tier " .. tierIndex .. " with Radius: " .. currentRadius)

        local lastOrbitCFrame = nil
        for i = 1, steps do
            -- Interrupsi instan di dalam loop pergerakan derajat orbit
            if not EngineConfig.AutoSearchMonster or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then break end

            local angle = (i / steps) * (math.pi * 2)
            local targetPos = centerPosition + Vector3.new(math.cos(angle) * currentRadius, 0, math.sin(angle) * currentRadius)

            CombatEngine.ResetPhysics(myHRP)
            lastOrbitCFrame = CFrame.new(targetPos, centerPosition)
            myHRP.CFrame = lastOrbitCFrame
            Services.RunService.Heartbeat:Wait()
        end

        if lastOrbitCFrame then
            local orbitStalled = CombatEngine.InterruptableStall(2, function()
                if not EngineConfig.AutoSearchMonster or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then return true end
                CombatEngine.ResetPhysics(myHRP)
                myHRP.CFrame = lastOrbitCFrame
            end)
            if orbitStalled or anyActiveTargetExists() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then break end
        end
    end

    if anyActiveTargetExists() or not EngineConfig.AutoSearchMonster or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then
        myHum.PlatformStand = false; return
    end

    local finalCFrame = myHRP.CFrame
    local isInterrupted = CombatEngine.InterruptableStall(5, function()
        if not EngineConfig.AutoSearchMonster or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then return true end
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = finalCFrame
    end)
    if isInterrupted or anyActiveTargetExists() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then
        myHum.PlatformStand = false; return
    end

    local portal = Navigation.GetClosestObject("RoundDoor", "Portal", myHRP.Position)
        or Navigation.GetClosestObject("Workspace", "Portal", myHRP.Position)
    if portal then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = portal:IsA("Model") and portal:GetPivot() or portal.CFrame

        local portalCFrame = myHRP.CFrame
        CombatEngine.InterruptableStall(3, function()
            if not EngineConfig.AutoSearchMonster or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then return true end
            CombatEngine.ResetPhysics(myHRP)
            myHRP.CFrame = portalCFrame
        end)
        if anyActiveTargetExists() or not EngineConfig.AutoSearchMonster or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then
            myHum.PlatformStand = false; return
        end
    end

    -- Idle stall 115 detik menunggu respawn
    if EngineConfig.AutoSearchMonster and not anyActiveTargetExists() and WORLD_INDEX[EngineConfig.SelectedWorld] == 1 then
        local idleCFrame = myHRP.CFrame
        CombatEngine.InterruptableStall(115, function()
            if not EngineConfig.AutoSearchMonster or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then return true end
            CombatEngine.ResetPhysics(myHRP)
            myHRP.CFrame = idleCFrame
        end)
    end
    myHum.PlatformStand = false
end

-- ── World 2 (Frozen Valley): stall → PortalD → Portal → idle ──
function Navigation.SearchWorld2(myHRP, myHum)
    if WORLD_INDEX[EngineConfig.SelectedWorld] ~= 2 then return end

    EngineConfig.IsLockDelay = true
    myHum.PlatformStand = true

    local function globalBreakCondition()
        return not EngineConfig.AutoSearchMonster or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 2
    end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    local portalDCF = Navigation.GetSingleClosestPortal("PortalD", myHRP.Position, 2)
    if portalDCF and not globalBreakCondition() then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = portalDCF
        task.wait(0.1)
    end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end
    if anyActiveTargetExists() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 2 then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    local portalCF = Navigation.GetSingleClosestPortal("Portal", myHRP.Position, 2)
    if portalCF and not globalBreakCondition() then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = portalCF
        task.wait(0.1)
    end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    EngineConfig.IsLockDelay = false
    if anyActiveTargetExists() or not EngineConfig.AutoSearchMonster or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 2 then
        myHum.PlatformStand = false; return
    end

    -- Idle stall 115 detik
    if EngineConfig.AutoSearchMonster and not anyActiveTargetExists() and WORLD_INDEX[EngineConfig.SelectedWorld] == 2 then
        EngineConfig.IsLockDelay = true
        CombatEngine.InterruptableStall(115, function()
            if globalBreakCondition() then return true end
            CombatEngine.ResetPhysics(myHRP)
        end)
        EngineConfig.IsLockDelay = false
    end
    myHum.PlatformStand = false
end

-- ── World 3 (Oathlost Castle): stall → Portal dinamis → idle ──
function Navigation.SearchWorld3(myHRP, myHum)
    if WORLD_INDEX[EngineConfig.SelectedWorld] ~= 3 then return end

    EngineConfig.IsLockDelay = true
    myHum.PlatformStand = true

    local function globalBreakCondition()
        return not EngineConfig.AutoSearchMonster or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 3
    end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    local closestPortalCF = Navigation.GetSingleClosestPortal("Portal", myHRP.Position, 3)
    if closestPortalCF and not globalBreakCondition() then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = closestPortalCF
        task.wait(0.1)
    end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    EngineConfig.IsLockDelay = false
    if anyActiveTargetExists() or not EngineConfig.AutoSearchMonster or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 3 then
        myHum.PlatformStand = false; return
    end

    -- Idle stall 115 detik
    if EngineConfig.AutoSearchMonster and not anyActiveTargetExists() and WORLD_INDEX[EngineConfig.SelectedWorld] == 3 then
        EngineConfig.IsLockDelay = true
        CombatEngine.InterruptableStall(115, function()
            if globalBreakCondition() then return true end
            CombatEngine.ResetPhysics(myHRP)
        end)
        EngineConfig.IsLockDelay = false
    end
    myHum.PlatformStand = false
end


--------------------------------------------------------------------------------
-- [S08] FARM LOOP
-- Satu loop terpadu menangani semua prioritas: Chest > Egg > Enemy.
-- Guard _farmLoopRunning mencegah instance ganda saat toggle dinyalakan ulang.
--------------------------------------------------------------------------------

-- Loop: Auto Attack Only (fire remote saja, tanpa movement)
task.spawn(function()
    while true do
        task.wait(math.max(EngineConfig.CFrameDelay,0.05))
        if EngineConfig.AutoAttackOnly then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _=1,EngineConfig.HitMultiplier do
                    task.defer(function() pcall(function() PlayerActionRE:FireServer("SkillAction","BaseAttack",3,hrp.CFrame) end) end)
                end
            end
        end
    end
end)

-- Guard: cegah loop dobel
local _farmLoopRunning=false

-- Cek apakah loop masih harus berjalan
local function anyFarmToggleActive()
    return EngineConfig.AutoFarmMonster or EngineConfig.AutoChestActive or EngineConfig.AutoEggActive or EngineConfig.AutoSearchMonster
end

--[[
  PRIORITAS (per frame):
  1. Chest  — jika AutoChestActive=true DAN ada chest
              (AutoChestActive mengabaikan enemy sepenuhnya)
  2. Egg    — jika AutoEggActive=true DAN DragonEgg ada di Workspace
              (AutoEggActive mengabaikan enemy, kecuali chest sdh ditangani di atas)
              Fase 1: CFrame tepat 3 stud di atas pusat telur → CFrame sekali ke telur (proximity)
              Fase 2: CFrame ke posisi dropdown (FarmPosition) + semua nilai Vector
  3. Enemy  — jika AutoFarmMonster=true DAN ada monster
  4. Cari   — jika AutoSearchMonster=true DAN tidak ada monster/egg/chest → navigasi pencarian
]]
local function startFarmLoop()
    if _farmLoopRunning then return end
    _farmLoopRunning=true

    local noTargetTimer=0

    while anyFarmToggleActive() do
        if checkVictoryUi() then DisableAutoFarm("Victory UI Found"); break end

        local char=LocalPlayer.Character
        local myHRP=char and char:FindFirstChild("HumanoidRootPart")
        local myHum=char and char:FindFirstChildOfClass("Humanoid")
        if not myHRP or not myHum then task.wait(0.1); continue end

        local worldIdx=WORLD_INDEX[EngineConfig.SelectedWorld] or 1

        -- == GUARD World 2 IsLockDelay ==
        if EngineConfig.AutoSearchMonster and worldIdx==2 and EngineConfig.IsLockDelay and not anyActiveTargetExists() then
            CombatEngine.ResetPhysics(myHRP); Services.RunService.Heartbeat:Wait()

        -- ──────────────── PRIORITAS 1: CHEST ────────────────
        elseif EngineConfig.AutoChestActive and #CombatEngine.GetValidChests()>0 then
            noTargetTimer=0; EngineConfig.IsLockDelay=false
            myHum.PlatformStand=true
            local chestRoot=CombatEngine.GetValidChests()[1].Root
            if chestRoot and chestRoot:IsA("BasePart") then
                local targetCF=GetPositionCFrame(chestRoot.Position,EngineConfig.FarmPosition)
                ApplyMovement(myHRP,targetCF)
                local atkCF=chestRoot.CFrame
                for _=1,EngineConfig.HitMultiplier do
                    task.defer(function() PlayerActionRE:FireServer("SkillAction","BaseAttack",3,atkCF) end)
                end
                task.wait(EngineConfig.CFrameDelay)
            else Services.RunService.Heartbeat:Wait() end

        -- ──────────────── PRIORITAS 2: EGG ────────────────
        elseif EngineConfig.AutoEggActive and Workspace:FindFirstChild("DragonEgg") then
            noTargetTimer=0; EngineConfig.IsLockDelay=false
            local egg=Workspace:FindFirstChild("DragonEgg")
            local ok,eggCF=pcall(function() return egg:GetPivot() end)
            if ok and eggCF then
                local eggPos=eggCF.Position
                myHum.PlatformStand=true

                -- ▶ FASE 1 — Step 1: CFrame tepat 3 stud di atas pusat telur
                CombatEngine.ResetPhysics(myHRP)
                myHRP.CFrame=CFrame.new(eggPos+Vector3.new(0,3,0),eggPos)
                task.wait(0.05)

                -- ▶ FASE 1 — Step 2: CFrame sekali langsung ke telur untuk trigger proximity
                CombatEngine.ResetPhysics(myHRP)
                myHRP.CFrame=CFrame.new(eggPos,eggPos+Vector3.new(0,1,0))
                task.wait(0.05)
                pcall(function()
                    for _,obj in ipairs(egg:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then fireproximityprompt(obj) end
                    end
                end)

                -- ▶ FASE 2: mengikuti dropdown posisi (FarmPosition) + semua nilai Vector
                local dropCF=GetPositionCFrame(eggPos,EngineConfig.FarmPosition)
                ApplyMovement(myHRP,dropCF)

                task.wait(EngineConfig.CFrameDelay)
            else Services.RunService.Heartbeat:Wait() end

        -- ──────────────── PRIORITAS 3: ENEMY ────────────────
        elseif EngineConfig.AutoFarmMonster and #CombatEngine.GetValidMonsters()>0 then
            noTargetTimer=0; EngineConfig.IsLockDelay=false
            myHum.PlatformStand=true
            local monsters=CombatEngine.GetValidMonsters()
            local target=monsters[1]
            local tPart=target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)
            local tHum=target and target:FindFirstChildOfClass("Humanoid")
            if tPart and (not tHum or tHum.Health>0) then
                -- BossHeight jika target boss
                local isBoss=CombatEngine.GetLevelType(target)=="boss"
                local savedH=EngineConfig.StandHeight
                if isBoss then EngineConfig.StandHeight=EngineConfig.BossHeight end
                local targetCF=GetPositionCFrame(tPart.Position,EngineConfig.FarmPosition)
                EngineConfig.StandHeight=savedH
                ApplyMovement(myHRP,targetCF)
                for _=1,EngineConfig.HitMultiplier do
                    task.defer(function() PlayerActionRE:FireServer("SkillAction","BaseAttack",3,tPart.CFrame) end)
                end
                task.wait(EngineConfig.CFrameDelay)
            else Services.RunService.Heartbeat:Wait() end

        -- ──────────────── TIDAK ADA TARGET ────────────────
        else
            myHum.PlatformStand=false
            CombatEngine.ResetPhysics(myHRP)
            noTargetTimer=noTargetTimer+0.1
            task.wait(0.1)
            -- Pencarian monster hanya jika AutoSearchMonster aktif (toggle terpisah)
            if EngineConfig.AutoSearchMonster and noTargetTimer>=3 then
                noTargetTimer=0
                if worldIdx==1 then Navigation.SearchWorld1(myHRP,myHum)
                elseif worldIdx==2 then Navigation.SearchWorld2(myHRP,myHum)
                elseif worldIdx==3 then Navigation.SearchWorld3(myHRP,myHum)
                end
            end
        end
    end

    -- Cleanup saat semua toggle OFF
    pcall(function()
        local char=LocalPlayer.Character
        local myHum=char and char:FindFirstChildOfClass("Humanoid")
        if myHum then myHum.PlatformStand=false end
        EngineConfig.IsLockDelay=false
    end)
    _farmLoopRunning=false
end


--------------------------------------------------------------------------------
-- [S09] BACKGROUND LOOPS
--------------------------------------------------------------------------------

-- Helper: cek skill mana yang aktif berdasarkan preset
local function getActiveSkillsFromPreset(preset)
    if preset=="Semua (1+2+U)"   then return {"Skill1","Skill2","SkillU"}
    elseif preset=="Skill1 Saja" then return {"Skill1"}
    elseif preset=="Skill2 Saja" then return {"Skill2"}
    elseif preset=="SkillU Saja" then return {"SkillU"}
    elseif preset=="Skill1 + Skill2" then return {"Skill1","Skill2"}
    elseif preset=="Skill1 + SkillU" then return {"Skill1","SkillU"}
    elseif preset=="Skill2 + SkillU" then return {"Skill2","SkillU"}
    end
    return {"Skill1","Skill2","SkillU"}
end

-- Loop: Auto Skill
task.spawn(function()
    while true do
        if EngineConfig.AutoSkillActive then
            local skills=getActiveSkillsFromPreset(EngineConfig.SkillPreset)
            for _,skillName in ipairs(skills) do
                for combo=1,3 do
                    pcall(function() PlayerActionRE:FireServer("SkillAction",skillName,combo) end)
                    task.wait(EngineConfig.SkillCooldownDelay)
                end
            end
            task.wait(5)
        else task.wait(0.5) end
    end
end)

-- Loop: Weapon Switcher
task.spawn(function()
    while true do
        if EngineConfig.AutoWeaponSwitchActive then
            pcall(function() EquipmentRE:FireServer("ChangeWeaponSlot") end)
            task.wait(3)
        else task.wait(0.5) end
    end
end)

-- [NOTE] Auto Egg sekarang ditangani oleh startFarmLoop() di [S08] dengan prioritas Chest>Egg>Enemy.
-- Loop terpisah tidak diperlukan lagi.

-- Loop: Auto Buy
task.spawn(function()
    local GoldShopRemote=Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("GoldShopSystem"):WaitForChild("GoldShopUtil"):WaitForChild("RemoteEvent")
    while true do
        task.wait(0.05)
        if EngineConfig.AutoBuyActive then
            local mainGui=LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MainGui")
            local sf=mainGui and mainGui:FindFirstChild("ScreenGoldShop") and mainGui.ScreenGoldShop:FindFirstChild("Content") and mainGui.ScreenGoldShop.Content:FindFirstChild("ScrollingFrame")
            if sf then
                for _,item in pairs(sf:GetChildren()) do
                    if EngineConfig.AutoBuyTargetList[item.Name] then
                        local stockTXT=item:FindFirstChild("StockTXT",true); local harga=0
                        for _,child in pairs(item:GetDescendants()) do
                            if child.Name=="Count" and child:IsA("TextLabel") and not child.Text:find("x") then
                                harga=tonumber(child.Text) or 0 end
                        end
                        if stockTXT and harga~=99 then
                            local stok=tonumber(stockTXT.Text:match("%d+")) or 0
                            if stok>=1 and stok<=9 then
                                pcall(function() GoldShopRemote:FireServer("BuyGoldShopItem",item.Name) end)
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end
    end
end)


--------------------------------------------------------------------------------
-- [S10] GUI COMPONENT BUILDER
--------------------------------------------------------------------------------
RuntimeMaid:DoCleaning()

local CoreGui=Instance.new("ScreenGui")
CoreGui.Name="XiFilPro_Modern"; CoreGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
CoreGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; CoreGui.ResetOnSpawn=false; CoreGui.DisplayOrder=99999
RuntimeMaid:GiveTask(CoreGui)

local function MakeDraggable(topbar,obj)
    local dragging,dragInput,dragStart,startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=obj.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if input==dragInput and dragging then
            local delta=input.Position-dragStart
            obj.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
end

local function CreateSection(parent,titleText)
    local lbl=Instance.new("TextLabel"); lbl.Parent=parent; lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,0,0,24)
    lbl.Font=Enum.Font.GothamBold; lbl.Text=string.upper(titleText); lbl.TextColor3=Color3.fromRGB(96,205,255)
    lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local ul=Instance.new("Frame",lbl); ul.BackgroundColor3=Color3.fromRGB(50,50,70); ul.BorderSizePixel=0
    ul.Size=UDim2.new(1,0,0,1); ul.Position=UDim2.new(0,0,1,0)
end

local function CreateButton(parent,text,callback)
    local btn=Instance.new("TextButton"); btn.Parent=parent; btn.BackgroundColor3=Color3.fromRGB(25,25,35)
    btn.Size=UDim2.new(1,0,0,32); btn.Font=Enum.Font.GothamSemibold; btn.Text=text
    btn.TextColor3=Color3.fromRGB(220,220,220); btn.TextSize=12
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",btn).Color=Color3.fromRGB(45,45,60)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3=Color3.fromRGB(35,35,45) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3=Color3.fromRGB(25,25,35) end)
    btn.MouseButton1Click:Connect(callback); return btn
end

local function CreateToggleUI(parent,text,default,callback)
    local container=Instance.new("Frame"); container.Parent=parent; container.BackgroundColor3=Color3.fromRGB(20,20,27)
    container.Size=UDim2.new(1,0,0,38); Instance.new("UICorner",container).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",container).Color=Color3.fromRGB(40,40,50)
    local lbl=Instance.new("TextLabel"); lbl.Parent=container; lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,12,0,0); lbl.Size=UDim2.new(0.75,0,1,0); lbl.Font=Enum.Font.GothamMedium; lbl.Text=text
    lbl.TextColor3=Color3.fromRGB(210,210,210); lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local tBG=Instance.new("TextButton"); tBG.Parent=container
    tBG.BackgroundColor3=default and Color3.fromRGB(96,205,255) or Color3.fromRGB(40,40,50)
    tBG.Position=UDim2.new(1,-44,0.5,-10); tBG.Size=UDim2.new(0,32,0,20); tBG.Text=""
    Instance.new("UICorner",tBG).CornerRadius=UDim.new(1,0)
    local circle=Instance.new("Frame",tBG); circle.BackgroundColor3=Color3.fromRGB(255,255,255); circle.Size=UDim2.new(0,16,0,16)
    circle.Position=default and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
    Instance.new("UICorner",circle).CornerRadius=UDim.new(1,0)
    local state=default; local api={}
    function api:SetValue(val)
        state=val; tBG.BackgroundColor3=state and Color3.fromRGB(96,205,255) or Color3.fromRGB(40,40,50)
        circle.Position=state and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8); callback(state)
    end
    tBG.MouseButton1Click:Connect(function() api:SetValue(not state) end); return api
end

local function CreateInputUI(parent,text,default,numeric,callback)
    local container=Instance.new("Frame"); container.Parent=parent; container.BackgroundColor3=Color3.fromRGB(20,20,27)
    container.Size=UDim2.new(1,0,0,38); Instance.new("UICorner",container).CornerRadius=UDim.new(0,6)
    local stroke=Instance.new("UIStroke",container); stroke.Color=Color3.fromRGB(40,40,50)
    local lbl=Instance.new("TextLabel"); lbl.Parent=container; lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,12,0,0); lbl.Size=UDim2.new(0.6,0,1,0); lbl.Font=Enum.Font.GothamMedium; lbl.Text=text
    lbl.TextColor3=Color3.fromRGB(210,210,210); lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local boxBG=Instance.new("Frame",container); boxBG.BackgroundColor3=Color3.fromRGB(15,15,20)
    boxBG.Position=UDim2.new(1,-85,0.5,-13); boxBG.Size=UDim2.new(0,75,0,26)
    Instance.new("UICorner",boxBG).CornerRadius=UDim.new(0,4)
    local boxStroke=Instance.new("UIStroke",boxBG); boxStroke.Color=Color3.fromRGB(50,50,60)
    local box=Instance.new("TextBox",boxBG); box.BackgroundTransparency=1; box.Size=UDim2.new(1,0,1,0)
    box.Font=Enum.Font.Gotham; box.Text=tostring(default); box.TextColor3=Color3.fromRGB(255,255,255); box.TextSize=11
    box.Focused:Connect(function() boxStroke.Color=Color3.fromRGB(96,205,255) end)
    box.FocusLost:Connect(function()
        boxStroke.Color=Color3.fromRGB(50,50,60); local val=box.Text
        if numeric then val=tonumber(val) or default; box.Text=tostring(val) end; callback(val)
    end)
    local api={}; function api:SetValue(val) box.Text=tostring(val); callback(val) end; return api
end

local function CreateCycleUI(parent,text,list,default,callback)
    local container=Instance.new("Frame"); container.Parent=parent; container.BackgroundColor3=Color3.fromRGB(20,20,27)
    container.Size=UDim2.new(1,0,0,38); Instance.new("UICorner",container).CornerRadius=UDim.new(0,6)
    Instance.new("UIStroke",container).Color=Color3.fromRGB(40,40,50)
    local lbl=Instance.new("TextLabel"); lbl.Parent=container; lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,12,0,0); lbl.Size=UDim2.new(0.45,0,1,0); lbl.Font=Enum.Font.GothamMedium; lbl.Text=text
    lbl.TextColor3=Color3.fromRGB(210,210,210); lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local btn=Instance.new("TextButton"); btn.Parent=container; btn.BackgroundColor3=Color3.fromRGB(30,30,40)
    btn.Position=UDim2.new(1,-120,0.5,-13); btn.Size=UDim2.new(0,110,0,26); btn.Font=Enum.Font.Gotham; btn.Text=tostring(default)
    btn.TextColor3=Color3.fromRGB(96,205,255); btn.TextSize=11
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4); Instance.new("UIStroke",btn).Color=Color3.fromRGB(60,60,75)
    local idx=1; for i,v in ipairs(list) do if v==default then idx=i; break end end
    local api={CurrentList=list}
    btn.MouseButton1Click:Connect(function()
        idx=idx%#api.CurrentList+1; local val=api.CurrentList[idx]; btn.Text=tostring(val); callback(val)
    end)
    function api:SetValues(nl) api.CurrentList=nl; idx=1; btn.Text=tostring(nl[1] or "None") end
    function api:SetValue(tv)
        for i,v in ipairs(api.CurrentList) do if tostring(v)==tostring(tv) then idx=i; btn.Text=tostring(v); callback(v); break end end
    end; return api
end

local function CreateDropdownUI(parent,text,list,default,callback)
    local container=Instance.new("Frame"); container.Parent=parent; container.BackgroundColor3=Color3.fromRGB(20,20,27)
    container.Size=UDim2.new(1,0,0,38); container.ClipsDescendants=false; container.ZIndex=5
    Instance.new("UICorner",container).CornerRadius=UDim.new(0,6); Instance.new("UIStroke",container).Color=Color3.fromRGB(40,40,50)
    local lbl=Instance.new("TextLabel"); lbl.Parent=container; lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,12,0,0); lbl.Size=UDim2.new(0.45,0,1,0); lbl.Font=Enum.Font.GothamMedium; lbl.Text=text
    lbl.TextColor3=Color3.fromRGB(210,210,210); lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.ZIndex=6
    local mainBtn=Instance.new("TextButton"); mainBtn.Parent=container; mainBtn.BackgroundColor3=Color3.fromRGB(30,30,40)
    mainBtn.Position=UDim2.new(1,-120,0.5,-13); mainBtn.Size=UDim2.new(0,110,0,26); mainBtn.Font=Enum.Font.Gotham
    mainBtn.Text=tostring(default).."  ▼"; mainBtn.TextColor3=Color3.fromRGB(96,205,255); mainBtn.TextSize=11; mainBtn.ZIndex=7
    Instance.new("UICorner",mainBtn).CornerRadius=UDim.new(0,4); Instance.new("UIStroke",mainBtn).Color=Color3.fromRGB(60,60,75)
    local sl=Instance.new("ScrollingFrame"); sl.Name="DD"; sl.Parent=mainBtn; sl.BackgroundColor3=Color3.fromRGB(20,20,27)
    sl.Position=UDim2.new(0,0,1,4); sl.Size=UDim2.new(1,0,0,120); sl.Visible=false; sl.ZIndex=200; sl.ScrollBarThickness=2
    sl.ScrollBarImageColor3=Color3.fromRGB(96,205,255); sl.AutomaticCanvasSize=Enum.AutomaticSize.Y; sl.BorderSizePixel=0
    Instance.new("UIStroke",sl).Color=Color3.fromRGB(96,205,255); Instance.new("UICorner",sl).CornerRadius=UDim.new(0,4)
    Instance.new("UIListLayout",sl).SortOrder=Enum.SortOrder.LayoutOrder
    local api={CurrentList=list,SelectedValue=default}
    local function refreshItems()
        for _,c in ipairs(sl:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _,valName in ipairs(api.CurrentList) do
            local ib=Instance.new("TextButton"); ib.Parent=sl; ib.BackgroundColor3=Color3.fromRGB(20,20,27)
            ib.Size=UDim2.new(1,0,0,26); ib.Font=Enum.Font.Gotham; ib.Text=tostring(valName)
            ib.TextColor3=Color3.fromRGB(220,220,220); ib.TextSize=11; ib.ZIndex=201; ib.BorderSizePixel=0
            ib.MouseEnter:Connect(function() ib.BackgroundColor3=Color3.fromRGB(35,35,45) end)
            ib.MouseLeave:Connect(function() ib.BackgroundColor3=Color3.fromRGB(20,20,27) end)
            ib.MouseButton1Click:Connect(function()
                api.SelectedValue=valName; mainBtn.Text=tostring(valName).."  ▼"
                sl.Visible=false; container.ZIndex=5; callback(valName)
            end)
        end
    end
    mainBtn.MouseButton1Click:Connect(function() sl.Visible=not sl.Visible; container.ZIndex=sl.Visible and 100 or 5 end)
    function api:SetValues(nl) api.CurrentList=nl; api.SelectedValue=nl[1] or "None"; mainBtn.Text=tostring(api.SelectedValue).."  ▼"; refreshItems() end
    function api:SetValue(tv) api.SelectedValue=tv; mainBtn.Text=tostring(tv).."  ▼"; sl.Visible=false; container.ZIndex=5; callback(tv) end
    refreshItems(); return api
end


--------------------------------------------------------------------------------
-- [S11] TAB SYSTEM
--------------------------------------------------------------------------------
local MainWindow=Instance.new("Frame"); MainWindow.Name="MainFrame"; MainWindow.Parent=CoreGui
MainWindow.BackgroundColor3=Color3.fromRGB(15,15,20); MainWindow.Position=UDim2.new(0.5,-250,0.5,-210)
MainWindow.Size=UDim2.new(0,500,0,440); MainWindow.Visible=false
Instance.new("UICorner",MainWindow).CornerRadius=UDim.new(0,10)
local MS=Instance.new("UIStroke",MainWindow); MS.Color=Color3.fromRGB(96,205,255); MS.Transparency=0.5; MS.Thickness=1.5

local TopBar=Instance.new("Frame"); TopBar.Name="TopBar"; TopBar.Parent=MainWindow
TopBar.BackgroundColor3=Color3.fromRGB(20,20,27); TopBar.Size=UDim2.new(1,0,0,38); TopBar.BorderSizePixel=0
Instance.new("UICorner",TopBar).CornerRadius=UDim.new(0,10); MakeDraggable(TopBar,MainWindow)
local TBH=Instance.new("Frame",TopBar); TBH.BackgroundColor3=Color3.fromRGB(20,20,27); TBH.BorderSizePixel=0
TBH.Size=UDim2.new(1,0,0,10); TBH.Position=UDim2.new(0,0,1,-10)

local Title=Instance.new("TextLabel"); Title.Parent=TopBar; Title.BackgroundTransparency=1
Title.Position=UDim2.new(0,16,0,0); Title.Size=UDim2.new(1,-32,1,0); Title.Font=Enum.Font.GothamBold
Title.Text='XIFIL Hub PRO <font color="#ffffff">//IRON SOUL V5</font>'; Title.RichText=true
Title.TextColor3=Color3.fromRGB(96,205,255); Title.TextSize=14; Title.TextXAlignment=Enum.TextXAlignment.Left

local TabSystemFrame=Instance.new("Frame"); TabSystemFrame.Name="TabSystem"; TabSystemFrame.Parent=MainWindow
TabSystemFrame.BackgroundColor3=Color3.fromRGB(20,20,27); TabSystemFrame.Position=UDim2.new(0,12,0,48)
TabSystemFrame.Size=UDim2.new(1,-24,0,30); TabSystemFrame.BorderSizePixel=0
Instance.new("UICorner",TabSystemFrame).CornerRadius=UDim.new(0,6)
local TBL=Instance.new("UIListLayout",TabSystemFrame); TBL.FillDirection=Enum.FillDirection.Horizontal
TBL.SortOrder=Enum.SortOrder.LayoutOrder; TBL.HorizontalAlignment=Enum.HorizontalAlignment.Left; TBL.Padding=UDim.new(0,2)

local ContentFrame=Instance.new("Frame"); ContentFrame.Name="ContentFrame"; ContentFrame.Parent=MainWindow
ContentFrame.BackgroundTransparency=1; ContentFrame.Position=UDim2.new(0,12,0,85); ContentFrame.Size=UDim2.new(1,-24,1,-95)

local TabRegistry={}; local currentActiveTab=nil

local function CreateTab(tabName,order)
    local tabBtn=Instance.new("TextButton"); tabBtn.Name=tabName; tabBtn.Parent=TabSystemFrame; tabBtn.LayoutOrder=order
    tabBtn.BackgroundTransparency=1; tabBtn.Size=UDim2.new(0,58,1,0); tabBtn.Font=Enum.Font.GothamSemibold
    tabBtn.Text=tabName; tabBtn.TextColor3=Color3.fromRGB(150,150,150); tabBtn.TextSize=9
    local Ind=Instance.new("Frame",tabBtn); Ind.Name="Indicator"; Ind.BackgroundColor3=Color3.fromRGB(96,205,255)
    Ind.BorderSizePixel=0; Ind.Size=UDim2.new(0.7,0,0,2); Ind.Position=UDim2.new(0.15,0,1,-2); Ind.Visible=false
    local pageScroll=Instance.new("ScrollingFrame"); pageScroll.Parent=ContentFrame; pageScroll.BackgroundTransparency=1
    pageScroll.Size=UDim2.new(1,0,1,0); pageScroll.ScrollBarThickness=3; pageScroll.AutomaticCanvasSize=Enum.AutomaticSize.Y; pageScroll.Visible=false
    local layout=Instance.new("UIListLayout",pageScroll); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,6)
    local function selectThisTab()
        if currentActiveTab then
            currentActiveTab.Button.BackgroundTransparency=1; currentActiveTab.Button.TextColor3=Color3.fromRGB(150,150,150)
            currentActiveTab.Button.Indicator.Visible=false; currentActiveTab.Page.Visible=false
        end
        tabBtn.BackgroundTransparency=0.5; tabBtn.TextColor3=Color3.fromRGB(255,255,255); Ind.Visible=true; pageScroll.Visible=true
        currentActiveTab={Button=tabBtn,Page=pageScroll}
    end
    tabBtn.MouseButton1Click:Connect(selectThisTab)
    TabRegistry[tabName]={Button=tabBtn,Page=pageScroll,Select=selectThisTab}; return pageScroll
end


--------------------------------------------------------------------------------
-- [S12] TAB 1 — MAIN FARM
--------------------------------------------------------------------------------
local MainFarmPage=CreateTab("🏠 Farm",1)

CreateSection(MainFarmPage,"Farm Engine Control")

-- Toggle: Auto Farm Monster (Prioritas 3: serang enemy yang ada)
_G.FarmMonsterToggle=CreateToggleUI(MainFarmPage,"🗡️ Auto Farm Monster ",EngineConfig.AutoFarmMonster,function(v)
    EngineConfig.AutoFarmMonster=v
    if v then
        if checkVictoryUi() then task.spawn(function() DisableAutoFarm("Victory aktif.") end)
        else task.spawn(startFarmLoop) end
    end
end)
ToggleControl=_G.FarmMonsterToggle

-- Toggle: Auto Search Monster (navigasi cari monster — aktif jika tidak ada monster/egg/chest)
_G.AutoSearchToggle=CreateToggleUI(MainFarmPage,"🔍 Auto Find Monster (World) ",EngineConfig.AutoSearchMonster,function(v)
    EngineConfig.AutoSearchMonster=v
    if v then
        CustomNotify("🔍 AUTO SEARCH","Aktif! Navigasi jika tidak ada target.",2)
        task.spawn(startFarmLoop)
    end
end)

_G.AutoAttackOnlyToggle=CreateToggleUI(MainFarmPage,"⚡ Kill Aura ",EngineConfig.AutoAttackOnly,function(v)
    EngineConfig.AutoAttackOnly=v
end)

-- Toggle: Auto Chest (Prioritas 1 — mengabaikan enemy sepenuhnya)
_G.AutoChestToggle=CreateToggleUI(MainFarmPage,"📦 Auto Chest ",EngineConfig.AutoChestActive,function(v)
    EngineConfig.AutoChestActive=v
    if v then
        CustomNotify("📦 AUTO CHEST","Aktif! Enemy diabaikan.",2)
        task.spawn(startFarmLoop)
    end
end)

-- Toggle: Auto Egg (Prioritas 2 — mengabaikan enemy, didahulukan setelah Chest)
_G.AutoEggToggle=CreateToggleUI(MainFarmPage,"🥚 Auto Egg ",EngineConfig.AutoEggActive,function(v)
    EngineConfig.AutoEggActive=v
    if v then
        CustomNotify("🥚 AUTO EGG","Aktif! F1→3stud+proximity, F2→posisi Vector.",2)
        task.spawn(startFarmLoop)
    end
end)

_G.ReplayToggle=CreateToggleUI(MainFarmPage,"🔄 Auto Play Again",EngineConfig.AutoReplayActive,function(v) EngineConfig.AutoReplayActive=v end)

CreateSection(MainFarmPage,"Target Selector")

_G.WorldDropdown=CreateCycleUI(MainFarmPage,"World",WORLD_NAMES,EngineConfig.SelectedWorld,function(v)
    EngineConfig.SelectedWorld=v
end)

local NormalDropdown=CreateCycleUI(MainFarmPage,"Normal Mob",GameLists.NormalNPCs,"None",function(v)
    EngineConfig.SelectedNormalNpcId=(v~="None") and v or nil
end)
local BossDropdown=CreateCycleUI(MainFarmPage,"Boss Mob",GameLists.BossNPCs,"None",function(v)
    EngineConfig.SelectedBossNpcId=(v~="None") and v or nil
end)

CreateButton(MainFarmPage,"🔄 Scan Map Targets",function()
    local normalIds,bossIds={"None"},{"None"}
    local ef=Workspace:FindFirstChild("EnemyNpc")
    if ef then
        local cn,cb={},{}
        for _,m in ipairs(ef:GetChildren()) do
            local id=CombatEngine.GetNpcId(m)
            if id and id~="" then
                if CombatEngine.GetLevelType(m)=="boss" then
                    if not cb[id] then cb[id]=true; table.insert(bossIds,id) end
                else
                    if not cn[id] then cn[id]=true; table.insert(normalIds,id) end
                end
            end
        end
    end
    GameLists.NormalNPCs=normalIds; GameLists.BossNPCs=bossIds
    NormalDropdown:SetValues(normalIds); BossDropdown:SetValues(bossIds)
    CustomNotify("Scan","Target disinkronkan.",2)
end)

CreateSection(MainFarmPage,"Metode & Posisi Gerakan")

_G.FarmMethodDropdown=CreateCycleUI(MainFarmPage,"Metode",{"CFrame","Lerp"},EngineConfig.FarmMethod,function(v) EngineConfig.FarmMethod=v end)
_G.FarmPositionDropdown=CreateDropdownUI(MainFarmPage,"Posisi Farm",POSITION_MODES,EngineConfig.FarmPosition,function(v) EngineConfig.FarmPosition=v end)
_G.LerpAlphaInput=CreateInputUI(MainFarmPage,"Lerp Alpha (0–1)",EngineConfig.LerpAlpha,false,function(v) EngineConfig.LerpAlpha=math.clamp(tonumber(v) or 0.3,0.01,1) end)

CreateSection(MainFarmPage,"Skill Config")

_G.AutoSkillToggle=CreateToggleUI(MainFarmPage,"🎯 Enable Auto Skill",EngineConfig.AutoSkillActive,function(v)
    EngineConfig.AutoSkillActive=v; if v then CustomNotify("⚔️ SKILL","Auto Skill AKTIF!",2) end
end)

_G.SkillPresetDropdown=CreateDropdownUI(MainFarmPage,"Pilih Skill",SKILL_PRESETS,EngineConfig.SkillPreset,function(v)
    EngineConfig.SkillPreset=v
end)

_G.SkillCooldownInput=CreateInputUI(MainFarmPage,"Skill Cooldown (s)",EngineConfig.SkillCooldownDelay,false,function(v)
    EngineConfig.SkillCooldownDelay=tonumber(v) or 0.5
end)

CreateSection(MainFarmPage,"Weapon Switcher")
_G.AutoSwitchToggle=CreateToggleUI(MainFarmPage,"🎒 Auto Weapon Switcher (3s)",EngineConfig.AutoWeaponSwitchActive,function(v)
    EngineConfig.AutoWeaponSwitchActive=v; if v then CustomNotify("🎒 WEAPON","Switcher AKTIF!",2) end
end)


--------------------------------------------------------------------------------
-- [S13] TAB 2 — VECTOR CONFIG
--------------------------------------------------------------------------------
local VectorPage=CreateTab("⚙️ Vector",2)
CreateSection(VectorPage,"Kinematic System Parameters")

_G.HeightInput=CreateInputUI(VectorPage,"Height Normal Target (Y)",EngineConfig.StandHeight,true,function(v)
    EngineConfig.StandHeight=tonumber(v) or 20
end)
_G.BossHeightInput=CreateInputUI(VectorPage,"Height Boss Target (Y)",EngineConfig.BossHeight,true,function(v)
    EngineConfig.BossHeight=tonumber(v) or 25
end)
_G.RadiusInput=CreateInputUI(VectorPage,"Orbit Radius",EngineConfig.OrbitRadius,true,function(v)
    EngineConfig.OrbitRadius=tonumber(v) or 12
end)
CreateButton(VectorPage,"🎯 Dodge Boss Skil (20)",function() EngineConfig.OrbitRadius=20; _G.RadiusInput:SetValue(20) end)
CreateButton(VectorPage,"🎯 Dodge Boss Skil(200)",function() EngineConfig.OrbitRadius=200; _G.RadiusInput:SetValue(200) end)
_G.SpeedInput=CreateInputUI(VectorPage,"Orbit Speed",EngineConfig.OrbitSpeed,true,function(v)
    EngineConfig.OrbitSpeed=tonumber(v) or 5
end)
_G.DelayInput=CreateInputUI(VectorPage,"CFrame Delay",EngineConfig.CFrameDelay,false,function(v)
    EngineConfig.CFrameDelay=tonumber(v) or 0.001
end)
_G.MultiplierInput=CreateInputUI(VectorPage,"Hit Multiplier",EngineConfig.HitMultiplier,true,function(v)
    EngineConfig.HitMultiplier=tonumber(v) or 1
end)


--------------------------------------------------------------------------------
-- [S14] TAB 3 — PROFILE
--------------------------------------------------------------------------------
local ProfilePage=CreateTab("💾 Profile",3)
CreateSection(ProfilePage,"Data Profiles")
local selectedConfig="None"; local newConfigName=""

local ConfigDropdown=CreateDropdownUI(ProfilePage,"Selected Profile",ConfigSystem.GetConfigList(),"None",function(v) selectedConfig=v end)
CreateInputUI(ProfilePage,"New Profile Name","",false,function(v) newConfigName=tostring(v) end)

local function RefreshConfigDropdown(selectName)
    ConfigDropdown:SetValues(ConfigSystem.GetConfigList())
    if selectName then ConfigDropdown:SetValue(selectName); selectedConfig=selectName end
end

CreateButton(ProfilePage,"➕ Save New Profile",function()
    if newConfigName~="" then
        local ok,err=ConfigSystem.SaveNew(newConfigName)
        if ok then CustomNotify("CONFIG","'"..newConfigName.."' disimpan!",3); task.wait(0.05); RefreshConfigDropdown(newConfigName)
        else CustomNotify("SAVE ERROR",err,4) end
    else CustomNotify("CONFIG WARN","Ketik nama profile!",3) end
end)
CreateButton(ProfilePage,"📂 Load Profile",function()
    if selectedConfig~="None" then
        if ConfigSystem.Load(selectedConfig,function() SyncAllVisualUI() end) then CustomNotify("CONFIG","Dimuat: "..selectedConfig,3)
        else CustomNotify("CONFIG ERROR","File tidak valid.",3) end
    else CustomNotify("CONFIG WARN","Pilih profile!",3) end
end)
CreateButton(ProfilePage,"⚡ Set as Autoload",function()
    if selectedConfig=="None" then CustomNotify("AUTOLOAD","Pilih profile!",3); return end
    ConfigSystem.SaveAutoLoadPointer(selectedConfig)
    CustomNotify("⚡ AUTOLOAD SET","'"..selectedConfig.."' autoload aktif.",3)
end)
CreateButton(ProfilePage,"❌ Reset Autoload",function()
    ConfigSystem.SaveAutoLoadPointer("None"); CustomNotify("⚡ AUTOLOAD OFF","Autoload di-reset.",3)
end)
CreateButton(ProfilePage,"🔄 Overwrite Profile",function()
    local target=(newConfigName~="") and newConfigName or selectedConfig
    if target and target~="None" and target~="" then
        local ok,err=ConfigSystem.OverwriteExisting(target)
        if ok then CustomNotify("CONFIG","'"..target.."' ditimpa!",3); task.wait(0.05); RefreshConfigDropdown(target)
        else CustomNotify("OVERWRITE ERROR",err,4) end
    else CustomNotify("CONFIG WARN","Pilih profile valid!",3) end
end)
CreateButton(ProfilePage,"🗑️ Hapus Profile",function()
    if selectedConfig~="None" then
        if ConfigSystem.Delete(selectedConfig) then CustomNotify("CONFIG","Dihapus.",3); task.wait(0.05); RefreshConfigDropdown()
        else CustomNotify("CONFIG ERROR","Gagal hapus.",3) end
    else CustomNotify("CONFIG WARN","Pilih target!",3) end
end)

CreateSection(ProfilePage,"System Guard")
_G.AntiAFKToggle=CreateToggleUI(ProfilePage,"🛡️ Anti-AFK",EngineConfig.AntiAFKActive,function(state)
    EngineConfig.AntiAFKActive=state; local VU=Services.VirtualUser
    if state then
        if not getgenv().AntiAFK_Connection then
            getgenv().AntiAFK_Connection=LocalPlayer.Idled:Connect(function()
                VU:CaptureController(); VU:ClickButton2(Vector2.new())
            end)
        end; CustomNotify("GUARD","Anti-AFK aktif.",2)
    else
        if getgenv().AntiAFK_Connection then getgenv().AntiAFK_Connection:Disconnect(); getgenv().AntiAFK_Connection=nil end
        CustomNotify("GUARD","Anti-AFK nonaktif.",2)
    end
end)
_G.AntiPausedToggle=CreateToggleUI(ProfilePage,"⏳ Disable Gameplay Paused",EngineConfig.AntiPausedActive,function(state)
    EngineConfig.AntiPausedActive=state
    Services.GuiService:SetGameplayPausedNotificationEnabled(not state)
    CustomNotify("GUARD",state and "Anti-Paused aktif." or "Nonaktif.",2)
end)

local AUTOEXEC_CODE = 'loadstring(game:HttpGet("https://xifil-hub-production.up.railway.app/api/lua/loader?game=soul_iron"))()'

-- Mendeteksi fungsi queue_on_teleport bawaan executor
local queue_teleport = queue_on_teleport or queueonteleport or syn.queue_on_teleport

_G.AutoExecuteToggle = CreateToggleUI(ProfilePage, "⚡ Auto Exec on Server Hop/Rejoin", EngineConfig.AutoExecuteOnRejoin, function(state)
    EngineConfig.AutoExecuteOnRejoin = state
    
    if state then
        if queue_teleport then
            -- Menambahkan script ke antrean teleportasi
            queue_teleport(AUTOEXEC_CODE)
            CustomNotify("⚡ AUTO EXEC AKTIF", "Script akan otomatis jalan saat pindah server/rejoin.", 4)
        else
            CustomNotify("❌ GAGAL", "Executor kamu tidak mendukung queue_on_teleport.", 4)
        end
    else
        -- Catatan: Kebanyakan executor tidak memiliki fungsi untuk menghapus antrean teleport
        -- Jadi kita hanya memberikan notifikasi bahwa toggle dimatikan untuk sesi berikutnya
        CustomNotify("⚠️ INFO", "Auto Execute dimatikan. Efektif setelah restart game.", 4)
    end
end)

--------------------------------------------------------------------------------
-- [S15] TAB 4 — SELL
--------------------------------------------------------------------------------
local SellPage=CreateTab("💰 Sell",4)
CreateSection(SellPage,"Inventory Management")

local MainGui=LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainGui", 10)
local EquipmentScroll=MainGui:FindFirstChild("ScreenBackpack") and MainGui.ScreenBackpack:FindFirstChild("InventoryFrame") and MainGui.ScreenBackpack.InventoryFrame:FindFirstChild("EquipmentContent") and MainGui.ScreenBackpack.InventoryFrame.EquipmentContent:FindFirstChild("ScrollingFrame")
local OresScroll=MainGui:FindFirstChild("ScreenEquipSell") and MainGui.ScreenEquipSell:FindFirstChild("SellFrame") and MainGui.ScreenEquipSell.SellFrame:FindFirstChild("OresContent") and MainGui.ScreenEquipSell.SellFrame.OresContent:FindFirstChild("ScrollingFrame")
local MaterialsScroll=MainGui:FindFirstChild("ScreenEquipSell") and MainGui.ScreenEquipSell:FindFirstChild("SellFrame") and MainGui.ScreenEquipSell.SellFrame:FindFirstChild("MaterialContent") and MainGui.ScreenEquipSell.SellFrame.MaterialContent:FindFirstChild("ScrollingFrame")

local BulkSelectedUUIDs={}
local SELL_CATEGORIES={"All","Weapon","Helmet","Breastplate","Ore","Material"}

_G.SellCategoryDropdown=CreateDropdownUI(SellPage,"Kategori",SELL_CATEGORIES,EngineConfig.SellCategory,function(v) EngineConfig.SellCategory=v end)

local ItemResultContainer=Instance.new("ScrollingFrame")
ItemResultContainer.Name="IRC"; ItemResultContainer.Parent=SellPage
ItemResultContainer.Size=UDim2.new(1,0,0,200); ItemResultContainer.BackgroundTransparency=1
ItemResultContainer.ScrollBarThickness=3; ItemResultContainer.AutomaticCanvasSize=Enum.AutomaticSize.Y
Instance.new("UIListLayout",ItemResultContainer).Padding=UDim.new(0,5)

local function sellSpesifikNamaItem(listUUIDs,tipeItem)
    if not listUUIDs or #listUUIDs==0 then return end
    if tipeItem=="Material" then pcall(function() MaterialRE:FireServer("Sell",listUUIDs,{}) end)
    elseif tipeItem=="Ore" then pcall(function() ForgeRF:InvokeServer("Sell",listUUIDs) end)
    else pcall(function() EquipmentRE:FireServer("Sell",listUUIDs) end) end
end

local function runInventoryScanner(parentFrame,filterCategory)
    for _,c in ipairs(parentFrame:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    local db={}; for _,cat in ipairs(SELL_CATEGORIES) do db[cat]={} end
    local function insertDB(cat,id,uuid,visual)
        if not db[cat][id] then db[cat][id]={Visual=visual,UUIDs={},OriginalCategory=cat} end
        table.insert(db[cat][id].UUIDs,uuid)
        if not db["All"][id] then db["All"][id]={Visual=visual,UUIDs={},OriginalCategory=cat} end
        table.insert(db["All"][id].UUIDs,uuid)
    end
    if EquipmentScroll then
        for _,slot in ipairs(EquipmentScroll:GetChildren()) do
            if slot:IsA("GuiObject") and slot.Name~="UIListLayout" and slot.Name~="UIPadding" then
                local vis=slot.Name; local nl=slot:FindFirstChild("ItemName",true) or slot:FindFirstChild("Name",true)
                if nl and nl:IsA("TextLabel") then vis=nl.Text end
                local uuid=slot:GetAttribute("UUID") or slot.Name
                local uo=slot:FindFirstChild("UUID",true)
                if uo then uuid=uo:IsA("ValueBase") and uo.Value or uo.Text end
                local check=string.lower(vis.." "..slot.Name)
                local cat="Weapon"
                if check:find("body") or check:find("plate") or check:find("armor") then cat="Breastplate"
                elseif check:find("helm") or check:find("head") or check:find("hat") then cat="Helmet" end
                insertDB(cat,vis,uuid,vis)
            end
        end
    end
    local function scrapeStackables(sg,cn)
        if not sg then return end
        for _,slot in ipairs(sg:GetChildren()) do
            if slot:IsA("GuiObject") and slot.Name~="UIListLayout" and slot.Name~="UIPadding" then
                local idAsli=slot.Name; local io=slot:FindFirstChild("ID",true)
                if io then idAsli=io:IsA("ValueBase") and tostring(io.Value) or io.Text end
                local nl=slot:FindFirstChild("ItemName",true) or slot:FindFirstChild("Name",true)
                local vis=idAsli; if nl and nl:IsA("TextLabel") then vis=nl.Text end
                insertDB(cn,idAsli,idAsli,vis)
            end
        end
    end
    scrapeStackables(OresScroll,"Ore"); scrapeStackables(MaterialsScroll,"Material")
    for targetID,dataObj in pairs(db[filterCategory]) do
        local storageKey=dataObj.OriginalCategory.."_"..targetID
        if (dataObj.OriginalCategory=="Ore" or dataObj.OriginalCategory=="Material") and EngineConfig.AutoSellStaticList[storageKey] then
            BulkSelectedUUIDs[storageKey]={UUIDs=dataObj.UUIDs,Type=dataObj.OriginalCategory}
        end
        local totalItem=#dataObj.UUIDs; local btnText=dataObj.Visual.." [x"..totalItem.."]"
        local ItemBtn=Instance.new("TextButton"); ItemBtn.Name="IR"; ItemBtn.Parent=parentFrame
        ItemBtn.Size=UDim2.new(1,-10,0,30); ItemBtn.Font=Enum.Font.Gotham; ItemBtn.TextSize=12
        ItemBtn.TextXAlignment=Enum.TextXAlignment.Left; ItemBtn.TextColor3=Color3.fromRGB(255,255,255)
        Instance.new("UICorner",ItemBtn).CornerRadius=UDim.new(0,4)
        local function refreshBtnVis()
            if BulkSelectedUUIDs[storageKey] then ItemBtn.BackgroundColor3=Color3.fromRGB(60,120,60); ItemBtn.Text="  ✅ "..btnText
            else ItemBtn.BackgroundColor3=Color3.fromRGB(40,40,50); ItemBtn.Text="  • "..btnText end
        end
        refreshBtnVis()
        ItemBtn.MouseButton1Click:Connect(function()
            if BulkSelectedUUIDs[storageKey] then
                BulkSelectedUUIDs[storageKey]=nil
                if dataObj.OriginalCategory=="Ore" or dataObj.OriginalCategory=="Material" then EngineConfig.AutoSellStaticList[storageKey]=nil end
            else
                BulkSelectedUUIDs[storageKey]={UUIDs=dataObj.UUIDs,Type=dataObj.OriginalCategory}
                if dataObj.OriginalCategory=="Ore" or dataObj.OriginalCategory=="Material" then EngineConfig.AutoSellStaticList[storageKey]=true end
            end; refreshBtnVis()
        end)
    end
end

CreateButton(SellPage,"🔄 Scan Inventory",function()
    runInventoryScanner(ItemResultContainer,EngineConfig.SellCategory)
    CustomNotify("SCANNER","Kategori: "..EngineConfig.SellCategory,2)
end)
CreateButton(SellPage,"💰 Execute Sell",function()
    local eq,ore,mat,cnt={},{},{},0
    for _,d in pairs(BulkSelectedUUIDs) do
        for _,uuid in ipairs(d.UUIDs) do
            if d.Type=="Material" then table.insert(mat,uuid)
            elseif d.Type=="Ore" then table.insert(ore,uuid)
            else table.insert(eq,uuid) end; cnt=cnt+1
        end
    end
    if cnt==0 then CustomNotify("SELL WARN","Tidak ada item!",3); return end
    if #eq>0 then sellSpesifikNamaItem(eq,"Equipment") end
    if #ore>0 then sellSpesifikNamaItem(ore,"Ore") end
    if #mat>0 then sellSpesifikNamaItem(mat,"Material") end
    task.wait(0.5); BulkSelectedUUIDs={}
    runInventoryScanner(ItemResultContainer,EngineConfig.SellCategory)
    CustomNotify("SELL","Jual massal ("..cnt.." item) selesai.",3)
end)

CreateSection(SellPage,"Merchant System")
CreateButton(SellPage,"🛒  Buka Merchant",function()
    local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp=char:WaitForChild("HumanoidRootPart"); local prompt=nil
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local txt=(v.ObjectText..v.ActionText):lower()
            if v.Parent.Name:lower():match("merchant") or txt:match("merchant") or v.Parent.Name:lower():match("shop") or txt:match("shop") then
                prompt=v; break end
        end
    end
    if prompt and prompt.Parent:IsA("BasePart") then
        CombatEngine.ResetPhysics(hrp); hrp.CFrame=prompt.Parent.CFrame*CFrame.new(0,2,0); task.wait(0.3)
        if fireproximityprompt then fireproximityprompt(prompt); CustomNotify("MERCHANT","Terbuka!",3)
        else CustomNotify("WARN","Executor tidak support fireproximityprompt",3) end
    else CustomNotify("MERCHANT ERROR","Gagal menemukan Merchant!",4) end
end)


--------------------------------------------------------------------------------
-- [S16] TAB 5 — ROOM HUB
--------------------------------------------------------------------------------
local RoomPage=CreateTab("🚪 Room",5)
CreateSection(RoomPage,"Matchmaking Control")

-- Status label
local sLblCon=Instance.new("Frame"); sLblCon.Parent=RoomPage; sLblCon.BackgroundColor3=Color3.fromRGB(30,30,40)
sLblCon.Size=UDim2.new(1,0,0,30); Instance.new("UICorner",sLblCon).CornerRadius=UDim.new(0,4)
local statusLbl=Instance.new("TextLabel"); statusLbl.Parent=sLblCon; statusLbl.Size=UDim2.new(1,0,1,0)
statusLbl.BackgroundTransparency=1; statusLbl.Font=Enum.Font.GothamBold; statusLbl.TextSize=11

local RoomMapping={
    World1={"Room1","Room2","Room3","Room4"}, World2={"Room1","Room2","Room3","Room4"},
    World3={"Room1","Room2","Room3","Room4"}, Cave1={"Room5","Room6","Room7","Room8"},
    Cave2={"Room5","Room6","Room7","Room8"},  Cave3={"Room5","Room6","Room7","Room8"},  -- Cave3 ditambahkan
    Season1={"Room9","Room10","Room11","Room12"},
}

-- Helper: bangun daftar mode berdasarkan world & tipe
local function buildModeList(isCave, modeType)
    local list={}
    if isCave then
        -- Cave: hanya mode 1-4
        for i=1,4 do table.insert(list,getModeLabel(i)) end
    elseif modeType=="Hell" then
        -- Hell: mode 6-10
        for i=6,10 do table.insert(list,getModeLabel(i)) end
    else
        -- Normal: mode 1-5
        for i=1,5 do table.insert(list,getModeLabel(i)) end
    end
    return list
end

local function getModeNumber(labelStr)
    local n=tonumber(labelStr:match("^(%d+)"))
    return n or 1
end

-- Referensi dropdown yang perlu di-update lintas-callback
local RoomModeTypeDropdown=nil
local RoomModeDropdown=nil
local RoomTargetDropdown=nil

local function updateModeDropdown(worldDisplay, modeType)
    local cave=isCaveWorld(worldDisplay)
    local list=buildModeList(cave, modeType)
    if RoomModeDropdown then RoomModeDropdown:SetValues(list) end
    EngineConfig.RoomMode=getModeNumber(list[1])
end

-- World selector
_G.RoomWorldDropdown=CreateDropdownUI(RoomPage,"World",ROOM_WORLD_DISPLAY,EngineConfig.RoomWorldDisplay,function(val)
    EngineConfig.RoomWorldDisplay=val
    local key=ROOM_WORLD_KEY[val] or "World1"
    -- Jika Cave, paksa ke Normal mode
    local cave=isCaveWorld(val)
    local modeType=cave and "Normal" or EngineConfig.RoomModeType
    if cave then
        EngineConfig.RoomModeType="Normal"
        if RoomModeTypeDropdown then RoomModeTypeDropdown:SetValue("Normal") end
    end
    updateModeDropdown(val,modeType)
    -- Update room target
    local rooms=RoomMapping[key] or {"Room1"}
    if RoomTargetDropdown then RoomTargetDropdown:SetValues(rooms); EngineConfig.RoomTarget=rooms[1] end
    -- Update status
    statusLbl.Text=val.." — Mode "..EngineConfig.RoomMode; statusLbl.TextColor3=Color3.fromRGB(96,205,255)
    task.spawn(function() pcall(function() WorldPlaceRE:FireServer("SelectWorld",key,EngineConfig.RoomMode) end) end)
end)

-- Mode Type dropdown (Normal / Hell)
RoomModeTypeDropdown=CreateDropdownUI(RoomPage,"Mode Type",{"Normal","Hell"},EngineConfig.RoomModeType,function(val)
    EngineConfig.RoomModeType=val
    updateModeDropdown(EngineConfig.RoomWorldDisplay,val)
end)
_G.RoomModeTypeDropdown=RoomModeTypeDropdown

-- Mode Number dropdown (isi dinamis)
local initModeList=buildModeList(isCaveWorld(EngineConfig.RoomWorldDisplay),EngineConfig.RoomModeType)
RoomModeDropdown=CreateDropdownUI(RoomPage,"Mode",initModeList,getModeLabel(EngineConfig.RoomMode),function(val)
    EngineConfig.RoomMode=getModeNumber(val)
    statusLbl.Text=EngineConfig.RoomWorldDisplay.." — Mode "..EngineConfig.RoomMode
    statusLbl.TextColor3=EngineConfig.RoomMode<=5 and Color3.fromRGB(0,255,127) or Color3.fromRGB(255,64,64)
    task.spawn(function()
        local key=ROOM_WORLD_KEY[EngineConfig.RoomWorldDisplay] or "World1"
        pcall(function() WorldPlaceRE:FireServer("SelectWorld",key,EngineConfig.RoomMode) end)
    end)
end)
_G.RoomModeDropdown=RoomModeDropdown

-- Players
_G.RoomPlayersDropdown=CreateDropdownUI(RoomPage,"Jumlah Player",{1,2,3,4},EngineConfig.RoomPlayers,function(val)
    EngineConfig.RoomPlayers=tonumber(val)
end)

-- Target Room
local initRooms=RoomMapping[ROOM_WORLD_KEY[EngineConfig.RoomWorldDisplay] or "World1"] or {"Room1"}
RoomTargetDropdown=CreateDropdownUI(RoomPage,"Target Room",initRooms,EngineConfig.RoomTarget or initRooms[1],function(val)
    EngineConfig.RoomTarget=val
end)
_G.RoomTargetDropdown=RoomTargetDropdown

-- Init status label
statusLbl.Text=EngineConfig.RoomWorldDisplay.." — Mode "..EngineConfig.RoomMode
statusLbl.TextColor3=EngineConfig.RoomMode<=5 and Color3.fromRGB(0,255,127) or Color3.fromRGB(255,64,64)

CreateSection(RoomPage,"Match Actions")

CreateButton(RoomPage,"🛠️ Create Room",function()
    local key=ROOM_WORLD_KEY[EngineConfig.RoomWorldDisplay] or "World1"
    pcall(function()
        GameMatchRE:FireServer("CreatRoom",key,EngineConfig.RoomMode,EngineConfig.RoomPlayers)
        CustomNotify("MATCHMAKING","Room: "..EngineConfig.RoomWorldDisplay.." [M:"..EngineConfig.RoomMode.."]",3)
    end)
end)

CreateButton(RoomPage,"🚀 TP Room",function()
    local targetRoom=EngineConfig.RoomTarget or "Room1"
    local mrf=Workspace:FindFirstChild("MatchRoom")
    local rf=mrf and mrf:FindFirstChild(targetRoom)
    local tm=rf and rf:FindFirstChild("Touch")
    local tp=tm and tm:FindFirstChild("Part")
    if tp and tp:IsA("BasePart") then
        local char=LocalPlayer.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if hrp then CombatEngine.ResetPhysics(hrp); hrp.CFrame=tp.CFrame; CustomNotify("ROOM TP","Ke "..targetRoom,3) end
    else CustomNotify("ROOM ERROR","Room '"..targetRoom.."' tidak ditemukan!",4) end
end)

-- [RESTORED] Leave Room
CreateButton(RoomPage,"🚪 Leave Room",function()
    pcall(function() GameMatchRE:FireServer("LeaveRoom") end)
    CustomNotify("ROOM","Leave Room dikirim.",2)
end)


--------------------------------------------------------------------------------
-- [S17] TAB 6 — AUTO BUY
--------------------------------------------------------------------------------
local BuyPage=CreateTab("🛒 Buy",6)
TabRegistry["🛒 Buy"].Button.Visible = false
CreateSection(BuyPage,"Gold Shop Auto-Buyer")

local BuyButtonsRef={}
local ShopListContainer=Instance.new("ScrollingFrame")
ShopListContainer.Name="SLC"; ShopListContainer.Parent=BuyPage
ShopListContainer.Size=UDim2.new(1,0,0,220); ShopListContainer.BackgroundTransparency=1
ShopListContainer.ScrollBarThickness=3; ShopListContainer.AutomaticCanvasSize=Enum.AutomaticSize.Y
local SLL=Instance.new("UIListLayout",ShopListContainer); SLL.Padding=UDim.new(0,5); SLL.SortOrder=Enum.SortOrder.LayoutOrder

_G.AutoBuyToggle=CreateToggleUI(BuyPage,"Enable Multi Auto-Buy",EngineConfig.AutoBuyActive,function(v)
    local cnt=0; for _ in pairs(EngineConfig.AutoBuyTargetList) do cnt=cnt+1 end
    if v and cnt==0 then CustomNotify("AUTO BUY WARN","Pilih item dulu!",3); EngineConfig.AutoBuyActive=false; _G.AutoBuyToggle:SetValue(false); return end
    EngineConfig.AutoBuyActive=v; CustomNotify("AUTO BUY",v and ("Berjalan! ("..cnt.." item)") or "Dimatikan.",2)
end)

CreateButton(BuyPage,"🔄 Scan Gold Shop",function()
    for _,c in ipairs(ShopListContainer:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    table.clear(BuyButtonsRef)
    local gui=LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MainGui")
    local sf=gui and gui:FindFirstChild("ScreenGoldShop") and gui.ScreenGoldShop:FindFirstChild("Content") and gui.ScreenGoldShop.Content:FindFirstChild("ScrollingFrame")
    if not sf then CustomNotify("ERROR","Buka toko dulu!",4); return end
    local total=0
    for _,item in ipairs(sf:GetChildren()) do
        if item.Name:find("GoldShop") then
            total=total+1
            local btn=Instance.new("TextButton"); btn.Parent=ShopListContainer; btn.Size=UDim2.new(1,-10,0,30)
            btn.Font=Enum.Font.Gotham; btn.TextSize=11; btn.TextXAlignment=Enum.TextXAlignment.Left
            btn.BackgroundColor3=EngineConfig.AutoBuyTargetList[item.Name] and Color3.fromRGB(60,120,60) or Color3.fromRGB(40,40,50)
            btn.TextColor3=Color3.fromRGB(255,255,255); btn.Text="  "..item.Name
            Instance.new("UICorner",btn).CornerRadius=UDim.new(0,4); BuyButtonsRef[item.Name]=btn
            btn.MouseButton1Click:Connect(function()
                if EngineConfig.AutoBuyTargetList[item.Name] then
                    EngineConfig.AutoBuyTargetList[item.Name]=nil; btn.BackgroundColor3=Color3.fromRGB(40,40,50)
                else EngineConfig.AutoBuyTargetList[item.Name]=true; btn.BackgroundColor3=Color3.fromRGB(60,120,60) end
            end)
        end
    end; CustomNotify("SHOP","Memuat "..total.." item.",3)
end)


--------------------------------------------------------------------------------
-- [S18] TAB 7 — FORGE & UTILITIES
-- Semua input Forge dihapus (nilai sudah tetap 1), Claim dihapus.
-- Ditambah 5 tombol utility (Enchantment, Grocery, dll)
--------------------------------------------------------------------------------
local ForgePage=CreateTab("🔨 Forge & Npc",7)

-- Forge QTE hook berjalan otomatis di background (nilai tetap 1)
local ForgeUtil = nil
pcall(function()
    local forgeUtilObj = _ForgeSys and _ForgeSys:WaitForChild("ForgeUtil", 10)
    if forgeUtilObj then ForgeUtil = require(forgeUtilObj) end
end)
if ForgeUtil then
    if not _G.OriginalQTE then _G.OriginalQTE = ForgeUtil.QTE end
    ForgeUtil.QTE = function(...)
        local args={...}; local data=nil
        for _,v in pairs(args) do if type(v)=="table" and v.UUID then data=v; break end end
        if data then
            task.spawn(function()
                if ForgeRF then
                    ForgeRF:InvokeServer("QTE",{UUID=data.UUID,Rating=15}); task.wait()
                    ForgeRF:InvokeServer("ForgeFinish"); task.wait()
                    ForgeRF:InvokeServer("ForgeResult",true); task.wait()
                end
            end)
        end
        if _G.OriginalQTE then return _G.OriginalQTE(...) end
    end
end

CreateSection(ForgePage,"Forge Utilities")
CreateButton(ForgePage,"🚀 Bypass FORGE",function()
    local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp=char:WaitForChild("HumanoidRootPart"); local prompt=nil
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local txt=(v.ObjectText..v.ActionText):lower()
            if v.Parent.Name:lower():match("forge") or txt:match("forge") or v.Parent.Name:lower():match("craft") or txt:match("craft") then
                prompt=v; break end
        end
    end
    if prompt and prompt.Parent:IsA("BasePart") then
        CombatEngine.ResetPhysics(hrp); hrp.CFrame=prompt.Parent.CFrame*CFrame.new(0,2,0); task.wait(0.3)
        if fireproximityprompt then fireproximityprompt(prompt) end
    else CombatEngine.ResetPhysics(hrp); hrp.CFrame=CFrame.new(122.5,12,-45.8); task.wait(0.3) end
    pcall(function()
        local TaskRE=Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("TaskSystem"):WaitForChild("TaskRE")
        TaskRE:FireServer("UpdateTaskProgress","OpenGUIWindow","ScreenForging")
    end)
    pcall(function()
        local FUI=LocalPlayer.PlayerGui:FindFirstChild("ScreenForging") or LocalPlayer.PlayerGui:FindFirstChild("ForgeGui")
        if FUI then for _,obj in pairs(FUI:GetChildren()) do if obj:IsA("Frame") then obj.Visible=true end end end
    end)
    CustomNotify("FORGE","TP & Bypass Berhasil.",3)
end)

-- Helper: TP & buka UI lewat ProximityPrompt berdasarkan keyword
local function TPAndOpenByKeyword(keywords, notifTitle)
    local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp=char:WaitForChild("HumanoidRootPart"); local prompt=nil
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local txt=string.lower(v.ObjectText..v.ActionText..(v.Parent.Name))
            local matched=false
            for _,kw in ipairs(keywords) do if txt:find(kw) then matched=true; break end end
            if matched then prompt=v; break end
        end
    end
    if prompt and prompt.Parent:IsA("BasePart") then
        CombatEngine.ResetPhysics(hrp); hrp.CFrame=prompt.Parent.CFrame*CFrame.new(0,2,0); task.wait(0.3)
        if fireproximityprompt then
            fireproximityprompt(prompt)
            CustomNotify(notifTitle,"UI berhasil dibuka!",3)
        else CustomNotify("WARN","Executor tidak support fireproximityprompt",3) end
    else CustomNotify(notifTitle.." ERROR","NPC tidak ditemukan!",4) end
end

CreateSection(ForgePage,"NPC Utility Access")

CreateButton(ForgePage,"🔮  Open Enchantment & runes",function()
    TPAndOpenByKeyword({"enchant"},"ENCHANTMENT")
end)

CreateButton(ForgePage,"🛒  Open Grocery",function()
    TPAndOpenByKeyword({"grocery","grocer"},"GROCERY")
end)

CreateButton(ForgePage,"🐾  Open Pet Upgrade",function()
    TPAndOpenByKeyword({"pet","upgrade","petupgrade"},"PET UPGRADE")
end)

CreateButton(ForgePage,"🏕️  Open Pet Expedition",function()
    TPAndOpenByKeyword({"expedition","petexp"},"PET EXPEDITION")
end)

CreateButton(ForgePage,"✨  Open Upgrade Equipment",function()
    TPAndOpenByKeyword({"bless","blessing"},"BLESS EQUIPMENT")
end)

CreateButton(ForgePage,"✨  Open The Guide ",function()
    TPAndOpenByKeyword({"guide","the"},"THE GUIDE")
end)


--------------------------------------------------------------------------------
-- [S19] SYNC ALL VISUAL UI
--------------------------------------------------------------------------------
function SyncAllVisualUI()
    pcall(function()
        -- Tab 1 — Farm
        if _G.FarmMonsterToggle    then _G.FarmMonsterToggle:SetValue(EngineConfig.AutoFarmMonster) end
        if _G.AutoSearchToggle     then _G.AutoSearchToggle:SetValue(EngineConfig.AutoSearchMonster) end
        if _G.AutoAttackOnlyToggle then _G.AutoAttackOnlyToggle:SetValue(EngineConfig.AutoAttackOnly) end
        if _G.AutoChestToggle      then _G.AutoChestToggle:SetValue(EngineConfig.AutoChestActive) end
        if _G.AutoEggToggle        then _G.AutoEggToggle:SetValue(EngineConfig.AutoEggActive) end
        if _G.ReplayToggle         then _G.ReplayToggle:SetValue(EngineConfig.AutoReplayActive) end
        if _G.WorldDropdown        then _G.WorldDropdown:SetValue(EngineConfig.SelectedWorld) end
        -- Tab 1 — Metode & Posisi
        if _G.FarmMethodDropdown   then _G.FarmMethodDropdown:SetValue(EngineConfig.FarmMethod) end
        if _G.FarmPositionDropdown then _G.FarmPositionDropdown:SetValue(EngineConfig.FarmPosition) end
        if _G.LerpAlphaInput       then _G.LerpAlphaInput:SetValue(EngineConfig.LerpAlpha) end
        -- Tab 1 — Skill
        if _G.AutoSkillToggle      then _G.AutoSkillToggle:SetValue(EngineConfig.AutoSkillActive) end
        if _G.SkillPresetDropdown  then _G.SkillPresetDropdown:SetValue(EngineConfig.SkillPreset) end
        if _G.SkillCooldownInput   then _G.SkillCooldownInput:SetValue(EngineConfig.SkillCooldownDelay) end
        if _G.AutoSwitchToggle     then _G.AutoSwitchToggle:SetValue(EngineConfig.AutoWeaponSwitchActive) end
        -- Tab 2 — Vector
        if _G.HeightInput     then _G.HeightInput:SetValue(EngineConfig.StandHeight) end
        if _G.BossHeightInput then _G.BossHeightInput:SetValue(EngineConfig.BossHeight) end
        if _G.RadiusInput     then _G.RadiusInput:SetValue(EngineConfig.OrbitRadius) end
        if _G.SpeedInput      then _G.SpeedInput:SetValue(EngineConfig.OrbitSpeed) end
        if _G.DelayInput      then _G.DelayInput:SetValue(EngineConfig.CFrameDelay) end
        if _G.MultiplierInput then _G.MultiplierInput:SetValue(EngineConfig.HitMultiplier) end
        -- Tab 3 — Guard
        if _G.AntiAFKToggle    then _G.AntiAFKToggle:SetValue(EngineConfig.AntiAFKActive) end
        if _G.AntiPausedToggle then _G.AntiPausedToggle:SetValue(EngineConfig.AntiPausedActive) end     
        if _G.AutoExecuteToggle then _G.AutoExecuteToggle:SetValue(EngineConfig.AutoExecuteOnRejoin) end
        -- Tab 4 — Sell
        if _G.SellCategoryDropdown then _G.SellCategoryDropdown:SetValue(EngineConfig.SellCategory) end
        -- Tab 5 — Room
        if _G.RoomWorldDropdown    then _G.RoomWorldDropdown:SetValue(EngineConfig.RoomWorldDisplay) end
        if _G.RoomModeTypeDropdown then _G.RoomModeTypeDropdown:SetValue(EngineConfig.RoomModeType) end
        if _G.RoomTargetDropdown   then _G.RoomTargetDropdown:SetValue(EngineConfig.RoomTarget) end
    end)
end


--------------------------------------------------------------------------------
-- [S20] FLOATING TOGGLE BUTTON
--------------------------------------------------------------------------------
local ToggleGuiBtn=Instance.new("ScreenGui")
ToggleGuiBtn.Name="XiFil_Toggle"; ToggleGuiBtn.Parent=LocalPlayer:WaitForChild("PlayerGui")
ToggleGuiBtn.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; ToggleGuiBtn.ResetOnSpawn=false; ToggleGuiBtn.DisplayOrder=999988
RuntimeMaid:GiveTask(ToggleGuiBtn)

local BtnContainer=Instance.new("Frame"); BtnContainer.Name="Container"; BtnContainer.Parent=ToggleGuiBtn
BtnContainer.BackgroundTransparency=1; BtnContainer.Position=UDim2.new(0.05,0,0.15,0); BtnContainer.Size=UDim2.fromOffset(85,42)

local floatBtn=Instance.new("TextButton"); floatBtn.Name="IC"; floatBtn.Parent=BtnContainer
floatBtn.BackgroundColor3=Color3.fromRGB(20,20,27); floatBtn.BorderSizePixel=0; floatBtn.Size=UDim2.new(1,0,1,0)
floatBtn.Text="XiFil"; floatBtn.Font=Enum.Font.GothamBlack; floatBtn.TextColor3=Color3.fromRGB(255,255,255)
floatBtn.TextSize=14; floatBtn.AutoButtonColor=false; Instance.new("UICorner",floatBtn).CornerRadius=UDim.new(0,8)

local ButtonStroke=Instance.new("UIStroke",floatBtn)
ButtonStroke.Color=Color3.fromRGB(96,205,255); ButtonStroke.Thickness=1.5; ButtonStroke.Transparency=0.3

local AccentLine=Instance.new("Frame",floatBtn)
AccentLine.BackgroundColor3=Color3.fromRGB(96,205,255); AccentLine.BorderSizePixel=0
AccentLine.Size=UDim2.new(0,20,0,2); AccentLine.Position=UDim2.new(0.5,-10,0.75,0)
Instance.new("UICorner",AccentLine).CornerRadius=UDim.new(1,0)

floatBtn.MouseEnter:Connect(function()
    TweenService:Create(floatBtn,TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(30,30,40)}):Play()
    TweenService:Create(ButtonStroke,TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Transparency=0,Thickness=2}):Play()
end)
floatBtn.MouseLeave:Connect(function()
    TweenService:Create(floatBtn,TweenInfo.new(0.4,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundColor3=Color3.fromRGB(20,20,27)}):Play()
    TweenService:Create(ButtonStroke,TweenInfo.new(0.4,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Transparency=0.3,Thickness=1.5}):Play()
end)
floatBtn.MouseButton1Down:Connect(function()
    TweenService:Create(floatBtn,TweenInfo.new(0.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0.9,0,0.9,0),Position=UDim2.new(0.05,0,0.05,0)}):Play()
end)
floatBtn.MouseButton1Up:Connect(function()
    TweenService:Create(floatBtn,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,0,0,0)}):Play()
end)
floatBtn.MouseButton1Click:Connect(function() MainWindow.Visible=not MainWindow.Visible end)

local function BinderDrag(uiObj)
    local dragging,dragStart,startPos
    local ic=floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=uiObj.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    RuntimeMaid:GiveTask(ic)
    local ich=Services.UserInputService.InputChanged:Connect(function(input)
        if (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) and dragging then
            local delta=input.Position-dragStart
            uiObj.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
    RuntimeMaid:GiveTask(ich)
end
BinderDrag(BtnContainer)


--------------------------------------------------------------------------------
-- [S21] INISIALISASI
--------------------------------------------------------------------------------
TabRegistry["🏠 Farm"].Select()

task.defer(function()
    if EngineConfig.AntiAFKActive    and _G.AntiAFKToggle    then _G.AntiAFKToggle:SetValue(true) end
    if EngineConfig.AntiPausedActive and _G.AntiPausedToggle then _G.AntiPausedToggle:SetValue(true) end
end)

ConfigSystem.ExecuteAutoLoad(function() SyncAllVisualUI() end)

-- Auto-buka window saat pertama kali dijalankan
task.delay(0.5, function()
    MainWindow.Visible = true
end)

CustomNotify("XiFil Engine V4","Iron Soul — Siap!",4)

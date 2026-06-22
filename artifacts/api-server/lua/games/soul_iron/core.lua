--------------------------------------------------------------------------------
-- [MODULE] core.lua — XIFIL Hub PRO
-- Services, EngineConfig, Maid, Notifications, ConfigSystem
-- Receives shared ctx table via (...)
--------------------------------------------------------------------------------
local ctx = ...

-- ── Services ──────────────────────────────────────────────────────────────────
ctx.Services = setmetatable({}, {
    __index = function(self, key)
        local s = game:GetService(key)
        if s then self[key] = s end
        return s
    end
})
local S            = ctx.Services
local LocalPlayer  = S.Players.LocalPlayer
local TweenService = S.TweenService
local Workspace    = S.Workspace

ctx.LocalPlayer  = LocalPlayer
ctx.Workspace    = Workspace
ctx.TweenService = TweenService

-- ── Remotes ───────────────────────────────────────────────────────────────────
local RS = S.ReplicatedStorage
local Remotes = RS:WaitForChild("Remotes", 10)
if Remotes then
    ctx.PlayerActionRE = Remotes:WaitForChild("PlayerActionRE", 10)
    ctx.GameRoundRE    = Remotes:WaitForChild("GameRoundRE", 10)
    ctx.GameMatchRE    = Remotes:WaitForChild("GameMatchRE", 10)
end
local FW = RS:WaitForChild("Framework", 10)
if FW then
    local Gameplay = FW:WaitForChild("Gameplay", 10)
    local Features = FW:WaitForChild("Features", 10)
    if Gameplay then
        local EqSys = Gameplay:WaitForChild("EquipmentSystem", 10)
        if EqSys then
            ctx.EquipmentRE = EqSys:WaitForChild("EquipmentRE", 10)
            local MatUtil = EqSys:WaitForChild("MaterialUtil", 10)
            if MatUtil then ctx.MaterialRE = MatUtil:WaitForChild("RemoteEvent", 10) end
        end
        local WP = Gameplay:WaitForChild("WorldPlace", 10)
        if WP then
            local WU = WP:WaitForChild("WorldUtil", 10)
            if WU then ctx.WorldPlaceRE = WU:WaitForChild("RemoteEvent", 10) end
        end
    end
    if Features then
        local ForgeSys = Features:WaitForChild("ForgeSystem", 10)
        if ForgeSys then ctx.ForgeRF = ForgeSys:WaitForChild("ForgeRF", 10) end
    end
end

-- ── Constants ─────────────────────────────────────────────────────────────────
ctx.WORLD_NAMES = { "Starless Forest", "Frozen Valley", "Oathlost Castle" }
ctx.WORLD_INDEX = { ["Starless Forest"]=1, ["Frozen Valley"]=2, ["Oathlost Castle"]=3 }
ctx.POSITION_MODES = {
    "Orbit Atas","Orbit Bawah","Orbit Samping",
    "Diam Atas","Diam Bawah","Depan Target","Belakang Target","Acak",
}
ctx.SKILL_PRESETS = {
    "Semua (1+2+U)","Skill1 Saja","Skill2 Saja","SkillU Saja",
    "Skill1 + Skill2","Skill1 + SkillU","Skill2 + SkillU",
}
ctx.ROOM_WORLD_DISPLAY = {
    "Starless Forest","Frozen Valley","Oathlost Castle",
    "Cave of Crystal","Cave of Runes","Abandoned Courtyard",
}
ctx.ROOM_WORLD_KEY = {
    ["Starless Forest"]    ="World1",["Frozen Valley"]     ="World2",
    ["Oathlost Castle"]    ="World3",["Cave of Crystal"]   ="Cave1",
    ["Cave of Runes"]      ="Cave2", ["Abandoned Courtyard"]="Cave3",
}
ctx.MODE_NAMES = {
    [1]="Trial",[2]="Challenge",[3]="Penitent",[4]="Torment",[5]="Inferno",
    [6]="Trial",[7]="Challenge",[8]="Penitent",[9]="Torment",[10]="Inferno",
}
function ctx.isCaveWorld(d)
    return d=="Cave of Crystal" or d=="Cave of Runes" or d=="Abandoned Courtyard"
end
function ctx.getModeLabel(n) return n.." - "..(ctx.MODE_NAMES[n] or tostring(n)) end
function ctx.getModeNumber(s) return tonumber(s:match("^(%d+)")) or 1 end

ctx.GameLists = { NormalNPCs={"None"}, BossNPCs={"None"} }

-- ── EngineConfig (new structure) ───────────────────────────────────────────────
ctx.EngineConfig = {
    -- MASTER FARM
    AutoFarm         = false,
    -- Sub-targets (hanya aktif jika AutoFarm=true)
    FarmMonster      = true,
    FarmChest        = false,
    FarmEgg          = false,
    -- Find / Navigate
    AutoFind         = false,
    -- Kill Aura
    AutoAttackOnly   = false,
    -- Replay
    AutoReplayActive = false,
    -- World
    SelectedWorld    = "Starless Forest",
    -- Method & position
    FarmMethod       = "CFrame",
    FarmPosition     = "Orbit Atas",
    LerpAlpha        = 0.3,
    -- Movement
    StandHeight      = 20,
    BossHeight       = 25,
    OrbitRadius      = 12,
    OrbitSpeed       = 5,
    CFrameDelay      = 0.001,
    HitMultiplier    = 1,
    IsLockDelay      = false,
    -- Skill
    AutoSkillActive     = false,
    SkillPreset         = "Semua (1+2+U)",
    SkillCooldownDelay  = 0.5,
    -- Weapon
    AutoWeaponSwitchActive = false,
    -- Target filter
    SelectedNormalNpcId = nil,
    SelectedBossNpcId   = nil,
    -- Sell
    SellCategory       = "All",
    AutoSellStaticList = {},
    -- Auto Buy
    AutoBuyActive     = false,
    AutoBuyTargetList = {},
    -- Room
    RoomWorldDisplay = "Starless Forest",
    RoomModeType     = "Normal",
    RoomMode         = 1,
    RoomPlayers      = 4,
    RoomTarget       = "Room1",
    -- Forge (fixed values, no UI)
    ForgeQTEBase=1,ForgeQTEMultiplier=1,
    ForgeFinishBase=1,ForgeFinishMultiplier=1,
    ForgeResultBase=1,ForgeResultMultiplier=1,
    -- System
    AntiAFKActive         = false,
    AntiPausedActive      = false,
    AutoExecuteOnRejoin   = false,
}

-- GUI appearance config
ctx.GuiConfig = {
    Transparency = 0,           -- 0 opaque → 0.85 very transparent
    Theme        = "Cyan",
    GestureOpen  = "Click",     -- "Slide" or "Click"
    AccentColor  = Color3.fromRGB(96,205,255),
}

-- ── Maid ──────────────────────────────────────────────────────────────────────
local Maid = {}; Maid.__index = Maid
function Maid.new() return setmetatable({tasks={}},Maid) end
function Maid:GiveTask(t) table.insert(self.tasks,t); return t end
function Maid:DoCleaning()
    for _,item in ipairs(self.tasks) do
        if type(item)=="function" then pcall(item)
        elseif typeof(item)=="RBXScriptConnection" then pcall(function() item:Disconnect() end)
        elseif type(item)=="table" and item.Destroy then pcall(function() item:Destroy() end) end
    end
    table.clear(self.tasks)
end
ctx.Maid = Maid

-- Cleanup previous execution's RuntimeMaid
if getgenv().XiFilRuntimeMaid then
    pcall(function() getgenv().XiFilRuntimeMaid:DoCleaning() end)
end
ctx.RuntimeMaid = Maid.new()
getgenv().XiFilRuntimeMaid = ctx.RuntimeMaid
local RuntimeMaid = ctx.RuntimeMaid

-- ── Notification Engine ────────────────────────────────────────────────────────
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name="XiFil_Notif"; NotifGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
NotifGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; NotifGui.ResetOnSpawn=false
RuntimeMaid:GiveTask(NotifGui)

local NC=Instance.new("Frame"); NC.Name="Container"; NC.Parent=NotifGui
NC.BackgroundTransparency=1; NC.Size=UDim2.new(0,270,1,-130); NC.Position=UDim2.new(1,-290,0,0); NC.ZIndex=99999
local NL=Instance.new("UIListLayout",NC)
NL.SortOrder=Enum.SortOrder.LayoutOrder; NL.Padding=UDim.new(0,8)
NL.VerticalAlignment=Enum.VerticalAlignment.Bottom; NL.HorizontalAlignment=Enum.HorizontalAlignment.Right

local function CustomNotify(title, text, duration)
    duration=duration or 3
    local accent=ctx.GuiConfig.AccentColor
    local W=Instance.new("Frame"); W.Parent=NC; W.BackgroundTransparency=1; W.Size=UDim2.new(0,260,0,62)
    local NF=Instance.new("Frame"); NF.Parent=W; NF.BackgroundColor3=Color3.fromRGB(18,18,24)
    NF.Size=UDim2.new(1,0,1,0); NF.Position=UDim2.new(1,55,0,0); NF.BackgroundTransparency=1
    Instance.new("UICorner",NF).CornerRadius=UDim.new(0,8)
    local Stroke=Instance.new("UIStroke",NF); Stroke.Color=accent; Stroke.Thickness=1; Stroke.Transparency=1
    local Bar=Instance.new("Frame",NF); Bar.BackgroundColor3=accent
    Bar.Size=UDim2.new(0,3,0,0); Bar.Position=UDim2.new(0,10,0.5,0); Bar.AnchorPoint=Vector2.new(0,0.5)
    Bar.BackgroundTransparency=1; Instance.new("UICorner",Bar).CornerRadius=UDim.new(1,0)
    local TL=Instance.new("TextLabel",NF); TL.BackgroundTransparency=1
    TL.Size=UDim2.new(1,-32,0,20); TL.Position=UDim2.new(0,22,0,10)
    TL.Font=Enum.Font.GothamBold; TL.Text=string.upper(title)
    TL.TextColor3=accent; TL.TextSize=11; TL.TextXAlignment=Enum.TextXAlignment.Left; TL.TextTransparency=1
    local BL=Instance.new("TextLabel",NF); BL.BackgroundTransparency=1
    BL.Size=UDim2.new(1,-32,0,20); BL.Position=UDim2.new(0,22,0,30)
    BL.Font=Enum.Font.Gotham; BL.Text=text
    BL.TextColor3=Color3.fromRGB(190,190,200); BL.TextSize=11; BL.TextXAlignment=Enum.TextXAlignment.Left; BL.TextTransparency=1
    local tIn=TweenInfo.new(0.4,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
    TweenService:Create(NF,tIn,{Position=UDim2.new(0,0,0,0),BackgroundTransparency=0.08}):Play()
    TweenService:Create(Stroke,tIn,{Transparency=0.3}):Play()
    TweenService:Create(TL,tIn,{TextTransparency=0}):Play()
    TweenService:Create(BL,tIn,{TextTransparency=0}):Play()
    TweenService:Create(Bar,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,3,1,-20),BackgroundTransparency=0}):Play()
    task.delay(duration,function()
        local tO=TweenInfo.new(0.35,Enum.EasingStyle.Quint,Enum.EasingDirection.In)
        TweenService:Create(NF,tO,{Position=UDim2.new(1,55,0,0),BackgroundTransparency=1}):Play()
        TweenService:Create(Stroke,tO,{Transparency=1}):Play()
        TweenService:Create(TL,tO,{TextTransparency=1}):Play()
        TweenService:Create(BL,tO,{TextTransparency=1}):Play()
        TweenService:Create(W,tO,{Size=UDim2.new(0,260,0,0)}):Play()
        task.wait(0.4); W:Destroy()
    end)
end
ctx.CustomNotify = CustomNotify

-- ── ConfigSystem ──────────────────────────────────────────────────────────────
local HttpService = S.HttpService
local FOLDER = "XiFilPro_Configs"
if not isfolder(FOLDER) then pcall(makefolder,FOLDER) end

ctx.ConfigSystem = {}
local CS = ctx.ConfigSystem

function CS.GetAutoLoadPointer()
    local p=FOLDER.."/autoload_pointer.txt"
    if isfile(p) then local ok,c=pcall(readfile,p); if ok and c then return c end end
    return "None"
end
function CS.SaveAutoLoadPointer(n) pcall(writefile,FOLDER.."/autoload_pointer.txt",tostring(n)) end
function CS.GetConfigList()
    local list={"None"}; local ok,files=pcall(listfiles,FOLDER)
    if ok and files then
        for _,f in ipairs(files) do
            local n=f:match("([^\\/]+)%.json$")
            if n and n~="autoload_pointer" then table.insert(list,n) end
        end
    end; return list
end
function CS.SaveNew(name)
    if name=="" or name=="None" then return false,"Nama tidak valid!" end
    local ok,enc=pcall(HttpService.JSONEncode,HttpService,ctx.EngineConfig)
    if not ok then return false,"Gagal encode." end
    if pcall(writefile,FOLDER.."/"..name..".json",enc) then return true else return false,"I/O Error." end
end
function CS.OverwriteExisting(name) return CS.SaveNew(name) end
function CS.Load(name,callback)
    if name=="None" then return false end
    local path=FOLDER.."/"..name..".json"
    if isfile(path) then
        local rok,content=pcall(readfile,path)
        if rok and content then
            local dok,data=pcall(HttpService.JSONDecode,HttpService,content)
            if dok and type(data)=="table" then
                for k,v in pairs(data) do if ctx.EngineConfig[k]~=nil then ctx.EngineConfig[k]=v end end
                if callback then callback() end; return true
            end
        end
    end; return false
end
function CS.Delete(name)
    if name=="None" then return false end
    local p=FOLDER.."/"..name..".json"
    if isfile(p) then return pcall(delfile,p) end; return false
end
function CS.ExecuteAutoLoad(callback)
    local target=CS.GetAutoLoadPointer()
    if target and target~="None" then
        task.spawn(function()
            task.wait(0.5)
            if CS.Load(target,callback) then ctx.CustomNotify("⚡ AUTOLOAD","Profil: "..target,3) end
        end)
    end
end

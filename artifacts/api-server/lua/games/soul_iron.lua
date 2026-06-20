--------------------------------------------------------------------------------
--// XiFil DRM Wrapper — Iron Soul
--------------------------------------------------------------------------------

local SERVER_URL  = "https://xifil-hub-production.up.railway.app"
local KEY_FILE    = "XiFilPro_Configs/license.key"
local FOLDER_NAME = "XiFilPro_Configs"

--------------------------------------------------------------------------------
--// HWID
--------------------------------------------------------------------------------
local function getHWID()
    local parts = {}
    local ok1, cid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok1 and cid and cid ~= "" then table.insert(parts, tostring(cid)) end

    local ok2, uid = pcall(function()
        return tostring(game.Players.LocalPlayer.UserId)
    end)
    if ok2 and uid then table.insert(parts, uid) end

    local ok3, execName = pcall(identifyexecutor)
    if ok3 and execName then table.insert(parts, execName:sub(1, 8)) end

    local raw = table.concat(parts, "|")
    local hash = 0
    for i = 1, #raw do
        hash = (hash * 31 + string.byte(raw, i)) % 2147483647
    end
    return string.format("rbx-%x-%s", hash, tostring(game.Players.LocalPlayer.UserId))
end

--------------------------------------------------------------------------------
--// BACA / SIMPAN KEY
--------------------------------------------------------------------------------
local function readKey()
    if not isfolder(FOLDER_NAME) then pcall(makefolder, FOLDER_NAME) end
    if isfile(KEY_FILE) then
        local ok, content = pcall(readfile, KEY_FILE)
        if ok and content and content:match("%S") then
            return content:gsub("%s+", "")
        end
    end
    return nil
end

local function saveKey(key)
    pcall(function()
        if not isfolder(FOLDER_NAME) then makefolder(FOLDER_NAME) end
        writefile(KEY_FILE, key)
    end)
end

local function deleteKey()
    pcall(function()
        if isfile(KEY_FILE) then delfile(KEY_FILE) end
    end)
end

--------------------------------------------------------------------------------
--// CEK KEY KE API
--------------------------------------------------------------------------------
local function checkLicense(key, hwid)
    local url = string.format(
        "%s/api/license/check?key=%s&hwid=%s",
        SERVER_URL, key, hwid
    )
    local ok, response = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok then return false, "Tidak bisa terhubung ke server." end

    local decoded
    local decOk = pcall(function()
        decoded = game:GetService("HttpService"):JSONDecode(response)
    end)
    if not decOk or not decoded then return false, "Respons server tidak valid." end

    if decoded.status == "success" then
        return true, decoded.message or "OK"
    else
        return false, decoded.message or "Key tidak valid."
    end
end

--------------------------------------------------------------------------------
--// INPUT KEY (GUI)
--------------------------------------------------------------------------------
local function promptKey(callback)
    local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "XiFil_KeyPrompt"
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local bg = Instance.new("Frame", gui)
    bg.Size = UDim2.new(0, 380, 0, 180)
    bg.Position = UDim2.new(0.5, -190, 0.5, -90)
    bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", bg)
    stroke.Color = Color3.fromRGB(96, 205, 255)
    stroke.Thickness = 1.5

    local title = Instance.new("TextLabel", bg)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🔑  XiFil — Masukkan License Key"
    title.TextColor3 = Color3.fromRGB(96, 205, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold

    local hint = Instance.new("TextLabel", bg)
    hint.Size = UDim2.new(1, -20, 0, 20)
    hint.Position = UDim2.new(0, 10, 0, 40)
    hint.BackgroundTransparency = 1
    hint.Text = "Format: XXXX-XXXX-XXXX-XXXX"
    hint.TextColor3 = Color3.fromRGB(130, 130, 150)
    hint.TextSize = 12
    hint.Font = Enum.Font.Gotham
    hint.TextXAlignment = Enum.TextXAlignment.Left

    local input = Instance.new("TextBox", bg)
    input.Size = UDim2.new(1, -20, 0, 38)
    input.Position = UDim2.new(0, 10, 0, 68)
    input.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    input.TextColor3 = Color3.fromRGB(240, 240, 240)
    input.PlaceholderText = "Paste key di sini..."
    input.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
    input.Text = ""
    input.TextSize = 14
    input.Font = Enum.Font.GothamMedium
    input.ClearTextOnFocus = false
    input.BorderSizePixel = 0
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)

    local status = Instance.new("TextLabel", bg)
    status.Size = UDim2.new(1, -20, 0, 20)
    status.Position = UDim2.new(0, 10, 0, 112)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 80, 80)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", bg)
    btn.Size = UDim2.new(1, -20, 0, 36)
    btn.Position = UDim2.new(0, 10, 0, 136)
    btn.BackgroundColor3 = Color3.fromRGB(96, 205, 255)
    btn.TextColor3 = Color3.fromRGB(10, 10, 20)
    btn.Text = "AKTIVASI"
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        local key = input.Text:gsub("%s+", "")
        if #key < 10 then status.Text = "⚠ Key terlalu pendek."; return end

        btn.Text = "Memeriksa..."
        btn.BackgroundColor3 = Color3.fromRGB(60, 130, 160)
        status.Text = ""

        local hwid = getHWID()
        local valid, msg = checkLicense(key, hwid)

        if valid then
            saveKey(key)
            status.TextColor3 = Color3.fromRGB(80, 255, 120)
            status.Text = "✅ " .. msg
            task.wait(0.8)
            gui:Destroy()
            callback(key, hwid)
        else
            deleteKey()
            btn.Text = "AKTIVASI"
            btn.BackgroundColor3 = Color3.fromRGB(96, 205, 255)
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            status.Text = "❌ " .. msg
        end
    end)
end

--------------------------------------------------------------------------------
--// ENTRY POINT
--------------------------------------------------------------------------------
local function startWithDRM(mainScript)
    local hwid = getHWID()
    local savedKey = readKey()

    if savedKey then
        local valid, msg = checkLicense(savedKey, hwid)
        if valid then
            mainScript(savedKey, hwid)
            return
        else
            deleteKey()
        end
    end

    promptKey(function(key, hwidUsed)
        mainScript(key, hwidUsed)
    end)
end

--------------------------------------------------------------------------------
--// IRON SOUL GAME SCRIPT
--------------------------------------------------------------------------------
startWithDRM(function(key, hwid)

--------------------------------------------------------------------------------
--// MODERN OBJECT-ORIENTED & OPTIMIZED FRAMEWORK (TAB SYSTEM VERSION)
--------------------------------------------------------------------------------
local Services = setmetatable({}, {
    __index = function(self, k)
        local service = game:GetService(k)
        if service then self[k] = service end
        return service
    end
})

local LocalPlayer = Services.Players.LocalPlayer
local Workspace = Services.Workspace
local PlayerActionRE = Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerActionRE")
local GameRoundRE = Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GameRoundRE")
local EquipmentRE = Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Gameplay"):WaitForChild("EquipmentSystem"):WaitForChild("EquipmentRE")
local ForgeRF = Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("ForgeSystem"):WaitForChild("ForgeRF")
local MaterialRE = Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Gameplay"):WaitForChild("EquipmentSystem"):WaitForChild("MaterialUtil"):WaitForChild("RemoteEvent")

local EngineConfig = {
    AutoAttackActive = false,
    AutoSkillActive = false,
    AutoWeaponSwitchActive = false,
    RoomWorld = "World1",
    RoomMode = 1,
    RoomPlayers = 4,
    RoomTarget = "Room1",
    AutoBuyActive = false,
    AutoBuyTargetList = {},
    AntiAFKActive = true,
    AntiPausedActive = true,
    ForgeQTEBase = 1,
    ForgeQTEMultiplier = 1,
    ForgeFinishBase = 1,
    ForgeFinishMultiplier = 1,
    ForgeResultBase = 1,
    ForgeResultMultiplier = 1,
    AutoReplayActive = false,
    SelectedWorld = "World 1",
    StandHeight = 20,
    OrbitRadius = 12,
    OrbitSpeed = 5,
    AutoCFrame = true,
    CFrameDelay = 0.05,
    PrioritizeChest = true,
    SelectedNormalNpcId = nil,
    SelectedBossNpcId = nil,
    HitMultiplier = 1,
    SellCategory = "All",
    AutoSellStaticList = {},
    IsLockDelay = false,
    SkillCooldownDelay = 0.5
}

local GameLists = {
    ManualNormalList = {},
    ManualBossList = {},
    NormalNPCs = {"None"},
    BossNPCs = {"None"}
}

--------------------------------------------------------------------------------
--// LOGIKA GLOBAL FILTER VISIBILITY ROOM HUB
--------------------------------------------------------------------------------
function RefreshRoomDropdownVisibility(currentWorld)
    local rawWorldUI = _G.RoomTargetWorldDropdown
    local rawCaveUI = _G.RoomTargetCaveDropdown
    local rawSeasonUI = _G.RoomTargetSeasonDropdown
    if rawWorldUI and rawCaveUI and rawSeasonUI then
        rawWorldUI.Visible = false
        rawCaveUI.Visible = false
        rawSeasonUI.Visible = false
        if string.find(currentWorld, "World") then
            rawWorldUI.Visible = true
            local num = tonumber(string.match(EngineConfig.RoomTarget, "%d+")) or 1
            if num < 1 or num > 4 then
                EngineConfig.RoomTarget = "Room1"
                if _G.RoomTargetWorldDropdown and _G.RoomTargetWorldDropdown.SetValue then _G.RoomTargetWorldDropdown:SetValue("Room1") end
            end
        elseif string.find(currentWorld, "Cave") then
            rawCaveUI.Visible = true
            local num = tonumber(string.match(EngineConfig.RoomTarget, "%d+")) or 5
            if num < 5 or num > 8 then
                EngineConfig.RoomTarget = "Room5"
                if _G.RoomTargetCaveDropdown and _G.RoomTargetCaveDropdown.SetValue then _G.RoomTargetCaveDropdown:SetValue("Room5") end
            end
        elseif string.find(currentWorld, "Season") then
            rawSeasonUI.Visible = true
            local num = tonumber(string.match(EngineConfig.RoomTarget, "%d+")) or 9
            if num < 9 or num > 12 then
                EngineConfig.RoomTarget = "Room9"
                if _G.RoomTargetSeasonDropdown and _G.RoomTargetSeasonDropdown.SetValue then _G.RoomTargetSeasonDropdown:SetValue("Room9") end
            end
        end
    end
end

--------------------------------------------------------------------------------
--// REAL FILE CONFIG SYSTEM
--------------------------------------------------------------------------------
local HttpService = Services.HttpService
local folderName = "XiFilPro_Configs"
if not isfolder(folderName) then pcall(function() makefolder(folderName) end) end

local ConfigSystem = {}

function ConfigSystem.GetAutoLoadPointer()
    local path = folderName .. "/autoload_pointer.txt"
    if isfile(path) then
        local ok, content = pcall(readfile, path)
        if ok and content then return content end
    end
    return "None"
end

function ConfigSystem.SaveAutoLoadPointer(name)
    pcall(writefile, folderName .. "/autoload_pointer.txt", tostring(name))
end

function ConfigSystem.GetConfigList()
    local list = {"None"}
    local ok, files = pcall(listfiles, folderName)
    if ok and files then
        for _, filePath in ipairs(files) do
            local fileName = filePath:match("([^\\/]+)%.json$")
            if fileName and fileName ~= "autoload_pointer" then
                table.insert(list, fileName)
            end
        end
    end
    return list
end

function ConfigSystem.SaveNew(name)
    if name == "" or name == "None" then return false, "Nama config tidak valid!" end
    local path = folderName .. "/" .. name .. ".json"
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, EngineConfig)
    if not ok then return false, "Gagal konversi data konfigurasi." end
    local writeOk = pcall(writefile, path, encoded)
    if writeOk then return true else return false, "I/O Error: Gagal menulis ke berkas disk." end
end

function ConfigSystem.OverwriteExisting(name)
    return ConfigSystem.SaveNew(name)
end

function ConfigSystem.Load(name, callback)
    if name == "None" then return false end
    local path = folderName .. "/" .. name .. ".json"
    if isfile(path) then
        local readOk, content = pcall(readfile, path)
        if readOk and content then
            local decOk, data = pcall(HttpService.JSONDecode, HttpService, content)
            if decOk and type(data) == "table" then
                for k, v in pairs(data) do
                    if EngineConfig[k] ~= nil then EngineConfig[k] = v end
                end
                if callback then callback() end
                return true
            end
        end
    end
    return false
end

function ConfigSystem.Delete(name)
    if name == "None" then return false end
    local path = folderName .. "/" .. name .. ".json"
    if isfile(path) then return pcall(delfile, path) end
    return false
end

function ConfigSystem.ExecuteAutoLoad(callback)
    local target = ConfigSystem.GetAutoLoadPointer()
    if target and target ~= "None" then
        task.spawn(function()
            task.wait(0.5)
            local ok = ConfigSystem.Load(target, callback)
            if ok then CustomNotify("⚡ AUTOLOAD SUCCESS", "Berhasil memuat profil: " .. target, 3) end
        end)
    end
end

local ToggleControl = nil
local ReplayToggleControl = nil

--------------------------------------------------------------------------------
--// MAID/CLEANUP CLASS
--------------------------------------------------------------------------------
local Maid = {}
Maid.__index = Maid
function Maid.new() return setmetatable({ tasks = {} }, Maid) end
function Maid:GiveTask(t) table.insert(self.tasks, t); return t end
function Maid:DoCleaning()
    for _, t in ipairs(self.tasks) do
        if type(t) == "function" then t()
        elseif typeof(t) == "RBXScriptConnection" then t:Disconnect()
        elseif type(t) == "table" and t.Destroy then t:Destroy() end
    end
    table.clear(self.tasks)
end
local RuntimeMaid = Maid.new()

--------------------------------------------------------------------------------
--// MODERN CUSTOM NOTIFICATION ENGINE
--------------------------------------------------------------------------------
local TweenService = Services.TweenService or game:GetService("TweenService")

local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "XiFil_ModernNotif"
NotifGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
NotifGui.ResetOnSpawn = false
RuntimeMaid:GiveTask(NotifGui)

local NotifContainer = Instance.new("Frame")
NotifContainer.Name = "Container"
NotifContainer.Parent = NotifGui
NotifContainer.BackgroundTransparency = 1
NotifContainer.Size = UDim2.new(0, 260, 1, -120)
NotifContainer.Position = UDim2.new(1, -280, 0, 0)
NotifContainer.ZIndex = 99999

local NListLayout = Instance.new("UIListLayout")
NListLayout.Parent = NotifContainer
NListLayout.SortOrder = Enum.SortOrder.LayoutOrder
NListLayout.Padding = UDim.new(0, 10)
NListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

local function CustomNotify(title, text, duration)
    duration = duration or 3
    local Wrapper = Instance.new("Frame")
    Wrapper.Name = "NotifWrapper"
    Wrapper.Parent = NotifContainer
    Wrapper.BackgroundTransparency = 1
    Wrapper.Size = UDim2.new(0, 260, 0, 60)
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Parent = Wrapper
    NotifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
    NotifFrame.Size = UDim2.new(1, 0, 1, 0)
    NotifFrame.Position = UDim2.new(1, 50, 0, 0)
    NotifFrame.BackgroundTransparency = 1
    Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 6)
    local Stroke = Instance.new("UIStroke", NotifFrame)
    Stroke.Color = Color3.fromRGB(96, 205, 255)
    Stroke.Thickness = 1.2
    Stroke.Transparency = 1
    local Accent = Instance.new("Frame", NotifFrame)
    Accent.BackgroundColor3 = Color3.fromRGB(96, 205, 255)
    Accent.Size = UDim2.new(0, 3, 0, 0)
    Accent.Position = UDim2.new(0, 12, 0.5, 0)
    Accent.AnchorPoint = Vector2.new(0, 0.5)
    Accent.BackgroundTransparency = 1
    Instance.new("UICorner", Accent).CornerRadius = UDim.new(1, 0)
    local TitleLbl = Instance.new("TextLabel", NotifFrame)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Size = UDim2.new(1, -34, 0, 20)
    TitleLbl.Position = UDim2.new(0, 24, 0, 10)
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = string.upper(title)
    TitleLbl.TextColor3 = Color3.fromRGB(96, 205, 255)
    TitleLbl.TextSize = 12
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.TextTransparency = 1
    local TextLbl = Instance.new("TextLabel", NotifFrame)
    TextLbl.BackgroundTransparency = 1
    TextLbl.Size = UDim2.new(1, -34, 0, 20)
    TextLbl.Position = UDim2.new(0, 24, 0, 30)
    TextLbl.Font = Enum.Font.Gotham
    TextLbl.Text = text
    TextLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    TextLbl.TextSize = 11
    TextLbl.TextXAlignment = Enum.TextXAlignment.Left
    TextLbl.TextTransparency = 1
    local tweenIn = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(NotifFrame, tweenIn, {Position = UDim2.new(0,0,0,0), BackgroundTransparency = 0.1}):Play()
    TweenService:Create(Stroke, tweenIn, {Transparency = 0}):Play()
    TweenService:Create(TitleLbl, tweenIn, {TextTransparency = 0}):Play()
    TweenService:Create(TextLbl, tweenIn, {TextTransparency = 0}):Play()
    TweenService:Create(Accent, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0,3,1,-24), BackgroundTransparency = 0}):Play()
    task.delay(duration, function()
        local tweenOut = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        TweenService:Create(NotifFrame, tweenOut, {Position = UDim2.new(1,50,0,0), BackgroundTransparency = 1}):Play()
        TweenService:Create(Stroke, tweenOut, {Transparency = 1}):Play()
        TweenService:Create(TitleLbl, tweenOut, {TextTransparency = 1}):Play()
        TweenService:Create(TextLbl, tweenOut, {TextTransparency = 1}):Play()
        TweenService:Create(Accent, tweenOut, {Size = UDim2.new(0,3,0,0), BackgroundTransparency = 1}):Play()
        TweenService:Create(Wrapper, tweenOut, {Size = UDim2.new(0,260,0,0)}):Play()
        task.wait(0.4)
        Wrapper:Destroy()
    end)
end

--------------------------------------------------------------------------------
--// OPTIMIZED AUTO REPLAY & FARM SEQUENCE
--------------------------------------------------------------------------------
local function FireReplayRemote()
    if EngineConfig.AutoReplayActive then
        task.wait(1.0)
        local ok, err = pcall(function() GameRoundRE:FireServer("VotePlayAgain") end)
        if ok then
            CustomNotify("🔄 AUTO REPLAY", "Sinyal 'VotePlayAgain' berhasil dikirim ke server!", 3)
        else
            CustomNotify("⚠️ REPLAY ERROR", "Gagal menghubungi server remote.", 3)
            warn("[SYSTEM REPLAY] Gagal FireServer: " .. tostring(err))
        end
    end
end

local function DisableAutoFarm(reason)
    if EngineConfig.AutoAttackActive then
        EngineConfig.AutoAttackActive = false
        if ToggleControl and ToggleControl.SetValue then
            ToggleControl:SetValue(false)
        elseif _G.FarmToggle and _G.FarmToggle.SetValue then
            _G.FarmToggle:SetValue(false)
        end
        CustomNotify("🚨 AUTO OFF", "Farm selesai: " .. reason, 4)
        if reason:find("Victory") or reason:find("Ui Found") or reason:find("Screen Detected") then
            task.spawn(FireReplayRemote)
        end
    end
end

local function isVictoryText(obj)
    if not obj or not obj:IsA("TextLabel") then return false end
    if not obj.Visible or obj.AbsoluteSize.X == 0 or obj.TextTransparency >= 1 then return false end
    local text = obj.Text:upper()
    if (obj.Name == "FirstClear" and text:find("FIRST CLEAR")) or (obj.Name == "Text" and text:find("VICTORY")) then
        local current = obj.Parent
        while current and not current:IsA("ScreenGui") do
            if current:IsA("GuiObject") and not current.Visible then return false end
            current = current.Parent
        end
        local parent = obj.Parent
        if parent and (parent.Name == "RoundCompleted" or parent.Name == "BTN" or parent.Name == "Victory") then
            return true
        end
    end
    return false
end

local function checkVictoryUi()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return false end
    for _, desc in ipairs(pGui:GetDescendants()) do
        if isVictoryText(desc) then return true end
    end
    return false
end

local uiConnection = LocalPlayer:WaitForChild("PlayerGui").DescendantAdded:Connect(function(desc)
    task.wait(0.2)
    if isVictoryText(desc) then DisableAutoFarm("Victory Screen Detected (Real-time Match)") end
end)
RuntimeMaid:GiveTask(uiConnection)

--------------------------------------------------------------------------------
--// BACKEND CORE ENGINE
--------------------------------------------------------------------------------
local CombatEngine = {}
CombatEngine.__index = CombatEngine

function CombatEngine.ResetPhysics(hrp)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

function CombatEngine.InterruptableStall(duration, conditionCheck)
    local elapsed = 0
    while elapsed < duration do
        if conditionCheck() then return true end
        elapsed = elapsed + Services.RunService.Heartbeat:Wait()
    end
    return false
end

function CombatEngine.GetLevelType(monster)
    local attr = monster:GetAttribute("LevelType")
    if attr then return tostring(attr):lower() end
    local obj = monster:FindFirstChild("LevelType")
    if obj and (obj:IsA("StringValue") or obj:IsA("IntValue")) then return tostring(obj.Value):lower() end
    if monster:FindFirstChild("BossTag") or string.find(string.lower(monster.Name), "boss") then return "boss" end
    return "normal"
end

function CombatEngine.GetNpcId(monster)
    local attr = monster:GetAttribute("NpcId")
    if attr then return tostring(attr) end
    local obj = monster:FindFirstChild("NpcId")
    if obj and (obj:IsA("StringValue") or obj:IsA("IntValue") or obj:IsA("NumberValue")) then return tostring(obj.Value) end
    return monster.Name
end

function CombatEngine.GetValidChests()
    local chests = {}
    local children = Workspace:GetChildren()
    for i = 1, #children do
        local obj = children[i]
        if obj.Name:find("Chest") then
            local root = obj:FindFirstChild("Root") or obj:FindFirstChild("Part") or (obj:IsA("Model") and obj.PrimaryPart)
            if root then table.insert(chests, {Object = obj, Root = root}) end
        end
    end
    return chests
end

function CombatEngine.GetValidMonsters()
    local enemyFolder = Workspace:FindFirstChild("EnemyNpc")
    if not enemyFolder then return {} end
    local normalMonsters, priorityMonsters = {}, {}
    local children = enemyFolder:GetChildren()
    for i = 1, #children do
        local monster = children[i]
        local hrp = monster:FindFirstChild("HumanoidRootPart")
        local humanoid = monster:FindFirstChildOfClass("Humanoid")
        if hrp and (not humanoid or humanoid.Health > 0) then
            local npcId = CombatEngine.GetNpcId(monster)
            local actualLevelType = CombatEngine.GetLevelType(monster)
            if (EngineConfig.SelectedNormalNpcId and npcId == EngineConfig.SelectedNormalNpcId) or
               (EngineConfig.SelectedBossNpcId and npcId == EngineConfig.SelectedBossNpcId) then
                table.insert(priorityMonsters, 1, monster)
            elseif actualLevelType == "boss" then
                table.insert(priorityMonsters, monster)
            else
                table.insert(normalMonsters, monster)
            end
        end
    end
    return #priorityMonsters > 0 and priorityMonsters or normalMonsters
end

function CombatEngine.TargetsExistGlobal()
    if EngineConfig.PrioritizeChest then
        return (#CombatEngine.GetValidChests() > 0 or #CombatEngine.GetValidMonsters() > 0)
    else
        return (#CombatEngine.GetValidMonsters() > 0)
    end
end

--------------------------------------------------------------------------------
--// MAP NAVIGATION
--------------------------------------------------------------------------------
local Navigation = {}

function Navigation.GetPortalRootCFrame(portalInstance)
    if not portalInstance then return nil end
    local root = portalInstance:FindFirstChild("Root")
    if root and root:IsA("BasePart") then return root.CFrame end
    if portalInstance:IsA("Model") then
        return portalInstance.PrimaryPart and portalInstance.PrimaryPart.CFrame or portalInstance:GetPivot()
    elseif portalInstance:IsA("BasePart") then
        return portalInstance.CFrame
    end
    return nil
end

function Navigation.TeleportToWorld(worldContext)
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local HRP = Character:WaitForChild("HumanoidRootPart")
    local portalFolder = Workspace:FindFirstChild("Portal") or Workspace:FindFirstChild("Portals") or Workspace:FindFirstChild("WorldPortals")
    if not portalFolder then warn("[NAV] Portal folder tidak ditemukan."); return false end
    local targetPortal = nil
    for _, portal in ipairs(portalFolder:GetChildren()) do
        local portalName = portal.Name:lower()
        local wCtx = tostring(worldContext):lower()
        if portalName == wCtx or portalName == "portal_" .. wCtx or portalName == wCtx .. "_portal" then
            targetPortal = portal; break
        end
        local attr = portal:GetAttribute("WorldId") or portal:GetAttribute("TargetWorld")
        if attr and tostring(attr):lower() == wCtx then targetPortal = portal; break end
    end
    if not targetPortal then warn("[NAV] Portal untuk world '" .. tostring(worldContext) .. "' tidak ditemukan."); return false end
    local targetCFrame = Navigation.GetPortalRootCFrame(targetPortal)
    if not targetCFrame then warn("[NAV] Gagal mendapatkan CFrame portal."); return false end
    CombatEngine.ResetPhysics(HRP)
    HRP.CFrame = targetCFrame * CFrame.new(0, 3, 0)
    return true
end

--------------------------------------------------------------------------------
--// CORE COMBAT SEQUENCE ENGINE
--------------------------------------------------------------------------------
local function doOrbitAttackSequence(targetHRP, myHRP)
    local cfg = EngineConfig
    local angle = 0
    while cfg.AutoAttackActive do
        local currentEnemy = targetHRP.Parent
        local humanoid = currentEnemy and currentEnemy:FindFirstChildOfClass("Humanoid")
        if not currentEnemy or not currentEnemy.Parent or (humanoid and humanoid.Health <= 0) then break end
        if cfg.AutoCFrame then
            angle = angle + (cfg.OrbitSpeed * cfg.CFrameDelay * math.pi * 2) / 1
            local orbitOffset = Vector3.new(math.cos(angle) * cfg.OrbitRadius, cfg.StandHeight, math.sin(angle) * cfg.OrbitRadius)
            local targetPos = targetHRP.Position + orbitOffset
            local lookCFrame = CFrame.lookAt(targetPos, targetHRP.Position)
            CombatEngine.ResetPhysics(myHRP)
            myHRP.CFrame = lookCFrame
        end
        for i = 1, cfg.HitMultiplier do
            pcall(function() PlayerActionRE:FireServer("Attack", targetHRP.Parent) end)
        end
        task.wait(cfg.CFrameDelay)
    end
end

local function startInfiniteDistanceLoop()
    local cfg = EngineConfig
    while cfg.AutoAttackActive do
        local Character = LocalPlayer.Character
        local myHRP = Character and Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then task.wait(1) end
        if cfg.PrioritizeChest then
            local chests = CombatEngine.GetValidChests()
            if #chests > 0 then
                local chest = chests[1]
                local chestRoot = chest.Root
                while cfg.AutoAttackActive and chestRoot and chestRoot.Parent do
                    if cfg.AutoCFrame then
                        CombatEngine.ResetPhysics(myHRP)
                        myHRP.CFrame = chestRoot.CFrame * CFrame.new(0, cfg.StandHeight, 0)
                    end
                    pcall(function() PlayerActionRE:FireServer("Attack", chest.Object) end)
                    task.wait(cfg.CFrameDelay)
                end
                task.wait(0.1)
            end
        end
        if not cfg.AutoAttackActive then break end
        local monsters = CombatEngine.GetValidMonsters()
        if #monsters > 0 then
            local monster = monsters[1]
            local targetHRP = monster:FindFirstChild("HumanoidRootPart")
            if targetHRP then doOrbitAttackSequence(targetHRP, myHRP) end
        else
            if checkVictoryUi() then DisableAutoFarm("Victory Ui Found — No Targets Remaining"); break end
            task.wait(0.5)
        end
    end
end

--------------------------------------------------------------------------------
--// ROOM HUB ENGINE
--------------------------------------------------------------------------------
local RoomHubEngine = {}
function RoomHubEngine.JoinRoom(worldName, mode, players, targetRoom)
    local ok, err = pcall(function()
        GameRoundRE:FireServer("JoinRoom", {World = worldName, Mode = mode, Players = players, Room = targetRoom})
    end)
    if ok then
        CustomNotify("🏠 ROOM HUB", "Join: " .. tostring(targetRoom) .. " | " .. tostring(worldName), 3)
    else
        CustomNotify("❌ ROOM ERROR", "Gagal join room: " .. tostring(err), 4)
    end
end

--------------------------------------------------------------------------------
--// AUTO SKILL & WEAPON SWITCHER
--------------------------------------------------------------------------------
task.spawn(function()
    while true do
        if EngineConfig.AutoSkillActive then
            pcall(function() PlayerActionRE:FireServer("SkillAction", "Skill1", 1) end)
            task.wait(EngineConfig.SkillCooldownDelay)
            pcall(function() PlayerActionRE:FireServer("SkillAction", "Skill1", 2) end)
            task.wait(EngineConfig.SkillCooldownDelay)
            pcall(function() PlayerActionRE:FireServer("SkillAction", "Skill1", 3) end)
            task.wait(EngineConfig.SkillCooldownDelay)
            pcall(function() PlayerActionRE:FireServer("SkillAction", "Skill2", 1) end)
            task.wait(EngineConfig.SkillCooldownDelay)
            pcall(function() PlayerActionRE:FireServer("SkillAction", "SkillU", 1) end)
            task.wait(5)
        else
            task.wait(0.5)
        end
    end
end)

task.spawn(function()
    while true do
        if EngineConfig.AutoWeaponSwitchActive then
            pcall(function() EquipmentRE:FireServer("ChangeWeaponSlot") end)
            task.wait(3)
        else
            task.wait(0.5)
        end
    end
end)

--------------------------------------------------------------------------------
--// MODERN NATIVE GUI BUILDER WITH MODULAR TAB SYSTEM
--------------------------------------------------------------------------------
RuntimeMaid:DoCleaning()

local CoreGui = Instance.new("ScreenGui")
CoreGui.Name = "XiFilPro_Modern"
CoreGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
CoreGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
CoreGui.ResetOnSpawn = false
RuntimeMaid:GiveTask(CoreGui)
CoreGui.DisplayOrder = 99999

local function MakeDraggable(topbar, obj)
    local dragToggle, dragInput, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true; dragStart = input.Position; startPos = obj.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end)
        end
    end)
    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragToggle then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local MainWindow = Instance.new("Frame")
MainWindow.Name = "MainFrame"
MainWindow.Parent = CoreGui
MainWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainWindow.Position = UDim2.new(0.5, -250, 0.5, -180)
MainWindow.Size = UDim2.new(0, 500, 0, 380)
MainWindow.Visible = false
Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", MainWindow)
MainStroke.Color = Color3.fromRGB(96, 205, 255)
MainStroke.Transparency = 0.5
MainStroke.Thickness = 1.5

local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Parent = MainWindow
TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
TopBar.Size = UDim2.new(1, 0, 0, 38)
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
MakeDraggable(TopBar, MainWindow)
local TopBarHider = Instance.new("Frame", TopBar)
TopBarHider.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
TopBarHider.Size = UDim2.new(1, 0, 0, 10)
TopBarHider.Position = UDim2.new(0, 0, 1, -10)
TopBarHider.BorderSizePixel = 0
local Title = Instance.new("TextLabel")
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 16, 0, 0)
Title.Size = UDim2.new(1, -32, 1, 0)
Title.Font = Enum.Font.GothamBold
Title.Text = "XiFil PRO <font color=\"#ffffff\">// V4 ENGINE</font>"
Title.RichText = true
Title.TextColor3 = Color3.fromRGB(96, 205, 255)
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left

local TabSystemFrame = Instance.new("Frame")
TabSystemFrame.Name = "TabSystem"
TabSystemFrame.Parent = MainWindow
TabSystemFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
TabSystemFrame.Position = UDim2.new(0, 12, 0, 48)
TabSystemFrame.Size = UDim2.new(0, 130, 1, -60)
Instance.new("UICorner", TabSystemFrame).CornerRadius = UDim.new(0, 8)
local TabButtonsLayout = Instance.new("UIListLayout")
TabButtonsLayout.Parent = TabSystemFrame
TabButtonsLayout.Padding = UDim.new(0, 6)
TabButtonsLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabButtonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
local TabPadding = Instance.new("UIPadding", TabSystemFrame)
TabPadding.PaddingTop = UDim.new(0, 8)

local PagesContainer = Instance.new("Frame")
PagesContainer.Name = "PagesContainer"
PagesContainer.Parent = MainWindow
PagesContainer.BackgroundTransparency = 1
PagesContainer.Position = UDim2.new(0, 154, 0, 48)
PagesContainer.Size = UDim2.new(1, -166, 1, -60)

local TabRegistry = {}
local currentActiveTab = nil

local function CreateTab(tabName, layoutOrder)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName .. "TabBtn"
    tabBtn.Parent = TabSystemFrame
    tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Size = UDim2.new(1, -16, 0, 32)
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.Text = "  " .. tabName
    tabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    tabBtn.TextSize = 12
    tabBtn.TextXAlignment = Enum.TextXAlignment.Left
    tabBtn.LayoutOrder = layoutOrder
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)
    local Indicator = Instance.new("Frame", tabBtn)
    Indicator.Name = "Indicator"
    Indicator.Size = UDim2.new(0, 3, 0.6, 0)
    Indicator.Position = UDim2.new(0, -8, 0.2, 0)
    Indicator.BackgroundColor3 = Color3.fromRGB(96, 205, 255)
    Indicator.Visible = false
    Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)
    local pageScroll = Instance.new("ScrollingFrame")
    pageScroll.Name = tabName .. "Page"
    pageScroll.Parent = PagesContainer
    pageScroll.BackgroundTransparency = 1
    pageScroll.Size = UDim2.new(1, 0, 1, 0)
    pageScroll.ScrollBarThickness = 2
    pageScroll.ScrollBarImageColor3 = Color3.fromRGB(50, 50, 70)
    pageScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pageScroll.Visible = false
    pageScroll.BorderSizePixel = 0
    pageScroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    local pList = Instance.new("UIListLayout")
    pList.Parent = pageScroll
    pList.Padding = UDim.new(0, 8)
    pList.SortOrder = Enum.SortOrder.LayoutOrder
    local pPad = Instance.new("UIPadding", pageScroll)
    pPad.PaddingLeft = UDim.new(0, 4)
    pPad.PaddingRight = UDim.new(0, 8)
    pPad.PaddingTop = UDim.new(0, 4)
    pPad.PaddingBottom = UDim.new(0, 10)
    local function selectThisTab()
        if currentActiveTab then
            currentActiveTab.Button.BackgroundTransparency = 1
            currentActiveTab.Button.TextColor3 = Color3.fromRGB(150, 150, 150)
            currentActiveTab.Button.Indicator.Visible = false
            currentActiveTab.Page.Visible = false
        end
        tabBtn.BackgroundTransparency = 0.5
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Indicator.Visible = true
        pageScroll.Visible = true
        currentActiveTab = {Button = tabBtn, Page = pageScroll}
    end
    tabBtn.MouseButton1Click:Connect(selectThisTab)
    TabRegistry[tabName] = {Button = tabBtn, Page = pageScroll, Select = selectThisTab}
    return pageScroll
end

--------------------------------------------------------------------------------
--// MODULAR COMPONENT GENERATOR UTILITIES
--------------------------------------------------------------------------------
local function CreateSection(parent, titleText)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = parent
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 24)
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = string.upper(titleText)
    lbl.TextColor3 = Color3.fromRGB(96, 205, 255)
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local underline = Instance.new("Frame", lbl)
    underline.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    underline.BorderSizePixel = 0
    underline.Size = UDim2.new(1, 0, 0, 1)
    underline.Position = UDim2.new(0, 0, 1, 0)
end

local function CreateButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = parent
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.Font = Enum.Font.GothamSemibold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    btn.TextSize = 12
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(45, 45, 60)
    btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45) end)
    btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35) end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function CreateToggleUI(parent, text, default, callback)
    local container = Instance.new("Frame")
    container.Parent = parent
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
    container.Size = UDim2.new(1, 0, 0, 38)
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", container).Color = Color3.fromRGB(40, 40, 50)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = container
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Size = UDim2.new(0.75, 0, 1, 0)
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local toggleBG = Instance.new("TextButton")
    toggleBG.Parent = container
    toggleBG.BackgroundColor3 = default and Color3.fromRGB(96, 205, 255) or Color3.fromRGB(40, 40, 50)
    toggleBG.Position = UDim2.new(1, -44, 0.5, -10)
    toggleBG.Size = UDim2.new(0, 32, 0, 20)
    toggleBG.Text = ""
    Instance.new("UICorner", toggleBG).CornerRadius = UDim.new(1, 0)
    local toggleCircle = Instance.new("Frame", toggleBG)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    Instance.new("UICorner", toggleCircle).CornerRadius = UDim.new(1, 0)
    local state = default
    local api = {}
    function api:SetValue(val)
        state = val
        toggleBG.BackgroundColor3 = state and Color3.fromRGB(96, 205, 255) or Color3.fromRGB(40, 40, 50)
        toggleCircle.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        callback(state)
    end
    toggleBG.MouseButton1Click:Connect(function() api:SetValue(not state) end)
    return api
end

local function CreateInputUI(parent, text, default, numeric, callback)
    local container = Instance.new("Frame")
    container.Parent = parent
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
    container.Size = UDim2.new(1, 0, 0, 38)
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke", container)
    stroke.Color = Color3.fromRGB(40, 40, 50)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = container
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local boxBG = Instance.new("Frame", container)
    boxBG.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    boxBG.Position = UDim2.new(1, -85, 0.5, -13)
    boxBG.Size = UDim2.new(0, 75, 0, 26)
    Instance.new("UICorner", boxBG).CornerRadius = UDim.new(0, 4)
    local boxStroke = Instance.new("UIStroke", boxBG)
    boxStroke.Color = Color3.fromRGB(50, 50, 60)
    local box = Instance.new("TextBox", boxBG)
    box.BackgroundTransparency = 1
    box.Size = UDim2.new(1, 0, 1, 0)
    box.Font = Enum.Font.Gotham
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 11
    box.Focused:Connect(function() boxStroke.Color = Color3.fromRGB(96, 205, 255) end)
    box.FocusLost:Connect(function()
        boxStroke.Color = Color3.fromRGB(50, 50, 60)
        local val = box.Text
        if numeric then val = tonumber(val) or default; box.Text = tostring(val) end
        callback(val)
    end)
    local api = {}
    function api:SetValue(val) box.Text = tostring(val); callback(val) end
    return api
end

local function CreateCycleUI(parent, text, list, default, callback)
    local container = Instance.new("Frame")
    container.Parent = parent
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
    container.Size = UDim2.new(1, 0, 0, 38)
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", container).Color = Color3.fromRGB(40, 40, 50)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = container
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    local btn = Instance.new("TextButton")
    btn.Parent = container
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    btn.Position = UDim2.new(1, -120, 0.5, -13)
    btn.Size = UDim2.new(0, 110, 0, 26)
    btn.Font = Enum.Font.Gotham
    btn.Text = tostring(default)
    btn.TextColor3 = Color3.fromRGB(96, 205, 255)
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", btn).Color = Color3.fromRGB(60, 60, 75)
    local currentIndex = 1
    for i, v in ipairs(list) do if v == default then currentIndex = i; break end end
    local api = {}
    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #api.CurrentList then currentIndex = 1 end
        local val = api.CurrentList[currentIndex]
        btn.Text = tostring(val)
        callback(val)
    end)
    api.CurrentList = list
    function api:SetValues(newList) api.CurrentList = newList; currentIndex = 1; btn.Text = tostring(newList[1] or "None") end
    function api:SetValue(targetValue)
        for i, v in ipairs(api.CurrentList) do
            if tostring(v) == tostring(targetValue) then currentIndex = i; btn.Text = tostring(v); callback(v); break end
        end
    end
    return api
end

local function CreateDropdownUI(parent, text, list, default, callback)
    local container = Instance.new("Frame")
    container.Parent = parent
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
    container.Size = UDim2.new(1, 0, 0, 38)
    container.ClipsDescendants = false
    container.ZIndex = 5
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", container).Color = Color3.fromRGB(40, 40, 50)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = container
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Size = UDim2.new(0.45, 0, 1, 0)
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 210, 210)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 6
    local mainBtn = Instance.new("TextButton")
    mainBtn.Parent = container
    mainBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainBtn.Position = UDim2.new(1, -120, 0.5, -13)
    mainBtn.Size = UDim2.new(0, 110, 0, 26)
    mainBtn.Font = Enum.Font.Gotham
    mainBtn.Text = tostring(default) .. "  ▼"
    mainBtn.TextColor3 = Color3.fromRGB(96, 205, 255)
    mainBtn.TextSize = 11
    mainBtn.ZIndex = 7
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", mainBtn).Color = Color3.fromRGB(60, 60, 75)
    local scrollList = Instance.new("ScrollingFrame")
    scrollList.Name = "DropdownMenuContainer"
    scrollList.Parent = mainBtn
    scrollList.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
    scrollList.Position = UDim2.new(0, 0, 1, 4)
    scrollList.Size = UDim2.new(1, 0, 0, 120)
    scrollList.Visible = false
    scrollList.ZIndex = 200
    scrollList.ScrollBarThickness = 2
    scrollList.ScrollBarImageColor3 = Color3.fromRGB(96, 205, 255)
    scrollList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollList.BorderSizePixel = 0
    Instance.new("UIStroke", scrollList).Color = Color3.fromRGB(96, 205, 255)
    Instance.new("UICorner", scrollList).CornerRadius = UDim.new(0, 4)
    local dLayout = Instance.new("UIListLayout")
    dLayout.Parent = scrollList
    dLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local api = { CurrentList = list, SelectedValue = default }
    local function refreshItems()
        for _, child in ipairs(scrollList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
        for i, valName in ipairs(api.CurrentList) do
            local itemBtn = Instance.new("TextButton")
            itemBtn.Parent = scrollList
            itemBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
            itemBtn.Size = UDim2.new(1, 0, 0, 26)
            itemBtn.Font = Enum.Font.Gotham
            itemBtn.Text = tostring(valName)
            itemBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
            itemBtn.TextSize = 11
            itemBtn.ZIndex = 201
            itemBtn.BorderSizePixel = 0
            itemBtn.MouseEnter:Connect(function() itemBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45) end)
            itemBtn.MouseLeave:Connect(function() itemBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 27) end)
            itemBtn.MouseButton1Click:Connect(function()
                api.SelectedValue = valName
                mainBtn.Text = tostring(valName) .. "  ▼"
                scrollList.Visible = false
                container.ZIndex = 5
                callback(valName)
            end)
        end
    end
    mainBtn.MouseButton1Click:Connect(function()
        scrollList.Visible = not scrollList.Visible
        container.ZIndex = scrollList.Visible and 100 or 5
    end)
    function api:SetValues(newList) api.CurrentList = newList; api.SelectedValue = newList[1] or "None"; mainBtn.Text = tostring(api.SelectedValue) .. "  ▼"; refreshItems() end
    function api:SetValue(targetValue) api.SelectedValue = targetValue; mainBtn.Text = tostring(targetValue) .. "  ▼"; scrollList.Visible = false; container.ZIndex = 5; callback(targetValue) end
    refreshItems()
    return api
end

-- INITIALIZE ALL PAGES
local MainFarmPage = CreateTab("🏠 Main Farm", 1)
local VectorPage   = CreateTab("⚙️ Vector", 2)
local ProfilePage  = CreateTab("💾 Profile", 3)

--------------------------------------------------------------------------------
-- [TAB 1]: MAIN FARM PAGE
--------------------------------------------------------------------------------
CreateSection(MainFarmPage, "Farming Engine Basics")
_G.WorldDropdown = CreateCycleUI(MainFarmPage, "Target Realm/World", {"World 1", "World 2", "World 3"}, EngineConfig.SelectedWorld, function(v) EngineConfig.SelectedWorld = v end)
local NormalDropdown = CreateCycleUI(MainFarmPage, "Normal Mob Selection", GameLists.NormalNPCs, "None", function(v) EngineConfig.SelectedNormalNpcId = (v ~= "None") and v or nil end)
local BossDropdown = CreateCycleUI(MainFarmPage, "Boss Mob Selection", GameLists.BossNPCs, "None", function(v) EngineConfig.SelectedBossNpcId = (v ~= "None") and v or nil end)

CreateButton(MainFarmPage, "🔄 Scan & Sync Map Targets", function()
    local normalIds, bossIds = {"None"}, {"None"}
    local enemyFolder = Workspace:FindFirstChild("EnemyNpc")
    if enemyFolder then
        local cacheN, cacheB = {}, {}
        for _, monster in ipairs(enemyFolder:GetChildren()) do
            local id = CombatEngine.GetNpcId(monster)
            if id and id ~= "" then
                if CombatEngine.GetLevelType(monster) == "boss" then
                    if not cacheB[id] then cacheB[id] = true; table.insert(bossIds, id) end
                else
                    if not cacheN[id] then cacheN[id] = true; table.insert(normalIds, id) end
                end
            end
        end
    end
    GameLists.NormalNPCs = normalIds; GameLists.BossNPCs = bossIds
    NormalDropdown:SetValues(normalIds); BossDropdown:SetValues(bossIds)
    CustomNotify("Engine Sync", "Dynamic targets synchronized.", 2)
end)

_G.FarmToggle = CreateToggleUI(MainFarmPage, "Execution State (Auto Farm)", EngineConfig.AutoAttackActive, function(v)
    EngineConfig.AutoAttackActive = v
    if v then
        if checkVictoryUi() then task.spawn(function() DisableAutoFarm("Victory Screen is active.") end)
        else task.spawn(startInfiniteDistanceLoop) end
    end
end)
_G.ReplayToggle = CreateToggleUI(MainFarmPage, "Auto Play Again (Replay)", EngineConfig.AutoReplayActive, function(v) EngineConfig.AutoReplayActive = v end)
_G.AutoSkillToggle = CreateToggleUI(MainFarmPage, "Auto Skill Execution", EngineConfig.AutoSkillActive, function(v) EngineConfig.AutoSkillActive = v end)
_G.AutoWeaponToggle = CreateToggleUI(MainFarmPage, "Auto Weapon Switcher", EngineConfig.AutoWeaponSwitchActive, function(v) EngineConfig.AutoWeaponSwitchActive = v end)

CreateSection(MainFarmPage, "Chest Priority System")
CreateToggleUI(MainFarmPage, "Prioritize Chest First", EngineConfig.PrioritizeChest, function(v) EngineConfig.PrioritizeChest = v end)

CreateSection(MainFarmPage, "Anti-AFK & Session Guard")
CreateToggleUI(MainFarmPage, "Anti-AFK System", EngineConfig.AntiAFKActive, function(v) EngineConfig.AntiAFKActive = v end)
CreateToggleUI(MainFarmPage, "Anti-Paused Guard", EngineConfig.AntiPausedActive, function(v) EngineConfig.AntiPausedActive = v end)

--------------------------------------------------------------------------------
-- [TAB 2]: VECTOR / COMBAT CONFIGURATION PAGE
--------------------------------------------------------------------------------
CreateSection(VectorPage, "Orbit & CFrame Settings")
CreateInputUI(VectorPage, "Stand Height", EngineConfig.StandHeight, true, function(v) EngineConfig.StandHeight = v end)
CreateInputUI(VectorPage, "Orbit Radius", EngineConfig.OrbitRadius, true, function(v) EngineConfig.OrbitRadius = v end)
CreateInputUI(VectorPage, "Orbit Speed", EngineConfig.OrbitSpeed, true, function(v) EngineConfig.OrbitSpeed = v end)
CreateInputUI(VectorPage, "CFrame Delay", EngineConfig.CFrameDelay, true, function(v) EngineConfig.CFrameDelay = v end)
CreateToggleUI(VectorPage, "Auto CFrame (Orbit Mode)", EngineConfig.AutoCFrame, function(v) EngineConfig.AutoCFrame = v end)
CreateSection(VectorPage, "Combat Multiplier")
CreateInputUI(VectorPage, "Hit Multiplier", EngineConfig.HitMultiplier, true, function(v) EngineConfig.HitMultiplier = v end)
CreateInputUI(VectorPage, "Skill Cooldown Delay", EngineConfig.SkillCooldownDelay, true, function(v) EngineConfig.SkillCooldownDelay = v end)

--------------------------------------------------------------------------------
-- [TAB 3]: PROFILE / CONFIG SAVE SYSTEM PAGE
--------------------------------------------------------------------------------
local function SyncAllVisualUI()
    if _G.WorldDropdown then _G.WorldDropdown:SetValue(EngineConfig.SelectedWorld) end
    if _G.FarmToggle then _G.FarmToggle:SetValue(EngineConfig.AutoAttackActive) end
    if _G.ReplayToggle then _G.ReplayToggle:SetValue(EngineConfig.AutoReplayActive) end
    if _G.AutoSkillToggle then _G.AutoSkillToggle:SetValue(EngineConfig.AutoSkillActive) end
    if _G.AutoWeaponToggle then _G.AutoWeaponToggle:SetValue(EngineConfig.AutoWeaponSwitchActive) end
    if _G.ForgeInput1 then _G.ForgeInput1:SetValue(EngineConfig.ForgeQTEBase) end
    if _G.ForgeInput2 then _G.ForgeInput2:SetValue(EngineConfig.ForgeQTEMultiplier) end
    if _G.ForgeInput3 then _G.ForgeInput3:SetValue(EngineConfig.ForgeFinishBase) end
    if _G.ForgeInput4 then _G.ForgeInput4:SetValue(EngineConfig.ForgeFinishMultiplier) end
    if _G.ForgeInput5 then _G.ForgeInput5:SetValue(EngineConfig.ForgeResultBase) end
    if _G.ForgeInput6 then _G.ForgeInput6:SetValue(EngineConfig.ForgeResultMultiplier) end
end

CreateSection(ProfilePage, "Configuration Manager")
local configDropdown = CreateDropdownUI(ProfilePage, "Active Profile", ConfigSystem.GetConfigList(), "None", function(v) end)
CreateInputUI(ProfilePage, "Profile Name", "", false, function(v) end)

CreateButton(ProfilePage, "💾 Save New Profile", function()
    CustomNotify("PROFILE SAVE", "Ketik nama di kolom 'Profile Name' lalu tekan Enter.", 4)
end)

CreateButton(ProfilePage, "📂 Load Selected Profile", function()
    local selected = configDropdown.SelectedValue
    if not selected or selected == "None" then CustomNotify("LOAD ERR", "Pilih profil dulu!", 3); return end
    local ok = ConfigSystem.Load(selected, SyncAllVisualUI)
    if ok then CustomNotify("✅ LOADED", "Profil '" .. selected .. "' berhasil dimuat!", 3)
    else CustomNotify("❌ LOAD FAIL", "Gagal memuat profil.", 3) end
end)

CreateButton(ProfilePage, "🗑️ Delete Selected Profile", function()
    local selected = configDropdown.SelectedValue
    if not selected or selected == "None" then CustomNotify("DELETE ERR", "Pilih profil dulu!", 3); return end
    local ok = ConfigSystem.Delete(selected)
    if ok then
        configDropdown:SetValues(ConfigSystem.GetConfigList())
        CustomNotify("🗑️ DELETED", "Profil '" .. selected .. "' dihapus.", 3)
    else CustomNotify("❌ DELETE FAIL", "Gagal menghapus profil.", 3) end
end)

CreateSection(ProfilePage, "Auto-Load Settings")
CreateDropdownUI(ProfilePage, "Auto-Load Pointer", ConfigSystem.GetConfigList(), ConfigSystem.GetAutoLoadPointer(), function(v)
    ConfigSystem.SaveAutoLoadPointer(v)
    CustomNotify("AUTO-LOAD SET", "Pointer diset ke: " .. v, 2)
end)

--------------------------------------------------------------------------------
-- [TAB 4]: ROOM HUB PAGE
--------------------------------------------------------------------------------
local RoomPage = CreateTab("🏠 Room Hub", 4)
CreateSection(RoomPage, "Auto Room Joiner")
local worldOptions = {"World1", "World2", "World3", "Cave1", "Cave2", "Season1", "Season2"}
_G.RoomWorldDropdown = CreateDropdownUI(RoomPage, "World", worldOptions, EngineConfig.RoomWorld, function(v)
    EngineConfig.RoomWorld = v
    RefreshRoomDropdownVisibility(v)
end)
local worldRoomOpts  = {"Room1","Room2","Room3","Room4"}
local caveRoomOpts   = {"Room5","Room6","Room7","Room8"}
local seasonRoomOpts = {"Room9","Room10","Room11","Room12"}
_G.RoomTargetWorldDropdown  = CreateDropdownUI(RoomPage, "Room (World)", worldRoomOpts, EngineConfig.RoomTarget, function(v) EngineConfig.RoomTarget = v end)
_G.RoomTargetCaveDropdown   = CreateDropdownUI(RoomPage, "Room (Cave)", caveRoomOpts, EngineConfig.RoomTarget, function(v) EngineConfig.RoomTarget = v end)
_G.RoomTargetSeasonDropdown = CreateDropdownUI(RoomPage, "Room (Season)", seasonRoomOpts, EngineConfig.RoomTarget, function(v) EngineConfig.RoomTarget = v end)
RefreshRoomDropdownVisibility(EngineConfig.RoomWorld)
CreateDropdownUI(RoomPage, "Mode", {1,2,3}, EngineConfig.RoomMode, function(v) EngineConfig.RoomMode = v end)
CreateDropdownUI(RoomPage, "Max Players", {1,2,3,4}, EngineConfig.RoomPlayers, function(v) EngineConfig.RoomPlayers = v end)
CreateButton(RoomPage, "🚀 Join Room Now", function()
    RoomHubEngine.JoinRoom(EngineConfig.RoomWorld, EngineConfig.RoomMode, EngineConfig.RoomPlayers, EngineConfig.RoomTarget)
end)

--------------------------------------------------------------------------------
-- [TAB 5]: SELL PAGE (MASS SELL SYSTEM)
--------------------------------------------------------------------------------
local SellPage = CreateTab("💰 Mass Sell", 5)
CreateSection(SellPage, "Inventory Scanner & Seller")
local EquipmentScroll, OresScroll, MaterialsScroll = nil, nil, nil
local BulkSelectedUUIDs = {}

CreateButton(SellPage, "🔍 Link Inventory UI", function()
    local mainGui = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
    if not mainGui then CustomNotify("ERROR", "MainGui tidak ditemukan!", 3); return end
    local inventoryScreen = mainGui:FindFirstChild("ScreenInventory") or mainGui:FindFirstChild("InventoryGui")
    if inventoryScreen then
        EquipmentScroll = inventoryScreen:FindFirstChild("EquipmentScroll", true)
        OresScroll = inventoryScreen:FindFirstChild("OresScroll", true)
        MaterialsScroll = inventoryScreen:FindFirstChild("MaterialsScroll", true)
        CustomNotify("LINKED", "Inventory UI terhubung!", 3)
    else
        CustomNotify("ERROR", "Buka UI Inventory di game dulu!", 4)
    end
end)

local categoryList = {"All", "Weapon", "Helmet", "Breastplate", "Ore", "Material"}
_G.SellCategoryDropdown = CreateDropdownUI(SellPage, "Pilih Kategori", categoryList, EngineConfig.SellCategory, function(v) EngineConfig.SellCategory = v end)

local ItemResultContainer = Instance.new("ScrollingFrame")
ItemResultContainer.Name = "ItemResultContainer"
ItemResultContainer.Parent = SellPage
ItemResultContainer.Size = UDim2.new(1, 0, 0, 200)
ItemResultContainer.BackgroundTransparency = 1
ItemResultContainer.ScrollBarThickness = 3
ItemResultContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
local ItemListLayout = Instance.new("UIListLayout", ItemResultContainer)
ItemListLayout.Padding = UDim.new(0, 5)

local function sellSpesifikNamaItem(listUUIDs, tipeItem)
    if not listUUIDs or #listUUIDs == 0 then return end
    if tipeItem == "Material" then pcall(function() MaterialRE:FireServer("Sell", listUUIDs, {}) end)
    elseif tipeItem == "Ore" then pcall(function() ForgeRF:InvokeServer("Sell", listUUIDs) end)
    else pcall(function() EquipmentRE:FireServer("Sell", listUUIDs) end) end
end

local function runCoreNotificationEngine(parentFrame, filterCategory)
    for _, child in ipairs(parentFrame:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
    local database = { ["All"]={}, ["Weapon"]={}, ["Helmet"]={}, ["Breastplate"]={}, ["Ore"]={}, ["Material"]={} }
    local function insertToDatabase(cat, id, uuid, visual)
        if not database[cat][id] then database[cat][id] = { Visual = visual, UUIDs = {}, OriginalCategory = cat } end
        table.insert(database[cat][id].UUIDs, uuid)
        if not database["All"][id] then database["All"][id] = { Visual = visual, UUIDs = {}, OriginalCategory = cat } end
        table.insert(database["All"][id].UUIDs, uuid)
    end
    if EquipmentScroll then
        for _, slot in ipairs(EquipmentScroll:GetChildren()) do
            if slot:IsA("GuiObject") and slot.Name ~= "UIListLayout" and slot.Name ~= "UIPadding" then
                local visualName = slot.Name
                local nameLabel = slot:FindFirstChild("ItemName", true) or slot:FindFirstChild("Name", true)
                if nameLabel and nameLabel:IsA("TextLabel") then visualName = nameLabel.Text end
                local itemUUID = slot:GetAttribute("UUID") or slot.Name
                local uuidObj = slot:FindFirstChild("UUID", true)
                if uuidObj then itemUUID = uuidObj:IsA("ValueBase") and uuidObj.Value or uuidObj.Text end
                local checkText = string.lower(visualName .. " " .. slot.Name)
                local finalCategory = "Weapon"
                if string.find(checkText, "body") or string.find(checkText, "plate") or string.find(checkText, "armor") then finalCategory = "Breastplate"
                elseif string.find(checkText, "helm") or string.find(checkText, "head") or string.find(checkText, "hat") then finalCategory = "Helmet" end
                insertToDatabase(finalCategory, visualName, itemUUID, visualName)
            end
        end
    end
    local function scrapeStackables(scrollGui, categoryName)
        if scrollGui then
            for _, slot in ipairs(scrollGui:GetChildren()) do
                if slot:IsA("GuiObject") and slot.Name ~= "UIListLayout" and slot.Name ~= "UIPadding" then
                    local idAsli = slot.Name
                    local idObj = slot:FindFirstChild("ID", true)
                    if idObj then idAsli = idObj:IsA("ValueBase") and tostring(idObj.Value) or idObj.Text end
                    local nameLabel = slot:FindFirstChild("ItemName", true) or slot:FindFirstChild("Name", true)
                    local visualName = idAsli
                    if nameLabel and nameLabel:IsA("TextLabel") then visualName = nameLabel.Text end
                    insertToDatabase(categoryName, idAsli, idAsli, visualName)
                end
            end
        end
    end
    scrapeStackables(OresScroll, "Ore")
    scrapeStackables(MaterialsScroll, "Material")
    local targetData = database[filterCategory]
    for targetID, dataObj in pairs(targetData) do
        local storageKey = dataObj.OriginalCategory .. "_" .. targetID
        if (dataObj.OriginalCategory == "Ore" or dataObj.OriginalCategory == "Material") then
            if EngineConfig.AutoSellStaticList[storageKey] then
                BulkSelectedUUIDs[storageKey] = { UUIDs = dataObj.UUIDs, Type = dataObj.OriginalCategory }
            end
        end
        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Name = "ItemResult"
        ItemBtn.Parent = parentFrame
        ItemBtn.Size = UDim2.new(1, -10, 0, 30)
        ItemBtn.Font = Enum.Font.Gotham
        ItemBtn.TextSize = 12
        ItemBtn.TextXAlignment = Enum.TextXAlignment.Left
        Instance.new("UICorner", ItemBtn).CornerRadius = UDim.new(0, 4)
        local totalItem = #dataObj.UUIDs
        local btnText = dataObj.Visual .. " [x" .. totalItem .. "]"
        if BulkSelectedUUIDs[storageKey] then
            ItemBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60); ItemBtn.Text = "  ✅ " .. btnText
        else
            ItemBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50); ItemBtn.Text = "  • " .. btnText
        end
        ItemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        ItemBtn.MouseButton1Click:Connect(function()
            if BulkSelectedUUIDs[storageKey] then
                BulkSelectedUUIDs[storageKey] = nil
                ItemBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50); ItemBtn.Text = "  • " .. btnText
                if dataObj.OriginalCategory == "Ore" or dataObj.OriginalCategory == "Material" then EngineConfig.AutoSellStaticList[storageKey] = nil end
            else
                BulkSelectedUUIDs[storageKey] = { UUIDs = dataObj.UUIDs, Type = dataObj.OriginalCategory }
                ItemBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60); ItemBtn.Text = "  ✅ " .. btnText
                if dataObj.OriginalCategory == "Ore" or dataObj.OriginalCategory == "Material" then EngineConfig.AutoSellStaticList[storageKey] = true end
            end
        end)
    end
end

CreateButton(SellPage, "🔄 Scan Inventory", function()
    runCoreNotificationEngine(ItemResultContainer, EngineConfig.SellCategory)
    CustomNotify("SCANNER", "Scanning kategori: " .. EngineConfig.SellCategory, 2)
end)

CreateButton(SellPage, "💰 Execute Mass Sell", function()
    local eqPayload, orePayload, matPayload, sellCount = {}, {}, {}, 0
    for k, dataObj in pairs(BulkSelectedUUIDs) do
        for _, uuid in ipairs(dataObj.UUIDs) do
            if dataObj.Type == "Material" then table.insert(matPayload, uuid)
            elseif dataObj.Type == "Ore" then table.insert(orePayload, uuid)
            else table.insert(eqPayload, uuid) end
            sellCount = sellCount + 1
        end
    end
    if sellCount == 0 then CustomNotify("SELL WARN", "Tidak ada item yang dipilih!", 3); return end
    if #eqPayload > 0 then sellSpesifikNamaItem(eqPayload, "Equipment") end
    if #orePayload > 0 then sellSpesifikNamaItem(orePayload, "Ore") end
    if #matPayload > 0 then sellSpesifikNamaItem(matPayload, "Material") end
    task.wait(0.5)
    BulkSelectedUUIDs = {}
    runCoreNotificationEngine(ItemResultContainer, EngineConfig.SellCategory)
    CustomNotify("SELL EXECUTED", "Proses jual massal (" .. sellCount .. " item) selesai.", 3)
end)

CreateSection(SellPage, "Merchant System")
CreateButton(SellPage, "🛒 TP & Buka UI Merchant", function()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local RootPart = Character:WaitForChild("HumanoidRootPart")
    local MerchantPrompt = nil
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local promptText = v.ObjectText:lower() .. v.ActionText:lower()
            local parentName = v.Parent.Name:lower()
            if parentName:match("merchant") or promptText:match("merchant") or parentName:match("shop") or promptText:match("shop") then
                MerchantPrompt = v; break
            end
        end
    end
    if MerchantPrompt and MerchantPrompt.Parent:IsA("BasePart") then
        CombatEngine.ResetPhysics(RootPart)
        RootPart.CFrame = MerchantPrompt.Parent.CFrame * CFrame.new(0, 2, 0)
        task.wait(0.3)
        if fireproximityprompt then fireproximityprompt(MerchantPrompt); CustomNotify("MERCHANT", "Berhasil membuka UI Merchant!", 3)
        else CustomNotify("EXECUTOR WARN", "Executor tidak support fireproximityprompt", 3) end
    else
        CustomNotify("MERCHANT ERROR", "Gagal menemukan NPC Merchant otomatis!", 4)
    end
end)

--------------------------------------------------------------------------------
-- [TAB 6]: BUY PAGE (AUTO BUYER GOLD SHOP)
--------------------------------------------------------------------------------
local BuyPage = CreateTab("🛒 Auto Buy", 6)
CreateSection(BuyPage, "Gold Shop Auto-Buyer")
local BuyButtonsRef = {}
local ShopListContainer = Instance.new("ScrollingFrame")
ShopListContainer.Name = "ShopListContainer"
ShopListContainer.Parent = BuyPage
ShopListContainer.Size = UDim2.new(1, 0, 0, 220)
ShopListContainer.BackgroundTransparency = 1
ShopListContainer.ScrollBarThickness = 3
ShopListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
local ShopListLayout = Instance.new("UIListLayout")
ShopListLayout.Parent = ShopListContainer
ShopListLayout.Padding = UDim.new(0, 5)
ShopListLayout.SortOrder = Enum.SortOrder.LayoutOrder

_G.AutoBuyToggle = CreateToggleUI(BuyPage, "Enable Multi Auto-Buy", EngineConfig.AutoBuyActive, function(v)
    local hitungTarget = 0
    for _ in pairs(EngineConfig.AutoBuyTargetList) do hitungTarget = hitungTarget + 1 end
    if v and hitungTarget == 0 then
        CustomNotify("AUTO BUY WARN", "Pilih minimal 1 item dulu!", 3)
        EngineConfig.AutoBuyActive = false
        if _G.AutoBuyToggle and _G.AutoBuyToggle.SetValue then _G.AutoBuyToggle:SetValue(false) end
        return
    end
    EngineConfig.AutoBuyActive = v
    if v then CustomNotify("AUTO BUY", "Berjalan! (" .. hitungTarget .. " item terpilih)", 3)
    else CustomNotify("AUTO BUY", "Sistem Auto-Buy Dimatikan", 2) end
end)

CreateButton(BuyPage, "🔄 Scan Gold Shop Items", function()
    for _, child in ipairs(ShopListContainer:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    table.clear(BuyButtonsRef)
    local mainGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MainGui")
    if not mainGui then CustomNotify("ERROR", "MainGui tidak ditemukan!", 3); return end
    local screenGoldShop = mainGui:FindFirstChild("ScreenGoldShop")
    local contentFrame = screenGoldShop and screenGoldShop:FindFirstChild("Content")
    local scrollFrame = contentFrame and contentFrame:FindFirstChild("ScrollingFrame")
    if not scrollFrame then CustomNotify("ERROR", "Toko belum diload! Buka toko di game dulu.", 4); return end
    local totalItem = 0
    for _, item in ipairs(scrollFrame:GetChildren()) do
        if string.find(item.Name, "GoldShop") then
            totalItem = totalItem + 1
            local btn = Instance.new("TextButton")
            btn.Parent = ShopListContainer
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            BuyButtonsRef[item.Name] = btn
            btn.MouseButton1Click:Connect(function()
                if EngineConfig.AutoBuyTargetList[item.Name] then EngineConfig.AutoBuyTargetList[item.Name] = nil
                else EngineConfig.AutoBuyTargetList[item.Name] = true end
            end)
        end
    end
    CustomNotify("SHOP SCANNER", "Berhasil memuat " .. totalItem .. " item toko!", 3)
end)

-- LOOP 1: Real-time Visual Update
task.spawn(function()
    while true do
        task.wait(0.1)
        local mainGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MainGui")
        local scrollFrame = mainGui and mainGui:FindFirstChild("ScreenGoldShop") and mainGui.ScreenGoldShop:FindFirstChild("Content") and mainGui.ScreenGoldShop.Content:FindFirstChild("ScrollingFrame")
        if scrollFrame then
            for _, item in pairs(scrollFrame:GetChildren()) do
                local itemBtn = BuyButtonsRef[item.Name]
                if string.find(item.Name, "GoldShop") and itemBtn then
                    local nameTXT = item:FindFirstChild("NameTXT", true)
                    local stockTXT = item:FindFirstChild("StockTXT", true)
                    local hargaNominal = 0
                    for _, child in pairs(item:GetDescendants()) do
                        if child.Name == "Count" and child:IsA("TextLabel") and not string.find(child.Text, "x") then
                            hargaNominal = tonumber(child.Text) or 0
                        end
                    end
                    local namaItem = nameTXT and nameTXT.Text or "Unknown Item"
                    local teksStok = stockTXT and stockTXT.Text or "Stok: 0"
                    local angkaStok = tonumber(string.match(teksStok, "%d+")) or 0
                    if hargaNominal == 99 then angkaStok = 0 end
                    local formatStok = string.format("[Stok: %d]", angkaStok)
                    local statusPilih = EngineConfig.AutoBuyTargetList[item.Name] and "✅ " or "⬜ "
                    itemBtn.Text = string.format("  %s %s - %d Gold %s", statusPilih, namaItem, hargaNominal, formatStok)
                    if angkaStok > 0 and angkaStok < 10 and hargaNominal ~= 99 then
                        itemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        itemBtn.BackgroundColor3 = EngineConfig.AutoBuyTargetList[item.Name] and Color3.fromRGB(60, 120, 60) or Color3.fromRGB(40, 40, 50)
                    else
                        itemBtn.TextColor3 = Color3.fromRGB(130, 130, 130)
                        itemBtn.BackgroundColor3 = EngineConfig.AutoBuyTargetList[item.Name] and Color3.fromRGB(120, 60, 60) or Color3.fromRGB(30, 30, 40)
                    end
                end
            end
        end
    end
end)

-- LOOP 2: Remote Spammer Auto-Buy
task.spawn(function()
    local GoldShopRemote = Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("GoldShopSystem"):WaitForChild("GoldShopUtil"):WaitForChild("RemoteEvent")
    while true do
        task.wait(0.05)
        if EngineConfig.AutoBuyActive then
            local mainGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MainGui")
            local scrollFrame = mainGui and mainGui:FindFirstChild("ScreenGoldShop") and mainGui.ScreenGoldShop:FindFirstChild("Content") and mainGui.ScreenGoldShop.Content:FindFirstChild("ScrollingFrame")
            if scrollFrame then
                for _, item in pairs(scrollFrame:GetChildren()) do
                    if EngineConfig.AutoBuyTargetList[item.Name] then
                        local stockTXT = item:FindFirstChild("StockTXT", true)
                        local hargaRealtime = 0
                        for _, child in pairs(item:GetDescendants()) do
                            if child.Name == "Count" and child:IsA("TextLabel") and not string.find(child.Text, "x") then
                                hargaRealtime = tonumber(child.Text) or 0
                            end
                        end
                        if stockTXT and hargaRealtime ~= 99 then
                            local angkaStok = tonumber(string.match(stockTXT.Text, "%d+")) or 0
                            if angkaStok >= 1 and angkaStok <= 9 then
                                pcall(function() GoldShopRemote:FireServer("BuyGoldShopItem", item.Name) end)
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
-- [TAB 7]: FORGE ENGINE PAGE
--------------------------------------------------------------------------------
local ForgePage = CreateTab("🔨 Forge Engine", 7)
CreateSection(ForgePage, "Forge Hooking Values")
local ForgeUtil = require(Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("ForgeSystem"):WaitForChild("ForgeUtil"))
if not _G.OriginalQTE then _G.OriginalQTE = ForgeUtil.QTE end
ForgeUtil.QTE = function(...)
    local args = {...}
    local data = nil
    for _, v in pairs(args) do if type(v) == "table" and v.UUID then data = v; break end end
    if data then
        task.spawn(function()
            local QTETotal    = math.floor(EngineConfig.ForgeQTEBase * EngineConfig.ForgeQTEMultiplier)
            local FinishTotal = math.floor(EngineConfig.ForgeFinishBase * EngineConfig.ForgeFinishMultiplier)
            local ResultTotal = math.floor(EngineConfig.ForgeResultBase * EngineConfig.ForgeResultMultiplier)
            for i = 1, QTETotal do ForgeRF:InvokeServer("QTE", {UUID = data.UUID, Rating = 15}); task.wait() end
            for i = 1, FinishTotal do ForgeRF:InvokeServer("ForgeFinish"); task.wait() end
            for i = 1, ResultTotal do ForgeRF:InvokeServer("ForgeResult", true); task.wait() end
        end)
    end
    return _G.OriginalQTE(...)
end
_G.ForgeInput1 = CreateInputUI(ForgePage, "QTE Base", EngineConfig.ForgeQTEBase, true, function(val) EngineConfig.ForgeQTEBase = val end)
_G.ForgeInput2 = CreateInputUI(ForgePage, "QTE Multiplier", EngineConfig.ForgeQTEMultiplier, true, function(val) EngineConfig.ForgeQTEMultiplier = val end)
_G.ForgeInput3 = CreateInputUI(ForgePage, "Finish Base", EngineConfig.ForgeFinishBase, true, function(val) EngineConfig.ForgeFinishBase = val end)
_G.ForgeInput4 = CreateInputUI(ForgePage, "Finish Multiplier", EngineConfig.ForgeFinishMultiplier, true, function(val) EngineConfig.ForgeFinishMultiplier = val end)
_G.ForgeInput5 = CreateInputUI(ForgePage, "Result Base", EngineConfig.ForgeResultBase, true, function(val) EngineConfig.ForgeResultBase = val end)
_G.ForgeInput6 = CreateInputUI(ForgePage, "Result Multiplier", EngineConfig.ForgeResultMultiplier, true, function(val) EngineConfig.ForgeResultMultiplier = val end)

CreateSection(ForgePage, "Forge Action Utilities")
CreateButton(ForgePage, "🚀 TP TO FORGE", function()
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local RootPart = Character:WaitForChild("HumanoidRootPart")
    local TargetPrompt = nil
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local promptText = v.ObjectText:lower() .. v.ActionText:lower()
            local parentName = v.Parent.Name:lower()
            if parentName:match("forge") or promptText:match("forge") or parentName:match("craft") or promptText:match("craft") then
                TargetPrompt = v; break
            end
        end
    end
    if TargetPrompt and TargetPrompt.Parent:IsA("BasePart") then
        CombatEngine.ResetPhysics(RootPart)
        RootPart.CFrame = TargetPrompt.Parent.CFrame * CFrame.new(0, 2, 0)
        task.wait(0.3)
        if fireproximityprompt then fireproximityprompt(TargetPrompt) end
    else
        CombatEngine.ResetPhysics(RootPart)
        RootPart.CFrame = CFrame.new(122.5, 12, -45.8)
        task.wait(0.3)
    end
    pcall(function()
        local TaskRE = Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("TaskSystem"):WaitForChild("TaskRE")
        TaskRE:FireServer("UpdateTaskProgress", "OpenGUIWindow", "ScreenForging")
    end)
    pcall(function()
        local ForgeUI = LocalPlayer.PlayerGui:FindFirstChild("ScreenForging") or LocalPlayer.PlayerGui:FindFirstChild("ForgeGui")
        if ForgeUI then for _, obj in pairs(ForgeUI:GetChildren()) do if obj:IsA("Frame") then obj.Visible = true end end end
    end)
    CustomNotify("FORGE SYSTEM", "Teleport & Bypass Interaksi Forge Berhasil.", 3)
end)

CreateButton(ForgePage, "💎 CLAIM FORGE RESULT", function()
    local ok, err = pcall(function() ForgeRF:InvokeServer("ForgeResult", true) end)
    if ok then CustomNotify("FORGE CLAIM", "Berhasil claim result!", 3)
    else CustomNotify("CLAIM ERROR", "Gagal melakukan remote claim.", 3) end
end)

--------------------------------------------------------------------------------
--// MODERN FLOATING TOGGLE BUTTON
--------------------------------------------------------------------------------
local ToggleGuiBtn = Instance.new("ScreenGui")
ToggleGuiBtn.Name = "XiFil_ToggleButton"
ToggleGuiBtn.Parent = LocalPlayer:WaitForChild("PlayerGui")
ToggleGuiBtn.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleGuiBtn.ResetOnSpawn = false
RuntimeMaid:GiveTask(ToggleGuiBtn)
ToggleGuiBtn.DisplayOrder = 999988

local BtnContainer = Instance.new("Frame")
BtnContainer.Name = "Container"
BtnContainer.Parent = ToggleGuiBtn
BtnContainer.BackgroundTransparency = 1
BtnContainer.Position = UDim2.new(0.05, 0, 0.15, 0)
BtnContainer.Size = UDim2.fromOffset(85, 42)

local floatBtn = Instance.new("TextButton")
floatBtn.Name = "InteractableCenter"
floatBtn.Parent = BtnContainer
floatBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
floatBtn.BorderSizePixel = 0
floatBtn.Size = UDim2.new(1, 0, 1, 0)
floatBtn.Position = UDim2.new(0, 0, 0, 0)
floatBtn.Text = "XiFil"
floatBtn.Font = Enum.Font.GothamBlack
floatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatBtn.TextSize = 14
floatBtn.AutoButtonColor = false
local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 8)
ButtonCorner.Parent = floatBtn
local ButtonStroke = Instance.new("UIStroke")
ButtonStroke.Parent = floatBtn
ButtonStroke.Color = Color3.fromRGB(96, 205, 255)
ButtonStroke.Thickness = 1.5
ButtonStroke.Transparency = 0.3
local AccentLine = Instance.new("Frame")
AccentLine.Name = "Accent"
AccentLine.Parent = floatBtn
AccentLine.BackgroundColor3 = Color3.fromRGB(96, 205, 255)
AccentLine.BorderSizePixel = 0
AccentLine.Size = UDim2.new(0, 20, 0, 2)
AccentLine.Position = UDim2.new(0.5, -10, 0.75, 0)
Instance.new("UICorner", AccentLine).CornerRadius = UDim.new(1, 0)

floatBtn.MouseEnter:Connect(function()
    TweenService:Create(floatBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
    TweenService:Create(ButtonStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0, Thickness = 2}):Play()
    TweenService:Create(AccentLine, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 36, 0, 2), Position = UDim2.new(0.5, -18, 0.75, 0)}):Play()
end)
floatBtn.MouseLeave:Connect(function()
    TweenService:Create(floatBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(20, 20, 27)}):Play()
    TweenService:Create(ButtonStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0.3, Thickness = 1.5}):Play()
    TweenService:Create(AccentLine, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 20, 0, 2), Position = UDim2.new(0.5, -10, 0.75, 0)}):Play()
end)
floatBtn.MouseButton1Down:Connect(function()
    TweenService:Create(floatBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.9, 0, 0.9, 0), Position = UDim2.new(0.05, 0, 0.05, 0)}):Play()
end)
floatBtn.MouseButton1Up:Connect(function()
    TweenService:Create(floatBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}):Play()
end)

local function BinderDrag(uiObj)
    local dragToggle, dragStart, startPos
    local inputBegan = floatBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragToggle = true; dragStart = input.Position; startPos = uiObj.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragToggle = false end end)
        end
    end)
    RuntimeMaid:GiveTask(inputBegan)
    local inputChanged = Services.UserInputService.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragToggle then
            local delta = input.Position - dragStart
            uiObj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    RuntimeMaid:GiveTask(inputChanged)
end
BinderDrag(BtnContainer)

floatBtn.MouseButton1Click:Connect(function()
    MainWindow.Visible = not MainWindow.Visible
end)

-- Default Initialization
TabRegistry["🏠 Main Farm"].Select()
ConfigSystem.ExecuteAutoLoad(function() SyncAllVisualUI() end)
CustomNotify("XiFil Engine V4", "Tabbed Interface successfully initialized.", 4)

end) -- end startWithDRM

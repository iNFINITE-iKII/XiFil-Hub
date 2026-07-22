--------------------------------------------------------------------------------
--// ui/tab_room.lua — S21 Tab 5: Room Hub
--------------------------------------------------------------------------------
local H                   = getgenv().Hub
local EngineConfig        = H.EngineConfig
local Services            = H.Services
local LocalPlayer         = H.LocalPlayer
local Workspace           = H.Workspace
local GameMatchRE         = H.GameMatchRE
local CombatEngine        = H.CombatEngine
local ROOM_WORLD_DISPLAY  = H.ROOM_WORLD_DISPLAY
local ROOM_WORLD_KEY      = H.ROOM_WORLD_KEY
local isCaveWorld         = H.isCaveWorld
local isEndlessTower      = H.isEndlessTower
local getModeLabel        = H.getModeLabel
local CustomNotify        = H.CustomNotify
local CreateTab           = H.CreateTab
local CreateSection       = H.CreateSection
local WorldPlaceRE        = H.WorldPlaceRE
local CreateCycleUI       = H.CreateCycleUI
local CreateDropdownUI    = H.CreateDropdownUI
local CreateButton        = H.CreateButton
local CreateInputUI       = H.CreateInputUI
local CreateToggleUI      = H.CreateToggleUI
local RegisterTranslation = H.RegisterTranslation

-- [S21] TAB 5 — ROOM HUB
--------------------------------------------------------------------------------
local RoomPage = CreateTab("🚪 Room", "tabRoom")
CreateSection(RoomPage, "Matchmaking Control", "secMatchmake")

local sLblCon = Instance.new("Frame", RoomPage)
sLblCon.BackgroundColor3 = Color3.fromRGB(22,22,35)
sLblCon.Size = UDim2.new(1,0,0,32); sLblCon.BorderSizePixel = 0
Instance.new("UICorner",sLblCon).CornerRadius = UDim.new(0,8)
local statusLbl = Instance.new("TextLabel",sLblCon)
statusLbl.Size = UDim2.new(1,0,1,0)
statusLbl.BackgroundTransparency = 1; statusLbl.Font = Enum.Font.GothamBold; statusLbl.TextSize = 11

-- RoomMapping: key → list of rooms
-- Endless1 hanya Room9 & Room10
local RoomMapping = {
    World1   = {"Room1","Room2","Room3","Room4"},
    World2   = {"Room1","Room2","Room3","Room4"},
    World3   = {"Room1","Room2","Room3","Room4"},
    Cave1    = {"Room5","Room6","Room7","Room8"},
    Cave2    = {"Room5","Room6","Room7","Room8"},
    Cave3    = {"Room5","Room6","Room7","Room8"},
    Season1  = {"Room9","Room10","Room11","Room12"},
    Endless1 = {"Room9","Room10"},
}

-- buildModeList: Endless Tower → hanya mode 1; Cave → mode 1-4; Hell → 6-10; Normal → 1-5
local function buildModeList(worldDisplay, modeType)
    local list = {}
    if isEndlessTower(worldDisplay) then
        table.insert(list, getModeLabel(1))
        return list
    end
    local isCave = isCaveWorld(worldDisplay)
    if isCave then
        for i=1,4 do table.insert(list, getModeLabel(i)) end
    elseif modeType == "Hell" then
        for i=6,10 do table.insert(list, getModeLabel(i)) end
    else
        for i=1,5 do table.insert(list, getModeLabel(i)) end
    end
    return list
end

local function getModeNumber(labelStr)
    local n = tonumber(labelStr:match("^(%d+)")); return n or 1
end

local RoomModeTypeDropdown = nil
local RoomModeDropdown     = nil
local RoomTargetDropdown   = nil

local function updateModeDropdown(worldDisplay, modeType)
    local list = buildModeList(worldDisplay, modeType)
    if RoomModeDropdown then RoomModeDropdown:SetValues(list) end
    EngineConfig.RoomMode = getModeNumber(list[1])
    -- Sync statusLbl setiap kali mode list berubah
    statusLbl.Text       = worldDisplay.." — Mode "..EngineConfig.RoomMode
    statusLbl.TextColor3 = EngineConfig.RoomMode<=5 and Color3.fromRGB(0,255,127) or Color3.fromRGB(255,64,64)
end

-- ── WORLD DROPDOWN ──
_G.RoomWorldDropdown = CreateDropdownUI(RoomPage, "World", ROOM_WORLD_DISPLAY, EngineConfig.RoomWorldDisplay, function(val)
    EngineConfig.RoomWorldDisplay = val
    local key     = ROOM_WORLD_KEY[val] or "World1"
    local endless = isEndlessTower(val)
    local cave    = isCaveWorld(val)
    -- Endless Tower & Cave dikunci ke Normal
    if (cave or endless) and RoomModeTypeDropdown then
        EngineConfig.RoomModeType = "Normal"
        RoomModeTypeDropdown:SetValue("Normal")
    end
    local modeType = (cave or endless) and "Normal" or EngineConfig.RoomModeType
    updateModeDropdown(val, modeType)
    -- Update room list
    local rooms = RoomMapping[key] or {"Room1"}
    if RoomTargetDropdown then RoomTargetDropdown:SetValues(rooms); EngineConfig.RoomTarget = rooms[1] end
    statusLbl.Text       = val.." — Mode "..EngineConfig.RoomMode
    statusLbl.TextColor3 = EngineConfig.RoomMode<=5 and Color3.fromRGB(0,255,127) or Color3.fromRGB(255,64,64)
    -- Endless Tower tidak perlu SelectWorld
    if not endless then
        task.spawn(function() pcall(function() WorldPlaceRE:FireServer("SelectWorld",key,EngineConfig.RoomMode) end) end)
    end
end, "lblRoomWorld")

-- ── MODE TYPE DROPDOWN ──
RoomModeTypeDropdown = CreateDropdownUI(RoomPage, "Mode Type", {"Normal","Hell"}, EngineConfig.RoomModeType, function(val)
    -- Endless Tower tidak menggunakan ModeType
    if isEndlessTower(EngineConfig.RoomWorldDisplay) then return end
    EngineConfig.RoomModeType = val
    updateModeDropdown(EngineConfig.RoomWorldDisplay, val)
end, "lblModeType")
_G.RoomModeTypeDropdown = RoomModeTypeDropdown

-- ── MODE DROPDOWN ──
local initModeList = buildModeList(EngineConfig.RoomWorldDisplay, EngineConfig.RoomModeType)
RoomModeDropdown = CreateDropdownUI(RoomPage, "Mode", initModeList, getModeLabel(EngineConfig.RoomMode), function(val)
    EngineConfig.RoomMode = getModeNumber(val)
    statusLbl.Text = EngineConfig.RoomWorldDisplay.." — Mode "..EngineConfig.RoomMode
    statusLbl.TextColor3 = EngineConfig.RoomMode<=5 and Color3.fromRGB(0,255,127) or Color3.fromRGB(255,64,64)
    task.spawn(function()
        local key = ROOM_WORLD_KEY[EngineConfig.RoomWorldDisplay] or "World1"
        pcall(function() WorldPlaceRE:FireServer("SelectWorld",key,EngineConfig.RoomMode) end)
    end, "lblMode")
end)
_G.RoomModeDropdown = RoomModeDropdown

-- ── PLAYER COUNT DROPDOWN ──
_G.RoomPlayersDropdown = CreateDropdownUI(RoomPage, "Jumlah Player", {1,2,3,4}, EngineConfig.RoomPlayers, function(val)
    EngineConfig.RoomPlayers = tonumber(val)
end, "lblPlayers")

-- ── TARGET ROOM DROPDOWN ──
local initRooms = RoomMapping[ROOM_WORLD_KEY[EngineConfig.RoomWorldDisplay] or "World1"] or {"Room1"}
RoomTargetDropdown = CreateDropdownUI(RoomPage, "Target Room", initRooms, EngineConfig.RoomTarget or initRooms[1], function(val)
    EngineConfig.RoomTarget = val
end, "lblTargetRoom")
_G.RoomTargetDropdown = RoomTargetDropdown

statusLbl.Text = EngineConfig.RoomWorldDisplay.." — Mode "..EngineConfig.RoomMode
statusLbl.TextColor3 = EngineConfig.RoomMode<=5 and Color3.fromRGB(0,255,127) or Color3.fromRGB(255,64,64)

-- ── ROOM SETTINGS: FRIEND ONLY ──
-- ON → panggil ChangeFriendOnly 1x; OFF → panggil ChangeFriendOnly 1x lagi
CreateSection(RoomPage, "Room Settings", "secRoomSettings")
_G.FriendOnlyToggle = CreateToggleUI(RoomPage, "🔒 Friend Only Room", EngineConfig.FriendOnlyRoom, function(v)
    EngineConfig.FriendOnlyRoom = v
    pcall(function() GameMatchRE:FireServer("ChangeFriendOnly") end)
    if v then CustomNotify("🔒 FRIEND ONLY","Aktif",2)
    else      CustomNotify("🔒 FRIEND ONLY","Nonaktif",2) end
end, "lblFriendOnly")

-- ── MATCH ACTIONS ──
CreateSection(RoomPage, "Match Actions", "secMatchActions")
CreateButton(RoomPage, "🛠️ Create Room", function()
    local key = ROOM_WORLD_KEY[EngineConfig.RoomWorldDisplay] or "World1"
    pcall(function()
        GameMatchRE:FireServer("CreatRoom", key, EngineConfig.RoomMode, EngineConfig.RoomPlayers)
        CustomNotify("MATCHMAKING","Room: "..EngineConfig.RoomWorldDisplay.." [M:"..EngineConfig.RoomMode.."]",3)
    end)
end, "btnCreateRoom")
CreateButton(RoomPage, "🚀 TP Room", function()
    local targetRoom = EngineConfig.RoomTarget or "Room1"
    local mrf = Workspace:FindFirstChild("MatchRoom"); local rf = mrf and mrf:FindFirstChild(targetRoom)
    local tm = rf and rf:FindFirstChild("Touch"); local tp = tm and tm:FindFirstChild("Part")
    if tp and tp:IsA("BasePart") then
        local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then CombatEngine.ResetPhysics(hrp); hrp.CFrame = tp.CFrame; CustomNotify("ROOM TP","Ke "..targetRoom,3) end
    else CustomNotify("ROOM ERROR","Room '"..targetRoom.."' tidak ditemukan!",4) end
end, "btnTPRoom")
CreateButton(RoomPage, "🚪 Leave Room", function()
    pcall(function() GameMatchRE:FireServer("LeaveRoom") end)
    CustomNotify("ROOM","Leave Room dikirim.",2)
end, "btnLeaveRoom")

-- ── AUTO JOIN ROOM ──
-- Jika ON: TP Room → Create Room → tunggu 30 detik → ulang
CreateSection(RoomPage, "Auto Room", "secAutoRoom")
_G.AutoJoinRoomToggle = CreateToggleUI(RoomPage, "🔁 Auto Join Room", EngineConfig.AutoJoinRoomActive, function(v)
    EngineConfig.AutoJoinRoomActive = v
    if v then CustomNotify("🔁 AUTO JOIN","TP + Buat Room setiap 30 detik",3)
    else      CustomNotify("🔁 AUTO JOIN","Nonaktif",2) end
end, "lblAutoJoinRoom")

--------------------------------------------------------------------------------

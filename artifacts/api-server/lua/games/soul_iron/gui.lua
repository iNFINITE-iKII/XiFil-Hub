--------------------------------------------------------------------------------
-- [MODULE] gui.lua — XIFIL Hub PRO
-- Full GUI redesign: themes, transparency, gesture open, resize, multi-select
--------------------------------------------------------------------------------
local ctx = ...
local Services          = ctx.Services
local EngineConfig      = ctx.EngineConfig
local GuiConfig         = ctx.GuiConfig
local LocalPlayer       = ctx.LocalPlayer
local Workspace         = ctx.Workspace
local TweenService      = ctx.TweenService
local RuntimeMaid       = ctx.RuntimeMaid
local CustomNotify      = ctx.CustomNotify
local ConfigSystem      = ctx.ConfigSystem
local CombatEngine      = ctx.CombatEngine
local startFarmLoop     = ctx.startFarmLoop
local DisableAutoFarm   = ctx.DisableAutoFarm
local WORLD_NAMES       = ctx.WORLD_NAMES
local WORLD_INDEX       = ctx.WORLD_INDEX
local POSITION_MODES    = ctx.POSITION_MODES
local SKILL_PRESETS     = ctx.SKILL_PRESETS
local ROOM_WORLD_DISPLAY= ctx.ROOM_WORLD_DISPLAY
local ROOM_WORLD_KEY    = ctx.ROOM_WORLD_KEY
local isCaveWorld       = ctx.isCaveWorld
local getModeLabel      = ctx.getModeLabel
local getModeNumber     = ctx.getModeNumber
local GameLists         = ctx.GameLists
local PlayerActionRE    = ctx.PlayerActionRE
local ForgeRF           = ctx.ForgeRF
local MaterialRE        = ctx.MaterialRE
local WorldPlaceRE      = ctx.WorldPlaceRE
local EquipmentRE       = ctx.EquipmentRE
local GameMatchRE       = ctx.GameMatchRE
local UIS               = Services.UserInputService

-- ── Theme Definitions ─────────────────────────────────────────────────────────
local THEMES = {
    Cyan    = { Accent=Color3.fromRGB(96,205,255),  BG=Color3.fromRGB(13,13,18),  Panel=Color3.fromRGB(19,19,27),  Dim=Color3.fromRGB(36,36,52) },
    Red     = { Accent=Color3.fromRGB(255,70,70),   BG=Color3.fromRGB(17,10,10),  Panel=Color3.fromRGB(24,14,14),  Dim=Color3.fromRGB(55,24,24) },
    Purple  = { Accent=Color3.fromRGB(185,95,255),  BG=Color3.fromRGB(13,9,20),   Panel=Color3.fromRGB(20,13,30),  Dim=Color3.fromRGB(44,26,65) },
    Gold    = { Accent=Color3.fromRGB(255,195,50),  BG=Color3.fromRGB(17,15,8),   Panel=Color3.fromRGB(24,21,10),  Dim=Color3.fromRGB(54,46,16) },
    Green   = { Accent=Color3.fromRGB(50,215,120),  BG=Color3.fromRGB(9,17,12),   Panel=Color3.fromRGB(11,24,16),  Dim=Color3.fromRGB(22,52,32) },
    Emerald = { Accent=Color3.fromRGB(0,230,200),   BG=Color3.fromRGB(8,16,16),   Panel=Color3.fromRGB(10,22,22),  Dim=Color3.fromRGB(18,48,48) },
    RGB     = { Accent=Color3.fromRGB(96,205,255),  BG=Color3.fromRGB(13,13,18),  Panel=Color3.fromRGB(19,19,27),  Dim=Color3.fromRGB(36,36,52) },
}
local THEME_NAMES = {"Cyan","Red","Purple","Gold","Green","Emerald","RGB"}

local function getTheme() return THEMES[GuiConfig.Theme] or THEMES.Cyan end
local function accent() return GuiConfig.AccentColor end

-- Accent-bound element registry
local _accentBinds = {}
local function bindAccent(obj, prop)
    table.insert(_accentBinds, {obj=obj, prop=prop})
    obj[prop] = accent()
end

local function applyTheme()
    local t = getTheme()
    GuiConfig.AccentColor = t.Accent
    for _, b in ipairs(_accentBinds) do
        if b.obj and b.obj.Parent then pcall(function() b.obj[b.prop]=GuiConfig.AccentColor end) end
    end
end

-- RGB loop
local _rgbConn = nil
local function updateRGBLoop()
    if GuiConfig.Theme == "RGB" then
        if _rgbConn then return end
        _rgbConn = Services.RunService.Heartbeat:Connect(function()
            if GuiConfig.Theme ~= "RGB" then _rgbConn:Disconnect(); _rgbConn=nil; return end
            GuiConfig.AccentColor = Color3.fromHSV((tick()*0.08)%1, 0.85, 1)
            for _, b in ipairs(_accentBinds) do
                if b.obj and b.obj.Parent then pcall(function() b.obj[b.prop]=GuiConfig.AccentColor end) end
            end
        end)
        RuntimeMaid:GiveTask(function() if _rgbConn then _rgbConn:Disconnect() end end)
    else
        if _rgbConn then _rgbConn:Disconnect(); _rgbConn=nil end
    end
end

local function switchTheme(name)
    GuiConfig.Theme = name
    local t = getTheme()
    GuiConfig.AccentColor = t.Accent
    -- Update window BG (smooth)
    if rawget(_G,"XiFil_MainWindow") then
        local mw = _G.XiFil_MainWindow
        TweenService:Create(mw, TweenInfo.new(0.4,Enum.EasingStyle.Quint), {BackgroundColor3=t.BG}):Play()
    end
    applyTheme()
    updateRGBLoop()
end

-- ── Transparency ──────────────────────────────────────────────────────────────
local _transBGList = {} -- {obj, baseTrans}
local function bindTransBG(obj, baseTrans)
    table.insert(_transBGList, {obj=obj, base=baseTrans or 0})
    obj.BackgroundTransparency = baseTrans or 0
end
local function applyTransparency(alpha)
    GuiConfig.Transparency = alpha
    local a = math.clamp(alpha, 0, 0.88)
    for _, b in ipairs(_transBGList) do
        if b.obj and b.obj.Parent then
            pcall(function() b.obj.BackgroundTransparency = b.base + (1 - b.base) * a end)
        end
    end
end

-- ── CoreGui ───────────────────────────────────────────────────────────────────
local CoreGui = Instance.new("ScreenGui")
CoreGui.Name="XiFil_Main"; CoreGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
CoreGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
CoreGui.ResetOnSpawn=false; CoreGui.DisplayOrder=99990
RuntimeMaid:GiveTask(CoreGui)

-- ── Draggable helper ──────────────────────────────────────────────────────────
local function MakeDraggable(handle, frame)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=frame.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            dragInput=input end
    end)
    UIS.InputChanged:Connect(function(input)
        if input==dragInput and dragging then
            local delta=input.Position-dragStart
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
end

-- ── Main Window ───────────────────────────────────────────────────────────────
local t0 = getTheme()
local MainWindow = Instance.new("Frame")
MainWindow.Name="XiFil_Window"; MainWindow.Parent=CoreGui
MainWindow.BackgroundColor3=t0.BG
MainWindow.Position=UDim2.new(0.5,-260,0.5,-225)
MainWindow.Size=UDim2.new(0,520,0,450)
MainWindow.Visible=false; MainWindow.ClipsDescendants=true
Instance.new("UICorner",MainWindow).CornerRadius=UDim.new(0,12)
local MWStroke=Instance.new("UIStroke",MainWindow); MWStroke.Thickness=1.2; MWStroke.Transparency=0.4
bindAccent(MWStroke,"Color"); bindTransBG(MainWindow, 0)
_G.XiFil_MainWindow = MainWindow

-- ── TopBar ────────────────────────────────────────────────────────────────────
local TopBar = Instance.new("Frame")
TopBar.Name="TopBar"; TopBar.Parent=MainWindow
TopBar.BackgroundColor3=t0.Panel; TopBar.Size=UDim2.new(1,0,0,40); TopBar.BorderSizePixel=0
Instance.new("UICorner",TopBar).CornerRadius=UDim.new(0,12)
-- patch bottom corners
local TBPatch=Instance.new("Frame",TopBar); TBPatch.BackgroundColor3=t0.Panel
TBPatch.Size=UDim2.new(1,0,0,12); TBPatch.Position=UDim2.new(0,0,1,-12); TBPatch.BorderSizePixel=0
bindTransBG(TopBar, 0); bindTransBG(TBPatch, 0)
MakeDraggable(TopBar, MainWindow)

-- Title
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Parent=TopBar; TitleLabel.BackgroundTransparency=1
TitleLabel.Position=UDim2.new(0,14,0,0); TitleLabel.Size=UDim2.new(1,-120,1,0)
TitleLabel.Font=Enum.Font.GothamBlack
TitleLabel.Text='XIFIL <font color="#aaaaaa">//</font> Iron Soul V5'
TitleLabel.RichText=true; TitleLabel.TextSize=13
TitleLabel.TextXAlignment=Enum.TextXAlignment.Left; TitleLabel.TextTransparency=0
bindAccent(TitleLabel,"TextColor3")

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent=TopBar; CloseBtn.Size=UDim2.new(0,28,0,28); CloseBtn.Position=UDim2.new(1,-36,0.5,-14)
CloseBtn.BackgroundColor3=Color3.fromRGB(200,60,60); CloseBtn.Text="✕"
CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.TextColor3=Color3.white; CloseBtn.TextSize=12
Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(1,0)
CloseBtn.MouseButton1Click:Connect(function()
    local tw=TweenService:Create(MainWindow,TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Position=UDim2.new(1.1,0,MainWindow.Position.Y.Scale,MainWindow.Position.Y.Offset)})
    tw:Play(); tw.Completed:Connect(function() MainWindow.Visible=false end)
end)

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Parent=TopBar; MinBtn.Size=UDim2.new(0,28,0,28); MinBtn.Position=UDim2.new(1,-68,0.5,-14)
MinBtn.BackgroundColor3=t0.Dim; MinBtn.Text="—"
MinBtn.Font=Enum.Font.GothamBold; MinBtn.TextSize=14
MinBtn.TextColor3=Color3.fromRGB(220,220,220)
Instance.new("UICorner",MinBtn).CornerRadius=UDim.new(1,0)
local _minimized = false
local _fullSize = MainWindow.Size
MinBtn.MouseButton1Click:Connect(function()
    _minimized = not _minimized
    _fullSize = _minimized and _fullSize or MainWindow.Size
    local targetSize = _minimized and UDim2.new(0,520,0,42) or _fullSize
    TweenService:Create(MainWindow,TweenInfo.new(0.35,Enum.EasingStyle.Quint),{Size=targetSize}):Play()
    MinBtn.Text = _minimized and "□" or "—"
end)

-- Theme dot (indicator)
local ThemeDot = Instance.new("Frame")
ThemeDot.Parent=TopBar; ThemeDot.Size=UDim2.new(0,10,0,10); ThemeDot.Position=UDim2.new(1,-80,0.5,-5)
Instance.new("UICorner",ThemeDot).CornerRadius=UDim.new(1,0); bindAccent(ThemeDot,"BackgroundColor3")

-- ── Tab System ────────────────────────────────────────────────────────────────
local TabBar = Instance.new("Frame")
TabBar.Name="TabBar"; TabBar.Parent=MainWindow; TabBar.BackgroundColor3=t0.Panel
TabBar.Position=UDim2.new(0,0,0,40); TabBar.Size=UDim2.new(1,0,0,36); TabBar.BorderSizePixel=0
bindTransBG(TabBar,0)
local TabLayout=Instance.new("UIListLayout",TabBar)
TabLayout.FillDirection=Enum.FillDirection.Horizontal; TabLayout.SortOrder=Enum.SortOrder.LayoutOrder
TabLayout.HorizontalAlignment=Enum.HorizontalAlignment.Left; TabLayout.Padding=UDim.new(0,1)

local ContentFrame=Instance.new("Frame")
ContentFrame.Name="Content"; ContentFrame.Parent=MainWindow
ContentFrame.BackgroundTransparency=1; ContentFrame.Position=UDim2.new(0,0,0,76); ContentFrame.Size=UDim2.new(1,0,1,-76)

local TabRegistry={}; local currentTab=nil

local function CreateTab(name, order)
    local btn=Instance.new("TextButton"); btn.Name=name; btn.Parent=TabBar; btn.LayoutOrder=order
    btn.BackgroundTransparency=1; btn.Size=UDim2.new(0,64,1,0)
    btn.Font=Enum.Font.GothamSemibold; btn.Text=name; btn.TextColor3=Color3.fromRGB(140,140,155); btn.TextSize=9
    local ind=Instance.new("Frame",btn); ind.Name="Ind"; ind.BackgroundTransparency=1
    ind.BorderSizePixel=0; ind.Size=UDim2.new(0.75,0,0,2); ind.Position=UDim2.new(0.125,0,1,-2)
    bindAccent(ind,"BackgroundColor3")

    local page=Instance.new("ScrollingFrame"); page.Parent=ContentFrame; page.BackgroundTransparency=1
    page.Size=UDim2.new(1,0,1,0); page.ScrollBarThickness=3; page.AutomaticCanvasSize=Enum.AutomaticSize.Y
    page.ScrollBarImageColor3=Color3.fromRGB(80,80,100); page.Visible=false
    local layout=Instance.new("UIListLayout",page); layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,5)
    local pad=Instance.new("UIPadding",page); pad.PaddingLeft=UDim.new(0,10); pad.PaddingRight=UDim.new(0,10); pad.PaddingTop=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,10)

    local function selectTab()
        if currentTab then
            currentTab.Btn.TextColor3=Color3.fromRGB(140,140,155)
            currentTab.Btn:FindFirstChild("Ind").BackgroundTransparency=1
            currentTab.Page.Visible=false
        end
        btn.TextColor3=Color3.white; ind.BackgroundTransparency=0; page.Visible=true
        currentTab={Btn=btn,Page=page}
    end
    btn.MouseButton1Click:Connect(selectTab)
    TabRegistry[name]={Btn=btn,Page=page,Select=selectTab}
    return page
end

-- ── Component Builders ────────────────────────────────────────────────────────
local function Section(parent, text)
    local row=Instance.new("Frame"); row.Parent=parent; row.BackgroundTransparency=1; row.Size=UDim2.new(1,0,0,22)
    local lbl=Instance.new("TextLabel",row); lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,-4,1,0)
    lbl.Font=Enum.Font.GothamBold; lbl.Text=string.upper(text); lbl.TextSize=10
    lbl.TextXAlignment=Enum.TextXAlignment.Left; bindAccent(lbl,"TextColor3")
    local line=Instance.new("Frame",row); line.BackgroundColor3=t0.Dim; line.BorderSizePixel=0
    line.Size=UDim2.new(1,0,0,1); line.Position=UDim2.new(0,0,1,-1)
end

local function Button(parent, text, cb)
    local t=getTheme()
    local btn=Instance.new("TextButton"); btn.Parent=parent
    btn.BackgroundColor3=t.Panel; btn.Size=UDim2.new(1,0,0,32)
    btn.Font=Enum.Font.GothamSemibold; btn.Text=text; btn.TextColor3=Color3.fromRGB(215,215,225); btn.TextSize=11
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
    local stk=Instance.new("UIStroke",btn); stk.Thickness=1; stk.Transparency=0.7; bindAccent(stk,"Color")
    btn.MouseEnter:Connect(function() TweenService:Create(btn,TweenInfo.new(0.18),{BackgroundColor3=t.Dim}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn,TweenInfo.new(0.25),{BackgroundColor3=t.Panel}):Play() end)
    btn.MouseButton1Down:Connect(function() TweenService:Create(btn,TweenInfo.new(0.08),{Size=UDim2.new(0.97,0,0,30)}):Play() end)
    btn.MouseButton1Up:Connect(function() TweenService:Create(btn,TweenInfo.new(0.15,Enum.EasingStyle.Back),{Size=UDim2.new(1,0,0,32)}):Play() end)
    btn.MouseButton1Click:Connect(cb); return btn
end

local function Toggle(parent, label, default, cb)
    local t=getTheme()
    local row=Instance.new("Frame"); row.Parent=parent; row.BackgroundColor3=t.Panel
    row.Size=UDim2.new(1,0,0,38); Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    local stk=Instance.new("UIStroke",row); stk.Thickness=1; stk.Transparency=0.75; bindAccent(stk,"Color")
    local lbl=Instance.new("TextLabel",row); lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,12,0,0); lbl.Size=UDim2.new(0.72,0,1,0)
    lbl.Font=Enum.Font.GothamMedium; lbl.Text=label; lbl.TextColor3=Color3.fromRGB(210,210,220)
    lbl.TextSize=12; lbl.TextXAlignment=Enum.TextXAlignment.Left

    local track=Instance.new("TextButton",row); track.Text=""
    track.Position=UDim2.new(1,-46,0.5,-11); track.Size=UDim2.new(0,34,0,22)
    track.BackgroundColor3=default and accent() or t.Dim
    Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame",track); knob.BackgroundColor3=Color3.white
    knob.Size=UDim2.new(0,18,0,18); knob.Position=default and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local state=default
    local api={}
    function api:SetValue(v)
        state=v
        local tgt=v and accent() or t.Dim
        TweenService:Create(track,TweenInfo.new(0.22,Enum.EasingStyle.Quint),{BackgroundColor3=tgt}):Play()
        TweenService:Create(knob,TweenInfo.new(0.22,Enum.EasingStyle.Quint),{Position=v and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)}):Play()
        cb(v)
    end
    function api:Get() return state end
    track.MouseButton1Click:Connect(function() api:SetValue(not state) end)
    -- bind track accent
    bindAccent(track,"BackgroundColor3") -- init color; will update if theme changes
    -- actually only bind when ON:
    if not default then track.BackgroundColor3=t.Dim end
    return api
end

local function InputBox(parent, label, default, numeric, cb)
    local t=getTheme()
    local row=Instance.new("Frame"); row.Parent=parent; row.BackgroundColor3=t.Panel
    row.Size=UDim2.new(1,0,0,38); Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",row).Color=t.Dim
    local lbl=Instance.new("TextLabel",row); lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,12,0,0); lbl.Size=UDim2.new(0.58,0,1,0)
    lbl.Font=Enum.Font.GothamMedium; lbl.Text=label; lbl.TextColor3=Color3.fromRGB(200,200,210); lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local boxBG=Instance.new("Frame",row); boxBG.BackgroundColor3=t.BG
    boxBG.Position=UDim2.new(1,-88,0.5,-13); boxBG.Size=UDim2.new(0,78,0,26)
    Instance.new("UICorner",boxBG).CornerRadius=UDim.new(0,5)
    local bStk=Instance.new("UIStroke",boxBG); bStk.Color=t.Dim
    local box=Instance.new("TextBox",boxBG); box.BackgroundTransparency=1; box.Size=UDim2.new(1,0,1,0)
    box.Font=Enum.Font.Gotham; box.Text=tostring(default); box.TextColor3=Color3.white; box.TextSize=11
    box.Focused:Connect(function() bStk.Color=accent() end)
    box.FocusLost:Connect(function()
        bStk.Color=t.Dim; local v=box.Text
        if numeric then v=tonumber(v) or default; box.Text=tostring(v) end; cb(v)
    end)
    local api={}; function api:SetValue(v) box.Text=tostring(v); cb(v) end; return api
end

local function Cycle(parent, label, list, default, cb)
    local t=getTheme()
    local row=Instance.new("Frame"); row.Parent=parent; row.BackgroundColor3=t.Panel
    row.Size=UDim2.new(1,0,0,38); Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",row).Color=t.Dim
    local lbl=Instance.new("TextLabel",row); lbl.BackgroundTransparency=1
    lbl.Position=UDim2.new(0,12,0,0); lbl.Size=UDim2.new(0.48,0,1,0)
    lbl.Font=Enum.Font.GothamMedium; lbl.Text=label; lbl.TextColor3=Color3.fromRGB(200,200,210); lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local btn=Instance.new("TextButton",row); btn.BackgroundColor3=t.Dim
    btn.Position=UDim2.new(1,-122,0.5,-13); btn.Size=UDim2.new(0,112,0,26)
    btn.Font=Enum.Font.Gotham; btn.Text=tostring(default); btn.TextSize=10
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5); bindAccent(btn,"TextColor3")
    local idx=1; for i,v in ipairs(list) do if v==default then idx=i; break end end
    local api={CurrentList=list}
    btn.MouseButton1Click:Connect(function()
        idx=idx%#api.CurrentList+1; local v=api.CurrentList[idx]; btn.Text=tostring(v); cb(v)
    end)
    function api:SetValues(nl) api.CurrentList=nl; idx=1; btn.Text=tostring(nl[1] or "None") end
    function api:SetValue(tv)
        for i,v in ipairs(api.CurrentList) do if tostring(v)==tostring(tv) then idx=i; btn.Text=tostring(v); cb(v); break end end
    end; return api
end

local function Dropdown(parent, label, list, default, cb)
    local t=getTheme()
    local outer=Instance.new("Frame"); outer.Parent=parent; outer.BackgroundColor3=t.Panel
    outer.Size=UDim2.new(1,0,0,38); outer.ClipsDescendants=false; outer.ZIndex=5
    Instance.new("UICorner",outer).CornerRadius=UDim.new(0,8); Instance.new("UIStroke",outer).Color=t.Dim
    local lbl=Instance.new("TextLabel",outer); lbl.BackgroundTransparency=1; lbl.ZIndex=6
    lbl.Position=UDim2.new(0,12,0,0); lbl.Size=UDim2.new(0.45,0,1,0)
    lbl.Font=Enum.Font.GothamMedium; lbl.Text=label; lbl.TextColor3=Color3.fromRGB(200,200,210); lbl.TextSize=11; lbl.TextXAlignment=Enum.TextXAlignment.Left
    local mainBtn=Instance.new("TextButton",outer); mainBtn.ZIndex=7
    mainBtn.Position=UDim2.new(1,-122,0.5,-13); mainBtn.Size=UDim2.new(0,112,0,26)
    mainBtn.BackgroundColor3=t.Dim; mainBtn.Font=Enum.Font.Gotham; mainBtn.Text=tostring(default).." ▾"; mainBtn.TextSize=10
    Instance.new("UICorner",mainBtn).CornerRadius=UDim.new(0,5); bindAccent(mainBtn,"TextColor3")
    local sl=Instance.new("ScrollingFrame",mainBtn); sl.Name="DD"
    sl.Position=UDim2.new(0,0,1,4); sl.Size=UDim2.new(1.4,-14,0,0); sl.Visible=false; sl.ZIndex=200
    sl.BackgroundColor3=t.Panel; sl.ScrollBarThickness=2; sl.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sl.ScrollBarImageColor3=accent(); sl.BorderSizePixel=0; sl.ClipsDescendants=true
    Instance.new("UIStroke",sl).Color=t.Dim; Instance.new("UICorner",sl).CornerRadius=UDim.new(0,6)
    Instance.new("UIListLayout",sl).SortOrder=Enum.SortOrder.LayoutOrder
    local api={CurrentList=list,SelectedValue=default}
    local function refreshItems()
        for _,c in ipairs(sl:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _,v in ipairs(api.CurrentList) do
            local ib=Instance.new("TextButton",sl); ib.BackgroundColor3=t.Panel
            ib.Size=UDim2.new(1,0,0,26); ib.Font=Enum.Font.Gotham; ib.Text=tostring(v)
            ib.TextColor3=Color3.fromRGB(215,215,225); ib.TextSize=10; ib.ZIndex=201; ib.BorderSizePixel=0
            ib.MouseEnter:Connect(function() ib.BackgroundColor3=t.Dim end)
            ib.MouseLeave:Connect(function() ib.BackgroundColor3=t.Panel end)
            ib.MouseButton1Click:Connect(function()
                api.SelectedValue=v; mainBtn.Text=tostring(v).." ▾"; sl.Visible=false
                sl.Size=UDim2.new(1.4,-14,0,0); outer.ZIndex=5; cb(v)
            end)
        end
    end
    mainBtn.MouseButton1Click:Connect(function()
        sl.Visible=not sl.Visible
        sl.Size=sl.Visible and UDim2.new(1.4,-14,0,math.min(#api.CurrentList*26,120)) or UDim2.new(1.4,-14,0,0)
        outer.ZIndex=sl.Visible and 100 or 5
    end)
    function api:SetValues(nl) api.CurrentList=nl; api.SelectedValue=nl[1] or "None"; mainBtn.Text=tostring(api.SelectedValue).." ▾"; refreshItems() end
    function api:SetValue(tv) api.SelectedValue=tv; mainBtn.Text=tostring(tv).." ▾"; sl.Visible=false; sl.Size=UDim2.new(1.4,-14,0,0); outer.ZIndex=5; cb(tv) end
    refreshItems(); return api
end

-- ────────────────────────────────────────────────────────────────────────────
-- TAB 1 — FARM
-- ────────────────────────────────────────────────────────────────────────────
local FarmPage=CreateTab("🏠 Farm",1)

Section(FarmPage,"Farm Engine Control")

-- AUTO FARM (master toggle)
local AutoFarmToggle = Toggle(FarmPage,"🔄 Auto Farm (Master)",EngineConfig.AutoFarm,function(v)
    EngineConfig.AutoFarm=v
    if v then
        if ctx._victoryDetected then task.spawn(function() DisableAutoFarm("Victory aktif.") end)
        else task.spawn(startFarmLoop) end
        CustomNotify("🔄 FARM","Master ON — memulai farm loop.",2)
    else
        ctx._searchInterrupt=true
        CustomNotify("🔄 FARM","Master OFF.",2)
    end
end)
-- Register callback so DisableAutoFarm can reset the toggle UI
ctx.GUI_OnFarmDisabled = function()
    pcall(function() AutoFarmToggle:SetValue(false) end)
end

-- Sub-target selector: 3 pill buttons in a row
local subRow=Instance.new("Frame"); subRow.Parent=FarmPage; subRow.BackgroundTransparency=1
subRow.Size=UDim2.new(1,0,0,34)
local subLayout=Instance.new("UIListLayout",subRow)
subLayout.FillDirection=Enum.FillDirection.Horizontal; subLayout.Padding=UDim.new(0,6)
subLayout.SortOrder=Enum.SortOrder.LayoutOrder; subLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center; subLayout.VerticalAlignment=Enum.VerticalAlignment.Center

local function PillCheck(parent, emoji, label, state, onSet)
    local t=getTheme()
    local pill=Instance.new("TextButton",parent); pill.Size=UDim2.new(0,148,0,28)
    pill.BackgroundColor3=state and accent() or t.Dim
    pill.Font=Enum.Font.GothamSemibold; pill.TextSize=11; pill.TextColor3=Color3.white
    pill.Text=(state and "✓ " or "· ")..emoji.." "..label
    Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
    local s=state
    local api={}
    function api:SetValue(v)
        s=v; onSet(v)
        TweenService:Create(pill,TweenInfo.new(0.2),{BackgroundColor3=v and accent() or t.Dim}):Play()
        pill.Text=(v and "✓ " or "· ")..emoji.." "..label
    end
    function api:Get() return s end
    pill.MouseButton1Click:Connect(function() api:SetValue(not s) end)
    return api
end

local MonsterPill = PillCheck(subRow,"⚔","Monster", EngineConfig.FarmMonster, function(v) EngineConfig.FarmMonster=v end)
local ChestPill   = PillCheck(subRow,"📦","Chest",   EngineConfig.FarmChest,   function(v) EngineConfig.FarmChest=v end)
local EggPill     = PillCheck(subRow,"🥚","Egg",     EngineConfig.FarmEgg,     function(v) EngineConfig.FarmEgg=v end)

-- AUTO FIND
local AutoFindToggle=Toggle(FarmPage,"🔍 Auto Find (Navigate World)",EngineConfig.AutoFind,function(v)
    EngineConfig.AutoFind=v
    if v then
        CustomNotify("🔍 AUTO FIND","Aktif! Navigasi jika tidak ada target.",2)
        if EngineConfig.AutoFarm then task.spawn(startFarmLoop) end
    else
        ctx._searchInterrupt=true
    end
end)

local KillAuraToggle=Toggle(FarmPage,"⚡ Kill Aura",EngineConfig.AutoAttackOnly,function(v) EngineConfig.AutoAttackOnly=v end)
local ReplayToggle  =Toggle(FarmPage,"🔄 Auto Play Again",EngineConfig.AutoReplayActive,function(v) EngineConfig.AutoReplayActive=v end)

Section(FarmPage,"Target Selector")

local WorldDropdown=Cycle(FarmPage,"World",WORLD_NAMES,EngineConfig.SelectedWorld,function(v) EngineConfig.SelectedWorld=v end)

local NormalDrop=Cycle(FarmPage,"Normal Mob",GameLists.NormalNPCs,"None",function(v)
    EngineConfig.SelectedNormalNpcId=(v~="None") and v or nil
end)
local BossDrop=Cycle(FarmPage,"Boss Mob",GameLists.BossNPCs,"None",function(v)
    EngineConfig.SelectedBossNpcId=(v~="None") and v or nil
end)

Button(FarmPage,"🔄 Scan Map Targets",function()
    local ni,bi={"None"},{"None"}; local cn,cb={}
    local ef=Workspace:FindFirstChild("EnemyNpc")
    if ef then
        for _,m in ipairs(ef:GetChildren()) do
            local id=CombatEngine.GetNpcId(m)
            if id and id~="" then
                if CombatEngine.GetLevelType(m)=="boss" then
                    if not cb then cb={} end
                    if not cb[id] then cb[id]=true; table.insert(bi,id) end
                else
                    if not cn[id] then cn[id]=true; table.insert(ni,id) end
                end
            end
        end
    end
    GameLists.NormalNPCs=ni; GameLists.BossNPCs=bi
    NormalDrop:SetValues(ni); BossDrop:SetValues(bi)
    CustomNotify("Scan","Target disinkronkan.",2)
end)

Section(FarmPage,"Metode & Posisi Gerakan")

local FarmMethodCycle=Cycle(FarmPage,"Metode",{"CFrame","Lerp"},EngineConfig.FarmMethod,function(v) EngineConfig.FarmMethod=v end)
local FarmPosDrop    =Dropdown(FarmPage,"Posisi Farm",POSITION_MODES,EngineConfig.FarmPosition,function(v) EngineConfig.FarmPosition=v end)
local LerpInput      =InputBox(FarmPage,"Lerp Alpha (0–1)",EngineConfig.LerpAlpha,false,function(v) EngineConfig.LerpAlpha=math.clamp(tonumber(v) or 0.3,0.01,1) end)

Section(FarmPage,"Skill Config")
local SkillToggle    =Toggle(FarmPage,"🎯 Auto Skill",EngineConfig.AutoSkillActive,function(v) EngineConfig.AutoSkillActive=v end)
local SkillPresetDrop=Dropdown(FarmPage,"Pilih Skill",SKILL_PRESETS,EngineConfig.SkillPreset,function(v) EngineConfig.SkillPreset=v end)
local SkillCDInput   =InputBox(FarmPage,"Skill Cooldown (s)",EngineConfig.SkillCooldownDelay,false,function(v) EngineConfig.SkillCooldownDelay=tonumber(v) or 0.5 end)

Section(FarmPage,"Weapon")
local WeaponToggle=Toggle(FarmPage,"🎒 Auto Weapon Switcher (3s)",EngineConfig.AutoWeaponSwitchActive,function(v) EngineConfig.AutoWeaponSwitchActive=v end)

-- ────────────────────────────────────────────────────────────────────────────
-- TAB 2 — VECTOR
-- ────────────────────────────────────────────────────────────────────────────
local VectorPage=CreateTab("⚙️ Vec",2)
Section(VectorPage,"Kinematic System Parameters")
local HeightInput    =InputBox(VectorPage,"Height Normal (Y)",EngineConfig.StandHeight,true,function(v) EngineConfig.StandHeight=tonumber(v) or 20 end)
local BossHInput     =InputBox(VectorPage,"Height Boss (Y)",EngineConfig.BossHeight,true,function(v) EngineConfig.BossHeight=tonumber(v) or 25 end)
local RadiusInput    =InputBox(VectorPage,"Orbit Radius",EngineConfig.OrbitRadius,true,function(v) EngineConfig.OrbitRadius=tonumber(v) or 12 end)
Button(VectorPage,"🎯 Dodge Boss (20)",function() EngineConfig.OrbitRadius=20; RadiusInput:SetValue(20) end)
Button(VectorPage,"🎯 Dodge Boss (200)",function() EngineConfig.OrbitRadius=200; RadiusInput:SetValue(200) end)
local SpeedInput     =InputBox(VectorPage,"Orbit Speed",EngineConfig.OrbitSpeed,true,function(v) EngineConfig.OrbitSpeed=tonumber(v) or 5 end)
local DelayInput     =InputBox(VectorPage,"CFrame Delay",EngineConfig.CFrameDelay,false,function(v) EngineConfig.CFrameDelay=tonumber(v) or 0.001 end)
local MultInput      =InputBox(VectorPage,"Hit Multiplier",EngineConfig.HitMultiplier,true,function(v) EngineConfig.HitMultiplier=tonumber(v) or 1 end)

-- ────────────────────────────────────────────────────────────────────────────
-- TAB 3 — PROFILE
-- ────────────────────────────────────────────────────────────────────────────
local ProfilePage=CreateTab("💾 Save",3)
Section(ProfilePage,"Data Profiles")
local selectedCfg="None"; local newCfgName=""
local CfgDrop=Dropdown(ProfilePage,"Selected Profile",ConfigSystem.GetConfigList(),"None",function(v) selectedCfg=v end)
InputBox(ProfilePage,"New Profile Name","",false,function(v) newCfgName=tostring(v) end)
local function RefreshCfgDrop(sel)
    CfgDrop:SetValues(ConfigSystem.GetConfigList())
    if sel then CfgDrop:SetValue(sel); selectedCfg=sel end
end
Button(ProfilePage,"➕ Save New Profile",function()
    if newCfgName~="" then
        local ok,err=ConfigSystem.SaveNew(newCfgName)
        if ok then CustomNotify("CONFIG","'"..newCfgName.."' disimpan!",3); task.wait(0.05); RefreshCfgDrop(newCfgName)
        else CustomNotify("SAVE ERROR",err,4) end
    else CustomNotify("WARN","Ketik nama profile!",3) end
end)
Button(ProfilePage,"📂 Load Profile",function()
    if selectedCfg~="None" then
        if ConfigSystem.Load(selectedCfg,function() ctx.SyncAllVisualUI() end) then
            CustomNotify("CONFIG","Dimuat: "..selectedCfg,3)
        else CustomNotify("CONFIG ERROR","File tidak valid.",3) end
    else CustomNotify("WARN","Pilih profile!",3) end
end)
Button(ProfilePage,"⚡ Set as Autoload",function()
    if selectedCfg=="None" then CustomNotify("WARN","Pilih profile!",3); return end
    ConfigSystem.SaveAutoLoadPointer(selectedCfg); CustomNotify("⚡ AUTOLOAD","'"..selectedCfg.."' aktif.",3)
end)
Button(ProfilePage,"❌ Reset Autoload",function() ConfigSystem.SaveAutoLoadPointer("None"); CustomNotify("AUTOLOAD OFF","Reset.",3) end)
Button(ProfilePage,"🔄 Overwrite Profile",function()
    local tgt=(newCfgName~="") and newCfgName or selectedCfg
    if tgt and tgt~="None" and tgt~="" then
        local ok,err=ConfigSystem.OverwriteExisting(tgt)
        if ok then CustomNotify("CONFIG","'"..tgt.."' ditimpa!",3); task.wait(0.05); RefreshCfgDrop(tgt)
        else CustomNotify("ERROR",err,4) end
    else CustomNotify("WARN","Pilih profile valid!",3) end
end)
Button(ProfilePage,"🗑️ Hapus Profile",function()
    if selectedCfg~="None" then
        if ConfigSystem.Delete(selectedCfg) then CustomNotify("CONFIG","Dihapus.",3); task.wait(0.05); RefreshCfgDrop()
        else CustomNotify("ERROR","Gagal hapus.",3) end
    else CustomNotify("WARN","Pilih target!",3) end
end)
Section(ProfilePage,"System Guard")
local AntiAFKToggle=Toggle(ProfilePage,"🛡️ Anti-AFK",EngineConfig.AntiAFKActive,function(state)
    EngineConfig.AntiAFKActive=state; local VU=Services.VirtualUser
    if state then
        if not getgenv().AntiAFK_XiFil then
            getgenv().AntiAFK_XiFil=LocalPlayer.Idled:Connect(function()
                VU:CaptureController(); VU:ClickButton2(Vector2.new())
            end)
        end; CustomNotify("GUARD","Anti-AFK aktif.",2)
    else
        if getgenv().AntiAFK_XiFil then getgenv().AntiAFK_XiFil:Disconnect(); getgenv().AntiAFK_XiFil=nil end
        CustomNotify("GUARD","Anti-AFK nonaktif.",2)
    end
end)
local AntiPausedToggle=Toggle(ProfilePage,"⏳ Disable Gameplay Paused",EngineConfig.AntiPausedActive,function(state)
    EngineConfig.AntiPausedActive=state
    Services.GuiService:SetGameplayPausedNotificationEnabled(not state)
    CustomNotify("GUARD",state and "Anti-Paused aktif." or "Nonaktif.",2)
end)
local AUTOEXEC_CODE='loadstring(game:HttpGet("https://xifil-hub-production.up.railway.app/api/lua/loader?game=soul_iron"))()'
local queue_tp=queue_on_teleport or queueonteleport or (rawget(_G,"syn") and syn.queue_on_teleport)
local AutoExecToggle=Toggle(ProfilePage,"⚡ Auto Exec on Rejoin",EngineConfig.AutoExecuteOnRejoin,function(state)
    EngineConfig.AutoExecuteOnRejoin=state
    if state then
        if queue_tp then queue_tp(AUTOEXEC_CODE); CustomNotify("⚡ AUTO EXEC","Aktif saat rejoin.",4)
        else CustomNotify("❌ GAGAL","Executor tidak support queue_on_teleport.",4) end
    else CustomNotify("INFO","Auto Exec dimatikan.",3) end
end)

-- ────────────────────────────────────────────────────────────────────────────
-- TAB 4 — SELL
-- ────────────────────────────────────────────────────────────────────────────
local SellPage=CreateTab("💰 Sell",4)
Section(SellPage,"Inventory Management")
local MainGui=LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainGui")
local EquipScroll=MainGui:FindFirstChild("ScreenBackpack") and MainGui.ScreenBackpack:FindFirstChild("InventoryFrame") and MainGui.ScreenBackpack.InventoryFrame:FindFirstChild("EquipmentContent") and MainGui.ScreenBackpack.InventoryFrame.EquipmentContent:FindFirstChild("ScrollingFrame")
local OresScroll=MainGui:FindFirstChild("ScreenEquipSell") and MainGui.ScreenEquipSell:FindFirstChild("SellFrame") and MainGui.ScreenEquipSell.SellFrame:FindFirstChild("OresContent") and MainGui.ScreenEquipSell.SellFrame.OresContent:FindFirstChild("ScrollingFrame")
local MatsScroll=MainGui:FindFirstChild("ScreenEquipSell") and MainGui.ScreenEquipSell:FindFirstChild("SellFrame") and MainGui.ScreenEquipSell.SellFrame:FindFirstChild("MaterialContent") and MainGui.ScreenEquipSell.SellFrame.MaterialContent:FindFirstChild("ScrollingFrame")
local BulkSel={}; local SELL_CATS={"All","Weapon","Helmet","Breastplate","Ore","Material"}
local SellCatDrop=Dropdown(SellPage,"Kategori",SELL_CATS,EngineConfig.SellCategory,function(v) EngineConfig.SellCategory=v end)
local IRC=Instance.new("ScrollingFrame"); IRC.Parent=SellPage
IRC.Size=UDim2.new(1,0,0,200); IRC.BackgroundTransparency=1; IRC.ScrollBarThickness=3; IRC.AutomaticCanvasSize=Enum.AutomaticSize.Y
Instance.new("UIListLayout",IRC).Padding=UDim.new(0,5)
local function sellItems(uuids,typ)
    if not uuids or #uuids==0 then return end
    if typ=="Material" then pcall(function() MaterialRE:FireServer("Sell",uuids,{}) end)
    elseif typ=="Ore" then pcall(function() ForgeRF:InvokeServer("Sell",uuids) end)
    else pcall(function() EquipmentRE:FireServer("Sell",uuids) end) end
end
local function scanInventory(parent,filter)
    for _,c in ipairs(parent:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    local db={}; for _,cat in ipairs(SELL_CATS) do db[cat]={} end
    local function ins(cat,id,uuid,vis)
        if not db[cat][id] then db[cat][id]={Visual=vis,UUIDs={},Orig=cat} end
        table.insert(db[cat][id].UUIDs,uuid)
        if not db["All"][id] then db["All"][id]={Visual=vis,UUIDs={},Orig=cat} end
        table.insert(db["All"][id].UUIDs,uuid)
    end
    if EquipScroll then
        for _,slot in ipairs(EquipScroll:GetChildren()) do
            if slot:IsA("GuiObject") and slot.Name~="UIListLayout" and slot.Name~="UIPadding" then
                local vis=slot.Name; local nl=slot:FindFirstChild("ItemName",true) or slot:FindFirstChild("Name",true)
                if nl and nl:IsA("TextLabel") then vis=nl.Text end
                local uuid=slot:GetAttribute("UUID") or slot.Name
                local uo=slot:FindFirstChild("UUID",true); if uo then uuid=uo:IsA("ValueBase") and uo.Value or uo.Text end
                local check=string.lower(vis.." "..slot.Name); local cat="Weapon"
                if check:find("body") or check:find("plate") or check:find("armor") then cat="Breastplate"
                elseif check:find("helm") or check:find("head") or check:find("hat") then cat="Helmet" end
                ins(cat,vis,uuid,vis)
            end
        end
    end
    local function scrapeStack(sg,cn)
        if not sg then return end
        for _,slot in ipairs(sg:GetChildren()) do
            if slot:IsA("GuiObject") and slot.Name~="UIListLayout" and slot.Name~="UIPadding" then
                local idA=slot.Name; local io=slot:FindFirstChild("ID",true)
                if io then idA=io:IsA("ValueBase") and tostring(io.Value) or io.Text end
                local nl=slot:FindFirstChild("ItemName",true) or slot:FindFirstChild("Name",true)
                local vis=idA; if nl and nl:IsA("TextLabel") then vis=nl.Text end
                ins(cn,idA,idA,vis)
            end
        end
    end
    scrapeStack(OresScroll,"Ore"); scrapeStack(MatsScroll,"Material")
    local t=getTheme()
    for targetID,d in pairs(db[filter]) do
        local sk=d.Orig.."_"..targetID
        if (d.Orig=="Ore" or d.Orig=="Material") and EngineConfig.AutoSellStaticList[sk] then
            BulkSel[sk]={UUIDs=d.UUIDs,Type=d.Orig}
        end
        local tot=#d.UUIDs; local btnTxt=d.Visual.." [x"..tot.."]"
        local IB=Instance.new("TextButton",parent); IB.Name="IR"
        IB.Size=UDim2.new(1,-10,0,30); IB.Font=Enum.Font.Gotham; IB.TextSize=11
        IB.TextXAlignment=Enum.TextXAlignment.Left; IB.TextColor3=Color3.white
        Instance.new("UICorner",IB).CornerRadius=UDim.new(0,5)
        local function rfBtnVis()
            if BulkSel[sk] then IB.BackgroundColor3=Color3.fromRGB(40,100,55); IB.Text="  ✅ "..btnTxt
            else IB.BackgroundColor3=t.Dim; IB.Text="  · "..btnTxt end
        end; rfBtnVis()
        IB.MouseButton1Click:Connect(function()
            if BulkSel[sk] then BulkSel[sk]=nil; if d.Orig=="Ore" or d.Orig=="Material" then EngineConfig.AutoSellStaticList[sk]=nil end
            else BulkSel[sk]={UUIDs=d.UUIDs,Type=d.Orig}; if d.Orig=="Ore" or d.Orig=="Material" then EngineConfig.AutoSellStaticList[sk]=true end
            end; rfBtnVis()
        end)
    end
end
Button(SellPage,"🔄 Scan Inventory",function() scanInventory(IRC,EngineConfig.SellCategory); CustomNotify("SCANNER","Kategori: "..EngineConfig.SellCategory,2) end)
Button(SellPage,"💰 Execute Sell",function()
    local eq,ore,mat,cnt={},{},{},0
    for _,d in pairs(BulkSel) do for _,u in ipairs(d.UUIDs) do
        if d.Type=="Material" then table.insert(mat,u) elseif d.Type=="Ore" then table.insert(ore,u) else table.insert(eq,u) end; cnt=cnt+1
    end end
    if cnt==0 then CustomNotify("SELL WARN","Tidak ada item!",3); return end
    if #eq>0 then sellItems(eq,"Eq") end; if #ore>0 then sellItems(ore,"Ore") end; if #mat>0 then sellItems(mat,"Material") end
    task.wait(0.5); BulkSel={}; scanInventory(IRC,EngineConfig.SellCategory); CustomNotify("SELL","("..cnt.." item) selesai.",3)
end)
Section(SellPage,"Merchant")
Button(SellPage,"🛒 Buka Merchant",function()
    local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp=char:WaitForChild("HumanoidRootPart"); local prompt=nil
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local txt=(v.ObjectText..v.ActionText):lower()
            if v.Parent.Name:lower():match("merchant") or txt:match("merchant") or v.Parent.Name:lower():match("shop") or txt:match("shop") then prompt=v; break end
        end
    end
    if prompt and prompt.Parent:IsA("BasePart") then
        hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=prompt.Parent.CFrame*CFrame.new(0,2,0); task.wait(0.3)
        if fireproximityprompt then fireproximityprompt(prompt); CustomNotify("MERCHANT","Terbuka!",3)
        else CustomNotify("WARN","Executor tidak support fireproximityprompt",3) end
    else CustomNotify("MERCHANT ERROR","Gagal menemukan Merchant!",4) end
end)

-- ────────────────────────────────────────────────────────────────────────────
-- TAB 5 — ROOM
-- ────────────────────────────────────────────────────────────────────────────
local RoomPage=CreateTab("🚪 Room",5)
Section(RoomPage,"Matchmaking Control")
local RoomMapping={
    World1={"Room1","Room2","Room3","Room4"}, World2={"Room1","Room2","Room3","Room4"},
    World3={"Room1","Room2","Room3","Room4"}, Cave1={"Room5","Room6","Room7","Room8"},
    Cave2={"Room5","Room6","Room7","Room8"},  Cave3={"Room5","Room6","Room7","Room8"},
}
local function buildModeList(isCave,modeType)
    local list={}
    if isCave then for i=1,4 do table.insert(list,getModeLabel(i)) end
    elseif modeType=="Hell" then for i=6,10 do table.insert(list,getModeLabel(i)) end
    else for i=1,5 do table.insert(list,getModeLabel(i)) end end
    return list
end
local RoomModeTypeDrop,RoomModeDrop,RoomTargetDrop
local function updateModeDrop(worldDisplay,modeType)
    local cave=isCaveWorld(worldDisplay)
    local list=buildModeList(cave,modeType)
    if RoomModeDrop then RoomModeDrop:SetValues(list) end
    EngineConfig.RoomMode=getModeNumber(list[1])
end
local RoomWorldDrop=Dropdown(RoomPage,"World",ROOM_WORLD_DISPLAY,EngineConfig.RoomWorldDisplay,function(val)
    EngineConfig.RoomWorldDisplay=val
    local key=ROOM_WORLD_KEY[val] or "World1"
    local cave=isCaveWorld(val); local mt=cave and "Normal" or EngineConfig.RoomModeType
    if cave then EngineConfig.RoomModeType="Normal"; if RoomModeTypeDrop then RoomModeTypeDrop:SetValue("Normal") end end
    updateModeDrop(val,mt)
    local rooms=RoomMapping[key] or {"Room1"}
    if RoomTargetDrop then RoomTargetDrop:SetValues(rooms); EngineConfig.RoomTarget=rooms[1] end
    task.spawn(function() pcall(function() WorldPlaceRE:FireServer("SelectWorld",key,EngineConfig.RoomMode) end) end)
end)
RoomModeTypeDrop=Dropdown(RoomPage,"Mode Type",{"Normal","Hell"},EngineConfig.RoomModeType,function(val)
    EngineConfig.RoomModeType=val; updateModeDrop(EngineConfig.RoomWorldDisplay,val)
end)
local initModeList=buildModeList(isCaveWorld(EngineConfig.RoomWorldDisplay),EngineConfig.RoomModeType)
RoomModeDrop=Dropdown(RoomPage,"Mode",initModeList,getModeLabel(EngineConfig.RoomMode),function(val) EngineConfig.RoomMode=getModeNumber(val) end)
local RoomPlayersDrop=Dropdown(RoomPage,"Jumlah Player",{1,2,3,4},EngineConfig.RoomPlayers,function(val) EngineConfig.RoomPlayers=tonumber(val) end)
local initRooms=RoomMapping[ROOM_WORLD_KEY[EngineConfig.RoomWorldDisplay] or "World1"] or {"Room1"}
RoomTargetDrop=Dropdown(RoomPage,"Target Room",initRooms,EngineConfig.RoomTarget or initRooms[1],function(val) EngineConfig.RoomTarget=val end)
Section(RoomPage,"Match Actions")
Button(RoomPage,"🛠️ Create Room",function()
    local key=ROOM_WORLD_KEY[EngineConfig.RoomWorldDisplay] or "World1"
    pcall(function() GameMatchRE:FireServer("CreatRoom",key,EngineConfig.RoomMode,EngineConfig.RoomPlayers)
        CustomNotify("ROOM","Room: "..EngineConfig.RoomWorldDisplay.." [M:"..EngineConfig.RoomMode.."]",3) end)
end)
Button(RoomPage,"🚀 TP Room",function()
    local tgt=EngineConfig.RoomTarget or "Room1"
    local mrf=Workspace:FindFirstChild("MatchRoom"); local rf=mrf and mrf:FindFirstChild(tgt)
    local tm=rf and rf:FindFirstChild("Touch"); local tp=tm and tm:FindFirstChild("Part")
    if tp and tp:IsA("BasePart") then
        local char=LocalPlayer.Character; local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=tp.CFrame; CustomNotify("ROOM TP","Ke "..tgt,3) end
    else CustomNotify("ROOM ERROR","Room '"..tgt.."' tidak ditemukan!",4) end
end)
Button(RoomPage,"🚪 Leave Room",function() pcall(function() GameMatchRE:FireServer("LeaveRoom") end); CustomNotify("ROOM","Leave dikirim.",2) end)

-- ────────────────────────────────────────────────────────────────────────────
-- TAB 6 — FORGE & NPC
-- ────────────────────────────────────────────────────────────────────────────
local ForgePage=CreateTab("🔨 Forge",6)
Section(ForgePage,"Forge Utilities")
local function TPAndOpenByKw(kws, title)
    local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp=char:WaitForChild("HumanoidRootPart"); local prompt=nil
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local txt=string.lower(v.ObjectText..v.ActionText..v.Parent.Name)
            local matched=false; for _,kw in ipairs(kws) do if txt:find(kw) then matched=true; break end end
            if matched then prompt=v; break end
        end
    end
    if prompt and prompt.Parent:IsA("BasePart") then
        hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=prompt.Parent.CFrame*CFrame.new(0,2,0); task.wait(0.3)
        if fireproximityprompt then fireproximityprompt(prompt); CustomNotify(title,"UI berhasil dibuka!",3)
        else CustomNotify("WARN","Executor tidak support fireproximityprompt",3) end
    else CustomNotify(title.." ERROR","NPC tidak ditemukan!",4) end
end
Button(ForgePage,"🚀 Bypass FORGE",function()
    local char=LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp=char:WaitForChild("HumanoidRootPart"); local prompt=nil
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local txt=(v.ObjectText..v.ActionText):lower()
            if v.Parent.Name:lower():match("forge") or txt:match("forge") or txt:match("craft") then prompt=v; break end
        end
    end
    if prompt and prompt.Parent:IsA("BasePart") then
        hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=prompt.Parent.CFrame*CFrame.new(0,2,0); task.wait(0.3)
        if fireproximityprompt then fireproximityprompt(prompt) end
    else hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=CFrame.new(122.5,12,-45.8); task.wait(0.3) end
    pcall(function()
        local TaskRE=Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("TaskSystem"):WaitForChild("TaskRE")
        TaskRE:FireServer("UpdateTaskProgress","OpenGUIWindow","ScreenForging")
    end); CustomNotify("FORGE","TP & Bypass.",3)
end)
Section(ForgePage,"NPC Utility Access")
Button(ForgePage,"🔮 Enchantment & Runes",function() TPAndOpenByKw({"enchant"},"ENCHANTMENT") end)
Button(ForgePage,"🛒 Grocery",function() TPAndOpenByKw({"grocery","grocer"},"GROCERY") end)
Button(ForgePage,"🐾 Pet Upgrade",function() TPAndOpenByKw({"pet","upgrade","petupgrade"},"PET UPGRADE") end)
Button(ForgePage,"🏕️ Pet Expedition",function() TPAndOpenByKw({"expedition","petexp"},"PET EXPEDITION") end)
Button(ForgePage,"✨ Upgrade Equipment",function() TPAndOpenByKw({"bless","blessing"},"BLESS") end)
Button(ForgePage,"📖 The Guide",function() TPAndOpenByKw({"guide","the"},"THE GUIDE") end)

-- ────────────────────────────────────────────────────────────────────────────
-- TAB 7 — SETTINGS
-- ────────────────────────────────────────────────────────────────────────────
local SettingsPage=CreateTab("⚙ Set",7)
Section(SettingsPage,"Appearance / Theme")

-- Theme Dropdown
Dropdown(SettingsPage,"Color Theme",THEME_NAMES,GuiConfig.Theme,function(v)
    switchTheme(v)
    CustomNotify("🎨 THEME",v.." aktif.",2)
end)

-- Transparency slider
local transRow=Instance.new("Frame"); transRow.Parent=SettingsPage; transRow.BackgroundTransparency=1; transRow.Size=UDim2.new(1,0,0,52)
local transLbl=Instance.new("TextLabel",transRow); transLbl.BackgroundTransparency=1; transLbl.Size=UDim2.new(1,0,0,20)
transLbl.Font=Enum.Font.GothamMedium; transLbl.Text="Transparansi GUI: 0%"
transLbl.TextColor3=Color3.fromRGB(200,200,210); transLbl.TextSize=11; transLbl.TextXAlignment=Enum.TextXAlignment.Left
local trackBG=Instance.new("Frame",transRow); trackBG.BackgroundColor3=t0.Dim
trackBG.Size=UDim2.new(1,0,0,6); trackBG.Position=UDim2.new(0,0,0,32); trackBG.BorderSizePixel=0
Instance.new("UICorner",trackBG).CornerRadius=UDim.new(1,0)
local trackFill=Instance.new("Frame",trackBG); trackFill.BackgroundColor3=accent()
trackFill.Size=UDim2.new(0,0,1,0); trackFill.BorderSizePixel=0
Instance.new("UICorner",trackFill).CornerRadius=UDim.new(1,0); bindAccent(trackFill,"BackgroundColor3")
local trackKnob=Instance.new("TextButton",trackBG); trackKnob.BackgroundColor3=Color3.white
trackKnob.Size=UDim2.new(0,16,0,16); trackKnob.Position=UDim2.new(0,-8,0.5,-8); trackKnob.Text=""
Instance.new("UICorner",trackKnob).CornerRadius=UDim.new(1,0)
local trackKnobStk=Instance.new("UIStroke",trackKnob); bindAccent(trackKnobStk,"Color")

local trackDragging=false
local function setTransFromX(absX)
    local tbAbs=trackBG.AbsolutePosition.X; local tbW=trackBG.AbsoluteSize.X
    local ratio=math.clamp((absX-tbAbs)/tbW,0,1)
    trackFill.Size=UDim2.new(ratio,0,1,0)
    trackKnob.Position=UDim2.new(ratio,-8,0.5,-8)
    local pct=math.floor(ratio*100)
    transLbl.Text="Transparansi GUI: "..pct.."%"
    applyTransparency(ratio*0.88)
end
trackKnob.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then trackDragging=true end
end)
trackKnob.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then trackDragging=false end
end)
UIS.InputChanged:Connect(function(input)
    if trackDragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        setTransFromX(input.Position.X)
    end
end)
trackBG.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        setTransFromX(input.Position.X); trackDragging=true end
end)

Section(SettingsPage,"Open Gesture")
Dropdown(SettingsPage,"Buka GUI dengan",{"Slide","Click"},GuiConfig.GestureOpen,function(v)
    GuiConfig.GestureOpen=v; CustomNotify("GESTURE",v.." mode aktif.",2)
end)

Section(SettingsPage,"Info")
local infoLbl=Instance.new("TextLabel",SettingsPage); infoLbl.BackgroundTransparency=1; infoLbl.Size=UDim2.new(1,0,0,60)
infoLbl.Font=Enum.Font.Gotham; infoLbl.TextSize=10; infoLbl.TextColor3=Color3.fromRGB(130,130,145)
infoLbl.TextWrapped=true; infoLbl.TextXAlignment=Enum.TextXAlignment.Left
infoLbl.Text="XIFIL Hub PRO // Iron Soul V5\nGesture: tahan tombol floating → geser kanan untuk buka\nResize: seret sudut kanan bawah window"

-- ── SyncAllVisualUI ───────────────────────────────────────────────────────────
function ctx.SyncAllVisualUI()
    pcall(function()
        AutoFarmToggle:SetValue(EngineConfig.AutoFarm)
        MonsterPill:SetValue(EngineConfig.FarmMonster)
        ChestPill:SetValue(EngineConfig.FarmChest)
        EggPill:SetValue(EngineConfig.FarmEgg)
        AutoFindToggle:SetValue(EngineConfig.AutoFind)
        KillAuraToggle:SetValue(EngineConfig.AutoAttackOnly)
        ReplayToggle:SetValue(EngineConfig.AutoReplayActive)
        WorldDropdown:SetValue(EngineConfig.SelectedWorld)
        FarmMethodCycle:SetValue(EngineConfig.FarmMethod)
        FarmPosDrop:SetValue(EngineConfig.FarmPosition)
        LerpInput:SetValue(EngineConfig.LerpAlpha)
        SkillToggle:SetValue(EngineConfig.AutoSkillActive)
        SkillPresetDrop:SetValue(EngineConfig.SkillPreset)
        SkillCDInput:SetValue(EngineConfig.SkillCooldownDelay)
        WeaponToggle:SetValue(EngineConfig.AutoWeaponSwitchActive)
        HeightInput:SetValue(EngineConfig.StandHeight)
        BossHInput:SetValue(EngineConfig.BossHeight)
        RadiusInput:SetValue(EngineConfig.OrbitRadius)
        SpeedInput:SetValue(EngineConfig.OrbitSpeed)
        DelayInput:SetValue(EngineConfig.CFrameDelay)
        MultInput:SetValue(EngineConfig.HitMultiplier)
        AntiAFKToggle:SetValue(EngineConfig.AntiAFKActive)
        AntiPausedToggle:SetValue(EngineConfig.AntiPausedActive)
        AutoExecToggle:SetValue(EngineConfig.AutoExecuteOnRejoin)
        SellCatDrop:SetValue(EngineConfig.SellCategory)
        RoomWorldDrop:SetValue(EngineConfig.RoomWorldDisplay)
        RoomModeTypeDrop:SetValue(EngineConfig.RoomModeType)
        if RoomTargetDrop then RoomTargetDrop:SetValue(EngineConfig.RoomTarget) end
    end)
end

-- ── Window Open/Close Animations ──────────────────────────────────────────────
local function openGUI()
    if MainWindow.Visible then return end
    _minimized=false; MainWindow.Size=_fullSize
    MainWindow.Position=UDim2.new(-0.6,0,MainWindow.Position.Y.Scale,MainWindow.Position.Y.Offset)
    MainWindow.Visible=true
    TweenService:Create(MainWindow,TweenInfo.new(0.42,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,-260,0.5,-225)}):Play()
end
local function closeGUI()
    local tw=TweenService:Create(MainWindow,TweenInfo.new(0.32,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Position=UDim2.new(1.1,0,MainWindow.Position.Y.Scale,MainWindow.Position.Y.Offset)})
    tw:Play(); tw.Completed:Connect(function() MainWindow.Visible=false end)
end
local function toggleGUI() if MainWindow.Visible then closeGUI() else openGUI() end end

-- ── Floating Gesture Button ───────────────────────────────────────────────────
local TogGui=Instance.new("ScreenGui")
TogGui.Name="XiFil_Toggle"; TogGui.Parent=LocalPlayer:WaitForChild("PlayerGui")
TogGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; TogGui.ResetOnSpawn=false; TogGui.DisplayOrder=99985
RuntimeMaid:GiveTask(TogGui)

local BtnCon=Instance.new("Frame",TogGui); BtnCon.BackgroundTransparency=1
BtnCon.Position=UDim2.new(0,0,0.12,0); BtnCon.Size=UDim2.fromOffset(52,64)

local floatBtn=Instance.new("TextButton",BtnCon)
floatBtn.BackgroundColor3=t0.Panel; floatBtn.BorderSizePixel=0
floatBtn.Size=UDim2.new(1,0,1,0); floatBtn.Text=""
floatBtn.AutoButtonColor=false
Instance.new("UICorner",floatBtn).CornerRadius=UDim.new(0,10)
local fStk=Instance.new("UIStroke",floatBtn); fStk.Thickness=1.5; bindAccent(fStk,"Color")

local fIcon=Instance.new("TextLabel",floatBtn); fIcon.BackgroundTransparency=1
fIcon.Size=UDim2.new(1,0,0.55,0); fIcon.Position=UDim2.new(0,0,0.05,0)
fIcon.Font=Enum.Font.GothamBlack; fIcon.Text="XI"; fIcon.TextSize=16; bindAccent(fIcon,"TextColor3")
local fSub=Instance.new("TextLabel",floatBtn); fSub.BackgroundTransparency=1
fSub.Size=UDim2.new(1,0,0.4,0); fSub.Position=UDim2.new(0,0,0.58,0)
fSub.Font=Enum.Font.Gotham; fSub.Text="FIL"; fSub.TextSize=9; fSub.TextColor3=Color3.fromRGB(160,160,175)

local fDot=Instance.new("Frame",floatBtn); fDot.Size=UDim2.new(0,5,0,5)
fDot.Position=UDim2.new(0.5,-2.5,1,-8); bindAccent(fDot,"BackgroundColor3")
Instance.new("UICorner",fDot).CornerRadius=UDim.new(1,0)

-- Draggable float button
local _fbDrag,_fbDragStart,_fbDragPos=false,nil,nil
floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        _fbDrag=true; _fbDragStart=input.Position; _fbDragPos=BtnCon.Position
    end
end)
floatBtn.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        _fbDrag=false
    end
end)

-- Gesture/Click logic
local _slideStartX=nil; local _slideTriggered=false
floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        _slideStartX=input.Position.X; _slideTriggered=false
    end
end)
floatBtn.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        if not _slideTriggered and GuiConfig.GestureOpen=="Click" then toggleGUI()
        elseif not _slideTriggered and GuiConfig.GestureOpen=="Slide" and MainWindow.Visible then closeGUI() end
        _slideStartX=nil; _slideTriggered=false
    end
end)
UIS.InputChanged:Connect(function(input)
    if (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) and _fbDrag then
        if _slideStartX then
            local dx=input.Position.X-_slideStartX
            if GuiConfig.GestureOpen=="Slide" and dx>55 and not _slideTriggered then
                _slideTriggered=true; openGUI()
            end
        end
        if _fbDragPos then
            local delta=input.Position-_fbDragStart
            BtnCon.Position=UDim2.new(_fbDragPos.X.Scale,_fbDragPos.X.Offset+delta.X,_fbDragPos.Y.Scale,_fbDragPos.Y.Offset+delta.Y)
        end
    end
end)

-- Hover animation on float button
floatBtn.MouseEnter:Connect(function()
    TweenService:Create(floatBtn,TweenInfo.new(0.2),{BackgroundColor3=t0.Dim}):Play()
    TweenService:Create(fStk,TweenInfo.new(0.2),{Transparency=0}):Play()
end)
floatBtn.MouseLeave:Connect(function()
    TweenService:Create(floatBtn,TweenInfo.new(0.25),{BackgroundColor3=t0.Panel}):Play()
    TweenService:Create(fStk,TweenInfo.new(0.3),{Transparency=0.3}):Play()
end)

-- ── Window Resize Handle (bottom-right corner) ─────────────────────────────
local ResizeHandle=Instance.new("TextButton")
ResizeHandle.Parent=MainWindow; ResizeHandle.BackgroundTransparency=0.5
ResizeHandle.BackgroundColor3=t0.Dim; ResizeHandle.Text="◢"; ResizeHandle.TextSize=12
ResizeHandle.TextColor3=Color3.fromRGB(120,120,140)
ResizeHandle.Size=UDim2.new(0,18,0,18); ResizeHandle.Position=UDim2.new(1,-18,1,-18)
ResizeHandle.AutoButtonColor=false; ResizeHandle.ZIndex=20

local _rsDrag=false; local _rsStart=nil; local _rsStartSize=nil
local MIN_W,MAX_W=440,720; local MIN_H,MAX_H=380,560

ResizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        _rsDrag=true; _rsStart=input.Position; _rsStartSize=MainWindow.AbsoluteSize
    end
end)
ResizeHandle.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
        _rsDrag=false; _fullSize=MainWindow.Size
    end
end)
UIS.InputChanged:Connect(function(input)
    if _rsDrag and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local delta=input.Position-_rsStart
        local nw=math.clamp(_rsStartSize.X+delta.X,MIN_W,MAX_W)
        local nh=math.clamp(_rsStartSize.Y+delta.Y,MIN_H,MAX_H)
        MainWindow.Size=UDim2.new(0,nw,0,nh)
    end
end)

-- ── Init ──────────────────────────────────────────────────────────────────────
TabRegistry["🏠 Farm"].Select()
applyTheme()
updateRGBLoop()

task.defer(function()
    if EngineConfig.AntiAFKActive and AntiAFKToggle then AntiAFKToggle:SetValue(true) end
    if EngineConfig.AntiPausedActive and AntiPausedToggle then AntiPausedToggle:SetValue(true) end
end)

ConfigSystem.ExecuteAutoLoad(function() ctx.SyncAllVisualUI() end)

CustomNotify("XIFIL Hub PRO","Iron Soul V5 — Siap!",4)

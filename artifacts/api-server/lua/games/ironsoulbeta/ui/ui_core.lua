--------------------------------------------------------------------------------
--// ui/ui_core.lua — S11 Visual Config & Themes
--//                  S12 Draggable & Resize
--//                  S13 UI Component Builder
--//                  S14 Main Window & Window Controls
--//                  S15 Tab System
--//                  S16 Background Effects + Config Patch (S16b)
--------------------------------------------------------------------------------
local H                  = getgenv().Hub
local LocalPlayer        = H.LocalPlayer
local TweenService       = H.TweenService
local Services           = H.Services
local RuntimeMaid        = H.RuntimeMaid
local RegisterTranslation   = H.RegisterTranslation
local RegisterTranslationFn = H.RegisterTranslationFn
-- Dependencies dari modul sebelumnya (digunakan di S16b Config Patch & ApplyAllVisuals)
local EngineConfig       = H.EngineConfig
local ConfigSystem       = H.ConfigSystem    -- digunakan di S16b patch SaveNew/Load
local NC                 = H.NC              -- notification container dari notify.lua
local CustomNotify       = H.CustomNotify
local HttpService        = H.HttpService
local FOLDER_NAME        = H.FOLDER_NAME
local ApplyTranslations  = H.ApplyTranslations

-- [S11] VISUAL CONFIG & THEMES
--------------------------------------------------------------------------------
local GUI_THEMES = {
    Cyan   = { Primary=Color3.fromRGB(0,220,255),   Secondary=Color3.fromRGB(0,160,200),   Text=Color3.fromRGB(0,220,255)   },
    Red    = { Primary=Color3.fromRGB(255,60,80),    Secondary=Color3.fromRGB(200,20,50),    Text=Color3.fromRGB(255,80,100)  },
    Purple = { Primary=Color3.fromRGB(160,80,255),   Secondary=Color3.fromRGB(110,40,200),   Text=Color3.fromRGB(180,100,255) },
    Green  = { Primary=Color3.fromRGB(0,220,120),    Secondary=Color3.fromRGB(0,160,90),     Text=Color3.fromRGB(0,220,130)   },
    Gold   = { Primary=Color3.fromRGB(255,195,30),   Secondary=Color3.fromRGB(200,145,0),    Text=Color3.fromRGB(255,210,60)  },
    Pink   = { Primary=Color3.fromRGB(255,80,200),   Secondary=Color3.fromRGB(200,30,150),   Text=Color3.fromRGB(255,100,210) },
    Orange = { Primary=Color3.fromRGB(255,130,30),   Secondary=Color3.fromRGB(220,90,0),     Text=Color3.fromRGB(255,150,50)  },
    RGB    = { Primary=Color3.fromRGB(96,205,255),   Secondary=Color3.fromRGB(60,150,200),   Text=Color3.fromRGB(120,220,255) },
    White  = { Primary=Color3.fromRGB(240,240,255),  Secondary=Color3.fromRGB(180,180,210),  Text=Color3.fromRGB(255,255,255) },
}
local THEME_NAMES = { "Cyan","Red","Purple","Green","Gold","Pink","Orange","RGB","White" }

local GUI_BACKGROUNDS = {
    ["Dark (Default)"] = { Main=Color3.fromRGB(13,13,20),   Header=Color3.fromRGB(18,18,30)  },
    ["Obsidian Black"] = { Main=Color3.fromRGB(8,8,8),      Header=Color3.fromRGB(14,14,14)  },
    ["Space Grey"]     = { Main=Color3.fromRGB(28,28,30),   Header=Color3.fromRGB(36,36,38)  },
    ["Midnight Blue"]  = { Main=Color3.fromRGB(10,14,26),   Header=Color3.fromRGB(16,22,38)  },
    ["Deep Slate"]     = { Main=Color3.fromRGB(18,22,28),   Header=Color3.fromRGB(26,32,40)  },
    ["Abyssal Teal"]   = { Main=Color3.fromRGB(12,24,28),   Header=Color3.fromRGB(18,36,42)  },
    ["Dark Amethyst"]  = { Main=Color3.fromRGB(16,12,26),   Header=Color3.fromRGB(24,18,38)  },
    ["Crimson Shadow"] = { Main=Color3.fromRGB(22,10,12),   Header=Color3.fromRGB(32,16,18)  },
    ["Mocha Brown"]    = { Main=Color3.fromRGB(24,18,16),   Header=Color3.fromRGB(34,26,24)  },
    ["Forest Night"]   = { Main=Color3.fromRGB(14,22,18),   Header=Color3.fromRGB(20,32,26)  },
    ["Matte Graphite"] = { Main=Color3.fromRGB(20,20,20),   Header=Color3.fromRGB(28,28,28)  },
}
local BG_THEME_NAMES = {
    "Dark (Default)","Obsidian Black","Space Grey","Midnight Blue",
    "Deep Slate","Abyssal Teal","Dark Amethyst","Crimson Shadow",
    "Mocha Brown","Forest Night","Matte Graphite"
}

local FONT_LIST = {
    "Gotham","GothamMedium","GothamSemibold","GothamBold","GothamBlack",
    "Arial","ArialBold","SourceSans","SourceSansBold","RobotoMono",
    "Code","Oswald","Nunito","Ubuntu"
}
local FONT_MAP = {
    Gotham=Enum.Font.Gotham, GothamMedium=Enum.Font.GothamMedium,
    GothamSemibold=Enum.Font.GothamSemibold, GothamBold=Enum.Font.GothamBold,
    GothamBlack=Enum.Font.GothamBlack, Arial=Enum.Font.Arial,
    ArialBold=Enum.Font.ArialBold, SourceSans=Enum.Font.SourceSans,
    SourceSansBold=Enum.Font.SourceSansBold, RobotoMono=Enum.Font.RobotoMono,
    Code=Enum.Font.Code, Oswald=Enum.Font.Oswald, Nunito=Enum.Font.Nunito, Ubuntu=Enum.Font.Ubuntu,
}

local ANIM_STYLES = { "Back","Bounce","Elastic","Quint","Sine","Quad","Quart","Linear" }
local ANIM_MAP = {
    Back=Enum.EasingStyle.Back, Bounce=Enum.EasingStyle.Bounce, Elastic=Enum.EasingStyle.Elastic,
    Quint=Enum.EasingStyle.Quint, Sine=Enum.EasingStyle.Sine, Quad=Enum.EasingStyle.Quad,
    Quart=Enum.EasingStyle.Quart, Linear=Enum.EasingStyle.Linear,
}

local TOGGLE_SHAPES = { "Pill","Square","Rounded" }
local TOGGLE_RADIUS_MAP = { Pill=UDim.new(1,0), Square=UDim.new(0,0), Rounded=UDim.new(0,6) }
local BUTTON_SHAPES = { "Rounded","Square","Pill" }
local BUTTON_RADIUS_MAP = { Rounded=UDim.new(0,6), Square=UDim.new(0,0), Pill=UDim.new(1,0) }

local BG_EFFECTS = { "Nonaktif","Ambient Aura","Nano Dust","Fluid Waves","Minimalist Dots","Glass Shards" }

local VisualConfig = {
    CurrentTheme      = "Cyan",
    CurrentBg         = "Dark (Default)",
    TransparentMode   = false,
    TransparencyLevel = 0.15,
    GestureMode       = "Classic",
    GuiWidth          = 500,
    GuiHeight         = 440,
    GuiMinWidth       = 340,
    GuiMinHeight      = 300,
    CurrentFont       = "SourceSans",
    FontSize          = 8,
    AnimStyle         = "Back",
    ToggleShape       = "Pill",
    ButtonShape       = "Rounded",
    TabMode           = "Horizontal",
    BgEffect          = "Fluid Waves",
    Language          = "Indonesia",
    NotifEnabled      = true,
}

local rgbHue = 0
local function GetThemeColor(key)
    if VisualConfig.CurrentTheme == "RGB" then
        if key == "Primary" then return Color3.fromHSV(rgbHue, 0.85, 1)
        elseif key == "Secondary" then return Color3.fromHSV((rgbHue + 0.15) % 1, 0.9, 0.85)
        else return Color3.fromHSV(rgbHue, 0.7, 1) end
    end
    return GUI_THEMES[VisualConfig.CurrentTheme][key]
end

local ThemeRegistry = {
    Strokes={}, Fills={}, Texts={}, Toggles={}, Indicators={},
    AllLabels={}, ToggleTracks={}, ToggleThumbs={}, BtnCorners={},
}
local function RegisterThemeElement(cat, elem) table.insert(ThemeRegistry[cat], elem) end

local function ApplyTheme()
    local pri, sec, txt = GetThemeColor("Primary"), GetThemeColor("Secondary"), GetThemeColor("Text")
    for _, stroke in ipairs(ThemeRegistry.Strokes) do pcall(function() stroke.Color = pri end) end
    for _, fill in ipairs(ThemeRegistry.Fills) do pcall(function() fill.elem.BackgroundColor3 = fill._type == "border" and sec or pri end) end
    for _, label in ipairs(ThemeRegistry.Texts) do pcall(function() label.TextColor3 = txt end) end
    for _, tdata in ipairs(ThemeRegistry.Toggles) do pcall(function() if tdata.state then tdata.bg.BackgroundColor3 = pri end end) end
    for _, ind in ipairs(ThemeRegistry.Indicators) do pcall(function() ind.BackgroundColor3 = pri end) end
end

function ApplyFont()
    local targetSize = VisualConfig.FontSize or 8 -- Default 8
    local targetFont = Enum.Font[VisualConfig.CurrentFont] or Enum.Font.Gotham
   
    -- FIX: Menggunakan ThemeRegistry.AllLabels karena GUI_MAIN tidak ada
    for _, obj in ipairs(ThemeRegistry.AllLabels) do
        pcall(function()
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                obj.Font = targetFont
                obj.TextSize = targetSize
            end
        end)
    end
end



local function ApplyToggleShape()
    local trackRadius = TOGGLE_RADIUS_MAP[VisualConfig.ToggleShape] or UDim.new(1, 0)
    local thumbRadius = (VisualConfig.ToggleShape == "Square") and UDim.new(0, 2) or UDim.new(1, 0)
    for _, corner in ipairs(ThemeRegistry.ToggleTracks) do pcall(function() corner.CornerRadius = trackRadius end) end
    for _, corner in ipairs(ThemeRegistry.ToggleThumbs) do pcall(function() corner.CornerRadius = thumbRadius end) end
end

local function ApplyButtonShape()
    local radius = BUTTON_RADIUS_MAP[VisualConfig.ButtonShape] or UDim.new(0, 6)
    for _, corner in ipairs(ThemeRegistry.BtnCorners) do pcall(function() corner.CornerRadius = radius end) end
end

local GuiPanels = {}
local function ApplyTransparency()
    local t = VisualConfig.TransparentMode and VisualConfig.TransparencyLevel or 0
    for _, panel in ipairs(GuiPanels) do pcall(function() TweenService:Create(panel, TweenInfo.new(0.3), {BackgroundTransparency = t}):Play() end) end
end
local function RegisterPanel(frame) table.insert(GuiPanels, frame) end

local ActiveBgEffect = nil
local ParticleTask = nil
local function ClearBgEffect()
    if ActiveBgEffect then pcall(function() ActiveBgEffect:Destroy() end) end
    ActiveBgEffect = nil
    if ParticleTask then task.cancel(ParticleTask) end
    ParticleTask = nil
end

-- Tambahkan fungsi ini di [S11]
function UpdateFontSize(newSize)
    VisualConfig.FontSize = newSize -- Simpan di config agar bisa diingat
    for _, obj in ipairs(ThemeRegistry.AllLabels) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            obj.TextSize = newSize
        end
    end
end



--------------------------------------------------------------------------------
-- [S12] DRAGGABLE & RESIZE
--------------------------------------------------------------------------------
local UserInputService = Services.UserInputService
local isWindowMaximized = false

local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not isWindowMaximized then
            dragging = true; dragStart = input.Position; startPos = target.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function MakeResizable(handle, target)
    local resizing, resizeStart, startSize
    handle.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not isWindowMaximized then
            resizing = true; resizeStart = input.Position; startSize = target.AbsoluteSize
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            local newW = math.max(VisualConfig.GuiMinWidth,  startSize.X + delta.X)
            local newH = math.max(VisualConfig.GuiMinHeight, startSize.Y + delta.Y)
            VisualConfig.GuiWidth = newW; VisualConfig.GuiHeight = newH
            target.Size = UDim2.new(0, newW, 0, newH)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then resizing = false end
    end)
end


--------------------------------------------------------------------------------
-- [S13] UI COMPONENT BUILDER
--------------------------------------------------------------------------------
RuntimeMaid:DoCleaning()

local function GetSafeParent()
    local ok, r = pcall(function() return gethui and gethui() end)
    if ok and r then return r end
    local ok2, r2 = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and r2 then return r2 end
    return LocalPlayer:WaitForChild("PlayerGui", 10)
end
local SafeParent = GetSafeParent()

local GuiRoot = Instance.new("ScreenGui", SafeParent)
GuiRoot.Name="XiFilHub_Modern"; GuiRoot.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
GuiRoot.ResetOnSpawn=false; GuiRoot.DisplayOrder=999990
GuiRoot.IgnoreGuiInset = true
RuntimeMaid:GiveTask(GuiRoot)

-- SECTION HEADER
local function CreateSection(parent, titleText, langKey)
    local sec = Instance.new("Frame", parent)
    sec.BackgroundTransparency = 1; sec.Size = UDim2.new(1, 0, 0, 28)
    local line = Instance.new("Frame", sec)
    line.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    line.Size = UDim2.new(1, 0, 0, 1); line.Position = UDim2.new(0, 0, 0.5, 0)
    line.AnchorPoint = Vector2.new(0, 0.5); line.BorderSizePixel = 0
    local lbl = Instance.new("TextLabel", sec)
    lbl.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    lbl.Size = UDim2.new(0, 0, 1, 0); lbl.AutomaticSize = Enum.AutomaticSize.X
    lbl.Position = UDim2.new(0, 8, 0, 0); lbl.BorderSizePixel = 0
    Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 6)
    lbl.Font = Enum.Font.GothamBold
    lbl.Text = "  " .. string.upper(titleText) .. "  "
    lbl.TextColor3 = GetThemeColor("Text"); lbl.TextSize = 10
    RegisterThemeElement("Texts", lbl)
    table.insert(ThemeRegistry.AllLabels, lbl)
    if langKey then
        RegisterTranslationFn(langKey, function(str)
            pcall(function() lbl.Text = "  " .. string.upper(str) .. "  " end)
        end)
    end
    return sec
end

-- TOGGLE
local function CreateToggleUI(parent, text, default, callback, langKey)
    local container = Instance.new("Frame", parent)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    container.BackgroundTransparency = 0.2
    container.Size = UDim2.new(1, 0, 0, 42); container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)

    local lbl = Instance.new("TextLabel", container)
    lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.Size = UDim2.new(0.75, 0, 1, 0); lbl.Font = Enum.Font.GothamMedium
    lbl.Text = text; lbl.TextColor3 = Color3.fromRGB(205, 205, 218)
    lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(ThemeRegistry.AllLabels, lbl)
    if langKey then RegisterTranslation(langKey, lbl, "Text") end

    local track = Instance.new("TextButton", container)
    track.BackgroundColor3 = default and GetThemeColor("Primary") or Color3.fromRGB(38, 38, 55)
    track.Position = UDim2.new(1, -52, 0.5, -12)
    track.Size = UDim2.new(0, 40, 0, 24); track.Text = ""
    track.AutoButtonColor = false; track.BorderSizePixel = 0
    local trackCorner = Instance.new("UICorner", track)
    trackCorner.CornerRadius = TOGGLE_RADIUS_MAP[VisualConfig.ToggleShape] or UDim.new(1, 0)
    table.insert(ThemeRegistry.ToggleTracks, trackCorner)

    local thumb = Instance.new("Frame", track)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.Size = UDim2.new(0, 20, 0, 20)
    thumb.Position = default and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    thumb.BorderSizePixel = 0
    local thumbCorner = Instance.new("UICorner", thumb)
    thumbCorner.CornerRadius = (VisualConfig.ToggleShape == "Square") and UDim.new(0, 2) or UDim.new(1, 0)
    table.insert(ThemeRegistry.ToggleThumbs, thumbCorner)

    local state = default
    local tdata = { bg = track, circle = thumb, state = state }
    RegisterThemeElement("Toggles", tdata)

    local api = {}
    function api:SetValue(val)
        state = val; tdata.state = val
        local pri = GetThemeColor("Primary")
        local ti = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        if val then
            TweenService:Create(track, ti, { BackgroundColor3 = pri }):Play()
            TweenService:Create(thumb, ti, { Position = UDim2.new(1, -22, 0.5, -10) }):Play()
        else
            TweenService:Create(track, ti, { BackgroundColor3 = Color3.fromRGB(38, 38, 55) }):Play()
            TweenService:Create(thumb, ti, { Position = UDim2.new(0, 2, 0.5, -10) }):Play()
        end
        pcall(callback, val)
    end
    track.MouseButton1Click:Connect(function() api:SetValue(not state) end)
    return api
end

-- DROPDOWN (animated, premium vertical)
-- DROPDOWN (FIXED VISUAL: ANTI TERTUMPUK & ANTI TERPOTONG)
local function CreateDropdownUI(parent, labelText, list, default, callback, langKey)
    local container = Instance.new("Frame", parent)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    container.BackgroundTransparency = 0.2
    container.Size = UDim2.new(1, 0, 0, 42)
    container.ClipsDescendants = false
    container.ZIndex = 10; container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

    -- [FIX 1] Spacer ajaib agar list dropdown memberi ruang pada tab scroll di bawahnya
    local spacer = Instance.new("Frame", parent)
    spacer.BackgroundTransparency = 1
    spacer.Size = UDim2.new(1, 0, 0, 0)
    spacer.Visible = false
    spacer.BorderSizePixel = 0

    local lbl = Instance.new("TextLabel", container)
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.Size = UDim2.new(0.48, 0, 1, 0)
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = labelText; lbl.TextColor3 = Color3.fromRGB(205, 205, 218)
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 11
    table.insert(ThemeRegistry.AllLabels, lbl)
    if langKey then RegisterTranslation(langKey, lbl, "Text") end

    local mainBtn = Instance.new("TextButton", container)
    mainBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 40)
    mainBtn.Position = UDim2.new(1, -135, 0.5, -14)
    mainBtn.Size = UDim2.new(0, 123, 0, 28)
    mainBtn.Font = Enum.Font.GothamSemibold
    mainBtn.Text = tostring(default) .. ""
    mainBtn.TextColor3 = GetThemeColor("Text")
    mainBtn.TextSize = 11
    mainBtn.AutoButtonColor = false; mainBtn.ZIndex = 12
    mainBtn.BorderSizePixel = 0
    local btnCorner = Instance.new("UICorner", mainBtn)
    btnCorner.CornerRadius = BUTTON_RADIUS_MAP[VisualConfig.ButtonShape] or UDim.new(0, 6)
    table.insert(ThemeRegistry.BtnCorners, btnCorner)
    table.insert(ThemeRegistry.AllLabels, mainBtn)
    local mbStroke = Instance.new("UIStroke", mainBtn)
    mbStroke.Color = GetThemeColor("Primary")
    mbStroke.Thickness = 1; mbStroke.Transparency = 0.5
    RegisterThemeElement("Strokes", mbStroke)
    RegisterThemeElement("Texts", mainBtn)

        local targetH = math.min(#list * 30, 150)
    local panelClip = Instance.new("Frame", mainBtn)
    panelClip.BackgroundTransparency = 1
    panelClip.Position = UDim2.new(0, 0, 1, 6)
    panelClip.Size = UDim2.new(1, 0, 0, 0)
    panelClip.ClipsDescendants = true
    panelClip.Visible = false
    panelClip.ZIndex = 9999; panelClip.BorderSizePixel = 0

    local panel = Instance.new("ScrollingFrame", panelClip)
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 32)
    -- [FIX UTAMA]: Beri jarak 1px ke dalam agar UIStroke tidak digunting oleh ClipsDescendants
    panel.Position = UDim2.new(0, 1, 0, 1)
    panel.Size = UDim2.new(1, -2, 1, -2) 
    panel.ZIndex = 10000
    panel.ScrollBarThickness = 3
    panel.ScrollBarImageColor3 = GetThemeColor("Primary")
    panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    Instance.new("UIListLayout", panel).SortOrder = Enum.SortOrder.LayoutOrder

    local panelPad = Instance.new("UIPadding", panel)
    panelPad.PaddingLeft = UDim.new(0, 2)
    panelPad.PaddingRight = UDim.new(0, 2)
    panelPad.PaddingTop = UDim.new(0, 2)
    panelPad.PaddingBottom = UDim.new(0, 2)

    local panelStroke = Instance.new("UIStroke", panel)
    panelStroke.Color = GetThemeColor("Primary")
    panelStroke.Thickness = 1; panelStroke.Transparency = 0.65
    RegisterThemeElement("Strokes", panelStroke)

    local isOpen = false
    local animating = false

    local api = { CurrentList = list, SelectedValue = default }

    local function refreshItems()
        for _, c in ipairs(panel:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        targetH = math.min(#api.CurrentList * 30, 150)
        for _, valName in ipairs(api.CurrentList) do
            local ib = Instance.new("TextButton", panel)
            ib.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
            ib.Size = UDim2.new(1, 0, 0, 30)
            ib.Font = Enum.Font.GothamMedium
            ib.Text = "  " .. tostring(valName)
            ib.TextColor3 = Color3.fromRGB(210, 210, 228)
            ib.TextSize = 11
            ib.TextXAlignment = Enum.TextXAlignment.Left
            ib.ZIndex = 10001
            ib.BorderSizePixel = 0
            Instance.new("UICorner", ib).CornerRadius = UDim.new(0, 6)
      
            table.insert(ThemeRegistry.AllLabels, ib)
            ib.MouseEnter:Connect(function()
                TweenService:Create(ib, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(32, 32, 52), TextColor3 = GetThemeColor("Text") }):Play()
            end)
            ib.MouseLeave:Connect(function()
                TweenService:Create(ib, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(22, 22, 35), TextColor3 = Color3.fromRGB(210, 210, 228) }):Play()
            end)
            ib.MouseButton1Click:Connect(function()
                mainBtn.Text = tostring(valName) .. ""
                -- Tutup Dropdown dan kempeskan Spacer bersamaan
                TweenService:Create(panelClip, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.new(1, 0, 0, 0) }):Play()
                TweenService:Create(spacer, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.new(1, 0, 0, 0) }):Play()
                task.wait(0.2)
                panelClip.Visible = false; spacer.Visible = false
                container.ZIndex = 10; isOpen = false; animating = false
                api.SelectedValue = valName
                pcall(callback, valName)
            end)
        end
    end

    mainBtn.MouseButton1Click:Connect(function()
        if animating then return end
        isOpen = not isOpen
        animating = true
        if isOpen then
            panelClip.Visible = true; spacer.Visible = true
            container.ZIndex = 9998
            -- Buka Dropdown dan lebarkan Spacer
            TweenService:Create(panelClip, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, targetH) }):Play()
            TweenService:Create(spacer, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, targetH + 6) }):Play()
            task.wait(0.28)
            animating = false
        else
            TweenService:Create(panelClip, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.new(1, 0, 0, 0) }):Play()
            TweenService:Create(spacer, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.new(1, 0, 0, 0) }):Play()
            task.wait(0.25)
            panelClip.Visible = false; spacer.Visible = false
            container.ZIndex = 10; animating = false
        end
    end)

    function api:SetValues(nl)
        api.CurrentList = nl
        api.SelectedValue = nl[1] or "None"
        mainBtn.Text = tostring(api.SelectedValue) .. ""
        refreshItems()
    end

    function api:SetValue(tv)
        -- Cari apakah nilai ada di list; fallback tetap set teks
        local found = false
        for _, v in ipairs(api.CurrentList) do
            if tostring(v) == tostring(tv) then found = true; break end
        end
        api.SelectedValue = tv
        mainBtn.Text = tostring(tv)
        -- Langsung reset state tanpa tween/wait agar save-load 100% sinkron:
        -- task.wait() di sini menyebabkan callback fires terlambat & race condition.
        panelClip.Size    = UDim2.new(1, 0, 0, 0)
        panelClip.Visible = false
        spacer.Size       = UDim2.new(1, 0, 0, 0)
        spacer.Visible    = false
        container.ZIndex  = 10
        isOpen    = false
        animating = false
        if found then pcall(callback, tv) end
    end

    refreshItems()
    return api
end


-- CYCLE BUTTON
local function CreateCycleUI(parent, text, list, default, callback)
    local container = Instance.new("Frame", parent)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    container.BackgroundTransparency = 0.2
    container.Size = UDim2.new(1, 0, 0, 42); container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
    local lbl = Instance.new("TextLabel", container)
    lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.Size = UDim2.new(0.45, 0, 1, 0); lbl.Font = Enum.Font.GothamMedium; lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 210, 210); lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(ThemeRegistry.AllLabels, lbl)
    local btn = Instance.new("TextButton", container)
    btn.BackgroundColor3 = Color3.fromRGB(26, 26, 40)
    btn.Position = UDim2.new(1, -135, 0.5, -14); btn.Size = UDim2.new(0, 123, 0, 28)
    btn.Font = Enum.Font.GothamSemibold; btn.Text = tostring(default)
    btn.TextColor3 = GetThemeColor("Text"); btn.TextSize = 11; btn.BorderSizePixel = 0
    local btnC = Instance.new("UICorner", btn)
    btnC.CornerRadius = BUTTON_RADIUS_MAP[VisualConfig.ButtonShape] or UDim.new(0, 6)
    table.insert(ThemeRegistry.BtnCorners, btnC)
    table.insert(ThemeRegistry.AllLabels, btn)
    RegisterThemeElement("Texts", btn)
    local bs = Instance.new("UIStroke", btn)
    bs.Color = GetThemeColor("Primary"); bs.Thickness = 1; bs.Transparency = 0.5
    RegisterThemeElement("Strokes", bs)
    local idx = 1; for i, v in ipairs(list) do if v == default then idx = i; break end end
    local api = { CurrentList = list }
    btn.MouseButton1Click:Connect(function()
        idx = idx % #api.CurrentList + 1; local val = api.CurrentList[idx]; btn.Text = tostring(val); callback(val)
    end)
    function api:SetValues(nl) api.CurrentList = nl; idx = 1; btn.Text = tostring(nl[1] or "None") end
    function api:SetValue(tv)
        for i, v in ipairs(api.CurrentList) do
            if tostring(v) == tostring(tv) then idx = i; btn.Text = tostring(v); callback(v); break end
        end
    end
    return api
end

-- INPUT BOX
local function CreateInputUI(parent, text, default, numeric, callback)
    local container = Instance.new("Frame", parent)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    container.BackgroundTransparency = 0.2
    container.Size = UDim2.new(1, 0, 0, 42); container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
    local lbl = Instance.new("TextLabel", container)
    lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.Size = UDim2.new(0.55, 0, 1, 0); lbl.Font = Enum.Font.GothamMedium; lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(210, 210, 210); lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(ThemeRegistry.AllLabels, lbl)
    local boxBG = Instance.new("Frame", container)
    boxBG.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
    boxBG.Position = UDim2.new(1, -135, 0.5, -14); boxBG.Size = UDim2.new(0, 123, 0, 28)
    Instance.new("UICorner", boxBG).CornerRadius = UDim.new(0, 6)
    local boxStroke = Instance.new("UIStroke", boxBG)
    boxStroke.Color = Color3.fromRGB(50, 50, 60); boxStroke.Thickness = 1
    local box = Instance.new("TextBox", boxBG)
    box.BackgroundTransparency = 1; box.Size = UDim2.new(1, 0, 1, 0)
    box.Font = Enum.Font.GothamMedium; box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(255, 255, 255); box.TextSize = 11
    box.Focused:Connect(function() boxStroke.Color = GetThemeColor("Primary") end)
    box.FocusLost:Connect(function()
        boxStroke.Color = Color3.fromRGB(50, 50, 60)
        local val = box.Text
        if numeric then val = tonumber(val) or default; box.Text = tostring(val) end
        -- Defensive: pastikan callback adalah fungsi agar salah-urutan argumen
        -- tidak crash seluruh SyncAllVisualUI (yang dibungkus satu pcall besar).
        if type(callback) == "function" then pcall(callback, val) end
    end)
    local api = {}
    function api:SetValue(val)
        -- Hanya update teks — tidak fire callback agar sync/load tidak
        -- re-trigger side-effect saat SyncAllVisualUI berjalan.
        box.Text = tostring(val)
    end
    return api
end

-- BUTTON
local function CreateButton(parent, text, callback, langKey)
    local btn = Instance.new("TextButton", parent)
    btn.BackgroundColor3 = Color3.fromRGB(22, 22, 35)
    btn.Size = UDim2.new(1, 0, 0, 36); btn.Font = Enum.Font.GothamSemibold; btn.Text = text
    btn.TextColor3 = Color3.fromRGB(220, 220, 220); btn.TextSize = 12; btn.BorderSizePixel = 0
    local bc = Instance.new("UICorner", btn)
    bc.CornerRadius = BUTTON_RADIUS_MAP[VisualConfig.ButtonShape] or UDim.new(0, 6)
    table.insert(ThemeRegistry.BtnCorners, bc)
    table.insert(ThemeRegistry.AllLabels, btn)
    local bs = Instance.new("UIStroke", btn)
    bs.Color = GetThemeColor("Primary"); bs.Thickness = 1; bs.Transparency = 0.6
    RegisterThemeElement("Strokes", bs)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(32, 32, 50) }):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.2), { BackgroundColor3 = Color3.fromRGB(22, 22, 35) }):Play() end)
    if langKey then RegisterTranslation(langKey, btn, "Text") end
    btn.MouseButton1Click:Connect(callback); return btn
end

-- SCROLLABLE MULTI-SELECT DROPDOWN
-- Menggantikan CreateMultiCheckUI: tampilan dropdown scrollable yang bisa
-- scroll jika itemnya banyak, dengan baris ✅/⬜ per item.
-- API kompatibel: mengembalikan array apis[i] dengan :SetValue(val) — silent
-- (tidak fire callback), callback hanya dari klik user.
local function CreateScrollableMultiSelectUI(parent, labelText, items, states, callbacks)
    local panelH = math.min(#items * 34 + 4, 200)

    local container = Instance.new("Frame", parent)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    container.BackgroundTransparency = 0.2
    container.Size = UDim2.new(1, 0, 0, 42)
    container.ClipsDescendants = false
    container.ZIndex = 10; container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

    local spacer = Instance.new("Frame", parent)
    spacer.BackgroundTransparency = 1
    spacer.Size = UDim2.new(1, 0, 0, 0)
    spacer.Visible = false; spacer.BorderSizePixel = 0

    local lbl = Instance.new("TextLabel", container)
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.Size = UDim2.new(0.48, 0, 1, 0)
    lbl.Font = Enum.Font.GothamMedium; lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(205, 205, 218)
    lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 11
    table.insert(ThemeRegistry.AllLabels, lbl)

    local mainBtn = Instance.new("TextButton", container)
    mainBtn.BackgroundColor3 = Color3.fromRGB(26, 26, 40)
    mainBtn.Position = UDim2.new(1, -135, 0.5, -14)
    mainBtn.Size = UDim2.new(0, 123, 0, 28)
    mainBtn.Font = Enum.Font.GothamSemibold
    mainBtn.TextColor3 = GetThemeColor("Text")
    mainBtn.TextSize = 10; mainBtn.AutoButtonColor = false; mainBtn.ZIndex = 12; mainBtn.BorderSizePixel = 0
    local mbc = Instance.new("UICorner", mainBtn)
    mbc.CornerRadius = BUTTON_RADIUS_MAP[VisualConfig.ButtonShape] or UDim.new(0, 6)
    table.insert(ThemeRegistry.BtnCorners, mbc)
    table.insert(ThemeRegistry.AllLabels, mainBtn)
    local mbStroke = Instance.new("UIStroke", mainBtn)
    mbStroke.Color = GetThemeColor("Primary"); mbStroke.Thickness = 1; mbStroke.Transparency = 0.5
    RegisterThemeElement("Strokes", mbStroke); RegisterThemeElement("Texts", mainBtn)

    local panelClip = Instance.new("Frame", mainBtn)
    panelClip.BackgroundTransparency = 1
    panelClip.Position = UDim2.new(0, 0, 1, 6)
    panelClip.Size = UDim2.new(1, 0, 0, 0)
    panelClip.ClipsDescendants = true
    panelClip.Visible = false; panelClip.ZIndex = 9999; panelClip.BorderSizePixel = 0

    local panel = Instance.new("ScrollingFrame", panelClip)
    panel.BackgroundColor3 = Color3.fromRGB(18, 18, 32)
    panel.Position = UDim2.new(0, 1, 0, 1)
    panel.Size = UDim2.new(1, -2, 1, -2)
    panel.ZIndex = 10000; panel.ScrollBarThickness = 3
    panel.ScrollBarImageColor3 = GetThemeColor("Primary")
    panel.AutomaticCanvasSize = Enum.AutomaticSize.Y
    panel.BorderSizePixel = 0
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    local panelLayout = Instance.new("UIListLayout", panel)
    panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local panelPad = Instance.new("UIPadding", panel)
    panelPad.PaddingLeft = UDim.new(0, 2); panelPad.PaddingRight = UDim.new(0, 2)
    panelPad.PaddingTop = UDim.new(0, 2); panelPad.PaddingBottom = UDim.new(0, 2)
    local panelStroke = Instance.new("UIStroke", panel)
    panelStroke.Color = GetThemeColor("Primary"); panelStroke.Thickness = 1; panelStroke.Transparency = 0.65
    RegisterThemeElement("Strokes", panelStroke)

    local currentStates = {}
    for i, s in ipairs(states) do currentStates[i] = s end

    local function countSelected()
        local n = 0
        for _, v in ipairs(currentStates) do if v then n = n + 1 end end
        return n
    end
    local function updateSummary()
        local n = countSelected()
        if n == 0 then mainBtn.Text = "Pilih..."
        elseif n == #items then mainBtn.Text = "Semua ✓"
        else mainBtn.Text = n .. " dipilih ✓" end
    end
    updateSummary()

    local isOpen = false; local animating = false
    local apis = {}

    for i, item in ipairs(items) do
        local rowBtn = Instance.new("TextButton", panel)
        rowBtn.BackgroundColor3 = currentStates[i] and Color3.fromRGB(28, 48, 32) or Color3.fromRGB(22, 22, 35)
        rowBtn.Size = UDim2.new(1, 0, 0, 32)
        rowBtn.Font = Enum.Font.GothamMedium
        rowBtn.Text = "  " .. (currentStates[i] and "✅ " or "⬜ ") .. item
        rowBtn.TextColor3 = Color3.fromRGB(210, 210, 228)
        rowBtn.TextSize = 11; rowBtn.TextXAlignment = Enum.TextXAlignment.Left
        rowBtn.ZIndex = 10001; rowBtn.BorderSizePixel = 0
        Instance.new("UICorner", rowBtn).CornerRadius = UDim.new(0, 6)
        table.insert(ThemeRegistry.AllLabels, rowBtn)

        local api = { state = currentStates[i] }
        local function applyRowVisual(val)
            api.state = val; currentStates[i] = val
            rowBtn.BackgroundColor3 = val and Color3.fromRGB(28, 48, 32) or Color3.fromRGB(22, 22, 35)
            rowBtn.Text = "  " .. (val and "✅ " or "⬜ ") .. item
            updateSummary()
        end
        function api:SetValue(val)
            applyRowVisual(val)
            -- Silent: data sudah benar di EngineConfig dari load; tidak fire callback
        end
        rowBtn.MouseButton1Click:Connect(function()
            applyRowVisual(not api.state)
            pcall(callbacks[i], api.state)
        end)
        rowBtn.MouseEnter:Connect(function()
            if not api.state then
                TweenService:Create(rowBtn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(30, 30, 48) }):Play()
            end
        end)
        rowBtn.MouseLeave:Connect(function()
            TweenService:Create(rowBtn, TweenInfo.new(0.12), {
                BackgroundColor3 = api.state and Color3.fromRGB(28, 48, 32) or Color3.fromRGB(22, 22, 35)
            }):Play()
        end)
        apis[i] = api
    end

    mainBtn.MouseButton1Click:Connect(function()
        if animating then return end
        isOpen = not isOpen; animating = true
        if isOpen then
            panelClip.Visible = true; spacer.Visible = true; container.ZIndex = 9998
            TweenService:Create(panelClip, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, panelH) }):Play()
            TweenService:Create(spacer,    TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 0, panelH + 6) }):Play()
            task.wait(0.28); animating = false
        else
            TweenService:Create(panelClip, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.new(1, 0, 0, 0) }):Play()
            TweenService:Create(spacer,    TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = UDim2.new(1, 0, 0, 0) }):Play()
            task.wait(0.25)
            panelClip.Visible = false; spacer.Visible = false; container.ZIndex = 10; animating = false
        end
    end)

    return apis
end

-- MULTI CHECK (pill row) — dipertahankan untuk backward-compat internal
local function CreateMultiCheckUI(parent, labelText, items, states, callbacks)
    local wrapper = Instance.new("Frame", parent)
    wrapper.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    wrapper.BackgroundTransparency = 0.2
    wrapper.BorderSizePixel = 0; wrapper.Size = UDim2.new(1, 0, 0, 64)
    Instance.new("UICorner", wrapper).CornerRadius = UDim.new(0, 10)
    local lbl = Instance.new("TextLabel", wrapper)
    lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0, 14, 0, 4); lbl.Size = UDim2.new(1, -16, 0, 18)
    lbl.Font = Enum.Font.GothamMedium; lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(150, 150, 165); lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(ThemeRegistry.AllLabels, lbl)
    local row = Instance.new("Frame", wrapper)
    row.BackgroundTransparency = 1; row.Position = UDim2.new(0, 10, 0, 26); row.Size = UDim2.new(1, -20, 0, 30)
    local layout = Instance.new("UIListLayout", row)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 6)
    local apis = {}
    for i, item in ipairs(items) do
        local active = states[i]
        local btn = Instance.new("TextButton", row)
        btn.Size = UDim2.new(0, 80, 0, 26)
        btn.BackgroundColor3 = active and GetThemeColor("Primary") or Color3.fromRGB(35, 35, 50)
        btn.TextColor3 = active and Color3.fromRGB(10, 10, 15) or Color3.fromRGB(200, 200, 200)
        btn.Text = item; btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 11; btn.AutoButtonColor = false; btn.BorderSizePixel = 0
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        local api = { state = active }
        local function applyVisual(val)
            -- Hanya update warna pill — tidak fire callback.
            -- Callback hanya terpanggil lewat klik user agar sync/load
            -- tidak double-write ke EngineConfig (data sudah benar dari load).
            api.state = val
            btn.BackgroundColor3 = val and GetThemeColor("Primary") or Color3.fromRGB(35, 35, 50)
            btn.TextColor3 = val and Color3.fromRGB(10, 10, 15) or Color3.fromRGB(200, 200, 200)
        end
        function api:SetValue(val)
            applyVisual(val)
            -- Tidak fire callbacks[i] di sini: dipanggil dari SyncAllVisualUI
            -- di mana EngineConfig sudah berisi nilai yang benar dari load.
        end
        btn.MouseButton1Click:Connect(function()
            local newVal = not api.state
            applyVisual(newVal)
            callbacks[i](newVal)   -- hanya user-click yang trigger callback
        end)
        apis[i] = api
    end
    return apis
end

-- SLIDER
local function CreateSliderUI(parent, labelText, min, max, default, callback, langKey)
    local container = Instance.new("Frame", parent)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    container.BackgroundTransparency = 0.2
    container.Size = UDim2.new(1, 0, 0, 58); container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 10)
    local header = Instance.new("TextLabel", container)
    header.BackgroundTransparency = 1; header.Position = UDim2.new(0, 14, 0, 6)
    header.Size = UDim2.new(0.68, 0, 0, 20); header.Font = Enum.Font.GothamMedium
    header.Text = labelText; header.TextColor3 = Color3.fromRGB(205, 205, 218)
    header.TextSize = 12; header.TextXAlignment = Enum.TextXAlignment.Left
    table.insert(ThemeRegistry.AllLabels, header)
    if langKey then RegisterTranslation(langKey, header, "Text") end
    local valLabel = Instance.new("TextLabel", container)
    valLabel.BackgroundTransparency = 1; valLabel.Position = UDim2.new(0.68, 0, 0, 6)
    valLabel.Size = UDim2.new(0.3, -10, 0, 20); valLabel.Font = Enum.Font.GothamBold
    valLabel.Text = tostring(default); valLabel.TextColor3 = GetThemeColor("Text")
    valLabel.TextSize = 12; valLabel.TextXAlignment = Enum.TextXAlignment.Right
    RegisterThemeElement("Texts", valLabel); table.insert(ThemeRegistry.AllLabels, valLabel)
    local track = Instance.new("Frame", container)
    track.BackgroundColor3 = Color3.fromRGB(35, 35, 52)
    track.Position = UDim2.new(0, 14, 0, 36); track.Size = UDim2.new(1, -28, 0, 6); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = GetThemeColor("Primary")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0); fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    RegisterThemeElement("Fills", { elem = fill, _type = "primary" })
    local thumb = Instance.new("TextButton", track)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.Size = UDim2.new(0, 18, 0, 18)
    thumb.Position = UDim2.new((default - min) / (max - min), -9, 0.5, -9)
    thumb.Text = ""; thumb.AutoButtonColor = false; thumb.BorderSizePixel = 0; thumb.ZIndex = 2
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
    local dragging = false
    local function updateVisual(value)
        -- Update tampilan track/thumb/label tanpa fire callback (untuk sync)
        local alpha = math.clamp((value - min) / (max - min), 0, 1)
        fill.Size      = UDim2.new(alpha, 0, 1, 0)
        thumb.Position = UDim2.new(alpha, -9, 0.5, -9)
        valLabel.Text  = tostring(value)
    end
    local function update(absPos)
        local alpha = math.clamp((absPos.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local value = math.floor(min + alpha * (max - min))
        updateVisual(value); pcall(callback, value)
    end
    thumb.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then update(inp.Position) end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then update(inp.Position) end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    -- API untuk programmatic sync (tidak fire callback, hanya update visual)
    local api = {}
    function api:SetValue(value)
        updateVisual(math.floor(math.clamp(value, min, max)))
    end
    return api
end


--------------------------------------------------------------------------------
-- [S14] MAIN WINDOW & WINDOW CONTROLS
--------------------------------------------------------------------------------
local camera = game:GetService("Workspace").CurrentCamera
local screenSize = camera.ViewportSize

-- Menghitung ukuran dinamis (misal: 40% lebar layar, 50% tinggi layar)
-- Dibatasi dengan math.clamp agar tidak lebih kecil dari batas minimum
local dynamicWidth = math.clamp(screenSize.X * 0.4, VisualConfig.GuiMinWidth, 800)
local dynamicHeight = math.clamp(screenSize.Y * 0.5, VisualConfig.GuiMinHeight, 600)

VisualConfig.GuiWidth = dynamicWidth
VisualConfig.GuiHeight = dynamicHeight

local MainWindow = Instance.new("Frame", GuiRoot)
MainWindow.BackgroundColor3 = Color3.fromRGB(13, 13, 20)
MainWindow.Position = UDim2.new(0.5, -dynamicWidth/2, 0.5, -dynamicHeight/2)
MainWindow.Size = UDim2.new(0, dynamicWidth, 0, dynamicHeight)
MainWindow.Visible = false;
MainWindow.BorderSizePixel = 0; MainWindow.ZIndex = 2
MainWindow.ClipsDescendants = true
Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 12)
RegisterPanel(MainWindow)

local TopBar = Instance.new("Frame", MainWindow)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
TopBar.Size = UDim2.new(1, 0, 0, 46);
TopBar.BorderSizePixel = 0; TopBar.ZIndex = 3
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 12)
RegisterPanel(TopBar)

local TBFix = Instance.new("Frame", TopBar)
TBFix.BackgroundColor3 = Color3.fromRGB(18, 18, 30);
TBFix.BorderSizePixel = 0
TBFix.Size = UDim2.new(1, 0, 0, 12); TBFix.Position = UDim2.new(0, 0, 1, -12);
TBFix.ZIndex = 3

local TopAccent = Instance.new("Frame", TopBar)
TopAccent.BackgroundColor3 = GetThemeColor("Primary")
TopAccent.Size = UDim2.new(1, 0, 0, 1);
TopAccent.Position = UDim2.new(0, 0, 1, -1)
TopAccent.BorderSizePixel = 0; TopAccent.BackgroundTransparency = 0.6;
TopAccent.ZIndex = 4
RegisterThemeElement("Fills", { elem = TopAccent, _type = "primary" })
MakeDraggable(TopBar, MainWindow)

local Title = Instance.new("TextLabel", TopBar)
Title.BackgroundTransparency = 1;
Title.Position = UDim2.new(0, 16, 0, 0)
Title.Size = UDim2.new(0.55, 0, 1, 0);
Title.Font = Enum.Font.GothamBlack
Title.RichText = true
Title.Text = 'XIFIL <font color="#ffffff">HUB</font> <font size="10" color="#606080">// IRON SOUL V5</font>'
Title.TextColor3 = GetThemeColor("Text");
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left; Title.ZIndex = 4
RegisterThemeElement("Texts", Title); table.insert(ThemeRegistry.AllLabels, Title)

-- Window Control Buttons (Minimize / Maximize / Close)
local WindowControls = Instance.new("Frame", TopBar)
WindowControls.BackgroundTransparency = 1
WindowControls.Position = UDim2.new(1, -120, 0, 0)
WindowControls.Size = UDim2.new(0, 120, 1, 0);
WindowControls.ZIndex = 5

local function CreateWinButton(parent, text, xPos)
    local btn = Instance.new("TextButton", parent)
    btn.BackgroundTransparency = 1
    btn.Position = UDim2.new(0, xPos, 0, 0);
    btn.Size = UDim2.new(0, 40, 1, 0)
    btn.Font = Enum.Font.GothamMedium;
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200);
    btn.TextSize = 14
    btn.AutoButtonColor = false
    local highlight = Instance.new("Frame", btn)
    highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    highlight.BackgroundTransparency = 1;
    highlight.Size = UDim2.new(1, 0, 1, 0); highlight.BorderSizePixel = 0
    Instance.new("UICorner", highlight).CornerRadius = UDim.new(0, 8)
    btn.MouseEnter:Connect(function()
        TweenService:Create(highlight, TweenInfo.new(0.2), { BackgroundTransparency = text == "X" and 0.2 or 0.8 }):Play()
        if text == "X" then highlight.BackgroundColor3 = Color3.fromRGB(255, 60, 60); btn.TextColor3 = Color3.fromRGB(255, 255, 255) end
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(highlight, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        if text == "X" then highlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255); btn.TextColor3 = Color3.fromRGB(200, 200, 200) end
    end)
    return btn
end
local BtnMin   = CreateWinButton(WindowControls, "_", 0)
local BtnMax   = CreateWinButton(WindowControls, "[ ]", 40)
local BtnClose = CreateWinButton(WindowControls, "X", 80)

-- Resize handle
local ResizeHandle = Instance.new("TextButton", MainWindow)
ResizeHandle.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
ResizeHandle.Size = UDim2.new(0, 20, 0, 20)
ResizeHandle.Position = UDim2.new(1, -20, 1, -20)
ResizeHandle.Text = "";
ResizeHandle.AutoButtonColor = false; ResizeHandle.ZIndex = 10; ResizeHandle.BorderSizePixel = 0
Instance.new("UICorner", ResizeHandle).CornerRadius = UDim.new(0, 5)
MakeResizable(ResizeHandle, MainWindow)
-- 3 titik diagonal sebagai indikator resize
for i = 0, 2 do
    local dot = Instance.new("Frame", ResizeHandle)
    dot.BackgroundColor3 = Color3.fromRGB(170, 170, 210)
    dot.BorderSizePixel = 0;
    dot.ZIndex = 11
    dot.Size = UDim2.new(0, 2, 0, 2)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.new(0, 6 + i*5, 0, 6 + i*5)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
end

local isMinimized = false
local normalPos = UDim2.new()
local normalSize = UDim2.new()



--------------------------------------------------------------------------------
-- [S15] TAB SYSTEM
--------------------------------------------------------------------------------
local TabBar = Instance.new("ScrollingFrame", MainWindow)
TabBar.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
TabBar.Position = UDim2.new(0, 10, 0, 54)
TabBar.Size = UDim2.new(1, -20, 0, 36); TabBar.BorderSizePixel = 0; TabBar.ZIndex = 3
TabBar.ScrollingDirection = Enum.ScrollingDirection.X
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.ScrollBarThickness = 0
Instance.new("UICorner", TabBar).CornerRadius = UDim.new(0, 8)
RegisterPanel(TabBar)
local TabLayout = Instance.new("UIListLayout", TabBar)
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Padding = UDim.new(0, 2)
local TabPad = Instance.new("UIPadding", TabBar); TabPad.PaddingLeft = UDim.new(0, 4)

local SideBar = Instance.new("ScrollingFrame", MainWindow)
SideBar.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
SideBar.Position = UDim2.new(0, 0, 0, 46)
SideBar.Size = UDim2.new(0, 90, 1, -46)
SideBar.BorderSizePixel = 0; SideBar.ZIndex = 3; SideBar.Visible = false

-- Konfigurasi khusus agar bisa di-scroll secara vertikal
SideBar.ScrollingDirection = Enum.ScrollingDirection.Y
SideBar.ScrollBarThickness = 2 -- Dibuat sangat tipis agar rapi di sidebar 90px
SideBar.CanvasSize = UDim2.new(0, 0, 0, 0)
SideBar.AutomaticCanvasSize = Enum.AutomaticSize.Y
SideBar.ScrollBarImageColor3 = GetThemeColor("Primary") -- Warna scrollbar menyesuaikan tema

Instance.new("UICorner", SideBar).CornerRadius = UDim.new(0, 0)
RegisterPanel(SideBar)

local SideLayout = Instance.new("UIListLayout", SideBar)
SideLayout.FillDirection = Enum.FillDirection.Vertical
SideLayout.SortOrder = Enum.SortOrder.LayoutOrder
SideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
SideLayout.Padding = UDim.new(0, 3)
Instance.new("UIPadding", SideBar).PaddingTop = UDim.new(0, 6)


local ContentFrame = Instance.new("Frame", MainWindow)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 10, 0, 96)
ContentFrame.Size = UDim2.new(1, -20, 1, -106); ContentFrame.ZIndex = 3

local TabRegistry = {}
local ActiveTab = nil

local SwitchTab
SwitchTab = function(tabName)
    if ActiveTab == tabName then return end
    ActiveTab = tabName
    for name, tdata in pairs(TabRegistry) do
        local isActive = (name == tabName)
        tdata.Page.Visible = isActive; tdata.Pill.Visible = isActive
        if tdata.SidePill then tdata.SidePill.Visible = isActive end
        tdata.Button.TextColor3 = isActive and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,140,165)
        if tdata.SideBtn then
            tdata.SideBtn.TextColor3 = isActive and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,140,165)
            tdata.SideBtn.BackgroundColor3 = isActive and Color3.fromRGB(28,28,48) or Color3.fromRGB(22,22,36)
        end
    end
end

local function CreateTab(tabName, langKey)
    local tabBtn = Instance.new("TextButton", TabBar)
    tabBtn.BackgroundTransparency = 1; tabBtn.Size = UDim2.new(0, 66, 1, -8)
    tabBtn.Font = Enum.Font.GothamSemibold; tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.fromRGB(140, 140, 165); tabBtn.TextSize = 9
    tabBtn.AutoButtonColor = false; tabBtn.ZIndex = 4
    table.insert(ThemeRegistry.AllLabels, tabBtn)

    local Pill = Instance.new("Frame", tabBtn)
    Pill.BackgroundColor3 = GetThemeColor("Primary"); Pill.BorderSizePixel = 0
    Pill.Size = UDim2.new(0.65, 0, 0, 2); Pill.Position = UDim2.new(0.5, 0, 1, 0)
    Pill.AnchorPoint = Vector2.new(0.5, 1); Pill.ZIndex = 4; Pill.Visible = false
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)
    RegisterThemeElement("Indicators", Pill)

    local sideBtn = Instance.new("TextButton", SideBar)
    sideBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
    sideBtn.Size = UDim2.new(1, -8, 0, 38); sideBtn.Font = Enum.Font.GothamSemibold
    sideBtn.Text = tabName; sideBtn.TextColor3 = Color3.fromRGB(140, 140, 165)
    sideBtn.TextSize = 9; sideBtn.AutoButtonColor = false; sideBtn.BorderSizePixel = 0
    Instance.new("UICorner", sideBtn).CornerRadius = UDim.new(0, 7)
    table.insert(ThemeRegistry.AllLabels, sideBtn)

    local sidePill = Instance.new("Frame", sideBtn)
    sidePill.BackgroundColor3 = GetThemeColor("Primary"); sidePill.BorderSizePixel = 0
    sidePill.Size = UDim2.new(0, 3, 0.6, 0)
    sidePill.Position = UDim2.new(0, 0, 0.5, 0); sidePill.AnchorPoint = Vector2.new(0, 0.5)
    sidePill.ZIndex = 4; sidePill.Visible = false
    Instance.new("UICorner", sidePill).CornerRadius = UDim.new(1, 0)
    RegisterThemeElement("Indicators", sidePill)

    local pageScroll = Instance.new("ScrollingFrame", ContentFrame)
    pageScroll.BackgroundTransparency = 1; pageScroll.Size = UDim2.new(1, 0, 1, 0)
    pageScroll.ScrollBarThickness = 3
    pageScroll.ScrollBarImageColor3 = GetThemeColor("Primary")
    pageScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    pageScroll.BorderSizePixel = 0; pageScroll.ZIndex = 4; pageScroll.Visible = false
    local layout = Instance.new("UIListLayout", pageScroll)
    layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 6)

    TabRegistry[tabName] = { Button=tabBtn, SideBtn=sideBtn, Page=pageScroll, Pill=Pill, SidePill=sidePill }
    if langKey then
        RegisterTranslation(langKey, tabBtn, "Text")
        RegisterTranslation(langKey, sideBtn, "Text")
    end
    tabBtn.MouseButton1Click:Connect(function() SwitchTab(tabName) end)
    sideBtn.MouseButton1Click:Connect(function() SwitchTab(tabName) end)
    return pageScroll
end

local function ApplyTabMode(mode)
    if mode == "Vertikal" then
        TabBar.Visible = false; SideBar.Visible = true
        ContentFrame.Position = UDim2.new(0, 96, 0, 54)
        ContentFrame.Size = UDim2.new(1, -106, 1, -64)
    else
        TabBar.Visible = true; SideBar.Visible = false
        ContentFrame.Position = UDim2.new(0, 10, 0, 96)
        ContentFrame.Size = UDim2.new(1, -20, 1, -106)
    end
end

-- Window Controls Logic
BtnMin.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        -- Jika belum di-maximize, simpan ukuran saat ini sebagai ukuran normal
        if not isWindowMaximized then normalSize = MainWindow.Size end
        
        -- Penentuan lebar saat minimize (Jika Maximize = Full layar, Jika Normal = Lebar saat itu)
        local targetSize = isWindowMaximized 
                           and UDim2.new(1, 0, 0, 46) 
                           or UDim2.new(0, MainWindow.Size.X.Offset, 0, 46)
        
        TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = targetSize}):Play()
        ContentFrame.Visible = false; TabBar.Visible = false; SideBar.Visible = false; ResizeHandle.Visible = false
    else
        -- Un-minimize (Kembalikan ke ukuran semula)
        local targetSize = isWindowMaximized 
                           and UDim2.new(1, 0, 1, 36) 
                           or normalSize
                           
        TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = targetSize}):Play()
        ContentFrame.Visible = true
        if VisualConfig.TabMode == "Horizontal" then TabBar.Visible = true; SideBar.Visible = false
        else TabBar.Visible = false; SideBar.Visible = true end
        ResizeHandle.Visible = not isWindowMaximized
    end
end)

BtnMax.MouseButton1Click:Connect(function()
    if isMinimized then return end -- Cegah maximize saat sedang di-minimize
    isWindowMaximized = not isWindowMaximized
    if isWindowMaximized then
        -- Simpan posisi & ukuran sebelum di-maximize
        normalPos = MainWindow.Position; normalSize = MainWindow.Size
        
        -- [PERBAIKAN] Gunakan UDim2.new(1, 0, 1, 0) murni agar layar penuh presisi
        TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.new(1, 0, 1, 0), 
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
        
        -- Matikan lengkungan ujung saat fullscreen
        local uiCorner = MainWindow:FindFirstChild("UICorner")
        if uiCorner then uiCorner.CornerRadius = UDim.new(0, 0) end
        ResizeHandle.Visible = false
    else
        -- Kembalikan ke posisi normal
        TweenService:Create(MainWindow, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = normalSize, 
            Position = normalPos
        }):Play()
        
        -- Nyalakan lagi lengkungan
        local uiCorner = MainWindow:FindFirstChild("UICorner")
        if uiCorner then uiCorner.CornerRadius = UDim.new(0, 12) end
        ResizeHandle.Visible = true
    end
end)



--------------------------------------------------------------------------------
-- [S16] BACKGROUND EFFECTS
--------------------------------------------------------------------------------
local function ApplyBgEffect(effectName)
    ClearBgEffect()
    if effectName == "Nonaktif" then return end
    
    
    local overlay = Instance.new("CanvasGroup", MainWindow)
    overlay.BackgroundTransparency = 1; overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.ZIndex = 1; overlay.BorderSizePixel = 0; overlay.ClipsDescendants = true
    ActiveBgEffect = overlay



    if effectName == "Ambient Aura" then
        local orbs = {}
        for i = 1, 5 do
            local sz = math.random(120, 200)
            local orb = Instance.new("Frame", overlay)
            orb.BackgroundColor3 = (i % 2 == 0) and GetThemeColor("Primary") or GetThemeColor("Secondary")
            orb.AnchorPoint = Vector2.new(0.5, 0.5)
            orb.Size = UDim2.fromOffset(sz, sz); orb.Position = UDim2.new(math.random(), 0, math.random(), 0)
            orb.BorderSizePixel = 0; orb.ZIndex = 1; orb.BackgroundTransparency = 0.88
            Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
            table.insert(orbs, { frame=orb, pX=math.random()*math.pi*2, pY=math.random()*math.pi*2, sX=0.05+math.random()*0.05, sY=0.05+math.random()*0.05, bX=math.random(), bY=math.random(), pulse=0.3+math.random()*0.3, baseSize=sz })
        end
        ParticleTask = task.spawn(function()
            while task.wait(0.03) do
                if not overlay.Parent then break end
                local t = tick()
                for _, o in ipairs(orbs) do
                    pcall(function()
                        local cs = o.baseSize + (math.sin(t * o.pulse) * 30)
                        o.frame.Position = UDim2.new(o.bX + math.sin(t * o.sX + o.pX) * 0.2, 0, o.bY + math.cos(t * o.sY + o.pY) * 0.2, 0)
                        o.frame.Size = UDim2.fromOffset(cs, cs)
                        o.frame.BackgroundTransparency = 0.85 + ((math.sin(t * o.pulse) + 1) / 2) * 0.1
                    end)
                end
            end
        end)
    elseif effectName == "Nano Dust" then
        local dusts = {}
        for i = 1, 35 do
            local d = Instance.new("Frame", overlay); local sz = math.random(1, 3)
            d.BackgroundColor3 = GetThemeColor("Primary"); d.Size = UDim2.fromOffset(sz, sz)
            d.Position = UDim2.new(math.random(), 0, math.random(), 0); d.BorderSizePixel = 0; d.ZIndex = 2
            Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
            table.insert(dusts, { frame=d, speed=0.01+math.random()*0.03, swayS=0.5+math.random(), swayA=0.005+math.random()*0.015, phase=math.random()*math.pi*2, alphaOffset=math.random() })
        end
        ParticleTask = task.spawn(function()
            while task.wait(0.03) do
                if not overlay.Parent then break end
                local t = tick()
                for _, d in ipairs(dusts) do
                    pcall(function()
                        local y = d.frame.Position.Y.Scale - (d.speed * 0.03)
                        if y < -0.05 then y = 1.05; d.frame.Position = UDim2.new(math.random(), 0, y, 0) end
                        local x = d.frame.Position.X.Scale + math.sin(t * d.swayS + d.phase) * (d.swayA * 0.05)
                        d.frame.Position = UDim2.new(x, 0, y, 0)
                        d.frame.BackgroundTransparency = 0.3 + ((math.sin(t * 2 + d.alphaOffset) + 1) / 2) * 0.6
                    end)
                end
            end
        end)
    elseif effectName == "Fluid Waves" then
        local waves = {}
        for i = 1, 3 do
            local w = Instance.new("Frame", overlay)
            w.BackgroundColor3 = i == 1 and GetThemeColor("Primary") or GetThemeColor("Secondary")
            w.Size = UDim2.new(1.5, 0, 0.4, 0); w.AnchorPoint = Vector2.new(0.5, 0)
            w.BorderSizePixel = 0; w.ZIndex = 1; w.BackgroundTransparency = 0.88 + (i * 0.02)
            Instance.new("UICorner", w).CornerRadius = UDim.new(1, 0)
            table.insert(waves, { frame=w, speed=0.3+(i*0.15), amp=0.05+(i*0.02), phase=i*2, baseH=0.85+(i*0.03) })
        end
        ParticleTask = task.spawn(function()
            while task.wait(0.03) do
                if not overlay.Parent then break end
                local t = tick()
                for _, w in ipairs(waves) do
                    pcall(function()
                        w.frame.Position = UDim2.new(0.5+math.sin(t*w.speed*0.5)*0.1, 0, w.baseH+math.sin(t*w.speed+w.phase)*w.amp, 0)
                        w.frame.Rotation = math.sin(t*w.speed*0.3)*5
                    end)
                end
            end
        end)
    elseif effectName == "Minimalist Dots" then
        local dots = {}
        for i = 1, 40 do
            local d = Instance.new("Frame", overlay)
            d.BackgroundColor3 = GetThemeColor("Primary"); d.Size = UDim2.fromOffset(2, 2)
            d.Position = UDim2.new(math.random(), 0, math.random(), 0); d.BorderSizePixel = 0; d.ZIndex = 1; d.BackgroundTransparency = 0.7
            Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
            table.insert(dots, { frame=d, speedX=0.001, speedY=0.001 })
        end
        ParticleTask = task.spawn(function()
            while task.wait(0.03) do
                if not overlay.Parent then break end
                for _, d in ipairs(dots) do
                    pcall(function()
                        local nx = d.frame.Position.X.Scale + d.speedX; local ny = d.frame.Position.Y.Scale + d.speedY
                        if nx > 1.05 then nx = -0.05 end; if ny > 1.05 then ny = -0.05 end
                        d.frame.Position = UDim2.new(nx, 0, ny, 0)
                    end)
                end
            end
        end)
    elseif effectName == "Glass Shards" then
        local shards = {}
        for i = 1, 8 do
            local sz = math.random(30, 80)
            local s = Instance.new("Frame", overlay); s.BackgroundTransparency = 1
            s.Size = UDim2.fromOffset(sz, sz); s.Position = UDim2.new(math.random(), 0, math.random(), 0)
            s.AnchorPoint = Vector2.new(0.5, 0.5); s.BorderSizePixel = 0; s.ZIndex = 1
            Instance.new("UICorner", s).CornerRadius = UDim.new(0, 8)
            local stroke = Instance.new("UIStroke", s)
            stroke.Color = GetThemeColor("Primary"); stroke.Thickness = 1.5; stroke.Transparency = 0.8
            table.insert(shards, { frame=s, rotSpeed=(math.random()>0.5 and 1 or -1)*(10+math.random()*20), driftX=(math.random()-0.5)*0.002, driftY=(math.random()-0.5)*0.002 })
        end
        ParticleTask = task.spawn(function()
            while task.wait(0.03) do
                if not overlay.Parent then break end
                local dt = 0.03
                for _, s in ipairs(shards) do
                    pcall(function()
                        s.frame.Rotation = s.frame.Rotation + (s.rotSpeed * dt)
                        local nx = s.frame.Position.X.Scale + s.driftX; local ny = s.frame.Position.Y.Scale + s.driftY
                        if nx < -0.1 then nx = 1.1 elseif nx > 1.1 then nx = -0.1 end
                        if ny < -0.1 then ny = 1.1 elseif ny > 1.1 then ny = -0.1 end
                        s.frame.Position = UDim2.new(nx, 0, ny, 0)
                    end)
                end
            end
        end)
    end
end

local function ApplyBgColorTheme(bgName)
    local colors = GUI_BACKGROUNDS[bgName] or GUI_BACKGROUNDS["Dark (Default)"]
    pcall(function()
        MainWindow.BackgroundColor3 = colors.Main
        TopBar.BackgroundColor3 = colors.Header
        TBFix.BackgroundColor3 = colors.Header
        TabBar.BackgroundColor3 = colors.Header
        SideBar.BackgroundColor3 = colors.Header
    end)
end


--------------------------------------------------------------------------------
-- [S16b] CONFIG SYSTEM PATCH — VISUAL SETTINGS SAVE / LOAD
-- Di-patch DI SINI (setelah VisualConfig & semua fungsi Apply* terdefinisi)
-- agar bisa diakses sebagai upvalue. ConfigSystem asli (S05) hanya menyimpan
-- EngineConfig; patch ini menambahkan dukungan penuh untuk VisualConfig.
--------------------------------------------------------------------------------

-- Patch CustomNotify agar warna notifikasi mengikuti tema aktif
-- + menghormati NotifEnabled dan FontSize dari VisualConfig
CustomNotify = function(title, text, duration)
    if VisualConfig and VisualConfig.NotifEnabled == false then return end
    duration = duration or 3
    local notifSize = (VisualConfig and VisualConfig.FontSize) or 8
    local notifH = math.max(60, notifSize * 3 + 6)
    local pri = GetThemeColor("Primary")
    local W = Instance.new("Frame"); W.Parent=NC; W.BackgroundTransparency=1; W.Size=UDim2.new(0,260,0,notifH)
    local NF = Instance.new("Frame"); NF.Parent=W; NF.BackgroundColor3=Color3.fromRGB(20,20,27)
    NF.Size=UDim2.new(1,0,1,0); NF.Position=UDim2.new(1,50,0,0); NF.BackgroundTransparency=1
    Instance.new("UICorner",NF).CornerRadius=UDim.new(0,6)
    local Stroke=Instance.new("UIStroke",NF); Stroke.Color=pri; Stroke.Thickness=1.2; Stroke.Transparency=1
    local Accent=Instance.new("Frame",NF); Accent.BackgroundColor3=pri
    Accent.Size=UDim2.new(0,3,0,0); Accent.Position=UDim2.new(0,12,0.5,0); Accent.AnchorPoint=Vector2.new(0,0.5)
    Accent.BackgroundTransparency=1; Instance.new("UICorner",Accent).CornerRadius=UDim.new(1,0)
    local TL=Instance.new("TextLabel",NF); TL.BackgroundTransparency=1
    TL.Size=UDim2.new(1,-34,0,notifSize+8); TL.Position=UDim2.new(0,24,0,8)
    TL.Font=Enum.Font.GothamBold; TL.Text=string.upper(title)
    TL.TextColor3=pri; TL.TextSize=notifSize; TL.TextXAlignment=Enum.TextXAlignment.Left; TL.TextTransparency=1; TL.TextWrapped=true
    local BL=Instance.new("TextLabel",NF); BL.BackgroundTransparency=1
    BL.Size=UDim2.new(1,-34,0,notifSize+6); BL.Position=UDim2.new(0,24,0,8+notifSize+10)
    BL.Font=Enum.Font.Gotham; BL.Text=text
    BL.TextColor3=Color3.fromRGB(200,200,200); BL.TextSize=math.max(6, notifSize - 2); BL.TextXAlignment=Enum.TextXAlignment.Left; BL.TextTransparency=1; BL.TextWrapped=true
    local ti=TweenInfo.new(0.4,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
    TweenService:Create(NF,ti,{Position=UDim2.new(0,0,0,0),BackgroundTransparency=0.1}):Play()
    TweenService:Create(Stroke,ti,{Transparency=0}):Play()
    TweenService:Create(TL,ti,{TextTransparency=0}):Play()
    TweenService:Create(BL,ti,{TextTransparency=0}):Play()
    TweenService:Create(Accent,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Size=UDim2.new(0,3,1,-24),BackgroundTransparency=0}):Play()
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
-- Perbarui referensi Hub agar tab_visual.lua & modul lain pakai versi yang sudah di-patch
H.CustomNotify = CustomNotify

-- Terapkan SEMUA pengaturan visual sekaligus dari VisualConfig saat ini
local function ApplyAllVisuals()
    pcall(function()
        ApplyBgColorTheme(VisualConfig.CurrentBg)
        ApplyTheme()
        ApplyFont()
        ApplyToggleShape()
        ApplyButtonShape()
        ApplyTransparency()
        ApplyTabMode(VisualConfig.TabMode)
        ApplyBgEffect(VisualConfig.BgEffect)
        H.SetLanguage(VisualConfig.Language or "Indonesia")
        ApplyTranslations()
    end)
end

-- Patch ConfigSystem.SaveNew — simpan EngineConfig + VisualConfig dalam 1 file
ConfigSystem.SaveNew = function(name)
    if name == "" or name == "None" then return false, "Nama tidak valid!" end
    -- Salin VisualConfig (hindari menyimpan referensi fungsi)
    local visualSnapshot = {}
    for k, v in pairs(VisualConfig) do
        if type(v) ~= "function" then visualSnapshot[k] = v end
    end
    local payload = { game = EngineConfig, visual = visualSnapshot }
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, payload)
    if not ok then return false, "Gagal encode." end
    if pcall(writefile, FOLDER_NAME.."/"..name..".json", encoded) then return true
    else return false, "I/O Error." end
end
-- Overwrite = SaveNew (tetap konsisten)
ConfigSystem.OverwriteExisting = ConfigSystem.SaveNew

-- Patch ConfigSystem.Load — muat EngineConfig + VisualConfig, lalu apply visual
ConfigSystem.Load = function(name, callback)
    if name == "None" then return false end
    local path = FOLDER_NAME.."/"..name..".json"
    if not isfile(path) then return false end
    local rok, content = pcall(readfile, path)
    if not (rok and content) then return false end
    local dok, data = pcall(HttpService.JSONDecode, HttpService, content)
    if not (dok and type(data) == "table") then return false end
    -- Format baru: { game={...}, visual={...} }
    -- Format lama (backwards compat): field EngineConfig langsung di root
    local gameData   = data.game   or data
    local visualData = data.visual or nil
    -- Restore EngineConfig
    for k, v in pairs(gameData) do
        if EngineConfig[k] ~= nil then EngineConfig[k] = v end
    end
    -- Restore VisualConfig + terapkan visual secara otomatis
    if visualData then
        for k, v in pairs(visualData) do
            if VisualConfig[k] ~= nil then VisualConfig[k] = v end
        end
        task.defer(ApplyAllVisuals)
    end
    if callback then callback() end
    return true
end


--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Export ke Hub
--------------------------------------------------------------------------------
H.VisualConfig         = VisualConfig
H.GUI_THEMES           = GUI_THEMES
H.THEME_NAMES          = THEME_NAMES
H.GUI_BACKGROUNDS      = GUI_BACKGROUNDS
H.BG_THEME_NAMES       = BG_THEME_NAMES
H.FONT_LIST            = FONT_LIST
H.FONT_MAP             = FONT_MAP
H.ANIM_STYLES          = ANIM_STYLES
H.ANIM_MAP             = ANIM_MAP
H.TOGGLE_SHAPES        = TOGGLE_SHAPES
H.TOGGLE_RADIUS_MAP    = TOGGLE_RADIUS_MAP
H.BUTTON_SHAPES        = BUTTON_SHAPES
H.BUTTON_RADIUS_MAP    = BUTTON_RADIUS_MAP
H.BG_EFFECTS           = BG_EFFECTS
H.ThemeRegistry        = ThemeRegistry
H.GetThemeColor        = GetThemeColor
H.RegisterThemeElement = RegisterThemeElement
H.ApplyTheme           = ApplyTheme
H.ApplyFont            = ApplyFont
H.ApplyToggleShape     = ApplyToggleShape
H.ApplyButtonShape     = ApplyButtonShape
H.ApplyTransparency    = ApplyTransparency
H.UpdateFontSize       = UpdateFontSize
H.GuiPanels            = GuiPanels
H.RegisterPanel        = RegisterPanel
H.ClearBgEffect        = ClearBgEffect
H.ApplyBgEffect        = ApplyBgEffect
H.GuiRoot              = GuiRoot
H.SafeParent           = SafeParent
H.MainWindow           = MainWindow
H.SwitchTab            = SwitchTab
H.CreateTab            = CreateTab
H.CreateSection        = CreateSection
H.CreateToggleUI       = CreateToggleUI
H.CreateCycleUI        = CreateCycleUI
H.CreateDropdownUI     = CreateDropdownUI
H.CreateInputUI        = CreateInputUI
H.CreateButton         = CreateButton
H.CreateMultiCheckUI             = CreateMultiCheckUI
H.CreateScrollableMultiSelectUI  = CreateScrollableMultiSelectUI
H.MakeDraggable        = MakeDraggable
H.MakeResizable        = MakeResizable
H.ApplyAllVisuals      = ApplyAllVisuals
H.CreateSliderUI       = CreateSliderUI   -- digunakan tab_visual
H.ApplyBgColorTheme    = ApplyBgColorTheme  -- digunakan tab_visual
H.ApplyTabMode         = ApplyTabMode        -- digunakan tab_visual
H.BtnClose             = BtnClose         -- digunakan init.lua untuk wire close button
H.UserInputService     = Services.UserInputService  -- digunakan init.lua
H.rgbHue               = 0       -- nilai awal; diperbarui oleh init.lua RGB loop
H.GetRgbHue            = function() return rgbHue end
H.SetRgbHue            = function(v) rgbHue = v; H.rgbHue = v end

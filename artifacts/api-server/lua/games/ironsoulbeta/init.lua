--------------------------------------------------------------------------------
--// init.lua — S28 Floating Toggle Button
--//            S29 Intro Animation
--//            S30 RGB Rainbow Loop
--//            S31 Inisialisasi Akhir
--------------------------------------------------------------------------------
local H               = getgenv().Hub
local VisualConfig    = H.VisualConfig
local EngineConfig    = H.EngineConfig
local ThemeRegistry   = H.ThemeRegistry
local Services        = H.Services
local LocalPlayer     = H.LocalPlayer
local TweenService    = H.TweenService
local GuiRoot         = H.GuiRoot
local SafeParent      = H.SafeParent
local MainWindow      = H.MainWindow
local SwitchTab       = H.SwitchTab
local ApplyAllVisuals = H.ApplyAllVisuals
local SyncAllVisualUI = function(...) return H.SyncAllVisualUI(...) end  -- late-bound
local ConfigSystem    = H.ConfigSystem
local CustomNotify    = H.CustomNotify
local RegisterThemeElement = H.RegisterThemeElement
local GetThemeColor        = H.GetThemeColor
local RegisterPanel        = H.RegisterPanel
local ApplyTheme           = H.ApplyTheme
local ANIM_MAP             = H.ANIM_MAP
-- Dari ui_core.lua
local RuntimeMaid      = H.RuntimeMaid
local BtnClose         = H.BtnClose
local UserInputService = H.UserInputService
-- rgbHue: diakses lewat Hub agar sync dengan GetThemeColor di ui_core
local function getRgbHue() return H.GetRgbHue() end
local function setRgbHue(v) H.SetRgbHue(v) end

-- [S28] FLOATING TOGGLE BUTTON (Premium)
--------------------------------------------------------------------------------
local ToggleGuiBtn = Instance.new("ScreenGui", SafeParent)
ToggleGuiBtn.Name = "XiFil_Toggle"; ToggleGuiBtn.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ToggleGuiBtn.ResetOnSpawn = false; ToggleGuiBtn.DisplayOrder = 999988
RuntimeMaid:GiveTask(ToggleGuiBtn)

local guiVisible = false
local isToggling = false

-- Memori untuk menyimpan status ukuran dan posisi terakhir GUI sebelum ditutup
local savedSize = UDim2.new(0, VisualConfig.GuiWidth, 0, VisualConfig.GuiHeight)
local savedPos = UDim2.new(0.5, -VisualConfig.GuiWidth/2, 0.5, -VisualConfig.GuiHeight/2)

local function ToggleGUI()
    if isToggling then return end -- ANTI-SPAM: Mencegah bug GUI mengecil/bergeser ke atas
    isToggling = true
    guiVisible = not guiVisible
    local easingStyle = ANIM_MAP[VisualConfig.AnimStyle] or Enum.EasingStyle.Back
    
    if guiVisible then
        MainWindow.Visible = true
        MainWindow.Size = UDim2.new(0, 0, 0, 0)
        MainWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        TweenService:Create(MainWindow, TweenInfo.new(0.35, easingStyle, Enum.EasingDirection.Out), {
            Size = savedSize,
            Position = savedPos
        }):Play()
        task.wait(0.35)
    else
        -- Simpan state SAAT INI (sebelum animasi jalan)
        savedSize = MainWindow.Size
        savedPos = MainWindow.Position
        
        TweenService:Create(MainWindow, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        task.wait(0.29)
        MainWindow.Visible = false
    end
    isToggling = false
end

BtnClose.MouseButton1Click:Connect(function()
    if guiVisible then ToggleGUI() end
end)

local BtnContainer = Instance.new("Frame", ToggleGuiBtn)
BtnContainer.BackgroundTransparency = 1
BtnContainer.Position = UDim2.new(0.05, 0, 0.15, 0)
BtnContainer.Size = UDim2.fromOffset(110, 36); BtnContainer.Visible = false

local floatGlow = Instance.new("Frame", BtnContainer)
floatGlow.BackgroundColor3 = GetThemeColor("Primary"); floatGlow.BackgroundTransparency = 0.8
floatGlow.Size = UDim2.new(1, 4, 1, 4); floatGlow.Position = UDim2.new(0.5,0,0.5,0)
floatGlow.AnchorPoint = Vector2.new(0.5,0.5); floatGlow.BorderSizePixel = 0
Instance.new("UICorner", floatGlow).CornerRadius = UDim.new(1, 0)
RegisterThemeElement("Fills", { elem = floatGlow, _type = "primary" })

local floatBtn = Instance.new("TextButton", BtnContainer)
floatBtn.BackgroundColor3 = Color3.fromRGB(15,15,22)
floatBtn.Size = UDim2.new(1,0,1,0); floatBtn.Position = UDim2.new(0.5,0,0.5,0)
floatBtn.AnchorPoint = Vector2.new(0.5,0.5); floatBtn.Text = ""; floatBtn.AutoButtonColor = false; floatBtn.BorderSizePixel = 0
Instance.new("UICorner", floatBtn).CornerRadius = UDim.new(1, 0)
local BtnStroke = Instance.new("UIStroke", floatBtn)
BtnStroke.Color = GetThemeColor("Primary"); BtnStroke.Thickness = 1.2; BtnStroke.Transparency = 0.35
RegisterThemeElement("Strokes", BtnStroke)

local TextLayout = Instance.new("Frame", floatBtn); TextLayout.BackgroundTransparency = 1; TextLayout.Size = UDim2.new(1,0,1,0)
local UIListL = Instance.new("UIListLayout", TextLayout)
UIListL.FillDirection = Enum.FillDirection.Horizontal
UIListL.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListL.VerticalAlignment = Enum.VerticalAlignment.Center
UIListL.Padding = UDim.new(0, 4)

local StatusDot = Instance.new("Frame", TextLayout)
StatusDot.BackgroundColor3 = GetThemeColor("Primary"); StatusDot.Size = UDim2.fromOffset(6,6); StatusDot.BorderSizePixel = 0
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1,0)
RegisterThemeElement("Fills", { elem = StatusDot, _type = "primary" })

local BtnLabel = Instance.new("TextLabel", TextLayout)
BtnLabel.BackgroundTransparency = 1; BtnLabel.Font = Enum.Font.GothamBlack; BtnLabel.Text = "XIFIL"
BtnLabel.TextColor3 = Color3.fromRGB(255,255,255); BtnLabel.TextSize = 12; BtnLabel.AutomaticSize = Enum.AutomaticSize.X

local BtnSubLabel = Instance.new("TextLabel", TextLayout)
BtnSubLabel.BackgroundTransparency = 1; BtnSubLabel.Font = Enum.Font.GothamBold; BtnSubLabel.Text = "HUB"
BtnSubLabel.TextColor3 = GetThemeColor("Primary"); BtnSubLabel.TextSize = 12; BtnSubLabel.AutomaticSize = Enum.AutomaticSize.X
RegisterThemeElement("Texts", BtnSubLabel)

-- ANIMASI HOVER EFEK
floatBtn.MouseEnter:Connect(function()
    TweenService:Create(floatGlow, TweenInfo.new(0.3,Enum.EasingStyle.Quint), {BackgroundTransparency=0.5, Size=UDim2.new(1,10,1,10)}):Play()
    TweenService:Create(floatBtn, TweenInfo.new(0.3,Enum.EasingStyle.Quint), {BackgroundColor3=Color3.fromRGB(22,22,32)}):Play()
    TweenService:Create(BtnStroke, TweenInfo.new(0.3,Enum.EasingStyle.Quint), {Transparency=0}):Play()
end)
floatBtn.MouseLeave:Connect(function()
    TweenService:Create(floatGlow, TweenInfo.new(0.3,Enum.EasingStyle.Quint), {BackgroundTransparency=0.8, Size=UDim2.new(1,4,1,4)}):Play()
    TweenService:Create(floatBtn, TweenInfo.new(0.3,Enum.EasingStyle.Quint), {BackgroundColor3=Color3.fromRGB(15,15,22)}):Play()
    TweenService:Create(BtnStroke, TweenInfo.new(0.3,Enum.EasingStyle.Quint), {Transparency=0.35}):Play()
end)

-- CUSTOM DRAG & CLICK LOGIC (Membedakan antara menggeser dan menekan)
local draggingFloating = false
local isMoved = false
local dragStartPos = nil
local startBtnPos = nil

floatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingFloating = true
        isMoved = false
        dragStartPos = input.Position
        startBtnPos = BtnContainer.Position
        
        -- Efek ditekan
        TweenService:Create(floatBtn, TweenInfo.new(0.15,Enum.EasingStyle.Quad), {Size=UDim2.new(0.9,0,0.9,0)}):Play()
        TweenService:Create(floatGlow, TweenInfo.new(0.15,Enum.EasingStyle.Quad), {Size=UDim2.new(0.9,4,0.9,4)}):Play()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingFloating and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        -- Jika mouse bergeser lebih dari 5 pixel, maka dianggap Drag (Bukan klik)
        if delta.Magnitude > 5 then
            isMoved = true 
        end
        BtnContainer.Position = UDim2.new(
            startBtnPos.X.Scale, startBtnPos.X.Offset + delta.X,
            startBtnPos.Y.Scale, startBtnPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if draggingFloating then
            draggingFloating = false
            
            -- Efek dilepas
            TweenService:Create(floatBtn, TweenInfo.new(0.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=UDim2.new(1,0,1,0)}):Play()
            TweenService:Create(floatGlow, TweenInfo.new(0.15,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {Size=UDim2.new(1,10,1,10)}):Play()
            
            -- JIKA TIDAK DIGESER (Hanya diklik/Tap biasa), maka buka/tutup GUI
            if not isMoved and VisualConfig.GestureMode == "Classic" then
                ToggleGUI()
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if VisualConfig.GestureMode == "Keybind [F]" and input.KeyCode == Enum.KeyCode.F then ToggleGUI() end
end)



--------------------------------------------------------------------------------
-- [S29] INTRO ANIMATION
--------------------------------------------------------------------------------
local function PlayIntroAnimation()
    local IntroGui = Instance.new("ScreenGui", SafeParent)
    IntroGui.Name = "XiFil_Intro"; IntroGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    IntroGui.ResetOnSpawn = false; IntroGui.DisplayOrder = 9999999; IntroGui.IgnoreGuiInset = true

    local Overlay = Instance.new("Frame", IntroGui)
    Overlay.BackgroundColor3 = Color3.fromRGB(6, 6, 12); Overlay.BackgroundTransparency = 1
    Overlay.Size = UDim2.new(1, 0, 1, 0); Overlay.BorderSizePixel = 0; Overlay.ZIndex = 1

    local Container = Instance.new("Frame", Overlay)
    Container.BackgroundTransparency = 1; Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0); Container.Size = UDim2.fromOffset(220, 65)
    Container.ClipsDescendants = true; Container.ZIndex = 2

    local Line = Instance.new("Frame", Container)
    Line.AnchorPoint = Vector2.new(0.5, 1); Line.Position = UDim2.new(0.5, 0, 0.95, 0)
    Line.Size = UDim2.fromOffset(0, 2); Line.BackgroundColor3 = GetThemeColor("Primary")
    Line.BorderSizePixel = 0; Line.ZIndex = 4
    Instance.new("UICorner", Line).CornerRadius = UDim.new(1, 0)
    local LineGlow = Instance.new("Frame", Line)
    LineGlow.BackgroundColor3 = GetThemeColor("Primary"); LineGlow.BackgroundTransparency = 0.6
    LineGlow.AnchorPoint = Vector2.new(0.5, 0.5); LineGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
    LineGlow.Size = UDim2.new(1, 16, 1, 8); LineGlow.BorderSizePixel = 0; LineGlow.ZIndex = 3
    Instance.new("UICorner", LineGlow).CornerRadius = UDim.new(1, 0)

    local MainText = Instance.new("TextLabel", Container)
    MainText.BackgroundColor3 = Color3.fromRGB(20, 20, 30); MainText.BackgroundTransparency = 0.35
    MainText.AnchorPoint = Vector2.new(0.5, 1); MainText.Position = UDim2.new(0.5, 0, 2, 0)
    MainText.Size = UDim2.fromOffset(190, 44); MainText.Font = Enum.Font.GothamBlack
    MainText.RichText = true; MainText.BorderSizePixel = 0; MainText.ZIndex = 3
    Instance.new("UICorner", MainText).CornerRadius = UDim.new(0, 10)
    local pColor = GetThemeColor("Primary")
    local hexFormat = string.format("#%02X%02X%02X", math.floor(pColor.R*255), math.floor(pColor.G*255), math.floor(pColor.B*255))
    MainText.Text = 'XIFIL <font color="'..hexFormat..'">HUB</font>'
    MainText.TextColor3 = Color3.fromRGB(255, 255, 255); MainText.TextSize = 28

    TweenService:Create(Line, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(190, 2)}):Play()
    task.wait(0.35)
    TweenService:Create(MainText, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.85, 0)}):Play()
    task.wait(1.3)
    TweenService:Create(MainText, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 2, 0)}):Play()
    task.wait(0.35)
    TweenService:Create(Line, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.fromOffset(0, 2)}):Play()
    task.wait(0.4)

    BtnContainer.Visible = true
    local finalSize = UDim2.fromOffset(110, 36); local finalPos = BtnContainer.Position
    local centerPos = UDim2.new(finalPos.X.Scale, finalPos.X.Offset + 55, finalPos.Y.Scale, finalPos.Y.Offset + 18)
    BtnContainer.Size = UDim2.fromOffset(0, 0); BtnContainer.Position = centerPos
    TweenService:Create(BtnContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = finalSize, Position = finalPos}):Play()
    task.wait(0.55)
    IntroGui:Destroy()
    ToggleGUI()
end


--------------------------------------------------------------------------------
-- [S30] RGB RAINBOW LOOP
--------------------------------------------------------------------------------
task.spawn(function()
    while true do
        task.wait(0.05); setRgbHue((getRgbHue() + 0.005) % 1)
        if VisualConfig.CurrentTheme == "RGB" then pcall(ApplyTheme) end
    end
end)


--------------------------------------------------------------------------------
-- [S31] INISIALISASI
--------------------------------------------------------------------------------
SwitchTab("🏠 Farm")

--------------------------------------------------------------------------------
-- [S31] INISIALISASI (Bagian Akhir Script)
--------------------------------------------------------------------------------
SwitchTab("🏠 Farm")

task.defer(function()
    -- 1. TERAPKAN VISUAL DEFAULT UNTUK USER BARU
    -- Ini akan langsung memunculkan Nano Dust, Font, dan Warna tanpa perlu diklik!
    if ApplyAllVisuals then
        pcall(ApplyAllVisuals)
    end

    -- 2. Sinkronkan tombol di UI agar menampilkan teks bawaan yang benar
    if SyncAllVisualUI then
        pcall(SyncAllVisualUI)
    end

    -- 3. Terapkan config mesin bawaan
    if EngineConfig.AntiAFKActive    and _G.AntiAFKToggle    then _G.AntiAFKToggle:SetValue(true) end
    if EngineConfig.AntiPausedActive and _G.AntiPausedToggle then _G.AntiPausedToggle:SetValue(true) end
    
    -- 4. Mainkan animasi intro & Tampilkan Notifikasi
    if PlayIntroAnimation then
        task.spawn(function()
            -- 1. Jalankan animasinya terlebih dahulu
            PlayIntroAnimation() 
            
            -- 2. Beri jeda waktu sampai animasi benar-benar selesai dan menjadi Floating.
            -- (Sesuaikan angka 2.5 ini dengan durasi detik animasi intro kamu)
            task.wait(2.5) 
            
            -- 3. Panggil Notifikasi
            -- Ganti "SendNotification" dengan nama fungsi notifikasimu yang sebenarnya jika berbeda
            pcall(function()
                CustomNotify("XIFIL HUB", "Script berhasil dieksekusi dan siap digunakan!", 5)
            end)
        end)
    end

end)

-- (Jika ada sistem Load Profile otomatis di bawah sini, biarkan saja)


ConfigSystem.ExecuteAutoLoad(function() SyncAllVisualUI() end)




--------------------------------------------------------------------------------
-- Export ke Hub (opsional, untuk akses eksternal jika dibutuhkan)
--------------------------------------------------------------------------------
H.ToggleGUI         = ToggleGUI
H.PlayIntroAnimation = PlayIntroAnimation

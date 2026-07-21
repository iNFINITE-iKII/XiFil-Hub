--------------------------------------------------------------------------------
--// XiFil DRM Wrapper — Template Game Baru
--// Duplikat file ini, rename sesuai nama game (contoh: blox_fruits.lua)
--// Lalu isi bagian mainScript di bawah dengan script game kamu
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
--// HELPER: Tween
--------------------------------------------------------------------------------
local TweenService = game:GetService("TweenService")
local function tween(obj, props, duration, style, direction)
    style     = style     or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.3, style, direction)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

--------------------------------------------------------------------------------
--// INPUT KEY — LANDSCAPE MODERN GUI
--------------------------------------------------------------------------------
local function promptKey(callback)
    local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    local existing = PlayerGui:FindFirstChild("XiFil_KeyPrompt")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name            = "XiFil_KeyPrompt"
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn    = false
    gui.IgnoreGuiInset  = true
    gui.Parent          = PlayerGui

    local backdrop = Instance.new("Frame", gui)
    backdrop.Size                   = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 1
    backdrop.BorderSizePixel        = 0
    backdrop.ZIndex                 = 1
    tween(backdrop, { BackgroundTransparency = 0.6 }, 0.4)

    local CW, CH = 580, 220

    local shadow = Instance.new("Frame", gui)
    shadow.Size                   = UDim2.new(0, CW + 14, 0, CH + 14)
    shadow.Position               = UDim2.new(0.5, -(CW + 14)/2, 0.62, -(CH + 14)/2)
    shadow.BackgroundColor3       = Color3.fromRGB(50, 130, 255)
    shadow.BackgroundTransparency = 0.78
    shadow.BorderSizePixel        = 0
    shadow.ZIndex                 = 2
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 22)
    tween(shadow, { Position = UDim2.new(0.5, -(CW + 14)/2, 0.5, -(CH + 14)/2) }, 0.5, Enum.EasingStyle.Back)

    local card = Instance.new("Frame", gui)
    card.Size                   = UDim2.new(0, CW, 0, CH)
    card.Position               = UDim2.new(0.5, -CW/2, 0.62, -CH/2)
    card.BackgroundColor3       = Color3.fromRGB(11, 13, 20)
    card.BorderSizePixel        = 0
    card.ZIndex                 = 3
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 16)
    tween(card, { Position = UDim2.new(0.5, -CW/2, 0.5, -CH/2) }, 0.5, Enum.EasingStyle.Back)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color        = Color3.fromRGB(40, 140, 255)
    stroke.Thickness    = 1
    stroke.Transparency = 0.35

    task.spawn(function()
        while card.Parent do
            tween(stroke, { Transparency = 0.7 }, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.4)
            tween(stroke, { Transparency = 0.1 }, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.4)
        end
    end)

    local LP = 180

    local leftPanel = Instance.new("Frame", card)
    leftPanel.Size             = UDim2.new(0, LP, 1, 0)
    leftPanel.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
    leftPanel.BorderSizePixel  = 0
    leftPanel.ZIndex           = 4
    Instance.new("UICorner", leftPanel).CornerRadius = UDim.new(0, 16)

    local leftClip = Instance.new("Frame", leftPanel)
    leftClip.Size             = UDim2.new(0, 16, 1, 0)
    leftClip.Position         = UDim2.new(1, -16, 0, 0)
    leftClip.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
    leftClip.BorderSizePixel  = 0
    leftClip.ZIndex           = 4

    local leftGrad = Instance.new("UIGradient", leftPanel)
    leftGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 20, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 22)),
    })
    leftGrad.Rotation = 120

    local leftEdge = Instance.new("Frame", card)
    leftEdge.Size             = UDim2.new(0, 1, 0, CH - 32)
    leftEdge.Position         = UDim2.new(0, LP, 0, 16)
    leftEdge.BackgroundColor3 = Color3.fromRGB(30, 45, 80)
    leftEdge.BorderSizePixel  = 0
    leftEdge.ZIndex           = 5

    local LOGO_ASSET_ID = "rbxassetid://74294782991577"

    local iconBg = Instance.new("Frame", leftPanel)
    iconBg.Size              = UDim2.new(0, 56, 0, 56)
    iconBg.Position          = UDim2.new(0.5, -28, 0, 26)
    iconBg.BackgroundColor3  = Color3.fromRGB(8, 14, 30)
    iconBg.BorderSizePixel   = 0
    iconBg.ClipsDescendants  = true
    iconBg.ZIndex            = 5
    Instance.new("UICorner", iconBg).CornerRadius = UDim.new(1, 0)

    local glowRing = Instance.new("Frame", leftPanel)
    glowRing.Size             = UDim2.new(0, 62, 0, 62)
    glowRing.Position         = UDim2.new(0.5, -31, 0, 23)
    glowRing.BackgroundTransparency = 1
    glowRing.BorderSizePixel  = 0
    glowRing.ZIndex           = 4
    Instance.new("UICorner", glowRing).CornerRadius = UDim.new(1, 0)

    local iconStroke = Instance.new("UIStroke", glowRing)
    iconStroke.Color        = Color3.fromRGB(50, 150, 255)
    iconStroke.Thickness    = 2
    iconStroke.Transparency = 0.2

    task.spawn(function()
        while glowRing.Parent do
            tween(iconStroke, { Transparency = 0.75 }, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
            tween(iconStroke, { Transparency = 0.0 }, 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
        end
    end)

    local iconImg = Instance.new("ImageLabel", iconBg)
    iconImg.Size                   = UDim2.new(1, 0, 1, 0)
    iconImg.BackgroundTransparency = 1
    iconImg.Image                  = LOGO_ASSET_ID
    iconImg.ScaleType              = Enum.ScaleType.Crop
    iconImg.ZIndex                 = 6

    local brandName = Instance.new("TextLabel", leftPanel)
    brandName.Size                  = UDim2.new(1, -10, 0, 24)
    brandName.Position              = UDim2.new(0, 5, 0, 86)
    brandName.BackgroundTransparency = 1
    brandName.Text                  = "XIFIL HUB"
    brandName.TextSize              = 15
    brandName.Font                  = Enum.Font.GothamBold
    brandName.TextXAlignment        = Enum.TextXAlignment.Center
    brandName.ZIndex                = 5

    local brandGrad = Instance.new("UIGradient", brandName)
    brandGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 240)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 240)),
    })

    task.spawn(function()
        while brandName.Parent do
            tween(brandName, { TextTransparency = 0.7 }, 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.0)
            tween(brandName, { TextTransparency = 0.0 }, 1.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.0)
        end
    end)

    local brandSub = Instance.new("TextLabel", leftPanel)
    brandSub.Size                  = UDim2.new(1, -10, 0, 16)
    brandSub.Position              = UDim2.new(0, 5, 0, 122)
    brandSub.BackgroundTransparency = 1
    brandSub.Text                  = "PREMIUM"
    brandSub.TextColor3            = Color3.fromRGB(70, 85, 120)
    brandSub.TextSize              = 10
    brandSub.Font                  = Enum.Font.GothamMedium
    brandSub.TextXAlignment        = Enum.TextXAlignment.Center
    brandSub.ZIndex                = 5

    local DISCORD_LINK = "https://discord.gg/hWqPM9hbH"

    local dcBtn = Instance.new("TextButton", leftPanel)
    dcBtn.Size             = UDim2.new(1, -24, 0, 34)
    dcBtn.Position         = UDim2.new(0, 12, 1, -50)
    dcBtn.BackgroundColor3 = Color3.fromRGB(50, 52, 100)
    dcBtn.TextColor3       = Color3.fromRGB(180, 190, 255)
    dcBtn.Text             = "💬  Discord"
    dcBtn.TextSize         = 11
    dcBtn.Font             = Enum.Font.GothamBold
    dcBtn.BorderSizePixel  = 0
    dcBtn.ZIndex           = 5
    Instance.new("UICorner", dcBtn).CornerRadius = UDim.new(0, 8)

    local dcStroke = Instance.new("UIStroke", dcBtn)
    dcStroke.Color        = Color3.fromRGB(88, 101, 242)
    dcStroke.Thickness    = 1
    dcStroke.Transparency = 0.5

    dcBtn.MouseEnter:Connect(function()
        tween(dcBtn, { BackgroundColor3 = Color3.fromRGB(68, 70, 130) }, 0.15)
        tween(dcStroke, { Transparency = 0.1 }, 0.15)
    end)
    dcBtn.MouseLeave:Connect(function()
        tween(dcBtn, { BackgroundColor3 = Color3.fromRGB(50, 52, 100) }, 0.15)
        tween(dcStroke, { Transparency = 0.5 }, 0.15)
    end)

    local dcCooldown = false
    dcBtn.MouseButton1Click:Connect(function()
        if dcCooldown then return end
        local opened = false
        pcall(function() syn.open_url(DISCORD_LINK); opened = true end)
        if not opened then pcall(function() open_url(DISCORD_LINK); opened = true end) end
        if not opened then pcall(function() setclipboard(DISCORD_LINK) end) end

        dcCooldown = true
        local prev = dcBtn.Text
        dcBtn.Text = opened and "Membuka..." or "Link disalin!"
        task.delay(2.2, function()
            if dcBtn.Parent then
                dcBtn.Text = prev
                dcCooldown = false
            end
        end)
    end)

    local badge = Instance.new("TextLabel", leftPanel)
    badge.Size                  = UDim2.new(1, -10, 0, 14)
    badge.Position              = UDim2.new(0, 5, 1, -14)
    badge.BackgroundTransparency = 1
    badge.Text                  = "● Protected"
    badge.TextColor3            = Color3.fromRGB(40, 180, 90)
    badge.TextSize              = 9
    badge.Font                  = Enum.Font.Gotham
    badge.TextXAlignment        = Enum.TextXAlignment.Center
    badge.ZIndex                = 5

    local RP_X = LP + 18

    local title = Instance.new("TextLabel", card)
    title.Size                  = UDim2.new(0, CW - RP_X - 18, 0, 22)
    title.Position              = UDim2.new(0, RP_X, 0, 22)
    title.BackgroundTransparency = 1
    title.Text                  = "Aktivasi License"
    title.TextColor3            = Color3.fromRGB(220, 232, 255)
    title.TextSize              = 16
    title.Font                  = Enum.Font.GothamBold
    title.TextXAlignment        = Enum.TextXAlignment.Left
    title.ZIndex                = 4

    local subtitle = Instance.new("TextLabel", card)
    subtitle.Size                  = UDim2.new(0, CW - RP_X - 18, 0, 16)
    subtitle.Position              = UDim2.new(0, RP_X, 0, 46)
    subtitle.BackgroundTransparency = 1
    subtitle.Text                  = "Masukkan license key kamu untuk melanjutkan"
    subtitle.TextColor3            = Color3.fromRGB(70, 85, 115)
    subtitle.TextSize              = 11
    subtitle.Font                  = Enum.Font.Gotham
    subtitle.TextXAlignment        = Enum.TextXAlignment.Left
    subtitle.ZIndex                = 4

    local titleLine = Instance.new("Frame", card)
    titleLine.Size             = UDim2.new(0, CW - RP_X - 18, 0, 1)
    titleLine.Position         = UDim2.new(0, RP_X, 0, 70)
    titleLine.BackgroundColor3 = Color3.fromRGB(25, 32, 55)
    titleLine.BorderSizePixel  = 0
    titleLine.ZIndex           = 4

    local inputWrap = Instance.new("Frame", card)
    inputWrap.Size             = UDim2.new(0, CW - RP_X - 18, 0, 42)
    inputWrap.Position         = UDim2.new(0, RP_X, 0, 82)
    inputWrap.BackgroundColor3 = Color3.fromRGB(15, 18, 30)
    inputWrap.BorderSizePixel  = 0
    inputWrap.ZIndex           = 4
    Instance.new("UICorner", inputWrap).CornerRadius = UDim.new(0, 10)

    local inputStroke = Instance.new("UIStroke", inputWrap)
    inputStroke.Color     = Color3.fromRGB(30, 40, 65)
    inputStroke.Thickness = 1.2

    local input = Instance.new("TextBox", inputWrap)
    input.Size                  = UDim2.new(1, -100, 1, 0)
    input.Position              = UDim2.new(0, 14, 0, 0)
    input.BackgroundTransparency = 1
    input.TextColor3            = Color3.fromRGB(210, 225, 255)
    input.PlaceholderText       = "XXXX-XXXX-XXXX-XXXX"
    input.PlaceholderColor3     = Color3.fromRGB(45, 55, 80)
    input.Text                  = ""
    input.TextSize              = 13
    input.Font                  = Enum.Font.GothamMedium
    input.ClearTextOnFocus      = false
    input.ZIndex                = 5

    local pasteBtn = Instance.new("TextButton", inputWrap)
    pasteBtn.Size             = UDim2.new(0, 52, 0, 26)
    pasteBtn.Position         = UDim2.new(1, -58, 0.5, -13)
    pasteBtn.BackgroundColor3 = Color3.fromRGB(22, 40, 72)
    pasteBtn.TextColor3       = Color3.fromRGB(80, 160, 255)
    pasteBtn.Text             = "PASTE"
    pasteBtn.TextSize         = 9
    pasteBtn.Font             = Enum.Font.GothamBold
    pasteBtn.BorderSizePixel  = 0
    pasteBtn.ZIndex           = 6
    Instance.new("UICorner", pasteBtn).CornerRadius = UDim.new(0, 6)

    pasteBtn.MouseButton1Click:Connect(function()
        local clip = nil
        local attempts = {
            function() return getclipboard() end,
            function() return syn.getclipboard() end,
            function() return clua.getclipboard() end,
            function() return Clipboard.get() end,
        }
        for _, fn in ipairs(attempts) do
            local ok, result = pcall(fn)
            if ok and type(result) == "string" and result:match("%S") then
                clip = result
                break
            end
        end

        if clip then
            input.Text = clip:gsub("%s+", "")
            pasteBtn.Text = "✓"
            pasteBtn.TextColor3 = Color3.fromRGB(60, 220, 120)
            task.delay(1.2, function()
                if pasteBtn.Parent then
                    pasteBtn.Text = "PASTE"
                    pasteBtn.TextColor3 = Color3.fromRGB(80, 160, 255)
                end
            end)
        else
            input:CaptureFocus()
        end
    end)

    input.Focused:Connect(function()
        tween(inputStroke, { Color = Color3.fromRGB(55, 140, 255), Thickness = 1.5 }, 0.2)
    end)
    input.FocusLost:Connect(function()
        tween(inputStroke, { Color = Color3.fromRGB(30, 40, 65), Thickness = 1.2 }, 0.2)
    end)

    local status = Instance.new("TextLabel", card)
    status.Size                  = UDim2.new(0, CW - RP_X - 18, 0, 16)
    status.Position              = UDim2.new(0, RP_X, 0, 130)
    status.BackgroundTransparency = 1
    status.Text                  = ""
    status.TextColor3            = Color3.fromRGB(255, 75, 75)
    status.TextSize              = 11
    status.Font                  = Enum.Font.Gotham
    status.TextXAlignment        = Enum.TextXAlignment.Left
    status.ZIndex                = 4

    local btnFrame = Instance.new("Frame", card)
    btnFrame.Size             = UDim2.new(0, CW - RP_X - 18, 0, 40)
    btnFrame.Position         = UDim2.new(0, RP_X, 0, 152)
    btnFrame.BackgroundColor3 = Color3.fromRGB(25, 90, 200)
    btnFrame.BorderSizePixel  = 0
    btnFrame.ZIndex           = 4
    Instance.new("UICorner", btnFrame).CornerRadius = UDim.new(0, 10)

    local btnGrad = Instance.new("UIGradient", btnFrame)
    btnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 85, 210)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 50, 230)),
    })
    btnGrad.Rotation = 90

    local btn = Instance.new("TextButton", btnFrame)
    btn.Size                  = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.TextColor3            = Color3.fromRGB(255, 255, 255)
    btn.Text                  = "AKTIVASI  →"
    btn.TextSize              = 13
    btn.Font                  = Enum.Font.GothamBold
    btn.ZIndex                = 5

    btn.MouseEnter:Connect(function()
        tween(btnFrame, { BackgroundColor3 = Color3.fromRGB(45, 120, 255) }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(btnFrame, { BackgroundColor3 = Color3.fromRGB(25, 90, 200) }, 0.15)
    end)

    local footer = Instance.new("TextLabel", card)
    footer.Size                  = UDim2.new(0, CW - RP_X - 18, 0, 14)
    footer.Position              = UDim2.new(0, RP_X, 0, 198)
    footer.BackgroundTransparency = 1
    footer.Text                  = "XiFil Hub  •  Secure"
    footer.TextColor3            = Color3.fromRGB(35, 45, 68)
    footer.TextSize              = 9
    footer.Font                  = Enum.Font.Gotham
    footer.TextXAlignment        = Enum.TextXAlignment.Right
    footer.ZIndex                = 4

    local checking = false
    local function setLoading(state)
        checking = state
        if state then
            btn.Active = false
            tween(btnFrame, { BackgroundColor3 = Color3.fromRGB(18, 35, 70) }, 0.2)
            task.spawn(function()
                local dots = {".", "..", "..."}
                local i = 1
                while checking do
                    btn.Text = "Memeriksa" .. dots[i]
                    i = (i % 3) + 1
                    task.wait(0.4)
                end
            end)
        else
            checking = false
            btn.Active = true
            btn.Text   = "AKTIVASI  →"
            tween(btnFrame, { BackgroundColor3 = Color3.fromRGB(25, 90, 200) }, 0.2)
        end
    end

    local function playSuccess(msg, onDone)
        status.TextColor3 = Color3.fromRGB(50, 220, 120)
        status.Text       = "✓  " .. msg
        btnFrame.BackgroundColor3 = Color3.fromRGB(15, 155, 70)
        btnGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 155, 65)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 195, 95)),
        })
        btn.Text = "✓  KEY VALID"
        tween(stroke, { Color = Color3.fromRGB(30, 220, 110), Transparency = 0 }, 0.3)

        task.wait(0.7)

        local slideInfo = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        local slideUp = TweenService:Create(card, slideInfo, {
            Position              = UDim2.new(0.5, -CW/2, 0.5, -CH/2 - 120),
            BackgroundTransparency = 1,
        })
        local fadeStroke = TweenService:Create(stroke, slideInfo, { Transparency = 1 })
        local fadeShadow = TweenService:Create(shadow, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
        local fadeBg     = TweenService:Create(backdrop, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { BackgroundTransparency = 1 })

        slideUp:Play()
        fadeStroke:Play()
        fadeShadow:Play()
        fadeBg:Play()

        task.wait(0.6)
        gui:Destroy()
        onDone()
    end

    btn.MouseButton1Click:Connect(function()
        if checking then return end
        local key = input.Text:gsub("%s+", "")
        if #key < 10 then
            status.TextColor3 = Color3.fromRGB(255, 75, 75)
            status.Text       = "⚠  Key terlalu pendek."
            tween(inputStroke, { Color = Color3.fromRGB(210, 50, 50) }, 0.15)
            task.delay(0.7, function()
                tween(inputStroke, { Color = Color3.fromRGB(30, 40, 65) }, 0.3)
            end)
            return
        end

        status.Text = ""
        setLoading(true)

        local hwid = getHWID()
        local valid, msg = checkLicense(key, hwid)

        if valid then
            saveKey(key)
            setLoading(false)
            playSuccess(msg, function() callback(key, hwid) end)
        else
            deleteKey()
            setLoading(false)
            status.TextColor3 = Color3.fromRGB(255, 75, 75)
            status.Text       = "✕  " .. msg

            local ox = -CW/2
            tween(card, { Position = UDim2.new(0.5, ox + 9,  0.5, -CH/2) }, 0.06)
            task.wait(0.06)
            tween(card, { Position = UDim2.new(0.5, ox - 9,  0.5, -CH/2) }, 0.06)
            task.wait(0.06)
            tween(card, { Position = UDim2.new(0.5, ox + 4,  0.5, -CH/2) }, 0.05)
            task.wait(0.05)
            tween(card, { Position = UDim2.new(0.5, ox,      0.5, -CH/2) }, 0.05)

            tween(inputStroke, { Color = Color3.fromRGB(200, 45, 45) }, 0.15)
            task.delay(1.2, function()
                if card.Parent then
                    tween(inputStroke, { Color = Color3.fromRGB(30, 40, 65) }, 0.4)
                end
            end)
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
--//  TARUH SCRIPT GAME KAMU DI SINI
--------------------------------------------------------------------------------
startWithDRM(function(key, hwid)
    -- Script game kamu di sini
    -- Contoh:
    -- print("Key valid:", key)
end)

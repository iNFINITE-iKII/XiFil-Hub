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
--// ✏️ TARUH SCRIPT GAME KAMU DI SINI
--------------------------------------------------------------------------------
startWithDRM(function(key, hwid)
    -- Script game kamu di sini
    -- Contoh:
    -- print("Key valid:", key)
    -- loadstring(game:HttpGet("https://raw.githubusercontent.com/.../script.lua"))()
end)

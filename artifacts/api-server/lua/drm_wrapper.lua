--------------------------------------------------------------------------------
--// XiFil DRM Wrapper — Taruh kode ini di PALING ATAS script utamamu
--// API Server: ganti SERVER_URL dengan URL Replit kamu
--------------------------------------------------------------------------------

local SERVER_URL  = "https://xifil-hub-production.up.railway.app"
local KEY_FILE    = "XiFilPro_Configs/license.key"
local FOLDER_NAME = "XiFilPro_Configs"

--------------------------------------------------------------------------------
--// HWID — Gabungkan beberapa pengenal unik mesin ini
--------------------------------------------------------------------------------
local function getHWID()
    local parts = {}

    -- 1. Client ID dari Roblox Analytics (unik per perangkat)
    local ok1, cid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok1 and cid and cid ~= "" then
        table.insert(parts, tostring(cid))
    end

    -- 2. UserId pemain (sebagai fallback tambahan)
    local ok2, uid = pcall(function()
        return tostring(game.Players.LocalPlayer.UserId)
    end)
    if ok2 and uid then table.insert(parts, uid) end

    -- 3. Nama executor sebagai salt ringan
    local ok3, execName = pcall(identifyexecutor)
    if ok3 and execName then
        table.insert(parts, execName:sub(1, 8))
    end

    local raw = table.concat(parts, "|")
    -- Hash sederhana agar tidak terlalu panjang
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
    if not isfolder(FOLDER_NAME) then
        pcall(makefolder, FOLDER_NAME)
    end
    if isfile(KEY_FILE) then
        local ok, content = pcall(readfile, KEY_FILE)
        if ok and content and content:match("%S") then
            return content:gsub("%s+", "") -- trim whitespace
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
        SERVER_URL,
        key,
        hwid
    )

    local ok, response = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not ok then
        return false, "Tidak bisa terhubung ke server. Coba lagi nanti."
    end

    local decoded
    local decOk, decErr = pcall(function()
        decoded = game:GetService("HttpService"):JSONDecode(response)
    end)

    if not decOk or not decoded then
        return false, "Respons server tidak valid."
    end

    if decoded.status == "success" then
        return true, decoded.message or "OK"
    else
        return false, decoded.message or "Key tidak valid."
    end
end

--------------------------------------------------------------------------------
--// INPUT KEY (GUI sederhana)
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
    title.Position = UDim2.new(0, 0, 0, 0)
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
        if #key < 10 then
            status.Text = "⚠ Key terlalu pendek."
            return
        end

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
--// ENTRY POINT UTAMA
--------------------------------------------------------------------------------
local function startWithDRM(mainScript)
    local hwid = getHWID()
    local savedKey = readKey()

    if savedKey then
        -- Coba validasi otomatis dengan key tersimpan
        local valid, msg = checkLicense(savedKey, hwid)
        if valid then
            mainScript(savedKey, hwid)
            return
        else
            -- Key tidak valid lagi, hapus dan minta ulang
            deleteKey()
        end
    end

    -- Tampilkan form input key
    promptKey(function(key, hwidUsed)
        mainScript(key, hwidUsed)
    end)
end

--------------------------------------------------------------------------------
--// PANGGIL startWithDRM DAN TARUH SELURUH SCRIPT UTAMA DI DALAMNYA
--// Contoh penggunaan — hapus bagian ini dan ganti dengan script aslimu:
--------------------------------------------------------------------------------
startWithDRM(function(key, hwid)
    -- ✅ Sampai sini berarti key sudah VALID
    -- Taruh seluruh isi SOUL_IRON_V2 (atau script lain) di sini
        --------------------------------------------------------------------------------
        --// MODERN OBJECT-ORIENTED & OPTIMIZED FRAMEWORK (TAB SYSTEM VERSION)
        --------------------------------------------------------------------------------
        local Services = setmetatable({}, {
            __index = function(self, key)
                local service = game:GetService(key)
                if service then self[key] = service end
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




        -- Master Global State Configuration (Encapsulated & Sync Bound)
        local EngineConfig = {
            AutoAttackActive = false,
            AutoSkillActive = false,        -- 🌟 TAMBAHAN BARU (Khusus Auto Skill)
            AutoWeaponSwitchActive = false, -- 🌟 TAMBAHAN BARU (Khusus Switcher Senjata)
            -- 🌟 SAVE DATA TAB 5 (ROOM HUB)
            RoomWorld = "World1",
            RoomMode = 1,
            RoomPlayers = 4,
            RoomTarget = "Room1",
              -- 🌟 SAVE DATA TAB 6 (AUTO BUY)
            AutoBuyActive = false,
            AutoBuyTargetList = {},
            AntiAFKActive = true,       -- 🌟 BARU: Menyimpan status Anti-AFK (Default: true)
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
            CFrameDelay = 0.001,
            PrioritizeChest = true,
            SelectedNormalNpcId = nil,
            SelectedBossNpcId = nil,
            HitMultiplier = 1,
            SellCategory = "All",
            AutoSellStaticList = {},
            IsLockDelay = false
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
            -- Ambil objek container UI asli dari dropdown
            local rawWorldUI = _G.RoomTargetWorldDropdown
            local rawCaveUI = _G.RoomTargetCaveDropdown
            local rawSeasonUI = _G.RoomTargetSeasonDropdown

            if rawWorldUI and rawCaveUI and rawSeasonUI then
                -- Sembunyikan semua dulu
                rawWorldUI.Visible = false
                rawCaveUI.Visible = false
                rawSeasonUI.Visible = false

                -- Filter berdasarkan text world yang dipilih
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
        --// REAL FILE CONFIG SYSTEM (Menggantikan Mockup Baris ~34)
        --------------------------------------------------------------------------------
        local HttpService = Services.HttpService
        local folderName = "XiFilPro_Configs"

        -- Membuat folder otomatis di direktori workspace PC Anda
        if not isfolder(folderName) then
            pcall(function() makefolder(folderName) end)
        end

        local ConfigSystem = {}

        function ConfigSystem.GetAutoLoadPointer()
            local path = folderName .. "/autoload_pointer.txt"
            if isfile(path) then
                local success, content = pcall(readfile, path)
                if success and content then return content end
            end
            return "None"
        end

        function ConfigSystem.SaveAutoLoadPointer(name)
            pcall(writefile, folderName .. "/autoload_pointer.txt", tostring(name))
        end

        function ConfigSystem.GetConfigList()
            local list = {"None"}
            local success, files = pcall(listfiles, folderName)

            if success and files then
                for _, filePath in ipairs(files) do
                    -- [PERBAIKAN] Mengunci regex agar HANYA membaca file yang berakhiran .json
                    local fileName = filePath:match("([^\\/]+)%.json$")

                    -- Jika file berformat .json dan bukan file autoload, masukkan ke daftar dropdown
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

            local success, encoded = pcall(HttpService.JSONEncode, HttpService, EngineConfig)
            if not success then return false, "Gagal konversi data konfigurasi." end

            local writeSuccess = pcall(writefile, path, encoded)
            if writeSuccess then
                return true
            else
                return false, "I/O Error: Gagal menulis ke berkas disk."
            end
        end

        function ConfigSystem.OverwriteExisting(name)
            return ConfigSystem.SaveNew(name) -- Logikanya sama dengan menimpa data baru
        end

        function ConfigSystem.Load(name, callback)
            if name == "None" then return false end
            local path = folderName .. "/" .. name .. ".json"

            if isfile(path) then
                local readSuccess, content = pcall(readfile, path)
                if readSuccess and content then
                    local decodeSuccess, data = pcall(HttpService.JSONDecode, HttpService, content)
                    if decodeSuccess and type(data) == "table" then
                        -- Menyuntikkan data yang tersimpan kembali ke EngineConfig utama
                        for key, value in pairs(data) do
                            if EngineConfig[key] ~= nil then
                                EngineConfig[key] = value
                            end
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
            if isfile(path) then
                local success = pcall(delfile, path)
                return success
            end
            return false
        end

        function ConfigSystem.ExecuteAutoLoad(callback)
            local target = ConfigSystem.GetAutoLoadPointer()
            if target and target ~= "None" then
                task.spawn(function()
                    task.wait(0.5) -- Jeda aman saat inject awal game
                    local success = ConfigSystem.Load(target, callback)
                    if success then
                        CustomNotify("⚡ AUTOLOAD SUCCESS", "Berhasil memuat profil: " .. target, 3)
                    end            
                end)
            end
        end




        -- Forward Declaration untuk komponen UI Toggle
        local ToggleControl = nil 
        local ReplayToggleControl = nil


        --------------------------------------------------------------------------------
        --// MAID/CLEANUP CLASS (Memory Leak Prevention)
        --------------------------------------------------------------------------------
        local Maid = {}
        Maid.__index = Maid

        function Maid.new()
            return setmetatable({ tasks = {} }, Maid)
        end

        function Maid:GiveTask(taskToGive)
            table.insert(self.tasks, taskToGive)
            return taskToGive
        end

        function Maid:DoCleaning()
            for _, taskItem in ipairs(self.tasks) do
                if type(taskItem) == "function" then
                    taskItem()
                elseif typeof(taskItem) == "RBXScriptConnection" then
                    taskItem:Disconnect()
                elseif type(taskItem) == "table" and taskItem.Destroy then
                    taskItem:Destroy()
                end
            end
            table.clear(self.tasks)
        end

        local RuntimeMaid = Maid.new()

        --------------------------------------------------------------------------------
        --// MODERN CUSTOM NOTIFICATION ENGINE (TWEEN SERVICE & AUTO-STACKING)
        --------------------------------------------------------------------------------
        local TweenService = Services.TweenService or game:GetService("TweenService")

        -- 1. Buat Container Utama untuk Notifikasi
        local NotifGui = Instance.new("ScreenGui")
        NotifGui.Name = "XiFil_ModernNotif"
        NotifGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        NotifGui.ResetOnSpawn = false
        RuntimeMaid:GiveTask(NotifGui)

        -- Container diletakkan di Kanan Bawah, dengan jarak dari tepi layar
        local NotifContainer = Instance.new("Frame")
        NotifContainer.Name = "Container"
        NotifContainer.Parent = NotifGui
        NotifContainer.BackgroundTransparency = 1
        NotifContainer.Size = UDim2.new(0, 260, 1, -120) -- Sisakan ruang 120px dari bawah layar
        NotifContainer.Position = UDim2.new(1, -280, 0, 0) -- Jarak 20px dari tepi kanan
        NotifContainer.ZIndex = 99999

        -- UIListLayout agar notifikasi bertumpuk rapi secara otomatis
        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Parent = NotifContainer
        ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        ListLayout.Padding = UDim.new(0, 10)
        ListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom -- Tumpuk dari bawah ke atas
        ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

        -- 2. Fungsi CustomNotify Modern
        local function CustomNotify(title, text, duration)
            duration = duration or 3

            -- Wrapper transparan agar tidak bertabrakan dengan UIListLayout saat dianimasikan
            local Wrapper = Instance.new("Frame")
            Wrapper.Name = "NotifWrapper"
            Wrapper.Parent = NotifContainer
            Wrapper.BackgroundTransparency = 1
            Wrapper.Size = UDim2.new(0, 260, 0, 60)

            -- Frame Visual Notifikasi
            local NotifFrame = Instance.new("Frame")
            NotifFrame.Parent = Wrapper
            NotifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
            NotifFrame.Size = UDim2.new(1, 0, 1, 0)
            NotifFrame.Position = UDim2.new(1, 50, 0, 0) -- Awal posisi di luar layar (ke kanan)
            NotifFrame.BackgroundTransparency = 1
            Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 6)

            -- Glowing Stroke
            local Stroke = Instance.new("UIStroke", NotifFrame)
            Stroke.Color = Color3.fromRGB(96, 205, 255)
            Stroke.Thickness = 1.2
            Stroke.Transparency = 1

            -- Accent Line (Garis biru di kiri yang dianimasikan)
            local Accent = Instance.new("Frame", NotifFrame)
            Accent.BackgroundColor3 = Color3.fromRGB(96, 205, 255)
            Accent.Size = UDim2.new(0, 3, 0, 0) -- Tinggi awal 0
            Accent.Position = UDim2.new(0, 12, 0.5, 0)
            Accent.AnchorPoint = Vector2.new(0, 0.5)
            Accent.BackgroundTransparency = 1
            Instance.new("UICorner", Accent).CornerRadius = UDim.new(1, 0)

            -- Judul Notifikasi
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

            -- Deskripsi Notifikasi
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

            -- 3. Animasi Masuk (Slide-In Kiri & Fade-In)
            local tweenInfoIn = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

            TweenService:Create(NotifFrame, tweenInfoIn, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.1}):Play()
            TweenService:Create(Stroke, tweenInfoIn, {Transparency = 0}):Play()
            TweenService:Create(TitleLbl, tweenInfoIn, {TextTransparency = 0}):Play()
            TweenService:Create(TextLbl, tweenInfoIn, {TextTransparency = 0}):Play()

            -- Efek garis aksen memanjang secara dinamis
            TweenService:Create(Accent, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 3, 1, -24), BackgroundTransparency = 0}):Play()

            -- 4. Logika Penghapusan Otomatis (Slide-Out Kanan)
            task.delay(duration, function()
                local tweenInfoOut = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

                TweenService:Create(NotifFrame, tweenInfoOut, {Position = UDim2.new(1, 50, 0, 0), BackgroundTransparency = 1}):Play()
                TweenService:Create(Stroke, tweenInfoOut, {Transparency = 1}):Play()
                TweenService:Create(TitleLbl, tweenInfoOut, {TextTransparency = 1}):Play()
                TweenService:Create(TextLbl, tweenInfoOut, {TextTransparency = 1}):Play()
                TweenService:Create(Accent, tweenInfoOut, {Size = UDim2.new(0, 3, 0, 0), BackgroundTransparency = 1}):Play()

                -- Perkecil ukuran wrapper menjadi 0 agar notifikasi lain turun dengan mulus
                TweenService:Create(Wrapper, tweenInfoOut, {Size = UDim2.new(0, 260, 0, 0)}):Play()

                task.wait(0.4)
                Wrapper:Destroy()
            end)
        end


        --------------------------------------------------------------------------------
        --// OPTIMIZED AUTO REPLAY & FARM SEQUENCE
        --------------------------------------------------------------------------------
        local function FireReplayRemote()
            -- Melakukan pengecekan ketat apakah fitur Auto Replay diaktifkan oleh user
            if EngineConfig.AutoReplayActive then
                print("[SYSTEM REPLAY] Sinyal kemenangan terdeteksi. Menyiapkan paket Replay...")

                -- Jeda aman sekian detik memberikan waktu server memproses data drop/hadiah Anda
                task.wait(1.0) 

                local success, err = pcall(function()
                    GameRoundRE:FireServer("VotePlayAgain")
                end)

                if success then
                    CustomNotify("🔄 AUTO REPLAY", "Sinyal 'VotePlayAgain' berhasil dikirim ke server!", 3)
                    print("[SYSTEM REPLAY] Sinyal VotePlayAgain sukses dieksekusi.")
                else
                    CustomNotify("⚠️ REPLAY ERROR", "Gagal menghubungi server remote.", 3)
                    warn("[SYSTEM REPLAY] Gagal FireServer: " .. tostring(err))
                end
            else
                print("[SYSTEM REPLAY] Auto Replay dilewati karena status: OFF")
            end
        end

        local function DisableAutoFarm(reason)
            if EngineConfig.AutoAttackActive then
                EngineConfig.AutoAttackActive = false

                -- Sinkronisasi visual toggle tombol agar kembali ke posisi OFF
                if ToggleControl and ToggleControl.SetValue then
                    ToggleControl:SetValue(false)
                elseif _G.FarmToggle and _G.FarmToggle.SetValue then
                    _G.FarmToggle:SetValue(false) -- Fallback sync menggunakan global pointer tab Anda
                end

                CustomNotify("🚨 AUTO OFF", "Farm selesai: " .. reason, 4)
                print("[SYSTEM UI] Auto Farm dinonaktifkan secara otomatis. Alasan: " .. reason)

                -- Berjalan secara Asynchronous (Menggunakan task.spawn agar tidak mengunci thread utama game)
                if reason:find("Victory") or reason:find("Ui Found") or reason:find("Screen Detected") then
                    task.spawn(FireReplayRemote)
                end
            end
        end


        local function isVictoryText(obj)
            if not obj or not obj:IsA("TextLabel") then return false end
            if not obj.Visible or obj.AbsoluteSize.X == 0 or obj.TextTransparency >= 1 then 
                return false 
            end

            local text = obj.Text:upper()
            if (obj.Name == "FirstClear" and text:find("FIRST CLEAR")) or (obj.Name == "Text" and text:find("VICTORY")) then
                local current = obj.Parent
                while current and not current:IsA("ScreenGui") do
                    if current:IsA("GuiObject") and not current.Visible then
                        return false 
                    end
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
                if isVictoryText(desc) then
                    return true
                end
            end
            return false
        end

        local uiConnection = LocalPlayer:WaitForChild("PlayerGui").DescendantAdded:Connect(function(desc)
            task.wait(0.2)
            if isVictoryText(desc) then
                DisableAutoFarm("Victory Screen Detected (Real-time Match)")
            end
        end)
        RuntimeMaid:GiveTask(uiConnection)

        --------------------------------------------------------------------------------
        --// BACKEND CORE ENGINE (Object-Oriented & Performance Optimized)
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
            if obj and (obj:IsA("StringValue") or obj:IsA("IntValue")) then
                return tostring(obj.Value):lower()
            end

            if monster:FindFirstChild("BossTag") or string.find(string.lower(monster.Name), "boss") then
                return "boss"
            end
            return "normal"
        end

        function CombatEngine.GetNpcId(monster)
            local attr = monster:GetAttribute("NpcId")
            if attr then return tostring(attr) end

            local obj = monster:FindFirstChild("NpcId")
            if obj and (obj:IsA("StringValue") or obj:IsA("IntValue") or obj:IsA("NumberValue")) then
                return tostring(obj.Value)
            end
            return monster.Name
        end

        function CombatEngine.GetValidChests()
            local chests = {}
            local children = Workspace:GetChildren()
            for i = 1, #children do
                local obj = children[i]
                if obj.Name:find("Chest") then
                    local root = obj:FindFirstChild("Root") or obj:FindFirstChild("Part") or (obj:IsA("Model") and obj.PrimaryPart)
                    if root then
                        table.insert(chests, {Object = obj, Root = root})
                    end
                end
            end
            return chests
        end

        function CombatEngine.GetValidMonsters()
            local enemyFolder = Workspace:FindFirstChild("EnemyNpc")
            if not enemyFolder then return {} end

            local normalMonsters = {}
            local priorityMonsters = {}
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
            -- Jika PrioritizeChest AKTIF, cek keberadaan Chest dan Monster
            if EngineConfig.PrioritizeChest then
                return (#CombatEngine.GetValidChests() > 0 or #CombatEngine.GetValidMonsters() > 0)
            else
                -- Jika PrioritizeChest OFF, abaikan Chest total dan hanya cek apakah Monster masih ada
                return (#CombatEngine.GetValidMonsters() > 0)
            end
        end


        --------------------------------------------------------------------------------
        --// SYSTEM RECONCILIATION: MAP NAVIGATION & EMERGENCY SEQUENCES (RESOLVED)
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

        -- Menambahkan penanganan aman terhadap parameter worldContext.
        -- Menerapkan perbandingan string secara ketat (==) pada World 1 & 2 untuk mencegah salah target 
        -- ke objek dekoratif langit, serta mempertahankan pencocokan pola khusus untuk World 3.
        function Navigation.GetSingleClosestPortal(portalName, myPosition, worldContext)
            local roundDoor = Workspace:FindFirstChild("RoundDoor")
            if not roundDoor then return nil end

            local closestPortalRoot = nil
            local shortestDistance = math.huge
            local children = roundDoor:GetChildren()

            -- Penapisan aman untuk mengantisipasi nilai parameter kosong (nil)
            local activeContext = worldContext or EngineConfig.SelectedWorld

            for i = 1, #children do
                local obj = children[i]
                local isMatch = false

                if activeContext == "World 3" then
                    -- Mempertahankan pola penamaan dinamis untuk World 3
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


        function Navigation.ExecuteEmergencyOrbitWorld1(myHRP, myHum)
            -- [INSTANT CHECK] Jika saat dipanggil ternyata UI sudah berubah, langsung batalkan!
            if EngineConfig.SelectedWorld ~= "World 1" then return end

            myHum.PlatformStand = true
            print("[SYSTEM W1] Room vacant! Searching fallback nodes...")

            local door = Navigation.GetClosestObject("RoundDoor", "Door", myHRP.Position)
            if door then
                CombatEngine.ResetPhysics(myHRP)
                myHRP.CFrame = door:IsA("Model") and door:GetPivot() or door.CFrame

                local interrupted = CombatEngine.InterruptableStall(0.5, function()
                    -- Interrupsi ditambahkan pengecekan SelectedWorld
                    return not EngineConfig.AutoAttackActive or CombatEngine.TargetsExistGlobal() or checkVictoryUi() or EngineConfig.SelectedWorld ~= "World 1"
                end)
                if interrupted or CombatEngine.TargetsExistGlobal() or EngineConfig.SelectedWorld ~= "World 1" then return end
            end

            local centerPosition = myHRP.Position 
            local steps = 50 
            local orbitTiers = {50, 150, 250}

            for tierIndex, currentRadius in ipairs(orbitTiers) do
                if CombatEngine.TargetsExistGlobal() or not EngineConfig.AutoAttackActive or checkVictoryUi() or EngineConfig.SelectedWorld ~= "World 1" then return end
                print("[SYSTEM W1] Executing Orbit Tier " .. tierIndex .. " with Radius: " .. currentRadius)

                local lastOrbitCFrame = nil
                for i = 1, steps do
                    -- Interrupsi instan di dalam loop pergerakan derajat orbit
                    if not EngineConfig.AutoAttackActive or CombatEngine.TargetsExistGlobal() or checkVictoryUi() or EngineConfig.SelectedWorld ~= "World 1" then return end

                    local angle = (i / steps) * (math.pi * 2) 
                    local targetPos = centerPosition + Vector3.new(math.cos(angle) * currentRadius, 0, math.sin(angle) * currentRadius)

                    CombatEngine.ResetPhysics(myHRP)
                    lastOrbitCFrame = CFrame.new(targetPos, centerPosition)
                    myHRP.CFrame = lastOrbitCFrame
                    Services.RunService.Heartbeat:Wait()
                end

                if lastOrbitCFrame then
                    local orbitStalled = CombatEngine.InterruptableStall(2, function()
                        if not EngineConfig.AutoAttackActive or CombatEngine.TargetsExistGlobal() or checkVictoryUi() or EngineConfig.SelectedWorld ~= "World 1" then return true end
                        CombatEngine.ResetPhysics(myHRP)
                        myHRP.CFrame = lastOrbitCFrame 
                    end)
                    if orbitStalled or CombatEngine.TargetsExistGlobal() or EngineConfig.SelectedWorld ~= "World 1" then return end
                end
            end

            local finalCFrame = myHRP.CFrame
            local isInterrupted = CombatEngine.InterruptableStall(5, function()
                if not EngineConfig.AutoAttackActive or CombatEngine.TargetsExistGlobal() or checkVictoryUi() or EngineConfig.SelectedWorld ~= "World 1" then return true end
                CombatEngine.ResetPhysics(myHRP)
                myHRP.CFrame = finalCFrame
            end)
            if isInterrupted or CombatEngine.TargetsExistGlobal() or EngineConfig.SelectedWorld ~= "World 1" then return end

            local portal = Navigation.GetClosestObject("RoundDoor", "Portal", myHRP.Position) or Navigation.GetClosestObject("Workspace", "Portal", myHRP.Position)
            if portal then
                CombatEngine.ResetPhysics(myHRP)
                myHRP.CFrame = portal:IsA("Model") and portal:GetPivot() or portal.CFrame

                local portalCFrame = myHRP.CFrame
                CombatEngine.InterruptableStall(3, function()
                    if not EngineConfig.AutoAttackActive or CombatEngine.TargetsExistGlobal() or checkVictoryUi() or EngineConfig.SelectedWorld ~= "World 1" then return true end
                    CombatEngine.ResetPhysics(myHRP)
                    myHRP.CFrame = portalCFrame
                end)
                if CombatEngine.TargetsExistGlobal() or not EngineConfig.AutoAttackActive or EngineConfig.SelectedWorld ~= "World 1" then return end
            end

            if EngineConfig.AutoAttackActive and not CombatEngine.TargetsExistGlobal() and EngineConfig.SelectedWorld == "World 1" then
                local idleCFrame = myHRP.CFrame
                CombatEngine.InterruptableStall(115, function()
                    if not EngineConfig.AutoAttackActive or CombatEngine.TargetsExistGlobal() or checkVictoryUi() or EngineConfig.SelectedWorld ~= "World 1" then return true end
                    CombatEngine.ResetPhysics(myHRP)
                    myHRP.CFrame = idleCFrame
                end)
            end
        end

        function Navigation.ExecuteEmergencySequenceWorld2(myHRP, myHum)
            if EngineConfig.SelectedWorld ~= "World 2" then return end

            EngineConfig.IsLockDelay = true
            myHum.PlatformStand = true

            local function globalBreakCondition()
                return not EngineConfig.AutoAttackActive or CombatEngine.TargetsExistGlobal() or checkVictoryUi() or EngineConfig.SelectedWorld ~= "World 2"
            end

            if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false return end

            local portalDCF = Navigation.GetSingleClosestPortal("PortalD", myHRP.Position, "World 2")
            if portalDCF and not globalBreakCondition() then 
                CombatEngine.ResetPhysics(myHRP)
                myHRP.CFrame = portalDCF 
                task.wait(0.1) 
            end

            if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false return end
            if CombatEngine.TargetsExistGlobal() or EngineConfig.SelectedWorld ~= "World 2" then EngineConfig.IsLockDelay = false return end

            if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false return end

            local portalCF = Navigation.GetSingleClosestPortal("Portal", myHRP.Position, "World 2")
            if portalCF and not globalBreakCondition() then 
                CombatEngine.ResetPhysics(myHRP)
                myHRP.CFrame = portalCF 
                task.wait(0.1) 
            end

            if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false return end

            EngineConfig.IsLockDelay = false
            if CombatEngine.TargetsExistGlobal() or not EngineConfig.AutoAttackActive or EngineConfig.SelectedWorld ~= "World 2" then return end

            if EngineConfig.AutoAttackActive and not CombatEngine.TargetsExistGlobal() and EngineConfig.SelectedWorld == "World 2" then
                EngineConfig.IsLockDelay = true
                CombatEngine.InterruptableStall(115, function()
                    if globalBreakCondition() then return true end
                    CombatEngine.ResetPhysics(myHRP)
                end)
                EngineConfig.IsLockDelay = false
            end
        end

        function Navigation.ExecuteEmergencySequenceWorld3(myHRP, myHum)
            if EngineConfig.SelectedWorld ~= "World 3" then return end

            EngineConfig.IsLockDelay = true
            myHum.PlatformStand = true

            local function globalBreakCondition()
                return not EngineConfig.AutoAttackActive or CombatEngine.TargetsExistGlobal() or checkVictoryUi() or EngineConfig.SelectedWorld ~= "World 3"
            end

            if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false return end

            local closestPortalCF = Navigation.GetSingleClosestPortal("Portal", myHRP.Position, "World 3")
            if closestPortalCF and not globalBreakCondition() then 
                CombatEngine.ResetPhysics(myHRP)
                myHRP.CFrame = closestPortalCF 
                task.wait(0.1) 
            end

            if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false return end

            EngineConfig.IsLockDelay = false
            if CombatEngine.TargetsExistGlobal() or not EngineConfig.AutoAttackActive or EngineConfig.SelectedWorld ~= "World 3" then return end

            if EngineConfig.AutoAttackActive and not CombatEngine.TargetsExistGlobal() and EngineConfig.SelectedWorld == "World 3" then
                EngineConfig.IsLockDelay = true
                CombatEngine.InterruptableStall(115, function()
                    if globalBreakCondition() then return true end
                    CombatEngine.ResetPhysics(myHRP)
                end)
                EngineConfig.IsLockDelay = false
            end
        end


        --------------------------------------------------------------------------------
        --// CORE INFINITE LOOP PROCESSOR (PROPERTIES DRIVEN) - FIX CHEST EXCLUSION
        --------------------------------------------------------------------------------
        function startInfiniteDistanceLoop()
            local noTargetTimerW1 = 0

            while EngineConfig.AutoAttackActive do
                if checkVictoryUi() then
                    DisableAutoFarm("Victory UI Found during loop cycle")
                    break
                end

                local char = LocalPlayer.Character
                local myHRP = char and char:FindFirstChild("HumanoidRootPart")
                local myHum = char and char:FindFirstChildOfClass("Humanoid")
                local enemyFolder = Workspace:FindFirstChild("EnemyNpc")

                if myHRP and myHum then
                    local chests = CombatEngine.GetValidChests()
                    local monsters = enemyFolder and CombatEngine.GetValidMonsters() or {}

                    -- Sinkronisasi PlatformStand berdasarkan status AutoCFrame
                    if EngineConfig.AutoCFrame then
                        myHum.PlatformStand = true
                    else
                        myHum.PlatformStand = false
                    end

                    -- [FIX] Sinkronisasi Deteksi Global saat World 2 Lock Delay
                    if EngineConfig.SelectedWorld == "World 2" and EngineConfig.IsLockDelay and not CombatEngine.TargetsExistGlobal() then
                        CombatEngine.ResetPhysics(myHRP)
                        Services.RunService.Heartbeat:Wait()

                    -- KONDISI 1: Hanya targetkan Chest jika Chest ada DAN sakelar PrioritizeChest AKTIF (ON)
                    elseif #chests > 0 and EngineConfig.PrioritizeChest then
                        EngineConfig.IsLockDelay = false
                        noTargetTimerW1 = 0
                        local targetChest = chests[1]
                        local chestRoot = targetChest.Root

                        if chestRoot and chestRoot:IsA("BasePart") then
                            if EngineConfig.AutoCFrame then
                                CombatEngine.ResetPhysics(myHRP)
                                local angle = tick() * EngineConfig.OrbitSpeed
                                myHRP.CFrame = CFrame.new(chestRoot.Position + Vector3.new(math.cos(angle) * EngineConfig.OrbitRadius, EngineConfig.StandHeight, math.sin(angle) * EngineConfig.OrbitRadius), chestRoot.Position)
                            end

                            local targetCF = chestRoot.CFrame
                            for i = 1, EngineConfig.HitMultiplier do 
                                task.defer(function() PlayerActionRE:FireServer("SkillAction", "BaseAttack", 3, targetCF) end) 
                            end
                            task.wait(EngineConfig.CFrameDelay)
                        else 
                            Services.RunService.Heartbeat:Wait()
                        end

                    -- KONDISI 2: Menyerang Monster (Akan langsung dipicu jika PrioritizeChest OFF atau Chest habis)
                    elseif #monsters > 0 then
                        EngineConfig.IsLockDelay = false
                        noTargetTimerW1 = 0
                        local currentTarget = monsters[1]

                        if currentTarget then
                            local tPart = currentTarget:FindFirstChild("HumanoidRootPart") or currentTarget.PrimaryPart
                            local tHum = currentTarget:FindFirstChildOfClass("Humanoid")

                            if tPart and (not tHum or tHum.Health > 0) then
                                local currentHeight = EngineConfig.StandHeight
                                if CombatEngine.GetLevelType(currentTarget) == "boss" then
                                    currentHeight = 25
                                end

                                if EngineConfig.AutoCFrame then
                                    CombatEngine.ResetPhysics(myHRP)
                                    local angle = tick() * EngineConfig.OrbitSpeed
                                    myHRP.CFrame = CFrame.new(tPart.Position + Vector3.new(math.cos(angle) * EngineConfig.OrbitRadius, currentHeight, math.sin(angle) * EngineConfig.OrbitRadius), tPart.Position)
                                end

                                local targetCF = tPart.CFrame
                                for i = 1, EngineConfig.HitMultiplier do 
                                    task.defer(function() PlayerActionRE:FireServer("SkillAction", "BaseAttack", 3, targetCF) end) 
                                end
                                task.wait(EngineConfig.CFrameDelay)
                            else 
                                Services.RunService.Heartbeat:Wait() 
                            end
                        else 
                            Services.RunService.Heartbeat:Wait() 
                        end

                    -- KONDISI 3: Ruangan Kosong / Target Habis -> Jalankan Emergency Sequence secara Normal
                             else
                        -- Penanganan Ruangan Kosong berdasarkan Pilihan World (INSTANT SWITCHED)
                        if EngineConfig.AutoCFrame then
                            if EngineConfig.SelectedWorld == "World 1" then
                                noTargetTimerW1 = noTargetTimerW1 + 0.1
                                if noTargetTimerW1 >= 3 then
                                    noTargetTimerW1 = 0
                                    Navigation.ExecuteEmergencyOrbitWorld1(myHRP, myHum)
                                end
                                task.wait(0.1)
                            elseif EngineConfig.SelectedWorld == "World 2" then
                                noTargetTimerW1 = 0 -- Reset timer world 1 agar tidak bentrok saat balik
                                Navigation.ExecuteEmergencySequenceWorld2(myHRP, myHum)
                                task.wait(0.1)
                            elseif EngineConfig.SelectedWorld == "World 3" then
                                noTargetTimerW1 = 0 -- Reset timer world 1 agar tidak bentrok saat balik
                                Navigation.ExecuteEmergencySequenceWorld3(myHRP, myHum)
                                task.wait(0.1)
                            end
                        else
                            Services.RunService.Heartbeat:Wait()
                        end
                    end

                else
                    task.wait(0.1)
                end
            end

            pcall(function()
                local char = LocalPlayer.Character
                local myHum = char and char:FindFirstChildOfClass("Humanoid")
                if myHum then myHum.PlatformStand = false end
            end)
            EngineConfig.IsLockDelay = false
        end


        -- Tambahkan variabel ini di bawah EngineConfig
        local BulkSelectedUUIDs = {} 

        -- Letakkan fungsi sellSpesifikNamaItem dan runCoreNotificationEngine di sini
        local function runCoreNotificationEngine(parentFrame, filterCategory)
            -- 1. Bersihkan hasil scan sebelumnya
            for _, child in ipairs(parentFrame:GetChildren()) do
                if child.Name == "ItemResult" then child:Destroy() end
            end

            -- 2. Mockup Data (Ganti path ini dengan path folder Inventory/Equipment asli di game Anda)
            local inventory = {} 

            -- 3. Loop item dan buat tombolnya
            for _, item in ipairs(inventory) do
                -- Filter kategori (Contoh logika)
                if filterCategory == "All" or item:GetAttribute("Category") == filterCategory then

                    local ItemBtn = Instance.new("TextButton")
                    ItemBtn.Name = "ItemResult"
                    ItemBtn.Parent = parentFrame
                    ItemBtn.Size = UDim2.new(1, -10, 0, 30)
                    ItemBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                    ItemBtn.Text = item.Name -- Nama item
                    ItemBtn.TextColor3 = Color3.new(1, 1, 1)

                    ItemBtn.MouseButton1Click:Connect(function()
                        -- Masukkan ke BulkSelectedUUIDs jika diklik
                        if not BulkSelectedUUIDs[item.Name] then
                            BulkSelectedUUIDs[item.Name] = true
                            ItemBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0) -- Indikator terpilih
                        else
                            BulkSelectedUUIDs[item.Name] = nil
                            ItemBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50) -- Normal
                        end
                    end)
                    Instance.new("UICorner", ItemBtn)
                end
            end
        end


        --------------------------------------------------------------------------------
        --// EXTRA LOGIC: SEPARATED AUTO SKILL & WEAPON SWITCHER ENGINE
        --------------------------------------------------------------------------------

        -- LOOP 1: Khusus Eksekusi Rangkaian Combo Skill (Berjalan mandiri)
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

                    -- Jeda 1 detik sebelum mengulang rangkaian skill (bisa disesuaikan)
                    task.wait(5) 
                else
                    task.wait(0.5)
                end
            end
        end)

        -- LOOP 2: Khusus Switcher Senjata Setiap 3 Detik (Berjalan mandiri)
        task.spawn(function()
            while true do
                if EngineConfig.AutoWeaponSwitchActive then
                    pcall(function() EquipmentRE:FireServer("ChangeWeaponSlot") end)
                    task.wait(3) -- Mengunci ritme ganti senjata tepat setiap 3 detik
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
            topbar.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
            Services.UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and dragToggle then
                    local delta = input.Position - dragStart
                    obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
        end

        -- MAIN BACKGROUND FRAME (Modern Dark Theme)
        local MainWindow = Instance.new("Frame")
        MainWindow.Name = "MainFrame"
        MainWindow.Parent = CoreGui
        MainWindow.BackgroundColor3 = Color3.fromRGB(15, 15, 20) -- Lebih gelap dan solid
        MainWindow.Position = UDim2.new(0.5, -250, 0.5, -180)
        MainWindow.Size = UDim2.new(0, 500, 0, 380) -- Sedikit lebih lebar untuk layout modern
        MainWindow.Visible = false
        Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 10)

        -- Glowing Modern Stroke
        local MainStroke = Instance.new("UIStroke", MainWindow)
        MainStroke.Color = Color3.fromRGB(96, 205, 255)
        MainStroke.Transparency = 0.5
        MainStroke.Thickness = 1.5

        -- TOP DRAGGABLE BAR
        local TopBar = Instance.new("Frame")
        TopBar.Name = "TopBar"
        TopBar.Parent = MainWindow
        TopBar.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
        TopBar.Size = UDim2.new(1, 0, 0, 38)
        TopBar.BorderSizePixel = 0
        Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
        MakeDraggable(TopBar, MainWindow)

        -- Menyembunyikan sudut bawah topbar agar menyatu dengan body
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

        -- 🛠️ TAB SYSTEM CONTAINERS SETUP
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
            -- Button UI
            local tabBtn = Instance.new("TextButton")
            tabBtn.Name = tabName .. "TabBtn"
            tabBtn.Parent = TabSystemFrame
            tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            tabBtn.BackgroundTransparency = 1 -- Default transparan untuk efek modern
            tabBtn.Size = UDim2.new(1, -16, 0, 32)
            tabBtn.Font = Enum.Font.GothamSemibold
            tabBtn.Text = "  " .. tabName
            tabBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
            tabBtn.TextSize = 12
            tabBtn.TextXAlignment = Enum.TextXAlignment.Left
            tabBtn.LayoutOrder = layoutOrder
            Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 6)

            -- Accent Indicator (Garis biru di kiri saat aktif)
            local Indicator = Instance.new("Frame", tabBtn)
            Indicator.Name = "Indicator" -- 🔥 INI FIX-NYA (Nama harus di-set) 🔥
            Indicator.Size = UDim2.new(0, 3, 0.6, 0)
            Indicator.Position = UDim2.new(0, -8, 0.2, 0)
            Indicator.BackgroundColor3 = Color3.fromRGB(96, 205, 255)
            Indicator.Visible = false
            Instance.new("UICorner", Indicator).CornerRadius = UDim.new(1, 0)

                -- Scrolling Canvas Page UI
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

            -- Mencegah Scrollbar menimpa UI di sebelah kanan
            pageScroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar

            local list = Instance.new("UIListLayout")
            list.Parent = pageScroll
            list.Padding = UDim.new(0, 8)
            list.SortOrder = Enum.SortOrder.LayoutOrder

            local padding = Instance.new("UIPadding", pageScroll)
            -- Memberikan ruang agar UIStroke (garis luar) tidak terpotong
            padding.PaddingLeft = UDim.new(0, 4) 
            padding.PaddingRight = UDim.new(0, 8)
            padding.PaddingTop = UDim.new(0, 4)
            padding.PaddingBottom = UDim.new(0, 10)


            -- Switch Tab Logic Function
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
        --// MODULAR COMPONENT GENERATOR UTILITIES (MODERNIZED)
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
                -- Simple Tweening effect (Fallback to basic positioning if TweenService not used)
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
            -- Logika sama dengan Input, hanya diperbarui desain kontainernya
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
            for i, v in ipairs(list) do if v == default then currentIndex = i break end end

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

            local layout = Instance.new("UIListLayout")
            layout.Parent = scrollList
            layout.SortOrder = Enum.SortOrder.LayoutOrder

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




        -- INIZIALIZE ALL PAGES INSIDE CONTAINER
        local MainFarmPage = CreateTab("🏠 Main Farm", 1)
        local VectorPage   = CreateTab("⚙️ Vector", 2)
        local ProfilePage  = CreateTab("💾 Profile", 3)


        --------------------------------------------------------------------------------
        -- [TAB 1]: MAIN FARM PAGE COMPONENTS
        --------------------------------------------------------------------------------
        CreateSection(MainFarmPage, "Farming Engine Basics")

        _G.WorldDropdown = CreateCycleUI(MainFarmPage, "Target Realm/World", {"World 1", "World 2", "World 3"}, EngineConfig.SelectedWorld, function(v) 
            EngineConfig.SelectedWorld = v 
        end)

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

        _G.ReplayToggle = CreateToggleUI(MainFarmPage, "Auto Play Again (Replay)", EngineConfig.AutoReplayActive, function(v) 
            EngineConfig.AutoReplayActive = v 
        end)

        _G.AutoSkillToggle = CreateToggleUI(MainFarmPage, "Auto Skill Execution", EngineConfig.AutoSkillActive, function(v)
            EngineConfig.AutoSkillActive = v
            CustomNotify("⚔️ SKILL ENGINE", v and "Auto Skill AKTIF!" , 2)
        end)

        _G.AutoSwitchToggle = CreateToggleUI(MainFarmPage, "Weapon Switcher (3s)", EngineConfig.AutoWeaponSwitchActive, function(v)
            EngineConfig.AutoWeaponSwitchActive = v
            CustomNotify("🎒 WEAPON SYSTEM", v and "Switcher AKTIF!" , 2)
        end)


        --------------------------------------------------------------------------------
        -- [TAB 2]: VECTOR CONFIG PAGE COMPONENTS
        --------------------------------------------------------------------------------
        CreateSection(VectorPage, "Kinematic System Parameters")

        _G.ChestToggle = CreateToggleUI(VectorPage, "Prioritize Valid Chests", EngineConfig.PrioritizeChest, function(v) EngineConfig.PrioritizeChest = v end)
        _G.HeightInput = CreateInputUI(VectorPage, "Flight Elevation Height (Y)", EngineConfig.StandHeight, true, function(v) EngineConfig.StandHeight = tonumber(v) or 10 end)

        _G.RadiusInput = CreateInputUI(VectorPage, "Orbit Structural Radius", EngineConfig.OrbitRadius, true, function(v) EngineConfig.OrbitRadius = tonumber(v) or 15 end)
        CreateButton(VectorPage, "🎯 Macro: Short Range Vector (20)", function() EngineConfig.OrbitRadius = 20; _G.RadiusInput:SetValue(20) end)
        CreateButton(VectorPage, "🎯 Macro: Long Range Vector (200)", function() EngineConfig.OrbitRadius = 200; _G.RadiusInput:SetValue(200) end)

        _G.SpeedInput = CreateInputUI(VectorPage, "Kinematic Rotation Speed", EngineConfig.OrbitSpeed, true, function(v) EngineConfig.OrbitSpeed = tonumber(v) or 25 end)
        _G.CFrameToggle = CreateToggleUI(VectorPage, "Active Axis Kinematics", EngineConfig.AutoCFrame, function(v) EngineConfig.AutoCFrame = v end)
        _G.DelayInput = CreateInputUI(VectorPage, "Network Throttling Latency", EngineConfig.CFrameDelay, false, function(v) EngineConfig.CFrameDelay = tonumber(v) or 0.01 end)

        CreateSection(VectorPage, "Network Injections")
        _G.MultiplierInput = CreateInputUI(VectorPage, "Burst Injections Per Frame", EngineConfig.HitMultiplier, true, function(v) EngineConfig.HitMultiplier = tonumber(v) or 1 end)

        --------------------------------------------------------------------------------
        -- [TAB 3]: PROFILE PAGE COMPONENTS (PROFILES DRIVEN)
        --------------------------------------------------------------------------------
        CreateSection(ProfilePage, "Data Optimization Profiles")

        local selectedConfig = "None"
        local newConfigName = ""
        local currentAutoLoadTarget = ConfigSystem.GetAutoLoadPointer()

        local ConfigDropdown = nil 

        -- Visual Synchronization Callback
        local function SyncAllVisualUI()
            pcall(function()

          if _G.SellCategoryDropdown and _G.SellCategoryDropdown.SetValue then 
                    _G.SellCategoryDropdown:SetValue(EngineConfig.SellCategory) 
                end

        --------------------------------------------------------------------------------
        -- [TAB 5]: ROOM HUB PAGE (COMPREHENSIVE MATCHMAKING ENGINE)
        --------------------------------------------------------------------------------
        local RoomPage = CreateTab("🚪 Room Hub", 5)

        -- Refrensi Remote Baru dari User
        local WorldPlaceRE = Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Gameplay"):WaitForChild("WorldPlace"):WaitForChild("WorldUtil"):WaitForChild("RemoteEvent")
        local GameMatchRE = Services.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("GameMatchRE")

        CreateSection(RoomPage, "Matchmaking Control")

        -- Custom Status Label UI untuk menampilkan Mode Aktif
        local statusLblContainer = Instance.new("Frame")
        statusLblContainer.Parent = RoomPage
        statusLblContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        statusLblContainer.Size = UDim2.new(1, 0, 0, 30)
        Instance.new("UICorner", statusLblContainer).CornerRadius = UDim.new(0, 4)

        local statusLbl = Instance.new("TextLabel")
        statusLbl.Parent = statusLblContainer
        statusLbl.Size = UDim2.new(1, 0, 1, 0)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Font = Enum.Font.GothamBold
        statusLbl.TextSize = 12

        -- Fungsi Global untuk Update Label Status & Sinkronisasi Dunia ke Server
        _G.UpdateRoomStatusLabel = function(mode)
            if mode <= 5 then
                statusLbl.Text = "Aktif: Normal (" .. mode .. ")"
                statusLbl.TextColor3 = Color3.fromRGB(0, 255, 127) -- Hijau
            else
                statusLbl.Text = "Aktif: Hell (" .. mode .. ")"
                statusLbl.TextColor3 = Color3.fromRGB(255, 64, 64) -- Merah
            end

            -- [AUTOMATION] Kirim sinyal perubahan World & Mode ke Server secara real-time
            task.spawn(function()
                pcall(function()
                    WorldPlaceRE:FireServer("SelectWorld", EngineConfig.RoomWorld, mode)
                end)
            end)
        end

        -- Forward declaration untuk dropdown room tunggal
        local RoomTargetDropdown = nil

        -- Pemetaan opsi room berdasarkan kategori World yang dipilih
        local RoomMapping = {
            ["World1"] = {"Room1", "Room2", "Room3", "Room4"},
            ["World2"] = {"Room1", "Room2", "Room3", "Room4"},
            ["World3"] = {"Room1", "Room2", "Room3", "Room4"},
            ["Cave1"]  = {"Room5", "Room6", "Room7", "Room8"},
            ["Cave2"]  = {"Room5", "Room6", "Room7", "Room8"},
            ["Season1"] = {"Room9", "Room10", "Room11", "Room12"}
        }

        -- Dropdown Utama World
        _G.RoomWorldDropdown = CreateDropdownUI(RoomPage, "Pilih World", {
            "World1", "World2", "World3", 
            "Cave1", "Cave2", 
            "Season1"
        }, EngineConfig.RoomWorld, function(val)
            EngineConfig.RoomWorld = val

            -- Sinkronisasi otomatis saat dropdown world diganti
            _G.UpdateRoomStatusLabel(EngineConfig.RoomMode)

            -- Perbarui opsi pada Dropdown Room Tunggal secara dinamis
            local availableRooms = RoomMapping[val] or {"Room1"}
            if RoomTargetDropdown and RoomTargetDropdown.SetValues then
                RoomTargetDropdown:SetValues(availableRooms)
                EngineConfig.RoomTarget = availableRooms[1]
            end
        end)

        _G.RoomModeNormalDropdown = CreateDropdownUI(RoomPage, "Mode Normal", {1, 2, 3, 4, 5}, (EngineConfig.RoomMode <= 5 and EngineConfig.RoomMode or 1), function(val)
            EngineConfig.RoomMode = tonumber(val)
            _G.UpdateRoomStatusLabel(EngineConfig.RoomMode)
        end)

        _G.RoomModeHellDropdown = CreateDropdownUI(RoomPage, "Mode Hell", {6, 7, 8, 9, 10}, (EngineConfig.RoomMode > 5 and EngineConfig.RoomMode or 6), function(val)
            EngineConfig.RoomMode = tonumber(val)
            _G.UpdateRoomStatusLabel(EngineConfig.RoomMode)
        end)

        _G.RoomPlayersDropdown = CreateDropdownUI(RoomPage, "Jumlah Player", {1, 2, 3, 4}, EngineConfig.RoomPlayers, function(val)
            EngineConfig.RoomPlayers = tonumber(val)
        end)

        -- 🌟 SATU DROPDOWN ROOM TUNGGAL (Filter Otomatis)
        local initialRooms = RoomMapping[EngineConfig.RoomWorld] or {"Room1"}
        RoomTargetDropdown = CreateDropdownUI(RoomPage, "Pilih Target Room", initialRooms, EngineConfig.RoomTarget or initialRooms[1], function(val)
            EngineConfig.RoomTarget = val
        end)

        -- Sinkronisasi pointer agar profile saver (Tab 3) tidak mengalami error nil pointer
        _G.RoomTargetWorldDropdown = RoomTargetDropdown 

        CreateSection(RoomPage, "Match Actions")

        -- 🌟 1. TOMBOL CREATE ROOM (Dinamis Berdasarkan Data UI)
        CreateButton(RoomPage, "🛠️ Create Room", function()
            pcall(function()
                GameMatchRE:FireServer(
                    "CreatRoom",
                    EngineConfig.RoomWorld,
                    EngineConfig.RoomMode,
                    EngineConfig.RoomPlayers
                )
                CustomNotify("MATCHMAKING", "Membuat room: " .. EngineConfig.RoomWorld .. " [M:" .. EngineConfig.RoomMode .. "]", 3)
            end)
        end)

        -- 🌟 2. TOMBOL TP ROOM (Teleport & Touch Interaction Part)
        CreateButton(RoomPage, "🚀 Tp Room", function()
            local targetRoomName = EngineConfig.RoomTarget or "Room1"

            local matchRoomFolder = Workspace:FindFirstChild("MatchRoom")
            local targetRoomFrame = matchRoomFolder and matchRoomFolder:FindFirstChild(targetRoomName)
            local touchModel = targetRoomFrame and targetRoomFrame:FindFirstChild("Touch")
            local targetPart = touchModel and touchModel:FindFirstChild("Part")

            if targetPart and targetPart:IsA("BasePart") then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")

                if hrp then
                    CombatEngine.ResetPhysics(hrp)
                    hrp.CFrame = targetPart.CFrame

                    -- Menembakkan fungsi sentuh bawaan exploit agar sistem game mendeteksi injakan player
                    if firetouchinterest then
                        firetouchinterest(targetPart, hrp, 0)
                        task.wait(0.1)
                        firetouchinterest(targetPart, hrp, 1)
                    end

                    CustomNotify("ROOM HUB", "Teleport & Touch sukses ke " .. targetRoomName, 3)
                else
                    CustomNotify("ERROR", "Karakter Anda belum sepenuhnya termuat!", 3)
                end
            else
                CustomNotify("MAP ERROR", "Fisik " .. targetRoomName .. ".Touch.Part tidak ditemukan!", 4)
            end
        end)

        -- 🌟 3. TOMBOL LEAVE ROOM
        CreateButton(RoomPage, "❌ Leave Room", function()
            pcall(function()
                GameMatchRE:FireServer("LeaveRoom")
                CustomNotify("MATCHMAKING", "Keluar dari antrean/room saat ini.", 3)
            end)
        end)

        -- Inisialisasi awal saat script di-load pertama kali
        task.defer(function()
            _G.UpdateRoomStatusLabel(EngineConfig.RoomMode)
        end)



                -- 🌟 SYNC TAB 6 (AUTO BUY)
                if _G.AutoBuyToggle and _G.AutoBuyToggle.SetValue then _G.AutoBuyToggle:SetValue(EngineConfig.AutoBuyActive) end

            if _G.AutoSkillToggle and _G.AutoSkillToggle.SetValue then _G.AutoSkillToggle:SetValue(EngineConfig.AutoSkillActive) end -- 🌟 SYNC BARU
                if _G.AutoSwitchToggle and _G.AutoSwitchToggle.SetValue then _G.AutoSwitchToggle:SetValue(EngineConfig.AutoWeaponSwitchActive) end -- 🌟 SYNC BARU
                if _G.ReplayToggle and _G.ReplayToggle.SetValue then _G.ReplayToggle:SetValue(EngineConfig.AutoReplayActive) end
                if _G.FarmToggle and _G.FarmToggle.SetValue then _G.FarmToggle:SetValue(EngineConfig.AutoAttackActive) end
                if _G.ReplayToggle and _G.ReplayToggle.SetValue then _G.ReplayToggle:SetValue(EngineConfig.AutoReplayActive) end
                if _G.FarmToggle and _G.FarmToggle.SetValue then _G.FarmToggle:SetValue(EngineConfig.AutoAttackActive) end
                if _G.ChestToggle and _G.ChestToggle.SetValue then _G.ChestToggle:SetValue(EngineConfig.PrioritizeChest) end
                if _G.CFrameToggle and _G.CFrameToggle.SetValue then _G.CFrameToggle:SetValue(EngineConfig.AutoCFrame) end
                if _G.RadiusInput and _G.RadiusInput.SetValue then _G.RadiusInput:SetValue(EngineConfig.OrbitRadius) end
                if _G.SpeedInput and _G.SpeedInput.SetValue then _G.SpeedInput:SetValue(EngineConfig.OrbitSpeed) end
                if _G.HeightInput and _G.HeightInput.SetValue then _G.HeightInput:SetValue(EngineConfig.StandHeight) end
                if _G.DelayInput and _G.DelayInput.SetValue then _G.DelayInput:SetValue(EngineConfig.CFrameDelay) end
                if _G.MultiplierInput and _G.MultiplierInput.SetValue then _G.MultiplierInput:SetValue(EngineConfig.HitMultiplier) end
                if _G.WorldDropdown and _G.WorldDropdown.SetValue then _G.WorldDropdown:SetValue(EngineConfig.SelectedWorld) end
            end)
        end

        -- Fungsi Refresh Dropdown
        local function RefreshConfigDropdown(forceSelectName)
            if ConfigDropdown and ConfigDropdown.SetValues then
                local updatedList = ConfigSystem.GetConfigList()
                ConfigDropdown:SetValues(updatedList)

                if forceSelectName and table.find(updatedList, forceSelectName) then
                    selectedConfig = forceSelectName
                    if ConfigDropdown.SetValue then ConfigDropdown:SetValue(forceSelectName) end
                else
                    selectedConfig = updatedList[1] or "None"
                end

                currentAutoLoadTarget = ConfigSystem.GetAutoLoadPointer()
            end
        end

        -- [URUTAN 1]: DROPDOWN SELECT TARGET
        ConfigDropdown = CreateDropdownUI(ProfilePage, "Selected Profile Storage", ConfigSystem.GetConfigList(), "None", function(v)
            selectedConfig = v
        end)

        -- INPUT FIELD TEXTBOX (Untuk nama file baru saat disave)
        CreateInputUI(ProfilePage, "New Input Identifier Name", "", false, function(v) 
            newConfigName = tostring(v) 
        end)

        -- [URUTAN 2]: SAVE ACTION
        CreateButton(ProfilePage, "➕ Save New Internal Profile", function()
            if newConfigName ~= "" then
                local success, errReason = ConfigSystem.SaveNew(newConfigName)
                if success then 
                    CustomNotify("CONFIG SYSTEM", "Profile '" .. newConfigName .. "' saved!", 3) 
                    task.wait(0.05)
                    RefreshConfigDropdown(newConfigName)
                else 
                    CustomNotify("SAVE ERROR", errReason, 4) 
                end
            else 
                CustomNotify("CONFIG WARN", "Ketik nama profile baru!", 3) 
            end
        end)

        -- [URUTAN 3]: LOAD ACTION
        CreateButton(ProfilePage, "📂 Load Bound Target Config", function()
            if selectedConfig and selectedConfig ~= "None" then
                local success = ConfigSystem.Load(selectedConfig, function() SyncAllVisualUI() end)
                if success then 
                    CustomNotify("CONFIG SYSTEM", "Profile '" .. selectedConfig .. "' loaded!", 3)
                else 
                    CustomNotify("CONFIG ERROR", "File corrupt/tidak ditemukan.", 3) 
                end
            else 
                CustomNotify("CONFIG WARN", "Pilih profile dropdown!", 3) 
            end
        end)

        -- [URUTAN 4]: AUTOLOAD BUTTON ACTION
        CreateButton(ProfilePage, "⚡ Set Profile as Autoload", function()
            if selectedConfig == "None" or selectedConfig == "" then 
                CustomNotify("AUTOLOAD WARN", "Pilih profile di dropdown terlebih dahulu!", 3)
                return 
            end

            currentAutoLoadTarget = selectedConfig
            ConfigSystem.SaveAutoLoadPointer(selectedConfig)
            CustomNotify("⚡ AUTOLOAD SET", "'" .. selectedConfig .. "' otomatis dimuat saat script aktif.", 3)
        end)

        -- [URUTAN 5]: RESET AUTOLOAD BUTTON ACTION
        CreateButton(ProfilePage, "❌ Reset Autoload Sequence", function()
            currentAutoLoadTarget = "None"
            ConfigSystem.SaveAutoLoadPointer("None")
            CustomNotify("⚡ AUTOLOAD OFF", "Sequence di-reset. Tidak ada profile yang dimuat otomatis.", 3)
        end)

        -- [URUTAN 6]: OVERWRITE ACTION
        CreateButton(ProfilePage, "🔄 Overwrite Focused Profile", function()
            local targetName = (newConfigName ~= "") and newConfigName or selectedConfig
            if targetName and targetName ~= "None" and targetName ~= "" then
                local success, errReason = ConfigSystem.OverwriteExisting(targetName)
                if success then 
                    CustomNotify("CONFIG SYSTEM", "Profile '" .. targetName .. "' overwritten!", 3) 
                    task.wait(0.05)
                    RefreshConfigDropdown(targetName)
                else 
                    CustomNotify("OVERWRITE ERROR", errReason, 4) 
                end
            else 
                CustomNotify("CONFIG WARN", "Pilih profile valid!", 3) 
            end
        end)

        -- [URUTAN 7]: DELETE ACTION
        CreateButton(ProfilePage, "🗑️ Wipe Focused Disk Profile", function()
            if selectedConfig and selectedConfig ~= "None" then
                if ConfigSystem.Delete(selectedConfig) then 
                    CustomNotify("CONFIG SYSTEM", "Profile wiped.", 3) 
                    task.wait(0.05)
                    RefreshConfigDropdown()
                else 
                    CustomNotify("CONFIG ERROR", "Gagal menghapus.", 3) 
                end
            else 
                CustomNotify("CONFIG WARN", "Pilih profile target!", 3) 
            end
        end)

        -- [URUTAN 7]: DELETE ACTION
        CreateButton(ProfilePage, "🗑️ Wipe Focused Disk Profile", function()
            if selectedConfig and selectedConfig ~= "None" then
                if ConfigSystem.Delete(selectedConfig) then 
                    CustomNotify("CONFIG SYSTEM", "Profile wiped.", 3) 
                    task.wait(0.05)
                    RefreshConfigDropdown()
                else 
                    CustomNotify("CONFIG ERROR", "Gagal menghapus.", 3) 
                end
            else 
                CustomNotify("CONFIG WARN", "Pilih profile target!", 3) 
            end
        end)

        --------------------------------------------------------------------------------
        -- 🛡️ [EXTRAS]: ANTI-AFK & ANTI-GAMEPLAY-PAUSED SYSTEM GUARD (PROFILE BOUND)
        --------------------------------------------------------------------------------
        CreateSection(ProfilePage, "System Guard Utilities")

        -- 1. UTILITY INTERACTION: ANTI-AFK ENGINE
        _G.AntiAFKToggle = CreateToggleUI(ProfilePage, "🛡️ Enable Modern Anti-AFK", EngineConfig.AntiAFKActive, function(state)
            EngineConfig.AntiAFKActive = state

            local VirtualUser = Services.VirtualUser
            if state then
                if not getgenv().AntiAFK_Connection then
                    getgenv().AntiAFK_Connection = LocalPlayer.Idled:Connect(function()
                        VirtualUser:CaptureController()
                        VirtualUser:ClickButton2(Vector2.new())
                        -- print("[System Guard] Anti-AFK signal sent.")
                    end)
                end
                CustomNotify("SYSTEM GUARD", "Anti-AFK diaktifkan.", 2)
            else
                if getgenv().AntiAFK_Connection then
                    getgenv().AntiAFK_Connection:Disconnect()
                    getgenv().AntiAFK_Connection = nil
                end
                CustomNotify("SYSTEM GUARD", "Anti-AFK dinonaktifkan.", 2)
            end
        end)

        -- 2. UTILITY INTERACTION: ANTI-GAMEPLAY-PAUSED (Fokus Window Hilang / Alt-Tab)
        _G.AntiPausedToggle = CreateToggleUI(ProfilePage, "⏳ Disable Gameplay Paused", EngineConfig.AntiPausedActive, function(state)
            EngineConfig.AntiPausedActive = state

            if state then
                -- Bypass system agar game tidak membeku saat di-minimize / alt-tab
                Services.GuiService.SetGameplayPausedNotificationEnabled(Services.GuiService, false)
                CustomNotify("SYSTEM GUARD", "Anti-Gameplay Paused aktif (Alt-Tab Aman).", 2)
            else
                -- Kembalikan ke pengaturan bawaan roblox
                Services.GuiService.SetGameplayPausedNotificationEnabled(Services.GuiService, true)
                CustomNotify("SYSTEM GUARD", "Anti-Gameplay Paused dinonaktifkan.", 2)
            end
        end)

        -- Trigger otomatis saat script pertama kali dieksekusi (Inisialisasi awal)
        task.defer(function()
            if EngineConfig.AntiAFKActive then _G.AntiAFKToggle:SetValue(true) end
            if EngineConfig.AntiPausedActive then _G.AntiPausedToggle:SetValue(true) end
        end)

        if _G.AntiAFKToggle and _G.AntiAFKToggle.SetValue then _G.AntiAFKToggle:SetValue(EngineConfig.AntiAFKActive) end
                if _G.AntiPausedToggle and _G.AntiPausedToggle.SetValue then _G.AntiPausedToggle:SetValue(EngineConfig.AntiPausedActive) end

                -- 🌟 SYNC TAB 7 (FORGE ENGINE)
                if _G.ForgeInput1 and _G.ForgeInput1.SetValue then _G.ForgeInput1:SetValue(EngineConfig.ForgeQTEBase) end
                if _G.ForgeInput2 and _G.ForgeInput2.SetValue then _G.ForgeInput2:SetValue(EngineConfig.ForgeQTEMultiplier) end
                if _G.ForgeInput3 and _G.ForgeInput3.SetValue then _G.ForgeInput3:SetValue(EngineConfig.ForgeFinishBase) end
                if _G.ForgeInput4 and _G.ForgeInput4.SetValue then _G.ForgeInput4:SetValue(EngineConfig.ForgeFinishMultiplier) end
                if _G.ForgeInput5 and _G.ForgeInput5.SetValue then _G.ForgeInput5:SetValue(EngineConfig.ForgeResultBase) end
                if _G.ForgeInput6 and _G.ForgeInput6.SetValue then _G.ForgeInput6:SetValue(EngineConfig.ForgeResultMultiplier) end

        --------------------------------------------------------------------------------
        -- [TAB 4]: SELL PAGE (IMPLEMENTASI LENGKAP & NATIVE SCRAPING)
        --------------------------------------------------------------------------------
        local SellPage = CreateTab("💰 Sell", 4)
        CreateSection(SellPage, "Inventory Management")

        -- [[ 1. STATE & UI DIRECTORY ]] --
        local MainGui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainGui")

        -- Pointer ke direktori scroll list asli di dalam game
        local EquipmentScroll = MainGui:FindFirstChild("ScreenBackpack") 
            and MainGui.ScreenBackpack:FindFirstChild("InventoryFrame")
            and MainGui.ScreenBackpack.InventoryFrame:FindFirstChild("EquipmentContent")
            and MainGui.ScreenBackpack.InventoryFrame.EquipmentContent:FindFirstChild("ScrollingFrame")

        local OresScroll = MainGui:FindFirstChild("ScreenEquipSell")
            and MainGui.ScreenEquipSell:FindFirstChild("SellFrame")
            and MainGui.ScreenEquipSell.SellFrame:FindFirstChild("OresContent")
            and MainGui.ScreenEquipSell.SellFrame.OresContent:FindFirstChild("ScrollingFrame")

        local MaterialsScroll = MainGui:FindFirstChild("ScreenEquipSell")
            and MainGui.ScreenEquipSell:FindFirstChild("SellFrame")
            and MainGui.ScreenEquipSell.SellFrame:FindFirstChild("MaterialContent")
            and MainGui.ScreenEquipSell.SellFrame.MaterialContent:FindFirstChild("ScrollingFrame")

        local BulkSelectedUUIDs = {}
        local categoryList = {"All", "Weapon", "Helmet", "Breastplate", "Ore", "Material"}

        -- Dropdown Kategori (Disambungkan ke EngineConfig & dibuat Global)
        _G.SellCategoryDropdown = CreateDropdownUI(SellPage, "Pilih Kategori", categoryList, EngineConfig.SellCategory, function(v)
            EngineConfig.SellCategory = v
        end)


        -- Container Khusus Hasil Scan
        local ItemResultContainer = Instance.new("ScrollingFrame")
        ItemResultContainer.Name = "ItemResultContainer"
        ItemResultContainer.Parent = SellPage
        ItemResultContainer.Size = UDim2.new(1, 0, 0, 200)
        ItemResultContainer.BackgroundTransparency = 1
        ItemResultContainer.ScrollBarThickness = 3
        ItemResultContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
        local ListLayout = Instance.new("UIListLayout", ItemResultContainer)
        ListLayout.Padding = UDim.new(0, 5)

        -- [[ 2. REMOTE ROUTER ]] --
        local function sellSpesifikNamaItem(listUUIDsTarget, tipeItem)
            if not listUUIDsTarget or #listUUIDsTarget == 0 then return end

            if tipeItem == "Material" then
                pcall(function() MaterialRE:FireServer("Sell", listUUIDsTarget, {}) end)
            elseif tipeItem == "Ore" then
                pcall(function() ForgeRF:InvokeServer("Sell", listUUIDsTarget) end)
            else
                pcall(function() EquipmentRE:FireServer("Sell", listUUIDsTarget) end)
            end
        end

        -- [[ 3. CORE SCANNER ENGINE ]] --
        local function runCoreNotificationEngine(parentFrame, filterCategory)
            -- Bersihkan frame UI lama
            for _, child in ipairs(parentFrame:GetChildren()) do
                if child:IsA("GuiObject") then child:Destroy() end
            end

            local database = { ["All"]={}, ["Weapon"]={}, ["Helmet"]={}, ["Breastplate"]={}, ["Ore"]={}, ["Material"]={} }

            -- Fungsi helper untuk memasukkan data ke database
            local function insertToDatabase(cat, id, uuid, visual)
                if not database[cat][id] then 
                    database[cat][id] = { Visual = visual, UUIDs = {}, OriginalCategory = cat } 
                end
                table.insert(database[cat][id].UUIDs, uuid)

                if not database["All"][id] then 
                    database["All"][id] = { Visual = visual, UUIDs = {}, OriginalCategory = cat } 
                end
                table.insert(database["All"][id].UUIDs, uuid)
            end

            -- Scrape Equipment
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
                        if string.find(checkText, "body") or string.find(checkText, "plate") or string.find(checkText, "armor") then 
                            finalCategory = "Breastplate"
                        elseif string.find(checkText, "helm") or string.find(checkText, "head") or string.find(checkText, "hat") then 
                            finalCategory = "Helmet" 
                        end

                        insertToDatabase(finalCategory, visualName, itemUUID, visualName)
                    end
                end
            end

            -- Scrape Ores & Materials [SUDAH DIPERBAIKI]
            local function scrapeStackables(scrollGui, categoryName)
                if scrollGui then
                    for _, slot in ipairs(scrollGui:GetChildren()) do
                        if slot:IsA("GuiObject") and slot.Name ~= "UIListLayout" and slot.Name ~= "UIPadding" then
                            -- 1. Ambil ID Asli untuk keperluan komunikasi ke Remote/Server
                            local idAsli = slot.Name
                            local idObj = slot:FindFirstChild("ID", true)
                            if idObj then 
                                idAsli = idObj:IsA("ValueBase") and tostring(idObj.Value) or idObj.Text 
                            end

                            -- 2. Ambil Nama Visual (Mencegah munculnya angka/ID di hasil scan)
                            -- Mencari TextLabel bernama "ItemName" atau "Name" di dalam slot
                            local nameLabel = slot:FindFirstChild("ItemName", true) or slot:FindFirstChild("Name", true)
                            local visualName = idAsli -- Cadangan jika tidak ada label sama sekali

                            if nameLabel and nameLabel:IsA("TextLabel") then 
                                visualName = nameLabel.Text 
                            end

                            -- 3. Masukkan ke database hasil scan
                            insertToDatabase(categoryName, idAsli, idAsli, visualName)
                        end
                    end
                end
            end

            scrapeStackables(OresScroll, "Ore")
            scrapeStackables(MaterialsScroll, "Material")

            -- Render UI Buttons
            local targetData = database[filterCategory]
            for targetID, dataObj in pairs(targetData) do
                -- Gunakan format Prefix_ID untuk mencegah duplikasi nama antar kategori
                local storageKey = dataObj.OriginalCategory .. "_" .. targetID 

                -- 🌟 [LOGIKA AUTOLOAD]: Cek apakah item ini ada di data Save (Khusus Ore & Material)
                if (dataObj.OriginalCategory == "Ore" or dataObj.OriginalCategory == "Material") then
                    if EngineConfig.AutoSellStaticList[storageKey] then
                        -- Masukkan otomatis ke keranjang jual saat di-scan
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

                -- Deteksi visual jika item terpilih (termasuk hasil Autoload)
                if BulkSelectedUUIDs[storageKey] then
                    ItemBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
                    ItemBtn.Text = "  ✅ " .. btnText
                else
                    ItemBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                    ItemBtn.Text = "  • " .. btnText
                end
                ItemBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

                ItemBtn.MouseButton1Click:Connect(function()
                    if BulkSelectedUUIDs[storageKey] then
                        -- Batal Pilih
                        BulkSelectedUUIDs[storageKey] = nil
                        ItemBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                        ItemBtn.Text = "  • " .. btnText

                        -- Hapus dari Data Save (Khusus Ore/Material)
                        if dataObj.OriginalCategory == "Ore" or dataObj.OriginalCategory == "Material" then
                            EngineConfig.AutoSellStaticList[storageKey] = nil
                        end
                    else
                        -- Pilih Item
                        BulkSelectedUUIDs[storageKey] = { UUIDs = dataObj.UUIDs, Type = dataObj.OriginalCategory }
                        ItemBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
                        ItemBtn.Text = "  ✅ " .. btnText

                        -- Masukkan ke Data Save (Khusus Ore/Material)
                        if dataObj.OriginalCategory == "Ore" or dataObj.OriginalCategory == "Material" then
                            EngineConfig.AutoSellStaticList[storageKey] = true
                        end
                    end
                end)
            end
        end


        -- [[ 4. UI BINDING & EXECUTION ]] --
        CreateButton(SellPage, "🔄 Scan Inventory", function()
            runCoreNotificationEngine(ItemResultContainer, EngineConfig.SellCategory)
            CustomNotify("SCANNER", "Scanning kategori: " .. EngineConfig.SellCategory, 2)
        end)


        CreateButton(SellPage, "💰 Execute Mass Sell", function()
            local equipmentPayload = {}
            local orePayload = {}
            local materialPayload = {}
            local sellCount = 0

            for key, dataObj in pairs(BulkSelectedUUIDs) do
                for _, uuid in ipairs(dataObj.UUIDs) do
                    if dataObj.Type == "Material" then table.insert(materialPayload, uuid)
                    elseif dataObj.Type == "Ore" then table.insert(orePayload, uuid)
                    else table.insert(equipmentPayload, uuid) end
                    sellCount = sellCount + 1
                end
            end

            if sellCount == 0 then
                CustomNotify("SELL WARN", "Tidak ada item yang dipilih!", 3)
                return
            end

            if #equipmentPayload > 0 then sellSpesifikNamaItem(equipmentPayload, "Equipment") end
            if #orePayload > 0 then sellSpesifikNamaItem(orePayload, "Ore") end
            if #materialPayload > 0 then sellSpesifikNamaItem(materialPayload, "Material") end

            task.wait(0.5)
            BulkSelectedUUIDs = {} -- Reset seleksi setelah dijual
            runCoreNotificationEngine(ItemResultContainer, EngineConfig.SellCategory) -- Refresh List
            CustomNotify("SELL EXECUTED", "Proses jual massal (" .. sellCount .. " item) selesai.", 3)
        end)
        CreateSection(SellPage, "Merchant System")

        CreateButton(SellPage, "🛒 TP & Buka UI Merchant", function()
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local RootPart = Character:WaitForChild("HumanoidRootPart")

            print("[Merchant Scan]: Mencari ProximityPrompt Merchant...")
            local MerchantPrompt = nil

            -- Loop mencari objek ProximityPrompt khusus Merchant
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    local promptText = v.ObjectText:lower() .. v.ActionText:lower()
                    local parentName = v.Parent.Name:lower()

                    if parentName:match("merchant") or promptText:match("merchant") or parentName:match("shop") or promptText:match("shop") then
                        MerchantPrompt = v
                        break
                    end
                end
            end

            -- Eksekusi CFrame
            if MerchantPrompt and MerchantPrompt.Parent:IsA("BasePart") then
                local PromptPart = MerchantPrompt.Parent
                print("[Merchant Success]: Menemukan Merchant di: " .. PromptPart:GetFullName())

                -- Menggunakan Engine Bawaanmu untuk mencegah karakter terlempar saat TP
                CombatEngine.ResetPhysics(RootPart)

                -- CFrame tubuh tepat di depan/atas Merchant
                RootPart.CFrame = PromptPart.CFrame * CFrame.new(0, 2, 0)
                task.wait(0.3) -- Jeda singkat agar server mencatat posisi baru

                if fireproximityprompt then
                    fireproximityprompt(MerchantPrompt)
                    CustomNotify("MERCHANT", "Berhasil membuka UI Merchant!", 3)
                else
                    CustomNotify("EXECUTOR WARN", "Executor tidak support fireproximityprompt", 3)
                end
            else
                CustomNotify("MERCHANT ERROR", "Gagal menemukan NPC Merchant otomatis!", 4)
            end
        end)


        --------------------------------------------------------------------------------
        -- [TAB 6]: BUY PAGE (AUTO BUYER GOLD SHOP - SAVE INTEGRATED)
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
            if v then
                CustomNotify("AUTO BUY", "Berjalan! (" .. hitungTarget .. " item terpilih)", 3)
            else
                CustomNotify("AUTO BUY", "Sistem Auto-Buy Dimatikan", 2)
            end
        end)

        CreateButton(BuyPage, "🔄 Scan Gold Shop Items", function()
            for _, child in ipairs(ShopListContainer:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            table.clear(BuyButtonsRef)

            local mainGui = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MainGui")
            if not mainGui then CustomNotify("ERROR", "MainGui tidak ditemukan!", 3) return end

            local screenGoldShop = mainGui:FindFirstChild("ScreenGoldShop")
            local contentFrame = screenGoldShop and screenGoldShop:FindFirstChild("Content")
            local scrollFrame = contentFrame and contentFrame:FindFirstChild("ScrollingFrame")

            if not scrollFrame then 
                CustomNotify("ERROR", "Toko belum diload! Buka toko di game dulu.", 4) 
                return 
            end

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
                        if EngineConfig.AutoBuyTargetList[item.Name] then
                            EngineConfig.AutoBuyTargetList[item.Name] = nil
                        else
                            EngineConfig.AutoBuyTargetList[item.Name] = true
                        end
                    end)
                end
            end
            CustomNotify("SHOP SCANNER", "Berhasil memuat " .. totalItem .. " item toko!", 3)
        end)

        --------------------------------------------------------------------------------
        -- BACKGROUND LOOPS ENGINE (TAB 6)
        --------------------------------------------------------------------------------

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
                                if EngineConfig.AutoBuyTargetList[item.Name] then
                                    itemBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
                                else
                                    itemBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
                                end
                            else
                                itemBtn.TextColor3 = Color3.fromRGB(130, 130, 130)
                                if EngineConfig.AutoBuyTargetList[item.Name] then
                                    itemBtn.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
                                else
                                    itemBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
                                end
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
                                        pcall(function()
                                            GoldShopRemote:FireServer("BuyGoldShopItem", item.Name)
                                        end)
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

        -- Ambil Utility Bawaan Game
        local ForgeUtil = require(Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("ForgeSystem"):WaitForChild("ForgeUtil"))

        -- Detour Hooking Logic (Berjalan secara background saat script diload)
        if not _G.OriginalQTE then _G.OriginalQTE = ForgeUtil.QTE end

        ForgeUtil.QTE = function(...)
            local args = {...}
            local data = nil
            for _, v in pairs(args) do 
                if type(v) == "table" and v.UUID then data = v break end 
            end

            if data then
                task.spawn(function()
                    -- Menggunakan data dari EngineConfig agar sinkron dengan Profile Save
                    local QTETotal = math.floor(EngineConfig.ForgeQTEBase * EngineConfig.ForgeQTEMultiplier)
                    local FinishTotal = math.floor(EngineConfig.ForgeFinishBase * EngineConfig.ForgeFinishMultiplier)
                    local ResultTotal = math.floor(EngineConfig.ForgeResultBase * EngineConfig.ForgeResultMultiplier)

                    for i = 1, QTETotal do ForgeRF:InvokeServer("QTE", {UUID = data.UUID, Rating = 15}) task.wait() end
                    for i = 1, FinishTotal do ForgeRF:InvokeServer("ForgeFinish") task.wait() end 
                    for i = 1, ResultTotal do ForgeRF:InvokeServer("ForgeResult", true) task.wait() end 
                end) 
            end
            return _G.OriginalQTE(...)
        end

        -- Input UI Builder (Modular)
        _G.ForgeInput1 = CreateInputUI(ForgePage, "QTE Base", EngineConfig.ForgeQTEBase, true, function(val) EngineConfig.ForgeQTEBase = val end)
        _G.ForgeInput2 = CreateInputUI(ForgePage, "QTE Multiplier", EngineConfig.ForgeQTEMultiplier, true, function(val) EngineConfig.ForgeQTEMultiplier = val end)
        _G.ForgeInput3 = CreateInputUI(ForgePage, "Finish Base", EngineConfig.ForgeFinishBase, true, function(val) EngineConfig.ForgeFinishBase = val end)
        _G.ForgeInput4 = CreateInputUI(ForgePage, "Finish Multiplier", EngineConfig.ForgeFinishMultiplier, true, function(val) EngineConfig.ForgeFinishMultiplier = val end)
        _G.ForgeInput5 = CreateInputUI(ForgePage, "Result Base", EngineConfig.ForgeResultBase, true, function(val) EngineConfig.ForgeResultBase = val end)
        _G.ForgeInput6 = CreateInputUI(ForgePage, "Result Multiplier", EngineConfig.ForgeResultMultiplier, true, function(val) EngineConfig.ForgeResultMultiplier = val end)

        CreateSection(ForgePage, "Forge Action Utilities")

        -- Tombol Teleport ke Forge
        CreateButton(ForgePage, "🚀 TP TO FORGE", function()
            local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local RootPart = Character:WaitForChild("HumanoidRootPart")

            print("[CFrame Scan]: Mencari ProximityPrompt Forge asli...")
            local TargetPrompt = nil

            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ProximityPrompt") then
                    local promptText = v.ObjectText:lower() .. v.ActionText:lower()
                    local parentName = v.Parent.Name:lower()

                    if parentName:match("forge") or promptText:match("forge") or parentName:match("craft") or promptText:match("craft") then
                        TargetPrompt = v
                        break
                    end
                end
            end

            if TargetPrompt and TargetPrompt.Parent:IsA("BasePart") then
                local PromptPart = TargetPrompt.Parent
                print("[CFrame Success]: Menemukan ProximityPrompt asli di: " .. PromptPart:GetFullName())
                CombatEngine.ResetPhysics(RootPart)
                RootPart.CFrame = PromptPart.CFrame * CFrame.new(0, 2, 0)
                task.wait(0.3)
                if fireproximityprompt then fireproximityprompt(TargetPrompt) end
            else
                warn("[CFrame Error]: Menggunakan koordinat paksa...")
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
                if ForgeUI then
                    for _, obj in pairs(ForgeUI:GetChildren()) do
                        if obj:IsA("Frame") then obj.Visible = true end
                    end
                end
            end)
            CustomNotify("FORGE SYSTEM", "Teleport & Bypass Interaksi Forge Berhasil.", 3)
        end)

        -- Tombol Claim Forge
        CreateButton(ForgePage, "💎 CLAIM FORGE RESULT", function()
            print("[Claim]: Mengirim ForgeResult ke server...")
            local success, err = pcall(function()
                ForgeRF:InvokeServer("ForgeResult", true)
            end)

            if success then
                CustomNotify("FORGE CLAIM", "Berhasil claim result!", 3)
            else
                warn("[Claim Error]: Gagal claim: " .. tostring(err))
                CustomNotify("CLAIM ERROR", "Gagal melakukan remote claim.", 3)
            end
        end)


        --------------------------------------------------------------------------------
        --// MODERN FLOATING TOGGLE BUTTON (TWEEN ANIMATED)
        --------------------------------------------------------------------------------
        local TweenService = Services.TweenService or game:GetService("TweenService")

        local ToggleGuiBtn = Instance.new("ScreenGui")
        ToggleGuiBtn.Name = "XiFil_ToggleButton"
        ToggleGuiBtn.Parent = LocalPlayer:WaitForChild("PlayerGui")
        ToggleGuiBtn.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ToggleGuiBtn.ResetOnSpawn = false
        RuntimeMaid:GiveTask(ToggleGuiBtn)
        ToggleGuiBtn.DisplayOrder = 999988

        -- Frame Container agar animasi scale/zoom tidak mengacaukan posisi drag
        local BtnContainer = Instance.new("Frame")
        BtnContainer.Name = "Container"
        BtnContainer.Parent = ToggleGuiBtn
        BtnContainer.BackgroundTransparency = 1
        BtnContainer.Position = UDim2.new(0.05, 0, 0.15, 0)
        BtnContainer.Size = UDim2.fromOffset(85, 42)

        local mainBtn = Instance.new("TextButton")
        mainBtn.Name = "InteractableCenter"
        mainBtn.Parent = BtnContainer
        mainBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
        mainBtn.BorderSizePixel = 0
        mainBtn.Size = UDim2.new(1, 0, 1, 0)
        mainBtn.Position = UDim2.new(0, 0, 0, 0)
        mainBtn.Text = "XiFil"
        mainBtn.Font = Enum.Font.GothamBlack
        mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        mainBtn.TextSize = 14
        mainBtn.AutoButtonColor = false -- Matikan warna default klik Roblox

        local ButtonCorner = Instance.new("UICorner")
        ButtonCorner.CornerRadius = UDim.new(0, 8)
        ButtonCorner.Parent = mainBtn

        -- Outline luar yang glowing
        local ButtonStroke = Instance.new("UIStroke")
        ButtonStroke.Parent = mainBtn
        ButtonStroke.Color = Color3.fromRGB(96, 205, 255)
        ButtonStroke.Thickness = 1.5
        ButtonStroke.Transparency = 0.3

        -- Garis aksen kecil di bawah teks untuk kesan futuristik/profesional
        local AccentLine = Instance.new("Frame")
        AccentLine.Name = "Accent"
        AccentLine.Parent = mainBtn
        AccentLine.BackgroundColor3 = Color3.fromRGB(96, 205, 255)
        AccentLine.BorderSizePixel = 0
        AccentLine.Size = UDim2.new(0, 20, 0, 2)
        AccentLine.Position = UDim2.new(0.5, -10, 0.75, 0)
        Instance.new("UICorner", AccentLine).CornerRadius = UDim.new(1, 0)


        -- Animasi Interaktif (Hover & Click)
        mainBtn.MouseEnter:Connect(function()
            TweenService:Create(mainBtn, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
            TweenService:Create(ButtonStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0, Thickness = 2}):Play()
            TweenService:Create(AccentLine, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 36, 0, 2), Position = UDim2.new(0.5, -18, 0.75, 0)}):Play()
        end)

        mainBtn.MouseLeave:Connect(function()
            TweenService:Create(mainBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(20, 20, 27)}):Play()
            TweenService:Create(ButtonStroke, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0.3, Thickness = 1.5}):Play()
            TweenService:Create(AccentLine, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 20, 0, 2), Position = UDim2.new(0.5, -10, 0.75, 0)}):Play()
        end)

        mainBtn.MouseButton1Down:Connect(function()
            TweenService:Create(mainBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.9, 0, 0.9, 0), Position = UDim2.new(0.05, 0, 0.05, 0)}):Play()
        end)

        mainBtn.MouseButton1Up:Connect(function()
            TweenService:Create(mainBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}):Play()
        end)

        -- Sistem Dragging yang dipasang di Container (Agar tidak bertabrakan dengan animasi tombol)
        local function BinderDrag(uiObj)
            local dragToggle, dragStart, startPos
            local inputBegan = mainBtn.InputBegan:Connect(function(input)
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

        mainBtn.MouseButton1Click:Connect(function()
            MainWindow.Visible = not MainWindow.Visible
        end)


        -- Default Initialization to Tab 1 & Booting Autoload
        TabRegistry["🏠 Main Farm"].Select()
        ConfigSystem.ExecuteAutoLoad(function() SyncAllVisualUI() end)

        CustomNotify("XiFil Engine V4", "Tabbed Interface successfully initialized.", 4)

    

    print("[XiFil] Key tervalidasi:", key)
    print("[XiFil] HWID:", hwid)

    -- ============ PASTE SCRIPT UTAMAMU DI BAWAH INI ============



    -- ============================================================
end)

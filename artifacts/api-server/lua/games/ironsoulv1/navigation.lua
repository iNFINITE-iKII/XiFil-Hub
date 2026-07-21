--------------------------------------------------------------------------------
--// navigation.lua — S07 Navigation Engine
--------------------------------------------------------------------------------
local H               = getgenv().Hub
local EngineConfig    = H.EngineConfig
local WORLD_INDEX     = H.WORLD_INDEX
local Workspace       = H.Workspace
local Services        = H.Services
local CombatEngine    = H.CombatEngine
local CustomNotify    = H.CustomNotify
local checkVictoryUi  = H.checkVictoryUi
local DisableAutoFarm = H.DisableAutoFarm

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
    local closestPortalInstance = nil
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
                    closestPortalInstance = obj
                end
            end
        end
    end
    -- Instance dikembalikan sebagai return kedua supaya caller (mis. World 3)
    -- bisa memicu ProximityPrompt / mengecek gerbang ronde, bukan cuma
    -- memindahkan CFrame lalu diam menunggu Touched yang mungkin tidak pernah fire.
    return closestPortalRoot, closestPortalInstance
end

-- [FIX] Beberapa portal (teramati di World 3 / Oathlost Castle) tidak
-- memakai Touched biasa, melainkan child "E" berupa ProximityPrompt yang
-- harus di-trigger manual — kalau cuma berdiri di CFrame-nya, tidak akan
-- pernah kebuka. Selain itu portal dikunci per-attribute "RoundNum" vs
-- "GameRoundCfg.GameRound"; kalau ronde belum sampai, menunggu di situ
-- tidak ada gunanya sama sekali.
-- Return: true kalau portal bisa/berhasil dicoba trigger, false kalau
-- memang masih terkunci oleh gerbang ronde (supaya caller bisa langsung
-- skip idle-wait daripada diam 115 detik sia-sia).
function Navigation.TryTriggerPortal(portalInstance)
    if not portalInstance then return true end

    -- Gerbang ronde — samakan dengan CanOpen() di script server portal asli
    local ok, roundNum = pcall(function() return portalInstance:GetAttribute("RoundNum") end)
    if ok and roundNum then
        local cfgFolder = Services.ReplicatedStorage:FindFirstChild("GameRoundCfg")
        local gameRound = cfgFolder and cfgFolder:GetAttribute("GameRound")
        if gameRound and roundNum >= gameRound then
            return false -- masih terkunci, jangan buang waktu menunggu
        end
    end

    -- Varian ProximityPrompt ("E") — perlu di-fire manual
    local promptHolder = portalInstance:FindFirstChild("E")
    local prompt = nil
    if promptHolder then
        if promptHolder:IsA("ProximityPrompt") then
            prompt = promptHolder
        else
            prompt = promptHolder:FindFirstChildOfClass("ProximityPrompt")
        end
    end
    if not prompt then
        prompt = portalInstance:FindFirstChildOfClass("ProximityPrompt")
    end

    if prompt and typeof(fireproximityprompt) == "function" then
        pcall(fireproximityprompt, prompt)
    end
    -- Kalau tidak ada ProximityPrompt sama sekali, berarti varian Touched —
    -- sudah tertangani otomatis begitu myHRP.CFrame disamakan dengan portal.
    return true
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

-- Cek: apakah ada target aktif sekarang? (berdasarkan target yang dipilih)
local function anyActiveTargetExists()
    if not EngineConfig.AutoFarmActive then return false end
    if EngineConfig.FarmTargetChest and #CombatEngine.GetValidChests()>0 then return true end
    if EngineConfig.FarmTargetEgg then
        for _, child in ipairs(Workspace:GetChildren()) do
            if child.Name == "DragonEgg" then
                local eggModel = child:FindFirstChild("EggModel")
                if eggModel and eggModel:FindFirstChild("Part") then return true end
            end
        end
    end
    if EngineConfig.FarmTargetMonster and #CombatEngine.GetValidMonsters()>0 then return true end
    return false
end

-- ── World 1 (Starless Forest): hardcoded positions → CFrame berurutan → idle ──
-- [HARDCODED POSITIONS] Mengatasi masalah StreamingEnabled — alih-alih mencari
-- instance di workspace, bot CFrame langsung ke koordinat tetap yang sudah diketahui.
-- 8 titik diiterasi berurutan. Indeks dikelola lewat _G._world1GroundIdx
-- (direset ke 1 di awal setiap sesi farm). Setelah titik ke-8, counter kembali ke 1.
--
-- [AUTO-SKIP] Kalau di titik tersebut tidak ada monster (stall 2 detik), langsung
-- lanjut ke titik berikutnya — terus maju sampai ketemu monster, farm dimatikan,
-- atau world berubah. Max 30 lompatan per pemanggilan.
function Navigation.SearchWorld1(myHRP, myHum)
    if WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then return end

    EngineConfig.IsLockDelay = true
    myHum.PlatformStand = true

    local function globalBreakCondition()
        return not EngineConfig.AutoFarmActive or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1
    end

    local positions = {
        Vector3.new(-660,  5,    -10),
        Vector3.new(-461,  6,      3),
        Vector3.new(-430,  5,    190),
        Vector3.new(1117,  7,    -23),
        Vector3.new(-650,  5,   -400),
        Vector3.new(-470,  5,   -380),
        Vector3.new(-445,  5,   -595),
        Vector3.new(-2200, 41, -13200),
        Vector3.new( 360,   7,   200),
        Vector3.new( 380,   7,    25),
        Vector3.new(-2420,  42,   -10),
    }
    local total = #positions

    local idx = _G._world1GroundIdx or 1
    if idx > total then idx = 1 end

    while not globalBreakCondition() do
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = CFrame.new(positions[idx])

        _G._world1GroundIdx = (idx % total) + 1
        idx = _G._world1GroundIdx

        if CombatEngine.InterruptableStall(0.001, globalBreakCondition) then break end
        if anyActiveTargetExists() then break end
    end

    EngineConfig.IsLockDelay = false
    myHum.PlatformStand = false
end

-- ── World 2 (Frozen Valley): fire TouchInterest portal tiap Room berurutan ──
-- [ROOM SEQUENTIAL] Iterasi semua subfolder workspace.World, tiap giliran:
--   1. Cari workspace.World.<room>.Portal.Root
--   2. CFrame ke Root
--   3. firetouchinterest(myHRP, Root.TouchInterest, 0)
-- Indeks dikelola lewat _G._world2RoomIdx (direset ke 1 di awal sesi farm).
-- [HARDCODED POSITIONS] Mengatasi masalah StreamingEnabled — CFrame langsung ke
-- koordinat tetap yang sudah diketahui, tanpa bergantung pada instance di workspace.
-- 8 titik diiterasi berurutan. Indeks dikelola lewat _G._world2RoomIdx
-- (direset ke 1 di awal setiap sesi farm). Setelah titik ke-8, counter kembali ke 1.
function Navigation.SearchWorld2(myHRP, myHum)
    if WORLD_INDEX[EngineConfig.SelectedWorld] ~= 2 then return end

    EngineConfig.IsLockDelay = true
    myHum.PlatformStand = true

    local function globalBreakCondition()
        return not EngineConfig.AutoFarmActive or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 2
    end

    local positions = {
        Vector3.new(-6165,   5,   641),
        Vector3.new(-4348, 569,  1581),
        Vector3.new(-4216, 560,  1583),
        Vector3.new(-4040, 561,  1576),
        Vector3.new(-6247,   3, -1432),
        Vector3.new(-4100, 562,  2500),
        Vector3.new(-4388, 564,  2515),
        Vector3.new(-4188, 649, -1866),
    }
    local total = #positions

    local idx = _G._world2RoomIdx or 1
    if idx > total then idx = 1 end

    while not globalBreakCondition() do
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = CFrame.new(positions[idx])

        _G._world2RoomIdx = (idx % total) + 1
        idx = _G._world2RoomIdx

        if CombatEngine.InterruptableStall(0.001, globalBreakCondition) then break end
        if anyActiveTargetExists() then break end
    end

    EngineConfig.IsLockDelay = false
    myHum.PlatformStand = false
end

-- ── World 3 (Oathlost Castle): hardcoded CFrame positions ──
-- [HARDCODED POSITIONS] 6 titik koordinat tetap Oathlost Castle diiterasi
-- berurutan. Indeks dikelola lewat _G._world3GroundIdx (direset ke 1 di awal
-- setiap sesi farm — lihat startFarmLoop() di farm.lua).
--
-- [AUTO-SKIP] Kalau di titik tersebut tidak ada monster (stall 0.05 detik),
-- langsung lanjut ke titik berikutnya — terus maju sampai ketemu monster,
-- farm dimatikan, atau world berubah.
function Navigation.SearchWorld3(myHRP, myHum)
    if WORLD_INDEX[EngineConfig.SelectedWorld] ~= 3 then return end

    EngineConfig.IsLockDelay = true
    myHum.PlatformStand = true

    local function globalBreakCondition()
        return not EngineConfig.AutoFarmActive or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 3
    end

    local positions = {
        Vector3.new(  687,  67,  600),
        Vector3.new(  125,  -8,  812),
        Vector3.new(  236,  10,  287),
        Vector3.new(  774,  64,  -34),
        Vector3.new( -756,  43,  255),
        Vector3.new( -448,  49,  262),
        Vector3.new(-1002,  22,  259),
    }
    local total = #positions

    local idx = _G._world3GroundIdx or 1
    if idx > total then idx = 1 end

    while not globalBreakCondition() do
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = CFrame.new(positions[idx])

        _G._world3GroundIdx = (idx % total) + 1
        idx = _G._world3GroundIdx

        if CombatEngine.InterruptableStall(0.001, globalBreakCondition) then break end
        if anyActiveTargetExists() then break end
    end

    EngineConfig.IsLockDelay = false
    myHum.PlatformStand = false
end


-- ── World 4 (Tartarus): hardcoded CFrame positions ──
-- [HARDCODED POSITIONS] 10 titik koordinat tetap Tartarus diiterasi berurutan.
-- Indeks dikelola lewat _G._world4GroundIdx (direset ke 1 di awal setiap sesi farm).
-- [AUTO-SKIP] Kalau di titik tersebut tidak ada monster, langsung lanjut ke titik berikutnya.
function Navigation.SearchWorld4(myHRP, myHum)
    if WORLD_INDEX[EngineConfig.SelectedWorld] ~= 4 then return end

    EngineConfig.IsLockDelay = true
    myHum.PlatformStand = true

    local function globalBreakCondition()
        return not EngineConfig.AutoFarmActive or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 4
    end

    local positions = {
        Vector3.new(-8815, 205, -1833),
        Vector3.new(-8891, 210, -1540),
        Vector3.new(-8713, 204, -1294),
        Vector3.new(-4111, 541, -1949),
        Vector3.new(-4449, 531, -1963),
        Vector3.new( 6136,-187,   592),
        Vector3.new(-4069, 447,  1557),
        Vector3.new(-4281, 452,  1586),
        Vector3.new(-4268, 452,  3176),
        Vector3.new(-4063, 452,  3148),
        Vector3.new(-5970,-188,   593),
        Vector3.new(-6020,-188,   594),
        Vector3.new(-6089,-190,   586),
    }
    local total = #positions

    local idx = _G._world4GroundIdx or 1
    if idx > total then idx = 1 end

    while not globalBreakCondition() do
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = CFrame.new(positions[idx])

        _G._world4GroundIdx = (idx % total) + 1
        idx = _G._world4GroundIdx

        if CombatEngine.InterruptableStall(0.001, globalBreakCondition) then break end
        if anyActiveTargetExists() then break end
    end

    EngineConfig.IsLockDelay = false
    myHum.PlatformStand = false
end


--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Export ke Hub
--------------------------------------------------------------------------------
H.Navigation            = Navigation
H.anyActiveTargetExists = anyActiveTargetExists

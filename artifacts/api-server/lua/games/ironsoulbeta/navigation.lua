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
        local egg = Workspace:FindFirstChild("DragonEgg")
        local ep  = egg and egg:FindFirstChild("EggModel") and egg.EggModel:FindFirstChild("Part")
        if ep then return true end
    end
    if EngineConfig.FarmTargetMonster and #CombatEngine.GetValidMonsters()>0 then return true end
    return false
end

-- ── World 1 (Starless Forest): orbit 3 tier 50/150/250, lalu cari portal, lalu idle ──
function Navigation.SearchWorld1(myHRP, myHum)
    -- [INSTANT CHECK] Jika saat dipanggil ternyata world sudah berubah, langsung batalkan!
    if WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then return end

    myHum.PlatformStand = true
    print("[SYSTEM W1] Room vacant! Searching fallback nodes...")

    local door = Navigation.GetClosestObject("RoundDoor", "Door", myHRP.Position)
    if door then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = door:IsA("Model") and door:GetPivot() or door.CFrame

        local interrupted = CombatEngine.InterruptableStall(0.5, function()
            -- Interrupsi ditambahkan pengecekan SelectedWorld
            return not EngineConfig.AutoFarmActive or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1
        end)
        if interrupted or anyActiveTargetExists() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then
            myHum.PlatformStand = false; return
        end
    end

    local centerPosition = myHRP.Position
    local orbitTiers = {50, 150, 250}

    -- [OPTIMIZED] Ganti orbit manual 50-step per tier (150 CFrame + 150 frame-wait
    -- total) dengan query spasial instan Workspace:GetPartBoundsInRadius(). Ini
    -- membaca struktur spasial internal physics engine langsung (broadphase +
    -- narrowphase) tanpa perlu memindahkan karakter sama sekali untuk "melihat"
    -- apakah ada target di radius tertentu — jauh lebih cepat & tanpa beban
    -- replikasi CFrame berulang ke server.
    local enemyFolder = Workspace:FindFirstChild("EnemyNpc")
    local radiusOverlapParams = OverlapParams.new()
    radiusOverlapParams.FilterType = Enum.RaycastFilterType.Include
    radiusOverlapParams.FilterDescendantsInstances = enemyFolder and { enemyFolder } or {}

    local function hasTargetWithinRadius(radius)
        if not enemyFolder then return false end
        local ok, parts = pcall(function()
            return Workspace:GetPartBoundsInRadius(centerPosition, radius, radiusOverlapParams)
        end)
        return ok and parts and #parts > 0
    end

    for tierIndex, currentRadius in ipairs(orbitTiers) do
        if anyActiveTargetExists() or not EngineConfig.AutoFarmActive or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then break end
        print("[SYSTEM W1] Checking Tier " .. tierIndex .. " (radius " .. currentRadius .. ") via GetPartBoundsInRadius")

        -- Query instan — tidak perlu 50x teleport untuk "melihat" apakah ada target
        if hasTargetWithinRadius(currentRadius) or anyActiveTargetExists() then
            break
        end

        -- Tidak ada target di radius ini: cukup 1x CFrame ke titik representatif
        -- tier ini (bukan 50x), lalu stall singkat sambil re-cek kondisi berhenti.
        CombatEngine.ResetPhysics(myHRP)
        local repCFrame = CFrame.new(centerPosition + Vector3.new(currentRadius, 0, 0), centerPosition)
        myHRP.CFrame = repCFrame

        local orbitStalled = CombatEngine.InterruptableStall(2, function()
            if not EngineConfig.AutoFarmActive or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then return true end
            CombatEngine.ResetPhysics(myHRP)
            myHRP.CFrame = repCFrame
        end)
        if orbitStalled or anyActiveTargetExists() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then break end
    end

    if anyActiveTargetExists() or not EngineConfig.AutoFarmActive or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then
        myHum.PlatformStand = false; return
    end

    local finalCFrame = myHRP.CFrame
    local isInterrupted = CombatEngine.InterruptableStall(5, function()
        if not EngineConfig.AutoFarmActive or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then return true end
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = finalCFrame
    end)
    if isInterrupted or anyActiveTargetExists() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then
        myHum.PlatformStand = false; return
    end

    local portal = Navigation.GetClosestObject("RoundDoor", "Portal", myHRP.Position)
        or Navigation.GetClosestObject("Workspace", "Portal", myHRP.Position)
    if portal then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = portal:IsA("Model") and portal:GetPivot() or portal.CFrame

        local portalCFrame = myHRP.CFrame
        CombatEngine.InterruptableStall(3, function()
            if not EngineConfig.AutoFarmActive or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then return true end
            CombatEngine.ResetPhysics(myHRP)
            myHRP.CFrame = portalCFrame
        end)
        if anyActiveTargetExists() or not EngineConfig.AutoFarmActive or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then
            myHum.PlatformStand = false; return
        end
    end

    -- Idle stall 115 detik menunggu respawn
    if EngineConfig.AutoFarmActive and not anyActiveTargetExists() and WORLD_INDEX[EngineConfig.SelectedWorld] == 1 then
        local idleCFrame = myHRP.CFrame
        CombatEngine.InterruptableStall(115, function()
            if not EngineConfig.AutoFarmActive or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 1 then return true end
            CombatEngine.ResetPhysics(myHRP)
            myHRP.CFrame = idleCFrame
        end)
    end
    myHum.PlatformStand = false
end

-- ── World 2 (Frozen Valley): stall → PortalD → Portal → idle ──
function Navigation.SearchWorld2(myHRP, myHum)
    if WORLD_INDEX[EngineConfig.SelectedWorld] ~= 2 then return end

    EngineConfig.IsLockDelay = true
    myHum.PlatformStand = true

    local function globalBreakCondition()
        return not EngineConfig.AutoFarmActive or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 2
    end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    local portalDCF = Navigation.GetSingleClosestPortal("PortalD", myHRP.Position, 2)
    if portalDCF and not globalBreakCondition() then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = portalDCF
        task.wait(0.1)
    end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end
    if anyActiveTargetExists() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 2 then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    local portalCF = Navigation.GetSingleClosestPortal("Portal", myHRP.Position, 2)
    if portalCF and not globalBreakCondition() then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = portalCF
        task.wait(0.1)
    end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    EngineConfig.IsLockDelay = false
    if anyActiveTargetExists() or not EngineConfig.AutoFarmActive or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 2 then
        myHum.PlatformStand = false; return
    end

    -- Idle stall 115 detik
    if EngineConfig.AutoFarmActive and not anyActiveTargetExists() and WORLD_INDEX[EngineConfig.SelectedWorld] == 2 then
        EngineConfig.IsLockDelay = true
        CombatEngine.InterruptableStall(115, function()
            if globalBreakCondition() then return true end
            CombatEngine.ResetPhysics(myHRP)
        end)
        EngineConfig.IsLockDelay = false
    end
    myHum.PlatformStand = false
end

-- ── World 3 (Oathlost Castle): stall → Portal dinamis → idle ──
function Navigation.SearchWorld3(myHRP, myHum)
    if WORLD_INDEX[EngineConfig.SelectedWorld] ~= 3 then return end

    EngineConfig.IsLockDelay = true
    myHum.PlatformStand = true

    local function globalBreakCondition()
        return not EngineConfig.AutoFarmActive or anyActiveTargetExists() or checkVictoryUi() or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 3
    end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    local closestPortalCF, closestPortalInstance = Navigation.GetSingleClosestPortal("Portal", myHRP.Position, 3)
    local portalUsable = true
    if closestPortalCF and not globalBreakCondition() then
        CombatEngine.ResetPhysics(myHRP)
        myHRP.CFrame = closestPortalCF
        task.wait(0.1)
        -- [FIX] Jangan cuma berdiri diam mengandalkan Touched — cek/fire
        -- ProximityPrompt ("E") kalau portal ini pakai varian itu, dan cek
        -- gerbang RoundNum vs GameRound biar tidak idle sia-sia di portal
        -- yang memang masih terkunci.
        portalUsable = Navigation.TryTriggerPortal(closestPortalInstance)
    end

    if CombatEngine.InterruptableStall(3, globalBreakCondition) then EngineConfig.IsLockDelay = false; myHum.PlatformStand = false; return end

    EngineConfig.IsLockDelay = false
    if anyActiveTargetExists() or not EngineConfig.AutoFarmActive or WORLD_INDEX[EngineConfig.SelectedWorld] ~= 3 then
        myHum.PlatformStand = false; return
    end

    -- Kalau portal terdeteksi masih terkunci ronde, jangan idle 115 detik
    -- percuma di depannya — langsung selesai supaya loop farm coba lagi
    -- lebih cepat (search berikutnya dipanggil ulang oleh farm.lua).
    if not portalUsable then
        myHum.PlatformStand = false; return
    end

    -- Idle stall 115 detik
    if EngineConfig.AutoFarmActive and not anyActiveTargetExists() and WORLD_INDEX[EngineConfig.SelectedWorld] == 3 then
        EngineConfig.IsLockDelay = true
        CombatEngine.InterruptableStall(115, function()
            if globalBreakCondition() then return true end
            CombatEngine.ResetPhysics(myHRP)
        end)
        EngineConfig.IsLockDelay = false
    end
    myHum.PlatformStand = false
end


--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Export ke Hub
--------------------------------------------------------------------------------
H.Navigation            = Navigation
H.anyActiveTargetExists = anyActiveTargetExists

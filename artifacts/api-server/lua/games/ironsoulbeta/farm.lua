--------------------------------------------------------------------------------
--// farm.lua — S08 Farm Loop + S09 Background Loops
--------------------------------------------------------------------------------
local H                     = getgenv().Hub
local EngineConfig          = H.EngineConfig
local LocalPlayer           = H.LocalPlayer
local Workspace             = H.Workspace
local Services              = H.Services
local PlayerActionRE        = H.PlayerActionRE
local GameMatchRE           = H.GameMatchRE
local WorldPlaceRE          = H.WorldPlaceRE
local MaterialRE            = H.MaterialRE
local EquipmentRE           = H.EquipmentRE
local CombatEngine          = H.CombatEngine
local Navigation            = H.Navigation
local anyActiveTargetExists = H.anyActiveTargetExists
local checkVictoryUi        = H.checkVictoryUi
local DisableAutoFarm       = H.DisableAutoFarm
local CustomNotify          = H.CustomNotify
local GetPositionCFrame     = H.GetPositionCFrame
local ApplyMovement         = H.ApplyMovement
local WORLD_INDEX           = H.WORLD_INDEX
local ROOM_WORLD_KEY        = H.ROOM_WORLD_KEY

-- [S08] FARM LOOP
-- Satu loop terpadu menangani semua prioritas: Chest > Egg > Enemy.
-- Guard _farmLoopRunning mencegah instance ganda saat toggle dinyalakan ulang.
--------------------------------------------------------------------------------

-- Flag: true saat weapon switch sedang berjalan → tahan auto attack
local _autoAttackPaused = false

-- Loop: Auto Attack Only (fire remote saja, tanpa movement)
-- Dibatasi 1x setiap 0.8 detik; berhenti selama jendela weapon switch.
task.spawn(function()
    while true do
        task.wait(0.8)  -- 1 serangan per 0.8 detik
        if EngineConfig.AutoAttackOnly and not _autoAttackPaused then
            local char=LocalPlayer.Character
            local hrp=char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _=1,EngineConfig.HitMultiplier do
                    task.defer(function() pcall(function() PlayerActionRE:FireServer("SkillAction","BaseAttack",3,hrp.CFrame) end) end)
                end
            end
        end
    end
end)

-- Guard: cegah loop dobel
local _farmLoopRunning=false

-- Timer serangan farm: pisahkan interval attack dari interval movement
-- Satu konstanta dipakai semua titik (Chest / Egg / Monster)
local _lastFarmAttack   = 0
local FARM_ATTACK_INTERVAL = 0.8  -- detik minimum antar BaseAttack di farm loop

-- Cek apakah loop masih harus berjalan
local function anyFarmToggleActive()
    return EngineConfig.AutoFarmActive
end

--[[
  SISTEM BARU — 1 Toggle (AutoFarmActive) + pilihan target (Monster/Chest/Egg)

  PRIORITAS (per frame) saat ada target yang dipilih:
    1. Monster — jika FarmTargetMonster=true DAN ada monster
    2. Chest   — jika FarmTargetChest=true DAN ada chest
    3. Egg     — jika FarmTargetEgg=true DAN ada DragonEgg
    4. Find    — Auto Farm aktif tapi tidak ada satupun target ditemukan → navigasi cari

  ATURAN:
  · Chest & Egg HANYA aktif jika AutoFarmActive=true.
  · Find otomatis berjalan saat tidak ada target, selalu.
  · Jika hanya Monster dipilih → setelah tidak ada monster langsung Find.
  · Jika Monster/Chest/Egg dipilih bersamaan → Monster lebih dulu, lalu Chest, baru Egg, baru Find.
]]
local function startFarmLoop()
    if _farmLoopRunning then return end
    _farmLoopRunning=true

    local noTargetTimer=0
    -- [WORLD3 ORBIT] Mulai sebagai "sudah selesai" agar orbit hanya muncul
    -- SETELAH ada monster World3 yang dibunuh, bukan dari awal loop kosong.
    _G._world3OrbitDone    = true
    _G._world3LastMonsterPos = nil   -- posisi monster terakhir yang dilawan di World3

    -- [ENDLESS TOWER] State per-session
    _G._endlessTowerNextCFrameAt = 0      -- tick() kapan CFrame berikutnya boleh jalan
    _G._endlessTowerHadTarget    = false  -- flag: target baru saja habis

    while anyFarmToggleActive() do
        if checkVictoryUi() then DisableAutoFarm("Victory UI Found"); break end

        local char=LocalPlayer.Character
        local myHRP=char and char:FindFirstChild("HumanoidRootPart")
        local myHum=char and char:FindFirstChildOfClass("Humanoid")
        if not myHRP or not myHum then task.wait(0.1); continue end

        local worldIdx=WORLD_INDEX[EngineConfig.SelectedWorld] or 1

        -- == GUARD World 2 IsLockDelay ==
        if worldIdx==2 and EngineConfig.IsLockDelay and not anyActiveTargetExists() then
            CombatEngine.ResetPhysics(myHRP); Services.RunService.Heartbeat:Wait()

        -- ──────────────── PRIORITAS 1: MONSTER ────────────────
        elseif EngineConfig.FarmTargetMonster and #CombatEngine.GetValidMonsters()>0 then
            noTargetTimer=0; EngineConfig.IsLockDelay=false
            -- Tandai: ada monster di World3 → orbit akan dipicu saat monster habis
            if worldIdx==3 then _G._world3OrbitDone=false end
            if not _autoAttackPaused then myHum.PlatformStand=true end
            local monsters=CombatEngine.GetValidMonsters()
            local target=monsters[1]
            local tPart=target and (target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart)
            local tHum=target and target:FindFirstChildOfClass("Humanoid")
            if tPart and (not tHum or tHum.Health>0) then
                -- Simpan posisi monster terakhir (World3) & tandai ada target (Endless Tower)
                if worldIdx==3 then _G._world3LastMonsterPos = tPart.Position end
                if worldIdx==4 then _G._endlessTowerHadTarget = true end
                local isBoss=CombatEngine.GetLevelType(target)=="boss"
                local savedH=EngineConfig.StandHeight
                if isBoss then EngineConfig.StandHeight=EngineConfig.BossHeight end
                local targetCF=GetPositionCFrame(tPart.Position,EngineConfig.FarmPosition)
                EngineConfig.StandHeight=savedH
                ApplyMovement(myHRP,targetCF)
                -- Attack dibatasi 1x per FARM_ATTACK_INTERVAL, movement tetap jalan tiap CFrameDelay
                local now=tick()
                if now-_lastFarmAttack >= FARM_ATTACK_INTERVAL and not _autoAttackPaused then
                    _lastFarmAttack=now
                    local atkCF=tPart.CFrame
                    for _=1,EngineConfig.HitMultiplier do
                        task.defer(function() pcall(function() PlayerActionRE:FireServer("SkillAction","BaseAttack",3,atkCF) end) end)
                    end
                end
                task.wait(EngineConfig.CFrameDelay)
            else Services.RunService.Heartbeat:Wait() end

        -- ──────────────── PRIORITAS 2: CHEST (max 50 stud — seperti Egg) ────────────────
        elseif EngineConfig.FarmTargetChest and (function()
            -- Hanya aktif jika ada chest yang jaraknya ≤ 500 stud dari player
            for _,c in ipairs(CombatEngine.GetValidChests()) do
                if c.Root and (c.Root.Position-myHRP.Position).Magnitude<=500 then return true end
            end
            return false
        end)() then
            noTargetTimer=0; EngineConfig.IsLockDelay=false
            -- Ambil chest terdekat yang masih ≤ 50 stud
            local nearestChest
            for _,c in ipairs(CombatEngine.GetValidChests()) do
                if c.Root and (c.Root.Position-myHRP.Position).Magnitude<=500 then
                    nearestChest=c; break
                end
            end
            local chestRoot = nearestChest and nearestChest.Root
            local chestObj  = nearestChest and nearestChest.Object
            if chestRoot and chestRoot:IsA("BasePart") then
                if not _autoAttackPaused then myHum.PlatformStand=true end

                -- Cek per-model: chest BARU = butuh approach phase.
                -- FIX: bandingkan dengan Object (model induk), bukan Root (Part anak)
                -- agar respawn / animasi buka-tutup chest yang mengganti Part anak
                -- tidak terus men-trigger ulang approach phase (CFrame ke lokasi yg sama).
                local _chestKey = nearestChest.Object
                if _G._chestApproached ~= _chestKey then
                    _G._chestApproached = _chestKey
                    -- ▶ FASE 1: CFrame ke chest + proximity prompt + attack selama 1 detik
                    CombatEngine.ResetPhysics(myHRP)
                    myHRP.CFrame = CFrame.new(chestRoot.Position+Vector3.new(0,3,0), chestRoot.Position)
                    local elapsed = 0
                    while elapsed < 1 do
                        if not EngineConfig.AutoFarmActive then break end
                        -- Coba fire proximity prompt (jika chest punya)
                        pcall(function()
                            local obj = chestObj or chestRoot.Parent
                            if obj then
                                for _,desc in ipairs(obj:GetDescendants()) do
                                    if desc:IsA("ProximityPrompt") then fireproximityprompt(desc) end
                                end
                            end
                        end)
                        -- Kirim attack ke chest
                        pcall(function()
                            PlayerActionRE:FireServer("SkillAction","BaseAttack",3,chestRoot.CFrame)
                        end)
                        task.wait(0.1)
                        elapsed = elapsed + 0.1
                    end
                end

                -- ▶ FASE 2: Orbit di sekitar chest sambil terus menyerang.
                -- Guard: jika farm dimatikan saat fase 1, lewati fase 2.
                if EngineConfig.AutoFarmActive then
                    local targetCF=GetPositionCFrame(chestRoot.Position,EngineConfig.FarmPosition)
                    ApplyMovement(myHRP,targetCF)
                    -- Attack dibatasi 1x per FARM_ATTACK_INTERVAL, movement tetap jalan tiap CFrameDelay
                    local now=tick()
                    if now-_lastFarmAttack >= FARM_ATTACK_INTERVAL and not _autoAttackPaused then
                        _lastFarmAttack=now
                        local atkCF=chestRoot.CFrame
                        for _=1,EngineConfig.HitMultiplier do
                            task.defer(function() pcall(function() PlayerActionRE:FireServer("SkillAction","BaseAttack",3,atkCF) end) end)
                        end
                    end
                    task.wait(EngineConfig.CFrameDelay)
                else
                    Services.RunService.Heartbeat:Wait()
                end
            else Services.RunService.Heartbeat:Wait() end

        -- ──────────────── PRIORITAS 3: EGG (max 50 stud — lebih dari itu SKIP) ────────────────
        elseif EngineConfig.FarmTargetEgg and (function()
            local egg=Workspace:FindFirstChild("DragonEgg")
            local ep=egg and egg:FindFirstChild("EggModel") and egg.EggModel:FindFirstChild("Part")
            return ep and (ep.Position-myHRP.Position).Magnitude<=500
        end)() then
            noTargetTimer=0; EngineConfig.IsLockDelay=false
            local egg=Workspace:FindFirstChild("DragonEgg")
            local eggPart = egg and egg:FindFirstChild("EggModel") and egg.EggModel:FindFirstChild("Part")
            -- Reset jika egg hilang (bisa karena diambil player lain)
            if not eggPart then _G._eggApproached=nil end
            if eggPart then
                if not _autoAttackPaused then myHum.PlatformStand=true end

                -- Cek per-referensi: egg BERBEDA = pendekatan baru (fix bug multi-egg)
                if _G._eggApproached ~= eggPart then
                    _G._eggApproached = eggPart  -- simpan referensi egg ini, bukan boolean
                    -- ▶ FASE 1: CFrame ke egg, diam 1 detik sambil proximity + attack dikirim
                    CombatEngine.ResetPhysics(myHRP)
                    myHRP.CFrame = CFrame.new(eggPart.Position+Vector3.new(0,3,0), eggPart.Position)
                    local elapsed = 0
                    while elapsed < 1 do
                        if not EngineConfig.AutoFarmActive then break end
                        -- Kirim proximity prompt
                        pcall(function()
                            for _,obj in ipairs(egg:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then fireproximityprompt(obj) end
                            end
                        end)
                        -- Kirim auto attack ke egg selama fase approach
                        pcall(function() PlayerActionRE:FireServer("SkillAction","BaseAttack",3,eggPart.CFrame) end)
                        task.wait(0.1)
                        elapsed = elapsed + 0.1
                    end
                end

                -- ▶ FASE 2: Orbit (setelah 1 detik approach selesai)
                local dropCF = GetPositionCFrame(eggPart.Position, EngineConfig.FarmPosition)
                ApplyMovement(myHRP, dropCF)

                task.wait(EngineConfig.CFrameDelay)
            else Services.RunService.Heartbeat:Wait() end

        -- ──────────────── TIDAK ADA TARGET → AUTO FIND ────────────────
        else
            -- [FIX] Tetap PlatformStand=true tepat saat target hilang, sama
            -- seperti fase Chest/Egg/Monster di atas — supaya karakter
            -- langsung "melayang" di posisi terakhir (gravity efektif
            -- di-nolkan lewat ResetPhysics setiap tick) dan tidak sempat
            -- jatuh ke tanah sebelum Auto Find / orbit World3 mengambil alih.
            if not _autoAttackPaused then myHum.PlatformStand=true end
            CombatEngine.ResetPhysics(myHRP)

            -- [ENDLESS TOWER] CFrame ke portal
            if worldIdx==4 then
                if _G._endlessTowerHadTarget then
                    -- Target baru saja habis: tunggu sesuai Reset Lock sebelum CFrame pertama
                    _G._endlessTowerHadTarget    = false
                    _G._endlessTowerNextCFrameAt = tick() + (EngineConfig.EndlessTowerResetLock or 5)
                end
                if tick() >= (_G._endlessTowerNextCFrameAt or 0) then
                    pcall(function()
                        local fxPart = Workspace.World.Start.Portal.EnemySpawnPortal.FX_SlowAOE
                        CombatEngine.ResetPhysics(myHRP)
                        myHRP.CFrame = fxPart.CFrame
                    end)
                    _G._endlessTowerNextCFrameAt = tick() + (EngineConfig.EndlessTowerResetLock or 5)
                end
            end

            -- [WORLD3] Orbit 1x cepat sesaat setelah monster habis.
            -- Orbit mengelilingi posisi monster terakhir (statis) agar tidak
            -- drift mengikuti karakter yang bergerak.
            -- Hanya berjalan sekali per wave (flag direset di blok MONSTER di atas).
            if worldIdx==3 and EngineConfig.FarmTargetMonster and not _G._world3OrbitDone then
                _G._world3OrbitDone = true
                local orbitCenter = _G._world3LastMonsterPos or myHRP.Position
                -- Durasi 1 putaran penuh (2π / speed), dibatasi max 3 detik agar selalu "cepat"
                local orbitDur = math.min(
                    math.max((2 * math.pi) / math.max(EngineConfig.OrbitSpeed, 0.5), 0.5),
                    3
                )
                local t0 = tick()
                while tick() - t0 < orbitDur and anyFarmToggleActive()
                      and #CombatEngine.GetValidMonsters() == 0 do
                    local c2 = LocalPlayer.Character
                    local h2 = c2 and c2:FindFirstChild("HumanoidRootPart")
                    if h2 then
                        ApplyMovement(h2, GetPositionCFrame(orbitCenter, EngineConfig.FarmPosition))
                    end
                    task.wait(math.max(EngineConfig.CFrameDelay, 0.05))
                end
            end

            noTargetTimer=noTargetTimer+0.1
            task.wait(0.1)
            -- World Search hanya aktif jika FarmTargetMonster ON
            -- (jika hanya Chest/Egg yang on, tidak perlu cari world baru)
            if noTargetTimer>=3 and EngineConfig.FarmTargetMonster then
                noTargetTimer=0
                if worldIdx==1 then Navigation.SearchWorld1(myHRP,myHum)
                elseif worldIdx==2 then Navigation.SearchWorld2(myHRP,myHum)
                elseif worldIdx==3 then Navigation.SearchWorld3(myHRP,myHum)
                end
            elseif noTargetTimer>=3 then
                noTargetTimer=0  -- reset timer meski tidak search, agar tidak numpuk
            end
        end
    end

    -- Cleanup saat Auto Farm dimatikan
    pcall(function()
        local char=LocalPlayer.Character
        local myHum=char and char:FindFirstChildOfClass("Humanoid")
        -- Jangan reset PlatformStand jika Fly masih aktif
        if myHum and not EngineConfig.FlyActive then myHum.PlatformStand=false end
        EngineConfig.IsLockDelay=false
    end)
    _G._eggApproached=nil    -- reset agar egg berikutnya di-approach ulang
    _G._chestApproached=nil  -- reset agar chest berikutnya di-approach ulang
    _farmLoopRunning=false
end


--------------------------------------------------------------------------------
-- [S09] BACKGROUND LOOPS
--------------------------------------------------------------------------------

-- Loop: Auto Skill — hanya aktif saat menargetkan monster/chest/egg (bukan saat Find)
task.spawn(function()
    while true do
        if EngineConfig.AutoSkillActive and EngineConfig.AutoFarmActive then
            -- Cek apakah ada target aktif yang sedang di-farm (monster / chest / egg)
            local hasActiveTarget = false
            if EngineConfig.FarmTargetMonster and #CombatEngine.GetValidMonsters()>0 then
                hasActiveTarget = true
            end
            if not hasActiveTarget and EngineConfig.FarmTargetChest then
                local char=LocalPlayer.Character
                local hrp=char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _,c in ipairs(CombatEngine.GetValidChests()) do
                        if c.Root and (c.Root.Position-hrp.Position).Magnitude<=500 then
                            hasActiveTarget=true; break
                        end
                    end
                end
            end
            if not hasActiveTarget and EngineConfig.FarmTargetEgg then
                local char=LocalPlayer.Character
                local hrp=char and char:FindFirstChild("HumanoidRootPart")
                local egg=Workspace:FindFirstChild("DragonEgg")
                local ep=egg and egg:FindFirstChild("EggModel") and egg.EggModel:FindFirstChild("Part")
                if hrp and ep and (ep.Position-hrp.Position).Magnitude<=500 then
                    hasActiveTarget=true
                end
            end

            if hasActiveTarget then
                local skills={}
                if EngineConfig.SkillActive1  then table.insert(skills,"Skill1")  end
                if EngineConfig.SkillActive2  then table.insert(skills,"Skill2")  end
                if EngineConfig.SkillActiveU  then table.insert(skills,"SkillU")  end
                if EngineConfig.SkillActiveAW then table.insert(skills,"SkillAW") end
                for _,skillName in ipairs(skills) do
                    for combo=1,3 do
                        pcall(function() PlayerActionRE:FireServer("SkillAction",skillName,combo) end)
                        task.wait(EngineConfig.SkillCooldownDelay)
                    end
                end
                task.wait(5)
            else
                task.wait(0.5)  -- tidak ada target aktif, tunggu dulu
            end
        else task.wait(0.5) end
    end
end)

-- Loop: Weapon Switcher
-- Pause auto attack selama 1 detik saat switch agar tidak tabrakan.
task.spawn(function()
    while true do
        if EngineConfig.AutoWeaponSwitchActive then
            -- Tahan auto attack dulu
            _autoAttackPaused = true
            -- Lepas PlatformStand agar server menerima weapon switch
            local char=LocalPlayer.Character
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.PlatformStand=false end
            task.wait(0.05)
            pcall(function() EquipmentRE:FireServer("ChangeWeaponSlot") end)
            -- Jendela 1 detik: auto attack berhenti, beri waktu switch selesai
            task.wait(1)
            _autoAttackPaused = false
            -- Farm loop akan kembalikan PlatformStand=true otomatis di iterasi berikutnya
            task.wait(3)
        else task.wait(0.5) end
    end
end)

-- [NOTE] Auto Egg sekarang ditangani oleh startFarmLoop() di [S08] dengan prioritas Chest>Egg>Enemy.
-- Loop terpisah tidak diperlukan lagi.

-- Dapatkan RemoteEvent ConsumableShop (path baru v4.0+)
local function FindGoldShopRemote()
    local ok, re = pcall(function()
        return Services.ReplicatedStorage
            :WaitForChild("Framework", 3):WaitForChild("Features", 3)
            :WaitForChild("ConsumableShopSystem", 3):WaitForChild("ConsumableShopUtil", 3)
            :WaitForChild("RemoteEvent", 3)
    end)
    if ok and re then return re end
    return nil
end

-- Dapatkan ScrollingFrame toko (ScreenConsumableShop)
local function FindGoldShopScrollingFrame()
    local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pgui then return nil end
    local mainGui = pgui:FindFirstChild("MainGui")
    if mainGui then
        local screen = mainGui:FindFirstChild("ScreenConsumableShop")
        if screen then
            local content = screen:FindFirstChild("Content")
            if content then
                local sf = content:FindFirstChildWhichIsA("ScrollingFrame")
                if sf then return sf end
            end
        end
    end
    return nil
end

-- Loop: Auto Join Room — TP ke room → buat room sesuai setting → tunggu 30 detik → ulang
task.spawn(function()
    while true do
        task.wait(1)
        if EngineConfig.AutoJoinRoomActive then
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")

            -- Step 1: TP ke target room
            local targetRoom = EngineConfig.RoomTarget or "Room1"
            local mrf = Workspace:FindFirstChild("MatchRoom")
            local rf  = mrf and mrf:FindFirstChild(targetRoom)
            local tm  = rf  and rf:FindFirstChild("Touch")
            local tp  = tm  and tm:FindFirstChild("Part")
            if hrp and tp and tp:IsA("BasePart") then
                CombatEngine.ResetPhysics(hrp)
                hrp.CFrame = tp.CFrame
                CustomNotify("🔁 AUTO JOIN","TP ke "..targetRoom,2)
            end
            task.wait(1)

            -- Step 2: Buat room sesuai setting yang dipilih
            local key = ROOM_WORLD_KEY and ROOM_WORLD_KEY[EngineConfig.RoomWorldDisplay] or "World1"
            pcall(function()
                GameMatchRE:FireServer("CreatRoom", key, EngineConfig.RoomMode, EngineConfig.RoomPlayers)
                CustomNotify("🔁 AUTO JOIN","Room: "..tostring(EngineConfig.RoomWorldDisplay).." [M:"..tostring(EngineConfig.RoomMode).."]",3)
            end)

            -- Step 3: Tunggu 30 detik sebelum siklus berikutnya
            local elapsed = 0
            while elapsed < 30 and EngineConfig.AutoJoinRoomActive do
                task.wait(1); elapsed = elapsed + 1
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if EngineConfig.AutoBuyActive then
            local sf = FindGoldShopScrollingFrame()
            if sf then
                for _, item in pairs(sf:GetChildren()) do
                    if EngineConfig.AutoBuyTargetList[item.Name] then
                        local stockTXT = item:FindFirstChild("StockTXT", true)
                        local stok = tonumber(stockTXT and stockTXT.Text:match("%d+")) or 0
                        if stok >= 1 and stok <= 9 then
                            local buyBtn = item:FindFirstChild("BuyBTN", true)
                            if buyBtn then
                                pcall(function()
                                    for _, conn in ipairs(getconnections(buyBtn.MouseButton1Down)) do
                                        conn:Fire()
                                    end
                                end)
                                task.wait(0.4)
                            end
                        end
                    end
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------

-- [S09-FLY] BACKGROUND LOOP: Fly  (Infinite Yield style)
-- BodyVelocity + BodyGyro → hover stabil, gravity sepenuhnya dinetralisir.
-- Mobile: joystick bawaan Roblox (horizontal) + virtual joystick kanan (vertikal).
-- PC    : WASD horizontal · Space naik · Ctrl/Shift turun.
--------------------------------------------------------------------------------
local _UIS = Services.UserInputService

--------------------------------------------------------------------------------
-- Helper: hancurkan BodyMover yang tertinggal di HRP
local function _destroyFlyObjects(hrp)
    if not hrp then return end
    local bv = hrp:FindFirstChild("_XiFilFlyBV")
    local bg = hrp:FindFirstChild("_XiFilFlyBG")
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
end

-- Helper: kembalikan CanCollide semua part karakter ke true
local function _restoreCollision(char)
    if not char then return end
    for _, p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end
end

--------------------------------------------------------------------------------
-- LOOP UTAMA FLY
--------------------------------------------------------------------------------
task.spawn(function()
    local _flyBV   = nil
    local _flyBG   = nil
    local _prevHRP = nil
    local _prevFly = false

    while true do
        Services.RunService.Heartbeat:Wait()

        if EngineConfig.FlyActive then
            local char = LocalPlayer.Character
            local hrp  = char and char:FindFirstChild("HumanoidRootPart")
            local hum  = char and char:FindFirstChildOfClass("Humanoid")

            if hrp and hum then
                -- ── Setup awal / setelah respawn ──────────────────────────
                if not _prevFly or hrp ~= _prevHRP then
                    if _prevHRP and _prevHRP ~= hrp then
                        _destroyFlyObjects(_prevHRP)
                    end
                    _prevFly = true
                    _prevHRP = hrp

                    hum.PlatformStand = true

                    _flyBV          = Instance.new("BodyVelocity")
                    _flyBV.Name     = "_XiFilFlyBV"
                    _flyBV.Velocity = Vector3.zero
                    _flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
                    _flyBV.P        = 1e4
                    _flyBV.Parent   = hrp

                    _flyBG           = Instance.new("BodyGyro")
                    _flyBG.Name      = "_XiFilFlyBG"
                    _flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
                    _flyBG.P         = 1e4
                    _flyBG.D         = 100
                    _flyBG.CFrame    = hrp.CFrame
                    _flyBG.Parent    = hrp

                end

                -- ── Baca input gerak (camera-relative 3D, persis Infinite Yield) ──
                --
                -- Cara IY: joystick/WASD dikali vektor PENUH kamera (termasuk Y).
                -- → Miringkan kamera ke atas + dorong joystick maju = terbang naik.
                -- → Miringkan kamera ke bawah + dorong joystick maju = terbang turun.
                -- Tidak perlu joystick kedua; 1 joystick + rotasi kamera = 6 arah.
                --
                local cam  = Workspace.CurrentCamera
                local move = Vector3.zero

                if cam then
                    local camCF = cam.CFrame

                    -- Proyeksikan MoveDirection (flat world-space) ke sumbu kamera
                    -- agar dapat skalar maju/mundur dan kiri/kanan.
                    local flatLook  = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z)
                    local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
                    local md = hum.MoveDirection   -- diisi Roblox dari joystick/WASD/gamepad

                    local fwd   = flatLook.Magnitude  > 0.01
                                  and md:Dot(flatLook.Unit)  or 0
                    local right = flatRight.Magnitude > 0.01
                                  and md:Dot(flatRight.Unit) or 0

                    -- Kalikan dengan vektor kamera PENUH (Y ikut → gerak 3D sejati)
                    move = camCF.LookVector * fwd + camCF.RightVector * right
                end

                -- Vertikal eksplisit: Space/Jump naik · Ctrl/Shift turun (PC & gamepad)
                -- Mobile: miringkan kamera ke atas/bawah + dorong joystick = naik/turun
                local vy = 0
                if _UIS:IsKeyDown(Enum.KeyCode.Space)
                or _UIS:IsKeyDown(Enum.KeyCode.ButtonA)
                   then vy = 1 end
                if _UIS:IsKeyDown(Enum.KeyCode.LeftControl)
                or _UIS:IsKeyDown(Enum.KeyCode.LeftShift)
                or _UIS:IsKeyDown(Enum.KeyCode.DPadDown)
                   then vy = -1 end
                move = move + Vector3.new(0, vy, 0)

                -- ── Terapkan velocity ─────────────────────────────────────
                local speed = math.max(EngineConfig.FlySpeed or 50, 1)
                if _flyBV and _flyBV.Parent then
                    _flyBV.Velocity = if move.Magnitude > 0
                        then move.Unit * speed
                        else Vector3.zero
                end

                -- ── Gyro: hadap arah kamera, karakter tegak ───────────────
                local cam = Workspace.CurrentCamera
                if _flyBG and _flyBG.Parent and cam then
                    local flatLook = Vector3.new(
                        cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
                    if flatLook.Magnitude > 0.01 then
                        _flyBG.CFrame = CFrame.new(Vector3.zero, flatLook)
                    end
                end

                -- ── Noclip ───────────────────────────────────────────────
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end

        elseif _prevFly then
            -- ── Cleanup saat fly dimatikan ────────────────────────────────
            _prevFly = false
            _destroyFlyObjects(_prevHRP)
            _flyBV, _flyBG = nil, nil

            local char = _prevHRP and _prevHRP.Parent
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum and not EngineConfig.AutoFarmActive then
                hum.PlatformStand = false
            end
            _restoreCollision(char)
            _prevHRP = nil
        end
    end
end)

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Export ke Hub
--------------------------------------------------------------------------------
H.startFarmLoop             = startFarmLoop
H.FindGoldShopScrollingFrame = FindGoldShopScrollingFrame  -- digunakan tab_autobuy

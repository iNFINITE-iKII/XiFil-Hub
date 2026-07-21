--------------------------------------------------------------------------------
--// combat.lua — S06 Combat Engine & Helper Posisi
--------------------------------------------------------------------------------
local H            = getgenv().Hub
local EngineConfig = H.EngineConfig
local LocalPlayer  = H.LocalPlayer
local Workspace    = H.Workspace
local Services     = H.Services
local PlayerActionRE = H.PlayerActionRE
local GameRoundRE    = H.GameRoundRE
local WorldPlaceRE   = H.WorldPlaceRE
local RuntimeMaid    = H.RuntimeMaid
local CustomNotify   = H.CustomNotify

-- [S06] COMBAT ENGINE & HELPER POSISI
--------------------------------------------------------------------------------

-- Hitung CFrame tujuan berdasarkan mode posisi
-- MUTLAK: semua mode selalu menghadap tepat ke arah target (3D lookAt)
local function GetPositionCFrame(targetPos, posMode)
    local r=EngineConfig.OrbitRadius; local h=EngineConfig.StandHeight
    local angle=tick()*EngineConfig.OrbitSpeed
    local pos
    if posMode=="Orbit Atas" then
        pos = targetPos+Vector3.new(math.cos(angle)*r,h,math.sin(angle)*r)
    elseif posMode=="Orbit Bawah" then
        pos = targetPos+Vector3.new(math.cos(angle)*r,-h,math.sin(angle)*r)
    elseif posMode=="Orbit Samping" then
        pos = targetPos+Vector3.new(math.cos(angle)*r,0,math.sin(angle)*r)
    elseif posMode=="Diam Atas" then
        pos = targetPos+Vector3.new(0,h,0)
    elseif posMode=="Diam Bawah" then
        pos = targetPos-Vector3.new(0,h,0)
    elseif posMode=="Depan Target" then
        pos = targetPos+Vector3.new(r,0,0)
    elseif posMode=="Belakang Target" then
        pos = targetPos+Vector3.new(-r,0,0)
    elseif posMode=="Acak" then
        local ra=math.random()*math.pi*2
        pos = targetPos+Vector3.new(math.cos(ra)*r,h,math.sin(ra)*r)
    else
        pos = targetPos+Vector3.new(math.cos(angle)*r,h,math.sin(angle)*r)
    end
    -- MUTLAK: selalu menghadap tepat ke target (lookAt penuh, termasuk arah Y)
    local dir = (targetPos - pos)
    if dir.Magnitude < 0.01 then dir = Vector3.new(1,0,0) end
    return CFrame.new(pos, pos + dir.Unit)
end

-- Terapkan gerakan: CFrame langsung atau Lerp
-- Noclip diterapkan setiap kali movement agar karakter bisa menembus objek/terrain
local function ApplyMovement(hrp, targetCF)
    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
    -- Nonaktifkan collision semua part karakter (noclip)
    local char = hrp.Parent
    if char then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    if EngineConfig.FarmMethod=="Lerp" then
        hrp.CFrame=hrp.CFrame:Lerp(targetCF,math.clamp(EngineConfig.LerpAlpha,0.01,1))
    else
        hrp.CFrame=targetCF
    end
end

local CombatEngine = {}
function CombatEngine.ResetPhysics(hrp)
    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
end
function CombatEngine.InterruptableStall(duration,conditionCheck)
    local elapsed=0
    while elapsed<duration do
        if conditionCheck() then return true end
        elapsed=elapsed+Services.RunService.Heartbeat:Wait()
    end; return false
end
function CombatEngine.GetLevelType(monster)
    local attr=monster:GetAttribute("LevelType")
    if attr then return tostring(attr):lower() end
    local obj=monster:FindFirstChild("LevelType")
    if obj and (obj:IsA("StringValue") or obj:IsA("IntValue")) then return tostring(obj.Value):lower() end
    if monster:FindFirstChild("BossTag") or string.lower(monster.Name):find("boss") then return "boss" end
    return "normal"
end
function CombatEngine.GetNpcId(monster)
    local attr=monster:GetAttribute("NpcId"); if attr then return tostring(attr) end
    local obj=monster:FindFirstChild("NpcId")
    if obj and (obj:IsA("StringValue") or obj:IsA("IntValue") or obj:IsA("NumberValue")) then return tostring(obj.Value) end
    return monster.Name
end
-- [OPTIMIZED] Radius pencarian untuk GetPartBoundsInRadius. Dibuat besar
-- (bukan radius kecil seperti orbit World1) supaya perilaku "cari di mana
-- saja" yang lama tetap terjaga — dampak performa datang dari native
-- broadphase query-nya, bukan dari mengecilkan area cari.
local SCAN_RADIUS = 5000

local function GetMyPosition()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    return hrp and hrp.Position or nil
end

function CombatEngine.GetValidChests()
    local myPos = GetMyPosition()
    if not myPos then return {} end

    local char = LocalPlayer.Character
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Exclude
    overlapParams.FilterDescendantsInstances = char and { char } or {}

    local ok, parts = pcall(function()
        return Workspace:GetPartBoundsInRadius(myPos, SCAN_RADIUS, overlapParams)
    end)
    if not ok or not parts then return {} end

    -- Chest asli adalah child LANGSUNG dari Workspace (sama seperti pencocokan
    -- lama) — naik dari part hasil query ke ancestor tersebut, lalu cek nama.
    local seen, chests = {}, {}
    for _, part in ipairs(parts) do
        local obj = part
        while obj and obj.Parent and obj.Parent ~= Workspace do
            obj = obj.Parent
        end
        if obj and obj.Parent == Workspace and not seen[obj] and obj.Name:find("Chest") then
            seen[obj] = true
            local root = obj:FindFirstChild("Root") or obj:FindFirstChild("Part") or (obj:IsA("Model") and obj.PrimaryPart)
            if root then
                table.insert(chests, { Object = obj, Root = root, _dist = (root.Position - myPos).Magnitude })
            end
        end
    end

    -- Urutkan dari yang paling dekat — sebelumnya urutan cuma ikut GetChildren()
    table.sort(chests, function(a, b) return a._dist < b._dist end)
    return chests
end

function CombatEngine.GetValidMonsters()
    local ef = Workspace:FindFirstChild("EnemyNpc")
    if not ef then return {} end
    local myPos = GetMyPosition()
    if not myPos then return {} end

    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Include
    overlapParams.FilterDescendantsInstances = { ef }

    local ok, parts = pcall(function()
        return Workspace:GetPartBoundsInRadius(myPos, SCAN_RADIUS, overlapParams)
    end)
    if not ok or not parts then return {} end

    local seen, normal, priority = {}, {}, {}
    for _, part in ipairs(parts) do
        local monster = part
        while monster and monster.Parent and monster.Parent ~= ef do
            monster = monster.Parent
        end
        if monster and monster.Parent == ef and not seen[monster] then
            seen[monster] = true
            local hrp = monster:FindFirstChild("HumanoidRootPart")
            local hum = monster:FindFirstChildOfClass("Humanoid")
            if hrp and (not hum or hum.Health > 0) then
                local dist = (hrp.Position - myPos).Magnitude
                local npcId = CombatEngine.GetNpcId(monster)
                local entry = { monster = monster, dist = dist }
                if (EngineConfig.SelectedNormalNpcId and npcId==EngineConfig.SelectedNormalNpcId)
                or (EngineConfig.SelectedBossNpcId   and npcId==EngineConfig.SelectedBossNpcId) then
                    entry.locked = true
                    table.insert(priority, entry)
                elseif CombatEngine.GetLevelType(monster)=="boss" then
                    table.insert(priority, entry)
                else
                    table.insert(normal, entry)
                end
            end
        end
    end

    -- Urutan dalam grup priority: NPC terkunci user dulu, baru boss biasa;
    -- dalam tiap sub-grup, yang JARAKNYA PALING DEKAT didahulukan.
    -- Sebelumnya: cuma insert terakhir yang ditaruh di depan, sisanya ikut
    -- urutan GetChildren() (bukan jarak sama sekali).
    table.sort(priority, function(a, b)
        if a.locked ~= b.locked then return a.locked end
        return a.dist < b.dist
    end)
    table.sort(normal, function(a, b) return a.dist < b.dist end)

    local source = #priority > 0 and priority or normal
    local result = {}
    for _, entry in ipairs(source) do
        table.insert(result, entry.monster)
    end
    return result
end
function CombatEngine.TargetsExistGlobal()
    return #CombatEngine.GetValidChests()>0 or #CombatEngine.GetValidMonsters()>0
end

-- Victory UI
local function isVictoryText(obj)
    if not obj or not obj:IsA("TextLabel") then return false end
    if not obj.Visible or obj.AbsoluteSize.X==0 or obj.TextTransparency>=1 then return false end
    local t=obj.Text:upper()
    if (obj.Name=="FirstClear" and t:find("FIRST CLEAR")) or (obj.Name=="Text" and t:find("VICTORY")) then
        local cur=obj.Parent
        while cur and not cur:IsA("ScreenGui") do
            if cur:IsA("GuiObject") and not cur.Visible then return false end
            cur=cur.Parent
        end
        local p=obj.Parent
        if p and (p.Name=="RoundCompleted" or p.Name=="BTN" or p.Name=="Victory") then return true end
    end; return false
end
local function checkVictoryUi()
    local pGui=LocalPlayer:FindFirstChild("PlayerGui"); if not pGui then return false end
    for _,desc in ipairs(pGui:GetDescendants()) do if isVictoryText(desc) then return true end end
    return false
end

local ToggleControl=nil

local function FireReplayRemote()
    if not EngineConfig.AutoReplayActive then return end
    task.wait(1.0)
    local ok,err=pcall(function() GameRoundRE:FireServer("VotePlayAgain") end)
    if ok then CustomNotify("🔄 REPLAY","Sinyal dikirim!",3)
    else CustomNotify("⚠️ REPLAY ERROR","Gagal: "..tostring(err),3) end
end

-- Kirim sinyal kembali ke lobby
local function FireBackLobby()
    local ok,err=pcall(function() WorldPlaceRE:FireServer("BackLobby") end)
    if ok then CustomNotify("🏠 LOBBY","Kembali ke lobby!",3)
    else CustomNotify("⚠️ LOBBY ERROR","Gagal: "..tostring(err),3) end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- HandleEndOfRound: dipanggil dari SEMUA jalur deteksi ronde selesai
-- (Victory UI, farm loop checkVictoryUi, dan Settlement event).
-- Debounce 35 detik mencegah duplicate task jika kedua jalur menyala bersamaan.
--
-- Logika:
--   AutoReplay ON & AutoReturn ON → Replay dulu, 30 detik, BackLobby
--   AutoReplay ON saja            → Replay saja
--   AutoReturn ON saja            → Langsung BackLobby (delay 1 detik)
-- ─────────────────────────────────────────────────────────────────────────────
local _endOfRoundHandled = false
local function HandleEndOfRound()
    if _endOfRoundHandled then return end
    _endOfRoundHandled = true
    task.delay(35, function() _endOfRoundHandled = false end)

    local doReplay = EngineConfig.AutoReplayActive
    local doReturn = EngineConfig.AutoReturnLobbyActive

    if doReplay and doReturn then
        task.spawn(function()
            CustomNotify("🔄 REPLAY+LOBBY","Replay dikirim, lobby dalam 30 detik...",5)
            task.wait(1.0)
            pcall(function() GameRoundRE:FireServer("VotePlayAgain") end)
            task.wait(30)
            FireBackLobby()
        end)
    elseif doReplay then
        task.spawn(FireReplayRemote)
    elseif doReturn then
        task.spawn(function()
            task.wait(1.0)
            FireBackLobby()
        end)
    end
end

local function DisableAutoFarm(reason)
    if not EngineConfig.AutoFarmActive then return end
    EngineConfig.AutoFarmActive=false
    if ToggleControl and ToggleControl.SetValue then ToggleControl:SetValue(false)
    elseif _G.FarmMonsterToggle and _G.FarmMonsterToggle.SetValue then _G.FarmMonsterToggle:SetValue(false) end
    CustomNotify("🚨 FARM OFF",reason,4)
    -- Trigger end-of-round actions (replay/return) dari jalur Victory MAUPUN Settlement
    if reason:find("Victory") or reason:find("Settlement") then
        task.spawn(HandleEndOfRound)
    end
end

-- Listener Victory UI (jalur 1)
local uiConn=LocalPlayer:WaitForChild("PlayerGui").DescendantAdded:Connect(function(desc)
    task.wait(0.2); if isVictoryText(desc) then DisableAutoFarm("Victory Screen Detected") end
end)
RuntimeMaid:GiveTask(uiConn)

-- Listener Settlement Screen (jalur 2 — backup & trigger utama untuk AutoReturn)
-- Menangkap: ReplicatedStorage.Framework.Systems.GUILib.WindowUtil.RemoteEvent
--            OnClientEvent("Open", "ScreenSettlement", ...)
task.spawn(function()
    local ok, settlementRE = pcall(function()
        return Services.ReplicatedStorage
            :WaitForChild("Framework",10)
            :WaitForChild("Systems",10)
            :WaitForChild("GUILib",10)
            :WaitForChild("WindowUtil",10)
            :WaitForChild("RemoteEvent",10)
    end)
    if not ok or not settlementRE then
        CustomNotify("⚠️ WARN","Settlement RE tidak ditemukan",4)
        return
    end

    local conn = settlementRE.OnClientEvent:Connect(function(action, screen, _data)
        if action ~= "Open" or screen ~= "ScreenSettlement" then return end
        -- DisableAutoFarm sudah mengandung debounce lewat HandleEndOfRound.
        -- Jika Victory sudah mematikan farm lebih dulu, HandleEndOfRound tidak akan
        -- duplikat karena _endOfRoundHandled sudah true.
        DisableAutoFarm("Settlement Screen")
    end)
    RuntimeMaid:GiveTask(conn)
end)


-------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Export ke Hub
--------------------------------------------------------------------------------
H.GetPositionCFrame = GetPositionCFrame
H.ApplyMovement     = ApplyMovement
H.CombatEngine      = CombatEngine
H.checkVictoryUi    = checkVictoryUi
H.DisableAutoFarm   = DisableAutoFarm
H.FireReplayRemote  = FireReplayRemote
H.FireBackLobby     = FireBackLobby
-- ToggleControl di-set oleh ui_core saat toggle dibuat, lewat H.SetToggleControl
H.SetToggleControl  = function(tc) ToggleControl = tc end

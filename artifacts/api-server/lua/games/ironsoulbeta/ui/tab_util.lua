--------------------------------------------------------------------------------
--// ui/tab_util.lua — Tab Utilitas: Redeem Code, Lottery, Reward, Race Reroll
--------------------------------------------------------------------------------
local H            = getgenv().Hub
local EngineConfig = H.EngineConfig
local Services     = H.Services
local LocalPlayer  = H.LocalPlayer
local CustomNotify = H.CustomNotify
local CreateTab                     = H.CreateTab
local CreateSection                 = H.CreateSection
local CreateToggleUI                = H.CreateToggleUI
local CreateInputUI                 = H.CreateInputUI
local CreateButton                  = H.CreateButton
local CreateScrollableMultiSelectUI = H.CreateScrollableMultiSelectUI
local CreateDropdownUI              = H.CreateDropdownUI
local RegisterTranslation           = H.RegisterTranslation

-- [UTIL] REMOTE EVENTS — lazy, di-cache setelah berhasil
--------------------------------------------------------------------------------
local _codeRE, _lotteryRE, _raceRE, _rewardRE = nil, nil, nil, nil

local function getCodeRE()
    if _codeRE then return _codeRE end
    local ok, re = pcall(function()
        return Services.ReplicatedStorage
            :WaitForChild("Framework",3):WaitForChild("Systems",3)
            :WaitForChild("CodesSystem",3):WaitForChild("CodeRE",3)
    end)
    if ok and re then _codeRE = re end
    return _codeRE
end

local function getLotteryRE()
    if _lotteryRE then return _lotteryRE end
    local ok, re = pcall(function()
        return Services.ReplicatedStorage
            :WaitForChild("Framework",3):WaitForChild("Features",3)
            :WaitForChild("SeasonSystem",3):WaitForChild("SeasonUtil",3)
            :WaitForChild("RemoteEvent",3)
    end)
    if ok and re then _lotteryRE = re end
    return _lotteryRE
end

local function getRaceRE()
    if _raceRE then return _raceRE end
    local ok, re = pcall(function()
        return Services.ReplicatedStorage
            :WaitForChild("Framework",3):WaitForChild("Gameplay",3)
            :WaitForChild("RaceSystem",3):WaitForChild("RaceRE",3)
    end)
    if ok and re then _raceRE = re end
    return _raceRE
end

local function getRewardRE()
    if _rewardRE then return _rewardRE end
    local ok, re = pcall(function()
        return Services.ReplicatedStorage
            :WaitForChild("Framework",3):WaitForChild("Features",3)
            :WaitForChild("UpdateLogSystem",3):WaitForChild("RemoteEvent",3)
    end)
    if ok and re then _rewardRE = re end
    return _rewardRE
end

-- [UTIL] DATA LISTS — tambah item baru di sini saja, tidak perlu ubah kode lain
--------------------------------------------------------------------------------

-- Kode redeem (terbaru di atas)
local CODE_LIST = {
    "TGIFSEASON2",       "SEASON2GIFTA",      "SEASON2LIVE",
    "IRONSOULWEEKEND13", "100KCONGRATS",       "IRONSOULWEEKEND12",
    "GOODJOB70KMEMBER",  "THURSDAYGIFT",       "IRONSOULWEEKEND11",
    "EXPEDITIONFIX",     "GROCERYFIX",
    "IRONSOULWEEKEND10", "THXFOR60KMEMBER",    "HAPPYJUNE",
    "50KMEMBER",         "IRONSOULWEEKEND9",   "40KMEMBER",
    "30KMEMBER",         "IRONSOULWEEKEND8",   "MEMBER20000",
    "IRONSOULWEEKEND7",  "FIXINGPATCH",        "IRONSOULWEEKEND6",
    "LIMITEDGIFT1",      "MEMBER10000",
}

-- Race (langka → umum; key harus cocok dengan text dari PlayerTitleGUI)
local RACE_LIST = {
    "Demon",     -- 0.20 %
    "Night Elf", -- 0.20 %
    "Angel",     -- 0.30 %
    "Archdruid", -- 1.00 %
    "Fairy",     -- 1.70 %
    "Sorcerer",  -- 2.10 %
    "Dragonkin", -- 6.00 %
    "Undead",    -- 13.00 %
    "Goblin",    -- 24.50 %
    "Orc",       -- 25.50 %
    "Human",     -- 25.50 %
}

-- Label dropdown (dengan persentase untuk konteks user)
local RACE_DISPLAY = {
    "Demon (0.20%)",     "Night Elf (0.20%)",
    "Angel (0.30%)",     "Archdruid (1.00%)",
    "Fairy (1.70%)",     "Sorcerer (2.10%)",
    "Dragonkin (6.00%)", "Undead (13.00%)",
    "Goblin (24.50%)",   "Orc (25.50%)",
    "Human (25.50%)",
}

-- Versi reward update (tambah versi baru di sini)
local REWARD_VERSIONS = {
    "V10.1", "V10", "V9.5", "V9.4", "V9.3", "V9.2",
}

-- Export lists ke Hub agar ui_sync bisa sync tanpa duplikat konstanta
H.UtilCodeList = CODE_LIST
H.UtilRaceList = RACE_LIST

-- [UTIL] HELPER: baca race karakter dari billboard di kepala
--------------------------------------------------------------------------------
local function getCurrentRace()
    local char = LocalPlayer.Character
    if not char then return "Unknown" end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return "Unknown" end
    local gui    = hrp:FindFirstChild("PlayerTitleGUI")
    local root   = gui   and gui:FindFirstChild("Root")
    local title  = root  and root:FindFirstChild("Title")
    local lbl    = title and title:FindFirstChild("Race")
    if lbl and (lbl:IsA("TextLabel") or lbl:IsA("TextBox")) then
        return lbl.Text
    end
    return "Unknown"
end

-- [UTIL] TAB
--------------------------------------------------------------------------------
local UtilPage = CreateTab("🔧 Utilitas", "tabUtil")

-- ════════════════════════════════════════════════════════════════════════════
-- [SEKSI 1] REDEEM CODE
-- ════════════════════════════════════════════════════════════════════════════
CreateSection(UtilPage, "Redeem Code", "secUtilCode")

local _codeInitVals, _codeCbs = {}, {}
for _, code in ipairs(CODE_LIST) do
    table.insert(_codeInitVals, EngineConfig.UtilSelectedCodes[code] == true)
    local _code = code
    table.insert(_codeCbs, function(v)
        EngineConfig.UtilSelectedCodes[_code] = (v == true)
    end)
end
_G.UtilCodeChecks = CreateScrollableMultiSelectUI(
    UtilPage, "Pilih Kode Redeem", CODE_LIST, _codeInitVals, _codeCbs
)

local _redeemBusy = false
CreateButton(UtilPage, "🎁 Redeem Kode Terpilih", function()
    if _redeemBusy then return end
    local re = getCodeRE()
    if not re then CustomNotify("⚠️ UTIL","CodeRE tidak ditemukan!",3); return end
    local selected = {}
    for _, code in ipairs(CODE_LIST) do
        if EngineConfig.UtilSelectedCodes[code] then
            table.insert(selected, code)
        end
    end
    if #selected == 0 then CustomNotify("⚠️ UTIL","Pilih minimal 1 kode!",3); return end
    _redeemBusy = true
    task.spawn(function()
        CustomNotify("🎁 REDEEM","Memulai "..#selected.." kode (15d jeda)...",4)
        for i, code in ipairs(selected) do
            pcall(function() re:FireServer({event="usecode", code=code}) end)
            if i < #selected then
                -- Hitung mundur agar terlihat
                for cd = 15, 1, -1 do
                    CustomNotify("🎁 REDEEM","["..i.."/"..#selected.."] "..code.." | Berikutnya: "..cd.."d",1)
                    task.wait(1)
                end
            end
        end
        CustomNotify("🎁 REDEEM","Selesai! "..#selected.." kode di-redeem.",4)
        _redeemBusy = false
    end)
end, "btnUtilRedeem")

-- ════════════════════════════════════════════════════════════════════════════
-- [SEKSI 2] AUTO REROLL LOTTERY
-- ════════════════════════════════════════════════════════════════════════════
CreateSection(UtilPage, "Auto Reroll Lottery", "secUtilLottery")

_G.UtilLotteryCountInput = CreateInputUI(
    UtilPage, "Jumlah Reroll Sekaligus", tostring(EngineConfig.UtilLotteryCount), true,
    function(v)
        local n = tonumber(v)
        if n and n >= 1 then EngineConfig.UtilLotteryCount = math.floor(n) end
    end
)

local _lotteryBusy = false
CreateButton(UtilPage, "🎰 Reroll Lottery Sekarang", function()
    if _lotteryBusy then return end
    local re = getLotteryRE()
    if not re then CustomNotify("⚠️ UTIL","LootRE tidak ditemukan!",3); return end
    local count = math.max(math.floor(EngineConfig.UtilLotteryCount or 15), 1)
    _lotteryBusy = true
    task.spawn(function()
        for i = 1, count do
            pcall(function() re:FireServer("TrySeasonLottery", 1) end)
            task.wait(0.05)
        end
        CustomNotify("🎰 LOTTERY","Selesai "..count.." reroll!",3)
        _lotteryBusy = false
    end)
end, "btnUtilLottery")

-- ════════════════════════════════════════════════════════════════════════════
-- [SEKSI 3] CLAIM REWARD UPDATE
-- ════════════════════════════════════════════════════════════════════════════
CreateSection(UtilPage, "Claim Reward Update", "secUtilReward")

local _rewardBusy = false
CreateButton(UtilPage, "🏆 Claim Semua Reward Update", function()
    if _rewardBusy then return end
    local re = getRewardRE()
    if not re then CustomNotify("⚠️ UTIL","RewardRE tidak ditemukan!",3); return end
    _rewardBusy = true
    task.spawn(function()
        for _, ver in ipairs(REWARD_VERSIONS) do
            CustomNotify("🏆 REWARD","Mengklaim: "..ver,1)
            pcall(function() re:FireServer("ClaimReward", ver) end)
            task.wait(0.5)
        end
        CustomNotify("🏆 REWARD","Semua reward berhasil diklaim!",4)
        _rewardBusy = false
    end)
end, "btnUtilClaimReward")

-- ════════════════════════════════════════════════════════════════════════════
-- [SEKSI 4] AUTO REROLL RACE
-- ════════════════════════════════════════════════════════════════════════════
CreateSection(UtilPage, "Auto Reroll Race", "secUtilRace")

-- Dropdown pilih slot (hanya 2 opsi: Free_1 dan 1)
local SLOT_LIST    = {"Free 1", "Slot 1"}
local SLOT_KEY_MAP = { ["Free 1"]="Free_1", ["Slot 1"]="1" }
-- Konversi default lama (integer) ke display string jika diperlukan
local _slotDefault = (EngineConfig.UtilRaceSlot == "1") and "Slot 1" or "Free 1"
_G.UtilRaceSlotDropdown = CreateDropdownUI(
    UtilPage, "🎰 Race Slot", SLOT_LIST,
    _slotDefault,
    function(val)
        EngineConfig.UtilRaceSlot = SLOT_KEY_MAP[val] or "Free_1"
    end, "lblUtilRaceSlot"
)

-- Dropdown multi-select (scrollable) — tampilkan RACE_DISPLAY (ada %)
-- tapi simpan state lewat RACE_LIST (nama asli)
local _raceInitVals, _raceCbs = {}, {}
for _, race in ipairs(RACE_LIST) do
    table.insert(_raceInitVals, EngineConfig.UtilTargetRaces[race] == true)
    local _race = race
    table.insert(_raceCbs, function(v)
        EngineConfig.UtilTargetRaces[_race] = (v == true)
    end)
end
_G.UtilRaceChecks = CreateScrollableMultiSelectUI(
    UtilPage, "Target Race", RACE_DISPLAY, _raceInitVals, _raceCbs
)

_G.UtilAutoRerollToggle = CreateToggleUI(
    UtilPage, "🎲 Auto Reroll Race", EngineConfig.UtilAutoRerollActive,
    function(v)
        EngineConfig.UtilAutoRerollActive = v
        if v then CustomNotify("🎲 AUTO REROLL","Aktif — roll sampai target!",3)
        else      CustomNotify("🎲 AUTO REROLL","Nonaktif",2) end
    end, "lblUtilAutoReroll"
)

-- Loop auto reroll race (background)
task.spawn(function()
    while true do
        task.wait(1)
        if not EngineConfig.UtilAutoRerollActive then continue end

        local re = getRaceRE()
        if not re then task.wait(3); continue end

        -- Cek setidaknya 1 target race dipilih
        local anyTarget = false
        for _, race in ipairs(RACE_LIST) do
            if EngineConfig.UtilTargetRaces[race] then anyTarget = true; break end
        end
        if not anyTarget then
            EngineConfig.UtilAutoRerollActive = false
            if _G.UtilAutoRerollToggle then _G.UtilAutoRerollToggle:SetValue(false) end
            CustomNotify("⚠️ AUTO REROLL","Pilih target race dulu!",4)
            continue
        end

        -- Baca race saat ini
        local currentRace = getCurrentRace()
        local raceLower   = string.lower(currentRace)

        -- Cek kecocokan
        local isMatch = false
        for _, race in ipairs(RACE_LIST) do
            if EngineConfig.UtilTargetRaces[race] then
                if string.find(raceLower, string.lower(race), 1, true) then
                    isMatch = true; break
                end
            end
        end

        if isMatch then
            -- Verifikasi 2x untuk hindari desync
            task.wait(0.5)
            local doubleRace = getCurrentRace()
            local dlLower    = string.lower(doubleRace)
            local verified   = false
            for _, race in ipairs(RACE_LIST) do
                if EngineConfig.UtilTargetRaces[race] then
                    if string.find(dlLower, string.lower(race), 1, true) then
                        verified = true; break
                    end
                end
            end
            if verified then
                EngineConfig.UtilAutoRerollActive = false
                if _G.UtilAutoRerollToggle then _G.UtilAutoRerollToggle:SetValue(false) end
                CustomNotify("🎉 RACE MATCH!","Dapat race: "..doubleRace,8)
            end
        else
            -- Belum cocok → roll sekali pada slot yang dipilih
            -- Normalisasi: jaga kompatibilitas jika nilai lama (integer) masih tersimpan
            local _rawSlot = EngineConfig.UtilRaceSlot
            local slotKey = (type(_rawSlot)=="string" and (_rawSlot=="Free_1" or _rawSlot=="1"))
                            and _rawSlot or "Free_1"
            pcall(function() re:FireServer("SelectSlot", slotKey) end)
        end
    end
end)

--------------------------------------------------------------------------------
-- Export ke Hub
--------------------------------------------------------------------------------
H.UtilCodeList = CODE_LIST
H.UtilRaceList = RACE_LIST

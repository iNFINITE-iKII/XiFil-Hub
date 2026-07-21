--------------------------------------------------------------------------------
--// buff_card.lua — Auto Buff Card Selector
-- Mendeteksi kartu di PlayerBonusCard.Cards lalu otomatis fire RemoteEvent
-- sesuai toggle yang diaktifkan user. Fire hanya 1x per update kartu.
--
-- Slot 1-3 → FireServer("Select", slotNum)
-- Slot 4   → FireServer("Unlock", 4)
--
-- Priority rules:
--   1. Jika kartu sama muncul di Unlock (4) DAN Select (1-3) → hanya fire Unlock
--   2. Jika kartu sama di beberapa slot Select → pilih slot tertinggi
--   3. Jika user enable beberapa kartu dengan nama dasar sama (mis. "Base Attack I"
--      & "Base Attack V") → pilih numeral tertinggi
--   4. Numeral sama → pilih yang pertama di-toggle (urutan di CARD_NAMES)
--------------------------------------------------------------------------------
local H                = getgenv().Hub
local EngineConfig     = H.EngineConfig
local WorldBonusCardRE = H.WorldBonusCardRE
local Services         = H.Services
local LocalPlayer      = Services.Players.LocalPlayer

-- Roman numeral parser (trailing suffix)
local ROMAN = {I=1, V=5, X=10, L=50, C=100, D=500, M=1000}
local function romanVal(cardName)
    local s = (cardName:match("%s([IVXLCDMivxlcdm]+)$") or ""):upper()
    if s == "" then return 0 end
    local val, prev = 0, 0
    for i = #s, 1, -1 do
        local c = ROMAN[s:sub(i, i)] or 0
        if c < prev then val = val - c else val = val + c end
        prev = c
    end
    return val
end

-- Ambil nama dasar kartu (buang angka romawi di akhir)
-- "Attack IV" → "Attack",  "MAX Health IV" → "MAX Health"
local function baseName(name)
    return name:match("^(.-)%s+[IVXLCDMivxlcdm]+$") or name
end

-- Baca teks kartu di item GUI (coba exact path, fallback recursive)
local function getCardText(item)
    local ok, lbl = pcall(function() return item.BTN.Stat.Name end)
    if ok and lbl and lbl:IsA("TextLabel") then
        return lbl.Text:gsub("\n", " "):match("^%s*(.-)%s*$")
    end
    for _, d in ipairs(item:GetDescendants()) do
        if d.Name == "Name" and d:IsA("TextLabel") then
            return d.Text:gsub("\n", " "):match("^%s*(.-)%s*$")
        end
    end
    return nil
end

-- Cocokkan base name kartu dengan kategori yang di-enable user
-- "Attack IV" → baseName = "Attack" → cari EngineConfig.BuffCardEnabled["Attack"]
local function matchCategory(cardText)
    local enabled = EngineConfig.BuffCardEnabled or {}
    local base = baseName(cardText):lower()
    for cat, on in pairs(enabled) do
        if on and cat:lower() == base then return cat end
    end
    return nil
end

-- Hitung aksi yang perlu di-fire
-- Setiap kategori yang di-enable: scan semua slot, otomatis pilih tier tertinggi (romawi terbesar).
-- Jika ada di slot 4 (Unlock) → prioritas Unlock.
-- Jika tier sama di beberapa slot → pilih slot tertinggi.
local function computeActions()
    if not WorldBonusCardRE then return {} end
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return {} end
    local ok, cards = pcall(function()
        return gui.MainGuiIgnoreGuiInset.PlayerBonusCard.Cards
    end)
    if not ok or not cards then return {} end

    -- matched[kategori] = list of {text, slot, rv}
    local matched = {}
    for _, item in ipairs(cards:GetChildren()) do
        local slotNum = tonumber(item.Name:match("^Item(%d+)$"))
        if slotNum then
            local text = getCardText(item)
            if text and text ~= "" then
                local cat = matchCategory(text)
                if cat then
                    if not matched[cat] then matched[cat] = {} end
                    table.insert(matched[cat], {
                        text = text,
                        slot = slotNum,
                        rv   = romanVal(text),
                    })
                end
            end
        end
    end

    local actions = {}
    for _, items in pairs(matched) do
        -- Sort: slot-4 (Unlock) > roman tertinggi > slot tertinggi
        table.sort(items, function(a, b)
            if (a.slot == 4) ~= (b.slot == 4) then return a.slot == 4 end
            if a.rv ~= b.rv then return a.rv > b.rv end
            return a.slot > b.slot
        end)
        local best = items[1]
        if best.slot == 4 then
            table.insert(actions, { action = "Unlock", slot = 4 })
        else
            table.insert(actions, { action = "Select", slot = best.slot })
        end
    end

    return actions
end

-- Fire semua aksi (debounced — 1x per event)
local _lastFire = 0
local function fireBuffCards()
    if not EngineConfig.BuffCardActive then return end
    local now = tick()
    if now - _lastFire < 0.3 then return end
    _lastFire = now

    local actions = computeActions()
    for _, act in ipairs(actions) do
        if act.action == "Select" then
            pcall(function() WorldBonusCardRE:FireServer("Select", act.slot) end)
        elseif act.action == "Unlock" then
            pcall(function() WorldBonusCardRE:FireServer("Unlock", 4) end)
        end
    end
end

-- Monitor Cards container
local function monitorCards()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if not gui then return end
    local ok, cards = pcall(function()
        local mgi = gui:WaitForChild("MainGuiIgnoreGuiInset", 10)
        local pbc = mgi:WaitForChild("PlayerBonusCard", 10)
        return pbc:WaitForChild("Cards", 10)
    end)
    if not ok or not cards then return end

    -- Scan kartu yang sudah ada
    fireBuffCards()

    -- Monitor kartu baru / perubahan teks
    cards.DescendantAdded:Connect(function(desc)
        if desc.Name == "Name" and desc:IsA("TextLabel") then
            task.wait(0.15)
            fireBuffCards()
            desc:GetPropertyChangedSignal("Text"):Connect(function()
                fireBuffCards()
            end)
        end
    end)
end

task.spawn(monitorCards)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1); task.spawn(monitorCards)
end)

H.BuffCard_FireNow = fireBuffCards

--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

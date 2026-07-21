--------------------------------------------------------------------------------
--// ui/tab_sell.lua — S20 Tab 4: Sell
--------------------------------------------------------------------------------
local H            = getgenv().Hub
local EngineConfig = H.EngineConfig
local Services     = H.Services
local LocalPlayer  = H.LocalPlayer
local EquipmentRE  = H.EquipmentRE
local MaterialRE   = H.MaterialRE
local CustomNotify = H.CustomNotify
local ForgeRF          = H.ForgeRF
local Workspace        = H.Workspace
local CombatEngine     = H.CombatEngine
local CreateTab        = H.CreateTab
local CreateSection    = H.CreateSection
local CreateDropdownUI = H.CreateDropdownUI
local CreateCycleUI      = H.CreateCycleUI
local CreateButton       = H.CreateButton
local CreateToggleUI     = H.CreateToggleUI
local CreateInputUI      = H.CreateInputUI
local CreateScrollableMultiSelectUI = H.CreateScrollableMultiSelectUI
local RegisterTranslation = H.RegisterTranslation

-- [S20] TAB 4 — SELL
--------------------------------------------------------------------------------
local SellPage = CreateTab("💰 Jual", "tabSell")

-- ════════════════════════════════════════════════════════════════════════════
-- [AUTO SELL BY RARITY] — Paling atas tab Sell
-- Deteksi rarity dari UIGradient color / TextLabel, jual semua yang dipilih.
-- ════════════════════════════════════════════════════════════════════════════
local RARITY_COLOR_MAP_SR = {
    ["195,195,195"] = "Common",
    ["76,206,103"]  = "Uncommon",
    ["88,201,253"]  = "Rare",
    ["253,88,234"]  = "Epic",
    ["255,245,83"]  = "Legendary",
    ["255,112,112"] = "Mythical",
}
local RARITY_TEXT_MAP_SR = {
    ["common"]="Common",["uncommon"]="Uncommon",["rare"]="Rare",
    ["epic"]="Epic",["legendary"]="Legendary",["mythical"]="Mythical",["divine"]="Divine",
}
local RARITY_ORDER_SR = {Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Mythical=6,Divine=7}
local RARITY_LIST_SR  = {"Common","Uncommon","Rare","Epic","Legendary","Mythical"}

local function _cleanSR(s) return string.lower(string.gsub(s,"[^%w]","")) end

local function _detectRarity(slot)
    local best = "Common"
    for _, d in ipairs(slot:GetDescendants()) do
        if d:IsA("UIGradient") and #d.Color.Keypoints > 0 then
            local c   = d.Color.Keypoints[1].Value
            local key = math.floor(c.R*255+.5)..","..math.floor(c.G*255+.5)..","..math.floor(c.B*255+.5)
            local r   = RARITY_COLOR_MAP_SR[key]
            if r and (RARITY_ORDER_SR[r] or 0) > (RARITY_ORDER_SR[best] or 0) then best = r end
        elseif d:IsA("TextLabel") then
            local m = RARITY_TEXT_MAP_SR[_cleanSR(d.Text)]
            if m and (RARITY_ORDER_SR[m] or 0) > (RARITY_ORDER_SR[best] or 0) then best = m end
        end
    end
    return best
end

local function _getOresScrollSR()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local mg = pg  and pg:FindFirstChild("MainGui")
    local bp = mg  and mg:FindFirstChild("ScreenBackpack")
    local iv = bp  and bp:FindFirstChild("InventoryFrame")
    local oc = iv  and iv:FindFirstChild("OresContent")
    return oc and oc:FindFirstChild("ScrollingFrame")
end

local function doSellByRarity()
    local scroll = _getOresScrollSR()
    if not scroll then CustomNotify("⚠️ SELL RARITY","Buka Inventory dulu!",3); return 0 end
    local ids = {}
    for _, slot in ipairs(scroll:GetChildren()) do
        if slot:IsA("GuiObject") and slot.Name ~= "UIListLayout" and slot.Name ~= "UIPadding" then
            local r = _detectRarity(slot)
            if EngineConfig.SellByRarityList[r] then
                local id = slot.Name
                local io = slot:FindFirstChild("ID", true)
                if io then id = io:IsA("ValueBase") and tostring(io.Value) or io.Text end
                table.insert(ids, id)
            end
        end
    end
    if #ids > 0 then
        pcall(function() ForgeRF:InvokeServer("Sell", ids) end)
        CustomNotify("🗑️ SELL RARITY","Terjual "..(#ids).." Ore",2)
    end
    return #ids
end

-- ─── UI ──────────────────────────────────────────────────────────────────────
CreateSection(SellPage, "Auto Sell by Rarity", "secSellByRarity")

-- Multi-check: bisa pilih lebih dari 1 rarity
local _rarityInitVals, _rarityCbs = {}, {}
for _, r in ipairs(RARITY_LIST_SR) do
    table.insert(_rarityInitVals, EngineConfig.SellByRarityList[r] == true)
    local rName = r
    table.insert(_rarityCbs, function(v)
        -- Simpan nilai boolean eksplisit (true/false, bukan nil) agar JSON
        -- encode selalu menyertakan semua 6 rarity → save/load bekerja benar.
        EngineConfig.SellByRarityList[rName] = (v == true)
    end)
end
_G.SellRarityChecks = CreateScrollableMultiSelectUI(SellPage, "Rarity yang dijual", RARITY_LIST_SR, _rarityInitVals, _rarityCbs)

-- Interval auto sell
-- FIX: argument order sebelumnya salah (callback & langKey tertukar).
-- Signature: CreateInputUI(parent, text, default, numeric, callback)
_G.SellByRarityIntervalInput = CreateInputUI(SellPage, "Interval Auto Sell (detik)", tostring(EngineConfig.SellByRarityInterval), false, function(v)
    local n = tonumber(v); if n and n >= 1 then EngineConfig.SellByRarityInterval = n end
end)

-- Sell sekali sekarang
CreateButton(SellPage, "🗑️ Sell Sekarang (Rarity)", function()
    doSellByRarity()
end, "btnSellByRarityNow")

-- Auto Sell toggle
_G.SellByRarityToggle = CreateToggleUI(SellPage, "⚡ Auto Sell by Rarity", EngineConfig.SellByRarityActive, function(v)
    EngineConfig.SellByRarityActive = v
    if v then CustomNotify("⚡ AUTO SELL RARITY","Aktif!",2)
    else      CustomNotify("⚡ AUTO SELL RARITY","Nonaktif",2) end
end, "lblSellByRarityAuto")

-- Background loop: jual otomatis setiap interval detik
task.spawn(function()
    local elapsed = 0
    while true do
        task.wait(1)
        if EngineConfig.SellByRarityActive then
            elapsed = elapsed + 1
            if elapsed >= math.max(EngineConfig.SellByRarityInterval or 3, 1) then
                elapsed = 0; doSellByRarity()
            end
        else
            elapsed = 0
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
CreateSection(SellPage, "Inventory Management", "secInventory")

local MainGui = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainGui")
local EquipmentScroll = MainGui:FindFirstChild("ScreenBackpack") and MainGui.ScreenBackpack:FindFirstChild("InventoryFrame") and MainGui.ScreenBackpack.InventoryFrame:FindFirstChild("EquipmentContent") and MainGui.ScreenBackpack.InventoryFrame.EquipmentContent:FindFirstChild("ScrollingFrame")
local OresScroll      = MainGui:FindFirstChild("ScreenEquipSell") and MainGui.ScreenEquipSell:FindFirstChild("SellFrame") and MainGui.ScreenEquipSell.SellFrame:FindFirstChild("OresContent") and MainGui.ScreenEquipSell.SellFrame.OresContent:FindFirstChild("ScrollingFrame")
local MaterialsScroll = MainGui:FindFirstChild("ScreenEquipSell") and MainGui.ScreenEquipSell:FindFirstChild("SellFrame") and MainGui.ScreenEquipSell.SellFrame:FindFirstChild("MaterialContent") and MainGui.ScreenEquipSell.SellFrame.MaterialContent:FindFirstChild("ScrollingFrame")

local BulkSelectedUUIDs = {}
local SELL_CATEGORIES   = {"All","Weapon","Helmet","Breastplate","Ore","Material"}

_G.SellCategoryDropdown = CreateDropdownUI(SellPage, "Kategori", SELL_CATEGORIES, EngineConfig.SellCategory, function(v) EngineConfig.SellCategory = v end, "lblSellCategory")

local ItemResultContainer = Instance.new("ScrollingFrame", SellPage)
ItemResultContainer.Name = "IRC"; ItemResultContainer.Size = UDim2.new(1, 0, 0, 200)
ItemResultContainer.BackgroundTransparency = 1; ItemResultContainer.ScrollBarThickness = 3; ItemResultContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
Instance.new("UIListLayout", ItemResultContainer).Padding = UDim.new(0, 5)

local function sellSpesifikNamaItem(listUUIDs, tipeItem)
    if not listUUIDs or #listUUIDs == 0 then return end
    if tipeItem == "Material" then pcall(function() MaterialRE:FireServer("Sell", listUUIDs, {}) end)
    elseif tipeItem == "Ore" then pcall(function() ForgeRF:InvokeServer("Sell", listUUIDs) end)
    else pcall(function() EquipmentRE:FireServer("Sell", listUUIDs) end) end
end

local function runInventoryScanner(parentFrame, filterCategory)
    for _, c in ipairs(parentFrame:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
    local db = {}; for _, cat in ipairs(SELL_CATEGORIES) do db[cat] = {} end
    local function insertDB(cat, id, uuid, visual)
        if not db[cat][id] then db[cat][id] = {Visual=visual,UUIDs={},OriginalCategory=cat} end
        table.insert(db[cat][id].UUIDs, uuid)
        if not db["All"][id] then db["All"][id] = {Visual=visual,UUIDs={},OriginalCategory=cat} end
        table.insert(db["All"][id].UUIDs, uuid)
    end
    if EquipmentScroll then
        for _, slot in ipairs(EquipmentScroll:GetChildren()) do
            if slot:IsA("GuiObject") and slot.Name ~= "UIListLayout" and slot.Name ~= "UIPadding" then
                local vis = slot.Name; local nl = slot:FindFirstChild("ItemName",true) or slot:FindFirstChild("Name",true)
                if nl and nl:IsA("TextLabel") then vis = nl.Text end
                local uuid = slot:GetAttribute("UUID") or slot.Name
                local uo = slot:FindFirstChild("UUID",true)
                if uo then uuid = uo:IsA("ValueBase") and uo.Value or uo.Text end
                local check = string.lower(vis.." "..slot.Name); local cat = "Weapon"
                if check:find("body") or check:find("plate") or check:find("armor") then cat = "Breastplate"
                elseif check:find("helm") or check:find("head") or check:find("hat") then cat = "Helmet" end
                insertDB(cat, vis, uuid, vis)
            end
        end
    end
    local function scrapeStackables(sg, cn)
        if not sg then return end
        for _, slot in ipairs(sg:GetChildren()) do
            if slot:IsA("GuiObject") and slot.Name ~= "UIListLayout" and slot.Name ~= "UIPadding" then
                local idAsli = slot.Name; local io = slot:FindFirstChild("ID",true)
                if io then idAsli = io:IsA("ValueBase") and tostring(io.Value) or io.Text end
                local nl = slot:FindFirstChild("ItemName",true) or slot:FindFirstChild("Name",true)
                local vis = idAsli; if nl and nl:IsA("TextLabel") then vis = nl.Text end
                insertDB(cn, idAsli, idAsli, vis)
            end
        end
    end
    scrapeStackables(OresScroll, "Ore"); scrapeStackables(MaterialsScroll, "Material")
    for targetID, dataObj in pairs(db[filterCategory]) do
        local storageKey = dataObj.OriginalCategory.."_"..targetID
        if (dataObj.OriginalCategory=="Ore" or dataObj.OriginalCategory=="Material") and EngineConfig.AutoSellStaticList[storageKey] then
            BulkSelectedUUIDs[storageKey] = {UUIDs=dataObj.UUIDs,Type=dataObj.OriginalCategory}
        end
        local totalItem = #dataObj.UUIDs; local btnText = dataObj.Visual.." [x"..totalItem.."]"
        local ItemBtn = Instance.new("TextButton", parentFrame)
        ItemBtn.Name = "IR"; ItemBtn.Size = UDim2.new(1,-10,0,32); ItemBtn.Font = Enum.Font.GothamMedium; ItemBtn.TextSize = 12
        ItemBtn.TextXAlignment = Enum.TextXAlignment.Left; ItemBtn.TextColor3 = Color3.fromRGB(255,255,255); ItemBtn.BorderSizePixel = 0
        Instance.new("UICorner", ItemBtn).CornerRadius = UDim.new(0, 6)
        local function refreshBtnVis()
            if BulkSelectedUUIDs[storageKey] then ItemBtn.BackgroundColor3 = Color3.fromRGB(40,90,50); ItemBtn.Text = "  ✅ "..btnText
            else ItemBtn.BackgroundColor3 = Color3.fromRGB(28,28,40); ItemBtn.Text = "  • "..btnText end
        end
        refreshBtnVis()
        ItemBtn.MouseButton1Click:Connect(function()
            if BulkSelectedUUIDs[storageKey] then
                BulkSelectedUUIDs[storageKey] = nil
                if dataObj.OriginalCategory=="Ore" or dataObj.OriginalCategory=="Material" then EngineConfig.AutoSellStaticList[storageKey] = nil end
            else
                BulkSelectedUUIDs[storageKey] = {UUIDs=dataObj.UUIDs,Type=dataObj.OriginalCategory}
                if dataObj.OriginalCategory=="Ore" or dataObj.OriginalCategory=="Material" then EngineConfig.AutoSellStaticList[storageKey] = true end
            end; refreshBtnVis()
        end)
    end
end

CreateButton(SellPage, "🔄 Scan Inventory", function()
    runInventoryScanner(ItemResultContainer, EngineConfig.SellCategory)
    CustomNotify("SCANNER","Kategori: "..EngineConfig.SellCategory,2)
end, "btnScanInventory")
CreateButton(SellPage, "💰 Execute Sell", function()
    local eq, ore, mat, cnt = {},{},{},0
    for _, d in pairs(BulkSelectedUUIDs) do
        for _, uuid in ipairs(d.UUIDs) do
            if d.Type=="Material" then table.insert(mat,uuid)
            elseif d.Type=="Ore" then table.insert(ore,uuid)
            else table.insert(eq,uuid) end; cnt = cnt+1
        end
    end
    if cnt == 0 then CustomNotify("SELL WARN","Tidak ada item!",3); return end
    if #eq  > 0 then sellSpesifikNamaItem(eq,"Equipment") end
    if #ore > 0 then sellSpesifikNamaItem(ore,"Ore") end
    if #mat > 0 then sellSpesifikNamaItem(mat,"Material") end
    task.wait(0.5); BulkSelectedUUIDs = {}
    runInventoryScanner(ItemResultContainer, EngineConfig.SellCategory)
    CustomNotify("SELL","Jual massal ("..cnt.." item) selesai.",3)
end, "btnExecuteSell")

CreateSection(SellPage, "Merchant System", "secMerchant")
CreateButton(SellPage, "🛒 Buka Merchant", function()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart"); local prompt = nil
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local txt = (v.ObjectText..v.ActionText):lower()
            if v.Parent.Name:lower():match("merchant") or txt:match("merchant") or v.Parent.Name:lower():match("shop") or txt:match("shop") then
                prompt = v; break end
        end
    end
    if prompt and prompt.Parent:IsA("BasePart") then
        CombatEngine.ResetPhysics(hrp); hrp.CFrame = prompt.Parent.CFrame*CFrame.new(0,2,0); task.wait(0.3)
        if fireproximityprompt then fireproximityprompt(prompt); CustomNotify("MERCHANT","Terbuka!",3)
        else CustomNotify("WARN","Executor tidak support fireproximityprompt",3) end
    else CustomNotify("MERCHANT ERROR","Gagal menemukan Merchant!",4) end
end, "btnOpenMerchant")


--------------------------------------------------------------------------------

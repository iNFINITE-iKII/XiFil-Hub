--------------------------------------------------------------------------------
--// ui/tab_autobuy.lua — S22 Tab 6: Auto Buy
--------------------------------------------------------------------------------
local H            = getgenv().Hub
local EngineConfig = H.EngineConfig
local Services     = H.Services
local LocalPlayer  = H.LocalPlayer
local CustomNotify = H.CustomNotify
local RegisterTranslation         = H.RegisterTranslation
local FindGoldShopScrollingFrame  = H.FindGoldShopScrollingFrame
local FindSeasonShopScrollingFrame = H.FindSeasonShopScrollingFrame
local CreateTab      = H.CreateTab
local CreateSection  = H.CreateSection
local CreateToggleUI = H.CreateToggleUI
local CreateCycleUI  = H.CreateCycleUI
local CreateButton   = H.CreateButton

-- [S22] TAB 6 — AUTO BUY
--------------------------------------------------------------------------------
local BuyPage = CreateTab("🛒 Auto Buy", "tabBuy")
CreateSection(BuyPage, "Gold Shop Auto-Buyer", "secGoldShop")

-- Kategori aktif: "Gold", "Bond", atau "Both"
local BuyCategory = "Gold"

-- Pilihan kategori (tab mini)
local CatFrame = Instance.new("Frame", BuyPage)
CatFrame.Size = UDim2.new(1,0,0,30); CatFrame.BackgroundTransparency = 1
local CatLayout = Instance.new("UIListLayout", CatFrame)
CatLayout.FillDirection = Enum.FillDirection.Horizontal
CatLayout.Padding = UDim.new(0,4); CatLayout.SortOrder = Enum.SortOrder.LayoutOrder

local catButtons = {}
-- [UPDATE] Menambahkan dukungan 'langKey' untuk Auto-Translate
local function makeCatBtn(label, cat, langKey)
    local b = Instance.new("TextButton", CatFrame)
    b.Size = UDim2.new(0,80,1,0); b.BorderSizePixel = 0
    b.Font = Enum.Font.GothamMedium; b.TextSize = 11
    b.TextColor3 = Color3.fromRGB(255,255,255)
    b.BackgroundColor3 = cat == BuyCategory and Color3.fromRGB(40,100,180) or Color3.fromRGB(35,35,55)
    b.Text = label
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
    catButtons[cat] = b
    
    -- Mendaftarkan tombol ini ke S10 Translate System
    if langKey then RegisterTranslation(langKey, b, "Text") end

    b.MouseButton1Click:Connect(function()
        BuyCategory = cat
        for k, cb in pairs(catButtons) do
            cb.BackgroundColor3 = k == cat and Color3.fromRGB(40,100,180) or Color3.fromRGB(35,35,55)
        end
    end)
end

-- Menyisipkan langKey ke masing-masing tombol
makeCatBtn("💰 Grocery",  "Gold",   "btnCatGrocery")
makeCatBtn("💎 Bond Shop", "Bond",  "btnCatBond")
makeCatBtn("🌸 Season",   "Season","btnCatSeason")
makeCatBtn("🌐 All",      "Both",  "btnCatAll")

local BuyButtonsRef = {}
local ShopListContainer = Instance.new("ScrollingFrame", BuyPage)
ShopListContainer.Name = "SLC"; ShopListContainer.Size = UDim2.new(1,0,0,200); ShopListContainer.BackgroundTransparency = 1
ShopListContainer.ScrollBarThickness = 3; ShopListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
local SLL = Instance.new("UIListLayout",ShopListContainer); SLL.Padding = UDim.new(0,4); SLL.SortOrder = Enum.SortOrder.LayoutOrder

-- [UPDATE] Menyisipkan "lblEnableAutoBuy" di akhir parameter untuk auto translate
_G.AutoBuyToggle = CreateToggleUI(BuyPage, "🛒 Enable Multi Auto-Buy", EngineConfig.AutoBuyActive, function(v)
    local cnt = 0; for _ in pairs(EngineConfig.AutoBuyTargetList) do cnt = cnt+1 end
    if v and cnt == 0 then CustomNotify("AUTO BUY WARN","Pilih item dulu!",3); EngineConfig.AutoBuyActive = false; _G.AutoBuyToggle:SetValue(false); return end
    -- Season beli via FireServer (tidak butuh GUI terbuka); cek shop hanya kalau ada target Gold/Bond
    local needsShop = false
    for k in pairs(EngineConfig.AutoBuyTargetList) do
        if not k:find("^SeasonShop_") then needsShop = true; break end
    end
    if v and needsShop and not FindGoldShopScrollingFrame() then CustomNotify("AUTO BUY WARN","Buka toko Consumable dulu!",3); EngineConfig.AutoBuyActive = false; _G.AutoBuyToggle:SetValue(false); return end
    EngineConfig.AutoBuyActive = v; CustomNotify("AUTO BUY", v and ("Berjalan! ("..cnt.." item)") or "Dimatikan.",2)
end, "lblEnableAutoBuy")

CreateButton(BuyPage, "🔄 Scan Shop", function()
    for _, c in ipairs(ShopListContainer:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    table.clear(BuyButtonsRef)

    local total = 0

    -- Cari nama visual dari item GUI: coba NameTXT dulu, lalu fallback ke
    -- TextLabel/TextButton pertama yang non-numerik dan non-kosong.
    local function getVisualName(item, fallback)
        local nameTXT = item:FindFirstChild("NameTXT", true)
        if nameTXT and nameTXT.Text ~= "" then return nameTXT.Text end
        -- Rekursif cari TextLabel/TextButton bermakna
        local function search(parent)
            for _, child in ipairs(parent:GetChildren()) do
                if (child:IsA("TextLabel") or child:IsA("TextButton"))
                    and child.Text ~= ""
                    and not child.Text:match("^%s*%d+%s*$")   -- bukan angka murni
                    and not child.Text:match("^%s*[×x]")      -- bukan quantity marker
                then
                    return child.Text
                end
                local found = search(child)
                if found then return found end
            end
        end
        return search(item) or fallback
    end

    -- Helper: scan satu ScrollingFrame, buat tombol item
    local function scanSF(sf, prefixes, source)
        for _, item in ipairs(sf:GetChildren()) do
            local match = false
            for _, pfx in ipairs(prefixes) do
                if item.Name:find(pfx, 1, true) then match = true; break end
            end
            if match then
                local stockTXT    = item:FindFirstChild("StockTXT", true)
                local stok        = tonumber(stockTXT and stockTXT.Text:match("%d+"))
                local displayName = getVisualName(item, item.Name)
                -- Badge berdasarkan currency: Gold_ = 💰, Bond_ = 💎
                local badge = item.Name:sub(1,5) == "Gold_" and "💰"
                           or item.Name:find("SeasonShop_", 1, true) and "🌸"
                           or "💎"
                total = total + 1

                local btn = Instance.new("TextButton", ShopListContainer)
                btn.Size = UDim2.new(1,-10,0,30)
                btn.Font = Enum.Font.GothamMedium; btn.TextSize = 11
                btn.TextXAlignment = Enum.TextXAlignment.Left; btn.BorderSizePixel = 0
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

                if not stockTXT or stok == 0 or stok == 10 then
                    -- Stok 0/10 atau tidak ada StockTXT: tampilkan item tanpa angka stok
                    btn.Text = "  " .. badge .. " " .. displayName
                else
                    btn.Text = "  " .. badge .. " " .. displayName .. "  [" .. stok .. "]"
                end

                btn.BackgroundColor3 = EngineConfig.AutoBuyTargetList[item.Name] and Color3.fromRGB(30,100,50) or Color3.fromRGB(28,28,40)
                btn.TextColor3 = Color3.fromRGB(255,255,255)

                btn.MouseButton1Click:Connect(function()
                    if EngineConfig.AutoBuyTargetList[item.Name] then
                        EngineConfig.AutoBuyTargetList[item.Name] = nil
                        btn.BackgroundColor3 = Color3.fromRGB(28,28,40)
                    else
                        EngineConfig.AutoBuyTargetList[item.Name] = true
                        btn.BackgroundColor3 = Color3.fromRGB(30,100,50)
                    end
                end)

                BuyButtonsRef[item.Name] = {
                    Button = btn,
                    Name   = displayName,
                    Badge  = badge,
                    Source = source,  -- "GoldBond" atau "Season"
                }
            end
        end
    end

    -- Consumable Shop (Gold + Bond)
    if BuyCategory == "Gold" or BuyCategory == "Bond" or BuyCategory == "Both" then
        local sf = FindGoldShopScrollingFrame()
        if sf then
            local pfx = {}
            -- Prefix berdasarkan currency (bukan shop):
            -- Gold_ = bayar gold (GoldShop & BondShop), Bond_ = bayar bond
            if BuyCategory == "Gold" or BuyCategory == "Both" then
                table.insert(pfx, "Gold_GoldShop")
                table.insert(pfx, "Gold_BondShop")
            end
            if BuyCategory == "Bond" or BuyCategory == "Both" then
                table.insert(pfx, "Bond_BondShop")
            end
            scanSF(sf, pfx, "GoldBond")
        else
            local pgui    = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local mainGui = pgui    and pgui:FindFirstChild("MainGui")
            local screen  = mainGui and mainGui:FindFirstChild("ScreenConsumableShop")
            local content = screen  and screen:FindFirstChild("Content")
            print("[XIFIL BUY] DEBUG CONSUMABLE PATH:")
            print("  PlayerGui =", pgui    and pgui.Name    or "NIL")
            print("  MainGui   =", mainGui and mainGui.Name or "NIL")
            print("  Screen    =", screen  and screen.Name  or "NIL")
            print("  Content   =", content and content.Name or "NIL")
            if content then for _, ch in ipairs(content:GetChildren()) do print("  child:", ch.Name, ch.ClassName) end end
            if BuyCategory ~= "Both" then CustomNotify("ERROR","Consumable Shop tidak ditemukan! Cek Output.",5); return end
        end
    end

    -- Season Shop — scan NormalFrame + SpecialFrame
    -- Nama visual di-hardcode karena MouseButton1Click:Fire() tidak trigger handler GUI
    local SEASON_NAMES = {
        SeasonShop_01 = "Storm Eagle",
        SeasonShop_02 = "Wyvern Bloom",
        SeasonShop_03 = "Horn Spire",
        SeasonShop_04 = "Crown Claw",
        SeasonShop_05 = "Race Reroll",
        SeasonShop_06 = "Season Ticket",
        SeasonShop_07 = "Rotten Lotus",
        SeasonShop_08 = "Crystal Gem x3",
        SeasonShop_09 = "Crystal Prism x3",
        SeasonShop_10 = "Dragon Tear x3",
        SeasonShop_11 = "?",
        SeasonShop_12 = "?",
        SeasonShop_13 = "Cave Ticket",
        SeasonShop_14 = "Rune Crack",
        SeasonShop_15 = "Gold Coin x1500",
        SeasonShop_16 = "Gold Potion",
        SeasonShop_17 = "Exp Potion",
        SeasonShop_18 = "Fate Potion",
        SeasonShop_19 = "Harvest Potion",
        SeasonShop_20 = "Attack Potion",
        SeasonShop_21 = "Life Potion",
        SeasonShop_22 = "Berserker Potion",
    }

    if BuyCategory == "Season" or BuyCategory == "Both" then
        local pgui       = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local ignoreGui  = pgui and pgui:FindFirstChild("MainGuiIgnoreGuiInset")
        local seasonScr  = ignoreGui and ignoreGui:FindFirstChild("ScreenSeasonPass")
        local stats      = seasonScr and seasonScr:FindFirstChild("StoreStatistics")

        if not stats then
            print("[XIFIL BUY] Season Shop tidak ditemukan — buka toko Season dulu")
            if BuyCategory ~= "Both" then CustomNotify("ERROR","Season Shop tidak ditemukan! Buka toko Season dulu.",5); return end
        else
            for _, frameName in ipairs({"NormalFrame", "SpecialFrame"}) do
                local frame = stats:FindFirstChild(frameName)
                local sf    = frame and frame:FindFirstChild("ScrollingFrame")
                if not sf then continue end

                for _, item in ipairs(sf:GetChildren()) do
                    if not item.Name:find("^SeasonShop_") then continue end

                    local displayName = SEASON_NAMES[item.Name] or item.Name

                    -- Baca harga: child bernama "Count" dengan teks angka murni
                    local price = ""
                    for _, desc in ipairs(item:GetDescendants()) do
                        if desc.Name == "Count"
                            and (desc:IsA("TextLabel") or desc:IsA("TextButton"))
                            and desc.Text:match("^%d+$")
                        then
                            price = desc.Text; break
                        end
                    end

                    total = total + 1

                    local priceTag = price ~= "" and ("  🎫" .. price) or ""

                    local btn = Instance.new("TextButton", ShopListContainer)
                    btn.Size = UDim2.new(1,-10,0,30)
                    btn.Font = Enum.Font.GothamMedium; btn.TextSize = 11
                    btn.TextXAlignment = Enum.TextXAlignment.Left; btn.BorderSizePixel = 0
                    Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

                    -- Season tidak tampilkan stok
                    btn.Text = "  🌸 " .. displayName .. priceTag

                    btn.BackgroundColor3 = EngineConfig.AutoBuyTargetList[item.Name] and Color3.fromRGB(30,100,50) or Color3.fromRGB(28,28,40)
                    btn.TextColor3 = Color3.fromRGB(255,255,255)

                    btn.MouseButton1Click:Connect(function()
                        if EngineConfig.AutoBuyTargetList[item.Name] then
                            EngineConfig.AutoBuyTargetList[item.Name] = nil
                            btn.BackgroundColor3 = Color3.fromRGB(28,28,40)
                        else
                            EngineConfig.AutoBuyTargetList[item.Name] = true
                            btn.BackgroundColor3 = Color3.fromRGB(30,100,50)
                        end
                    end)

                    BuyButtonsRef[item.Name] = {
                        Button      = btn,
                        Name        = displayName,
                        Price       = price,
                        Badge       = "🌸",
                        Source      = "Season",
                        SeasonFrame = frameName,
                    }
                end
            end
        end
    end

    if total == 0 then
        CustomNotify("SCAN","0 item cocok. Cek nama di Output!",5)
    else
        CustomNotify("SHOP","Memuat "..total.." item ("..BuyCategory..").",3)
    end
end, "btnScanGoldShop")

-- Helper: dapatkan SF Season berdasarkan nama frame yang tersimpan di BuyButtonsRef
local function getSeasonSF(frameName)
    local pgui      = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local ignoreGui = pgui and pgui:FindFirstChild("MainGuiIgnoreGuiInset")
    local stats     = ignoreGui
        and ignoreGui:FindFirstChild("ScreenSeasonPass")
        and ignoreGui.ScreenSeasonPass:FindFirstChild("StoreStatistics")
    if not stats then return nil end
    local frame = stats:FindFirstChild(frameName or "SpecialFrame")
    return frame and frame:FindFirstChild("ScrollingFrame")
end

-- Background Loop untuk Update Stok Real-time (Anti Geser & Warna Aman)
task.spawn(function()
    while true do
        task.wait(2)
        if EngineConfig.AutoBuyActive and BuyButtonsRef then
            local sf = FindGoldShopScrollingFrame()

            for itemName, data in pairs(BuyButtonsRef) do
                local btn = data.Button
                if btn and btn.Parent then
                    -- Pilih SF yang tepat berdasarkan asal item
                    local parentSF = (data.Source == "Season")
                        and getSeasonSF(data.SeasonFrame)
                        or sf
                    if parentSF then
                        local item = parentSF:FindFirstChild(itemName)
                        if item then
                            if data.Source == "Season" then
                                -- Season: hanya tampil nama + harga, tanpa stok
                                local priceTag = (data.Price and data.Price ~= "") and ("  🎫" .. data.Price) or ""
                                btn.Text = "  🌸 " .. data.Name .. priceTag
                            else
                                -- Gold/Bond: tampil stok real-time
                                local stockTXT = item:FindFirstChild("StockTXT", true)
                                local stok     = tonumber(stockTXT and stockTXT.Text:match("%d+"))
                                if not stockTXT or stok == 0 or stok == 10 then
                                    btn.Text = "  " .. data.Badge .. " " .. data.Name
                                else
                                    btn.Text = "  " .. data.Badge .. " " .. data.Name .. "  [" .. stok .. "]"
                                end
                            end

                            -- Warna dikunci ketat ke status TargetList
                            btn.BackgroundColor3 = EngineConfig.AutoBuyTargetList[itemName] and Color3.fromRGB(30,100,50) or Color3.fromRGB(28,28,40)
                        end
                    end
                end
            end
        end
    end
end)



--------------------------------------------------------------------------------

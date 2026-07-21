--------------------------------------------------------------------------------
--// ui/tab_autobuy.lua — S22 Tab 6: Auto Buy
--------------------------------------------------------------------------------
local H            = getgenv().Hub
local EngineConfig = H.EngineConfig
local Services     = H.Services
local LocalPlayer  = H.LocalPlayer
local CustomNotify = H.CustomNotify
local RegisterTranslation        = H.RegisterTranslation
local FindGoldShopScrollingFrame = H.FindGoldShopScrollingFrame
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
makeCatBtn("💰 Grocery",  "Gold", "btnCatGrocery")
makeCatBtn("💎 Bond Shop", "Bond", "btnCatBond")
makeCatBtn("🌐 All",  "Both", "btnCatAll")

local BuyButtonsRef = {}
local ShopListContainer = Instance.new("ScrollingFrame", BuyPage)
ShopListContainer.Name = "SLC"; ShopListContainer.Size = UDim2.new(1,0,0,200); ShopListContainer.BackgroundTransparency = 1
ShopListContainer.ScrollBarThickness = 3; ShopListContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
local SLL = Instance.new("UIListLayout",ShopListContainer); SLL.Padding = UDim.new(0,4); SLL.SortOrder = Enum.SortOrder.LayoutOrder

-- [UPDATE] Menyisipkan "lblEnableAutoBuy" di akhir parameter untuk auto translate
_G.AutoBuyToggle = CreateToggleUI(BuyPage, "🛒 Enable Multi Auto-Buy", EngineConfig.AutoBuyActive, function(v)
    local cnt = 0; for _ in pairs(EngineConfig.AutoBuyTargetList) do cnt = cnt+1 end
    if v and cnt == 0 then CustomNotify("AUTO BUY WARN","Pilih item dulu!",3); EngineConfig.AutoBuyActive = false; _G.AutoBuyToggle:SetValue(false); return end
    if v and not FindGoldShopScrollingFrame() then CustomNotify("AUTO BUY WARN","Buka toko dulu!",3); EngineConfig.AutoBuyActive = false; _G.AutoBuyToggle:SetValue(false); return end
    EngineConfig.AutoBuyActive = v; CustomNotify("AUTO BUY", v and ("Berjalan! ("..cnt.." item)") or "Dimatikan.",2)
end, "lblEnableAutoBuy")

CreateButton(BuyPage, "🔄 Scan Shop", function()
    for _, c in ipairs(ShopListContainer:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    table.clear(BuyButtonsRef)

    local sf = FindGoldShopScrollingFrame()
    if not sf then
        local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local mainGui = pgui and pgui:FindFirstChild("MainGui")
        local screen  = mainGui and mainGui:FindFirstChild("ScreenConsumableShop")
        local content  = screen and screen:FindFirstChild("Content")
        print("[XIFIL BUY] DEBUG PATH:")
        print("  PlayerGui =", pgui and pgui.Name or "NIL")
        print("  MainGui   =", mainGui and mainGui.Name or "NIL")
        print("  Screen    =", screen and screen.Name or "NIL")
        print("  Content   =", content and content.Name or "NIL")
        if content then
            for _, ch in ipairs(content:GetChildren()) do print("  Content child:", ch.Name, ch.ClassName) end
        end
        CustomNotify("ERROR","Toko tidak ditemukan! Cek Output.",5)
        return
    end

    local allChildren = sf:GetChildren()
    local total = 0
    local prefixes = {}
    if BuyCategory == "Gold" or BuyCategory == "Both" then table.insert(prefixes, "Gold_GoldShop") end
    if BuyCategory == "Bond" or BuyCategory == "Both" then table.insert(prefixes, "Bond_BondShop") end

    for _, item in ipairs(allChildren) do
        local match = false
        for _, pfx in ipairs(prefixes) do
            if item.Name:find(pfx) then match = true; break end
        end
        if match then
            local stockTXT = item:FindFirstChild("StockTXT", true)
            local nameTXT  = item:FindFirstChild("NameTXT",  true)
            local stok = tonumber(stockTXT and stockTXT.Text:match("%d+")) or 0
            local displayName = (nameTXT and nameTXT.Text ~= "") and nameTXT.Text or item.Name
            local badge = item.Name:find("Gold_GoldShop") and "💰" or "💎"
            total = total + 1
            
            local btn = Instance.new("TextButton", ShopListContainer)
            btn.Size = UDim2.new(1,-10,0,30)
            btn.Font = Enum.Font.GothamMedium; btn.TextSize = 11
            btn.TextXAlignment = Enum.TextXAlignment.Left; btn.BorderSizePixel = 0
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)
            
            -- Tampilan awal saat discan
            if stok == 0 or stok == 10 then
                btn.Text = "  ❌ " .. badge .. " " .. displayName .. "  [OUT OF STOCK]"
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
                Name = displayName, 
                Badge = badge 
            }
        end
    end

    if total == 0 then
        CustomNotify("SCAN","0 item cocok. Cek nama di Output!",5)
    else
        CustomNotify("SHOP","Memuat "..total.." item ("..BuyCategory..").",3)
    end
end, "btnScanGoldShop")

-- Background Loop untuk Update Stok Real-time (Anti Geser & Warna Aman)
task.spawn(function()
    while true do
        task.wait(2)
        if EngineConfig.AutoBuyActive and BuyButtonsRef then
            local sf = FindGoldShopScrollingFrame()
            if sf then
                for itemName, data in pairs(BuyButtonsRef) do
                    local btn = data.Button
                    if btn and btn.Parent then
                        local item = sf:FindFirstChild(itemName)
                        if item then
                            local stockTXT = item:FindFirstChild("StockTXT", true)
                            local stok = tonumber(stockTXT and stockTXT.Text:match("%d+")) or 0
                            
                            -- Menggunakan data asli dari tabel, teks dipastikan tidak menumpuk/bergeser
                            if stok == 0 or stok == 10 then
                                btn.Text = "  ❌ " .. data.Badge .. " " .. data.Name .. "  [OUT OF STOCK]"
                            else
                                btn.Text = "  " .. data.Badge .. " " .. data.Name .. "  [" .. stok .. "]"
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

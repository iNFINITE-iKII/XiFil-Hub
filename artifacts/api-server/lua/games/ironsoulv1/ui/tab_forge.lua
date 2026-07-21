--------------------------------------------------------------------------------
--// ui/tab_forge.lua — S23 Tab 7: Forge & Utilities
--------------------------------------------------------------------------------
local H            = getgenv().Hub
local EngineConfig = H.EngineConfig
local Services     = H.Services
local LocalPlayer  = H.LocalPlayer
local Workspace    = H.Workspace
local ForgeRF      = H.ForgeRF
local CombatEngine = H.CombatEngine
local CustomNotify = H.CustomNotify
local CreateTab     = H.CreateTab
local CreateSection = H.CreateSection
local CreateButton  = H.CreateButton

-- [S23] TAB 7 — FORGE & UTILITIES
--------------------------------------------------------------------------------
local ForgePage = CreateTab("🔨 Forge", "tabForge")

local ForgeUtil = require(Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("ForgeSystem"):WaitForChild("ForgeUtil"))
if not _G.OriginalQTE then _G.OriginalQTE = ForgeUtil.QTE end
ForgeUtil.QTE = function(...)
    local args = {...}; local data = nil
    for _, v in pairs(args) do if type(v) == "table" and v.UUID then data = v; break end end
    if data then
        task.spawn(function()
            for _=1,1 do ForgeRF:InvokeServer("QTE",{UUID=data.UUID,Rating=15}); task.wait() end
            for _=1,1 do ForgeRF:InvokeServer("ForgeFinish"); task.wait() end
            for _=1,1 do ForgeRF:InvokeServer("ForgeResult",true); task.wait() end
        end)
    end; return _G.OriginalQTE(...)
end

CreateSection(ForgePage, "Forge Utilities", "secForgeUtil")
CreateButton(ForgePage, "🚀 Bypass FORGE", function()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart"); local prompt = nil
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local txt = (v.ObjectText..v.ActionText):lower()
            if v.Parent.Name:lower():match("forge") or txt:match("forge") or v.Parent.Name:lower():match("craft") or txt:match("craft") then
                prompt = v; break end
        end
    end
    if prompt and prompt.Parent:IsA("BasePart") then
        CombatEngine.ResetPhysics(hrp); hrp.CFrame = prompt.Parent.CFrame*CFrame.new(0,2,0); task.wait(0.3)
        if fireproximityprompt then fireproximityprompt(prompt) end
    else CombatEngine.ResetPhysics(hrp); hrp.CFrame = CFrame.new(122.5,12,-45.8); task.wait(0.3) end
    pcall(function()
        local TaskRE = Services.ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Features"):WaitForChild("TaskSystem"):WaitForChild("TaskRE")
        TaskRE:FireServer("UpdateTaskProgress","OpenGUIWindow","ScreenForging")
    end, "btnForgeBypass")
    pcall(function()
        local FUI = LocalPlayer.PlayerGui:FindFirstChild("ScreenForging") or LocalPlayer.PlayerGui:FindFirstChild("ForgeGui")
        if FUI then for _, obj in pairs(FUI:GetChildren()) do if obj:IsA("Frame") then obj.Visible = true end end end
    end, "btnForgeBypass")
    CustomNotify("FORGE","TP & Bypass Berhasil.",3)
end)

local function TPAndOpenByKeyword(keywords, notifTitle)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp  = char:WaitForChild("HumanoidRootPart"); local prompt = nil
    for _, v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ProximityPrompt") then
            local txt = string.lower(v.ObjectText..v.ActionText..(v.Parent.Name)); local matched = false
            for _, kw in ipairs(keywords) do if txt:find(kw) then matched = true; break end end
            if matched then prompt = v; break end
        end
    end
    if prompt and prompt.Parent:IsA("BasePart") then
        CombatEngine.ResetPhysics(hrp); hrp.CFrame = prompt.Parent.CFrame*CFrame.new(0,2,0); task.wait(0.3)
        if fireproximityprompt then fireproximityprompt(prompt); CustomNotify(notifTitle,"UI berhasil dibuka!",3)
        else CustomNotify("WARN","Executor tidak support fireproximityprompt",3) end
    else CustomNotify(notifTitle.." ERROR","NPC tidak ditemukan!",4) end
end

CreateSection(ForgePage, "NPC Utility Access", "secNpcUtil")
CreateButton(ForgePage, "🔮 Open Enchantment & Runes",  function() TPAndOpenByKeyword({"enchant"},"ENCHANTMENT") end, "btnOpenEnchant")
CreateButton(ForgePage, "🛒 Open Grocery",              function() TPAndOpenByKeyword({"grocery","grocer"},"GROCERY") end, "btnOpenGrocery")
CreateButton(ForgePage, "🐾 Open Pet Upgrade",          function() TPAndOpenByKeyword({"pet","upgrade","petupgrade"},"PET UPGRADE") end, "btnOpenPetUpgrade")
CreateButton(ForgePage, "🏕️ Open Pet Expedition",      function() TPAndOpenByKeyword({"expedition","petexp"},"PET EXPEDITION") end, "btnOpenPetExp")
CreateButton(ForgePage, "✨ Open Upgrade Equipment",    function() TPAndOpenByKeyword({"bless","blessing"},"BLESS EQUIPMENT") end, "btnOpenBless")
CreateButton(ForgePage, "✨ Open The Guide",            function() TPAndOpenByKeyword({"guide","the"},"THE GUIDE") end, "btnOpenGuide")


--------------------------------------------------------------------------------

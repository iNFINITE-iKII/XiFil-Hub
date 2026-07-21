--------------------------------------------------------------------------------
--// ui/tab_profile.lua — S19 Tab 3: Profile / Config System
--------------------------------------------------------------------------------
local H            = getgenv().Hub
local EngineConfig = H.EngineConfig
local ConfigSystem = H.ConfigSystem
local Services     = H.Services
local LocalPlayer  = H.LocalPlayer
local CustomNotify = H.CustomNotify
local CreateTab          = H.CreateTab
local CreateSection      = H.CreateSection
local CreateToggleUI     = H.CreateToggleUI
local CreateCycleUI      = H.CreateCycleUI
local CreateInputUI      = H.CreateInputUI
local CreateDropdownUI   = H.CreateDropdownUI
local CreateButton       = H.CreateButton
local SyncAllVisualUI    = function(...) return H.SyncAllVisualUI(...) end  -- late-bound

-- [S19] TAB 3 — PROFILE
--------------------------------------------------------------------------------
local ProfilePage = CreateTab("💾 Profil", "tabProfile")
CreateSection(ProfilePage, "Data Profiles", "secDataProfile")
local selectedConfig = "None"; local newConfigName = ""

local ConfigDropdown = CreateDropdownUI(ProfilePage, "Selected Profile", ConfigSystem.GetConfigList(), "None", function(v) selectedConfig = v end, "lblSelectedProfile")
CreateInputUI(ProfilePage, "New Profile Name", "", false, function(v) newConfigName = tostring(v) end)

local function RefreshConfigDropdown(selectName)
    ConfigDropdown:SetValues(ConfigSystem.GetConfigList())
    if selectName then ConfigDropdown:SetValue(selectName); selectedConfig = selectName end
end

CreateButton(ProfilePage, "➕ Save New Profile", function()
    if newConfigName ~= "" then
        local ok, err = ConfigSystem.SaveNew(newConfigName)
        if ok then CustomNotify("CONFIG","'"..newConfigName.."' disimpan!",3); task.wait(0.05); RefreshConfigDropdown(newConfigName)
        else CustomNotify("SAVE ERROR",err,4) end
    else CustomNotify("CONFIG WARN","Ketik nama profile!",3) end
end, "btnSaveProfile")
CreateButton(ProfilePage, "📂 Load Profile", function()
    if selectedConfig ~= "None" then
        if ConfigSystem.Load(selectedConfig, function() SyncAllVisualUI() end) then CustomNotify("CONFIG","Dimuat: "..selectedConfig,3)
        else CustomNotify("CONFIG ERROR","File tidak valid.",3) end
    else CustomNotify("CONFIG WARN","Pilih profile!",3) end
end, "btnLoadProfile")
CreateButton(ProfilePage, "⚡ Set as Autoload", function()
    if selectedConfig == "None" then CustomNotify("AUTOLOAD","Pilih profile!",3); return end
    ConfigSystem.SaveAutoLoadPointer(selectedConfig)
    CustomNotify("⚡ AUTOLOAD SET","'"..selectedConfig.."' autoload aktif.",3)
end, "btnSetAutoload")
CreateButton(ProfilePage, "❌ Reset Autoload", function()
    ConfigSystem.SaveAutoLoadPointer("None"); CustomNotify("⚡ AUTOLOAD OFF","Autoload di-reset.",3)
end, "btnResetAutoload")
CreateButton(ProfilePage, "🔄 Overwrite Profile", function()
    local target = (newConfigName ~= "") and newConfigName or selectedConfig
    if target and target ~= "None" and target ~= "" then
        local ok, err = ConfigSystem.OverwriteExisting(target)
        if ok then CustomNotify("CONFIG","'"..target.."' ditimpa!",3); task.wait(0.05); RefreshConfigDropdown(target)
        else CustomNotify("OVERWRITE ERROR",err,4) end
    else CustomNotify("CONFIG WARN","Pilih profile valid!",3) end
end, "btnOverwriteProfile")
CreateButton(ProfilePage, "🗑️ Hapus Profile", function()
    if selectedConfig ~= "None" then
        if ConfigSystem.Delete(selectedConfig) then CustomNotify("CONFIG","Dihapus.",3); task.wait(0.05); RefreshConfigDropdown()
        else CustomNotify("CONFIG ERROR","Gagal hapus.",3) end
    else CustomNotify("CONFIG WARN","Pilih target!",3) end
end, "btnDeleteProfile")

CreateSection(ProfilePage, "System Guard", "secSystemGuard")
_G.AntiAFKToggle = CreateToggleUI(ProfilePage, "🛡️ Anti-AFK", EngineConfig.AntiAFKActive, function(state)
    EngineConfig.AntiAFKActive = state
    local VU = Services.VirtualUser
    if state then
        -- Proaktif: simulasi input tiap 14 menit (sebelum batas idle 20 menit)
        -- Cek setiap 1 detik agar bisa berhenti cepat saat dimatikan
        if not getgenv().AntiAFK_Loop then
            getgenv().AntiAFK_Loop = task.spawn(function()
                local elapsed = 0
                while EngineConfig.AntiAFKActive do
                    task.wait(1)
                    elapsed = elapsed + 1
                    if elapsed >= 840 then   -- 840 detik = 14 menit
                        elapsed = 0
                        pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
                    end
                end
                getgenv().AntiAFK_Loop = nil
            end)
        end
        CustomNotify("GUARD","Anti-AFK aktif.",2)
    else
        -- Stop loop (flag cukup; loop cek tiap 1d)
        getgenv().AntiAFK_Loop = nil
        CustomNotify("GUARD","Anti-AFK nonaktif.",2)
    end
end, "lblAntiAFK")
_G.AntiPausedToggle = CreateToggleUI(ProfilePage, "⏳ Disable Gameplay Paused", EngineConfig.AntiPausedActive, function(state)
    EngineConfig.AntiPausedActive = state
    Services.GuiService:SetGameplayPausedNotificationEnabled(not state)
    CustomNotify("GUARD", state and "Anti-Paused aktif." or "Nonaktif.", 2)
end, "lblAntiPaused")


--------------------------------------------------------------------------------

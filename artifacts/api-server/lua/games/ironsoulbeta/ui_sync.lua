--------------------------------------------------------------------------------
--// ui_sync.lua — S27 Sync All Visual UI
--------------------------------------------------------------------------------
local H              = getgenv().Hub
local VisualConfig   = H.VisualConfig
local EngineConfig   = H.EngineConfig
local ThemeRegistry  = H.ThemeRegistry
local ApplyTheme       = H.ApplyTheme
local ApplyFont        = H.ApplyFont
local ApplyTransparency = H.ApplyTransparency
local ApplyToggleShape  = H.ApplyToggleShape
local ApplyButtonShape  = H.ApplyButtonShape
local ClearBgEffect    = H.ClearBgEffect
local ApplyBgEffect    = H.ApplyBgEffect
local ApplyAllVisuals  = H.ApplyAllVisuals
local ApplyTranslations = H.ApplyTranslations
local getModeLabel     = H.getModeLabel
local isCaveWorld      = H.isCaveWorld
local isEndlessTower   = H.isEndlessTower

-- Clamp a stored RoomMode to the valid range for the given world + modeType.
-- Mirrors the logic in tab_room.lua:buildModeList.
local function _clampRoomMode(worldDisplay, modeType, mode)
    if isEndlessTower(worldDisplay) then return 1 end
    if isCaveWorld(worldDisplay)    then return math.clamp(mode, 1, 4) end
    if modeType == "Hell"           then return math.clamp(mode, 6, 10) end
    return math.clamp(mode, 1, 5)   -- Normal
end

-- [S27] SYNC ALL VISUAL UI
--------------------------------------------------------------------------------
function SyncAllVisualUI()
    pcall(function()
        -- [1] SYNC DATA GAME (EngineConfig)
        if _G.AutoFarmToggle        then _G.AutoFarmToggle:SetValue(EngineConfig.AutoFarmActive) end
        if _G.TargetMonsterToggle   then _G.TargetMonsterToggle:SetValue(EngineConfig.FarmTargetMonster) end
        if _G.TargetChestToggle     then _G.TargetChestToggle:SetValue(EngineConfig.FarmTargetChest) end
        if _G.TargetEggToggle       then _G.TargetEggToggle:SetValue(EngineConfig.FarmTargetEgg) end
        if _G.AutoAttackOnlyToggle  then _G.AutoAttackOnlyToggle:SetValue(EngineConfig.AutoAttackOnly) end
        if _G.ReplayToggle          then _G.ReplayToggle:SetValue(EngineConfig.AutoReplayActive) end
        if _G.WorldDropdown         then _G.WorldDropdown:SetValue(EngineConfig.SelectedWorld) end
        if _G.FarmMethodDropdown    then _G.FarmMethodDropdown:SetValue(EngineConfig.FarmMethod) end
        if _G.FarmPositionDropdown  then _G.FarmPositionDropdown:SetValue(EngineConfig.FarmPosition) end
        if _G.LerpAlphaInput        then _G.LerpAlphaInput:SetValue(EngineConfig.LerpAlpha) end
        if _G.AutoSkillToggle       then _G.AutoSkillToggle:SetValue(EngineConfig.AutoSkillActive) end
        if _G.SkillActive1Toggle    then _G.SkillActive1Toggle:SetValue(EngineConfig.SkillActive1) end
        if _G.SkillActive2Toggle    then _G.SkillActive2Toggle:SetValue(EngineConfig.SkillActive2) end
        if _G.SkillActiveUToggle    then _G.SkillActiveUToggle:SetValue(EngineConfig.SkillActiveU) end
        if _G.SkillCooldownInput    then _G.SkillCooldownInput:SetValue(EngineConfig.SkillCooldownDelay) end
        if _G.AutoSwitchToggle      then _G.AutoSwitchToggle:SetValue(EngineConfig.AutoWeaponSwitchActive) end
        if _G.HeightInput           then _G.HeightInput:SetValue(EngineConfig.StandHeight) end
        if _G.BossHeightInput       then _G.BossHeightInput:SetValue(EngineConfig.BossHeight) end
        if _G.RadiusInput           then _G.RadiusInput:SetValue(EngineConfig.OrbitRadius) end
        if _G.SpeedInput            then _G.SpeedInput:SetValue(EngineConfig.OrbitSpeed) end
        if _G.DelayInput            then _G.DelayInput:SetValue(EngineConfig.CFrameDelay) end
        if _G.MultiplierInput       then _G.MultiplierInput:SetValue(EngineConfig.HitMultiplier) end
        if _G.AntiAFKToggle         then _G.AntiAFKToggle:SetValue(EngineConfig.AntiAFKActive) end
        if _G.AntiPausedToggle      then _G.AntiPausedToggle:SetValue(EngineConfig.AntiPausedActive) end
        if _G.AutoExecuteToggle      then _G.AutoExecuteToggle:SetValue(EngineConfig.AutoExecuteOnRejoin) end
        if _G.AutoReturnLobbyToggle  then _G.AutoReturnLobbyToggle:SetValue(EngineConfig.AutoReturnLobbyActive) end
        if _G.SellCategoryDropdown  then _G.SellCategoryDropdown:SetValue(EngineConfig.SellCategory) end

        -- ── Room tab sync ──────────────────────────────────────────────────
        -- RoomWorldDropdown:SetValue() fires its callback which calls
        -- updateModeDropdown() → resets EngineConfig.RoomMode + RoomTarget.
        -- RoomModeTypeDropdown:SetValue() also calls updateModeDropdown()
        -- and resets RoomMode again.  Save all intended values first, then
        -- restore them after each overwriting callback.
        do
            local _rwd = EngineConfig.RoomWorldDisplay
            local _rp  = EngineConfig.RoomPlayers
            local _rt  = EngineConfig.RoomTarget

            -- Cave / Endless worlds are locked to Normal mode type
            local _rmt = (isCaveWorld(_rwd) or isEndlessTower(_rwd))
                          and "Normal" or EngineConfig.RoomModeType

            -- Clamp the stored mode to the valid range for this world + modeType
            local _rm = _clampRoomMode(_rwd, _rmt, EngineConfig.RoomMode)

            -- 1. Set World — callback resets RoomMode, RoomModeType, RoomTarget
            if _G.RoomWorldDropdown then _G.RoomWorldDropdown:SetValue(_rwd) end
            EngineConfig.RoomModeType = _rmt
            EngineConfig.RoomMode     = _rm
            EngineConfig.RoomTarget   = _rt

            -- 2. Set ModeType — callback calls updateModeDropdown → resets RoomMode
            if _G.RoomModeTypeDropdown then _G.RoomModeTypeDropdown:SetValue(_rmt) end
            EngineConfig.RoomMode = _rm

            -- 3. Set Mode dropdown (was missing entirely)
            if _G.RoomModeDropdown then _G.RoomModeDropdown:SetValue(getModeLabel(_rm)) end

            -- 4. Set Players dropdown (was missing entirely)
            if _G.RoomPlayersDropdown then _G.RoomPlayersDropdown:SetValue(_rp) end

            -- 5. Set Target Room (restored after World callback overwrote it)
            if _G.RoomTargetDropdown then _G.RoomTargetDropdown:SetValue(_rt) end
        end

        if _G.FriendOnlyToggle      then _G.FriendOnlyToggle:SetValue(EngineConfig.FriendOnlyRoom) end
        if _G.AutoJoinRoomToggle    then _G.AutoJoinRoomToggle:SetValue(EngineConfig.AutoJoinRoomActive) end
        if _G.AutoBuyToggle         then _G.AutoBuyToggle:SetValue(EngineConfig.AutoBuyActive) end
        -- ── Utilitas Tab sync ──────────────────────────────────────────────
        if _G.UtilLotteryCountInput  then _G.UtilLotteryCountInput:SetValue(tostring(EngineConfig.UtilLotteryCount or 15)) end
        if _G.UtilRaceSlotDropdown   then
            -- Map kunci string ke label display (2 slot saja)
            local _slotDisplayMap = { ["Free_1"]="Free 1", ["1"]="Slot 1" }
            local _raw = EngineConfig.UtilRaceSlot
            -- Normalisasi: nilai lama (integer) → default "Free 1"
            local _display = _slotDisplayMap[tostring(_raw) or ""] or "Free 1"
            _G.UtilRaceSlotDropdown:SetValue(_display)
        end
        if _G.UtilAutoRerollToggle   then _G.UtilAutoRerollToggle:SetValue(EngineConfig.UtilAutoRerollActive == true) end
        if _G.UtilCodeChecks then
            local _codes = H.UtilCodeList or {}
            for i, code in ipairs(_codes) do
                if _G.UtilCodeChecks[i] then
                    _G.UtilCodeChecks[i]:SetValue(EngineConfig.UtilSelectedCodes[code] == true)
                end
            end
        end
        if _G.UtilRaceChecks then
            local _races = H.UtilRaceList or {}
            for i, race in ipairs(_races) do
                if _G.UtilRaceChecks[i] then
                    _G.UtilRaceChecks[i]:SetValue(EngineConfig.UtilTargetRaces[race] == true)
                end
            end
        end
        if _G.SellByRarityToggle    then _G.SellByRarityToggle:SetValue(EngineConfig.SellByRarityActive) end
        if _G.SellByRarityIntervalInput then _G.SellByRarityIntervalInput:SetValue(tostring(EngineConfig.SellByRarityInterval)) end
        if _G.SellRarityChecks then
            local _RL = {"Common","Uncommon","Rare","Epic","Legendary","Mythical"}
            for i, r in ipairs(_RL) do
                if _G.SellRarityChecks[i] then
                    _G.SellRarityChecks[i]:SetValue(EngineConfig.SellByRarityList[r] == true)
                end
            end
        end

        -- [2] SYNC DATA TAMPILAN / VISUAL (VisualConfig)
        if _G.BgColorDropdown       then _G.BgColorDropdown:SetValue(VisualConfig.CurrentBg) end
        if _G.ThemeColorDropdown    then _G.ThemeColorDropdown:SetValue(VisualConfig.CurrentTheme) end
        if _G.TranspToggleUI        then _G.TranspToggleUI:SetValue(VisualConfig.TransparentMode) end
        if _G.TranspSliderUI        then _G.TranspSliderUI:SetValue(math.floor(VisualConfig.TransparencyLevel * 100)) end
        if _G.GestureModeDropdown   then _G.GestureModeDropdown:SetValue(VisualConfig.GestureMode) end
        if _G.TabModeDropdownUI     then _G.TabModeDropdownUI:SetValue(VisualConfig.TabMode) end
        if _G.NotifEnabledToggleUI  then _G.NotifEnabledToggleUI:SetValue(VisualConfig.NotifEnabled) end
        if _G.LangDropdownUI        then _G.LangDropdownUI:SetValue(VisualConfig.Language) end
        if _G.FontDropdownUI        then _G.FontDropdownUI:SetValue(VisualConfig.CurrentFont) end
        if _G.ToggleShapeDropdownUI then _G.ToggleShapeDropdownUI:SetValue(VisualConfig.ToggleShape) end
        if _G.BtnShapeDropdownUI    then _G.BtnShapeDropdownUI:SetValue(VisualConfig.ButtonShape) end
        if _G.AnimStyleDropdownUI   then _G.AnimStyleDropdownUI:SetValue(VisualConfig.AnimStyle) end
        if _G.BgEffectDropdownUI    then _G.BgEffectDropdownUI:SetValue(VisualConfig.BgEffect) end
        if _G.FontSizeInput then _G.FontSizeInput:SetValue(tostring(VisualConfig.FontSize or 8)) end
    end)
    
    -- Terapkan semua setting visual setelah data sinkron
    pcall(ApplyAllVisuals)
end

--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Export ke Hub
--------------------------------------------------------------------------------
H.SyncAllVisualUI = SyncAllVisualUI

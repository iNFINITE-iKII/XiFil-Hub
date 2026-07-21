--------------------------------------------------------------------------------
--// ui/tab_visual.lua — S24 Tampilan + S25 Font & Bentuk + S26 Efek & Animasi
--------------------------------------------------------------------------------
local H               = getgenv().Hub
local EngineConfig    = H.EngineConfig
local VisualConfig    = H.VisualConfig
local Services        = H.Services
local CustomNotify    = H.CustomNotify
local GUI_BACKGROUNDS = H.GUI_BACKGROUNDS
local BG_THEME_NAMES  = H.BG_THEME_NAMES
local THEME_NAMES     = H.THEME_NAMES
local FONT_LIST       = H.FONT_LIST
local ANIM_STYLES     = H.ANIM_STYLES
local TOGGLE_SHAPES   = H.TOGGLE_SHAPES
local BUTTON_SHAPES   = H.BUTTON_SHAPES
local BG_EFFECTS      = H.BG_EFFECTS
local LANGUAGES       = H.LANGUAGES
local ApplyTheme        = H.ApplyTheme
local ApplyFont         = H.ApplyFont
local ApplyToggleShape  = H.ApplyToggleShape
local ApplyButtonShape  = H.ApplyButtonShape
local ApplyTransparency = H.ApplyTransparency
local ApplyBgEffect     = H.ApplyBgEffect
local UpdateFontSize    = H.UpdateFontSize
local ApplyTranslations = H.ApplyTranslations
local CreateTab          = H.CreateTab
local CreateSection      = H.CreateSection
local CreateToggleUI     = H.CreateToggleUI
local CreateCycleUI      = H.CreateCycleUI
local CreateInputUI      = H.CreateInputUI
local CreateDropdownUI   = H.CreateDropdownUI
local CreateSliderUI     = H.CreateSliderUI
local CreateButton       = H.CreateButton
local ApplyBgColorTheme  = H.ApplyBgColorTheme
local ApplyTabMode       = H.ApplyTabMode
local CurrentLang        = H.CurrentLang   -- initial value; updates via H.CurrentLang

-- [S24] TAB 8 — TAMPILAN
--------------------------------------------------------------------------------
local AppearPage = CreateTab("🎨 Tampilan", "tabAppear")

CreateSection(AppearPage, "Notifikasi", "secNotif")
_G.NotifEnabledToggleUI = CreateToggleUI(AppearPage, "🔔 Tampilkan Notifikasi", VisualConfig.NotifEnabled, function(v)
    VisualConfig.NotifEnabled = v
    if v then CustomNotify("🔔 NOTIFIKASI", "Notifikasi diaktifkan", 2) end
end, "lblNotifEnabled")

CreateSection(AppearPage, "Warna Latar GUI", "secBgColor")
_G.BgColorDropdown = CreateDropdownUI(AppearPage, "Background", BG_THEME_NAMES, VisualConfig.CurrentBg, function(v)
    VisualConfig.CurrentBg = v; ApplyBgColorTheme(v)
end, "lblBackground")

CreateSection(AppearPage, "Tema Warna GUI", "secTheme")
_G.ThemeColorDropdown = CreateDropdownUI(AppearPage, "🎨 Tema Warna", THEME_NAMES, VisualConfig.CurrentTheme, function(v)
    VisualConfig.CurrentTheme = v; ApplyTheme()
    CustomNotify("🎨 TEMA","Tema diubah ke: "..v,2)
end, "lblTheme")

CreateSection(AppearPage, "Transparansi", "secTransp")
_G.TranspToggleUI = CreateToggleUI(AppearPage, "🌫️ Mode Transparan", VisualConfig.TransparentMode, function(v)
    VisualConfig.TransparentMode = v; ApplyTransparency()
    CustomNotify("🌫️ TRANSPARAN", v and "Aktif" or "Nonaktif", 2)
end, "lblTranspMode")

_G.TranspSliderUI = CreateSliderUI(AppearPage, "🔆 Level Transparansi", 0, 100, math.floor(VisualConfig.TransparencyLevel * 100), function(v)
    VisualConfig.TransparencyLevel = v / 100
    if VisualConfig.TransparentMode then ApplyTransparency() end
end, "lblLevel")

CreateSection(AppearPage, "Gesture & Open Button", "secGesture")
_G.GestureModeDropdown = CreateDropdownUI(AppearPage, "🖐️ Mode Buka GUI", { "Classic", "Keybind [F]" }, VisualConfig.GestureMode, function(v)
    VisualConfig.GestureMode = v; CustomNotify("🖐️ GESTURE","Mode buka: "..v,2)
end, "lblGesture")

CreateSection(AppearPage, "Mode Tab", "secTabMode")
_G.TabModeDropdownUI = CreateDropdownUI(AppearPage, "📑 Orientasi Tab", { "Horizontal", "Vertikal" }, VisualConfig.TabMode, function(v)
    VisualConfig.TabMode = v; ApplyTabMode(v)
    CustomNotify("📑 TAB","Mode: "..v,2)
end, "lblTabMode")

CreateSection(AppearPage, "Bahasa / Translate", "secLang")
_G.LangDropdownUI = CreateDropdownUI(AppearPage, "🌐 Bahasa", LANGUAGES, CurrentLang, function(v)
    H.SetLanguage(v); VisualConfig.Language = v; ApplyTranslations()
    CustomNotify("🌐 BAHASA","Bahasa: "..v,3)
end, "lblLang")

--------------------------------------------------------------------------------
-- [S25] TAB 9 — FONT & BENTUK
--------------------------------------------------------------------------------
local FontPage = CreateTab("🔤 Font", "tabFont")

CreateSection(FontPage, "Font GUI", "secFont")
_G.FontDropdownUI = CreateDropdownUI(FontPage, "🔤 Pilihan Font", FONT_LIST, VisualConfig.CurrentFont, function(v)
    VisualConfig.CurrentFont = v; ApplyFont()
    CustomNotify("🔤 FONT","Font diubah ke: "..v,2)
end, "lblFont")
CreateSection(FontPage, "Pengaturan Ukuran Font", "secFontSize")
-- FIX: Mengganti default text jadi angka 14 dan menambah parameter 'true' agar fungsi callback tidak tergeser (nil)
_G.FontSizeInput = CreateInputUI(FontPage, "Ukuran Font (Default 8)", 8, true, function(v)
    local num = tonumber(v)
    if num then
        VisualConfig.FontSize = num
        ApplyFont() -- Panggil fungsi untuk update semua teks di GUI
        CustomNotify("🔤SIZE FONT", "Ukuran diubah ke: "..num, 2)
    end
end)


CreateSection(FontPage, "Bentuk Sakelar (Toggle)", "secToggle")
_G.ToggleShapeDropdownUI = CreateDropdownUI(FontPage, "🔘 Bentuk Toggle", TOGGLE_SHAPES, VisualConfig.ToggleShape, function(v)
    VisualConfig.ToggleShape = v; ApplyToggleShape()
    CustomNotify("🔘 TOGGLE","Bentuk: "..v,2)
end, "lblToggle")

CreateSection(FontPage, "Bentuk Button Dropdown", "secBtnShape")
_G.BtnShapeDropdownUI = CreateDropdownUI(FontPage, "🟦 Bentuk Button", BUTTON_SHAPES, VisualConfig.ButtonShape, function(v)
    VisualConfig.ButtonShape = v; ApplyButtonShape()
    CustomNotify("🟦 BUTTON","Bentuk: "..v,2)
end, "lblBtnShape")

--------------------------------------------------------------------------------
-- [S26] TAB 10 — EFEK & ANIMASI
--------------------------------------------------------------------------------
local AnimPage = CreateTab("✨ Efek", "tabFx")

CreateSection(AnimPage, "Gaya Animasi Buka/Tutup", "secAnimStyle")
_G.AnimStyleDropdownUI = CreateDropdownUI(AnimPage, "✨ Animasi", ANIM_STYLES, VisualConfig.AnimStyle, function(v)
    VisualConfig.AnimStyle = v; CustomNotify("✨ ANIMASI","Gaya animasi: "..v,2)
end, "lblAnimStyle")

CreateSection(AnimPage, "Efek Latar & Partikel", "secBgFx")
_G.BgEffectDropdownUI = CreateDropdownUI(AnimPage, "🌟 Efek Latar", BG_EFFECTS, VisualConfig.BgEffect, function(v)
    VisualConfig.BgEffect = v; ApplyBgEffect(v)
    CustomNotify("🌟 EFEK","Efek latar: "..v,2)
end, "lblBgFx")

CreateSection(AnimPage, "Info", "secInfo")
local infoLbl = Instance.new("TextLabel", AnimPage)
infoLbl.BackgroundColor3 = Color3.fromRGB(18, 18, 28); infoLbl.Size = UDim2.new(1, 0, 0, 52)
infoLbl.BorderSizePixel = 0; infoLbl.Font = Enum.Font.Gotham
infoLbl.Text = "Partikel & efek berjalan secara real-time.\nUbah tema untuk menyesuaikan warna partikel."
infoLbl.TextColor3 = Color3.fromRGB(130, 130, 155); infoLbl.TextSize = 10; infoLbl.TextWrapped = true
Instance.new("UICorner", infoLbl).CornerRadius = UDim.new(0, 8)

--------------------------------------------------------------------------------

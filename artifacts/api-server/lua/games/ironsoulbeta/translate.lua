--------------------------------------------------------------------------------
--// translate.lua — S10 Translate System
--------------------------------------------------------------------------------
local H = getgenv().Hub

-- [S10] TRANSLATE SYSTEM
--------------------------------------------------------------------------------
local LANGUAGES = { "Indonesia", "English" }


local LANG_STRINGS = {
    Indonesia = {
        tabFarm="🏠 Farm", tabVector="⚙️ Vector", tabProfile="💾 Profil",
        tabSell="💰 Jual", tabRoom="🚪 Room", tabForge="🔨 Forge",
        tabAppear="🎨 Tampilan", tabFont="🔤 Font", tabFx="✨ Efek",
        secTheme="Tema Warna GUI", secTrans="Transparansi",
        secGesture="Gesture & Open Button", secTabMode="Mode Tab",
        secLang="Bahasa / Translate", secFont="Font GUI",
        secToggle="Bentuk Sakelar (Toggle)", secBtnShape="Bentuk Button Dropdown",
        secAnimStyle="Gaya Animasi Buka/Tutup", secBgFx="Efek Latar & Partikel",
        -- Nama Tab
        tabFarm="🌾 Farm",       tabVector="🎯 Vektor",   tabProfile="📋 Profil",
                tabBuy="🛒 Auto Beli",
        
        btnCatGrocery="💰 Toko Grosir",
        btnCatBond="💎 Toko Bond",
        btnCatAll="🌐 Semua",

        tabSell="🏪 Jual",       tabRoom="🗺️ Room",       tabForge="⚒️ Tempa",
        tabAppear="🖌️ Tampilan", tabFont="🔡 Font",       tabFx="🌟 Efek",
        -- Header Seksi (Game)
        secWorld="Dunia",
        secFarmEngine="Kontrol Mesin Farm",
        secMethodPos="Metode & Posisi Gerakan",
        secSkillCfg="Konfigurasi Skill",
        secWeapon="Ganti Senjata",
        secUtils="Utilitas",
        secFly="Terbang (Fly)",
        lblFly="✈️ Terbang",
        lblFlySpeed="⚡ Kecepatan Terbang",
        secTargetSel="Pilih Target",
        secDodgeBoss="Hindari Boss",
        secKinematic="Parameter Sistem Kinematik",
        secDataProfile="Data Profil",
        secSystemGuard="Penjaga Sistem",
        secInventory="Manajemen Inventaris",
        secMerchant="Sistem Pedagang",
        secMatchmake="Kontrol Matchmaking",
        secMatchActions="Aksi Match",
        secForgeUtil="Utilitas Tempa",
        secNpcUtil="Akses NPC Utilitas",
        secGoldShop="Pembeli Toko Emas",
        -- Header Seksi (Visual)
        secBgColor="Warna Latar GUI",
        secTheme="Tema Warna GUI",
        secTransp="Transparansi",
        secGesture="Tombol Buka & Gesture",
        secTabMode="Mode Tab",
        secLang="Bahasa / Terjemahan",
        secFont="Font GUI",
        secToggle="Bentuk Sakelar (Toggle)",
        secBtnShape="Bentuk Tombol Dropdown",
        secAnimStyle="Gaya Animasi Buka/Tutup",
        secBgFx="Efek Latar & Partikel",
        secNotif="Notifikasi",
        lblNotifEnabled="🔔 Tampilkan Notifikasi",
        secInfo="Info",
        lblTheme="🎨 Tema Warna", lblTransp="🌫️ Mode Transparan",
        lblEnableAutoBuy="🛒 Aktifkan Multi Auto-Buy",
        lblLevel="🔆 Level Transparansi", lblGesture="🖐️ Mode Buka GUI",
        lblTabMode="📑 Orientasi Tab", lblLang="🌐 Bahasa",
        lblFont="🔤 Pilihan Font", lblToggle="🔘 Bentuk Toggle",
        lblBtnShape="🟦 Bentuk Button", lblAnimStyle="✨ Animasi",
        -- Label Kontrol Game
        lblWorld="🌍 Dunia",
        lblAutoFarm="🌾 Auto Farm",
        lblFarmTargets="Target Auto Farm  (aktif saat Auto Farm ON)",
        lblMethod="Metode",
        lblPosition="Posisi Farm",
        lblKillAura="⚡ Kill Aura",
        lblAutoSkill="🎯 Aktifkan Auto Skill",
        lblSkillActive="Skill Aktif  (bisa pilih lebih dari 1)",
        lblWeaponSwitch="🎒 Auto Ganti Senjata (3d)",
        lblAutoReplay="🔄 Auto Ulangi",
        lblAutoExec="⚡ Auto Jalankan saat Pindah Server",
        lblNormalMob="Mob Normal",
        lblBossMob="Mob Boss",
        lblOrbitRadius="Radius Orbit",
        lblHeightNormal="Tinggi Target Normal (Y)",
        lblHeightBoss="Tinggi Target Boss (Y)",
        lblOrbitSpeed="Kecepatan Orbit",
        lblCFrameDelay="Jeda CFrame",
        lblHitMultiplier="Pengali Hit",
        lblLerpAlpha="Lerp Alpha (0-1)",
        lblSkillCooldown="Cooldown Skill (d)",
        lblSelectedProfile="Profil Dipilih",
        lblNewProfileName="Nama Profil Baru",
        lblAntiAFK="🛡️ Anti-AFK",
        lblAntiPaused="⏳ Nonaktifkan Gameplay Paused",
        lblSellCategory="Kategori",
        lblRoomWorld="Dunia",
        lblModeType="Tipe Mode",
        lblMode="Mode",
        lblPlayers="Jumlah Pemain",
        lblTargetRoom="Target Room",
        -- Label Kontrol Visual
        lblBackground="Latar Belakang",
        lblTheme="🎨 Tema Warna",
        lblTranspMode="🌫️ Mode Transparan",
        lblLevel="🔆 Level Transparansi",
        lblGesture="🖐️ Mode Buka GUI",
        lblTabMode="📑 Orientasi Tab",
        lblLang="🌐 Bahasa",
        lblFont="🔤 Pilihan Font",
        lblToggle="🔘 Bentuk Toggle",
        lblBtnShape="🟦 Bentuk Tombol",
        lblAnimStyle="✨ Gaya Animasi",
        lblBgFx="🌟 Efek Latar",
        -- Tombol
        btnScanMap="🔄 Scan Target Peta",
        btnDodge20="🎯 Hindari Boss Skill (20)",
        btnDodge200="🎯 Hindari Boss Skill (200)",
        btnSaveProfile="➕ Simpan Profil Baru",
        btnLoadProfile="📂 Muat Profil",
        btnSetAutoload="⚡ Jadikan Autoload",
        btnResetAutoload="❌ Reset Autoload",
        btnOverwriteProfile="🔄 Timpa Profil",
        btnDeleteProfile="🗑️ Hapus Profil",
        secSellByRarity="Auto Sell by Rarity",
        lblRaritySelect="Rarity yang dijual",
        lblSellByRarityInterval="Interval Auto Sell (detik)",
        btnSellByRarityNow="🗑️ Jual Sekarang (Rarity)",
        lblSellByRarityAuto="⚡ Auto Sell by Rarity",
        btnScanInventory="🔄 Scan Inventaris",
        btnExecuteSell="💰 Jual Sekarang",
        btnOpenMerchant="🛒 Buka Pedagang",
        btnCreateRoom="🛠️ Buat Room",
        btnTPRoom="🚀 TP ke Room",
        btnLeaveRoom="🚪 Keluar Room",
        lblFriendOnly="🔒 Friend Only Room",
        lblAutoJoinRoom="🔁 Auto Join Room",
        secRoomSettings="Pengaturan Room",
        secAutoRoom="Auto Room",
        lblAutoReturn="🏠 Auto Kembali ke Lobby",
        -- Tab Utilitas
        tabUtil="🔧 Utilitas",
        secUtilCode="Redeem Code",
        secUtilLottery="Auto Reroll Lottery",
        secUtilReward="Claim Reward Update",
        secUtilRace="Auto Reroll Race",
        lblUtilCodeSelect="Pilih Kode Redeem",
        btnUtilRedeem="🎁 Redeem Kode Terpilih",
        lblUtilLotteryCount="Jumlah Reroll Sekaligus",
        btnUtilLottery="🎰 Reroll Lottery Sekarang",
        btnUtilClaimReward="🏆 Claim Semua Reward Update",
        lblUtilRaceSlot="🎰 Race Slot",
        lblUtilRaceSelect="Target Race",
        lblUtilAutoReroll="🎲 Auto Reroll Race",
        btnScanGoldShop="🔄 Scan Toko ",
        btnForgeBypass="🚀 Bypass FORGE",
        btnOpenEnchant="🔮 Buka Enchantment & Rune",
        btnOpenGrocery="🛒 Buka Toko Bahan",
        btnOpenPetUpgrade="🐾 Buka Upgrade Pet",
        btnOpenPetExp="🏕️ Buka Ekspedisi Pet",
        btnOpenBless="✨ Buka Upgrade Equipment",
        btnOpenGuide="✨ Buka The Guide",
        -- Notifikasi & Judul
        infoText="Partikel & efek berjalan secara real-time.\nUbah tema untuk menyesuaikan warna partikel.",
        notifyTheme="Tema diubah ke: ", notifyFont="Font diubah ke: ",
        notifyGest="Mode buka: ", notifyTab="Mode: ",
        notifyLang="Bahasa: ", notifyLoad="GUI Berhasil Dimuat! v4.0",
        titleLoad="✦ XIFIL HUB",
        notifyTheme="Tema diubah ke: ",  notifyFont="Font diubah ke: ",
        notifyGest="Mode buka: ",        notifyTab="Mode: ",
        notifyLang="Bahasa: ",           notifyLoad="GUI Berhasil Dimuat! v4.0",
        titleLoad="✦ XIFIL HUB",
    },
    English = {
        tabFarm="🏠 Farm", tabVector="⚙️ Vector", tabProfile="💾 Profile",
        tabSell="💰 Sell", tabRoom="🚪 Room", tabForge="🔨 Forge",
        tabAppear="🎨 Appearance", tabFont="🔤 Font", tabFx="✨ Effects",
        secTheme="GUI Color Theme", secTrans="Transparency",
        secGesture="Gesture & Open Button", secTabMode="Tab Mode",
        secLang="Language / Translate", secFont="GUI Font",
        secToggle="Toggle Shape", secBtnShape="Dropdown Button Shape",
        secAnimStyle="Open/Close Animation Style", secBgFx="Background & Particle FX",
        -- Tab names
        tabFarm="🌾 Farm",         tabVector="🎯 Vector",     tabProfile="📋 Profile",
        tabSell="🏪 Sell",           tabBuy="🛒 Auto Buy",
        lblEnableAutoBuy="🛒 Enable Multi Auto-Buy",
        btnCatGrocery="💰 Grocery",
        btnCatBond="💎 Bond Shop",
        btnCatAll="🌐 All",

      tabRoom="🗺️ Room",         tabForge="⚒️ Forge",
        tabAppear="🖌️ Appearance", tabFont="🔡 Font",         tabFx="🌟 Effects",
        -- Section headers (Game)
        secWorld="World",
        secFarmEngine="Farm Engine Control",
        secMethodPos="Method & Movement Position",
        secSkillCfg="Skill Configuration",
        secWeapon="Weapon Switcher",
        secUtils="Utilities",
        secFly="Fly",
        lblFly="✈️ Fly",
        lblFlySpeed="⚡ Fly Speed",
        secTargetSel="Target Selector",
        secDodgeBoss="Dodge Boss",
        secKinematic="Kinematic System Parameters",
        secDataProfile="Profile Data",
        secSystemGuard="System Guard",
        secInventory="Inventory Management",
        secMerchant="Merchant System",
        secMatchmake="Matchmaking Control",
        secMatchActions="Match Actions",
        secForgeUtil="Forge Utilities",
        secNpcUtil="NPC Utility Access",
        secGoldShop="Gold Shop Auto-Buyer",
        -- Section headers (Visual)
        secBgColor="GUI Background Color",
        secTheme="GUI Color Theme",
        secTransp="Transparency",
        secGesture="Gesture & Open Button",
        secTabMode="Tab Mode",
        secLang="Language / Translate",
        secFont="GUI Font",
        secToggle="Toggle Shape",
        secBtnShape="Dropdown Button Shape",
        secAnimStyle="Open/Close Animation Style",
        secBgFx="Background & Particle FX",
        secNotif="Notifications",
        lblNotifEnabled="🔔 Show Notifications",
        secInfo="Info",
        lblTheme="🎨 Color Theme", lblTransp="🌫️ Transparent Mode",
        lblLevel="🔆 Transparency Level", lblGesture="🖐️ Open Mode",
        lblTabMode="📑 Tab Orientation", lblLang="🌐 Language",
        lblFont="🔤 Font Choice", lblToggle="🔘 Toggle Shape",
        lblBtnShape="🟦 Button Shape", lblAnimStyle="✨ Animation",
        -- Control labels (Game)
        lblWorld="🌍 World",
        lblAutoFarm="🌾 Auto Farm",
        lblFarmTargets="Auto Farm Target  (active when Farm ON)",
        lblMethod="Method",
        lblPosition="Farm Position",
        lblKillAura="⚡ Kill Aura",
        lblAutoSkill="🎯 Enable Auto Skill",
        lblSkillActive="Active Skills  (can select multiple)",
        lblWeaponSwitch="🎒 Auto Weapon Switcher (3s)",
        lblAutoReplay="🔄 Auto Play Again",
        lblAutoExec="⚡ Auto Exec on Server Hop/Rejoin",
        lblNormalMob="Normal Mob",
        lblBossMob="Boss Mob",
        lblOrbitRadius="Orbit Radius",
        lblHeightNormal="Height Normal Target (Y)",
        lblHeightBoss="Height Boss Target (Y)",
        lblOrbitSpeed="Orbit Speed",
        lblCFrameDelay="CFrame Delay",
        lblHitMultiplier="Hit Multiplier",
        lblLerpAlpha="Lerp Alpha (0-1)",
        lblSkillCooldown="Skill Cooldown (s)",
        lblSelectedProfile="Selected Profile",
        lblNewProfileName="New Profile Name",
        lblAntiAFK="🛡️ Anti-AFK",
        lblAntiPaused="⏳ Disable Gameplay Paused",
        lblSellCategory="Category",
        lblRoomWorld="World",
        lblModeType="Mode Type",
        lblMode="Mode",
        lblPlayers="Player Count",
        lblTargetRoom="Target Room",
        -- Control labels (Visual)
        lblBackground="Background",
        lblTheme="🎨 Color Theme",
        lblTranspMode="🌫️ Transparent Mode",
        lblLevel="🔆 Transparency Level",
        lblGesture="🖐️ Open Mode",
        lblTabMode="📑 Tab Orientation",
        lblLang="🌐 Language",
        lblFont="🔤 Font Choice",
        lblToggle="🔘 Toggle Shape",
        lblBtnShape="🟦 Button Shape",
        lblAnimStyle="✨ Animation Style",
        lblBgFx="🌟 Background FX",
        -- Buttons
        btnScanMap="🔄 Scan Map Targets",
        btnDodge20="🎯 Dodge Boss Skill (20)",
        btnDodge200="🎯 Dodge Boss Skill (200)",
        btnSaveProfile="➕ Save New Profile",
        btnLoadProfile="📂 Load Profile",
        btnSetAutoload="⚡ Set as Autoload",
        btnResetAutoload="❌ Reset Autoload",
        btnOverwriteProfile="🔄 Overwrite Profile",
        btnDeleteProfile="🗑️ Delete Profile",
        secSellByRarity="Auto Sell by Rarity",
        lblRaritySelect="Rarity to sell",
        lblSellByRarityInterval="Auto Sell Interval (sec)",
        btnSellByRarityNow="🗑️ Sell Now (Rarity)",
        lblSellByRarityAuto="⚡ Auto Sell by Rarity",
        btnScanInventory="🔄 Scan Inventory",
        btnExecuteSell="💰 Execute Sell",
        btnOpenMerchant="🛒 Open Merchant",
        btnCreateRoom="🛠️ Create Room",
        btnTPRoom="🚀 TP Room",
        btnLeaveRoom="🚪 Leave Room",
        lblFriendOnly="🔒 Friend Only Room",
        lblAutoJoinRoom="🔁 Auto Join Room",
        secRoomSettings="Room Settings",
        secAutoRoom="Auto Room",
        lblAutoReturn="🏠 Auto Return to Lobby",
        -- Util Tab
        tabUtil="🔧 Utilities",
        secUtilCode="Redeem Code",
        secUtilLottery="Auto Reroll Lottery",
        secUtilReward="Claim Reward Update",
        secUtilRace="Auto Reroll Race",
        lblUtilCodeSelect="Select Redeem Codes",
        btnUtilRedeem="🎁 Redeem Selected Codes",
        lblUtilLotteryCount="Reroll Count at Once",
        btnUtilLottery="🎰 Reroll Lottery Now",
        btnUtilClaimReward="🏆 Claim All Update Rewards",
        lblUtilRaceSlot="🎰 Race Slot",
        lblUtilRaceSelect="Target Race",
        lblUtilAutoReroll="🎲 Auto Reroll Race",
        btnScanGoldShop="🔄 Scan Gold Shop",
        btnForgeBypass="🚀 Bypass FORGE",
        btnOpenEnchant="🔮 Open Enchantment & Runes",
        btnOpenGrocery="🛒 Open Grocery",
        btnOpenPetUpgrade="🐾 Open Pet Upgrade",
        btnOpenPetExp="🏕️ Open Pet Expedition",
        btnOpenBless="✨ Open Upgrade Equipment",
        btnOpenGuide="✨ Open The Guide",
        -- Notifications & title
        infoText="Particles & effects run in real-time.\nChange theme to sync particle color.",
        notifyTheme="Theme changed to: ", notifyFont="Font changed to: ",
        notifyGest="Open mode: ", notifyTab="Mode: ",
        notifyLang="Language: ", notifyLoad="GUI Loaded! v4.0",
        titleLoad="✦ XIFIL HUB",
        notifyTheme="Theme changed to: ",  notifyFont="Font changed to: ",
        notifyGest="Open mode: ",          notifyTab="Mode: ",
        notifyLang="Language: ",           notifyLoad="GUI Loaded! v4.0",
        titleLoad="✦ XIFIL HUB",
    },
}

local CurrentLang = "Indonesia"
local TranslationRegistry = {}

local function T(key)
    local tbl = LANG_STRINGS[CurrentLang] or LANG_STRINGS["Indonesia"]
    return tbl[key] or key
end

local function RegisterTranslation(key, obj, prop)
    if not TranslationRegistry[key] then TranslationRegistry[key] = {} end
    table.insert(TranslationRegistry[key], { obj = obj, prop = prop })
end

local function RegisterTranslationFn(key, fn)
    if not TranslationRegistry[key] then TranslationRegistry[key] = {} end
    table.insert(TranslationRegistry[key], { custom = fn })
end

local function ApplyTranslations()
    local tbl = LANG_STRINGS[CurrentLang] or LANG_STRINGS["Indonesia"]
    for key, entries in pairs(TranslationRegistry) do
        local str = tbl[key] or key
        for _, entry in ipairs(entries) do
            if entry.custom then
                entry.custom(str)
            else
                pcall(function() entry.obj[entry.prop] = str end)
            end
        end
    end
end


local function SetLanguage(lang)
    if LANG_STRINGS[lang] then
        CurrentLang = lang
        H.CurrentLang = lang
    end
end

--------------------------------------------------------------------------------
-- Export ke Hub
--------------------------------------------------------------------------------
H.T                    = T
H.RegisterTranslation  = RegisterTranslation
H.RegisterTranslationFn = RegisterTranslationFn
H.ApplyTranslations    = ApplyTranslations
H.SetLanguage          = SetLanguage
H.CurrentLang          = CurrentLang  -- READ-ONLY: jangan assign langsung; gunakan H.SetLanguage()
H.LANGUAGES            = LANGUAGES

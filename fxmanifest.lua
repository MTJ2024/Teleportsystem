--[[
==========================================================
    MTJ Door & Teleport System
    Copyright © MTJScripts - All rights reserved.
    Unauthorized redistribution or resale is prohibited.
==========================================================
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'MTJScripts'
description 'MTJ Door System - Dynamic Door/Teleport/NPC Interaction Manager with In-Game Dashboard'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'shared/bridge.lua'
}

client_scripts {
    'client/main.lua',
    'client/creator.lua',
    'client/nui.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/permissions.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    -- Schriftarten optional - bei Bedarf entkommentieren und Dateien
    -- in html/fonts/ ablegen (siehe html/fonts/README.txt):
    -- 'html/fonts/pricedown.otf',
    -- 'html/fonts/chalet.otf'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_target',
    'oxmysql'
}

escrow_ignore {
    'config.lua',
    'shared/bridge.lua'
}

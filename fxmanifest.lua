fx_version 'cerulean'
game 'gta5'

name 'nova_fuel'
author 'NOVA Framework'
description 'Sistema de combustível para NOVA Framework'
version '1.0.0'

lua54 'yes'

ui_page 'html/index.html'

shared_script 'config.lua'

client_scripts {
    'client/main.lua',
    'client/stations.lua',
    'client/jerrycan.lua',
}

server_script 'server/main.lua'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}

dependencies {
    'nova_core',
    'nova_notify',
}

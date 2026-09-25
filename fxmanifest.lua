fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'val-resources'
author 'Vallen'
description 'Small quality-of-life components for Qbox, QBCore or standalone servers'
version '2.0.0'
license 'GPL-3.0'

shared_script 'config.lua'

client_scripts {
    'core/client.lua',
    'bridge/client.lua',
    'modules/**/client.lua',
}

server_scripts {
    'core/server.lua',
    'bridge/server.lua',
    'modules/**/server.lua',
}

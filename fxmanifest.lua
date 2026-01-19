fx_version 'cerulean'
game 'gta5'

version '1.0.9'
lua54 'yes'
author 'DemiAutomatic'

files {
    'web/*',
    'client/modules/*.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    -- 'test.lua' -- Uncomment this line to enable test commands
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/version.lua',
    'server/main.lua',
}

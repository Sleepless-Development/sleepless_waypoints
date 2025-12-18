fx_version 'cerulean'
game 'gta5'

version '1.0.1'
lua54 'yes'
author 'DemiAutomatic'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    -- 'test.lua' -- Uncomment this line to enable test commands
}

client_scripts {
    'client/modules/*.lua',
    'client/main.lua',
}

server_scripts {
    'server/modules/*.lua',
    'server/main.lua',
}

files {
    'web/*',
}

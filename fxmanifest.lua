
fx_version "cerulean"
game "gta5"

description "Daily Missions"
author "boynull"

lua54 'yes'

games { "gta5" }

ui_page 'web/index.html'

shared_scripts {
  '@vrp/lib/utils.lua',
  'shared/**'
}

server_scripts {
	"server/*",
}

client_scripts {
	"client/client.lua",
  "client/missions/online.lua",
}

files {
	'web/index.html',
	'web/script.js'
}
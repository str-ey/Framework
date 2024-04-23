fx_version('cerulean')
game('gta5')
lua54('yes')

shared_scripts({
	'common/modules/locale.lua',
	'common/locales/**/*.lua',
	'shared.lua',
	'config/**/*.lua',
})

client_scripts({
	'client/modules/common.lua',
	'client/functions.lua',
	'client/modules/callback.lua',
	'client/modules/timeout.lua',
	'client/main.lua',

	'client/modules/actions.lua',
	'client/modules/death.lua',
	'client/modules/game.lua',
	'client/modules/scaleform.lua',
	'client/modules/streaming.lua',

	'common/modules/math.lua',
	'common/modules/table.lua',
	'common/functions.lua',
})

server_scripts({
	'@oxmysql/lib/MySQL.lua',

	'server/modules/common.lua',
	'server/modules/timeout.lua',
	'server/modules/callback.lua',
	'server/classes/group.lua',
	'server/classes/player.lua',
	'server/functions.lua',
	'server/onesync.lua',
	'server/paycheck.lua',
	'server/main.lua',
	'server/commands.lua',

	'server/modules/actions.lua',

	'common/modules/math.lua',
	'common/modules/table.lua',
	'common/functions.lua',
})

dependency({'oxmysql'})
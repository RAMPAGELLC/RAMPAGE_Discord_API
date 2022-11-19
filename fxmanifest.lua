fx_version 'cerulean'
game 'gta5'

author 'RAMPAGE Interactive'
description 'RAMPAGE Interactive\'s Discord API'
version '1.6'
url 'https://github.com/RAMPAGELLC/RAMPAGE_Discord_API'

client_scripts {
	'client.lua',
}

server_scripts {
	'config.lua',
	"server.lua",
}

server_exports {
    -- API
	"DiscordRequest",
    "CheckEqual",

    -- Cache
    "PurgeCache",

    -- User
    "GetDiscordUsername",
	"GetDiscordRoles",
    "GetDiscordId",

    -- Guild
    "FetchRoleId",
    "GetRoleIdFromRoleName",
    "GetGuildRoleList",
    "GetGuildOnlineMemberCount",
    "GetGuildMemberCount",
    "GetGuildDescription",
    "GetGuildName",
    "GetGuildSplash",
    "GetGuildIcon",
} 
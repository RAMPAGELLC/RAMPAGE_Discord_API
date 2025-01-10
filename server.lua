-- Copyright (c) 2024 RAMPAGE Interactive. All rights reserved.
-- Re-write of Badger_Discord_API to be better organized & additional features.

local Token = "Bot " .. Config.DiscordBot.Token
local DataCache = {
	Avatars = {},
	RoleList = {},
	UserRoles = {},
}

local RN = "[" .. GetCurrentResourceName() .. "] "

if not Config.DiscordBot.Token then
	print(
		RN
			.. "IMPORTANT: Resource MUST have a Discord Bot Token in config, create a bot at https://discord.com/developers/."
	)
	return StopResource(GetCurrentResourceName())
end

-- Internal Function
-- Returns boolean of success or not
function CreateNotification(PlayerId, Style, Event, Message)
	if
		Config.Notifications.EventsEnabled[Event] == nil
		or Config.Notifications.EventsEnabled[Event] ~= nil and not Config.Notifications.EventsEnabled[Event]
	then
		return false
	end

	TriggerClientEvent(Config.Notifications.ResourceName .. ":" .. Config.Notifications.ResourceExport, PlayerId, {
		[Config.Notifications.Format.customstyle] = {},
		[Config.Notifications.Format.style] = Config.Notifications.Format.styles[Style]
			or Config.Notifications.Format.styles["default"],
		[Config.Notifications.Format.title] = Config.Notifications.Format.title == false and false or "",
		[Config.Notifications.Format.message] = Message,
	})

	return true
end

-- Internal Function
function has_value(tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end

	return false
end

-- Internal Function
function csv_table(table)
	local newstring = ""

	for i, v in pairs(table) do
		if i > 1 then
			newstring = newstring .. ", "
		end
		newstring = newstring .. tostring(v)
	end

	return newstring
end

-- Internal Function
-- returns Guild Id, Defaults to default guild id if non-found.
function GetGuildId(GuildName)
	if type(GuildName) == "number" then
		return GuildName
	end

	local result = Config.GuildId

	if GuildName and Config.Guilds[GuildName] then
		result = tostring(Config.Guilds[GuildName])
	end

	return result
end

function GetIdentifier(source, id_type)
	if type(id_type) ~= "string" then
		return
	end

	local ids = GetPlayerIdentifiers(source)

	if GetConvarInt("sv_fxdkMode", 0) == 1 then
		print("fxDK MODE DETECTED. PASSING FAKE IDENTIFERS. MODIFY WITH YOUR OWN IN LINE 91.")
		table.insert(ids, "steam:76561198054464303")
		table.insert(ids, "discord:295744013406044162")
		table.insert(ids, "live:test")
		table.insert(ids, "xbl:test")
		table.insert(ids, "license:test")
	end

	for _, identifier in pairs(ids) do
		if string.find(identifier, id_type) then
			return identifier
		end
	end

	return nil
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetDiscordId()
-- returns boolean success, discord license
function GetDiscordId(PlayerId)
	local id = GetIdentifier(PlayerId, "discord")
	return id ~= nil, string.sub(id, 9, -1)
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:PurgeCache()
-- returns boolean success
function PurgeCache()
	DataCache = {
		Avatars = {},
		RoleList = {},
		UserRoles = {},
	}

	return true
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:DiscordRequest(method, endpoint, jsondata)
-- example: print(exports["RAMPAGE_Discord_API"]:DiscordRequest("GET", "guilds/1", {}))
function DiscordRequest(method, endpoint, jsondata)
	local data = nil

	PerformHttpRequest(
		"https://discordapp.com/api/" .. endpoint,
		function(errorCode, resultData, resultHeaders)
			data = {
				data = resultData,
				code = errorCode,
				headers = resultHeaders,
			}
		end,
		method,
		#jsondata > 0 and jsondata or "",
		{
			["Content-Type"] = "application/json",
			["Authorization"] = Token,
		}
	)

	while data == nil do
		Citizen.Wait(0)
	end

	return data
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetGuildRoleList(guildAlias: string | number (optional))
-- returns success boolean & roles array.
function GetGuildRoleList(guildAlias)
	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API - GetGuildRoleList: guildAlias must be a string or number.")
		return false, ""
	end

	local guildId = GetGuildId(GuildId)

	if Config.UseCache and DataCache.RoleList[guildId] ~= nil then
		return true, DataCache.RoleList[guildId]
	end

	local guild = DiscordRequest("GET", "guilds/" .. guildId, {})

	if guild.code ~= 200 then
		if Config.UseCache then
			DataCache.RoleList[guildId] = nil
		end

		return false, {}
	end

	local data = json.decode(guild.data)
	local roles = data.roles
	local roleList = {}

	for i = 1, #roles do
		roleList[roles[i].name] = roles[i].id
	end

	if Config.UseCache then
		DataCache.RoleList[guildId] = roleList
	end

	return true, roleList
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetDiscordRoles(PlayerId: number, guildAlias: string | number (optional))
-- example: print(exports["RAMPAGE_Discord_API"]:GetDiscordRoles(1, 123))
-- returns success boolean & roles array.
function GetDiscordRoles(PlayerId, guildAlias)
	if PlayerId == nil or PlayerId ~= nil and type(PlayerId) ~= "number" then
		print("RAMPAGE_Discord_API - GetDiscordRoles: PlayerId must be a number and not nil.")
		return false, ""
	end

	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API - GetDiscordRoles: guildAlias must be a string or number.")
		return false, ""
	end

	local ids, discordId = GetDiscordId(PlayerId)
	local guildId = GetGuildId(guildAlias)

	if not ids then
		return false, {}
	end

	if Config.UseCache and DataCache.UserRoles[discordId] ~= nil and DataCache.UserRoles[discordId][guildId] ~= nil then
		return true, DataCache.UserRoles[discordId][guildId]
	end

	local endpoint = ("guilds/%s/members/%s"):format(guildId, discordId)
	local member = DiscordRequest("GET", endpoint, {})

	if member.code ~= 200 then
		return false, {}
	end

	local data = json.decode(member.data)
	local roles = data.roles

	if Config.UseCache then
		DataCache.UserRoles[discordId] = DataCache.UserRoles[discordId] or {}
		DataCache.UserRoles[discordId][guildId] = roles

		Citizen.SetTimeout(((Config.UpdateRate or 30) * 1000), function()
			DataCache.UserRoles[discordId][guildId] = nil
		end)
	end

	return true, roles
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:HasDiscordRole(PlayerId: number, RoleId: number, guildAlias: string | number (optional))
-- returns boolean
function HasDiscordRole(PlayerId, RoleId, guildAlias)
	if PlayerId == nil or PlayerId ~= nil and type(PlayerId) ~= "number" then
		print("RAMPAGE_Discord_API - HasDiscordRole: PlayerId must be a number and not nil.")
		return false, ""
	end

	if RoleId == nil or RoleId ~= nil and type(RoleId) ~= "number" then
		print("RAMPAGE_Discord_API - HasDiscordRole: RoleId must be a number and not nil.")
		return false, ""
	end

	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API: guildAlias must be a string or number.")
		return false, ""
	end

	local suc, roles = GetDiscordRoles(PlayerId, guildAlias)
	local roleFound = false

	if suc then
		for i, v in pairs(roles) do
			if tonumber(v) == tonumber(RoleId) then
				roleFound = true
				break
			end
		end
	end

	return roleFound
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetDiscordUsername(PlayerId: number, SendAsTable: boolean (optional))
-- returns success boolean & string
function GetDiscordUsername(PlayerId, SendAsTable)
	if PlayerId == nil or PlayerId ~= nil and type(PlayerId) ~= "number" then
		print("RAMPAGE_Discord_API - GetDiscordUsername: PlayerId must be a number and not nil.")
		return false, ""
	end

	if SendAsTable == nil then
		SendAsTable = false
	end

	local ids, discordId = GetDiscordId(PlayerId)
	local nameData = nil

	if not ids then
		return false, "Discord"
	end

	local endpoint = ("users/%s"):format(discordId)
	local member = DiscordRequest("GET", endpoint, {})

	if member.code ~= 200 then
		return false, "Discord"
	end

	local data = json.decode(member.data)

	if data == nil then
		return false, "Discord"
	end

	if SendAsTable then
		return true, {
			["username"] = data.username,
			["discriminator"] = data.discriminator,
		}
	else
		return true, data.username .. "#" .. data.discriminator
	end
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetGuildIcon(guildAlias: string | number (optional))
-- returns success boolean & string
function GetGuildIcon(guildAlias)
	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API - GetGuildIcon: guildAlias must be a string or number.")
		return false, ""
	end

	local guildId = GetGuildId(guildAlias)
	guild = DiscordRequest("GET", "guilds/" .. guildId, {})

	if guild.code ~= 200 then
		return false, ""
	end

	local data = json.decode(guild.data)

	if data.icon:sub(1, 1) and data.icon:sub(2, 2) == "_" then
		return true, "https://cdn.discordapp.com/icons/" .. Config.GuildId .. "/" .. data.icon .. ".gif"
	else
		return true, "https://cdn.discordapp.com/icons/" .. Config.GuildId .. "/" .. data.icon .. ".png"
	end
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetGuildSplash(guildAlias: string | number (optional))
-- returns success boolean & string
function GetGuildSplash(guildAlias)
	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API - GetGuildSplash: guildAlias must be a string or number.")
		return false, ""
	end

	local guildId = GetGuildId(guildAlias)
	guild = DiscordRequest("GET", "guilds/" .. guildId, {})

	if guild.code ~= 200 then
		return false, ""
	end

	local data = json.decode(guild.data)
	return true, "https://cdn.discordapp.com/splashes/" .. Config.GuildId .. "/" .. data.icon .. ".png"
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetGuildName(guildAlias: string | number (optional))
-- returns success boolean & string
function GetGuildName(guildAlias)
	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API: guildAlias must be a string or number.")
		return false, ""
	end

	local guildId = GetGuildId(guildAlias)
	guild = DiscordRequest("GET", "guilds/" .. guildId, {})

	if guild.code ~= 200 then
		return false, "Discord"
	end

	local data = json.decode(guild.data)
	return true, data.name
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetGuildDescription(guildAlias: string | number (optional))
-- returns success boolean & string
function GetGuildDescription(guildAlias)
	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API - GetGuildDescription: guildAlias must be a string or number.")
		return false, ""
	end

	local guildId = GetGuildId(guildAlias)
	guild = DiscordRequest("GET", "guilds/" .. guildId, {})

	if guild.code ~= 200 then
		return false, "Discord is a cool app."
	end

	local data = json.decode(guild.data)
	return true, data.description
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetGuildMemberCount(guildAlias: string | number (optional))
-- returns success boolean & count
function GetGuildMemberCount(guildAlias)
	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API - GetGuildMemberCount: guildAlias must be a string or number.")
		return false, 0
	end

	local guildId = GetGuildId(guildAlias)
	guild = DiscordRequest("GET", "guilds/" .. guildId .. "?with_counts=true", {})

	if guild.code ~= 200 then
		return false, 0
	end

	local data = json.decode(guild.data)
	return true, (data.approximate_member_count or 0)
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetGuildOnlineMemberCount(guildAlias: string | number (optional))
-- returns success boolean & count
function GetGuildOnlineMemberCount(guildAlias)
	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API - GetGuildOnlineMemberCount: guildAlias must be a string or number.")
		return false, 0
	end

	local guildId = GetGuildId(guildAlias)
	guild = DiscordRequest("GET", "guilds/" .. guildId .. "?with_counts=true", {})

	if guild.code ~= 200 then
		return false, 0
	end

	local data = json.decode(guild.data)
	return true, (data.approximate_presence_count or 0)
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetDiscordAvatar(PlayerId: number)
-- returns success boolean & image url
function GetDiscordAvatar(PlayerId)
	if PlayerId == nil or PlayerId ~= nil and type(PlayerId) ~= "number" then
		print("RAMPAGE_Discord_API - GetDiscordAvatar: PlayerId must be a number and not nil.")
		return false, ""
	end

	local ids, discordId = GetDiscordId(PlayerId)

	if not ids then
		return false, ""
	end

	if Config.UseCache and DataCache.Avatars[discordId] ~= nil then
		return true, DataCache.Avatars[discordId]
	end

	local endpoint = ("users/%s"):format(discordId)
	local member = DiscordRequest("GET", endpoint, {})

	if member.code ~= 200 then
		return false, ""
	end

	local data = json.decode(member.data)

	if data ~= nil and data.avatar ~= nil then
		local imgURL = ""

		if data.avatar:sub(1, 1) and data.avatar:sub(2, 2) == "_" then
			imgURL = "https://cdn.discordapp.com/avatars/" .. discordId .. "/" .. data.avatar .. ".gif"
		else
			imgURL = "https://cdn.discordapp.com/avatars/" .. discordId .. "/" .. data.avatar .. ".png"
		end

		if imgURL == "" then
			return false, ""
		end

		if Config.UseCache and DataCache.Avatars[discordId] == nil then
			DataCache.Avatars[discordId] = imgURL
		end

		return true, imgURL
	end
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetRoleNameFromRoleId(roleId: number | string, guildAlias: string | number (optional))
-- returns boolean & role name
function GetRoleNameFromRoleId(roleId, guildAlias)
	if roleId == nil or roleId ~= nil and (type(roleId) ~= "number" and type(roleId) ~= "string") then
		print("RAMPAGE_Discord_API - GetRoleNameFromRoleId: roleId must be a number or string and not nil.")
		return false, ""
	end

	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API - GetRoleNameFromRoleId: guildAlias must be a string or number.")
		return false, ""
	end

	local guildId = GetGuildId(guildAlias)
	local s, roles = false, {}

	if Config.UseCache and DataCache.RoleList[guildId] ~= nil then
		roles = DataCache.RoleList[guildId]
	else
		s, roles = GetGuildRoleList(guild)

		if not s then
			return false, ""
		end
	end

	for name, id in pairs(roles) do
		if id == roleId then
			return true, name
		end
	end

	return false, ""
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:GetRoleIdFromRoleName(roleName: string, guildAlias: string | number (optional))
-- returns boolean & roleid
function GetRoleIdFromRoleName(roleName, guildAlias)
	if roleName == nil then
		print("RAMPAGE_Discord_API - GetRoleIdFromRoleName: roleName must be a string and not nil.")
		return false, 1
	end

	if type(roleName) ~= "string" then
		print("RAMPAGE_Discord_API - GetRoleIdFromRoleName: roleName must be a string.")
		print("(roleName) Got type: " .. type(roleName))
		print("(roleName) Got value: " .. roleName)
		return false, 1
	end

	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API - GetRoleIdFromRoleName: guildAlias must be a string or number.")
		print("(guildAlias) Got type: " .. type(guildAlias))
		print("(guildAlias) Got value: " .. guildAlias)
		return false, 1
	end

	local guildId = GetGuildId(guildAlias)

	if Config.UseCache and DataCache.RoleList[guildId] ~= nil then
		return true, DataCache.RoleList[guildId][roleName]
	end

	if type(roleName) == "number" then
		return true, tonumber(roleName)
	end

	local s, roles = GetGuildRoleList(guild)

	if not s then
		return false, 1
	end

	return true, tonumber(roles[roleName])
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:FetchRoleId(roleId: number, guildAlias: string | number (optional))
-- returns boolean & roleid
function FetchRoleId(RoleId, guildAlias)
	print(
		"RAMPAGE_Discord_API - FetchRoleId: FetchRoleId has been deprecated in RAMPAGE Discord API v3, please use GetRoleIdFromRoleName."
	)
	
	return GetRoleIdFromRoleName(RoleId, guildAlias)
end

-- Public Function
-- @exports["RAMPAGE_Discord_API"]:CheckEqual(role1: number, role2: number, guildAlias: string | number (optional))
-- returns boolean
function CheckEqual(role1, role2, guildAlias)
	if role1 == nil or role1 ~= nil and type(role1) ~= "number" then
		print("RAMPAGE_Discord_API - CheckEqual: role1 must be a number and not nil.")
		return false
	end

	if role2 == nil or role2 ~= nil and type(role2) ~= "number" then
		print("RAMPAGE_Discord_API - CheckEqual: role2 must be a number and not nil.")
		return false
	end

	if guildAlias ~= nil and type(guildAlias) ~= "string" and type(guildAlias) ~= "number" then
		print("RAMPAGE_Discord_API - CheckEqual: guildAlias must be a string or number.")
		return false
	end

	local s, roleID1 = GetRoleIdFromRoleName(role1, guildAlias)
	local s2, roleID2 = GetRoleIdFromRoleName(role2, guildAlias)

	if not s or not s2 then
		return false
	end

	if roleID1 == roleID2 and type(roleID1) ~= "nil" then
		return true
	end

	return false
end

-- Thread
Citizen.CreateThread(function()
	if GetCurrentResourceName() ~= "RAMPAGE_Discord_API" then
		print(
			RN .. "IMPORTANT: Resource MUST be named RAMPAGE_Discord_API otherwise some scripts may NOT work properly."
		)
	end

	local Guild = DiscordRequest("GET", "guilds/" .. Config.GuildId, {})

	if Guild.code == 200 then
		local data = json.decode(Guild.data)
		print("[RAMPAGE_Discord_API] Successful connection to discord guild '" .. data.name .. "'")
	else
		print(
			"[RAMPAGE_Discord_API] An error occured while attempting to connect to guild. Error Data: "
				.. (Guild.data and json.decode(Guild.data) or Guild.code)
		)
	end
end)

RegisterNetEvent("RAMPAGE_Discord_API:LoadPlayer")
AddEventHandler("RAMPAGE_Discord_API:LoadPlayer", function()
	local src = source

	if GetCurrentResourceName() ~= "RAMPAGE_Discord_API" then
		print(
			RN .. "IMPORTANT: Resource MUST be named RAMPAGE_Discord_API otherwise some scripts may NOT work properly."
		)
	end

	TriggerClientEvent("chatMessage", src, "^2Your permissions have loaded with RAMPAGE Discord API.")

	if not Config.UseCache then
		return
	end

	Citizen.CreateThread(function()
		local recheckTime = (Config.Notifications.NotificationRate or 30) * 1000

		while true do
			--print("My FiveM id is: " .. src)

			local success, discordId = GetDiscordId(src)

			if not success then
				--	print("Failed to find discord!")
				return
			end

			--print("My Discord ID is: " .. discordId)
			local success2, roles = GetDiscordRoles(src)

			if success and success2 then
				local added = {}
				local removed = {}

				for _, roleId in pairs(roles) do
					if roleId ~= nil and  not has_value(DataCache.UserRoles[discordId], roleId) then
						local suc, name = GetRoleNameFromRoleId(roleId)
						table.insert(added, suc and name or roleId)
					end
				end

				for _, roleId in pairs(DataCache.UserRoles[discordId]) do
					if roleId ~= nil and not has_value(roles, roleId) then
						local suc, name = GetRoleNameFromRoleId(roleId)
						table.insert(removed, suc and name or roleId)
					end
				end

				if Config.Notifications.EventsEnabled.RoleAdded then
					added = csv_table(added)
				else
					added = false
				end

				if Config.Notifications.EventsEnabled.RoleRemoved then
					removed = csv_table(removed)
				else
					removed = false
				end

				if added and added ~= {} then
					CreateNotification(src, "green", "RoleAdded", added .. " role(s) have been added to your discord.")
				end

				if removed and removed ~= {} then
					CreateNotification(
						src,
						"red",
						"RoelRemoved",
						added .. " role(s) have been removed from your discord."
					)
				end
			end

			Citizen.Wait(recheckTime)
		end
	end)
end)
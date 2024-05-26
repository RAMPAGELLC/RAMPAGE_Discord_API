Config = {
	UseCache = false, -- Use role cache system
	UpdateRate = 60, -- Rate of re-fetching roles after cache. (in seconds)
	GuildId = 11111111111111, -- Primary Guild Id (Defaults to this if no guild is specified for some exports)
	Guilds = {
		["guildAlias"] = "guild_id", -- Replace this with a name, like "main"
	},
	Notifications = {
		NotificationRate = 60, -- Rate of comparing cache & current roles for notification events.
		ResourceName = "t-notify:client",
		ResourceExport = "Custom",
		--[[
        t-notify Format:
        GitHub: https://github.com/tasooneasia/t-notify
        ResourceName = "t-notify:client",
        ResourceExport = "Custom",
        Format = {
            customstyle = "style",
            style = "style", --  Name of events styling. (required)
            message = "message", -- Name of events message (required)
            title = false, -- Name of events title (required)
            styles = {
                -- Name of events coloring for style field.
                ["green"] = 'success',
                ["red"] = 'error',
                ["orange"] = 'warning',
                ["default"] = 'message'
            }
        },

        mythic_notify Format:
        GitHub: https://github.com/JayMontana36/mythic_notify
        ResourceName = "mythic_notify:client",
        ResourceExport = "SendAlert",
        Format = {
            customstyle = "style",
            style = "type", --  Name of events styling. (required)
            message = "text", -- Name of events message (required)
            title = false, -- Name of events title (required)
            styles = {
                -- Name of events coloring for style field.
                ["green"] = 'success',
                ["red"] = 'error',
                ["orange"] = 'inform',
                ["default"] = 'inform'
            }
        },
        
        ]]
		Format = {
			-- Please enter the fields for the server exports of notification
			-- system you plan to use, the config below is for t-notify, some notification system formats are provided above.
			customstyle = "style",
			style = "style", --  Name of events styling. (required)
			message = "message", -- Name of events message (required)
			title = false, -- Name of events title (required)
			styles = {
				-- Name of events coloring for style field.
				["green"] = "success",
				["red"] = "error",
				["orange"] = "warning",
				["default"] = "message",
			},
		},
		EventsEnabled = {
			RoleAdded = true,
			RoleRemoved = true,
		},
	},
	DiscordBot = { 
		Token = false, -- Token is required in-order for the bot to properly function.
	},
}

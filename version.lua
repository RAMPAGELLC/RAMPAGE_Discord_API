Citizen.CreateThread(function()
	local updatePath = "/RAMPAGELLC/RAMPAGE_Discord_API" -- your git user/repo path
	local resourceName = "RAMPAGE_Discord_API (" .. GetCurrentResourceName() .. ")" -- the resource name

	function checkVersion(err, responseText, headers)
		local curVersion = LoadResourceFile(GetCurrentResourceName(), "version.txt")

		if curVersion ~= responseText and tonumber(curVersion) < tonumber(responseText) then
			print("\n###############################")
			print(
				"\n"
					.. resourceName
					.. " is outdated, should be: "
					.. responseText
					.. "\nis: "
					.. curVersion
					.. "\nplease update it from https://github.com"
					.. updatePath
					.. ""
			)
			print("\n###############################")
		elseif tonumber(curVersion) > tonumber(responseText) then
			print(
				"You somehow skipped a few versions of "
					.. resourceName
					.. " or the git went offline, if it's still online I advise you to update..."
			)
		else
			print("\n" .. resourceName .. " is up to date!")
		end
	end

	PerformHttpRequest(
		"https://raw.githubusercontent.com/RAMPAGELLC/RAMPAGE_Discord_API/main/version.txt",
		checkVersion,
		"GET"
	)
end)

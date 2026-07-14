return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`ping_duration_changer` requires the Darktide Mod Framework.")

		new_mod("ping_duration_changer", {
			mod_script       = "ping_duration_changer/scripts/mods/ping_duration_changer/ping_duration_changer",
			mod_data         = "ping_duration_changer/scripts/mods/ping_duration_changer/ping_duration_changer_data",
			mod_localization = "ping_duration_changer/scripts/mods/ping_duration_changer/ping_duration_changer_localization",
		})
	end,
	packages = {},
}


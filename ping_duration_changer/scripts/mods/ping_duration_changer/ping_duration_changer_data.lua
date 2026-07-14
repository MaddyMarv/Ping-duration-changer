local mod = get_mod("ping_duration_changer")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "section_scope",
				type = "group",
				title = "section_scope",
				localize = true,
				sub_widgets = {
					{
						setting_id = "use_on_your_pings",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "use_on_teammates_pings",
						type = "checkbox",
						default_value = true,
					},
				},
			},
			{
				setting_id = "section_duration",
				type = "group",
				title = "section_duration",
				localize = true,
				sub_widgets = {
					{
						setting_id = "duration_enemies",
						type = "numeric",
						default_value = 10.0,
						range = { 0.1, 60.0 },
						decimals_number = 1,
					},
					{
						setting_id = "duration_companion_targets",
						type = "numeric",
						default_value = 25.0,
						range = { 0.1, 60.0 },
						decimals_number = 1,
					},
					{
						setting_id = "duration_materials_items",
						type = "numeric",
						default_value = 10.0,
						range = { 0.1, 60.0 },
						decimals_number = 1,
					},
					{
						setting_id = "duration_health_stations",
						type = "numeric",
						default_value = 10.0,
						range = { 0.1, 60.0 },
						decimals_number = 1,
					},
					{
						setting_id = "duration_location_pings",
						type = "numeric",
						default_value = 60.0,
						range = { 0.1, 60.0 },
						decimals_number = 1,
					},
					{
						setting_id = "duration_threat_warnings",
						type = "numeric",
						default_value = 30.0,
						range = { 0.1, 60.0 },
						decimals_number = 1,
					},
					{
						setting_id = "duration_attention_warnings",
						type = "numeric",
						default_value = 30.0,
						range = { 0.1, 60.0 },
						decimals_number = 1,
					},
				},
			},
			{
				setting_id = "section_visibility",
				type = "group",
				title = "section_visibility",
				localize = true,
				sub_widgets = {
					{
						setting_id = "disable_enemies",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "disable_companion_targets",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "disable_materials_items",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "disable_health_stations",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "disable_location_pings",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "disable_threat_warnings",
						type = "checkbox",
						default_value = false,
					},
					{
						setting_id = "disable_attention_warnings",
						type = "checkbox",
						default_value = false,
					},
				},
			},
		},
	},
}


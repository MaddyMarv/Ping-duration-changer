local mod = get_mod("ping_duration_changer")

local SmartTag = require("scripts/extension_systems/smart_tag/smart_tag")
local REMOVE_TAG_REASONS = SmartTag.REMOVE_TAG_REASONS

local function is_group_disabled(tag_group)
	if tag_group == "enemy" then
		return mod:get("disable_enemies") == true
	elseif tag_group == "double_tag_enemy" then
		return mod:get("disable_companion_targets") == true
	elseif tag_group == "object" then
		return mod:get("disable_materials_items") == true
	elseif tag_group == "health_station" then
		return mod:get("disable_health_stations") == true
	elseif tag_group == "location_ping" then
		return mod:get("disable_location_pings") == true
	elseif tag_group == "location_threat" then
		return mod:get("disable_threat_warnings") == true
	elseif tag_group == "location_attention" then
		return mod:get("disable_attention_warnings") == true
	end
	return false
end

local function get_group_duration(tag_group)
	if tag_group == "enemy" then
		return mod:get("duration_enemies") or 10.0
	elseif tag_group == "double_tag_enemy" then
		return mod:get("duration_companion_targets") or 25.0
	elseif tag_group == "object" then
		return mod:get("duration_materials_items") or 10.0
	elseif tag_group == "health_station" then
		return mod:get("duration_health_stations") or 10.0
	elseif tag_group == "location_ping" then
		return mod:get("duration_location_pings") or 60.0
	elseif tag_group == "location_threat" then
		return mod:get("duration_threat_warnings") or 30.0
	elseif tag_group == "location_attention" then
		return mod:get("duration_attention_warnings") or 30.0
	end
	return 10.0
end

local function should_apply_settings(tagger_player)
	if not tagger_player then
		return true
	end

	local local_player = Managers.player and Managers.player:local_player(1)
	local success, is_local = pcall(function()
		return local_player and tagger_player.unique_id and tagger_player:unique_id() == local_player:unique_id()
	end)

	if success and is_local then
		return mod:get("use_on_your_pings") ~= false
	else
		return mod:get("use_on_teammates_pings") ~= false
	end
end

mod:hook("EventManager", "trigger", function(func, self, event_name, ...)
	if event_name == "event_smart_tag_created" then
		local tag_instance = select(1, ...)

		if tag_instance then
			local success, tagger_player = pcall(function() return tag_instance:tagger_player() end)
			local success2, tag_group = pcall(function() return tag_instance:group() end)

			if success and success2 and tag_group and should_apply_settings(tagger_player) then
				if is_group_disabled(tag_group) then
					return
				end
			end
		end
	end

	func(self, event_name, ...)
end)

mod:hook("SmartTagSystem", "_create_tag_locally", function(func, self, tag_id, template_name, tagger_unit, target_unit, target_location, replies, is_hotjoin_synced)
	local tag = func(self, tag_id, template_name, tagger_unit, target_unit, target_location, replies, is_hotjoin_synced)

	if tag then
		local success1, tagger_player = pcall(function() return tag:tagger_player() end)
		local success2, tag_group = pcall(function() return tag:group() end)

		if success1 and success2 and tag_group and should_apply_settings(tagger_player) then
			local success3 = pcall(function()
				if is_group_disabled(tag_group) then
					tag:set_expire_time(-999999)
				else
					local time_manager = Managers.time
					if time_manager then
						local t = time_manager:time("gameplay")
						tag:set_expire_time(t + get_group_duration(tag_group))
					end
				end
			end)
		end
	end

	return tag
end)

mod:hook("SmartTagSystem", "set_tag", function(func, self, template_name, tagger_unit, target_unit, target_location)
	if self._is_server then
		local SmartTagSettings = require("scripts/settings/smart_tag/smart_tag_settings")
		if SmartTagSettings and SmartTagSettings.templates then
			local template = SmartTagSettings.templates[template_name]

			if template and template.group and type(template.group) == "string" then
				local player_unit_spawn = Managers.state and Managers.state.player_unit_spawn
				local tagger_player = tagger_unit and player_unit_spawn and player_unit_spawn:owner(tagger_unit) or nil

				if should_apply_settings(tagger_player) and is_group_disabled(template.group) then
					return
				end
			end
		end
	end

	return func(self, template_name, tagger_unit, target_unit, target_location)
end)

mod:hook("HudElementSmartTagging", "event_smart_tag_created", function(func, self, tag_instance, is_hotjoin_synced)
	if tag_instance then
		local success1, tagger_player = pcall(function() return tag_instance:tagger_player() end)
		local success2, tag_group = pcall(function() return tag_instance:group() end)

		if success1 and success2 and tag_group and should_apply_settings(tagger_player) then
			if is_group_disabled(tag_group) then
				return
			end
		end
	end

	func(self, tag_instance, is_hotjoin_synced)
end)

mod:hook("HudElementSmartTagging", "_add_smart_tag_presentation", function(func, self, tag_instance, is_hotjoin_synced)
	if tag_instance then
		local success1, tagger_player = pcall(function() return tag_instance:tagger_player() end)
		local success2, tag_group = pcall(function() return tag_instance:group() end)

		if success1 and success2 and tag_group and should_apply_settings(tagger_player) then
			if is_group_disabled(tag_group) then
				return
			end
		end
	end

	func(self, tag_instance, is_hotjoin_synced)
end)

mod:hook("HudElementSmartTagging", "_play_tag_sound", function(func, self, tag_instance, event_name)
	if tag_instance then
		local success1, tagger_player = pcall(function() return tag_instance:tagger_player() end)
		local success2, tag_group = pcall(function() return tag_instance:group() end)

		if success1 and success2 and tag_group and should_apply_settings(tagger_player) then
			if is_group_disabled(tag_group) then
				return
			end
		end
	end

	func(self, tag_instance, event_name)
end)

mod:hook("SmartTag", "is_valid", function(func, self, t)
	local success1, tagger_player = pcall(function() return self:tagger_player() end)
	local success2, tag_group = pcall(function() return self:group() end)
	local success3, expire_time = pcall(function() return self:expire_time() end)

	if success1 and success2 and success3 and tag_group and should_apply_settings(tagger_player) then
		if not is_group_disabled(tag_group) then
			if expire_time then
				if t >= expire_time then
					return false, REMOVE_TAG_REASONS.expired
				else
					local is_valid, remove_reason = func(self, t)

					if not is_valid and remove_reason == REMOVE_TAG_REASONS.expired then
						return true
					end

					return is_valid, remove_reason
				end
			end
		end
	end

	return func(self, t)
end)

mod:hook("SmartTagSystem", "update", function(func, self, context, dt, t, ...)
	func(self, context, dt, t, ...)

	if not self._all_tags then
		return
	end

	local tags_to_remove = {}

	for tag_id, tag in pairs(self._all_tags) do
		if tag then
			local success1, tagger_player = pcall(function() return tag:tagger_player() end)
			local success2, tag_group = pcall(function() return tag:group() end)
			local success3, expire_time = pcall(function() return tag:expire_time() end)

			if success1 and success2 and success3 and tag_group and should_apply_settings(tagger_player) then
				local target_valid = true
				local success4, target_unit = pcall(function() return tag:target_unit() end)
				if success4 and target_unit then
					local success5, target_extension = pcall(function()
						return ScriptUnit.has_extension(target_unit, "smart_tag_system")
					end)
					if not success5 or not target_extension then
						target_valid = false
					end
				end

				if is_group_disabled(tag_group) then
					table.insert(tags_to_remove, {tag_id = tag_id, reason = REMOVE_TAG_REASONS.external_removal})
				elseif not target_valid then
					table.insert(tags_to_remove, {tag_id = tag_id, reason = REMOVE_TAG_REASONS.tagged_unit_died})
				elseif expire_time and t >= expire_time then
					table.insert(tags_to_remove, {tag_id = tag_id, reason = REMOVE_TAG_REASONS.expired})
				end
			end
		end
	end

	for _, removal_data in ipairs(tags_to_remove) do
		if self._remove_tag_locally then
			pcall(function() self:_remove_tag_locally(removal_data.tag_id, removal_data.reason) end)
		end

		if self._is_server then
			local game_session = Managers.state and Managers.state.game_session
			if game_session and game_session.send_rpc_clients then
				local REMOVE_TAG_REASONS_LOOKUP = table.mirror_array_inplace(table.keys(REMOVE_TAG_REASONS))
				local reason_id = REMOVE_TAG_REASONS_LOOKUP[removal_data.reason]

				if reason_id then
					pcall(function() game_session:send_rpc_clients("rpc_remove_smart_tag", removal_data.tag_id, reason_id) end)
				end
			end
		end
	end
end)

mod:hook("SmartTagSystem", "_remove_tag_locally", function(func, self, tag_id, reason)
	if not self._is_server and self._all_tags then
		local tag = self._all_tags[tag_id]

		if tag then
			local success1, tagger_player = pcall(function() return tag:tagger_player() end)
			local success2, tag_group = pcall(function() return tag:group() end)
			local success3, expire_time = pcall(function() return tag:expire_time() end)
			local success4, target_unit = pcall(function() return tag:target_unit() end)

			local target_valid = true
			if success4 and target_unit then
				local success5, target_extension = pcall(function()
					return ScriptUnit.has_extension(target_unit, "smart_tag_system")
				end)
				if not success5 or not target_extension then
					target_valid = false
				end
			end

			if success1 and success2 and success3 and success4 and target_valid and tag_group and should_apply_settings(tagger_player) then
				if not is_group_disabled(tag_group) then
					if expire_time and reason == REMOVE_TAG_REASONS.expired then
						local time_manager = Managers.time
						if time_manager then
							local t = time_manager:time("gameplay")

							if t < expire_time then
								return
							end
						end
					end
				end
			end
		end
	end

	if self._all_tags then
		local tag = self._all_tags[tag_id]
		if tag then
			local tagger_unit = tag:tagger_unit()
			if tagger_unit and not self._unit_extension_data[tagger_unit] then
				tag:clear_tagger()
			end

			local replies = tag:replies()
			if replies then
				for replier_unit, _ in pairs(replies) do
					if not self._unit_extension_data[replier_unit] then
						tag:remove_reply(replier_unit)
					end
				end
			end

			local target_unit = tag:target_unit()
			if target_unit and ALIVE[target_unit] and not self._unit_extension_data[target_unit] then
				tag._target_unit = nil
			end
		end
	end

	func(self, tag_id, reason)
end)

mod:hook("SmartTag", "display_name", function(func, self)
	local target_unit = self._target_unit
	if target_unit then
		local success, smart_tag_extension = pcall(function()
			return ScriptUnit.has_extension(target_unit, "smart_tag_system")
		end)

		if not success or not smart_tag_extension then
			return self._template and self._template.display_name or "n/a"
		end
	end

	return func(self)
end)

local mod = get_mod("ping_duration_changer")

local SmartTag = require("scripts/extension_systems/smart_tag/smart_tag")
local SmartTagSettings = require("scripts/settings/smart_tag/smart_tag_settings")
local REASONS = SmartTag.REMOVE_TAG_REASONS

local GROUP_SETTINGS = {
	enemy = { disable = "disable_enemies", duration = "duration_enemies", default = 10 },
	double_tag = { disable = "disable_companion_targets", duration = "duration_companion_targets", default = 25 },
	double_tag_enemy = { disable = "disable_companion_targets", duration = "duration_companion_targets", default = 25 },
	object = { disable = "disable_materials_items", duration = "duration_materials_items", default = 10 },
	hacking = { disable = "disable_materials_items", duration = "duration_materials_items", default = 10 },
	health_station = { disable = "disable_health_stations", duration = "duration_health_stations", default = 10 },
	location_ping = { disable = "disable_location_pings", duration = "duration_location_pings", default = 60 },
	location_threat = { disable = "disable_threat_warnings", duration = "duration_threat_warnings", default = 30 },
	location_attention = { disable = "disable_attention_warnings", duration = "duration_attention_warnings", default = 30 },
}

local function is_disabled(group)
	local cfg = GROUP_SETTINGS[group]
	return cfg and mod:get(cfg.disable) == true
end

local function get_duration(group)
	local cfg = GROUP_SETTINGS[group]
	return cfg and (mod:get(cfg.duration) or cfg.default) or 10
end

local function should_apply(player)
	if not player or not Managers.player then
		return true
	end
	local local_player = Managers.player:local_player(1)
	if not local_player then
		return true
	end
	if player:unique_id() == local_player:unique_id() then
		return mod:get("use_on_your_pings") ~= false
	end
	return mod:get("use_on_teammates_pings") ~= false
end

local function tag_player(tag)
	if not tag or not tag.tagger_player then
		return nil
	end
	local player = tag:tagger_player()
	if not player and tag.tagger_unit then
		local unit = tag:tagger_unit()
		local spawner = Managers.state and Managers.state.player_unit_spawn
		player = unit and spawner and spawner:owner(unit)
	end
	return player
end

local function should_disable(tag)
	if not tag or not tag.group then
		return false
	end
	return is_disabled(tag:group()) and should_apply(tag_player(tag))
end

local function is_tag_valid(tag, t)
	local expire = tag:expire_time()
	if expire and t >= expire then
		return false, REASONS.expired
	end
	local unit = tag:target_unit()
	if unit then
		if ALIVE and not ALIVE[unit] then
			return false, REASONS.tagged_unit_died
		end
		local spawner = Managers.state and Managers.state.unit_spawner
		if spawner then
			local _, id = spawner:game_object_id_or_level_index(unit)
			if not id then
				return false, REASONS.tagged_unit_removed
			end
		end
		return SmartTag.validate_target_unit(unit)
	end
	return true
end

mod:hook("SmartTag", "display_name", function(func, self)
	local unit = self._target_unit
	if unit and ((ALIVE and not ALIVE[unit]) or not ScriptUnit.has_extension(unit, "smart_tag_system")) then
		return self._template and self._template.display_name or "n/a"
	end
	return func(self)
end)

mod:hook("SmartTagSystem", "set_tag", function(func, self, template_name, tagger_unit, ...)
	if self._is_server then
		local template = SmartTagSettings and SmartTagSettings.templates and SmartTagSettings.templates[template_name]
		if template and is_disabled(template.group) then
			local spawner = Managers.state and Managers.state.player_unit_spawn
			local player = tagger_unit and spawner and spawner:owner(tagger_unit)
			if should_apply(player) then
				return
			end
		end
	end
	return func(self, template_name, tagger_unit, ...)
end)

mod:hook("SmartTagSystem", "_create_tag_locally", function(func, self, tag_id, template_name, ...)
	local tag = func(self, tag_id, template_name, ...)
	if tag and should_apply(tag_player(tag)) then
		local group = tag:group()
		if is_disabled(group) then
			tag:set_expire_time(-math.huge)
		else
			local t = Managers.time and Managers.time:time("gameplay") or 0
			tag:set_expire_time(t + get_duration(group))
		end
	end
	return tag
end)

mod:hook("SmartTagSystem", "update", function(func, self, context, dt, t, ...)
	if not self._is_server and self._all_tags then
		local to_remove
		for id, tag in pairs(self._all_tags) do
			if should_apply(tag_player(tag)) then
				if is_disabled(tag:group()) then
					to_remove = to_remove or {}
					to_remove[#to_remove + 1] = { id = id, reason = REASONS.external_removal }
				else
					local valid, reason = is_tag_valid(tag, t)
					if not valid then
						to_remove = to_remove or {}
						to_remove[#to_remove + 1] = { id = id, reason = reason }
					end
				end
			end
		end
		if to_remove then
			for i = 1, #to_remove do
				self:_remove_tag_locally(to_remove[i].id, to_remove[i].reason)
			end
		end
	end
	func(self, context, dt, t, ...)
end)

mod:hook("SmartTagSystem", "_remove_tag_locally", function(func, self, id, reason)
	if not self._is_server and self._all_tags then
		local tag = self._all_tags[id]
		if tag and reason == REASONS.expired then
			local group = tag:group()
			if should_apply(tag_player(tag)) and not is_disabled(group) then
				local t = Managers.time and Managers.time:time("gameplay") or 0
				if is_tag_valid(tag, t) then
					return
				end
			end
		end
	end
	if self._all_tags then
		local tag = self._all_tags[id]
		if tag then
			local tagger = tag:tagger_unit()
			if tagger and not self._unit_extension_data[tagger] then
				tag:clear_tagger()
			end
			local replies = tag:replies()
			if replies then
				for replier, _ in pairs(replies) do
					if not self._unit_extension_data[replier] then
						tag:remove_reply(replier)
					end
				end
			end
			local target = tag:target_unit()
			if target and not self._unit_extension_data[target] then
				tag._target_unit = nil
			end
		end
	end
	func(self, id, reason)
end)

mod:hook("HudElementSmartTagging", "_play_tag_sound", function(func, self, tag, ...)
	if should_disable(tag) then
		return
	end
	return func(self, tag, ...)
end)

mod:hook("HudElementSmartTagging", "event_smart_tag_created", function(func, self, tag, ...)
	if should_disable(tag) then
		return
	end
	return func(self, tag, ...)
end)

mod:hook("HudElementSmartTagging", "_add_smart_tag_presentation", function(func, self, tag, ...)
	if should_disable(tag) then
		return
	end
	return func(self, tag, ...)
end)

mod:hook("HudElementSmartTagging", "event_smart_tag_removed", function(func, self, tag, ...)
	if should_disable(tag) then
		self:_remove_smart_tag_presentation(tag:id())
		return
	end
	return func(self, tag, ...)
end)

mod:hook("OutlineSystem", "_event_smart_tag_created", function(func, self, tag, ...)
	if should_disable(tag) then
		return
	end
	return func(self, tag, ...)
end)

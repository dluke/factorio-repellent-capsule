
local function on_new_grenade_hit(event)
		log("grenade_hit")
	local target = event.entity
	if target.force.name == "enemy" then
		log("on_entity_damaged")
		target.set_command({
			type = defines.command.flee,
			from = event.cause
				-- type = defines.command.go_to_location,
				-- destination = {x = 40, y = 40}
				-- ticks_to_wait = 1000
		})
	end
	-- if target.type == "unit" and target.force.name == "enemy" then
	--   -- make biters run away from grenade
	--   -- local new_pos = target.position - event.source_position
	--   target.set_command({
	--     type = defines.command.flee,
	--     from = event.cause
	--     -- make biters run in the opposite direction of the grenade
	--   })
	-- end
end

-- add event handler for new-grenade hits
script.on_event(defines.events.on_entity_damaged, function(event)
	if event.damage_type.name == "explosion" and event.original_damage_amount >= 0 then
		log('damage' .. event.damage_type.name .. event.original_damage_amount)
		on_new_grenade_hit(event)
	end
end)


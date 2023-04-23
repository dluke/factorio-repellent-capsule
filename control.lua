
script.on_init(function()
	-- keep track of biters affected by the fear debuff
	global.feared = {}
	-- global.feared_indicator = {}
end)



local function on_new_grenade_hit(event)
	local target = event.entity
	if target.force.name ~= "enemy" then
		return
	end
	if target.spawner == nil then 
		target.set_command({
				type = defines.command.flee,
				from = event.cause,
				distraction = defines.distraction.none
		})
	else
		target.set_command({
			type = defines.command.compound,
			structure_type = defines.compound_command.return_last,
			commands = {
				{
					type = defines.command.flee,
					from = event.cause,
					distraction = defines.distraction.none
				},
				{
					type = defines.command.go_to_location,
					destination_entity = target.spawner,
					distraction = defines.distraction.by_damage
				}
			}
		})
	end
	global.feared[target.unit_number] = target

	-- local trail_entity = target.surface.create_entity({name="fear-trail", position=target.position})
	-- global.feared_indicator[target] = trail_entity
end

script.on_event(defines.events.on_ai_command_completed, function(event)
	log("ai command of unit " .. event.unit_number .. " completed")
	local unit_number = event.unit_number
	if global.feared[unit_number] then
		local entity = global.feared[unit_number]
		if entity.stickers then
			for i = #entity.stickers, 1, -1 do
				if entity.stickers[i].name == "repel-sticker" then
					local sticker = table.remove(entity.stickers, i)
					sticker.destroy()
				end
			end
		end
		table.remove(global.feared, unit_number)
	end
end)

-- script.on_event(defines.events.on_tick, function()
-- end)

script.on_event(defines.events.on_entity_damaged, function(event)
	if event.damage_type.name == "repelling" and event.original_damage_amount >= 0 then
		-- log('damage ' .. event.damage_type.name .. ' ' .. event.original_damage_amount)
		if event.entity.type == "unit" then 
			on_new_grenade_hit(event)
		end
	end
end)


-- for testing ---

script.on_event(defines.events.on_player_created, function(event)
	-- hard coded position
	local starship = game.get_surface("nauvis").find_entity("crash-site-spaceship", {-5,-6})
	local player = game.get_player(event.player_index)
	local cache = starship

	-- give the player a stack of repel capsules
	if settings.startup["grenade-cache"] then 
		cache.insert({name = "repel-capsule", count = 26})
		cache.insert({name = "poison-capsule", count = 16})
		cache.insert({name = "slowdown-capsule", count = 25})
		cache.insert({name = "grenade", count = 10})
	end
end)


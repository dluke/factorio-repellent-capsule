
local math2d = require("math2d")

script.on_init(function()
	-- keep track of biters affected by the fear debuff
	global.feared = {}
	global.postpone = {}
	global.shivered = {}
	global.shivered_toggle = {}
	-- global.feared_indicator = {}
	global.repel_count = {}
end)


local function increment_repel_count(entity)
	if global.repel_count[entity.unit_number] == nil then
		global.repel_count[entity.unit_number] = 1
	else
		global.repel_count[entity.unit_number] = global.repel_count[entity.unit_number] + 1
	end
end

-- clean up
script.on_event(defines.events.on_entity_died, function(event)
	global.feared[event.entity.unit_number] = nil
	global.shivered[event.entity.unit_number] = nil
	global.shivered_toggle[event.entity.unit_number] = nil
	global.repel_count[event.entity.unit_number] = nil
end)

local function apply_shivered(entity) 
	global.shivered[entity.unit_number] = entity
	global.shivered_toggle[entity.unit_number] = 1
	entity.set_command({
		type = defines.command.stop,
		distraction = defines.distraction.none,
		-- ticks_to_wait = 10
	})
end

local function update_shivering()
	local shift = 0.1
	for unit_number, entity in pairs(global.shivered) do
		local shift_state = global.shivered_toggle[unit_number]
		entity.teleport({x = entity.position.x + shift_state * shift, y = entity.position.y})
		global.shivered_toggle[unit_number] = global.shivered_toggle[unit_number] * -1
	end
end

local function flee_from_cause(cause, entity, flee_distance) 
	-- !implement flee ourselves
	local vector = math2d.position.subtract(cause.position, entity.position)

	local target_vector = math2d.position.multiply_scalar(vector, flee_distance / math2d.position.vector_length(vector))
	local target_destination = math2d.position.add(cause.position, target_vector)
	log('destination ' .. target_destination.x .. ' ' .. target_destination.y)
	local command = {
		type = defines.command.go_to_location,
		destination = target_destination,
		distraction = defines.distraction.none
	}
	return command

end

local function on_new_grenade_hit(event)
	local target = event.entity
	if target.force.name ~= "enemy" then
		return
	end
	increment_repel_count(target)
	-- apply_shivered(target)

	if target.spawner == nil then 
		apply_shivered(target)
		-- target.set_command({
		-- 		type = defines.command.flee,
		-- 		from = event.cause,
		-- 		distraction = defines.distraction.none
		-- })
	else
		target.set_command({
			type = defines.command.flee,
			from = event.cause,
			distraction = defines.distraction.none
		})
		-- local flee_distance = 100
		-- target.set_command({
		-- 	type = defines.command.compound,
		-- 	structure_type = defines.compound_command.logical_or,
		-- 	commands = {
		-- 		-- target.set_command(flee_from_cause(event.cause, target, flee_distance)),
		-- 		{
		-- 			type = defines.command.flee,
		-- 			from = event.cause,
		-- 			distraction = defines.distraction.none
		-- 		},
		-- 		{
		-- 			type = defines.command.go_to_location,
		-- 			destination_entity = target.spawner,
		-- 			distraction = defines.distraction.by_damage
		-- 		}
		-- 	}
		-- })
	end
	global.feared[target.unit_number] = target

end

script.on_event(defines.events.on_ai_command_completed, function(event)
	-- log("ai command of unit " .. event.unit_number .. " completed")
	local unit_number = event.unit_number
	if global.feared[unit_number] then
		local entity = global.feared[unit_number]
		global.postpone[entity] = true
		-- handle debuff
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


script.on_event(defines.events.on_entity_damaged, function(event)
	if event.damage_type.name == "repelling" and event.original_damage_amount >= 0 then
		-- log('damage ' .. event.damage_type.name .. ' ' .. event.original_damage_amount)
		if event.entity.type == "unit" then 
			on_new_grenade_hit(event)
		end
	end
end)

script.on_event(defines.events.on_tick, function()
	for entity, _ in pairs(global.postpone) do
		if entity.valid then
			entity.set_command({
				type = defines.command.go_to_location,
				destination_entity = entity.spawner,
				distraction = defines.distraction.by_damage
			})
		end
		global.postpone[entity] = nil
	end

	local tick = game.tick
	if tick % 3 == 0 then
		update_shivering()
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


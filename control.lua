
local inspect = require("inspect")

local math2d = require("math2d")

function init_repellent()
	-- keep track of biters affected by the fear debuff
	global.feared = {}
	global.repel_count = {}
	global.repel_resistance = {}
	-- global.postpone = {}
	global.shivered = {}
	global.shivered_toggle = {}
	-- global.feared_indicator = {}
end


script.on_init(function()
	-- 
	init_repellent()
	-- init grenade cache
	if settings.startup["grenade-cache"] then 
		if remote.interfaces["freeplay"] then
			if not settings.startup['disable-crashsite'].value then 
				local ship_items = remote.call("freeplay", "get_ship_items")
				ship_items["repel-capsule"] = 28
				ship_items["poison-capsule"] = 16
				ship_items["slowdown-capsule"] = 25
				ship_items["grenade"] = 10
				remote.call("freeplay", "set_ship_items", ship_items)
			end
		end
	end
end)

local repellent_resistance_table = {
	["small-biter"] = {{1.0, 1}},
	["medium-biter"] = {{0.7, 1}, {0.3, 2}},
	["bit-biter"] = {{0.2, 1}, {0.8, 2}},
	["behemoth-biter"] = {{0.1, 2}, {0.7, 3}, {0.2, 4}},
-- 
	["small-spitter"] =  {{1.0, 1}},
	["medium-spitter"] =  {{1.0, 1}},
	["big-spitter"] =  {{0.7, 1}, {0.3, 2}},
	["behemoth-spitter"] = {{0.4, 2}, {0.6, 3}},
}

function draw_resistance(biter) 
	local resist_table = repellent_resistance_table[biter.name]
	if resist_table == nil then return 1 end
	local u = math.random()
	local value = 1
	for _, pair in pairs(resist_table) do
		if u < pair[1] then
			value = pair[2]
			break
		end
	end
	return value
end


local function increment_repel_count(entity)
	if global.repel_count[entity.unit_number] == nil then
		global.repel_resistance[entity.unit_number] = draw_resistance(entity)
		-- log('resistance value ' .. global.repel_resistance[entity.unit_number])
		global.repel_count[entity.unit_number] = 1
	else
		global.repel_count[entity.unit_number] = global.repel_count[entity.unit_number] + 1
	end
end

-- clean up
script.on_event(defines.events.on_entity_died, function(event)
	if not event.entity.unit_number then
		return
	end
	global.feared[event.entity.unit_number] = nil
	global.shivered[event.entity.unit_number] = nil
	global.shivered_toggle[event.entity.unit_number] = nil
	global.repel_count[event.entity.unit_number] = nil
	global.repel_resistance[event.entity.unit_number] = nil
end)

local function apply_shivered(entity, ticks_to_wait) 
	global.shivered[entity.unit_number] = entity
	global.shivered_toggle[entity.unit_number] = 1
	entity.set_command({
		type = defines.command.stop,
		distraction = defines.distraction.none,
		ticks_to_wait = ticks_to_wait
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

-- !implement flee ourselves
-- !not used
local function flee_from_cause(cause, entity, flee_distance) 
	local vector = math2d.position.subtract(cause.position, entity.position)

	local target_vector = math2d.position.multiply_scalar(vector, flee_distance / math2d.position.vector_length(vector))
	local target_destination = math2d.position.add(cause.position, target_vector)
	-- log('destination ' .. target_destination.x .. ' ' .. target_destination.y)
	local command = {
		type = defines.command.go_to_location,
		destination = target_destination,
		distraction = defines.distraction.none
	}
	return command
end

local function on_grenade_hit(event)
	local target = event.entity
	if target.force.name ~= "enemy" then
		return
	end
	log('unit_group ' .. inspect(target.unit_group))
	increment_repel_count(target)

	if global.repel_count[target.unit_number] >= global.repel_resistance[target.unit_number] then
		target.set_command({
				type = defines.command.flee,
				from = event.cause,
				distraction = defines.distraction.none
			})
	else
		apply_shivered(target, 20)
	end
	global.feared[target.unit_number] = target

	-- if target.spawner == nil then 
	-- 	apply_shivered(target)
	-- else
	-- 	target.set_command({
	-- 		type = defines.command.flee,
	-- 		from = event.cause,
	-- 		distraction = defines.distraction.none
	-- 	})
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
	-- end

end

local function find_spawner(entity)
	-- TODO efficiency
	return entity.surface.find_entities_filtered({type="unit-spawner"})[1]
end


script.on_event(defines.events.on_ai_command_completed, function(event)
	-- log("ai command of unit " .. event.unit_number .. " completed")
	local unit_number = event.unit_number
	if global.shivered[unit_number] then
		global.shivered[unit_number] = nil
		return
	end


	if global.feared[unit_number] ~= nil then
		local entity = global.feared[unit_number]
		local spawner = entity.spawner or find_spawner(entity)
		if entity.valid and spawner then
			log('go to location' .. spawner.position.x .. ' ' ..spawner.position.y)
			entity.set_command({
				type = defines.command.go_to_location,
				radius = 5,
				destination_entity = spawner,
				distraction = defines.distraction.none,
				pathfind_flags = {allow_destroy_friendly_entities = true, allow_paths_through_own_entities = true}
			})
		end
		-- handle debuff
		if entity.stickers then
			for i = #entity.stickers, 1, -1 do
				if entity.stickers[i].name == "repel-sticker" then
					local sticker = table.remove(entity.stickers, i)
					sticker.destroy()
				end
			end
		end
		global.feared[unit_number] = nil
		-- table.remove(global.feared, unit_number)
	end
end)


script.on_event(defines.events.on_entity_damaged, function(event)
	if event.damage_type.name == "repelling" and event.original_damage_amount >= 0 then
		-- log('damage ' .. event.damage_type.name .. ' ' .. event.original_damage_amount)
		if event.entity.type == "unit" then 
			on_grenade_hit(event)
		end
	end
end)


script.on_event(defines.events.on_tick, function()
	local tick = game.tick
	if tick % 2 == 0 then
		update_shivering()
	end
end)



-- for testing ---

function insert_capsule_pack(cache) 
	cache.insert({name = "repel-capsule", count = 26})
	cache.insert({name = "poison-capsule", count = 16})
	cache.insert({name = "slowdown-capsule", count = 25})
	cache.insert({name = "grenade", count = 10})
end

script.on_event(defines.events.on_player_created, function(event)
	local enemy_force = game.forces["enemy"]
	enemy_force.evolution_factor = 0.99
end)


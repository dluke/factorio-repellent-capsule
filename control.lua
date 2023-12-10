

local FLEE_ONLY = true

local inspect = require("inspect")
local math2d = require("math2d")

local DEBUG = false
function debug(string) 
	if DEBUG then
		log(string)
	end
end


function init_repellent()
	-- keep track of biters affected by the fear debuff
	global.feared = {}
	global.biter_data = {}
	global.shivered = {}
	global.shivered_toggle = {}
end


script.on_init(function()
	-- 
	init_repellent()
	-- init grenade cache
	if settings.startup["grenade-cache"] then 
		if remote.interfaces["freeplay"] then
			if settings.startup['disable-crashsite'] ~= nil and not settings.startup['disable-crashsite'].value then 
				local ship_items = remote.call("freeplay", "get_ship_items")
				ship_items["repel-capsule"] = 58
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
	local feared = global.feared[entity.unit_number]
	if feared == nil then
		global.feared[entity.unit_number] = {entity = entity, repel_count = 1, repel_resistance = draw_resistance(entity)}
	else
		feared.repel_count = feared.repel_count + 1
	end
end

script.on_event(defines.events.on_entity_spawned, function(event)
	-- this check is needed because on_entity_spawned is called before on_init
	if global.biter_data == nil then
		global.biter_data = {}
	end
	global.biter_data[event.entity.unit_number] = {entity = event.entity, spawner = event.spawner, spawn_position = event.spawner.position}
end)

function _destroy_biter_data(entity)
	global.feared[entity.unit_number] = nil
	global.biter_data[entity.unit_number] = nil
	global.shivered[entity.unit_number] = nil
	global.shivered_toggle[entity.unit_number] = nil
end

-- clean up
script.on_event(defines.events.on_entity_died, function(event)
	if not event.entity.unit_number then
		return
	end
	_destroy_biter_data(event.entity)
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

local function on_grenade_hit(event)
	local target = event.entity
	if target.force.name ~= "enemy" then
		return
	end
	debug('unit_group ' .. inspect(target.unit_group))
	increment_repel_count(target)

	local feared = global.feared[target.unit_number]
	if feared.repel_count >= feared.repel_resistance then
		target.set_command({
				type = defines.command.flee,
				from = event.cause,
				distraction = defines.distraction.none
			})
	else
		apply_shivered(target, 20)
	end
end

local function find_spawn_location(entity)
	-- return entity.surface.find_entities_filtered({type="unit-spawner"})[1]
	local data = global.biter_data[entity.unit_number]
	if data == nil then
		debug("no biter data")
		return
	end
	if data.spawner.valid then
		return data.spawner.position
	else
		debug('warning: home spawner is invalid')
		return data.spawn_position
	end
end

function get_area_at(position, r)
	return {{position.x-r, position.y-r}, {position.x+r, position.y+r}}
end

script.on_event(defines.events.on_ai_command_completed, function(event)
	-- log("ai command of unit " .. event.unit_number .. " completed")
	local unit_number = event.unit_number
	if global.shivered[unit_number] then
		global.shivered[unit_number] = nil
		return
	end

	local data = global.biter_data[unit_number]
	if data == nil then return end

	local entity = data.entity
	if entity.stickers then
		for i = #entity.stickers, 1, -1 do
			if entity.stickers[i].name == "repel-sticker" then
				local sticker = table.remove(entity.stickers, i)
				sticker.destroy()
			end
		end
		global.feared[unit_number] = nil
	end

	if not FLEE_ONLY then
		local DESPAWN_RADIUS = 5
		if data.return_to_spawner ~= nil then
			-- ! complete return command -- if already units nearby, despawn
			local biters = entity.surface.find_entities_filtered({type = "unit", force = "enemy", area = get_area_at(entity.position, DESPAWN_RADIUS)})
			-- TODO if biters don't despawn their AI sometimes gets stuck -- can I delete them and force the spawner to spawn one?
			if #biters > 0 then
				_destroy_biter_data(data.entity)
				data.entity.destroy()
			end
			-- ! otherwise do not despawn
		elseif global.feared[unit_number] ~= nil then
			-- ! completed fear command
			local location = find_spawn_location(entity)
			if location then
				debug('go to location' .. location.x .. ' ' ..location.y)
				entity.set_command({
					type = defines.command.go_to_location,
					radius = 6,
					destination = location,
					-- destination_entity = spawner,
					distraction = defines.distraction.none,
					pathfind_flags = {allow_destroy_friendly_entities = false, allow_paths_through_own_entities = false}
				})
				global.biter_data[unit_number].return_to_spawner = true
			end
		end
	end
end)


script.on_event(defines.events.on_entity_damaged, function(event)
	if event.damage_type.name == "repelling" and event.original_damage_amount >= 0 then
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

-- script.on_event(defines.events.on_player_created, function(event)
-- 	local enemy_force = game.forces["enemy"]
-- 	-- !tmp
-- 	enemy_force.evolution_factor = 0.99
-- end)


-- define new grenade type

require("particles")

local util = require("util")
local sounds = require ("__base__/prototypes/entity/sounds")
local smoke_animations = require("__base__/prototypes/entity/smoke-animations")

local smoke_fast_animation = smoke_animations.trivial_smoke_fast
local trivial_smoke = smoke_animations.trivial_smoke



-- expand the crashed ship container
local ship_container_size = data.raw["container"]["crash-site-spaceship"].inventory_size
data.raw["container"]["crash-site-spaceship"].inventory_size = math.max(ship_container_size, 20)

data:extend(
{
  {
    type = "damage-type",
    name = "repelling"
  }
})

-- set the player to be resistant to repelling damage
-- TODO compatibility
data.raw["character"]["character"]["resistances"] = {{type = "repelling", percent = 100}}


-- helper
local default_light = function(size)
  return
  {
    intensity = 1,
    size = size,
    color = {r = 1.0, g = 1.0, b = 1.0}
  }
end



local repel_capsule = {
	type = "capsule",
	name = "repel-capsule",
	icon = "__repellent-capsule__/graphics/icons/fear-capsule.png",
	icon_size = 64, icon_mipmaps = 4,
	capsule_action =
	{
		type = "throw",
		attack_parameters =
		{
			type = "projectile",
			activation_type = "throw",
			ammo_category = "grenade",
			cooldown = 30,
			projectile_creation_distance = 0.6,
			range = 25,
			ammo_type =
			{
				category = "grenade",
				target_type = "position",
				action =
				{
					{
						type = "direct",
						action_delivery =
						{
							type = "projectile",
							projectile = "repel-grenade",
							starting_speed = 0.3
						}
					},
					{
						type = "direct",
						action_delivery =
						{
							type = "instant",
							target_effects =
							{
								{
									type = "play-sound",
									sound = sounds.throw_projectile
								}
							}
						}
					}
				}
			}
		}
	},
	-- radius_color = { r = 0.25, g = 0.05, b = 0.25, a = 0.25 },
	subgroup = "capsule",
	order = "a[grenade]-a[normal]",
	stack_size = 100
}

capsule_smoke =
{
  {
    name = "smoke-fast",
    deviation = {0.15, 0.15},
    frequency = 1,
    position = {0, 0},
    starting_frame = 3,
    starting_frame_deviation = 5,
    starting_frame_speed_deviation = 5
  }
}

local flash = {
	type = "particle-source",
	name = "capsule-flash",
	localised_name = {"entity-name.capsule-flash"},
	icon = "__base__/graphics/item-group/effects.png",
	icon_size = 64,
	flags = {"not-on-map", "hidden"},
	subgroup = "explosions",
	light = default_light(50),
	-- sound = sounds.medium_explosion(0.4)
	time_to_live = 10,
	time_before_start = 0,
	height = 0.4,
	vertical_speed = 0.0,
	horizontal_speed = 0.0,
	smoke = capsule_smoke
}

local repel_grenade = 
{
	type = "projectile",
	name = "repel-grenade",
	flags = {"not-on-map"},
	acceleration = 0.005,
	action = {
		{
			type = 'direct',
			action_delivery = 
			{ 
				type = "instant",
				target_effects = 
				{
					-- {
					-- 	type = "create-entity",
					-- 	entity_name = "fear-cloud"
					-- },
					{
						type = "create-particle",
						repeat_count = 40,
            particle_name = "repel-smoke-particle",
            -- particle_name = "explosion-stone-particle-medium",
            initial_height = 0.1,
            speed_from_center = 0.12,
            speed_from_center_deviation = 0.20,
						-- frame_speed_deviation = -0.1,
            initial_vertical_speed = 0.00,
            offset_deviation = { { -0.8984, -0.5 }, { 0.8984, 0.5 } }
					},
					{
						type = "play-sound",
						sound = sounds.poison_capsule_explosion(0.3)
					}
				}
			}
		},
		{
			type = "area",
			force = "enemy",
			radius = 12.0,
			action_delivery =
			{
				type = "instant",
				target_effects =
				{
					{
						type = "damage",
						damage = {amount = 1, type = "repelling"}
					},
					{
						type = "create-sticker",
						sticker = "repel-sticker"
					}
				}
			}
		}
	},
	light = {intensity = 1.0, size = 8},
	animation =
	{
		filename = "__repellent-capsule__/graphics/entity/fear-capsule.png",
		draw_as_glow = true,
		frame_count = 15,
		line_length = 8,
		animation_speed = 0.250,
		width = 26,
		height = 28,
		shift = util.by_pixel(1, 1),
		priority = "high",
		-- TODO hr_version?
	},
	shadow =
	{
		filename = "__base__/graphics/entity/grenade/grenade-shadow.png",
		frame_count = 15,
		line_length = 8,
		animation_speed = 0.250,
		width = 26,
		height = 20,
		shift = util.by_pixel(2, 6),
		priority = "high",
		draw_as_shadow = true,
		hr_version =
		{
			filename = "__base__/graphics/entity/grenade/hr-grenade-shadow.png",
			frame_count = 15,
			line_length = 8,
			animation_speed = 0.250,
			width = 50,
			height = 40,
			shift = util.by_pixel(2, 6),
			priority = "high",
			draw_as_shadow = true,
			scale = 0.5
		}
	}
}



local fear_trail = {
	name = "fear-trail",
	type = "smoke-with-trigger",
	flags = {"not-on-map"},
	show_when_smoke_off = true,
	affected_by_wind = false,
	cyclic = true,
	duration = 20 * 60,
	fade_in_duration = 1,
	fade_away_duration = 1,
	color = {r = 241/255, g = 91/255, b = 1, a = 0.590}, -- #F15BFF
	animation = 
	{
    filename = "__base__/graphics/entity/smoke-fast/smoke-fast.png",
    priority = "high",
    width = 50,
    height = 50,
    frame_count = 16,
    animation_speed = 16 / 60,
    scale = 1.0,
    tint = {r = 1, g = 1, b = 1, a = 1}
  }
}

 
local fear_cloud = {
	name = "fear-cloud",
	type = "smoke-with-trigger",
	flags = {"not-on-map"},
	show_when_smoke_off = true,
	particle_count = 16,
	particle_spread = { 1.6 * 1.05, 1.6 * 0.6 * 1.05 },
	particle_distance_scale_factor = 0.5,
	particle_scale_factor = { 1, 0.707 },
	wave_speed = { 1/80, 1/60 },
	wave_distance = { 1.3, 0.2 },
	spread_duration_variation = 4,
	particle_duration_variation = 60 * 0.5,
	render_layer = "object",
	speed_from_center = 1.0,

	affected_by_wind = false,
	cyclic = true,
	fade_in_duration = 1,
	duration = 1.5 * 60,
	fade_away_duration = 0.5 * 60,
	spread_duration = 20,
	-- color = {r = 0.239, g = 0.875, b = 0.992, a = 0.690}, -- #3ddffdb0,
	color = {r = 241/255, g = 91/255, b = 1, a = 0.590}, -- #F15BFF

	animation =
	{
		width = 152,
		height = 120,
		line_length = 5,
		frame_count = 60,
		shift = {-0.53125, -0.4375},
		priority = "high",
		animation_speed = 1.0,
		filename = "__base__/graphics/entity/smoke/smoke.png",
		flags = { "smoke" }
	}
}

local fear_sticker = {
	type = "sticker",
	name = "repel-sticker",
	flags = {},
	animation =
	{
		filename = "__base__/graphics/entity/slowdown-sticker/slowdown-sticker.png",
		priority = "extra-high",
		line_length = 5,
		width = 22,
		height = 24,
		frame_count = 50,
		animation_speed = 0.5,
		tint = {r = 1.000, g = 0.663, b = 0.000, a = 0.694}, -- #ffa900b1
		shift = util.by_pixel (2,-1),
		hr_version =
		{
			filename = "__base__/graphics/entity/slowdown-sticker/hr-slowdown-sticker.png",
			line_length = 5,
			width = 42,
			height = 48,
			frame_count = 50,
			animation_speed = 0.5,
			tint = {r = 241/255, g = 91/255, b = 1, a = 0.590}, -- #F15BFF
			shift = util.by_pixel(2, -0.5),
			scale = 0.5
		}
	},
	duration_in_ticks = 10 * 60,
	target_movement_modifier = 0.9
}



data:extend{
	repel_capsule, 
	repel_grenade, 
	flash, 
	fear_cloud,
	fear_trail,
	fear_sticker,
	repel_smoke_particle
}

data:extend{
	{
		type = "recipe",
		name = "repel-capsule",
		enabled = true,
		energy_required = 8,
		ingredients =
		{
			{"steel-plate", 2},
			{"electronic-circuit", 3},
			{"sulfur", 5}
		},
		result = "repel-capsule"
	}
}

-- add this recipe to an existing technology

table.insert(data.raw["technology"]["military-3"]["effects"], {recipe = "repel-capsule", type="unlock-recipe"})

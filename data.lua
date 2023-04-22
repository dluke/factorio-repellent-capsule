-- define new grenade type

local sounds = require ("__base__/prototypes/entity/sounds")



data:extend(
{
  {
    type = "damage-type",
    name = "repelling"
  }
})

-- set the player to be resistant to repelling damage
-- data.raw["character"]["resistances"] = {repelling = 1.0}
-- TODO compatibility
data.raw["character"]["character"]["resistances"] = {{type = "repelling", percent = 100}}
data.raw["character"]["character"]["damage_hit_tint"] = {r=0, g=0, b=0, a=0}


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
	icon = "__pacifactorio__/graphics/icons/fear-capsule.png",
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
			range = 15,
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
			action_delivery = { 
				type = "instant",
				target_effects = {
					{
						type = "create-entity",
						entity_name = "fear-cloud"
					}
				}
			}
		},
		{
			type = "area",
			radius = 6.5,
			action_delivery =
			{
				type = "instant",
				target_effects =
				{
					{
						type = "damage",
						damage = {amount = 1, type = "repelling"}
					},
				}
			}
		}
	},
	light = {intensity = 1.0, size = 8},
	animation =
	{
		filename = "__pacifactorio__/graphics/entity/fear-capsule.png",
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

	affected_by_wind = false,
	cyclic = true,
	fade_in_duration = 1,
	duration = 1.5 * 60,
	fade_away_duration = 0.5 * 60,
	spread_duration = 20,
	-- color = {r = 0.239, g = 0.875, b = 0.992, a = 0.690}, -- #3ddffdb0,
	color = {r = 241/255, g = 91/255, b = 1, a = 0.390}, -- #F15BFF

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

data:extend{repel_capsule, repel_grenade, flash, fear_cloud}

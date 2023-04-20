-- define new grenade type

data:extend(
{
  {
    type = "damage-type",
    name = "repelling"
  }
})

-- helper
local default_light = function(size)
  return
  {
    intensity = 1,
    size = size,
    color = {r = 1.0, g = 1.0, b = 1.0}
  }
end


-- local grenade = table.deepcopy(data.raw["ammo"]["grenade"])
-- grenade.name = "repel-grenade"
local sounds = require ("__base__/prototypes/entity/sounds")

local repel_capsule = {
	type = "capsule",
	name = "repel-capsule",
	icon = "__base__/graphics/icons/grenade.png",
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
							-- projectile = "repel-grenade",
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
						entity_name = "capsule-flash"
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
						damage = {amount = 1, type = "explosion"}
					},
				}
			}
		}
	},
	light = {intensity = 1.0, size = 8},
	animation =
	{
		filename = "__base__/graphics/entity/grenade/grenade.png",
		draw_as_glow = true,
		frame_count = 15,
		line_length = 8,
		animation_speed = 0.250,
		width = 26,
		height = 28,
		shift = util.by_pixel(1, 1),
		priority = "high",
		hr_version =
		{
			filename = "__base__/graphics/entity/grenade/hr-grenade.png",
			draw_as_glow = true,
			frame_count = 15,
			line_length = 8,
			animation_speed = 0.250,
			width = 48,
			height = 54,
			shift = util.by_pixel(0.5, 0.5),
			priority = "high",
			scale = 0.5
		}

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

data:extend{repel_capsule, repel_grenade, flash}

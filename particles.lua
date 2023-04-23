
local sounds = require("__base__.prototypes.entity.sounds")
-- TODO directly require __base__/prototypes/particle

local particle_animations = {}

local default_ended_in_water_trigger_effect = function()
  return
  {

    {
      type = "create-particle",
      probability = 1,
      affects_target = false,
      show_in_tooltip = false,
      particle_name = "deep-water-particle",
      offset_deviation = { { -0.05, -0.05 }, { 0.05, 0.05 } },
      tile_collision_mask = nil,
      initial_height = 0,
      initial_height_deviation = 0.02,
      initial_vertical_speed = 0.05,
      initial_vertical_speed_deviation = 0.05,
      speed_from_center = 0.01,
      speed_from_center_deviation = 0.006,
      frame_speed = 1,
      frame_speed_deviation = 0,
      tail_length = 2,
      tail_length_deviation = 1,
      tail_width = 3
    },
    {
      type = "create-particle",
      repeat_count = 10,
      repeat_count_deviation = 6,
      probability = 0.03,
      affects_target = false,
      show_in_tooltip = false,
      particle_name = "water-particle",
      offsets =
      {
        { 0, 0 },
        { 0.01563, -0.09375 },
        { 0.0625, 0.09375 },
        { -0.1094, 0.0625 }
      },
      offset_deviation = { { -0.2969, -0.1992 }, { 0.2969, 0.1992 } },
      tile_collision_mask = nil,
      initial_height = 0,
      initial_height_deviation = 0.02,
      initial_vertical_speed = 0.053,
      initial_vertical_speed_deviation = 0.005,
      speed_from_center = 0.02,
      speed_from_center_deviation = 0.006,
      frame_speed = 1,
      frame_speed_deviation = 0,
      tail_length = 9,
      tail_length_deviation = 0,
      tail_width = 1
    },
    {
      type = "play-sound",
      sound = sounds.small_splash
    }
  }

end



local make_particle = function(params)

  if not params then error("No params given to make_particle function") end
  local name = params.name or error("No name given")

  local ended_in_water_trigger_effect = params.ended_in_water_trigger_effect or default_ended_in_water_trigger_effect()
  if params.ended_in_water_trigger_effect == false then
    ended_in_water_trigger_effect = nil
  end

  local particle =
  {

    type = "optimized-particle",
    name = name,

    life_time = params.life_time or 60 * 15,
    fade_away_duration = params.fade_away_duration,

    render_layer = params.render_layer or "projectile",
    render_layer_when_on_ground = params.render_layer_when_on_ground or "corpse",

    regular_trigger_effect_frequency = params.regular_trigger_effect_frequency or 2,
    regular_trigger_effect = params.regular_trigger_effect,
    ended_in_water_trigger_effect = ended_in_water_trigger_effect,

    pictures = params.pictures,
    shadows = params.shadows,
    draw_shadow_when_on_ground = params.draw_shadow_when_on_ground,

    movement_modifier_when_on_ground = params.movement_modifier_when_on_ground,
    movement_modifier = params.movement_modifier,
    vertical_acceleration = params.vertical_acceleration,

    mining_particle_frame_speed = params.mining_particle_frame_speed,

  }

  return particle

end

particle_animations.get_general_dust_particle = function(options)
  local options = options or {}
  return
  {
    sheet =
    {
    filename = "__base__/graphics/entity/smoke-fast/smoke-general.png",
    priority = "high",
    width = 50,
    height = 50,
    frame_count = 16,
    animation_speed = 1 / 2,
    scale = 0.5,
    variation_count = 1,
    tint = options.tint,
    affected_by_wind = true
    }
  }
end

particle_animations.get_smoke_particle = function(options)
  local options = options or {}
  return
  {
    sheet =
    {
    filename = "__base__/graphics/entity/smoke/smoke.png",
    priority = "high",
    width = 152,
    height = 120,
    frame_count = 60,
    line_length = 5,
    animation_speed = 1.2,
    -- scale = 0.8,
    variation_count = 1,
    tint = options.tint,
    affected_by_wind = false,
    -- movement_modifier = 0.5
    }
  }
end

-- {
--   width = 152,
--   height = 120,
--   line_length = 5,
--   frame_count = 60,
--   shift = {-0.53125, -0.4375},
--   priority = "high",
--   animation_speed = 1.0,
--   filename = "__base__/graphics/entity/smoke/smoke.png",
--   flags = { "smoke" }
-- }



-- !mod particles
local purple = {r = 241/255, g = 91/255, b = 1, a = 0.690}

local repel_smoke_particle = make_particle
{
	name = "repel-smoke-particle",
	life_time = 0.5 * 60,
	pictures = particle_animations.get_smoke_particle({ tint = purple}),  --({ tint = { r = 0.443, g = 0.333, b = 0.189, a = 0.502 }}),
	shadows = nil,
	ended_in_water_trigger_effect = false,
	movement_modifier = 0.1,
	movement_modifier_when_on_ground = 0,
  cyclic = true,
	fade_in_duration = 1,
	fade_away_duration = 0.3 * 60,
	render_layer = "lower-object"
}

data:extend{
  repel_smoke_particle
}

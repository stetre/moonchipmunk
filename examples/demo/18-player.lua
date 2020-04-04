#!/usr/bin/env lua
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local cp = require("moonchipmunk")
local toolbox = require("moonchipmunk.toolbox")

cp.glmath_compat(true)
local pi, infinity = math.pi, math.huge
local sin, cos, abs, exp, sqrt = math.sin, math.cos, math.abs, math.exp, math.sqrt
local fmt = string.format
local vec2 = glmath.vec2
local clamp, mix = glmath.clamp, glmath.mix
local identity = cp.transform_identity()

-- Initializations ------------------------------------------------------------

local TITLE = "Platformer Player Controls"
local FW, FH = 640, 480 -- width and height of the field
local W, H = 1024, 768 -- window width and height
local BG_COLOR = {0x07/255, 0x36/255, 0x42/255, 1.0}
local FONT_COLOR, FONT_SIZE = {0xfd/250, 0xf6/250, 0xe3/250, 1.0}, 12/H
local RED = {1, 0, 0, 1}
local BLUE = {0, 0, 1, 1}
local BLUE1 = {0, 0, 1, .1}

glfw.version_hint(3, 3, 'core')
glfw.window_hint('samples', 32)
local window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
gl.init()
toolbox.init(W, H)
local camera = toolbox.camera()

local function resize(window, width, height)
   W, H = width, height
   toolbox.resize(W, H)
   toolbox.set_matrices(camera:view(), camera:projection(-FW/2, FW/2, -FH/2, FH/2))
   gl.viewport(0, 0, W, H)
end

glfw.set_window_size_callback(window, resize)
resize(window, W, H)

-- Fonts ----------------------------------------------------------------------
local font = toolbox.font("../ttf-bitstream-vera-1.10/VeraMoBd.ttf", 40/H)

-- Demo inits -----------------------------------------------------------------

local PLAYER_VELOCITY=500.0
local PLAYER_GROUND_ACCEL_TIME=0.1
local PLAYER_GROUND_ACCEL=(PLAYER_VELOCITY/PLAYER_GROUND_ACCEL_TIME)
local PLAYER_AIR_ACCEL_TIME=0.25
local PLAYER_AIR_ACCEL=(PLAYER_VELOCITY/PLAYER_AIR_ACCEL_TIME)
local JUMP_HEIGHT=50.0
local JUMP_BOOST_HEIGHT=55.0
local FALL_VELOCITY=900.0
local GRAVITY=2000.0

local remainingBoost = 0
local grounded, lastJumpState = false, false

local key_x, key_y = 0, 0

local function playerUpdateVelocity(body, gravity, damping, dt)
   local jumpState = (key_y > 0.0)
   -- Grab the grounding normal from last frame
   local groundNormal = vec2(0, 0)
   body:each_arbiter(function(body, arbiter)
      local n = -arbiter:get_normal()
      if n.y > groundNormal.y then groundNormal = n end
   end)
   grounded = (groundNormal.y > 0.0)
   if groundNormal.y < 0.0 then remainingBoost = 0.0 end
   -- Do a normal-ish update
   local boost = jumpState and remainingBoost > 0.0
   local g = boost and vec2() or gravity
   body:update_velocity(g, damping, dt)
   -- Target horizontal speed for air/ground control
   local target_vx = PLAYER_VELOCITY*key_x
   -- Update the surface velocity and friction
   -- Note that the "feet" move in the opposite direction of the player.
   local surface_v = {-target_vx, 0.0}
   body:each_shape(function(body, shape)
      shape:set_surface_velocity(surface_v)
      shape:set_friction(grounded and PLAYER_GROUND_ACCEL/GRAVITY or 0.0)
   end)
   -- Apply air control if not grounded
   local vel = body:get_velocity()
   if not grounded then -- Smoothly accelerate the velocity
      vel.x = cp.flerpconst(vel.x, target_vx, PLAYER_AIR_ACCEL*dt)
   end
   vel.y = clamp(vel.y, -FALL_VELOCITY, infinity) -- ???
   body:set_velocity(vel)
end

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(10)
space:set_gravity({0, -GRAVITY})
-- space:set_sleep_time_threshold(1000)
local static_body = space:get_static_body()
-- Create segments around the edge of the screen.
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,-240}, {-320,240}, 0.0))
shape:set_elasticity(1.0) shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {320,-240}, {320,240}, 0.0))
shape:set_elasticity(1.0) shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,-240}, {320,-240}, 0.0))
shape:set_elasticity(1.0) shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,240}, {320,240}, 0.0))
shape:set_elasticity(1.0) shape:set_friction(1.0)
shape:set_filter(not_grabbable)
-- Set up the player
local playerBody = space:add_body(cp.body_new(1.0, infinity))
playerBody:set_position({0, -200})
playerBody:set_velocity_update_func(playerUpdateVelocity)
local playerShape = cp.box_shape_new(playerBody, {-15.0, 15.0, -27.5, 27.5}, 10.0)
space:add_shape(playerShape)
-- playerShape = space:add_shape(cp.segment_shape_new(playerBody, {0, 0}, {0, radius}, radius))
playerShape:set_elasticity(0.0) playerShape:set_friction(0.0)
playerShape:set_collision_type(1)
-- Add some boxes to jump on
for i=0, 5 do
   for j=0, 2 do
      local body = space:add_body(cp.body_new(4.0, infinity))
      body:set_position({100 + j*60, -200 + i*60})
      local shape = space:add_shape(cp.box_shape_new(body, 50, 50, 0.0))
      shape:set_elasticity(0.0) shape:set_friction(0.7)
   end
end
   
-- Input handling -------------------------------------------------------------

local toggle_fullscreen = toolbox.toggle_fullscreen(window)
local keys = {} -- keys[k] = true if key k is pressed

local function player_control(key, action)
   if action == 'repeat' then return end
   if     key == 'up'    then key_y = key_y + ((action=='press') and  1 or -1)
   elseif key == 'down'  then key_y = key_y + ((action=='press') and -1 or  1)
   elseif key == 'left'  then key_x = key_x + ((action=='press') and -1 or  1)
   elseif key == 'right' then key_x = key_x + ((action=='press') and  1 or -1)
   end
end

glfw.set_key_callback(window, function(window, key, scancode, action)
   if key == 'escape' and action == 'press' then glfw.set_window_should_close(window, true)
   elseif key == 'f11' and action == 'press' then toggle_fullscreen()
   else
      keys[key] = action ~= 'release'
   end
   player_control(key, action)
end)

glfw.set_cursor_pos_callback(window, function(window, x, y)
   grabber:cursor_pos_callback(x, y)
end)

glfw.set_mouse_button_callback(window, function(window, button, action, shift, control, alt, super)
   grabber:mouse_button_callback(button, action, shift, control, alt, super)
end)

-- Game loop ------------------------------------------------------------------
local timer = toolbox.frame_timer()
local spf = 1/60 -- 1 / desired fps
local fdt = 1/180 -- fixed dt for physics updates
local n_physics_updates = toolbox.fixed_dt_counter(fdt)
local n, dt

local renderer = toolbox.renderer(space)

collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(spf)
   dt = timer:update() -- duration of the current frame
   n = n_physics_updates(dt) -- no. of physics updates to do in this frame

   for i=1, n do
      local jumpState = (key_y > 0.0)
      -- If the jump key was just pressed this frame, jump!
      if jumpState and not lastJumpState and grounded then
         local jump_v = sqrt(2.0*JUMP_HEIGHT*GRAVITY)
         local vel = playerBody:get_velocity()
         playerBody:set_velocity(vel + vec2(0.0, jump_v))
         remainingBoost = JUMP_BOOST_HEIGHT/jump_v
      end
      -- Step the space
      space:step(fdt)
      grabber:step(fdt)
      remainingBoost = remainingBoost - fdt
      lastJumpState = jumpState
   end

   glfw.set_window_title(window, fmt("%s - fps=%.0f, n=%d", TITLE, timer:fps(), n))
   gl.clear_color(BG_COLOR)
   gl.clear('color')

   renderer:begin()
   space:debug_draw()
   renderer:done()

   -- font:draw(message, .05, .9, FONT_SIZE, FONT_COLOR)

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


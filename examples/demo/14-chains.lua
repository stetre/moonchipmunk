#!/usr/bin/env lua
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local cp = require("moonchipmunk")
local toolbox = require("moonchipmunk.toolbox")

cp.glmath_compat(true)
local pi, infinity = math.pi, math.huge
local sin, cos, abs = math.sin, math.cos, math.abs
local fmt = string.format
local vec2 = glmath.vec2
local clamp, mix = glmath.clamp, glmath.mix
local identity = cp.transform_identity()

-- Initializations ------------------------------------------------------------

local TITLE = "Breakable Chains"
local FW, FH = 640, 480 -- width and height of the field
local W, H = 1024, 768 -- window width and height
local BG_COLOR = {0x07/255, 0x36/255, 0x42/255, 1.0}
local FONT_COLOR, FONT_SIZE = {0xfd/250, 0xf6/250, 0xe3/250, 1.0}, 12/H

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

local chain_count, link_count = 8, 10
local breaking_force = 80000

local function breakable_joint_post_solve(joint, space)
   local joint = joint
   local dt = space:get_current_time_step()
   -- Convert the impulse to a force by dividing it by the timestep.
   local force = joint:get_impulse()/dt
   local maxForce = joint:get_max_force()
   -- If the force is almost as big as the joint's max force, break it.
   if force > 0.9*maxForce then
      space:add_post_step_callback(function(space)
            space:remove_constraint(joint)
            joint:free()
      end)
   end
end

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(30)
space:set_gravity({0, -100})
space:set_sleep_time_threshold(0.5)
local static_body = space:get_static_body()
-- Create segments around the edge of the screen.
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,-240}, {-320,240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {320,-240}, {320,240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,-240}, {320,-240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,240}, {320,240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local mass, width, height = 1, 20, 30
local spacing = width*0.3
-- Add lots of boxes.
for i=0, chain_count-1 do
   local prev = nil
   for j= 0, link_count-1 do
      local pos = vec2(40*(i-(chain_count-1)/2.0), 240-(j+0.5)*height-(j+1)*spacing)
      local body = space:add_body(cp.body_new(mass, cp.moment_for_box(mass, width, height)))
      body:set_position(pos)
      local shape = cp.segment_shape_new(body, 
                        {0, (height-width)/2.0}, {0, (width-height)/2.0}, width/2.0)
      space:add_shape(shape)
      shape:set_friction(0.8)
      local constraint
      if not prev then
         constraint = cp.slide_joint_new(body, static_body, {0, height/2}, {pos.x, 240}, 0, spacing)
      else
         constraint = cp.slide_joint_new(body, prev, {0, height/2}, {0, -height/2}, 0, spacing)
      end
      space:add_constraint(constraint)
      constraint:set_max_force(breaking_force)
      constraint:set_post_solve_func(breakable_joint_post_solve)
      constraint:set_collide_bodies(false)
      prev = body
   end
end
local radius = 15.0
local body = space:add_body(cp.body_new(10.0, cp.moment_for_circle(10.0, 0.0, radius, {0, 0})))
body:set_position({0, -240 + radius+5})
body:set_velocity({0, 300})
local shape = space:add_shape(cp.circle_shape_new(body, radius, {0, 0}))
shape:set_elasticity(0.0)
shape:set_friction(0.9)

-- Input handling -------------------------------------------------------------

local toggle_fullscreen = toolbox.toggle_fullscreen(window)
local keys = {} -- keys[k] = true if key k is pressed

glfw.set_key_callback(window, function(window, key, scancode, action)
   if key == 'escape' and action == 'press' then
      glfw.set_window_should_close(window, true)
   elseif key == 'f11' and action == 'press' then
      toggle_fullscreen()
   else
      keys[key] = action ~= 'release'
   end
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
   space:step(fdt, n)
   grabber:step(fdt, n)

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


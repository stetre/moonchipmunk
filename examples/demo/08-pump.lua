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
local clamp = glmath.clamp
local identity = cp.transform_identity()

-- Initializations ------------------------------------------------------------

local TITLE = "Pump"
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

local num_balls = 5

local function add_ball(space, pos)
   local pos = vec2(pos[1], pos[2])
   local body = space:add_body(cp.body_new(1.0, cp.moment_for_circle(1.0, 30, 0, {0, 0})))
   body:set_position(pos)
   local shape = space:add_shape(cp.circle_shape_new(body, 30, {0, 0}))
   shape:set_elasticity(0.0)
   shape:set_friction(0.5)
   return body
end

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
local filter_none = {group=0, categories=0, mask=0 }
space:set_gravity({0, -600})
local static_body = space:get_static_body()
-- beveling all of the line segments slightly helps prevent things from getting stuck on cracks
local shape = space:add_shape(cp.segment_shape_new(static_body, {-256,16}, {-256,300}, 2.0))
shape:set_elasticity(0.0)
shape:set_friction(0.5)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-256,16}, {-192,0}, 2.0))
shape:set_elasticity(0.0)
shape:set_friction(0.5)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-192,0}, {-192, -64}, 2.0))
shape:set_elasticity(0.0)
shape:set_friction(0.5)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-128,-64}, {-128,144}, 2.0))
shape:set_elasticity(0.0)
shape:set_friction(0.5)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-192,80}, {-192,176}, 2.0))
shape:set_elasticity(0.0)
shape:set_friction(0.5)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-192,176}, {-128,240}, 2.0))
shape:set_elasticity(0.0)
shape:set_friction(0.5)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-128,144}, {192,64}, 2.0))
shape:set_elasticity(0.0)
shape:set_friction(0.5)
shape:set_filter(not_grabbable)
local verts = {{-30,-80}, {-30, 80}, { 30, 64}, { 30,-80}}
local plunger = space:add_body(cp.body_new(1.0, infinity))
plunger:set_position({-160,-80})
local shape = space:add_shape(cp.poly_shape_new(plunger, verts, 0.0, identity))
shape:set_elasticity(1.0)
shape:set_friction(0.5)
shape:set_filter({group=0, categories=1, mask=1})
-- add balls to hopper
local balls = {}
for i=0, num_balls-1 do
   table.insert(balls, add_ball(space, {-224 + i,80 + 64*i}))
end
-- add small gear
local small_gear = space:add_body(cp.body_new(10.0, cp.moment_for_circle(10.0, 80, 0, {0, 0})))
small_gear:set_position({-160,-160})
small_gear:set_angle(-pi/2.0)
local shape = space:add_shape(cp.circle_shape_new(small_gear, 80.0, {0, 0}))
shape:set_filter(cp.shape_filter_none())
space:add_constraint(cp.pivot_joint_new(static_body, small_gear, {-160,-160}, {0, 0}))
-- add big gear
local big_gear = space:add_body(cp.body_new(40.0, cp.moment_for_circle(40.0, 160, 0, {0, 0})))
big_gear:set_position({80,-160})
big_gear:set_angle(pi/2.0)
local shape = space:add_shape(cp.circle_shape_new(big_gear, 160.0, {0, 0}))
shape:set_filter(cp.shape_filter_none())
space:add_constraint(cp.pivot_joint_new(static_body, big_gear, {80,-160}, {0, 0}))
-- connect the plunger to the small gear.
space:add_constraint(cp.pin_joint_new(small_gear, plunger, {80,0}, {0,0}))
-- connect the gears.
space:add_constraint(cp.gear_joint_new(small_gear, big_gear, -pi/2.0, -2.0))
-- feeder mechanism
local bottom, top = -300.0, 32.0
local feeder = space:add_body(cp.body_new(1.0,
cp.moment_for_segment(1.0, {-224.0, bottom}, {-224.0, top}, 0.0)))
feeder:set_position({-224, (bottom + top)/2.0})
local len = top - bottom
local shape = space:add_shape(cp.segment_shape_new(feeder, {0.0, len/2.0}, {0.0, -len/2.0}, 20.0))
shape:set_filter(grabbable)
space:add_constraint(cp.pivot_joint_new(static_body, feeder, {-224.0, bottom}, {0.0, -len/2.0}))
local anchor = feeder:world_to_local({-224.0, -160.0})
space:add_constraint(cp.pin_joint_new(feeder, small_gear, anchor, {0.0, 80.0}))
-- motorize the second gear
motor = space:add_constraint(cp.simple_motor_new(static_body, big_gear, 3.0))

-- Input handling -------------------------------------------------------------

local toggle_fullscreen = toolbox.toggle_fullscreen(window)
local keys = {} -- keys[k] = true if key k is pressed

local key_x, key_y = 0, 0
local function control_machine(key, action)
   if action == 'repeat' then return end
   if     key == 'up'    then key_y = key_y + ((action=='press') and  1 or -1)
   elseif key == 'down'  then key_y = key_y + ((action=='press') and -1 or  1)
   elseif key == 'left'  then key_x = key_x + ((action=='press') and -1 or  1)
   elseif key == 'right' then key_x = key_x + ((action=='press') and  1 or -1)
   end
end

glfw.set_key_callback(window, function(window, key, scancode, action)
   if key == 'escape' and action == 'press' then
      glfw.set_window_should_close(window, true)
   elseif key == 'f11' and action == 'press' then toggle_fullscreen()
   else
      keys[key] = action ~= 'release'
   end
   control_machine(key, action)
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
local fdt = 1/120 -- fixed dt for physics updates
local n_physics_updates = toolbox.fixed_dt_counter(fdt)
local n, dt

local renderer = toolbox.renderer(space)

collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(spf)
   dt = timer:update() -- duration of the current frame
   n = n_physics_updates(dt) -- no. of physics updates to do in this frame

   local coef = (2.0 + key_y)/3.0
   local rate = key_x*30.0*coef

   for i=1, n do
      motor:set_rate(rate)
      motor:set_max_force(rate==0.0 and 0.0 or 1000000.0)
      space:step(fdt)
      grabber:step(fdt)
      for _, ball in ipairs(balls) do
         local pos = ball: get_position()
         if pos.x > 320.0 then
            ball:set_velocity({0, 0})
            ball:set_position({-224.0, 200.0})
         end
      end
   end

   glfw.set_window_title(window, fmt("%s - fps=%.0f, n=%d", TITLE, timer:fps(), n))
   gl.clear_color(BG_COLOR)
   gl.clear('color')
   renderer:begin()
   space:debug_draw()
   renderer:done()

   font:draw("Use the arrow keys to control the machine.", .05, .9, FONT_SIZE, FONT_COLOR)

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


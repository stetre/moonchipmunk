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

local TITLE = "Theo Jansen Machine"
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
-- Rfr: http://en.wikipedia.org/wiki/Theo_Jansen

local seg_radius = 3.0
local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(20)
space:set_gravity({0,-500})
local static_body = space:get_static_body(space)


local function make_leg(space, side, offset, chassis, crank, anchor)
   local leg_mass = 1.0
   -- make leg
   local a, b = {0,0}, {0.0, side}
   local upper_leg = cp.body_new(leg_mass, cp.moment_for_segment(leg_mass, a, b, 0.0))
   space:add_body(upper_leg)
   upper_leg:set_position({offset, 0.0})
   local shape = space:add_shape(cp.segment_shape_new(upper_leg, a, b, seg_radius))
   shape:set_filter({group=1, categories=-1, mask=-1})
   space:add_constraint(cp.pivot_joint_new(chassis, upper_leg, {offset, 0.0}, {0,0}))
   -- lower leg
   local a, b = {0,0}, {0.0, -1.0*side}
   local lower_leg = cp.body_new(leg_mass, cp.moment_for_segment(leg_mass, a, b, 0.0))
   space:add_body(lower_leg)
   lower_leg:set_position({offset, -side})
   local shape = space:add_shape(cp.segment_shape_new(lower_leg, a, b, seg_radius))
   shape:set_filter({group=1, categories=-1, mask=-1})
   local shape = space:add_shape(cp.circle_shape_new(lower_leg, seg_radius*2.0, b))
   shape:set_filter({group=1, categories=-1, mask=-1})
   shape:set_elasticity(0.0)
   shape:set_friction(1.0)
   space:add_constraint(cp.pin_joint_new(chassis, lower_leg, {offset, 0.0}, {0,0}))
   space:add_constraint(cp.gear_joint_new(upper_leg, lower_leg, 0.0, 1.0))
   local diag = math.sqrt(side*side + offset*offset)
   local constraint = space:add_constraint(cp.pin_joint_new(crank, upper_leg, anchor, {0.0, side}))
   constraint:set_dist(diag)
   local constraint = space:add_constraint(cp.pin_joint_new(crank, lower_leg, anchor, {0,0}))
   constraint:set_dist(diag)
end

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
local offset = 30.0
-- make chassis
local chassis_mass = 2.0
local a, b = {-offset, 0.0}, {offset, 0.0}
local chassis = cp.body_new(chassis_mass, cp.moment_for_segment(chassis_mass, a, b, 0.0))
space:add_body(chassis)
local shape = space:add_shape(cp.segment_shape_new(chassis, a, b, seg_radius))
shape:set_filter({group=1, categories=-1, mask=-1})
-- make crank
local crank_mass, crank_radius = 1.0,13.0
local crank = cp.body_new(crank_mass, cp.moment_for_circle(crank_mass, crank_radius, 0.0, {0,0}))
space:add_body(crank)
local shape = space:add_shape(cp.circle_shape_new(crank, crank_radius, {0,0}))
shape:set_filter({group=1, categories=-1, mask=-1})
space:add_constraint(cp.pivot_joint_new(chassis, crank, {0,0}, {0,0}))
local side = 30.0
local num_legs = 2
for i=0, num_legs do
   local anchor = cp.vforangle((2*i+0)/num_legs*pi) * crank_radius
   make_leg(space, side,  offset, chassis, crank, anchor)
   local anchor = cp.vforangle((2*i+1)/num_legs*pi) * crank_radius
   make_leg(space, side, -offset, chassis, crank, anchor)
end
local motor = space:add_constraint(cp.simple_motor_new(chassis, crank, 6.0))

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
   elseif key == 'f11' and action == 'press' then
      toggle_fullscreen()
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

   local coef = (2.0 + key_y)/3.0
   local rate = key_x*10.0*coef
   motor:set_rate(rate)
   motor:set_max_force(rate==0.0 and 0.0 or 100000.0)
   space:step(fdt, n)
   grabber:step(fdt, n)

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


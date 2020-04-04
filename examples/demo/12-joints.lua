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

local TITLE = "Joints and Constraints"
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

local function add_ball(space, pos, boxOffset)
   local radius, mass = 15.0, 1.0
   local body = space:add_body(cp.body_new(mass, cp.moment_for_circle(mass, 0.0, radius, {0, 0})))
   body:set_position(pos+boxOffset)
   local shape = space:add_shape(cp.circle_shape_new(body, radius, {0, 0}))
   shape:set_elasticity(0.0)
   shape:set_friction(0.7)
   return body
end

local function add_lever(space, pos, boxOffset)
   local mass = 1.0
   local a, b = vec2(0,  15), vec2(0, -15)
   local body = space:add_body(cp.body_new(mass, cp.moment_for_segment(mass, a, b, 0.0)))
   body:set_position(pos + boxOffset + vec2(0, -15))
   local shape = space:add_shape(cp.segment_shape_new(body, a, b, 5.0))
   shape:set_elasticity(0.0)
   shape:set_friction(0.7)
   return body
end

local function add_bar(space, pos, boxOffset)
   local mass = 2.0
   local a, b = {0,  30}, {0, -30}
   local body = space:add_body(cp.body_new(mass, cp.moment_for_segment(mass, a, b, 0.0)))
   body:set_position(pos + boxOffset)
   local shape = space:add_shape(cp.segment_shape_new(body, a, b, 5.0))
   shape:set_elasticity(0.0)
   shape:set_friction(0.7)
   shape:set_filter(cp.shape_filter_new(1, cp.ALL_CATEGORIES, cp.ALL_CATEGORIES))
   return body
end

local function add_wheel(space, pos, boxOffset)
   local radius, mass = 15.0, 1.0
   local body = space:add_body(cp.body_new(mass, cp.moment_for_circle(mass, 0.0, radius, {0, 0})))
   body:set_position(pos + boxOffset)
   local shape = space:add_shape(cp.circle_shape_new(body, radius, {0, 0}))
   shape:set_elasticity(0.0)
   shape:set_friction(0.7)
   shape:set_filter(cp.shape_filter_new(1, cp.ALL_CATEGORIES, cp.ALL_CATEGORIES))
   return body
end

local function add_chassis(space, pos, boxOffset)
   local mass, width, height = 5.0, 80, 30
   local body = space:add_body(cp.body_new(mass, cp.moment_for_box(mass, width, height)))
   body:set_position(pos + boxOffset)
   local shape = space:add_shape(cp.box_shape_new(body, width, height, 0.0))
   shape:set_elasticity(0.0)
   shape:set_friction(0.7)
   shape:set_filter(cp.shape_filter_new(1, cp.ALL_CATEGORIES, cp.ALL_CATEGORIES))
   return body
end

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(10)
space:set_gravity({0, -100})
space:set_sleep_time_threshold(0.5)
local static_body = space:get_static_body()
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,240}, {320,240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,120}, {320,120}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,0}, {320,0}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,-120}, {320,-120}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,-240}, {320,-240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,-240}, {-320,240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-160,-240}, {-160,240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {0,-240}, {0,240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {160,-240}, {160,240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {320,-240}, {320,240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local posA, posB = vec2(50, 60), vec2(110, 60)
-- Pin Joints - Link shapes with a solid bar or pin.
-- Keeps the anchor points the same distance apart from when the joint was created.
local boxOffset = vec2(-320, -240)
local body1 = add_ball(space, posA, boxOffset)
local body2 = add_ball(space, posB, boxOffset)
space:add_constraint(cp.pin_joint_new(body1, body2, {15,0}, {-15,0}))
-- Slide Joints - Like pin joints but with a min/max distance.
-- Can be used for a cheap approximation of a rope.
local boxOffset = vec2(-160, -240)
local body1 = add_ball(space, posA, boxOffset)
local body2 = add_ball(space, posB, boxOffset)
space:add_constraint(cp.slide_joint_new(body1, body2, {15,0}, {-15,0}, 20.0, 40.0))
-- Pivot Joints - Holds the two anchor points together. Like a swivel.
local boxOffset = vec2(0, -240)
local body1 = add_ball(space, posA, boxOffset)
local body2 = add_ball(space, posB, boxOffset)
space:add_constraint(cp.pivot_joint_new(body1, body2, boxOffset + vec2(80,60)))
-- cp.pivot_joint_new() takes it's anchor parameter in world coordinates and calculates
-- the anchor, or, alternatively, it lets you specify the two anchor points explicitly
-- Groove Joints - Like a pivot joint, but one of the anchors is a line segment that
-- the pivot can slide in
local boxOffset = vec2(160, -240)
local body1 = add_ball(space, posA, boxOffset)
local body2 = add_ball(space, posB, boxOffset)
space:add_constraint(cp.groove_joint_new(body1, body2, {30,30}, {30,-30}, {-30,0}))
-- Damped Springs
local boxOffset = vec2(-320, -120)
local body1 = add_ball(space, posA, boxOffset)
local body2 = add_ball(space, posB, boxOffset)
space:add_constraint(cp.damped_spring_new(body1, body2, {15,0}, {-15,0}, 20.0, 5.0, 0.3))
-- Damped Rotary Springs
local boxOffset = vec2(-160, -120)
local body1 = add_bar(space, posA, boxOffset)
local body2 = add_bar(space, posB, boxOffset)
-- Add some pin joints to hold the circles in place.
space:add_constraint(cp.pivot_joint_new(body1, static_body, posA+boxOffset))
space:add_constraint(cp.pivot_joint_new(body2, static_body, posB+boxOffset))
space:add_constraint(cp.damped_rotary_spring_new(body1, body2, 0.0, 3000.0, 60.0))
-- Rotary Limit Joint
local boxOffset = vec2(0, -120)
local body1 = add_lever(space, posA, boxOffset)
local body2 = add_lever(space, posB, boxOffset)
-- Add some pin joints to hold the circles in place.
space:add_constraint(cp.pivot_joint_new(body1, static_body, posA+boxOffset))
space:add_constraint(cp.pivot_joint_new(body2, static_body, posB+boxOffset))
-- Hold their rotation within 90 degrees of each other.
space:add_constraint(cp.rotary_limit_joint_new(body1, body2, -pi/2.0, pi/2.0))
-- Ratchet Joint - A rotary ratchet, like a socket wrench
local boxOffset = vec2(160, -120)
local body1 = add_lever(space, posA, boxOffset)
local body2 = add_lever(space, posB, boxOffset)
-- Add some pin joints to hold the circles in place.
space:add_constraint(cp.pivot_joint_new(body1, static_body, posA+boxOffset))
space:add_constraint(cp.pivot_joint_new(body2, static_body, posB+boxOffset))
-- Ratchet every 90 degrees
space:add_constraint(cp.ratchet_joint_new(body1, body2, 0.0, pi/2.0))
-- Gear Joint - Maintain a specific angular velocity ratio
local boxOffset = vec2(-320, 0)
local body1 = add_bar(space, posA, boxOffset)
local body2 = add_bar(space, posB, boxOffset)
-- Add some pin joints to hold the circles in place.
space:add_constraint(cp.pivot_joint_new(body1, static_body, posA+boxOffset))
space:add_constraint(cp.pivot_joint_new(body2, static_body, posB+boxOffset))
-- Force one to sping 2x as fast as the other
space:add_constraint(cp.gear_joint_new(body1, body2, 0.0, 2.0))
-- Simple Motor - Maintain a specific angular relative velocity
local boxOffset = vec2(-160, 0)
local body1 = add_bar(space, posA, boxOffset)
local body2 = add_bar(space, posB, boxOffset)
-- Add some pin joints to hold the circles in place.
space:add_constraint(cp.pivot_joint_new(body1, static_body, posA+boxOffset))
space:add_constraint(cp.pivot_joint_new(body2, static_body, posB+boxOffset))
-- Make them spin at 1/2 revolution per second in relation to each other.
space:add_constraint(cp.simple_motor_new(body1, body2, pi))
-- Make a car with some nice soft suspension
local boxOffset = vec2(0, 0)
local wheel1 = add_wheel(space, posA, boxOffset)
local wheel2 = add_wheel(space, posB, boxOffset)
local chassis = add_chassis(space, vec2(80, 100), boxOffset)
space:add_constraint(cp.groove_joint_new(chassis, wheel1, {-30, -10}, {-30, -40}, {0, 0}))
space:add_constraint(cp.groove_joint_new(chassis, wheel2, { 30, -10}, { 30, -40}, {0, 0}))
space:add_constraint(cp.damped_spring_new(chassis, wheel1,{-30, 0},{0, 0}, 50.0, 20.0, 10.0))
space:add_constraint(cp.damped_spring_new(chassis, wheel2,{ 30, 0},{0, 0}, 50.0, 20.0, 10.0))

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
local fdt = 1/60 -- fixed dt for physics updates
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

   --font:draw("" .05, .9, FONT_SIZE, FONT_COLOR)

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


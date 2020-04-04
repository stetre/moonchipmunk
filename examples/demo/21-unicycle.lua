#!/usr/bin/env lua
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local cp = require("moonchipmunk")
local toolbox = require("moonchipmunk.toolbox")

cp.glmath_compat(true)
local pi, infinity = math.pi, math.huge
local sin, cos, asin = math.sin, math.cos, math.asin
local abs, exp, sqrt = math.abs, math.exp, math.sqrt
local fmt = string.format
local vec2, box2 = glmath.vec2, glmath.box2
local clamp, mix = glmath.clamp, glmath.mix
local identity = cp.transform_identity()

-- Initializations ------------------------------------------------------------

local TITLE = "Unicycle"
local FW, FH = 640, 480 -- width and height of the field
local W, H = 1024, 768 -- window width and height
local BG_COLOR = {0x07/255, 0x36/255, 0x42/255, 1.0}
local FONT_COLOR, FONT_SIZE = {0xfd/250, 0xf6/250, 0xe3/250, 1.0}, 12/H
local RED = {1, 0, 0, 1}

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

local balance_sin = 0.0
local max_v = 500.0
local max_rate = 50.0
local max_sin = sin(0.6)
local target_x

-- TODO: - Clamp max angle dynamically based on output torque.

--local function bias_coef(errorBias, dt) return 1.0 - errorBias^dt end
local function bias_coef(errorBias, dt) return 1.0 - math.pow(errorBias, dt) end

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(30)
space:set_gravity({0, -500})
local static_body = space:get_static_body()
local shape = space:add_shape(cp.segment_shape_new(static_body, {-3200,-240}, {3200,-240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {0,-200}, {240,-240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-240,-240}, {0,-200}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local radius, mass = 20.0, 1.0
local moment = cp.moment_for_circle(mass, 0.0, radius, {0, 0})
local wheel_body = space:add_body(cp.body_new(mass, moment))
wheel_body:set_position({0.0, -160.0 + radius})
local shape = space:add_shape(cp.circle_shape_new(wheel_body, radius, {0, 0}))
shape:set_friction(0.7)
shape:set_filter(cp.shape_filter_new(1, cp.ALL_CATEGORIES, cp.ALL_CATEGORIES))
local cog_offset = 30.0
local bb1 = box2(-5.0, 5.0, 0.0 - cog_offset, cog_offset*1.2 - cog_offset)
local bb2 = box2(-25.0, 25.0, bb1.maxy, bb1.maxy + 10.0)
local mass = 3.0
local moment = cp.moment_for_box(mass, bb1) + cp.moment_for_box(mass, bb2)
local balance_body = space:add_body(cp.body_new(mass, moment))
balance_body:set_position({0.0, wheel_body:get_position().y + cog_offset})
local shape = space:add_shape(cp.box_shape_new(balance_body, bb1, 0.0))
shape:set_friction(1.0)
shape:set_filter(cp.shape_filter_new(1, cp.ALL_CATEGORIES, cp.ALL_CATEGORIES))
local shape = space:add_shape(cp.box_shape_new(balance_body, bb2, 0.0))
shape:set_friction(1.0)
shape:set_filter(cp.shape_filter_new(1, cp.ALL_CATEGORIES, cp.ALL_CATEGORIES))
local anchorA = balance_body:world_to_local(wheel_body:get_position())
local groove_a = anchorA + vec2(0.0,  30.0)
local groove_b = anchorA + vec2(0.0, -10.0)
space:add_constraint(cp.groove_joint_new(balance_body, wheel_body, groove_a, groove_b, {0, 0}))
space:add_constraint(cp.damped_spring_new(balance_body, wheel_body, anchorA, {0, 0}, 0.0, 6.0e2, 30.0))
local motor = space:add_constraint(cp.simple_motor_new(wheel_body, balance_body, 0.0))

motor:set_pre_solve_func(function(motor, space)
   local dt = space:get_current_time_step()
   target_x = grabber:get_pos().x
   local target_v = clamp(bias_coef(0.5, dt/1.2)*(target_x - balance_body:get_position().x)/dt, -max_v, max_v)
   local error_v = (target_v - balance_body:get_velocity().x)
   local target_sin = 3.0e-3*bias_coef(0.1, dt)*error_v/dt
   balance_sin = clamp(balance_sin - 6.0e-5*bias_coef(0.2, dt)*error_v/dt, -max_sin, max_sin)
   local target_a = asin(clamp(-target_sin + balance_sin, -max_sin, max_sin))
   local angular_diff = asin(cp.vcross(balance_body:get_rotation(), cp.vforangle(target_a)))
   local target_w = bias_coef(0.1, dt/0.4)*(angular_diff)/dt
   local rate = wheel_body:get_angular_velocity() + balance_body:get_angular_velocity() - target_w
   motor:set_rate(clamp(rate, -max_rate, max_rate))
   motor:set_max_force(8.0e4)
end)

local width, height, mass = 100.0, 20.0, 3.0
local boxBody = space:add_body(cp.body_new(mass, cp.moment_for_box(mass, width, height)))
boxBody:set_position({200, -100})
local shape = space:add_shape(cp.box_shape_new(boxBody, width, height, 0.0))
shape:set_friction(0.7)

-- Input handling -------------------------------------------------------------

local toggle_fullscreen = toolbox.toggle_fullscreen(window)
local keys = {} -- keys[k] = true if key k is pressed
local right_click = false

glfw.set_key_callback(window, function(window, key, scancode, action)
   if key == 'escape' and action == 'press' then glfw.set_window_should_close(window, true)
   elseif key == 'f11' and action == 'press' then toggle_fullscreen()
   else
      keys[key] = action ~= 'release'
   end
end)

glfw.set_cursor_pos_callback(window, function(window, x, y)
   grabber:cursor_pos_callback(x, y)
end)

glfw.set_mouse_button_callback(window, function(window, button, action, shift, control, alt, super)
   grabber:mouse_button_callback(button, action, shift, control, alt, super)
   if button == 'right' then right_click = action ~= 'release' end
end)

-- Game loop ------------------------------------------------------------------
local timer = toolbox.frame_timer()
local spf = 1/60 -- 1 / desired fps
local fdt = 1/60 -- fixed dt for physics updates
local n_physics_updates = toolbox.fixed_dt_counter(fdt)
local n, dt

local renderer = toolbox.renderer(space)

local message1 = "This unicycle is completely driven and balanced by a single simple_motor."
local message2 = "Move the mouse to make the unicycle follow it."
local LH = FONT_SIZE*1.4

-- position the mouse at the center of the window:
glfw.set_cursor_pos(window, W/2, H/2)

collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(spf)
   dt = timer:update() -- duration of the current frame
   n = n_physics_updates(dt) -- no. of physics updates to do in this frame

   glfw.set_window_title(window, fmt("%s - fps=%.0f, n=%d", TITLE, timer:fps(), n))
   gl.clear_color(BG_COLOR)
   gl.clear('color')

   renderer:begin()
   space:step(fdt, n)
   grabber:step(fdt, n)
   renderer:draw_segment({target_x, -1000.0}, {target_x, 1000.0}, RED)
   space:debug_draw()
   renderer:done()

   font:draw(message1, .05, .9, FONT_SIZE, FONT_COLOR)
   font:draw(message2, .05, .9+LH, FONT_SIZE, FONT_COLOR)
   
   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


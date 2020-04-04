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

local TITLE = "Tank"
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

math.randomseed(os.time())

local function add_box(space, size, mass)
   local radius = vec2(size, size):norm()
   local body = space:add_body(cp.body_new(mass, cp.moment_for_box(mass, size, size)))
   local pos = {math.random()*(640-2*radius)-(320-radius), math.random()*(480-2*radius)-(240-radius)}
   body:set_position(pos)
   local shape = space:add_shape(cp.box_shape_new(body, size, size, 0.0))
   shape:set_elasticity(0.0)
   shape:set_friction(0.7)
   return body
end

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(10)
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
for i= 0, 50 do
   local body = add_box(space, 20, 1)
   local pivot = space:add_constraint(cp.pivot_joint_new(static_body, body, {0, 0}, {0, 0}))
   pivot:set_max_bias(0) -- disable joint correction
   pivot:set_max_force(1000.0) -- emulate linear friction
   local gear = space:add_constraint(cp.gear_joint_new(static_body, body, 0.0, 1.0))
   gear:set_max_bias(0) -- disable joint correction
   gear:set_max_force(5000.0) -- emulate angular friction
end
-- We joint the tank to the control body and control the tank indirectly by modifying the control body.
local tankControlBody = space:add_body(cp.body_new_kinematic())
local tankBody = add_box(space, 30, 10)
local pivot = space:add_constraint(cp.pivot_joint_new(tankControlBody, tankBody, {0, 0}, {0, 0}))
pivot:set_max_bias(0) -- disable joint correction
pivot:set_max_force(10000.0) -- emulate linear friction
local gear = space:add_constraint(cp.gear_joint_new(tankControlBody, tankBody, 0.0, 1.0))
gear:set_error_bias(0) -- attempt to fully correct the joint each step
gear:set_max_bias(1.2)  -- but limit it's angular correction rate
gear:set_max_force(50000.0) -- emulate angular friction

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
local message = "Use the mouse to drive the tank, it will follow the cursor."

collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(spf)
   dt = timer:update() -- duration of the current frame
   n = n_physics_updates(dt) -- no. of physics updates to do in this frame
   space:step(fdt, n)
   grabber:step(fdt, n)

   local mouse_pos = grabber:get_pos()
   -- turn the control body based on the angle relative to the actual body
   local mouseDelta = mouse_pos - tankBody:get_position()
   local turn = cp.vtoangle(cp.vunrotate(tankBody:get_rotation(), mouseDelta))
   tankControlBody:set_angle(tankBody:get_angle() - turn)
   -- drive the tank towards the mouse
   if cp.vnear(mouse_pos, tankBody:get_position(), 30.0) then
      tankControlBody:set_velocity({0, 0}) -- stop
   else
      local direction = mouseDelta*tankBody:get_rotation() > 0.0 and 1.0 or -1.0
      tankControlBody:set_velocity(cp.vrotate(tankBody:get_rotation(), {30.0*direction, 0.0}))
   end

   glfw.set_window_title(window, fmt("%s - fps=%.0f, n=%d", TITLE, timer:fps(), n))
   gl.clear_color(BG_COLOR)
   gl.clear('color')

   renderer:begin()
   space:debug_draw()
   renderer:done()

   font:draw(message, .05, .9, FONT_SIZE, FONT_COLOR)

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


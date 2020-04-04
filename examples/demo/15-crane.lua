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

local TITLE = "Crane"
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

-- Collision types:
local HOOK_SENSOR=1
local CRATE=2

local hookJoint = false -- Temporary joint used to hold the hook to the load.
local function hook_crate(arbiter, space)
   if not hookJoint then
      -- Get the two bodies in the collision pair and define local variables for them.
      -- Their order matches the order of the collision types passed to the collision handler
      -- this function was defined for
      local hook, crate = arbiter:get_bodies()
      -- additions and removals can't be done in a normal callback.
      -- Schedule a post step callback to do it.
      -- Use the hook as the key and pass along the arbiter.
      space:add_post_step_callback(function(space) -- attach hook
         hookJoint = space:add_constraint(cp.pivot_joint_new(hook, crate, hook:get_position()))
      end)
   end
   return true -- return value is ignored for sensor callbacks anyway
end

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(30)
space:set_gravity({0, -100})
space:set_damping(0.8)
local static_body = space:get_static_body()
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,-240}, {320,-240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
-- Add a body for the dolly.
local dollyBody = space:add_body(cp.body_new(10, infinity))
dollyBody:set_position({0, 100})
-- Add a block so you can see it.
space:add_shape(cp.box_shape_new(dollyBody, 30, 30, 0.0))
-- Add a groove joint for it to move back and forth on.
space:add_constraint(cp.groove_joint_new(static_body, dollyBody, {-250, 100}, {250, 100}, {0, 0}))
-- Add a pivot joint to act as a servo motor controlling it's position
-- By updating the anchor points of the pivot joint, you can move the dolly.
local dollyServo = cp.pivot_joint_new(static_body, dollyBody, dollyBody:get_position())
space:add_constraint(dollyServo)
-- Max force the dolly servo can generate.
dollyServo:set_max_force(10000)
-- Max speed of the dolly servo
dollyServo:set_max_bias(100)
-- You can also change the error bias to control how it slows down.
--dollyServo:set_error_bias(0.2)
-- Add the crane hook.
local hookBody = space:add_body(cp.body_new(1, infinity))
hookBody:set_position({0, 50})
-- Add a sensor shape for it. This will be used to figure out when the hook touches a box.
local shape = space:add_shape(cp.circle_shape_new(hookBody, 10, {0, 0}))
shape:set_sensor(true)
shape:set_collision_type(HOOK_SENSOR)
-- Add a slide joint to act as a winch motor
-- By updating the max length of the joint you can make it pull up the load.
local winchServo = cp.slide_joint_new(dollyBody, hookBody, {0, 0}, {0, 0}, 0, infinity)
space:add_constraint(winchServo)
-- Max force the dolly servo can generate.
winchServo:set_max_force(30000)
-- Max speed of the dolly servo
winchServo:set_max_bias(60)
-- Finally a box to play with
local boxBody = space:add_body(cp.body_new(30, cp.moment_for_box(30, 50, 50)))
boxBody:set_position({200, -200})
-- Add a block so you can see it.
local shape = space:add_shape(cp.box_shape_new(boxBody, 50, 50, 0.0))
shape:set_friction(0.7)
shape:set_collision_type(CRATE)
local handler = space:add_collision_handler(HOOK_SENSOR, CRATE)
handler:set_begin_func(hook_crate)


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
   if button == 'right' then right_click = (action ~= 'release') end
   grabber:mouse_button_callback(button, action, shift, control, alt, super)
end)

-- Game loop ------------------------------------------------------------------
local timer = toolbox.frame_timer()
local spf = 1/60 -- 1 / desired fps
local fdt = 1/60 -- fixed dt for physics updates
local n_physics_updates = toolbox.fixed_dt_counter(fdt)
local n, dt

local message = "Control the crane by moving the mouse. Right click to release."
local renderer = toolbox.renderer(space)

collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(spf)
   dt = timer:update() -- duration of the current frame
   n = n_physics_updates(dt) -- no. of physics updates to do in this frame

   local mouse_pos = grabber:get_pos()
   -- Set the first anchor point (the one attached to the static body) of the
   -- dolly servo to the mouse's x position.
   dollyServo:set_anchor_a({mouse_pos.x, 100})
   -- Set the max length of the winch servo to match the mouse's height.
   winchServo:set_max(math.max(100 - mouse_pos.y, 50))
   if hookJoint and right_click then
      space:remove_constraint(hookJoint)
      hookJoint:free()
      hookJoint = false
   end

   space:step(fdt, n)
   grabber:step(fdt, n)

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


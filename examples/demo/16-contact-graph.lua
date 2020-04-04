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

local TITLE = "Contact Graph"
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

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(30)
space:set_gravity({0, -300})
space:set_collision_slop(0.5)
space:set_sleep_time_threshold(1.0)
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
local scale_static_body = space:add_body(cp.body_new_static())
local shape = space:add_shape(cp.segment_shape_new(scale_static_body, {-240,-180}, {-140,-180}, 4.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
-- add some boxes to stack on the scale
for i=0, 4 do
   local body = space:add_body(cp.body_new(1.0, cp.moment_for_box(1.0, 30.0, 30.0)))
   body:set_position({0, i*32 - 220})
   local shape = space:add_shape(cp.box_shape_new(body, 30.0, 30.0, 0.0))
   shape:set_elasticity(0.0)
   shape:set_friction(0.8)
end
-- Add a ball that we'll track which objects are beneath it.
local radius = 15.0
local ball_body = space:add_body(cp.body_new(10.0, cp.moment_for_circle(10.0, 0.0, radius, {0, 0})))
ball_body:set_position({120, -240 + radius+5})
local shape = space:add_shape(cp.circle_shape_new(ball_body, radius, {0, 0}))
shape:set_elasticity(0.0)
shape:set_friction(0.9)


-- Input handling -------------------------------------------------------------

local toggle_fullscreen = toolbox.toggle_fullscreen(window)
local keys = {} -- keys[k] = true if key k is pressed

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
end)

-- Game loop ------------------------------------------------------------------
local timer = toolbox.frame_timer()
local spf = 1/60 -- 1 / desired fps
local fdt = 1/60 -- fixed dt for physics updates
local n_physics_updates = toolbox.fixed_dt_counter(fdt)
local n, dt

local renderer = toolbox.renderer(space)


local message = {}
collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(spf)
   dt = timer:update() -- duration of the current frame
   n = n_physics_updates(dt) -- no. of physics updates to do in this frame

   space:step(fdt, n)
   grabber:step(fdt, n)

   message[1] = "Place objects on the scale to weigh them. The ball marks the shapes it's sitting on."
   -- Sum the total impulse applied to the scale from all collision pairs in the contact graph.
   local impulseSum = vec2(0, 0)
   scale_static_body:each_arbiter(function(body, arbiter)
      impulseSum = impulseSum + arbiter:total_impulse()
   end)
   
   local force = impulseSum:norm()/fdt -- force is the impulse divided by the timestep.
   -- Weight can be found similarly from the gravity vector.
   local g = space:get_gravity()
   local weight = (g*impulseSum)/(g:norm2()*fdt)
   -- Highlight and count the number of shapes the ball is touching.
   local count = 0
   ball_body:each_arbiter(function(body, arbiter)
      -- body is the body we are iterating the arbiters for (i.e. ball_body).
      -- arbiter:get_bodies/get_shapes() in an arbiter iterator always returns the
      -- body/shape for the iterated body first.
      local ball, other = arbiter:get_shapes()
      renderer:draw_box(other:get_bb(), RED)
      count = count + 1
   end)
   message[2] = fmt("Total force: %5.2f, Total weight: %5.2f. The ball is touching %d shapes.",
               force, weight, count)

   local magnitude_sum=0.0
   local vector_sum = vec2(0, 0)
   ball_body:each_arbiter(function(body, arbiter) -- estimate crushing
      local j = arbiter:total_impulse()
      magnitude_sum = magnitude_sum + j:norm()
      vector_sum = vector_sum + j
   end)
   local crush_force = (magnitude_sum - vector_sum:norm())*fdt
   if crush_force > 10.0 then
      message[3] = fmt("The ball is being crushed. (f: %.2f)", crush_force)
   else
      message[3] = fmt("The ball is not being crushed. (f: %.2f)", crush_force)
   end

   glfw.set_window_title(window, fmt("%s - fps=%.0f, n=%d", TITLE, timer:fps(), n))
   gl.clear_color(BG_COLOR)
   gl.clear('color')

   renderer:begin()
   space:debug_draw()
   renderer:done()

   local line_height = FONT_SIZE*1.4
   font:draw(message[1], .05, .9, FONT_SIZE, FONT_COLOR)
   font:draw(message[2], .05, .9+line_height, FONT_SIZE, FONT_COLOR)
   font:draw(message[3], .05, .9+2*line_height, FONT_SIZE, FONT_COLOR)

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


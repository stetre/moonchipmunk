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
local identity = cp.transform_identity()

-- Initializations ------------------------------------------------------------

local TITLE = "Planet"
local FW, FH = 640, 480 -- width and height of the field
local W, H = 1024, 768 -- window width and height
local BG_COLOR = {0x07/255, 0x36/255, 0x42/255, 1.0}

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

-- Demo inits -----------------------------------------------------------------

local gravity_strength = 5.0e6

local function planet_gravity_velocity_func(body, gravity, damping, dt)
   -- Gravitational acceleration is proportional to the inverse square of
   -- distance, and directed toward the origin. The central planet is assumed
   -- to be massive enough that it affects the satellites but not vice versa.
   local pos = body:get_position()
   local r = pos:norm()
   local g = (-gravity_strength/(r^3))*pos
   body:update_velocity(g, damping, dt)
end

local function rand_pos(radius)
   while true do
      local v = vec2(math.random()*(FW-2*radius)-(FW/2-radius), math.random()*(FH-2*radius)-(FH/2-radius))
      if v:norm() >= 85.0 then return v end
   end
end

local function add_box(space)
   local size, mass = 10.0, 1.0
   local verts = {{-size,-size}, {-size, size}, { size, size}, { size,-size}}
   local radius = vec2(size, size):norm()
   local pos = rand_pos(radius)
   local body = cp.body_new(mass, cp.moment_for_poly(mass, verts, {0, 0}, 0.0))
   space:add_body(body)
   body:set_velocity_update_func(planet_gravity_velocity_func)
   body:set_position(pos)
   -- Set the box's velocity to put it into a circular orbit from its  starting position.
   local r = pos:norm()
   local v = math.sqrt(gravity_strength/r)/r
   body:set_velocity(v*vec2(-pos.y, pos.x)) -- perp
   -- Set the box's angular velocity to match its orbital period and
   -- align its initial angle with its position.
   body:set_angular_velocity(v)
   body:set_angle(math.atan(pos.y, pos.x))
   local shape = cp.poly_shape_new(body, verts, 0.0, identity)
   space:add_shape(shape)
   shape:set_elasticity(0.0)
   shape:set_friction(0.7)
end

-- Create a rouge body to control the planet manually.
local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(20)
local planetBody = space:add_body(cp.body_new_kinematic())
planetBody:set_angular_velocity(0.2)
for i=1, 30 do add_box(space) end
local shape = space:add_shape(cp.circle_shape_new(planetBody, 70.0, {0, 0}))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)

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

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


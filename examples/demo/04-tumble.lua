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

-- Initializations ------------------------------------------------------------

local TITLE = "Tumble"
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

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_gravity({0, -600})
-- We create an infinite mass rogue body to attach the line segments too
-- This way we can control the rotation however we want.
local kinematic_box_body = cp.body_new_kinematic()
space:add_body(kinematic_box_body)
kinematic_box_body:set_angular_velocity(0.4)
-- Set up the static box.
local a, b, c, d = {-200, -200}, {-200,  200}, { 200,  200}, { 200, -200}
local shape = space:add_shape(cp.segment_shape_new(kinematic_box_body, a, b, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(kinematic_box_body, b, c, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(kinematic_box_body, c, d, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(kinematic_box_body, d, a, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)

-- Add the bricks.

local function add_box(space, pos, mass, width, height)
   local body = space:add_body(cp.body_new(mass, cp.moment_for_box(mass, width, height)))
   body:set_position(pos)
   local shape = space:add_shape(cp.box_shape_new(body, width, height, 0.0))
   shape:set_elasticity(0.0)
   shape:set_friction(0.7)
end

local function add_segment(space, pos, mass, width, height)
   local body = space:add_body(cp.body_new(mass, cp.moment_for_box(mass, width, height)))
   body:set_position(pos)
   local a, b =  {0.0, (height-width)/2.0}, {0.0, (width-height)/2.0}
   local shape = space:add_shape(cp.segment_shape_new(body, a, b, width/2.0))
   shape:set_elasticity(0.0)
   shape:set_friction(0.7)
end

local function add_circle(space, pos, mass, radius)
   local body = space:add_body(cp.body_new(mass, cp.moment_for_circle(mass, 0.0, radius, {0, 0})))
   body:set_position(pos)
   local shape = space:add_shape(cp.circle_shape_new(body, radius, {0, 0}))
   shape:set_elasticity(0.0)
   shape:set_friction(0.7)
end

local mass, width, height = 1, 30, 60
math.randomseed(os.time())
for i=0, 6 do
   for j=0, 2 do
      local pos = vec2(i*width - 150, j*height - 150)
      local dice = math.random(0,2) -- 3-faces dice (0, 1, 2)
      if dice==0 then
         add_box(space, pos, mass, width, height)
      elseif dice == 1 then
         add_segment(space, pos, mass, width, height)
      else -- dice == 2
         add_circle(space, pos + vec2(0.0, (height - width)/2.0), mass, width/2.0)
         add_circle(space, pos + vec2(0.0, (width - height)/2.0), mass, width/2.0)
      end
   end
end

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


#!/usr/bin/env lua
local glfw = require("moonglfw")
local gl = require("moongl")
local cp = require("moonchipmunk")
local toolbox = require("moonchipmunk.toolbox")

local infinity = math.huge
local fmt = string.format

-- Initializations ------------------------------------------------------------

local TITLE = "Pyramid Stack"
local FW, FH = 640, 480 -- width and height of the field
local W, H = 1024, 768 -- width and height of the window
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

local space = cp.space_new()
space:set_iterations(30)
space:set_gravity({0, -100})
space:set_sleep_time_threshold(0.5)
space:set_collision_slop(0.5)
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()

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
-- Add lots of boxes.
for i=0, 13 do
   for j=0,i do
      local body = space:add_body(cp.body_new(1.0, cp.moment_for_box(1.0, 30.0, 30.0)))
      body:set_position({j*32 - i*16, 300 - i*32})
      shape = space:add_shape(cp.box_shape_new(body, 30.0, 30.0, 0.5))
      shape:set_elasticity(0.0)
      shape:set_friction(0.8)
   end
end
-- Add a ball to make things more interesting
local radius = 15.0
local body = space:add_body(cp.body_new(10.0, cp.moment_for_circle(10.0, 0.0, radius, {0, 0})))
body:set_position({0, -240 + radius+5})
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

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


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

local TITLE = "Pyramid Topple"
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
space:set_iterations(30)
space:set_gravity({0, -300})
space:set_sleep_time_threshold(0.5)
space:set_collision_slop(0.5)
-- Add a floor.
local shape = cp.segment_shape_new(space:get_static_body(),{-600,-240}, {600,-240}, 0.0)
space:add_shape(shape)
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)

-- Add the dominoes.
local n, width, height = 12, 4.0, 30.0
local n = 12

local function add_domino(space, pos, flipped)
   local mass, radius = 1.0, 0.5
   local moment = cp.moment_for_box(mass, width, height)
   local body = space:add_body(cp.body_new(mass, moment))
   body:set_position(pos)
   local shape
   if flipped then
      shape = cp.box_shape_new(body, height, width, 0.0)
   else
      shape = cp.box_shape_new(body, width - radius*2.0, height, radius)
   end
   space:add_shape(shape)
   shape:set_elasticity(0.0)
   shape:set_friction(0.6)
end

for i=0, n-1 do
   for j=0, (n-i-1) do
      local offset = vec2((j-(n-1-i)*0.5)*1.5*height, (i+0.5)*(height+2*width)-width-240)
      add_domino(space, offset, false)
      add_domino(space, offset+vec2(0, (height + width)/2.0), true)
      if j == 0 then
         add_domino(space, offset + vec2(0.5*(width - height), height + width), false)
      end
      if j ~= (n-i-1) then
         add_domino(space, offset + vec2(height*0.75, (height + 3*width)/2.0), true)
      else
         add_domino(space, offset + vec2(0.5*(height - width), height + width), false)
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


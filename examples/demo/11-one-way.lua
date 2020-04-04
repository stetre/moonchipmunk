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

local TITLE = "One Way Platforms"
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

local collision_type = { ONE_WAY=1, STANDARD=2 }

local platforms = {} -- indexed by shape
local function new_platform(normal, shape)
   local platform = {
      normal=normal,  -- direction objects may pass through
      shape=shape,    -- the platform's shape
   }
   platforms[shape] = platform
   return platform
end

local function pre_solve(arbiter, space)
   local a, b = arbiter:get_shapes()
   local platform = platforms[a]
   if arbiter:get_normal()*platform.normal < 0 then return arbiter:ignore() end
   return true
end
   
local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(10)
space:set_gravity({0, -100})
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
-- Add our one way segment
local shape = space:add_shape(cp.segment_shape_new(static_body, {-160,-100}, {160,-100}, 10.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_collision_type(collision_type.ONE_WAY)
shape:set_filter(not_grabbable)
local platform = new_platform(vec2(0,1), shape)
-- Add a ball to test it out
local radius = 15.0
local body = space:add_body(cp.body_new(10.0, cp.moment_for_circle(10.0, 0.0, radius, {0, 0})))
body:set_position({0, -200})
body:set_velocity({0, 170})
local shape = space:add_shape(cp.circle_shape_new(body, radius, {0, 0}))
shape:set_elasticity(0.0)
shape:set_friction(0.9)
shape:set_collision_type(collision_type.STANDARD)
local handler = space:add_wildcard_handler(collision_type.ONE_WAY)
handler:set_pre_solve_func(pre_solve)

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

local message = "One way platforms are trivial in Chipmunk using a very simple collision callback."
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

   font:draw(message, .05, .9, FONT_SIZE, FONT_COLOR)

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


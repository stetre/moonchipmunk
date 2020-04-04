#!/usr/bin/env lua
local glfw = require("moonglfw")
local gl = require("moongl")
local cp = require("moonchipmunk")
local toolbox = require("moonchipmunk.toolbox")

local pi, infinity = math.pi, math.huge
local sin, cos, abs = math.sin, math.cos, math.abs
local fmt = string.format

-- Initializations ------------------------------------------------------------

local TITLE = "Pyramid Stack"
local FW, FH = 640, 480 -- width and height of the field
local W, H = 1024, 768 -- width and height of the window
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
local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(5)
space:set_gravity({0, -100})
local static_body = space:get_static_body()
local tris = {{-15,-15}, {  0, 10}, { 15,-15}} -- Vertexes for a triangle shape.
-- Create the static triangles.
for i=0, 8 do
   for j=0, 5 do
      local stagger = (j%2)*40
      local offset = {i*80 - 320 + stagger, j*70 - 240}
      local transform = cp.transform_translate(offset)
      local shape = cp.poly_shape_new(static_body, tris, 0.0, transform)
      space:add_shape(shape)
      shape:set_elasticity(1.0)
      shape:set_friction(1.0)
      shape:set_filter(not_grabbable)
   end
end

-- Add lots of pentagons.
local num_pentagon_verts= 5
local pentagon_mass = 1.0
local pentagon_verts = {} -- vertices for a pentagon shape.
for i=0, num_pentagon_verts-1 do
   local angle = -2.0*pi*i/num_pentagon_verts
   table.insert(pentagon_verts, {10*cos(angle), 10*sin(angle)})
end
local pentagon_moment = cp.moment_for_poly(pentagon_mass, pentagon_verts, {0, 0}, 0.0)
local identity = cp.transform_identity()

math.randomseed(os.time())
for i=0,299 do
   local body = cp.body_new(pentagon_mass, pentagon_moment)
   space:add_body(body)
   body:set_position({math.random()*640-320, 350})
   local shape = cp.poly_shape_new(body, pentagon_verts, 0.0, identity)
   space:add_shape(shape)
   shape:set_elasticity(0.0)
   shape:set_friction(0.4)
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
   if button=='right' and action=='press' then
      -- toggle the nearest body (if any) from static to dynamic and viceversa
      local nearest = space:point_query_nearest(grabber:get_pos(), 0.0, grabbable)
      if nearest then
         local body = nearest.shape:get_body()
         if body:get_type() == 'static' then
            body:set_type('dynamic')
            body:set_mass(pentagon_mass)
            body:set_moment(pentagon_moment)
         elseif body:get_type()=='dynamic' then
            body:set_type('static')
         end
      end
   end
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

   for i = 1, n do
      -- Iterate over all of the bodies and reset the ones that have fallen offscreen.
      space:each_body(function(space, body)
         local x, y = table.unpack(body:get_position())
         if y < -260 or abs(x) > 340 then
            body:set_position({math.random()*640-320, 260})
         end
      end)
      space:step(fdt)
      grabber:step(fdt)
   end

   glfw.set_window_title(window, fmt("%s - fps=%.0f, n=%d", TITLE, timer:fps(), n))
   gl.clear_color(BG_COLOR)
   gl.clear('color')
   renderer:begin()
   space:debug_draw()
   renderer:done()

   font:draw("Right click to make pentagons static/dynamic.", .05, .9, FONT_SIZE, FONT_COLOR)

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()



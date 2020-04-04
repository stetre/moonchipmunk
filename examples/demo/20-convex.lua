#!/usr/bin/env lua
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local cp = require("moonchipmunk")
local toolbox = require("moonchipmunk.toolbox")

cp.glmath_compat(true)
local pi, infinity = math.pi, math.huge
local sin, cos, abs, exp, sqrt = math.sin, math.cos, math.abs, math.exp, math.sqrt
local fmt = string.format
local vec2 = glmath.vec2
local clamp, mix = glmath.clamp, glmath.mix
local identity = cp.transform_identity()

-- Initializations ------------------------------------------------------------

local TITLE = "Convex"
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

local density = 1/10000
local tolerance = 2.0

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(30)
space:set_gravity({0, -500})
space:set_sleep_time_threshold(0.5)
space:set_collision_slop(0.5)
local static_body = space:get_static_body(space)
-- Create segments around the edge of the screen.
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,-240}, {320,-240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local width, height = 50.0, 70.0
local mass = width*height*density
local moment = cp.moment_for_box(mass, width, height)
local body = space:add_body(cp.body_new(mass, moment))
local shape = space:add_shape(cp.box_shape_new(body, width, height, 0.0))
shape:set_friction(0.6)

-- Input handling -------------------------------------------------------------

local toggle_fullscreen = toolbox.toggle_fullscreen(window)
local keys = {} -- keys[k] = true if key k is pressed
local right_click, last_right_click_state  = false, false

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

collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(spf)
   dt = timer:update() -- duration of the current frame
   n = n_physics_updates(dt) -- no. of physics updates to do in this frame

   if right_click then
      local mouse_pos = grabber:get_pos()
      local info = shape:point_query(mouse_pos)
      if info.distance > tolerance then
         local body = shape:get_body()
         local verts = shape:get_verts()
         verts[#verts+1] = body:world_to_local(mouse_pos)
         -- This function builds a convex hull for the vertexes.
         local verts = cp.convex_hull(verts, tolerance)
         -- Figure out how much to shift the body by.
         local centroid = cp.centroid_for_poly(verts)
         -- Recalculate the body properties to match the updated shape.
         local mass = cp.area_for_poly(verts, 0.0)*density
         body:set_mass(mass)
         body:set_moment(cp.moment_for_poly(mass, verts, -centroid, 0.0))
         body:set_position(body:local_to_world(centroid))
         -- Use the setter function from chipmunk_unsafe.h.
         -- You could also remove and recreate the shape if you wanted.
         shape:set_verts(verts, cp.transform_translate(-centroid))
      end
   end
   space:step(fdt, n)
   grabber:step(fdt, n)

   glfw.set_window_title(window, fmt("%s - fps=%.0f, n=%d", TITLE, timer:fps(), n))
   gl.clear_color(BG_COLOR)
   gl.clear('color')

   renderer:begin()
   space:debug_draw()
   renderer:done()

   font:draw("Right click and drag to change the blocks's shape.", .05, .9, FONT_SIZE, FONT_COLOR)
   
   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


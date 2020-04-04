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

local TITLE = "Segment Query"
local FW, FH = 640, 480 -- width and height of the field
local W, H = 1024, 768 -- window width and height
local BG_COLOR = {0x07/255, 0x36/255, 0x42/255, 1.0}
local FONT_COLOR, FONT_SIZE = {0xfd/250, 0xf6/250, 0xe3/250, 1.0}, 12/H

local NO_COLOR = {0, 0, 0, 0}
local RED = {1, 0, 0, 1}
local GREEN = {0, 1, 0, 1}
local BLUE = {0, 0, 1, 1}
local GREY = {.5, .5, .5, 1}

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
local filter_all = {group=0, categories=-1, mask=-1 }
local filter_none = {group=0, categories=0, mask=0 }
space:set_iterations(5)

-- add a fat segment
local mass, length = 1.0, 100.0
local a, b = {-length/2.0, 0.0}, {length/2.0, 0.0}
local body = space:add_body(cp.body_new(mass, cp.moment_for_segment(mass, a, b, 0.0)))
body:set_position({0.0, 100.0})
space:add_shape(cp.segment_shape_new(body, a, b, 20.0))
-- add a static segment
space:add_shape(cp.segment_shape_new(space:get_static_body(), {0, 300}, {300, 0}, 0.0))
-- add a pentagon
local mass, verts = 1.0, {}
for i=0, 5 do
   local angle = -2.0*pi*i/5
   table.insert(verts, {30*cos(angle), 30*sin(angle)})
end
local body = space:add_body(cp.body_new(mass, cp.moment_for_poly(mass, verts, {0, 0}, 0.0)))
body:set_position({50.0, 30.0})
space:add_shape(cp.poly_shape_new(body, verts, 10.0, identity))
-- add a circle
local mass, r = 1.0, 20.0
local body = space:add_body(cp.body_new(mass, cp.moment_for_circle(mass, 0.0, r, {0, 0})))
body:set_position({100.0, 100.0})
space:add_shape(cp.circle_shape_new(body, r, {0, 0}))

-- Input handling -------------------------------------------------------------

local toggle_fullscreen = toolbox.toggle_fullscreen(window)
local keys = {} -- keys[k] = true if key k is pressed

local right_click = false
local query_start = vec2()

glfw.set_key_callback(window, function(window, key, scancode, action)
   if key == 'escape' and action == 'press' then
      glfw.set_window_should_close(window, true)
   elseif key == 'f11' and action == 'press' then
      toggle_fullscreen()
   elseif key == 'right' then right_click = action~='release'
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
local message1, message2

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

   local mouse_pos = grabber:get_pos()
   if right_click then query_start = mouse_pos end
   local p_start = query_start
   local p_end = mouse_pos
   local dist = (p_end - p_start):norm()
   local radius = 10.0

   renderer:draw_segment(p_start, p_end, GREEN)
   message1 = fmt("Query: Dist(%f) Point(%5.2f, %5.2f), ", dist, p_end.x, p_end.y)
   local info = space:segment_query_first(p_start, p_end, radius, filter_all)
   local alpha = info and info.alpha or 0
   if info then
      local point, normal = info.point, info.normal
      -- Draw blue over the occluded part of the query
      renderer:draw_segment(mix(p_start, p_end, alpha), p_end, BLUE) 
      -- Draw a little red surface normal
      renderer:draw_segment(point, point + 16*normal, RED)
      -- Draw a little red dot on the hit point.
      renderer:draw_dot(3, point, RED)
      message2 = fmt("Segment Query: Dist(%f) Normal(%5.2f, %5.2f)", alpha*dist, normal.x, normal.y)
   else
      message2 = "Segment Query (None)"
   end
   -- Draw a fat green line over the unoccluded part of the query
   renderer:draw_fat_segment(p_start, mix(p_start,p_end, alpha), radius, GREEN, NO_COLOR)
   local nearest_info = space:point_query_nearest(mouse_pos, 100.0, filter_all)
   if nearest_info then
      -- Draw a grey line to the closest shape.
      renderer:draw_dot(3, mouse_pos, GREY)
      renderer:draw_segment(mouse_pos, nearest_info.point, GREY)
      -- Draw a red bounding box around the shape under the mouse.
      if nearest_info.distance < 0 then
         renderer:draw_box(nearest_info.shape:get_bb(), RED)
      end
   end

   renderer:done()

   font:draw(message1..message2, .05, .9, FONT_SIZE, FONT_COLOR)

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


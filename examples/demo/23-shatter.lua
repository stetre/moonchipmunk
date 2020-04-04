#!/usr/bin/env lua
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local cp = require("moonchipmunk")
local toolbox = require("moonchipmunk.toolbox")

cp.glmath_compat(true)
local pi, infinity = math.pi, math.huge
local sin, cos, asin = math.sin, math.cos, math.asin
local min, max = math.min, math.max
local abs, exp, sqrt = math.abs, math.exp, math.sqrt
local fmt = string.format
local vec2, box2 = glmath.vec2, glmath.box2
local clamp, mix = glmath.clamp, glmath.mix
local identity = cp.transform_identity()

-- Initializations ------------------------------------------------------------

local TITLE = "Shatter"
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

local DENSITY = 1/10000
local MAX_VERTEXES_PER_VORONOI = 16

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(30)
space:set_gravity({0, -500})
space:set_sleep_time_threshold(0.5)
space:set_collision_slop(0.5)
local static_body = space:get_static_body()
-- Create segments around the edge of the screen.
local shape = space:add_shape(cp.segment_shape_new(static_body, {-1000, -240}, { 1000, -240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local width, height = 200.0, 200.0
local mass = width*height*DENSITY
local moment = cp.moment_for_box(mass, width, height)
local body = space:add_body(cp.body_new(mass, moment))
local shape = space:add_shape(cp.box_shape_new(body, width, height, 0.0))
shape:set_friction(0.6)


local function HashVect(x, y, seed)
-- local border = 0.21
   local border = 0.05
   local h = (x*1640531513 ~ y*2654435789) + seed
   return vec2(mix(border, 1.0 - border, (h&0xFFFF)/0xFFFF),
               mix(border, 1.0 - border, ((h>>16)&0xFFFF)/0xFFFF))
end

local function WorleyPoint(i, j, context)
   local size, width, height = context.cellSize, context.width, context.height
   local l, r, b, t = table.unpack(context.bb)
   local fv = HashVect(i, j, context.seed)
   return vec2(mix(l, r, 0.5) + size*(i-1 + fv.x - width*0.5),
           mix(b, t, 0.5) + size*(j-1 + fv.y - height*0.5))
end

local function ClipCell(shape, center, i, j, context, verts)
   local other = WorleyPoint(i, j, context)
   if shape:point_query(other).distance > 0.0 then
      return verts
   end
   local n = other - center
   local dist = n * mix(center, other, 0.5)
   local clipped = {}
   local i=#verts
   for j=1, #verts do
      local a = verts[i]
      local a_dist = a * n - dist
      if a_dist <= 0.0 then
         table.insert(clipped, a)
      end
      local b = verts[j]
      local b_dist = b * n - dist
      if a_dist*b_dist < 0.0 then
         table.insert(clipped, mix(a, b, abs(a_dist)/(abs(a_dist) + abs(b_dist))))
      end
      i=j
   end
   return clipped
end


local function ShatterCell(space, shape, cell, cell_i, cell_j, context)
   local body = shape:get_body()
   local ping = {}
   local verts = shape:get_verts()
   local count = #verts > MAX_VERTEXES_PER_VORONOI and MAX_VERTEXES_PER_VORONOI or #verts
   for i=1, count do 
      ping[i] = body:local_to_world(verts[i])
   end
   for i=1, context.width do
      for j = 1, context.height do
         if not (i==cell_i and j==cell_j) and shape:point_query(cell).distance < 0.0 then
            ping = ClipCell(shape, cell, i, j, context, ping)
         end
      end
   end
   local centroid = cp.centroid_for_poly(ping)
   local mass = cp.area_for_poly(ping, 0.0)*DENSITY
   local moment = cp.moment_for_poly(mass, ping, -centroid, 0.0)
   local new_body = space:add_body(cp.body_new(mass, moment))
   new_body:set_position(centroid)
   new_body:set_velocity(body:get_velocity_at_world_point(centroid))
   new_body:set_angular_velocity(body:get_angular_velocity())
   local transform = cp.transform_translate(-centroid)
   local new_shape = space:add_shape(cp.poly_shape_new(new_body, ping, 0.0, transform))
   -- Copy whatever properties you have set on the original shape that are important
   new_shape:set_friction(shape:get_friction())
end

math.randomseed(os.time())
local function ShatterShape(space, shape, cellSize, focus)
   space:remove_shape(shape)
   space:remove_body(shape:get_body())
   local bb = shape:get_bb()
   local l, r, b, t = table.unpack(bb)
   local width = (r - l)/cellSize + 1
   local height = (t - b)/cellSize + 1
   local context = { -- WorleyContex
      seed = math.random(0, 0x7fff),
      cellSize = cellSize, 
      width = width,
      height = height,
      bb = bb,
      focus = focus
   }
   for i=1, context.width do
      for j=1, context.height do
         local cell = WorleyPoint(i, j, context)
         local info = shape:point_query(cell)
         if info.distance < 0.0 then
            ShatterCell(space, shape, cell, i, j, context)
         end
      end
   end
   shape:get_body():free()
   shape:free()
end

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

local message = "Right click something to shatter it."

collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(spf)
   dt = timer:update() -- duration of the current frame
   n = n_physics_updates(dt) -- no. of physics updates to do in this frame

   space:step(fdt, n)
   grabber:step(fdt, n)

   if right_click then
      local mouse_pos = grabber:get_pos()
      local info = space:point_query_nearest(mouse_pos, 0, grabbable)
      if info then
         local l, r, b, t = table.unpack(info.shape:get_bb())
         local cell_size = max(r - l, t - b)/5.0
         if cell_size > 5.0 then
            ShatterShape(space, info.shape, cell_size, mouse_pos)
         end
      end
   end

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


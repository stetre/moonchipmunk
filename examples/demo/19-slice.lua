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

local TITLE = "Slice"
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

local function clip_poly(space, shape, normal, dist)
   local body = shape:get_body()
   local verts = shape:get_verts()
   local clipped = {}
   local j = #verts
   for i=1, #verts do 
      local a = body:local_to_world(verts[j])
      local a_dist = a*normal - dist
      if a_dist < 0.0 then table.insert(clipped, a) end
      local b = body:local_to_world(verts[i])
      local b_dist = b*normal - dist
      if a_dist*b_dist < 0.0 then
         table.insert(clipped, mix(a, b, abs(a_dist)/(abs(a_dist)+abs(b_dist))))
      end
      j = i
   end
   local centroid = cp.centroid_for_poly(clipped)
   local mass = cp.area_for_poly(clipped, 0.0)*DENSITY
   local moment = cp.moment_for_poly(mass, clipped, -centroid, 0.0)
   local new_body = space:add_body(cp.body_new(mass, moment))
   new_body:set_position(centroid)
   new_body:set_velocity(body:get_velocity_at_world_point(centroid))
   new_body:set_angular_velocity(body:get_angular_velocity())
   local transform = cp.transform_translate(-centroid)
   local new_shape = space:add_shape(cp.poly_shape_new(new_body, clipped, 0.0, transform))
   -- Copy whatever properties you have set on the original shape that are important
   new_shape:set_friction(shape:get_friction())
end

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(30)
space:set_gravity({0, -500})
space:set_sleep_time_threshold(0.5)
space:set_collision_slop(0.5)
local staticBody = space:get_static_body()
-- Create segments around the edge of the screen.
local shape = space:add_shape(cp.segment_shape_new(staticBody, {-1000,-240}, {1000,-240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local width, height = 200.0, 300.0
local mass = width*height*DENSITY
local moment = cp.moment_for_box(mass, width, height)
local body = space:add_body(cp.body_new(mass, moment))
local shape = space:add_shape(cp.box_shape_new(body, width, height, 0.0))
shape:set_friction(0.6)

-- Input handling -------------------------------------------------------------

local toggle_fullscreen = toolbox.toggle_fullscreen(window)
local keys = {} -- keys[k] = true if key k is pressed
local right_click, last_right_click_state  = false, false
local sliceStart = vec2(0, 0)

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


   glfw.set_window_title(window, fmt("%s - fps=%.0f, n=%d", TITLE, timer:fps(), n))
   gl.clear_color(BG_COLOR)
   gl.clear('color')

   renderer:begin()

   for i=1, n do
      space:step(fdt)
      grabber:step(fdt)
      local mouse_pos = grabber:get_pos()
      if right_click ~= last_right_click_state then
         if right_click then
            sliceStart = mouse_pos
         else
            local a, b = sliceStart, mouse_pos
            space:segment_query(sliceStart, mouse_pos, 0.0, grabbable,
               function(space, shape, point, normal, alpha)
                  -- Check that the slice was complete by checking that the
                  -- endpoints aren't in the sliced shape.
                  local info1 = shape:point_query(a)
                  local info2 = shape:point_query(b)
                  if info1.distance > 0 and info2.distance > 0 then
                     -- Can't modify the space during a query.
                     -- Must make a post-step callback to do the actual slicing.
                     space: add_post_step_callback(function(space)
                        -- Clipping plane normal and distance.
                        local normal = (cp.vperp(b-a)):normalize()
                        local dist = a * normal
                        clip_poly(space, shape, normal, dist)
                        clip_poly(space, shape, -normal, -dist)
                        local body = shape:get_body()
                        space:remove_shape(shape)
                        space:remove_body(body)
                        shape:free()
                        body:free()
                     end)
                  end
               end)
         end
         last_right_click_state = right_click
      end
      if right_click then
         renderer:draw_segment(sliceStart, mouse_pos, RED) end
   end

   space:debug_draw()
   renderer:done()

   font:draw("Right click and drag to slice up the block.", .05, .9, FONT_SIZE, FONT_COLOR)
   
   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


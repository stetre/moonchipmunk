#!/usr/bin/env lua
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local cp = require("moonchipmunk")
local toolbox = require("moonchipmunk.toolbox")

cp.glmath_compat(true)
local pi, infinity = math.pi, math.huge
local sin, cos, abs, exp = math.sin, math.cos, math.abs, math.exp
local fmt = string.format
local vec2 = glmath.vec2
local clamp, mix = glmath.clamp, glmath.mix
local identity = cp.transform_identity()

-- Initializations ------------------------------------------------------------

local TITLE = "Simple Sensor based fluids."
local FW, FH = 640, 480 -- width and height of the field
local W, H = 1024, 768 -- window width and height
local BG_COLOR = {0x07/255, 0x36/255, 0x42/255, 1.0}
local FONT_COLOR, FONT_SIZE = {0xfd/250, 0xf6/250, 0xe3/250, 1.0}, 12/H
local RED = {1, 0, 0, 1}
local BLUE = {0, 0, 1, 1}
local BLUE1 = {0, 0, 1, .1}

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

local renderer -- forwad decl.
local fluid_density, fluid_drag = 0.00014, 2.0

local function k_scalar_body(body, point, normal)
   local rcn = cp.vcross(point - body:get_position(), normal)
   return 1.0/body:get_mass() + rcn*rcn/body:get_moment()
end

local function waterPreSolve(arbiter, space)
   local water, poly = arbiter:get_shapes()
   local body = poly:get_body()
   -- Get the top of the water sensor bounding box to use as the water level.
   local level = water:get_bb().maxy
   -- Clip the polygon against the water level
   local poly_verts = poly:get_verts()
   local clipped = {}
   local j = #poly_verts
   for i=1, #poly_verts do
      local a = body:local_to_world(poly_verts[j])
      local b = body:local_to_world(poly_verts[i])
      if a.y < level then table.insert(clipped, a) end
      local a_level = a.y - level
      local b_level = b.y - level
      if a_level*b_level < 0.0 then
         local t = abs(a_level)/(abs(a_level) + abs(b_level))
         table.insert(clipped, mix(a, b, t))
      end
      j = i
   end
   -- Calculate buoyancy from the clipped polygon area
   local clippedArea = cp.area_for_poly(clipped, 0.0)
   local displacedMass = clippedArea*fluid_density
   local centroid = cp.centroid_for_poly(clipped)
   renderer:draw_polygon(clipped, 5.0, BLUE, BLUE1)
   renderer:draw_dot(5, centroid, BLUE)
   local dt = space:get_current_time_step()
   local g = space:get_gravity()
   -- Apply the buoyancy force as an impulse.
   body:apply_impulse_at_world_point(-displacedMass*dt*g, centroid)
   -- Apply linear damping for the fluid drag.
   local v_centroid = body:get_velocity_at_world_point(centroid)
   local k = k_scalar_body(body, centroid, v_centroid:normalize())
   local damping = clippedArea*fluid_drag*fluid_density
   local v_coef = exp(-damping*dt*k) -- linear drag
-- local v_coef = 1.0/(1.0 + damping*dt*v_centroid:norm()*k) -- quadratic drag
   body:apply_impulse_at_world_point(v_centroid*(v_coef-1)/k, centroid)
   -- Apply angular damping for the fluid drag.
   local cog = body:local_to_world(body:get_center_of_gravity())
   local mass = fluid_drag*fluid_density*clippedArea
   local w_damping = cp.moment_for_poly(mass, clipped, -cog, 0.0)
   local ang_vel = body:get_angular_velocity()
   body:set_angular_velocity(ang_vel*exp(-w_damping*dt/body:get_moment()))
   return true
end

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(30)
space:set_gravity({0, -500})
-- space:set_damping(0.5)
space:set_sleep_time_threshold(0.5)
space:set_collision_slop(0.5)
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
local shape = space:add_shape(cp.segment_shape_new(static_body, {-320,240}, {320,240}, 0.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
-- Add the edges of the bucket
local l, b, r, t, radius = -300, -200, 100, 0, 5.0
local shape = space:add_shape(cp.segment_shape_new(static_body,{l,b},{l,t},radius))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body,{r,b},{r,t},radius))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body,{l,b},{r, b},radius))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
-- Add the sensor for the water.
local shape = space:add_shape(cp.box_shape_new(static_body, {l, r, b, t}, 0.0))
shape:set_sensor(true)
shape:set_collision_type(1)
local width, height = 200.0, 50.0
local mass = 0.3*fluid_density*width*height
local moment = cp.moment_for_box(mass, width, height)
local body = space:add_body(cp.body_new(mass, moment))
body:set_position({-50, -100})
body:set_velocity({0, -100})
body:set_angular_velocity(1)
local shape = space:add_shape(cp.box_shape_new(body, width, height, 0.0))
shape:set_friction(0.8)
local width, height = 40.0, 80.0
local mass = 0.3*fluid_density*width*height
local moment = cp.moment_for_box(mass, width, height)
local body = space:add_body(cp.body_new(mass, moment))
body:set_position({-200, -50})
body:set_velocity({0, -100})
body:set_angular_velocity(1)
local shape = space:add_shape(cp.box_shape_new(body, width, height, 0.0))
shape:set_friction(0.8)
local handler = space:add_collision_handler(1, 0)
handler:set_pre_solve_func(waterPreSolve)

-- Input handling -------------------------------------------------------------

local toggle_fullscreen = toolbox.toggle_fullscreen(window)
local keys = {} -- keys[k] = true if key k is pressed

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
end)

-- Game loop ------------------------------------------------------------------
local timer = toolbox.frame_timer()
local spf = 1/60 -- 1 / desired fps
local fdt = 1/180 -- fixed dt for physics updates
local n_physics_updates = toolbox.fixed_dt_counter(fdt)
local n, dt

renderer = toolbox.renderer(space)

collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(spf)
   dt = timer:update() -- duration of the current frame
   n = n_physics_updates(dt) -- no. of physics updates to do in this frame

   renderer:begin()
   glfw.set_window_title(window, fmt("%s - fps=%.0f, n=%d", TITLE, timer:fps(), n))
   gl.clear_color(BG_COLOR)
   gl.clear('color')
   -- Note that since we render within a callback, we need to call space:step() between
   -- renderer:begin() and renderer:done()
   space:step(fdt, n)
   grabber:step(fdt, n)
   space:debug_draw()
   renderer:done()

   -- font:draw(message, .05, .9, FONT_SIZE, FONT_COLOR)

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


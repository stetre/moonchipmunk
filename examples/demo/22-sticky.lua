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

local TITLE = "Sticky Surfaces"
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

local COLLISION_TYPE_STICKY = 1
local STICK_SENSOR_THICKNESS = 2.5

local user_data = {} -- user_data for arbiters
local function set_user_data(arbiter, val)
   if not val then -- unset
      local i = arbiter:get_user_index()
      if user_data[i] then
         user_data[i]=nil
         arbiter:set_user_index(0)
      end
   else -- set
      local i =#user_data+1
      user_data[i]=val
      arbiter:set_user_index(i)
   end
end

local function get_user_data(arbiter)
   local i = arbiter:get_user_index()
   return user_data[i]
end

local function StickyPreSolve(arbiter, space)
   -- We want to fudge the collisions a bit to allow shapes to overlap more.
   -- This simulates their squishy sticky surface, and more importantly
   -- keeps them from separating and destroying the joint.
   -- Track the deepest collision point and use that to determine if a rigid collision should occur.
   local deepest = infinity
   -- Grab the contact set and iterate over them.
   local normal, points = arbiter:get_contact_point_set()
   local delta = STICK_SENSOR_THICKNESS*normal
   for _, point in ipairs(points) do
      -- Sink the contact points into the surface of each shape.
      point.a = point.a - delta
      point.b = point.b + delta
      deepest = min(deepest, point.distance + 2.0*STICK_SENSOR_THICKNESS)
   end
   -- Set the new contact point data.
   arbiter:set_contact_point_set(normal, points)
   -- If the shapes are overlapping enough, then create a joint that sticks them together
   -- at the first contact point.
   local joint = get_user_data(arbiter)
   if not joint and deepest <= 0.0 then
      local bodyA, bodyB = arbiter:get_bodies()
      -- Create a joint at the contact point to hold the body in place.
      local anchorA = bodyA:world_to_local(points[1].a)
      local anchorB = bodyB:world_to_local(points[1].b)
      local joint = cp.pivot_joint_new(bodyA, bodyB, anchorA, anchorB)
      -- Give it a finite force for the stickyness.
      joint:set_max_force(3e3)
      -- Schedule a post-step() callback to add the joint
      -- (Notice how here closures come in handy to pass the joint to the callback)
      space:add_post_step_callback(function(space) space:add_constraint(joint) end)
      -- Store the joint on the arbiter so we can remove it later.
      set_user_data(arbiter, joint)
   end
   -- Position correction and velocity are handled separately so changing
   -- the overlap distance alone won't prevent the collision from occuring.
   -- Explicitly the collision for this frame if the shapes don't overlap using the new distance.
   return (deepest <= 0.0)
   -- Lots more that you could improve upon here as well:
   -- * Modify the joint over time to make it plastic.
   -- * Modify the joint in the post-step to make it conditionally plastic (like clay).
   -- * Track a joint for the deepest contact point instead of the first.
   -- * Track a joint for each contact point. (more complicated since you only get one data pointer).
end

local function StickySeparate(arbiter, space)
   local joint = get_user_data(arbiter)
   if joint then
      -- The joint won't be removed until the step is done.
      -- Need to disable it so that it won't apply itself.
      -- Setting the force to 0 will do just that
      joint:set_max_force(0.0)
      -- Perform the removal in a post-step() callback.
      space:add_post_step_callback(function(space)
         space:remove_constraint(joint)
         joint:free()
      end)
      set_user_data(arbiter, nil)
   end
end

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
space:set_iterations(10)
space:set_gravity({0, -1000})
space:set_collision_slop(2.0)
local static_body = space:get_static_body()
-- Create segments around the edge of the screen.
local shape = space:add_shape(cp.segment_shape_new(static_body, {-340,-260}, {-340, 260}, 20.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, { 340,-260}, { 340, 260}, 20.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-340,-260}, { 340,-260}, 20.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local shape = space:add_shape(cp.segment_shape_new(static_body, {-340, 260}, { 340, 260}, 20.0))
shape:set_elasticity(1.0)
shape:set_friction(1.0)
shape:set_filter(not_grabbable)
local mass, radius = 0.15, 10.0
math.randomseed(os.time())
-- for i=1, 200 do -- alas, 200 is too many, at least for my system
for i=1, 150 do
   local body = space:add_body(cp.body_new(mass, cp.moment_for_circle(mass, 0.0, radius, {0, 0})))
   body:set_position({mix(-150.0, 150.0, math.random()), mix(-150.0, 150.0, math.random())})
   local shape = space:add_shape(cp.circle_shape_new(body, radius + STICK_SENSOR_THICKNESS, {0, 0}))
   shape:set_friction(0.9)
   shape:set_collision_type(COLLISION_TYPE_STICKY)
end
local handler = space:add_wildcard_handler(COLLISION_TYPE_STICKY)
handler:set_pre_solve_func(StickyPreSolve)
handler:set_separate_func(StickySeparate)


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

local message = "Sticky collisions using arbiters."

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


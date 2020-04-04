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
local clamp = glmath.clamp
local identity = cp.transform_identity()

-- Initializations ------------------------------------------------------------

local TITLE = "Springies"
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


local function new_spring(body_a, body_b, anchor_a, anchor_b, rest_length, stiff, damp)
   local spring = cp.damped_spring_new(body_a, body_b, anchor_a, anchor_b, rest_length, stiff, damp)
   spring:set_spring_force_func(function(spring, dist)
      return clamp(spring:get_rest_length()-dist, -20.0, 20.0)*spring:get_stiffness()
   end)
   return spring
end

local function add_bar(space, a, b, group)
   local a, b = vec2(a[1], a[2]), vec2(b[1], b[2])
   local center = (a+b)/2
   local length = (b-a):norm()
   local mass = length/160.0
   local body = space:add_body(cp.body_new(mass, mass*length*length/12.0))
   body:set_position(center)
   local shape = cp.segment_shape_new(body, a-center, b-center, 10.0)
   space:add_shape(shape)
   shape:set_filter({group=group, categories=-1, mask=-1})
   return body
end

local space = cp.space_new()
local grabber = toolbox.grabber(window, space)
local grabbable, not_grabbable = grabber:filters()
local static_body = space:get_static_body()

local body1  = add_bar(space, {-240,  160}, {-160,   80}, 1)
local body2  = add_bar(space, {-160,   80}, { -80,  160}, 1)
local body3  = add_bar(space, {   0,  160}, {  80,    0}, 0)
local body4  = add_bar(space, { 160,  160}, { 240,  160}, 0)
local body5  = add_bar(space, {-240,    0}, {-160,  -80}, 2)
local body6  = add_bar(space, {-160,  -80}, { -80,    0}, 2)
local body7  = add_bar(space, { -80,    0}, {   0,    0}, 2)
local body8  = add_bar(space, {   0,  -80}, {  80,  -80}, 0)
local body9  = add_bar(space, { 240,   80}, { 160,    0}, 3)
local body10 = add_bar(space, { 160,    0}, { 240,  -80}, 3)
local body11 = add_bar(space, {-240,  -80}, {-160, -160}, 4)
local body12 = add_bar(space, {-160, -160}, { -80, -160}, 4)
local body13 = add_bar(space, {   0, -160}, {  80, -160}, 0)
local body14 = add_bar(space, { 160, -160}, { 240, -160}, 0)

space:add_constraint(cp.pivot_joint_new( body1,  body2, { 40,-40}, {-40,-40}))
space:add_constraint(cp.pivot_joint_new( body5,  body6, { 40,-40}, {-40,-40}))
space:add_constraint(cp.pivot_joint_new( body6,  body7, { 40, 40}, {-40,  0}))
space:add_constraint(cp.pivot_joint_new( body9, body10, {-40,-40}, {-40, 40}))
space:add_constraint(cp.pivot_joint_new(body11, body12, { 40,-40}, {-40,  0}))

local stiff, damp = 100.0, 0.5
space:add_constraint(new_spring(static_body,body1,{-320,240},{-40,40},0.0,stiff,damp))
space:add_constraint(new_spring(static_body,body1,{-320,80},{-40,40},0.0,stiff,damp))
space:add_constraint(new_spring(static_body,body1,{-160,240},{-40,40},0.0,stiff,damp))

space:add_constraint(new_spring(static_body,body2,{-160,240},{40,40},0.0,stiff,damp))
space:add_constraint(new_spring(static_body,body2,{0,240},{40,40},0.0,stiff,damp))

space:add_constraint(new_spring(static_body,body3,{80,240},{-40,80},0.0,stiff,damp))

space:add_constraint(new_spring(static_body,body4,{80,240},{-40,0},0.0,stiff,damp))
space:add_constraint(new_spring(static_body,body4,{320,240},{40,0},0.0,stiff,damp))

space:add_constraint(new_spring(static_body,body5,{-320,80},{-40,40},0.0,stiff,damp))
   
space:add_constraint(new_spring(static_body,body9,{320,80},{40,40},0.0,stiff,damp))

space:add_constraint(new_spring(static_body,body10,{320,0},{40,-40},0.0,stiff,damp))
space:add_constraint(new_spring(static_body,body10,{320,-160},{40,-40},0.0,stiff,damp))

space:add_constraint(new_spring(static_body,body11,{-320,-160},{-40,40},0.0,stiff,damp))

space:add_constraint(new_spring(static_body,body12,{-240,-240},{-40,0},0.0,stiff,damp))
space:add_constraint(new_spring(static_body,body12,{0,-240},{40,0},0.0,stiff,damp))

space:add_constraint(new_spring(static_body,body13,{0,-240},{-40,0},0.0,stiff,damp))
space:add_constraint(new_spring(static_body,body13,{80,-240},{40,0},0.0,stiff,damp))

space:add_constraint(new_spring(static_body,body14,{80,-240},{-40,0},0.0,stiff,damp))
space:add_constraint(new_spring(static_body,body14,{240,-240},{40,0},0.0,stiff,damp))
space:add_constraint(new_spring(static_body,body14,{320,-160},{40,0},0.0,stiff,damp))

space:add_constraint(new_spring(body1,body5,{40,-40},{-40,40},0.0,stiff,damp))
space:add_constraint(new_spring(body1,body6,{40,-40},{40,40},0.0,stiff,damp))
space:add_constraint(new_spring(body2,body3,{40,40},{-40,80},0.0,stiff,damp))
space:add_constraint(new_spring(body3,body4,{-40,80},{-40,0},0.0,stiff,damp))
space:add_constraint(new_spring(body3,body4,{40,-80},{-40,0},0.0,stiff,damp))
space:add_constraint(new_spring(body3,body7,{40,-80},{40,0},0.0,stiff,damp))
space:add_constraint(new_spring(body3,body7,{-40,80},{-40,0},0.0,stiff,damp))
space:add_constraint(new_spring(body3,body8,{40,-80},{40,0},0.0,stiff,damp))
space:add_constraint(new_spring(body3,body9,{40,-80},{-40,-40},0.0,stiff,damp))
space:add_constraint(new_spring(body4,body9,{40,0},{40,40},0.0,stiff,damp))
space:add_constraint(new_spring(body5,body11,{-40,40},{-40,40},0.0,stiff,damp))
space:add_constraint(new_spring(body5,body11,{40,-40},{40,-40},0.0,stiff,damp))
space:add_constraint(new_spring(body7,body8,{40,0},{-40,0},0.0,stiff,damp))
space:add_constraint(new_spring(body8,body12,{-40,0},{40,0},0.0,stiff,damp))
space:add_constraint(new_spring(body8,body13,{-40,0},{-40,0},0.0,stiff,damp))
space:add_constraint(new_spring(body8,body13,{40,0},{40,0},0.0,stiff,damp))
space:add_constraint(new_spring(body8,body14,{40,0},{-40,0},0.0,stiff,damp))
space:add_constraint(new_spring(body10,body14,{40,-40},{-40,0},0.0,stiff,damp))
space:add_constraint(new_spring(body10,body14,{40,-40},{-40,0},0.0,stiff,damp))

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


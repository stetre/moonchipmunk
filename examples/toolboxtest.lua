#!/usr/bin/env lua
local glfw = require("moonglfw")
local gl = require("moongl")
local glmath = require("moonglmath")
local cp = require("moonchipmunk")
local toolbox = require("moonchipmunk.toolbox")
--local game = require("game")

local vec2, vec3, vec4 = glmath.vec2, glmath.vec3, glmath.vec4
local fmt = string.format

-- Initializations ------------------------------------------------------------

local TITLE = "Prova!"
local FW, FH = 640, 480 -- width and height of the field
local W, H = 1024, 768 -- window width and height

local WHITE = {1, 1, 1, 1}
local RED = {1, 0, 0, 1}
local GREEN = {0, 1, 0, 1}
local BLUE = {0, 0, 1, 1}

glfw.version_hint(3, 3, 'core')
glfw.window_hint('samples', 32)
local window = glfw.create_window(W, H, TITLE)
glfw.make_context_current(window)
gl.init()
toolbox.init(W, H, true)
local camera = toolbox.camera(vec3(0, 0, 0))
--game.init(W, H)

local view, projection
local function set_matrices()
   toolbox.set_matrices(camera:view(), camera:projection(-FW/2, FW/2, -FH/2, FH/2))
   toolbox.resize(W, H)
end

local function resize(window, w, h)
   W, H = w, h
   set_matrices()
   --game.resize(W, H)
   gl.viewport(0, 0, W, H)
end

glfw.set_window_size_callback(window, resize)
resize(window, W, H)

local space = cp.space_new()
local renderer = toolbox.renderer(space)

-- Fonts ----------------------------------------------------------------------
local font = toolbox.font("ttf-bitstream-vera-1.10/VeraMoBd.ttf", .3)

-- Sprites --------------------------------------------------------------------
local face = toolbox.sprite("sprites/awesomeface.png", 'rgba')
local block = toolbox.sprite("sprites/block.png", 'rgb')

-- Sounds ---------------------------------------------------------------------
local shoot = toolbox.sound_sample("sounds/Shoot_00.wav")
local explosion = toolbox.sound_sample("sounds/Explosion_00.wav")
local jinglewin = toolbox.sound_sample("sounds/Jingle_Win_00.wav")

local function playsoundevery(sample, interval)
   local sample = sample
   local interval = interval
   local t = 0
   return function(dt)
      t = t+dt
      if t >= interval then sample:play() t = 0 end
   end
end

local playshoot = playsoundevery(shoot, 1)
local playexplosion = playsoundevery(explosion, 2.3)
local playjinglewin = playsoundevery(jinglewin, 2.7)

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

-- Game loop ------------------------------------------------------------------

local timer = toolbox.frame_timer()

local rot = 0
local fdt = 1/180 -- fixed dt for physics updates
local n_physics_updates = toolbox.fixed_dt_counter(fdt)
local dt = timer:update()


local ang_speed = math.pi/10 -- rad/s
collectgarbage()
collectgarbage('stop')
while not glfw.window_should_close(window) do
   glfw.wait_events_timeout(1/60)
   dt = timer:update()
   local n = n_physics_updates(dt)
   space:step(fdt, n) -- do n update steps with time interval = fdt
   
   glfw.set_window_title(window, tostring(timer))

   playshoot(dt)
   playexplosion(dt)
   playjinglewin(dt)

   if keys['up'] then camera:move('up', 200, dt) end
   if keys['down'] then camera:move('down', 200, dt) end
   if keys['left'] then camera:move('left', 200, dt) end
   if keys['right'] then camera:move('right', 200, dt) end
   if keys['w'] then camera:zoom('in', 1, dt) end
   if keys['s'] then camera:zoom('out', 1, dt) end
   if keys['a'] then camera:rotate('ccw', ang_speed, dt) end
   if keys['d'] then camera:rotate('cw', ang_speed, dt) end
   set_matrices()

   --game.input(keys)
   --game.update(dt, keys)
   --game.draw(dt, keys)

   gl.clear_color(0.3, 0.3, 0.3, 1.0)
   gl.clear('color')
   renderer:begin()
   renderer:draw_dot(40, {0, 0}, {1, 0, 0, 1})
   renderer:draw_dot(40, {FW/2, FH/2}, {0, 0, 1, 1})

   rot = rot + dt
   face:draw({0,100}, {100,100}, rot)
   block:draw({0, -200}, {100, 30}, 0, RED)
   block:draw({100, -200}, {100, 30}, 0, GREEN)
   block:draw({200, -200}, {100, 30}, math.pi/4, BLUE)
   block:draw({300, -200}, {100, 30}, 0, WHITE)

   font:draw(string.format("Physics intervals = %d", n), 0, 0, .05, WHITE)

   renderer:draw_box({-FW/4, 0, FH/8, FH/4}, {1, 0, 0, 1}) 
   renderer:draw_fat_segment({0, 0}, vec2(FW/4, FH/4)*math.cos(rot), 10, {0, 1, 0, 1}, {0, 0, 0, 0}) 
   renderer:done()

   glfw.swap_buffers(window)
   collectgarbage()
end

toolbox.cleanup()


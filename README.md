## MoonChipmunk: Lua bindings for Chipmunk2D

MoonChipmunk is a Lua binding library for Scott Lembcke's [Chipmunk2D](http://chipmunk-physics.net/) physics engine.

It runs on GNU/Linux and on Windows (MSYS2/MinGW) and requires
[Lua](http://www.lua.org/) (>=5.3) and [Chipmunk2D](http://chipmunk-physics.net/downloads.php) (>= 7.0.3).

_Author:_ _[Stefano Trettel](https://www.linkedin.com/in/stetre)_

[![Lua logo](./doc/powered-by-lua.gif)](http://www.lua.org/)

#### License

MIT/X11 license (same as Lua). See [LICENSE](./LICENSE).

#### Documentation

See the [Reference Manual](https://stetre.github.io/moonchipmunk/doc/index.html).

#### Getting and installing

Setup the build environment as described [here](https://github.com/stetre/moonlibs), then:

```sh
$ git clone https://github.com/stetre/moonchipmunk/
$ cd moonchipmunk
moonchipmunk$ make
moonchipmunk$ sudo make install
```

#### Example

The example below is a port of the ["Hello Chipmunk (World)" example](http://chipmunk-physics.net/release/ChipmunkLatest-Docs/#Intro-HelloChipmunk) from the Chipmunk2D manual.

Other examples, including a Lua port of the Chipmunk2D demos, can be found in the **examples/** directory.

```lua
-- MoonChipmunk example: hello.lua
local cp = require("moonchipmunk")

-- Create an empty space and set the gravity for it.
local space = cp.space_new()
space:set_gravity({0, -100})
  
-- Add a static line segment shape for the ground.
-- We'll make it slightly tilted so the ball will roll off.
-- We attach it to a static body to tell Chipmunk it shouldn't be movable.
local ground = cp.segment_shape_new(space:get_static_body(), {-20, 5}, {20, -5}, 0)
ground:set_friction(1)
space:add_shape(ground)

-- Now let's make a ball that falls onto the line and rolls off.
-- First we need to make a body to hold the physical properties of the object.
-- These include the mass, position, velocity, angle, etc. of the object.
-- Then we attach collision shapes to the body to give it a size and shape.
local radius = 5
local mass = 1
-- The moment of inertia is like mass for rotation
-- Use the cp.moment_for*() functions to help you approximate it.
local moment = cp.moment_for_circle(mass, 0, radius, {0, 0})
  
 -- The space:add*() methods return the thing that you are adding.
-- It's convenient to create and add an object in one line.
local ballBody = space:add_body(cp.body_new(mass, moment))
ballBody:set_position({0, 15})
  
-- Now we create the collision shape for the ball.
-- You can create multiple collision shapes that point to the same body.
-- They will all be attached to the body and move around to follow it.
local ballShape = space:add_shape(cp.circle_shape_new(ballBody, radius, {0, 0}))
ballShape:set_friction(0.7)
  
-- Now that it's all set up, we simulate all the objects in the space by
-- stepping forward through time in small increments called steps.
-- It is *highly* recommended to use a fixed size time step.
local timeStep = 1.0/60.0
for time = 0, 2, timeStep do
    local pos = ballBody:get_position()
    local vel = ballBody:get_velocity()
   print(string.format(
        "Time is %5.2f. ballBody is at (%5.2f, %5.2f). It's velocity is (%5.2f, %5.2f)",
        time, pos[1], pos[2], vel[1], vel[2]))
   space:step(timeStep)
end
 
-- No need to delete objects here (they are are automatically deleted ad exit).
```

The script can be executed at the shell prompt with the standard Lua interpreter:

```shell
$ lua hello.lua
```

#### See also

* [MoonLibs - Graphics and Audio Lua Libraries](https://github.com/stetre/moonlibs).

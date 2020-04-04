#!/usr/bin/env lua
-- MoonChipmunk example: hello.lua
-- This is a port of the "Hello Chipmunk (World)" example from the Chipmunk manual:
-- (see http://chipmunk-physics.net/release/ChipmunkLatest-Docs/#Intro-HelloChipmunk )

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

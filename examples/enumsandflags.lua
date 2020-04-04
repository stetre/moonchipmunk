#!/usr/bin/env lua
-- MoonChipmunk example: enumsandflags.lua
local cp = require("moonchipmunk")

-- Enums
print(table.unpack(cp.enum('bodytype')))

-- Flags
print(cp.debugdrawflags(-1))
print(string.format("0x%.8x", cp.debugdrawflags('shapes', 'constraints', 'points')))

print(string.format("SPACE_DEBUG_DRAW_SHAPES 0x%x", cp.SPACE_DEBUG_DRAW_SHAPES))
print(string.format("SPACE_DEBUG_DRAW_CONSTRAINTS 0x%x", cp.SPACE_DEBUG_DRAW_CONSTRAINTS))
print(string.format("SPACE_DEBUG_DRAW_COLLISION_POINTS 0x%x", cp.SPACE_DEBUG_DRAW_COLLISION_POINTS))
local flags = cp.SPACE_DEBUG_DRAW_SHAPES|cp.SPACE_DEBUG_DRAW_CONSTRAINTS|cp.SPACE_DEBUG_DRAW_COLLISION_POINTS
print(string.format("0x%.8x", flags))

-- Constants
print(string.format("NO_GROUP 0x%x", cp.NO_GROUP))
print(string.format("ALL_CATEGORIES 0x%x", cp.ALL_CATEGORIES))
print(string.format("WILDCARD_COLLISION_TYPE 0x%x", cp.WILDCARD_COLLISION_TYPE))


print(string.format("~ALL_CATEGORIES 0x%x", ~cp.ALL_CATEGORIES))
print(string.format("~WILDCARD_COLLISION_TYPE 0x%x", ~cp.WILDCARD_COLLISION_TYPE))

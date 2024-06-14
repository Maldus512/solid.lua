local Solid = require "src.solid"

local cube1 = Solid.cube { { 10, 10, 10 }, center = true }
local cube2 = Solid.cube { { 20, 20, 20 }, center = true }
local cube3 = Solid.cube { { 30, 30, 30 }, center = true }
local addition = Solid.union { cube1, cube2 }
addition = Solid.union { addition, Solid.translate({1,2,3}, cube3) }
print(Solid.exportToString(addition))

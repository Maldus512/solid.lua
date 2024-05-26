local Solid = require "src.solid"

local cube = Solid.cube { { 10, 10, 10 }, center = true }
local addition = Solid.union { cube, cube }
print(Solid.exportToString(addition))

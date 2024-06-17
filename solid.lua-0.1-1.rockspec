package = "solid.lua"
version = "0.1-1"
source = { 
    --url = "git://github.com/Maldus512/solid.lua",
    url = "file:///home/maldus/Projects/Maldus512/solid.lua",
    dir = "solid.lua",
}
description = {
    summary = "Lua bindings to generated OpenScad scripts",
    detailed = [[ ]],
    license = "MIT"      -- or whatever you like
}
dependencies = {
    "lua >= 5.4"
    -- If you depend on other rocks, add them here
}
build = {
    type = "builtin",
    modules = {
        solid = "src/solid.lua"
    }
}

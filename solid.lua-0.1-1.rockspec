package = "solid.lua"
version = "0.1-1"
source = {
    url = "..." -- We don't have one yet
}
description = {
    summary = "Lua bindings to generated OpenScad scripts",
    detailed = [[ ]],
    homepage = "http://...", -- We don't have one yet
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

local folderOfThisFile = (...):match("(.-)[^%.]+$")
local Type = (require(folderOfThisFile .. "sum")).Type

local Solid = Type {
    Cube = { "dimensions", "center" },
    Union = { "solids" },
}

local function exportToString(solid, string, indent)
    if string == nil then
        string = ""
    end

    if indent == nil then
        indent = 0
    end

    -- TODO: optimize with tail call
    return solid:match {
        Cube = function(dimensions, center)
            return string ..
                (string.rep("    ", indent)) ..
                "cube([" ..
                tostring(dimensions[1]) ..
                ", " ..
                tostring(dimensions[2]) ..
                ", " .. tostring(dimensions[3]) .. "], center=" .. tostring(center) .. ");\n"
        end,
        Union = function(elements)
            local indentation = string.rep("    ", indent)
            local content = ""
            for _, value in ipairs(elements) do
                content = content .. exportToString(value, "", indent + 1)
            end

            return string ..
                indentation ..
                "union()(\n" .. content .. indentation .. ");\n"
        end
    }
end

Solid = Solid .. {
    exportToString = exportToString
}

return {
    cube = function(args)
        if args.center == nil then
            args.center = false
        end
        return Solid.Cube(args[1], args.center)
    end,
    union = function(args)
        return Solid.Union(args)
    end,
    test = function()
    end,
}

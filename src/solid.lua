local Union = require("union-types")

local Solid = Union.Type {
    Cube = { "dimensions", "center" },
    Cylinder = { "diameter", "height", "center" },
    Literal = { "value" },
    Union = { "solids" },
    Difference = { "solids" },
    Translate = { "vector", "solid" },
}

local function exportToString(solid, string, indent)
    local operation = function(name)
        return function(elements)
            local indentation = string.rep("    ", indent)
            local content = ""
            for _, value in ipairs(elements) do
                content = content .. exportToString(value, "", indent + 1)
            end

            return string ..
                indentation
                .. name .. "(){\n" .. content .. indentation .. "};\n"
        end
    end
    local transform = function(name)
        return function(vector, element)
            local indentation = string.rep("    ", indent)
            return string ..
                indentation ..
                string.format("%s([%i, %i, %i]) %s;\n", name, vector[1], vector[2], vector[3],
                    exportToString(element, "", indent))
        end
    end


    if string == nil then
        string = ""
    end

    if indent == nil then
        indent = 0
    end

    -- TODO: optimize with tail call
    return Union.match(solid) {
        Cylinder = function(diameter, height, center)
            return string ..
                (string.rep("    ", indent)) ..
                string.format("cylinder(d=%s, h=%s, center=%s);\n", diameter, height, tostring(center))
        end,
        Cube = function(dimensions, center)
            return string ..
                (string.rep("    ", indent)) ..
                "cube([" ..
                tostring(dimensions[1]) ..
                ", " ..
                tostring(dimensions[2]) ..
                ", " .. tostring(dimensions[3]) .. "], center=" .. tostring(center) .. ");\n"
        end,
        Literal = function(value)
            return string .. value
        end,
        Union = operation("union"),
        Difference = operation("difference"),
        Translate = transform("translate"),
    }
end

local function exportToFile(solid, path)
    local file = io.open(path, "w")
    assert(file ~= nil, "Could not open " .. path)
    file:write(exportToString(solid, "", 0))
    file:close()
end

return {
    cube = function(args)
        if args.center == nil then
            args.center = false
        end
        return Solid.Cube(args[1], args.center)
    end,
    cylinder = function(args)
        if args.center == nil then
            args.center = false
        end
        assert(args.diameter ~= nil, "Diameter required")
        assert(args.height ~= nil, "Height required")
        return Solid.Cylinder(args.diameter, args.height, args.center)
    end,
    union = function(args)
        return Solid.Union(args)
    end,
    difference = function(args)
        return Solid.Difference(args)
    end,
    translate = function(vector, solid)
        return Solid.Translate(vector, solid)
    end,
    literal = Solid.Literal,
    test = function()
    end,
    exportToString = function(solid)
        return exportToString(solid, "", 0)
    end,
    exportToFile = exportToFile,
}

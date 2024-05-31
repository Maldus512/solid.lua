local Union = require("union-types")

---@alias Cube {}
---@alias Cylinder {}
---@alias Literal {}
---@alias Operation {}
---@alias Transform {}
---@alias Solid Cube | Cylinder | Literal | Operation | Transform | Solid
local Solid = Union.Type {
    Cube = { "dimensions", "center" },
    Cylinder = { "diameter", "height", "center" },
    Sphere = { "diameter" },
    Literal = { "value" },
    Operation = { "name", "solids" },
    Transform = { "name", "vector", "solid" },
}

local exportToString
---@param solid Solid
---@param string string
---@param indent number
---@return string
exportToString = function(solid, string, indent)
    local operation = function(name, elements)
        local indentation = string.rep("    ", indent)
        local content = ""
        for _, value in ipairs(elements) do
            content = content .. exportToString(value, "", indent + 1)
        end

        return string ..
            indentation
            .. name .. "(){\n" .. content .. indentation .. "};\n"
    end
    local transform = function(name, vector, element)
        local indentation = string.rep("    ", indent)
        return string ..
            indentation ..
            string.format("%s([%f, %f, %f]) %s;\n", name, vector[1], vector[2], vector[3],
                exportToString(element, "", indent))
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
        Sphere = function(diameter)
            return string ..
                (string.rep("    ", indent)) ..
                string.format("sphere(d=%s);\n", diameter)
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
        Operation = operation,
        Transform = transform,
    }
end

local exportToFile = function(solid, path)
    local file = io.open(path, "w")
    assert(file ~= nil, "Could not open " .. path)
    file:write(exportToString(solid, "", 0))
    file:close()
end

local union = function(args)
    return Solid.Operation("union", args)
end

local difference = function(args)
    return Solid.Operation("difference", args)
end

local intersection = function(args)
    return Solid.Operation("intersection", args)
end

local minkowski = function(args)
    return Solid.Operation("minkowski", args)
end

local translate = function(vector, solid)
    return Solid.Transform("translate", vector, solid)
end

setmetatable(Solid, {
    __add = function(t1, t2)
        return union { t1, t2 }
    end,
    __sub = function(t1, t2)
        return difference { t1, t2 }
    end,
    __mul = function(t1, t2)
        return minkowski { t1, t2 }
    end,
    __shr = function(t1, t2)
        return translate(t2, t1)
    end
})

---@class Module
---@field cube fun(args : {[1] : number[], center: boolean}): Solid

---@type Module
return {
    cube = function(args)
        if args.center == nil then
            args.center = false
        end
        return Solid.Cube(args[1], args.center)
    end,

    ---@return Solid
    cylinder = function(args)
        if args.center == nil then
            args.center = false
        end
        assert(args.diameter ~= nil, "Diameter required")
        assert(args.height ~= nil, "Height required")
        return Solid.Cylinder(args.diameter, args.height, args.center)
    end,

    ---@return Solid
    sphere = function(args)
        assert(args.diameter ~= nil or args.radius ~= nil, "Diameter or radius required")
        return Solid.Sphere(args.diameter or args.radius * 2)
    end,

    ---@return Solid
    union = union,

    ---@return Solid
    difference = difference,

    ---@return Solid
    intersection = intersection,

    ---@return Solid
    minkowski = minkowski,

    ---@return Solid
    translate = translate,

    ---@return Solid
    rotate = function(vector, solid) return Solid.Transform("rotate", vector, solid) end,

    ---@return Solid
    scale = function(vector, solid) return Solid.Transform("scale", vector, solid) end,

    ---@return Solid
    literal = Solid.Literal,

    test = function()
    end,

    exportToString = function(solid)
        return exportToString(solid, "", 0)
    end,
    exportToFile = exportToFile,
}

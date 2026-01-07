---@diagnostic disable: redefined-local

---@meta
---@alias Vector number[]

---@alias Cube { Cube : { dimensions: Vector, center: boolean } }
---@alias Cylinder { Cylinder : { radius: number, height: number, center: boolean } }
---@alias Sphere { Sphere : { radius: number } }
---@alias Literal { Literal: string }
---@alias Operation { Operation : { name: string, solids : Solid[] } }
---@alias Transform { Transform : { name: string, vector: Vector, solid: Solid} }
---@alias Solid Cube | Cylinder | Literal | Sphere | Operation | Transform | Solid

local defaultCenter = false

local match = function(variant)
    return function(branches)
        for k, v in pairs(branches) do
            if variant[k] ~= nil then
                v(variant[k])
                return
            end
        end

        if branches._ ~= nil then
            for _, v in pairs(variant) do
                branches._(v)
                return
            end
        end

        assert(false, "Non exahustive pattern matching")
    end
end

local indentation = function(n)
    return string.rep("    ", n)
end

local exportToString = function(solid)
    ---@type ({solid : Solid, indent: number} |  string)[]
    local stack = {}
    local indent = 0

    local addIndented = function(value, base)
        if base then
            table.insert(stack, base, indentation(indent) .. value)
        else
            table.insert(stack, indentation(indent) .. value)
        end
    end

    local operation = function(args)
        local stackBase = #stack + 1

        addIndented(args.name .. "() {\n", stackBase)
        for _, value in ipairs(args.solids) do
            table.insert(stack, stackBase, { solid = value, indent = indent + 1 })
            table.insert(stack, stackBase, ";\n")
        end
        addIndented("}", stackBase)
    end
    local transform = function(args)
        table.insert(stack, { solid = args.solid, indent = indent + 1 })
        addIndented(string.format("%s([%f, %f, %f])\n", args.name, args.vector[1], args.vector[2], args.vector[3]))
    end

    table.insert(stack, ";")
    table.insert(stack, { solid = solid, indent = 0 })
    local result = ""

    while #stack > 0 do
        local block = table.remove(stack)

        if type(block) == "string" then
            result = result .. block
        else
            indent = block.indent

            match(block.solid) {
                Cylinder = function(args)
                    addIndented(string.format("cylinder(r=%s, h=%s, center=%s)", args.radius, args.height,
                        tostring(args.center)))
                end,
                Sphere = function(diameter)
                    addIndented(string.format("sphere(d=%s)", diameter))
                end,
                Cube = function(args)
                    addIndented("cube([" ..
                        tostring(args.dimensions[1]) ..
                        ", " ..
                        tostring(args.dimensions[2]) ..
                        ", " .. tostring(args.dimensions[3]) .. "], center=" .. tostring(args.center) .. ")")
                end,
                Literal = function(value)
                    addIndented(value)
                end,
                Operation = operation,
                Transform = transform,
            }
        end
    end

    return result
end

local exportToFile = function(solid, path)
    local file = io.open(path, "w")
    assert(file ~= nil, "Could not open " .. path)
    file:write(exportToString(solid))
    file:close()
end

local metaSolid

local newOperation = function(name, solids)
    return metaSolid({ Operation = { name = name, solids = solids } })
end

local newTransform = function(name, vector, solid)
    assert(type(vector) == "table", "Vector must be an array, not " .. type(vector))
    assert(type(vector[1]) == "number", "Vector[1] must be a number, not " .. type(vector[1]))
    assert(type(vector[1]) == "number", "Vector[1] must be a number, not " .. type(vector[2]))
    assert(type(vector[1]) == "number", "Vector[1] must be a number, not " .. type(vector[3]))

    return metaSolid({ Transform = { name = name, vector = vector, solid = solid } })
end

local createVector = function(arg)
    if type(arg) == "number" then
        return { arg, arg, arg }
    elseif type(arg) == "table" then
        if #arg > 0 then
            arg[2] = arg[2] or 0
            arg[3] = arg[3] or 0
            return arg
        elseif arg.x or arg.y or arg.z then
            return { arg.x or 0, arg.y or 0, arg.z or 0 }
        else
            error("Vector must be a number, a number array with at least 1 element, or a table with either x, y or z")
        end
    else
        error("Vector must be a number, a number array with at least 1 element, or a table with either x, y or z")
    end
end

local union = function(args)
    return newOperation("union", args)
end

local difference = function(args)
    return newOperation("difference", args)
end

local intersection = function(args)
    return newOperation("intersection", args)
end

local minkowski = function(args)
    return newOperation("minkowski", args)
end

local scale = function(vector, solid) return newTransform("scale", vector, solid) end

local translate = function(vector, solid)
    return newTransform("translate", createVector(vector), solid)
end

---@return Solid
local rotate = function(solid, vector) return newTransform("rotate", vector, solid) end
---@return Solid
local mirror = function(solid, vector) return newTransform("mirror", vector, solid) end

metaSolid = function(target)
    target.add = function(self, solid)
        return union { self, solid }
    end

    target.sub = function(self, solid)
        return difference { self, solid }
    end

    target.rotate = function(self, vector)
        return rotate(self, vector)
    end

    target.mirror = function(self, vector)
        return mirror(self, vector)
    end

    return setmetatable(target, {
        __add = function(t1, t2)
            return union { t1, t2 }
        end,
        __sub = function(t1, t2)
            return difference { t1, t2 }
        end,
        __mul = function(t1, t2)
            if type(t2) == "number" then
                return scale({ t2, t2, t2 }, t1)
            else
                return scale({ t2[1] or 1, t2[2] or 1, t2[3] or 1 }, t1)
            end
        end,
        __shr = function(t1, t2)
            return translate(t2, t1)
        end
    })
end

---@class Module

---@type Module
return {
    ---@param args {[1] : (number[]|number)?, dimensions: (number[]|number)?, center: boolean} | number[] | number
    ---@return Solid
    cube = function(args)
        if type(args) == "number" then
            metaSolid { Cube = { dimensions = createVector(args), center = defaultCenter } }
        elseif #args > 1 then
            args.center = args.center or defaultCenter
            args.dimensions = createVector(args)
            return metaSolid { Cube = args }
        elseif args.dimensions or args[1] then
            args.center = args.center or defaultCenter
            args.dimensions = createVector(args.dimensions or args[1])
            return metaSolid { Cube = args }
        else
            return metaSolid { Cube = { dimensions = createVector(args), center = defaultCenter } }
        end
    end,
    ---@return Solid
    cylinder = function(args)
        assert(args.diameter ~= nil or args.radius ~= nil, "Either radius or diameter required")
        assert(args.diameter == nil or args.radius == nil, "Only radius or diameter required")
        assert(args.height ~= nil, "Height required")
        return metaSolid { Cylinder = {
            height = args.height,
            radius = args.radius or args.diameter / 2,
            center = args.center or defaultCenter,
        } }
    end,
    ---@return Solid
    sphere = function(args)
        assert(args.diameter ~= nil or args.radius ~= nil, "Diameter or radius required")
        return metaSolid { Sphere = args.diameter or args.radius * 2 }
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
    hull = function(args)
        return newOperation("hull", args)
    end,
    ---@return Solid
    translate = translate,
    ---@return Solid
    rotate = rotate,
    ---@return Solid
    mirror = mirror,
    ---@return Solid
    scale = scale,
    ---@return Solid
    literal = function(value)
        return metaSolid { Literal = value }
    end,
    exportToString = exportToString,
    exportToFile = exportToFile,
    defaultCenter = function(self, default)
        defaultCenter = default
        return self
    end,
    test = function()
    end,
}

---@diagnostic disable: redefined-local

---@alias Vector number[]

---@alias Cube { Cube = { dimensions: Vector, center: boolean } }
---@alias Cylinder { Cylinder = { radius: number, height: number, center: boolean } }
---@alias Sphere { Sphere = { radius: number } }
---@alias Literal { Literal: string }
---@alias Operation { Operation = { name: string, solids : Solid[] } }
---@alias Transform { Transform = { name: string, vector: Vector, solid: Solid} }
---@alias Solid Cube | Cylinder | Literal | Sphere | Operation | Transform | Solid

local Operation = function(name, solids) 
    return { Operation = { name = name, solids = solids } }
end

local indentation = function(n)
    return string.rep("    ", n)
end

local exportToString
---@param solid Solid
---@return string
exportToString = function(solid)
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

    local operation = function(name, elements)
        local stackBase = #stack + 1

        addIndented(name .. "() {\n", stackBase)
        for _, value in ipairs(elements) do
            table.insert(stack, stackBase, { solid = value, indent = indent + 1 })
            table.insert(stack, stackBase, ";\n")
        end
        addIndented("}", stackBase)
    end
    local transform = function(name, vector, element)
        table.insert(stack, { solid = element, indent = indent + 1 })
        addIndented(string.format("%s([%f, %f, %f])\n", name, vector[1], vector[2], vector[3]))
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

            Union.match(block.solid) {
                Cylinder = function(diameter, height, center)
                    addIndented(string.format("cylinder(d=%s, h=%s, center=%s)", diameter, height, tostring(center)))
                end,
                Sphere = function(diameter)
                    addIndented(string.format("sphere(d=%s)", diameter))
                end,
                Cube = function(dimensions, center)
                    addIndented("cube([" ..
                        tostring(dimensions[1]) ..
                        ", " ..
                        tostring(dimensions[2]) ..
                        ", " .. tostring(dimensions[3]) .. "], center=" .. tostring(center) .. ")")
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

local union = function(args)
    return Operation("union", args)
end

local difference = function(args)
    return Operation("difference", args)
end

local intersection = function(args)
    return Operation("intersection", args)
end

local minkowski = function(args)
    return Operation("minkowski", args)
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
        return exportToString(solid, 0)
    end,
    exportToFile = exportToFile,
}

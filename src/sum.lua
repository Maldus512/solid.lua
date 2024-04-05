local first_to_upper = function(str)
    return (str:gsub("^%l", string.upper))
end

local LUAVER = tonumber(_VERSION:match("Lua (%d.%d)"))

local length = (function()
    if LUAVER > 5.1 then
        return function(t) return #t end
    else
        return table.getn
    end
end)()

local unpack_table = (function()
    if LUAVER > 5.1 then
        return table.unpack
    else
        return unpack
    end
end)()

local build_variant = function(name, parameters, additionalFields)
    local num_parameters = 0
    if parameters ~= nil then
        num_parameters = length(parameters)
    end

    local unique = {}

    return setmetatable(unique, {
        __call =
            function(_, ...)
                local args = { ... }
                if length(args) ~= num_parameters then
                    error("Enum variant " ..
                        first_to_upper(name) .. " requires " .. tostring(num_parameters) .. " parameters")
                else
                    local variant = {}

                    for i, actual in ipairs(args) do
                        variant[parameters[i]] = actual
                    end

                    variant.is = function(_, variant_type)
                        return variant_type == unique
                    end

                    variant.oneOf = function(_, variant_types)
                        for _, variant_type in ipairs(variant_types) do
                            if variant:is(variant_type) then
                                return true
                            end
                        end
                        return false
                    end

                    variant.match = function(self, branches)
                        if branches[name] ~= nil then
                            return branches[name](unpack_table(args))
                        elseif branches._ ~= nil then
                            return branches._(self)
                        else
                            error("Non exhaustive pattern matching")
                        end
                    end

                    return setmetatable(variant, {
                        __index = function(_, key)
                            return additionalFields[key]
                        end
                    })
                end
            end
    })
end

return {
    Type = function(variants)
        assert(type(variants) == "table", "Invalid argument for building a closed sum type: " .. type(variants))
        assert(variants.match == nil, "Key 'match' is reserved, please avoid it")
        assert(variants.match == nil, "Key 'is' is reserved, please avoid it")

        local additionalFieldsMetaTable = {}
        local Variants = {}
        for name, arguments in pairs(variants) do
            Variants[name] = build_variant(name, arguments, additionalFieldsMetaTable)
        end

        return setmetatable(Variants, {
            __concat = function(self, addition)
                for k, v in pairs(addition) do
                    additionalFieldsMetaTable[k] = v
                end
                return self
            end
        })
    end,
    test = function(self)
        local Option
        Option = self.Type {
                Some = { "value" },
                None = {},
            } .. {
                isEmpty = function(variant)
                    variant:is(Option.None)
                end
            }

        local some = Option.Some("Hello")
        local none = Option.None()

        assert(some:is(Option.Some), "Wrong variant!")
        assert(some.value == "Hello")
        assert(not some:isEmpty(), "Wrong variant!")
        some:match {
            None = function() error "Wrong variant!" end,
            Some = function(value) assert(value == "Hello") end
        }

        assert(none:is(Option.None), "Wrong variant!")
        --assert(none:isEmpty(), "Wrong variant!")
        none:match {
            Some = function(_) error "Wrong variant!" end,
            _ = function(_)
            end,
        }

        print("sum module tests successful!")
    end
}

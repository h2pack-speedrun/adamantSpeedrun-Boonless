local support = {}

function support.assertEqual(actual, expected)
    if actual ~= expected then
        error(string.format("expected %q, got %q", tostring(expected), tostring(actual)), 2)
    end
end

function support.withImport(callback)
    local previousImport = _G.import
    _G.import = function(path)
        return assert(loadfile("src/" .. path))()
    end

    local ok, result = pcall(callback)
    _G.import = previousImport

    if not ok then
        error(result, 2)
    end
    return result
end

function support.loadBehaviors()
    return support.withImport(function()
        return assert(loadfile("src/behaviors.lua"))()
    end)
end

function support.createUiState(values)
    return {
        get = function(alias)
            return {
                alias = alias,
                read = function()
                    return values[alias]
                end,
                write = function(_, value)
                    values[alias] = value
                    return true
                end,
            }
        end,
    }
end

return support

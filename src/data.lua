local PACK_ID = "speedrun"
local PRESET_ALIAS = "Preset"

local data = {}

function data.buildStorage(options)
    local storage = {
        {
            type = "string",
            alias = PRESET_ALIAS,
            default = "custom",
            maxLen = 32,
            persist = false,
            hash = false,
        },
    }
    for _, option in ipairs(options) do
        if option.type == "checkbox" then
            table.insert(storage, {
                type = "bool",
                alias = option.alias,
                default = option.default == true,
            })
        else
            error(("Unsupported option type '%s' in %s"):format(tostring(option.type), PACK_ID .. ".Boonless"))
        end
    end
    return storage
end

return data

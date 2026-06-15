local behaviors = {
    hooks = {},
    options = {},
}

local function appendOptions(behavior)
    if behavior.option then
        table.insert(behaviors.options, behavior.option)
    end
    for _, option in ipairs(behavior.options or {}) do
        table.insert(behaviors.options, option)
    end
end

local function register(path)
    local behavior = import(path)
    appendOptions(behavior)
    for _, hook in ipairs(behavior.hooks or {}) do
        table.insert(behaviors.hooks, hook)
    end
end

register("behaviors/VowRewardSkip.lua")
register("behaviors/SpecialBoonFallbacks.lua")

return behaviors

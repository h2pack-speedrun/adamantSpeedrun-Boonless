return {
    option = {
        type = "checkbox",
        alias = "UnlimitedBoonSkips",
        label = "Unlimited Vow of Forfeit",
        default = false,
        tooltip = "Keeps Vow of Forfeit active for every eligible boon reward in a biome.",
    },
    hooks = {
        function(module)
            module.hooks.wrap("CheckBoonSkipShrineUpgrade", function(host, runtime, baseFunc, source, args)
                if not runtime.data.read("UnlimitedBoonSkips") or not host.isEnabled() then
                    return baseFunc(source, args)
                end

                local previousSkipCount = CurrentRun and CurrentRun.BiomeBoonSkipCount
                local reward = baseFunc(source, args)

                if reward ~= nil and previousSkipCount ~= nil and CurrentRun then
                    CurrentRun.BiomeBoonSkipCount = previousSkipCount
                end

                return reward
            end)
        end,
    },
}

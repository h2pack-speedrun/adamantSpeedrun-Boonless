local BOON_VOW_ALIAS = "BoonVowSkips"
local HAMMER_VOW_ALIAS = "HammerVowSkips"
local HEX_VOW_ALIAS = "HexVowSkips"

local VOW_SKIP_REWARD_TYPES = {
    SpellDrop = HEX_VOW_ALIAS,
    WeaponUpgrade = HAMMER_VOW_ALIAS,
}

local function getRewardType(args)
    args = args or {}
    local currentRoom = CurrentRun.CurrentRoom
    local currentEncounter = currentRoom.Encounter or {}
    return args.RewardOverride
        or currentEncounter.EncounterRoomRewardOverride
        or currentRoom.ChangeReward
        or currentRoom.ChosenRewardType
end

local function hasAvailableBoonSkip()
    return GetNumShrineUpgrades("BoonSkipShrineUpgrade") > CurrentRun.BiomeBoonSkipCount
end

local function copyArgs(args)
    local result = {}
    for key, value in pairs(args or {}) do
        result[key] = value
    end
    return result
end

return {
    hooks = {
        function(module)
            module.hooks.wrap("CheckBoonSkipShrineUpgrade", function(host, runtime, baseFunc, source, args)
                if not runtime.data.read(BOON_VOW_ALIAS) or not host.isEnabled() then
                    return baseFunc(source, args)
                end

                local previousSkipCount = CurrentRun and CurrentRun.BiomeBoonSkipCount
                local reward = baseFunc(source, args)

                if reward ~= nil and previousSkipCount ~= nil and CurrentRun then
                    CurrentRun.BiomeBoonSkipCount = previousSkipCount
                end

                return reward
            end)

            module.hooks.wrap("SpawnRoomReward", function(host, runtime, baseFunc, eventSource, args)
                if not host.isEnabled() then
                    return baseFunc(eventSource, args)
                end
                local skipAlias = VOW_SKIP_REWARD_TYPES[getRewardType(args)]
                if skipAlias == nil or not runtime.data.read(skipAlias) or not hasAvailableBoonSkip() then
                    return baseFunc(eventSource, args)
                end

                local previousSkipCount = CurrentRun and CurrentRun.BiomeBoonSkipCount
                local overrideArgs = copyArgs(args)
                overrideArgs.RewardOverride = "Boon"
                overrideArgs.LootName = nil
                local reward = baseFunc(eventSource, overrideArgs)

                if reward ~= nil and previousSkipCount ~= nil and CurrentRun then
                    CurrentRun.BiomeBoonSkipCount = previousSkipCount
                end

                return reward
            end)
        end,
    },
}

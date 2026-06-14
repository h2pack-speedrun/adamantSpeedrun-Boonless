local BOON_OFFERS_ALIAS = "BoonOffersToSharedWealth"

local providers = {
    {
        alias = BOON_OFFERS_ALIAS,
        label = "Boon Offers to Shared Wealth",
        tooltip = "Makes normal god and Hermes boon offers fall back to Shared Wealth.",
    },
    {
        alias = "WeaponUpgradesToSharedWealth",
        label = "Weapon Upgrades to Shared Wealth",
        lootName = "WeaponUpgrade",
        tooltip = "Makes Daedalus Hammer offers fall back to Shared Wealth.",
    },
    {
        alias = "ChaosToSharedWealth",
        label = "Chaos to Shared Wealth",
        lootName = "TrialUpgrade",
        tooltip = "Makes Chaos offers fall back to Shared Wealth instead of curses and blessings.",
    },
    {
        alias = "ArtemisToSharedWealth",
        label = "Artemis to Shared Wealth",
        lootName = "NPC_Artemis_Field_01",
        tooltip = "Makes Artemis field offers fall back to Shared Wealth.",
    },
    {
        alias = "AthenaToSharedWealth",
        label = "Athena to Shared Wealth",
        lootName = "NPC_Athena_01",
        tooltip = "Makes Athena offers fall back to Shared Wealth.",
    },
    {
        alias = "ArachneToSharedWealth",
        label = "Arachne to Shared Wealth",
        lootName = "NPC_Arachne_01",
        tooltip = "Makes Arachne offers fall back to Shared Wealth.",
    },
    {
        alias = "NarcissusToSharedWealth",
        label = "Narcissus to Shared Wealth",
        lootName = "NPC_Narcissus_01",
        tooltip = "Makes Narcissus offers fall back to Shared Wealth.",
    },
    {
        alias = "EchoToSharedWealth",
        label = "Echo to Shared Wealth",
        lootName = "NPC_Echo_01",
        tooltip = "Makes Echo offers fall back to Shared Wealth.",
    },
    {
        alias = "HadesToSharedWealth",
        label = "Hades to Shared Wealth",
        lootName = "NPC_Hades_Field_01",
        tooltip = "Makes Hades offers fall back to Shared Wealth.",
    },
    {
        alias = "MedeaToSharedWealth",
        label = "Medea to Shared Wealth",
        lootName = "NPC_Medea_01",
        tooltip = "Makes Medea offers fall back to Shared Wealth.",
    },
    {
        alias = "CirceToSharedWealth",
        label = "Circe to Shared Wealth",
        lootName = "NPC_Circe_01",
        tooltip = "Makes Circe offers fall back to Shared Wealth.",
    },
    {
        alias = "IcarusToSharedWealth",
        label = "Icarus to Shared Wealth",
        lootName = "NPC_Icarus_01",
        tooltip = "Makes Icarus offers fall back to Shared Wealth.",
    },
    {
        alias = "DionysusToSharedWealth",
        label = "Dionysus to Shared Wealth",
        lootName = "NPC_Dionysus_01",
        tooltip = "Makes Dionysus offers fall back to Shared Wealth.",
    },
}

local aliasByLootName = {}
local options = {}

for _, provider in ipairs(providers) do
    if provider.lootName then
        aliasByLootName[provider.lootName] = provider.alias
    end
    table.insert(options, {
        type = "checkbox",
        alias = provider.alias,
        label = provider.label,
        default = false,
        tooltip = provider.tooltip,
    })
end

local function isBoonOffer(lootData)
    return lootData.GodLoot == true or lootData.Name == "HermesUpgrade"
end

local function shouldUseFallback(runtime, lootData)
    if lootData == nil then
        return false
    end
    if runtime.data.read(BOON_OFFERS_ALIAS) and isBoonOffer(lootData) then
        return true
    end

    local alias = aliasByLootName[lootData.Name]
    return alias ~= nil and runtime.data.read(alias)
end

return {
    options = options,
    hooks = {
        function(module)
            module.hooks.wrap("SetTraitsOnLoot", function(host, runtime, baseFunc, lootData, args)
                local result = baseFunc(lootData, args)

                if host.isEnabled() and shouldUseFallback(runtime, lootData) then
                    lootData.UpgradeOptions = {}
                    lootData.BlockReroll = true
                end

                return result
            end)
        end,
    },
}

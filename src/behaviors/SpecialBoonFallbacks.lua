local BOON_OFFERS_ALIAS = "BoonOffersToSharedWealth"
local SELENE_ALIAS = "SeleneToSharedWealth"
local SPELL_DROP_NAME = "SpellDrop"
local BOON_VOW_ALIAS = "BoonVowSkips"
local HAMMER_VOW_ALIAS = "HammerVowSkips"
local HEX_VOW_ALIAS = "HexVowSkips"

local providers = {
    {
        alias = BOON_OFFERS_ALIAS,
        label = "Boon Offers to Shared Wealth",
        tooltip = "Makes normal god and Hermes boon offers fall back to Shared Wealth.",
        extraOptions = {
            {
                alias = BOON_VOW_ALIAS,
                label = "Onion Boons",
                tooltip = "Keeps Vow of Forfeit active for normal god and Hermes boon room rewards.",
            },
        },
    },
    {
        alias = "WeaponUpgradesToSharedWealth",
        label = "Hammers to Shared Wealth",
        lootName = "WeaponUpgrade",
        tooltip = "Makes Daedalus Hammer offers fall back to Shared Wealth.",
        extraOptions = {
            {
                alias = HAMMER_VOW_ALIAS,
                label = "Onion Hammers",
                tooltip = "Lets Vow of Forfeit skip Daedalus Hammer room rewards.",
            },
        },
    },
    {
        alias = SELENE_ALIAS,
        label = "Selene to Shared Wealth",
        lootName = SPELL_DROP_NAME,
        tooltip = "Makes Selene Hex offers fall back to Shared Wealth instead of opening Path of Stars.",
        extraOptions = {
            {
                alias = HEX_VOW_ALIAS,
                label = "Onion Hexes",
                tooltip = "Lets Vow of Forfeit skip Selene Hex room rewards.",
            },
        },
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

local directChoiceFallbacks = {
    {
        functionName = "ArachneCostumeChoice",
        alias = "ArachneToSharedWealth",
    },
    {
        functionName = "NarcissusBenefitChoice",
        alias = "NarcissusToSharedWealth",
    },
    {
        functionName = "EchoChoice",
        alias = "EchoToSharedWealth",
    },
    {
        functionName = "MedeaCurseChoice",
        alias = "MedeaToSharedWealth",
    },
    {
        functionName = "CirceBlessingChoice",
        alias = "CirceToSharedWealth",
    },
    {
        functionName = "IcarusBenefitChoice",
        alias = "IcarusToSharedWealth",
    },
}
local directChoiceFallbackDepth = 0

local function appendOption(option)
    table.insert(options, {
        type = "checkbox",
        alias = option.alias,
        label = option.label,
        default = option.default == true,
        tooltip = option.tooltip,
    })
end

for _, provider in ipairs(providers) do
    if provider.lootName then
        aliasByLootName[provider.lootName] = provider.alias
    end
    appendOption(provider)
    for _, extraOption in ipairs(provider.extraOptions or {}) do
        appendOption(extraOption)
    end
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

local function shouldUseSeleneFallback(host, runtime, spellItem)
    return host.isEnabled()
        and spellItem ~= nil
        and spellItem.Name == SPELL_DROP_NAME
        and runtime.data.read(SELENE_ALIAS)
end

local function chargeSpellDropIfNeeded(spellItem, args)
    if spellItem.ResourceCosts ~= nil and not HasResources(spellItem.ResourceCosts) then
        CantAffordPresentation(spellItem)
        return false
    end
    if args.PackageName then
        LoadPackages({ Name = args.PackageName })
    end
    if HasResourceCost(spellItem.ResourceCosts) then
        spellItem.Purchased = true
        SpendResources(spellItem.ResourceCosts, spellItem.Name or "Loot")
        RemoveStoreItem({ Id = spellItem.ObjectId, Name = spellItem.Name, ScreenName = UIData.SpellMenuId })
        if (spellItem.ResourceCosts.Money or 0) > 0 then
            HandleCharonPurchase("UseLoot", spellItem.ResourceCosts.Money)
        end
        PlaySound({ Name = "/Leftovers/Menu Sounds/StoreBuyingItem" })
        thread(PlayVoiceLines, GlobalVoiceLines.PurchasedConsumableVoiceLines, true)
    end
    return true
end

local function prepareSeleneFallback(spellItem)
    spellItem.UpgradeOptions = {}
    spellItem.BlockReroll = true
    spellItem.DestroyOnPickup = true
    spellItem.PostPickupFunctionName = spellItem.PostPickupFunctionName or "SpellDropInteractPresentationEnd"
    spellItem.MenuTitle = spellItem.MenuTitle or spellItem.BoonInfoTitleText or spellItem.SurfaceShopText or spellItem.Name
    if spellItem.BackgroundAnimation == nil and spellItem.NarrativeContextArt ~= nil then
        spellItem.BackgroundAnimation = spellItem.NarrativeContextArt .. "_In"
    end
end

local function createSafeDirectChoiceOptions()
    return {
        { Type = "Trait", ItemName = "FallbackGold" },
        { Type = "Trait", ItemName = "FallbackGold" },
        { Type = "Trait", ItemName = "FallbackGold" },
    }
end

local function copyArgsWithSafeDirectChoiceOptions(args)
    local result = {}
    for key, value in pairs(args or {}) do
        result[key] = value
    end
    result.UpgradeOptions = createSafeDirectChoiceOptions()
    return result
end

local function runWithDirectChoiceFallback(baseFunc, source, args, screen)
    directChoiceFallbackDepth = directChoiceFallbackDepth + 1
    local result = baseFunc(source, copyArgsWithSafeDirectChoiceOptions(args), screen)
    directChoiceFallbackDepth = directChoiceFallbackDepth - 1
    return result
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

            module.hooks.wrap("OpenSpellScreen", function(host, runtime, baseFunc, spellItem, args, user)
                args = args or {}
                if not shouldUseSeleneFallback(host, runtime, spellItem) then
                    return baseFunc(spellItem, args, user)
                end
                if not chargeSpellDropIfNeeded(spellItem, args) then
                    return nil
                end

                prepareSeleneFallback(spellItem)
                return HandleLootPickup(CurrentRun, spellItem, args)
            end)

            module.hooks.wrap("OpenUpgradeChoiceMenu", function(host, runtime, baseFunc, source, args)
                if directChoiceFallbackDepth > 0 then
                    source.UpgradeOptions = {}
                    source.BlockReroll = true
                end
                return baseFunc(source, args)
            end)

            for _, fallback in ipairs(directChoiceFallbacks) do
                module.hooks.wrap(fallback.functionName, function(host, runtime, baseFunc, source, args, screen)
                    if host.isEnabled() and runtime.data.read(fallback.alias) then
                        return runWithDirectChoiceFallback(baseFunc, source, args, screen)
                    end
                    return baseFunc(source, args, screen)
                end)
            end
        end,
    },
}

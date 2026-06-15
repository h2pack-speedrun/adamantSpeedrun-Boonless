local support = dofile("tests/support.lua")
local assertEqual = support.assertEqual

local behaviors = support.loadBehaviors()

local hooks = {}
for _, registerHook in ipairs(behaviors.hooks) do
    registerHook({
        hooks = {
            wrap = function(name, callback)
                hooks[name] = callback
            end,
        },
    })
end

local optionAliases = {}
for _, option in ipairs(behaviors.options) do
    optionAliases[option.alias] = true
end
local expectedTopAliases = {
    "BoonOffersToSharedWealth",
    "BoonVowSkips",
    "WeaponUpgradesToSharedWealth",
    "HammerVowSkips",
    "SeleneToSharedWealth",
    "HexVowSkips",
}
for index, alias in ipairs(expectedTopAliases) do
    assertEqual(behaviors.options[index].alias, alias)
end
assertEqual(optionAliases.BoonVowSkips, true)
assertEqual(optionAliases.HammerVowSkips, true)
assertEqual(optionAliases.HexVowSkips, true)
assertEqual(optionAliases.SeleneToSharedWealth, true)

local host = {
    isEnabled = function()
        return true
    end,
}

local enabledAliases = {
    BoonVowSkips = true,
    HammerVowSkips = true,
    HexVowSkips = true,
    SeleneToSharedWealth = true,
}

local runtime = {
    data = {
        read = function(alias)
            return enabledAliases[alias] == true
        end,
    },
}

local function runDirectChoiceFallbackTest(functionName, alias)
    enabledAliases[alias] = true
    local originalArgs = {
        UpgradeOptions = {
            { ItemName = "OriginalGift" },
        },
        KeepMe = true,
    }
    local forwardedArgs
    local menuSource
    local menuArgs
    hooks[functionName](host, runtime, function(source, args)
        forwardedArgs = args
        for i = 1, 3 do
            assertEqual(args.UpgradeOptions[i].ItemName, "FallbackGold")
        end
        source.UpgradeOptions = args.UpgradeOptions
        return hooks.OpenUpgradeChoiceMenu(host, runtime, function(openSource, openArgs)
            menuSource = openSource
            menuArgs = openArgs
            return "fallback"
        end, source, args)
    end, {}, originalArgs, {})
    assertEqual(forwardedArgs ~= originalArgs, true)
    assertEqual(#forwardedArgs.UpgradeOptions, 3)
    assertEqual(forwardedArgs.KeepMe, true)
    assertEqual(#menuSource.UpgradeOptions, 0)
    assertEqual(menuSource.BlockReroll, true)
    assertEqual(menuArgs, forwardedArgs)

    enabledAliases[alias] = false
    menuSource = nil
    menuArgs = nil
    hooks[functionName](host, runtime, function(source, args)
        forwardedArgs = args
        source.UpgradeOptions = args.UpgradeOptions
        return hooks.OpenUpgradeChoiceMenu(host, runtime, function(openSource, openArgs)
            menuSource = openSource
            menuArgs = openArgs
            return "base"
        end, source, args)
    end, {}, originalArgs, {})
    assertEqual(forwardedArgs, originalArgs)
    assertEqual(menuArgs, originalArgs)
    assertEqual(#menuSource.UpgradeOptions, 1)
end

runDirectChoiceFallbackTest("ArachneCostumeChoice", "ArachneToSharedWealth")
runDirectChoiceFallbackTest("NarcissusBenefitChoice", "NarcissusToSharedWealth")
runDirectChoiceFallbackTest("EchoChoice", "EchoToSharedWealth")
runDirectChoiceFallbackTest("MedeaCurseChoice", "MedeaToSharedWealth")
runDirectChoiceFallbackTest("CirceBlessingChoice", "CirceToSharedWealth")
runDirectChoiceFallbackTest("IcarusBenefitChoice", "IcarusToSharedWealth")

local oldCurrentRun = _G.CurrentRun
local oldHasResources = _G.HasResources
local oldHasResourceCost = _G.HasResourceCost
local oldHandleLootPickup = _G.HandleLootPickup
local oldGetNumShrineUpgrades = _G.GetNumShrineUpgrades

_G.CurrentRun = {
    BiomeBoonSkipCount = 0,
    CurrentRoom = {
        ChosenRewardType = "SpellDrop",
        Encounter = {},
    },
}
_G.HasResources = function()
    return true
end
_G.HasResourceCost = function()
    return false
end

local handledSpellItem
_G.HandleLootPickup = function(_, spellItem)
    handledSpellItem = spellItem
    return "handled"
end

local openResult = hooks.OpenSpellScreen(host, runtime, function()
    return "base"
end, {
    Name = "SpellDrop",
    BoonInfoTitleText = "Codex_BoonInfo_Selene",
    NarrativeContextArt = "DialogueBackground_Moon",
}, {}, {})

assertEqual(openResult, "handled")
assertEqual(handledSpellItem.UpgradeOptions ~= nil, true)
assertEqual(handledSpellItem.BlockReroll, true)
assertEqual(handledSpellItem.DestroyOnPickup, true)
assertEqual(handledSpellItem.PostPickupFunctionName, "SpellDropInteractPresentationEnd")
assertEqual(handledSpellItem.MenuTitle, "Codex_BoonInfo_Selene")
assertEqual(handledSpellItem.BackgroundAnimation, "DialogueBackground_Moon_In")

_G.GetNumShrineUpgrades = function()
    return 1
end

CurrentRun.BiomeBoonSkipCount = 3
hooks.CheckBoonSkipShrineUpgrade(host, runtime, function()
    CurrentRun.BiomeBoonSkipCount = 4
    return {}
end, {}, {})
assertEqual(CurrentRun.BiomeBoonSkipCount, 3)

CurrentRun.BiomeBoonSkipCount = 0

local function runSpawnRewardTest(rewardType, expectedRewardOverride)
    CurrentRun.CurrentRoom.ChosenRewardType = rewardType
    local spawnArgs
    hooks.SpawnRoomReward(host, runtime, function(_, args)
        spawnArgs = args
        return "spawned"
    end, {}, {})
    assertEqual(spawnArgs.RewardOverride, expectedRewardOverride)
    assertEqual(spawnArgs.LootName, nil)
end

runSpawnRewardTest("SpellDrop", "Boon")
runSpawnRewardTest("WeaponUpgrade", "Boon")

_G.GetNumShrineUpgrades = function()
    return 0
end

runSpawnRewardTest("WeaponUpgrade", nil)

_G.CurrentRun = oldCurrentRun
_G.HasResources = oldHasResources
_G.HasResourceCost = oldHasResourceCost
_G.HandleLootPickup = oldHandleLootPickup
_G.GetNumShrineUpgrades = oldGetNumShrineUpgrades

local support = dofile("tests/support.lua")
local assertEqual = support.assertEqual

local behaviors = support.loadBehaviors()
local uiModule = assert(loadfile("src/ui.lua"))()

local tabContent
local quickContent
uiModule.attach({
    ui = {
        tab = function(callback)
            tabContent = callback
        end,
        quickContent = function(callback)
            quickContent = callback
        end,
    },
}, behaviors.options)

local values = {}
for _, option in ipairs(behaviors.options) do
    values[option.alias] = true
end
values.Preset = "custom"

local selectedPreset
local dropdownCurrent
local dropdownValues
local draw = {
    widgets = {
        dropdown = function(field, opts)
            dropdownCurrent = field:read()
            dropdownValues = opts.values
            field:write(selectedPreset)
            return true
        end,
        text = function() end,
        separator = function() end,
        checkbox = function() end,
    },
}

local host = {
    isEnabled = function()
        return true
    end,
}

selectedPreset = "clear_all"
quickContent(host, {
    draw = draw,
    data = support.createUiState(values),
})

assertEqual(dropdownCurrent, "shared_wealth_only")
assertEqual(dropdownValues[1], "custom")
for _, value in pairs(values) do
    if value ~= values.Preset then
        assertEqual(value, false)
    end
end
assertEqual(values.Preset, "clear_all")

selectedPreset = "no_normal_boons"
quickContent(host, {
    draw = draw,
    data = support.createUiState(values),
})

assertEqual(dropdownCurrent, "clear_all")
for alias, value in pairs(values) do
    if alias ~= "Preset" then
        assertEqual(value, alias == "BoonOffersToSharedWealth" or alias == "BoonVowSkips")
    end
end
assertEqual(values.Preset, "no_normal_boons")

local tabValues = {}
for _, option in ipairs(behaviors.options) do
    tabValues[option.alias] = false
end
tabValues.Preset = "custom"

local drawEvents = {}
local tabDraw = {
    widgets = {
        dropdown = function()
            return false
        end,
        text = function() end,
        separator = function()
            drawEvents[#drawEvents + 1] = "separator"
        end,
        checkbox = function(field, opts)
            assertEqual(opts ~= nil, true)
            drawEvents[#drawEvents + 1] = field.alias
        end,
    },
}

tabContent(host, {
    draw = tabDraw,
    data = support.createUiState(tabValues),
})

local expectedDrawEvents = {
    "separator",
    "separator",
    "BoonOffersToSharedWealth",
    "BoonVowSkips",
    "separator",
    "WeaponUpgradesToSharedWealth",
    "HammerVowSkips",
    "separator",
    "SeleneToSharedWealth",
    "HexVowSkips",
    "separator",
    "ArtemisToSharedWealth",
    "AthenaToSharedWealth",
    "DionysusToSharedWealth",
    "separator",
    "ArachneToSharedWealth",
    "NarcissusToSharedWealth",
    "EchoToSharedWealth",
    "HadesToSharedWealth",
    "MedeaToSharedWealth",
    "CirceToSharedWealth",
    "IcarusToSharedWealth",
    "ChaosToSharedWealth",
}

assertEqual(#drawEvents, #expectedDrawEvents)
for index, expectedEvent in ipairs(expectedDrawEvents) do
    assertEqual(drawEvents[index], expectedEvent)
end

local renderedAliases = {}
local renderedCount = 0
for _, event in ipairs(drawEvents) do
    if event ~= "separator" then
        renderedAliases[event] = (renderedAliases[event] or 0) + 1
        renderedCount = renderedCount + 1
    end
end

local optionCount = 0
for _, option in ipairs(behaviors.options) do
    if option.type == "checkbox" then
        optionCount = optionCount + 1
        assertEqual(renderedAliases[option.alias], 1)
    end
end
assertEqual(renderedCount, optionCount)

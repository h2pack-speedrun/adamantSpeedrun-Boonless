local support = dofile("tests/support.lua")
local assertEqual = support.assertEqual

local behaviors = support.loadBehaviors()
local uiModule = assert(loadfile("src/ui.lua"))()

local quickContent
uiModule.attach({
    ui = {
        tab = function() end,
        quickContent = function(callback)
            quickContent = callback
        end,
    },
}, behaviors.options)

local values = {}
for _, option in ipairs(behaviors.options) do
    if option.alias == "UnlimitedBoonSkips" then
        values[option.alias] = false
    else
        values[option.alias] = true
    end
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
        assertEqual(value, alias == "BoonOffersToSharedWealth")
    end
end
assertEqual(values.Preset, "no_normal_boons")

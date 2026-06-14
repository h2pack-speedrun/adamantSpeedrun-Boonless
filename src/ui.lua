local module = {}

local PRESET_ALIAS = "Preset"
local UNLIMITED_BOON_SKIPS_ALIAS = "UnlimitedBoonSkips"
local BOON_OFFERS_ALIAS = "BoonOffersToSharedWealth"
local WARNING_TEXT_OPTS = {
    color = { 1.0, 0.18, 0.18, 1.0 },
}
local CHALLENGE_WARNING_TEXT = "Challenge run module active: this configuration changes boon rewards."

local OLYMPIAN_GIFT_ALIASES = {
    "ArtemisToSharedWealth",
    "AthenaToSharedWealth",
    "DionysusToSharedWealth",
}

local NPC_GIFT_ALIASES = {
    "HadesToSharedWealth",
    "ArachneToSharedWealth",
    "CirceToSharedWealth",
    "EchoToSharedWealth",
    "IcarusToSharedWealth",
    "MedeaToSharedWealth",
    "NarcissusToSharedWealth",
}

local PRESETS = {
    {
        alias = "clear_all",
        label = "Clear All",
        enabledAliases = {},
    },
    {
        alias = "no_normal_boons",
        label = "No Normal Boons",
        enabledAliases = { BOON_OFFERS_ALIAS },
    },
    {
        alias = "no_olympian_gifts",
        label = "No Olympian Gifts",
        enabledAliases = { BOON_OFFERS_ALIAS, OLYMPIAN_GIFT_ALIASES },
    },
    {
        alias = "no_olympian_and_npc_gifts",
        label = "No Olympian and NPC Gifts",
        enabledAliases = { BOON_OFFERS_ALIAS, OLYMPIAN_GIFT_ALIASES, NPC_GIFT_ALIASES },
    },
    {
        alias = "shared_wealth_only",
        label = "Shared Wealth Only",
        enableAllSharedWealth = true,
    },
}

local CUSTOM_PRESET = {
    alias = "custom",
    label = "Custom",
}

local PRESET_VALUES = {
    CUSTOM_PRESET.alias,
}
local PRESET_DISPLAY_VALUES = {
    [CUSTOM_PRESET.alias] = CUSTOM_PRESET.label,
}
local PRESET_BY_ALIAS = {}

for _, preset in ipairs(PRESETS) do
    PRESET_VALUES[#PRESET_VALUES + 1] = preset.alias
    PRESET_DISPLAY_VALUES[preset.alias] = preset.label
    PRESET_BY_ALIAS[preset.alias] = preset
end

local PRESET_DROPDOWN_OPTS = {
    id = "BoonlessPreset",
    label = "Preset",
    tooltip = "Apply a preset to the Boonless checkboxes.",
    values = PRESET_VALUES,
    displayValues = PRESET_DISPLAY_VALUES,
    controlWidth = 280,
}

local function addAlias(aliasSet, aliasList, alias)
    if aliasSet[alias] then
        return
    end
    aliasSet[alias] = true
    table.insert(aliasList, alias)
end

local function appendPresetAliases(enabledSet, aliases)
    if type(aliases) == "string" then
        enabledSet[aliases] = true
        return
    end
    for _, alias in ipairs(aliases or {}) do
        appendPresetAliases(enabledSet, alias)
    end
end

local function preparePreset(preset, allSharedWealthAliases)
    local enabledSet = {}
    if preset.enableAllSharedWealth then
        appendPresetAliases(enabledSet, allSharedWealthAliases)
    else
        appendPresetAliases(enabledSet, preset.enabledAliases)
    end
    preset.enabledSet = enabledSet
end

local function buildPresetContext(options)
    local allAliases = {}
    local allAliasSet = {}
    local allSharedWealthAliases = {}
    local allSharedWealthAliasSet = {}

    for _, option in ipairs(options) do
        if option.type == "checkbox" then
            addAlias(allAliasSet, allAliases, option.alias)
            if option.alias ~= UNLIMITED_BOON_SKIPS_ALIAS then
                addAlias(allSharedWealthAliasSet, allSharedWealthAliases, option.alias)
            end
        end
    end

    for _, preset in ipairs(PRESETS) do
        preparePreset(preset, allSharedWealthAliases)
    end

    return {
        allAliases = allAliases,
        allAliasSet = allAliasSet,
    }
end

local function isAliasEnabledForPreset(preset, alias)
    return preset.enabledSet and preset.enabledSet[alias] == true
end

local function getPresetForState(state, context)
    for _, preset in ipairs(PRESETS) do
        local matches = true
        for _, alias in ipairs(context.allAliases) do
            if state.get(alias):read() ~= isAliasEnabledForPreset(preset, alias) then
                matches = false
                break
            end
        end
        if matches then
            return preset
        end
    end
    return CUSTOM_PRESET
end

local function applyPreset(state, context, preset)
    for _, alias in ipairs(context.allAliases) do
        state.get(alias):write(isAliasEnabledForPreset(preset, alias))
    end
    state.get(PRESET_ALIAS):write(preset.alias)
end

local function hasActiveOption(state, context)
    for _, alias in ipairs(context.allAliases) do
        if state.get(alias):read() == true then
            return true
        end
    end
    return false
end

local function shouldShowChallengeWarning(host, state, context)
    return host.isEnabled() == true and hasActiveOption(state, context)
end

local function drawChallengeWarning(draw, host, state, context)
    if shouldShowChallengeWarning(host, state, context) then
        draw.widgets.text(CHALLENGE_WARNING_TEXT, WARNING_TEXT_OPTS)
    end
end

local function drawPresetDropdown(draw, state, context)
    local currentPreset = getPresetForState(state, context)
    local presetField = state.get(PRESET_ALIAS)
    presetField:write(currentPreset.alias)

    if draw.widgets.dropdown(presetField, PRESET_DROPDOWN_OPTS) then
        local selectedPreset = PRESET_BY_ALIAS[presetField:read()]
        if selectedPreset ~= nil then
            applyPreset(state, context, selectedPreset)
        end
    end
end

local function buildCheckboxOptions(options)
    local optsByAlias = {}
    for _, option in ipairs(options) do
        if option.type == "checkbox" then
            optsByAlias[option.alias] = {
                label = option.label,
                tooltip = option.tooltip,
            }
        end
    end
    return optsByAlias
end

local function drawOptions(draw, state, options, checkboxOptsByAlias)
    for _, option in ipairs(options) do
        if option.type == "checkbox" then
            draw.widgets.checkbox(state.get(option.alias), checkboxOptsByAlias[option.alias])
        end
    end
end

function module.drawTab(host, draw, state, options, checkboxOptsByAlias, presetContext)
    draw.widgets.separator()
    drawPresetDropdown(draw, state, presetContext)
    drawChallengeWarning(draw, host, state, presetContext)
    draw.widgets.separator()
    drawOptions(draw, state, options, checkboxOptsByAlias)
end

function module.drawQuickContent(host, draw, state, presetContext)
    drawPresetDropdown(draw, state, presetContext)
    drawChallengeWarning(draw, host, state, presetContext)
end

function module.attach(libModule, options)
    local checkboxOptsByAlias = buildCheckboxOptions(options)
    local presetContext = buildPresetContext(options)
    libModule.ui.tab(function(host, ui)
        return module.drawTab(host, ui.draw, ui.data, options, checkboxOptsByAlias, presetContext)
    end)
    libModule.ui.quickContent(function(host, ui)
        return module.drawQuickContent(host, ui.draw, ui.data, presetContext)
    end)
end

return module

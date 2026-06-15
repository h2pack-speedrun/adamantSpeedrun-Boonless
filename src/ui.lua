local module = {}

local PRESET_ALIAS = "Preset"
local BOON_OFFERS_ALIAS = "BoonOffersToSharedWealth"
local BOON_VOW_ALIAS = "BoonVowSkips"
local HAMMER_OFFERS_ALIAS = "WeaponUpgradesToSharedWealth"
local HAMMER_VOW_ALIAS = "HammerVowSkips"
local SELENE_OFFERS_ALIAS = "SeleneToSharedWealth"
local HEX_VOW_ALIAS = "HexVowSkips"
local WARNING_TEXT_OPTS = {
    color = { 1.0, 0.18, 0.18, 1.0 },
}
local CHALLENGE_WARNING_TEXT = "Challenge run module active: this configuration removes rewards during runs."

local BOON_REWARD_ALIASES = {
    BOON_OFFERS_ALIAS,
    BOON_VOW_ALIAS,
}

local HAMMER_REWARD_ALIASES = {
    HAMMER_OFFERS_ALIAS,
    HAMMER_VOW_ALIAS,
}

local SELENE_REWARD_ALIASES = {
    SELENE_OFFERS_ALIAS,
    HEX_VOW_ALIAS,
}

local OLYMPIAN_GIFT_ALIASES = {
    "ArtemisToSharedWealth",
    "AthenaToSharedWealth",
    "DionysusToSharedWealth",
}

local NPC_GIFT_ALIASES = {
    "ArachneToSharedWealth",
    "NarcissusToSharedWealth",
    "EchoToSharedWealth",
    "HadesToSharedWealth",
    "MedeaToSharedWealth",
    "CirceToSharedWealth",
    "IcarusToSharedWealth",
    "ChaosToSharedWealth",
}

local CHECKBOX_GROUPS = {
    BOON_REWARD_ALIASES,
    HAMMER_REWARD_ALIASES,
    SELENE_REWARD_ALIASES,
    OLYMPIAN_GIFT_ALIASES,
    NPC_GIFT_ALIASES,
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
        enabledAliases = { BOON_REWARD_ALIASES },
    },
    {
        alias = "no_olympian_gifts",
        label = "No Olympian Gifts",
        enabledAliases = { BOON_REWARD_ALIASES, OLYMPIAN_GIFT_ALIASES },
    },
    {
        alias = "no_olympian_and_npc_gifts",
        label = "No Olympian and NPC Gifts",
        enabledAliases = { BOON_REWARD_ALIASES, SELENE_REWARD_ALIASES, OLYMPIAN_GIFT_ALIASES, NPC_GIFT_ALIASES },
    },
    {
        alias = "shared_wealth_only",
        label = "Shared Wealth Only",
        enabledAliases = {
            BOON_REWARD_ALIASES,
            HAMMER_REWARD_ALIASES,
            SELENE_REWARD_ALIASES,
            OLYMPIAN_GIFT_ALIASES,
            NPC_GIFT_ALIASES,
        },
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

local function preparePreset(preset)
    local enabledSet = {}
    appendPresetAliases(enabledSet, preset.enabledAliases)
    preset.enabledSet = enabledSet
end

local function buildPresetContext(options)
    local allAliases = {}
    local allAliasSet = {}

    for _, option in ipairs(options) do
        if option.type == "checkbox" then
            addAlias(allAliasSet, allAliases, option.alias)
        end
    end

    for _, preset in ipairs(PRESETS) do
        preparePreset(preset)
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

local function drawOptions(draw, state, checkboxOptsByAlias)
    for groupIndex, aliases in ipairs(CHECKBOX_GROUPS) do
        if groupIndex > 1 then
            draw.widgets.separator()
        end
        for _, alias in ipairs(aliases) do
            draw.widgets.checkbox(state.get(alias), checkboxOptsByAlias[alias])
        end
    end
end

function module.drawTab(host, draw, state, checkboxOptsByAlias, presetContext)
    draw.widgets.separator()
    drawPresetDropdown(draw, state, presetContext)
    drawChallengeWarning(draw, host, state, presetContext)
    draw.widgets.separator()
    drawOptions(draw, state, checkboxOptsByAlias)
end

function module.drawQuickContent(host, draw, state, presetContext)
    drawPresetDropdown(draw, state, presetContext)
    drawChallengeWarning(draw, host, state, presetContext)
end

function module.attach(libModule, options)
    local checkboxOptsByAlias = buildCheckboxOptions(options)
    local presetContext = buildPresetContext(options)
    libModule.ui.tab(function(host, ui)
        return module.drawTab(host, ui.draw, ui.data, checkboxOptsByAlias, presetContext)
    end)
    libModule.ui.quickContent(function(host, ui)
        return module.drawQuickContent(host, ui.draw, ui.data, presetContext)
    end)
end

return module

-- luacheck: globals rom import_as_fallback modutil lib _PLUGIN game

local mods = rom.mods
mods["SGG_Modding-ENVY"].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods["SGG_Modding-ModUtil"]
local reload = mods["SGG_Modding-ReLoad"]
---@module "adamant-ModpackLib"
---@type AdamantModpackLib
lib = mods["adamant-ModpackLib"]

local PACK_ID = "speedrun"
local MODULE_ID = "Boonless"
local PLUGIN_GUID = _PLUGIN.guid

local function init()
    import_as_fallback(rom.game)

    local data = import("data.lua")
    local behaviors = import("behaviors.lua")
    local logic = import("logic.lua")
    local ui = import("ui.lua")

    local module = lib.createModule({
        pluginGuid = PLUGIN_GUID,
        modpack = PACK_ID,
        id = MODULE_ID,
        name = "Boonless",
        shortName = "Boonless",
        tooltip = "Boonless route options for the Speedrun modpack.",
    })
    if not module then
        return
    end

    module.data.define(data.buildStorage(behaviors.options))
    ui.attach(module, behaviors.options)
    module.fallbackUi.attachGuiOnce(function(fallbackUi)
        rom.gui.add_imgui(fallbackUi.renderWindow)
        rom.gui.add_to_menu_bar(fallbackUi.addMenuBar)
    end)
    logic.attach(module, behaviors.hooks)

    local ok = module.activate()
    if not ok then
        return
    end
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(nil, init)
end)

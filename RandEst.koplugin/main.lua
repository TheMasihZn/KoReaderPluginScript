local Dispatcher = require("dispatcher")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

-- Extend WidgetContainer like Calibre does
local RandEst = WidgetContainer:extend{
    name = "RandEst",
    is_doc_only = false,
}

-- Dynamically get the path where this plugin is located
local function current_plugin_dir()
    return debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])")
end

local KINDLE_PLUGIN_DIR = current_plugin_dir()
if not KINDLE_PLUGIN_DIR then
    KINDLE_PLUGIN_DIR = "/mnt/us/koreader/plugins/RandEst.koplugin/"
end
local SCRIPT_PATH = KINDLE_PLUGIN_DIR .. "rand.sh"

local function file_exists(path)
    local f = io.open(path, "r")
    if f then f:close() return true end
    return false
end

function RandEst:init()
    self:onDispatcherRegisterActions()
    -- self.ui is usually set by WidgetContainer:new, but for plugins we might need to ensure it exists if we use it.
    self.ui = UIManager 
end

function RandEst:onDispatcherRegisterActions()
    Dispatcher:registerAction("randest_run_script", {
        category = "none",
        event = "RandEstRunScript",
        title = _("Run RandEst script"),
        general = true,
    })
end

-- Handler for the event registered above
function RandEst:onRandEstRunScript()
    self:runScript()
    return true
end

function RandEst:runScript()
    if not file_exists(SCRIPT_PATH) then
        UIManager:show(InfoMessage:new{ text = _("rand.sh not found at: ") .. (SCRIPT_PATH or "unknown") })
        return
    end
    -- Use 'sh' explicitly
    local cmd = string.format("sh '%s' &", SCRIPT_PATH)
    local ok = os.execute(cmd)

    local msg = ok and _("rand.sh launched.") or _("Failed to launch rand.sh.")
    UIManager:show(InfoMessage:new{ text = msg })
end

-- Add to the main menu (upper bar -> tools)
function RandEst:addToMainMenu(menu_items)
    menu_items.randest = {
        text = _("RandEst"),
        sub_item_table = {
            {
                text = _("Run rand.sh"),
                callback = function()
                    self:runScript()
                end,
            },
        },
    }
end

return RandEst

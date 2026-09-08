---@diagnostic disable: lowercase-global
local L = locale
local function en_zh(en, zh)
    return L ~= "zh" and L ~= "zhr" and L ~= "zht" and en or zh
end

name = en_zh("Global Events Timer - Client", "全局事件计时器 - 客户端版") -- 模组名称
description = en_zh([[
Adds a widget in-game that opens an event timer panel.
The panel displays countdowns for various events and BOSS respawns.
You can tick the checkbox on the right side of the panel to keep the timer always visible in the top-left corner of the screen.
]],
[[
在游戏内添加一个小部件，点开后显示事件计时器面板。
面板内显示各事件和BOSS刷新倒计时
勾选面板右侧的复选框可使计时始终显示在屏幕左上角
点击事件可宣告其信息
]])
author = "冰冰羊"
version = "0.2.04" -- 模组版本
api_version = 10

--[[
岛屿冒险-海难 priority = 4
岛屿冒险-猪镇 priority = 3
云霄国度 priority = -1
永不妥协 priority = -10
永不妥协公开测试版 priority = -10
热带冒险 priority = -100
]]
priority = -100 -- 模组加载优先级

dst_compatible = true -- 兼容联机版
dont_starve_compatible = false -- 不兼容单机版

all_clients_require_mod = false
client_only_mod = true
server_only_mod = false

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

local toggle = {
	{description = en_zh("Enabled", "开启"), data = true},
	{description = en_zh("Disabled", "关闭"), data = false},
}

local keyboard = { -- from STRINGS.UI.CONTROLSSCREEN.INPUTS[1] of strings.lua, need to match constants.lua too.
  { 'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12', 'Print', 'ScrolLock', 'Pause' },
  { '1', '2', '3', '4', '5', '6', '7', '8', '9', '0' },
  { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M' },
  { 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z' },
  { 'Escape', 'Tab', 'CapsLock', 'LShift', 'LCtrl', 'LSuper', 'LAlt' },
  { 'Space', 'RAlt', 'RSuper', 'RCtrl', 'RShift', 'Enter', 'Backspace' },
  { 'BackQuote', 'Minus', 'Equals', 'LeftBracket', 'RightBracket' },
  { 'Backslash', 'Semicolon', 'Quote', 'Period', 'Slash' }, -- punctuation
  { 'Up', 'Down', 'Left', 'Right', 'Insert', 'Delete', 'Home', 'End', 'PageUp', 'PageDown' }, -- navigation
}
local numpad = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'Period', 'Divide', 'Multiply', 'Minus', 'Plus' }
local mouse = { '\238\132\128', '\238\132\129', '\238\132\130', '\238\132\131', '\238\132\132' } -- Mouse Button Left/Right/Middle/4/5
local key_disabled = { description = en_zh('Disabled', '禁用'), data = 'KEY_DISABLED' }
keys = { key_disabled }
for i = 1, #mouse do
  keys[#keys + 1] = { description = mouse[i], data = mouse[i] }
end
for i = 1, #keyboard do
  for j = 1, #keyboard[i] do
    local key = keyboard[i][j]
    keys[#keys + 1] = { description = key, data = 'KEY_' .. key:upper() }
  end
  keys[#keys + 1] = key_disabled
end
for i = 1, #numpad do
  local key = numpad[i]
  keys[#keys + 1] = { description = 'Numpad ' .. key, data = 'KEY_KP_' .. key:upper() }
end

---@param label string|nil 标题
---@param client_config boolean|nil 是否仅显示在客户端设置页面上
---@return table
local function SkipSpace(label, client_config)
	return { name = "",label = label, hover = "", options = { { description = "", data = false }, }, default = false, client = client_config}
end

configuration_options = {
    {
        name = "language",
        label = en_zh("Language", "语言"),
        hover = en_zh("Select the language you want to use", "选择你想要使用的语言"),
        options =
        {
            {description = "中文(Chinese)", data = "zh", hover = ""},
            {description = "English(英语)", data = "en", hover = ""},
        },
        default = en_zh("en", "zh"),
    },
    {
        name = "GetTimeFromRemoteCommand",
        label = en_zh("Get Time from Server", "从服务器获取数据"),
        hover = en_zh("Get event time from server via remote command, It only works when you are server admin", "通过远程命令从服务器获取事件时间，只有你是管理员的时候才有效果"),
        options = toggle,
        default = true,
    },
    {
        name = "BossTimer",
        label = en_zh("Boss Timing Format", "Boss计时格式"),
        options =
        {
            {description = en_zh("day:m:s", "天:分:秒"), data = 1, hover = en_zh("Game Time", "游戏时间,一天8分钟")},
            {description = en_zh("h:m:s", "时:分:秒"), data = 2, hover = en_zh("Real Time", "现实时间")},
        },
        default = 1,
    },
    {
        name = "UIButton",
        label = en_zh("Button Visibility", "按钮显示"),
        hover = en_zh("Choose when the event timer panel toggle button appears", "选择事件计时器面板的开关在什么情况下显示"),
        options = {
            {description = en_zh("Always Visible", "始终显示"), data = "always"},
            {description = en_zh("Pause Menu", "在暂停页面显示"), hover = en_zh("Visible when you press ESC to open the pause menu", "按ESC打开暂停页面时显示"), data = "pause_screen"},
        },
        default = "always",
    },
    {
        name = "hotkey",
        label = en_zh("Panel Hotkey", "计时器面板快捷键"),
        hover = en_zh("Hotkey to toggle the timer panel", "开关计时器面板的快捷键"),
        options = keys,
        default = "KEY_DISABLED",
    },
    {
        name = "ShowTips",
        label = en_zh("Highlight Tips", "醒目提示"),
        hover = en_zh("Show a noticeable alert when entering the game or when an event countdown is about to end", "当进入游戏时/事件倒计时即将结束时发出醒目提示"),
        options = toggle,
        default = true,
    },
}
---@diagnostic disable: lowercase-global
local L = locale
local function en_zh(en, zh)
    return L ~= "zh" and L ~= "zhr" and L ~= "zht" and en or zh
end

name = en_zh("Global Events Timer", "全局事件计时器") -- 模组名称
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
author = "冰冰羊，Jerry"
version = "0.1.11.1" -- 模组版本
version_compatible = "0.1.10" -- 最低兼容版本
api_version = 10
priority = -1 -- 模组加载优先级
dst_compatible = true -- 兼容联机版
dont_starve_compatible = false -- 不兼容单机版

all_clients_require_mod = true
client_only_mod = false
server_only_mod = false

server_filter_tags = { -- 服务器标签
    "全局事件计时器 V" .. version,
    "Global Events Timer V" .. version,
}

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

configuration_options = {
    {
        name = "lang",
        label = en_zh("Language", "语言"),
        hover = en_zh("Select the language you want to use", "选择你想要使用的语言"),
        options =
        {
            {description = "English(英语)", data = "en", hover = ""},
            {description = "中文(Chinese)", data = "zh", hover = ""},
            {description = en_zh("Auto", "自动"), data = "auto", hover = en_zh("Automatically set according to the game language", "根据游戏语言自动设置")},
        },
        default = "auto",
    },
    {
        name = "hotkey",
        label = en_zh("Panel Hotkey", "计时器面板快捷键"),
        hover = en_zh("Hotkey to toggle the timer panel", "开关计时器面板的快捷键"),
        options = keys,
        default = "KEY_DISABLED",
        client = true,
    },
    {
        name = "UIButton",
        label = en_zh("Panel Toggle Button Visibility", "面板开关按钮何时显示"),
        hover = en_zh("Choose when the event timer panel toggle button appears", "选择事件计时器面板的开关在什么情况下显示"),
        options = {
            {description = en_zh("Always Visible", "始终显示"), data = "always"},
            {description = en_zh("Pause Menu", "在暂停页面显示"), hover = en_zh("Visible when you press ESC to open the pause menu", "按ESC打开暂停页面时显示"), data = "pause_screen"},
        },
        default = "always",
        client = true,
    },
    {
        name = "UpdateTime",
        label = en_zh("Server Data Update Frequency", "服务器数据更新频率"),
        hover = en_zh("How often the server updates the timer data","设置服务器多久更新一次计时器数据"),
        options =
        {
            {description = "0.5s", data = 0.5},
            {description = "1s", data = 1},
            {description = "2s", data = 2},
            {description = "3s", data = 3},
            {description = "4s", data = 4},
            {description = "5s", data = 5},
            {description = "6s", data = 6},
            {description = "7s", data = 7},
            {description = "8s", data = 8},
            {description = "9s", data = 9},
            {description = "10s", data = 10},
        },
        default = 1,
    },
    {
        name = "ClientPrediction",
        label = en_zh("Client Predicted Countdown", "客户端预测倒计时"),
        hover = en_zh("If the server update interval is longer than 1 second, use client prediction to fill the gaps","如果服务器的数据更新频率在1秒以上，则使用客户端预测填补空缺的刷新周期"),
        options = toggle,
        default = true,
        client = true,
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
        name = "ShowTips",
        label = en_zh("Highlight Tips", "醒目提示"),
        hover = en_zh("Show a noticeable alert when entering the game or when an event countdown is about to end", "当进入游戏时/事件倒计时即将结束时发出醒目提示"),
        options = toggle,
        default = true,
        client = true,
    },
    {
        name = "SyncTimer",
        label = en_zh("Sync Timer", "跨世界同步计时"),
        options = toggle,
        default = true,
    },
}
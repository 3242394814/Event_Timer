---@diagnostic disable: lowercase-global
local L = locale
local function en_zh(en, zh)
    return L ~= "zh" and L ~= "zhr" and L ~= "zht" and en or zh
end

name = "全局事件计时器" -- 模组名称
description = en_zh([[

]],[[
在游戏内添加一个小部件，点开后显示事件计时器面板。
面板内显示各事件和BOSS刷新倒计时
勾选面板右侧的复选框可使计时始终显示在屏幕左上角

功能说明：
【跨世界同步计时】：开启后该世界的事件计时数据会与其它世界共享
（多层世界专服玩家注意，如果你同时开了2个相同的世界，请关掉其中1个世界的同步功能，否则数据会冲突）
]])
author = "冰冰羊"
version = 1 -- 模组版本
description = ""

dst_compatible = true -- 兼容联机版
dont_starve_compatible = false -- 不兼容单机版

all_clients_require_mod = true
client_only_mod = false
server_only_mod = false


local options_enable = {
	{description = en_zh("Disabled", "关闭"), data = false},
	{description = en_zh("Enabled", "开启"), data = true},
}


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
        name = "BossTimer",
        label = en_zh("BossTimer", "Boss计时格式"),
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
        options =
        {
            {description = en_zh("On", "开"), data = true, hover = ""},
            {description = en_zh("Off", "关"), data = false, hover = ""},
        },
        default = true,
        client = true,
    },
    {
        name = "SyncTimer",
        label = en_zh("Sync Timer", "跨世界同步计时"),
        options =
        {
            {description = en_zh("On", "开"), data = true, hover = ""},
            {description = en_zh("Off", "关"), data = false, hover = ""},
        },
        default = true,
    },
}
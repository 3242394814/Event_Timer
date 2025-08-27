---@diagnostic disable: lowercase-global
local L = locale
local function en_zh(en, zh)
    return L ~= "zh" and L ~= "zhr" and L ~= "zht" and en or zh
end

name = "事件计时器" -- 模组名称
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

configuration_options = {}

local options_enable = {
	{description = en_zh("Disabled", "关闭"), data = false},
	{description = en_zh("Enabled", "开启"), data = true},
}

local function AddOption(name, label_en, label_ch, options, default)
    configuration_options[#configuration_options + 1] = {
        name = name,
		label = en_zh(label_en, label_ch),
		options = options or options_enable,
		default = default == nil and true or default,
	}
end

AddOption("lang", "Language", "语言",{
    {description = en_zh("Auto", "自动"), data = "auto", hover = en_zh("Automatically set according to the game language", "根据游戏语言自动设置")},
    {description = en_zh("Chinese", "中文"), data = "zh", hover = ""},
    {description = en_zh("English", "英文"), data = "en", hover = ""},
}, "auto")

AddOption("BossTimer", "BossTimer", "Boss计时格式",{
    {description = en_zh("day:m:s", "天:分:秒"), data = 1, hover = en_zh("Game Time", "游戏时间,一天8分钟")},
    {description = en_zh("h:m:s", "时:分:秒"), data = 2, hover = en_zh("Real Time", "现实时间")},
    {description = en_zh("Disabled", "关闭"), data = false},
}, 1)

AddOption("SyncTimer", "Sync Timer", "跨世界同步计时",{
    {description = en_zh("On", "开"), data = true, hover = ""},
    {description = en_zh("Off", "关"), data = false, hover = ""},
}, true)
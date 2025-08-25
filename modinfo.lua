---@diagnostic disable: lowercase-global
name = "BOSS计时器" -- 模组名称
description = [[

]]
author = "冰冰羊"
version = 1 -- 模组版本
description = ""

dst_compatible = true -- 兼容联机版
dont_starve_compatible = false -- 不兼容单机版

all_clients_require_mod = true
client_only_mod = false
server_only_mod = false

configuration_options = {}

local L = locale
local function en_zh(en, zh)
    return L ~= "zh" and L ~= "zhr" and L ~= "zht" and en or zh
end

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

AddOption("BossTimer", "BossTimer", "Boss计时",{
    {description = en_zh("day:m:s", "天:分:秒"), data = 1, hover = en_zh("Game Time", "游戏时间,一天8分钟")},
    {description = en_zh("h:m:s", "时:分:秒"), data = 2, hover = en_zh("Real Time", "现实时间")},
    {description = en_zh("Disabled", "关闭"), data = false},
}, 1)
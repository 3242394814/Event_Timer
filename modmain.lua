----------------------------------------加载资源---------------------------------------

Assets = {
	Asset("ATLAS", "images/dyc_panel_shadow.xml"), -- 来自单机饥荒模组【全能信息面板】
	Asset("IMAGE", "images/dyc_panel_shadow.tex"), -- 来自单机饥荒模组【全能信息面板】
}

----------------------------------------语言检测---------------------------------------

ModLanguage = GetModConfigData("lang") or "auto"
if ModLanguage == "auto" then
    ModLanguage = GLOBAL.LanguageTranslator.defaultlang
end

local _languages = {
	de = "de", --german
	es = "es", --spanish
	fr = "fr", --french
	it = "it", --italian
	ko = "ko", --korean
	--Note: The only language mod I found that uses "pt" is also brazilian portuguese -M
	pt = "pt", --portuguese
	br = "pt", --brazilian portuguese
	pl = "pl", --polish
	ru = "ru", --russian
	zh = "zh", --Chinese for Steam
	zhr = "zh", --Chinese for WeGame
	ch = "zh", --Chinese mod
	chs = "zh", --Chinese mod
	sc = "zh", --simple Chinese
	chinese = "zh", --Chinese mod
	zht = "zh", --traditional Chinese for Steam
	tc = "zh", --traditional Chinese
	cht = "zh", --Chinese mod
}

if _languages[ModLanguage] ~= nil then
    ModLanguage = _languages[ModLanguage]
else
    ModLanguage = "en"
end

----------------------------------------定义模组环境函数---------------------------------------

function Import(modulename)
	local f = GLOBAL.kleiloadlua(modulename)
	if f and type(f) == "function" then
        GLOBAL.setfenv(f, env.env)
        return f()
	end
end

Upvaluehelper = Import(MODROOT .. "scripts/utils/bbgoat_upvaluehelper.lua")

function ReplacePrefabName(str)
	if type(str) ~= "string" then return end
    return str:gsub("<prefab=(.-)>", function(prefab)
        local key = prefab:upper()
        return GLOBAL.STRINGS.NAMES[key] or prefab
    end)
end

-- 反向提取信息
function Extract_by_format(text, format_str)
    if type(text) ~= "string" or type(format_str) ~= "string" then return end
    local safe = string.gsub(format_str, "%-", "%%%1")
    local pattern = safe:gsub("%%s", "(.*)")
    return text:match(pattern)
end

function GetWorldtypeStr() -- 根据世界类型返回一段字符串
    if GLOBAL.TheWorld:HasTag("porkland") then
        return "porkland"
    elseif GLOBAL.TheWorld:HasTag("island") then
        return "shipwrecked"
    elseif GLOBAL.TheWorld:HasTag("cave") then
        return "cave"
    else
        return "forest"
    end
end

-- 存取数据
local DATA_FILE = 'mod_config_data/Events_Timer.json'
RW_Data = {}

function RW_Data:SaveData(data)
	local str = GLOBAL.json.encode(data)
	local insz, outsz = GLOBAL.SavePersistentString(DATA_FILE, str)
end

function RW_Data:LoadData()
	local data
	GLOBAL.TheSim:GetPersistentString(DATA_FILE, function(load_success, str)
		if load_success then
			if string.len(str) > 0 and not string.find(str,"return") then
				data = GLOBAL.json.decode(str) or {}
			else
				data = {}
			end
		end
	end)
	return data or {}
end

----------------------------------------模组环境映射到全局环境---------------------------------------

GLOBAL.EventTimer = {}
GLOBAL.EventTimer.env = env

----------------------------------------加载模组---------------------------------------

modimport("Languages/" .. ModLanguage) -- 加载翻译

GLOBAL.EventTimer.TimerMode = GetModConfigData("BossTimer", true) -- 倒计时格式
GLOBAL.EventTimer.SyncTimer = GetModConfigData("SyncTimer", false)
GLOBAL.EventTimer.TimerTips = GetModConfigData("ShowTips", true) -- 醒目提示
GLOBAL.EventTimer.UpdateTime = GetModConfigData("UpdateTime", false) -- 服务器数据更新频率
GLOBAL.EventTimer.ClientPrediction = GetModConfigData("ClientPrediction", true) -- 客户端预测倒计时

local IA_CONFIG = GLOBAL.rawget(GLOBAL, "IA_CONFIG")
if IA_CONFIG then
	IA_CONFIG.pondfishable = false
end

AddReplicableComponent("waringtimer")

modimport("main/commands")
modimport("main/waringevent") -- 事件计时功能
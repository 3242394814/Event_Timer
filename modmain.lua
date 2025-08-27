-- 语言检测

local lang = GetModConfigData("lang") or "auto"
if lang == "auto" then
    lang = GLOBAL.LanguageTranslator.defaultlang
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

if _languages[lang] ~= nil then
    lang = _languages[lang]
else
    lang = "en"
end

local function Import(modulename)
	local f = GLOBAL.kleiloadlua(modulename)
	if f and type(f) == "function" then
        GLOBAL.setfenv(f, env.env)
        return f()
	end
end

Upvaluehelper = Import(MODROOT .. "scripts/utils/bbgoat_upvaluehelper.lua")

function ReplacePrefabName(str)
    return str:gsub("<prefab=(.-)>", function(prefab)
        local key = prefab:upper()
        return GLOBAL.STRINGS.NAMES[key] or prefab
    end)
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

-- 模组环境映射到全局环境
GLOBAL.EventTimer = {}
GLOBAL.EventTimer.env = env
GLOBAL.EventTimer.language = lang

-- 加载模组
modimport("Languages/" .. lang) -- 加载翻译


GLOBAL.TimerMode = GetModConfigData("BossTimer") -- 倒计时格式

local IA_CONFIG = GLOBAL.rawget(GLOBAL, "IA_CONFIG")
if IA_CONFIG then
	IA_CONFIG.pondfishable = false
end

AddReplicableComponent("waringtimer")

modimport("main/commands")
modimport("main/waringevent") -- 事件计时功能

-- TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/XP_bar_fill_unlock") -- 播放BOSS提示音
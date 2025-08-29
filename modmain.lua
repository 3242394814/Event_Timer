----------------------------------------加载资源---------------------------------------

Assets = {
	Asset("ATLAS", "images/Hound.xml"),
	Asset("IMAGE", "images/Hound.tex"),
    Asset("ATLAS", "images/Depths_Worm.xml"),
	Asset("IMAGE", "images/Depths_Worm.tex"),
	Asset("ATLAS", "images/Twister.xml"),
	Asset("IMAGE", "images/Twister.tex"),
    Asset("ATLAS", "images/saveslot_portraits.xml"),
	Asset("IMAGE", "images/saveslot_portraits.tex"),
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

----------------------------------------鼠标跟随补丁---------------------------------------

local function ModFollowMouse(self)
    local old_sva = self.SetVAnchor
    self.SetVAnchor = function (_self, anchor)
        self.v_anchor = anchor
        return old_sva(_self, anchor)
    end

    local old_sha = self.SetHAnchor
    self.SetHAnchor = function (_self, anchor)
        self.h_anchor = anchor
        return old_sha(_self, anchor)
    end

    local function GetMouseLocalPos(ui, mouse_pos)
        local g_s = ui:GetScale()
        local l_s = Vector3(0,0,0)
        l_s.x, l_s.y, l_s.z = ui:GetLooseScale()
        local scale = Vector3(g_s.x/l_s.x, g_s.y/l_s.y, g_s.z/l_s.z)

        local ui_local_pos = ui:GetPosition()
        ui_local_pos = Vector3(ui_local_pos.x * scale.x, ui_local_pos.y * scale.y, ui_local_pos.z * scale.z)
        local ui_world_pos = ui:GetWorldPosition()
        if not (not ui.v_anchor or ui.v_anchor == ANCHOR_BOTTOM) or not (not ui.h_anchor or ui.h_anchor == ANCHOR_LEFT) then
            local screen_w, screen_h = TheSim:GetScreenSize()
            if ui.v_anchor and ui.v_anchor ~= ANCHOR_BOTTOM then
                ui_world_pos.y = ui.v_anchor == ANCHOR_MIDDLE and screen_h/2 + ui_world_pos.y or screen_h - ui_world_pos.y
            end
            if ui.h_anchor and ui.h_anchor ~= ANCHOR_LEFT then
                ui_world_pos.x = ui.h_anchor == ANCHOR_MIDDLE and screen_w/2 + ui_world_pos.x or screen_w - ui_world_pos.x
            end
        end

        local origin_point = ui_world_pos - ui_local_pos
        mouse_pos = mouse_pos - origin_point

        return Vector3(mouse_pos.x/ scale.x, mouse_pos.y/ scale.y, mouse_pos.z/ scale.z)
    end

    self.FollowMouse = function(_self)
        if _self.followhandler == nil then
            _self.followhandler = TheInput:AddMoveHandler(function(x, y)
                local loc_pos = GetMouseLocalPos(_self, Vector3(x, y, 0))
                _self:UpdatePosition(loc_pos.x, loc_pos.y)
            end)
            _self:SetPosition(GetMouseLocalPos(_self, TheInput:GetScreenPosition()))
        end
    end
end
AddClassPostConstruct("widgets/widget", ModFollowMouse)
----------------------------------------加载资源---------------------------------------

Assets = {
	Asset("ATLAS", "images/Hound.xml"), -- 猎犬
	Asset("IMAGE", "images/Hound.tex"),
    Asset("ATLAS", "images/Depths_Worm.xml"), -- 洞穴蠕虫
	Asset("IMAGE", "images/Depths_Worm.tex"),
    Asset("ATLAS", "images/Worm_boss.xml"), -- 巨大洞穴蠕虫
	Asset("IMAGE", "images/Worm_boss.tex"),
    Asset("ATLAS", "images/Daywalker.xml"), -- 梦魇疯猪
	Asset("IMAGE", "images/Daywalker.tex"),
    Asset("ATLAS", "images/Rift_Split.xml"), -- 双裂隙
	Asset("IMAGE", "images/Rift_Split.tex"),
    Asset("ATLAS", "images/Dreadstone_Outcrop.xml"), -- 被控制的梦魇裂隙
	Asset("IMAGE", "images/Dreadstone_Outcrop.tex"),
    Asset("ATLAS", "images/moon_full.xml"), -- 月圆
	Asset("IMAGE", "images/moon_full.tex"),
    Asset("ATLAS", "images/moon_new.xml"), -- 月黑
	Asset("IMAGE", "images/moon_new.tex"),
    Asset("ATLAS", "images/Moose.xml"), -- 麋鹿鹅
	Asset("IMAGE", "images/Moose.tex"),
    Asset("ATLAS", "images/Dragonfly.xml"), -- 龙蝇
	Asset("IMAGE", "images/Dragonfly.tex"),
	Asset("ATLAS", "images/Twister.xml"), -- 豹卷风
	Asset("IMAGE", "images/Twister.tex"),
    Asset("ATLAS", "images/scrapbook.xml"), -- 图标背景
    Asset("ATLAS", "images/lifeplant.xml"), -- 不老泉
    Asset("IMAGE", "images/lifeplant.tex"),
    Asset("ATLAS", "images/pig_bandit.xml"), -- 蒙面猪人
    Asset("IMAGE", "images/pig_bandit.tex"),
    Asset("ATLAS", "images/Aporkalypse_Clock.xml"), -- 灾变日历
    Asset("IMAGE", "images/Aporkalypse_Clock.tex"),
    Asset("ATLAS", "images/Ancient_Herald.xml"), -- 远古先驱
    Asset("IMAGE", "images/Ancient_Herald.tex"),
    Asset("ATLAS", "images/Roc.xml"), -- 友善的大鹏
    Asset("IMAGE", "images/Roc.tex"),
	Asset("ATLAS", "images/dyc_panel_shadow.xml"), -- Tips部件背景，来自单机饥荒模组【全能信息面板】，感谢DYC
	Asset("IMAGE", "images/dyc_panel_shadow.tex"),
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

local STRINGS = GLOBAL.STRINGS
local TimerMode = GetModConfigData("BossTimer", true)

-- 填充Prefab名字
--- @param str string
--- @return string, number
function ReplacePrefabName(str)
	if type(str) ~= "string" then return str end
    return str:gsub("<prefab=(.-)>", function(prefab)
        local key = prefab:upper()
        return STRINGS.NAMES[key] or prefab
    end)
end

-- 格式化时间
function TimeToString(seconds)
    if type(seconds) ~= "number" then return seconds end
    local daytime = TimerMode == 2 and 3600 or TUNING.TOTAL_DAY_TIME
    local d = math.floor(seconds / daytime)
    local min = math.floor(seconds % daytime / 60)
    local s = math.floor(seconds % daytime % 60)

    if TimerMode == 2 then
        return d .. STRINGS.eventtimer.time.hour .. min .. STRINGS.eventtimer.time.minutes .. s .. STRINGS.eventtimer.time.seconds
    else
        return d .. STRINGS.eventtimer.time.day .. min .. STRINGS.eventtimer.time.minutes .. s .. STRINGS.eventtimer.time.seconds
    end
end

-- 反向提取信息
function Extract_by_format(text, format_str)
    if type(text) ~= "string" or type(format_str) ~= "string" then return end
    local safe = format_str:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    local pattern = safe:gsub("%%%%s", "(.*)")
    return text:match(pattern)
end

-- 根据世界类型返回一段字符串
function GetWorldtypeStr()
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

local env = env
GLOBAL.EventTimer = {
    env = env,
    UIButton = GetModConfigData("UIButton", true), -- UI开关何时显示
    UpdateTime = GetModConfigData("UpdateTime", false), -- 服务器数据更新频率
    ClientPrediction = GetModConfigData("ClientPrediction", true), -- 客户端预测倒计时
    TimerMode = GetModConfigData("BossTimer", true), -- 倒计时格式
    TimerTips = GetModConfigData("ShowTips", true), -- 醒目提示
    SyncTimer = GetModConfigData("SyncTimer", false), -- 跨世界同步计时
}

----------------------------------------加载模组---------------------------------------

modimport("Languages/" .. ModLanguage) -- 加载翻译

AddReplicableComponent("warningtimer")

modimport("main/commands") -- 调试指令
modimport("main/warningevent") -- 事件计时功能
modimport("main/modcompat") -- 检测其它模组

----------------------------------------鼠标跟随补丁---------------------------------------

GLOBAL.setfenv(1, GLOBAL)
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
env.AddClassPostConstruct("widgets/widget", ModFollowMouse)

----------------------------------------镜头缩放补丁---------------------------------------

local function IsCursorOnHUD()
	local input = TheInput
	return input.hoverinst and input.hoverinst.Transform == nil
end

local function playercontroller_postinit(self)
	local old_DoCameraControl = self.DoCameraControl
	function self:DoCameraControl()
		if not ((TheInput:IsControlPressed(CONTROL_ZOOM_IN) or TheInput:IsControlPressed(CONTROL_ZOOM_OUT)) and IsCursorOnHUD() ) then
			if old_DoCameraControl ~= nil then old_DoCameraControl(self) end
		end
	end
end

env.AddComponentPostInit("playercontroller",playercontroller_postinit)
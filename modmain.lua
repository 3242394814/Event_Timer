-- 以防万一
GLOBAL.setmetatable(env, {
    __index = function(t, k)
        -- local info = GLOBAL.debug.getinfo(2)
        -- print("[全局事件计时器] 当前正在尝试从全局环境获取值", k, "调用于", info.source, info.currentline)
        return GLOBAL.rawget(GLOBAL, k)
    end
})

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
    -- Asset("ATLAS", "images/Rift_Split.xml"), -- 双裂隙
	-- Asset("IMAGE", "images/Rift_Split.tex"),
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
    Asset("ATLAS", "images/Volcano_Active.xml"), -- 正在爆发的火山
    Asset("IMAGE", "images/Volcano_Active.tex"),
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
    Asset("ANIM", "anim/nigthmarephaseindicator.zip"), -- 远古遗迹阶段倒计时贴图，来自【Nightmare phase indicator】模组
}

----------------------------------------语言检测---------------------------------------

ModLanguage = GetModConfigData("language")

local _languages = {
	-- de = "de", --german
	-- es = "es", --spanish
	-- fr = "fr", --french
	-- it = "it", --italian
	-- ko = "ko", --korean
	-- --Note: The only language mod I found that uses "pt" is also brazilian portuguese -M
	-- pt = "pt", --portuguese
	-- br = "pt", --brazilian portuguese
	-- pl = "pl", --polish
	-- ru = "ru", --russian
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

modimport("Languages/" .. ModLanguage) -- 加载模组字符串
modimport("scripts/bbgoat_utils/utils") -- 加载模组工具
modimport("main/timerprefab")

----------------------------------------定义模组环境函数---------------------------------------

local STRINGS = GLOBAL.STRINGS
local TimerMode = GetModConfigData("BossTimer")
local SyncTimer = GetModConfigData("SyncTimer")

-- 填充Prefab名字
--- @param str string
--- @return string, number
function ReplacePrefabName(str)
	if not GLOBAL.checkstring(str) then return str end
    return str:gsub("<prefab=(.-)>", function(prefab)
        local key = prefab:upper()
        return STRINGS.NAMES[key] or prefab
    end)
end

-- 格式化时间
function TimeToString(seconds)
    if not GLOBAL.checknumber(seconds) then return seconds end
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

-- 反向格式化时间
local day_str = STRINGS.eventtimer.time.day
local hour_str = STRINGS.eventtimer.time.hour
local min_str = STRINGS.eventtimer.time.minutes
local sec_str = STRINGS.eventtimer.time.seconds
local StringToTime_format_1 = "(.*)".. day_str .. "(.*)" .. min_str .. "(.*)" .. sec_str
local StringToTime_format_2 = "(.*)" .. hour_str .. "(.*)" .. min_str .. "(.*)" .. sec_str
function StringToTime(string)
    if not GLOBAL.checkstring(string) then return string end
    local time = 0
    local daytime = TimerMode == 2 and 3600 or TUNING.TOTAL_DAY_TIME
    local format = TimerMode == 2 and StringToTime_format_2 or StringToTime_format_1
    local d,m,s = string.match(string, format)
    d = GLOBAL.tonumber(d)
    m = GLOBAL.tonumber(m)
    s = GLOBAL.tonumber(s)
    if d and m and s then
        time = time + d * daytime
        time = time + m * 60
        time = time + s
        return time
    end
end

-- 反向提取信息
function Extract_by_format(text, format_str)
    if not GLOBAL.checkstring(text) or not GLOBAL.checkstring(format_str) then return end
    local safe = format_str:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
    local pattern = safe:gsub("%%%%s", "(.*)")
    return text:match(pattern)
end

-- 根据世界类型返回一段字符串，兼容热带冒险
function GetWorldtypeStr()
    if GLOBAL.TheWorld:HasTag("porkland") then
        return "porkland"
    elseif GLOBAL.TheWorld:HasTag("island") or GLOBAL.TheWorld:HasTag("volcano") then
        return "shipwrecked"
    elseif GLOBAL.TheWorld:HasTag("cave") then
        return "cave"
    else
        local ThePlayer = GLOBAL.ThePlayer
        if ThePlayer and TUNING.TROPICAL_ADVENTURE_ACTIVATED then
            if ThePlayer.AwareInVolcanoArea and ThePlayer:AwareInVolcanoArea() then
                return "shipwrecked"
            elseif ThePlayer.AwareInShipwreckedArea and ThePlayer:AwareInShipwreckedArea() then
                return "shipwrecked"
            elseif ThePlayer.AwareInHamletArea and ThePlayer:AwareInHamletArea() then
                return "porkland"
            end
        end
        return "forest"
    end
end

----------------------------------------事件计时需要用到的函数---------------------------------------

-- 从worldsettingstimer或TimerPrefabs获取倒计时
local function GetWorldSettingsTimeLeft(name, prefab)
    return function()
        local ent = GLOBAL.TheWorld
        if prefab then
            ent = GLOBAL.TimerPrefabs[prefab]
        end
        if ent and ent.components.worldsettingstimer then
            if not ent.components.worldsettingstimer:IsPaused(name) then
                local time = ent.components.worldsettingstimer:GetTimeLeft(name)
                return time and time < 65535 and time
            end
        end
    end
end

-- 合并字符串
local function CombineLines(...)
    local lines, argnum = nil, select("#",...)

    for i = 1, argnum do
        local v = select(i, ...)

        if v ~= nil then
            lines = lines or {}
            lines[#lines+1] = tostring(v)
        end
    end

    return (lines and table.concat(lines, "\n")) or nil
end

-- 根据冬季盛宴活动决定anim
local function ChangeanimByWintersFeast(self)
    if GLOBAL.IsSpecialEventActive(GLOBAL.SPECIAL_EVENTS.WINTERS_FEAST) then
        self.anim = self.winterfeastanim
    else
        self.anim = self.defaultanim
    end
end

-- 根据世界类型决定image
local function ChangeimageByWorld(self)
    local worldtype = GetWorldtypeStr()
    if worldtype == "porkland" then
        self.image = self.porklandimage
    elseif worldtype == "shipwrecked" then
        self.image = self.islandimage
    elseif worldtype == "cave" then
        self.image = self.caveimage
    else
        self.image = self.forestimage
    end
end

-- 根据世界类型决定anim
local function ChangeanimByWorld(self)
    local worldtype = GetWorldtypeStr()
    if worldtype == "porkland" then
        self.anim = self.porklandanim
    elseif worldtype == "shipwrecked" then
        self.anim = self.islandanim
    elseif worldtype == "cave" then
        self.anim = self.caveanim
    else
        self.anim = self.forestanim
    end
end

-- 将字符串打包为一个返回该字符串的函数
local function StringToFunction(str)
    return function()
        return str
    end
end

-- 如果event_time > 0，在刚进入游戏的10秒内返回true
local function JustEntered(event_time)
    if not GLOBAL.checknumber(event_time) then return end
    return GLOBAL.GetTime() < 10 and event_time > 0
end

-- 当time在0~2秒时返回true
local function ready_attack(time)
    if not GLOBAL.checknumber(time) then return end
    if time < 2 and time > 0 then
        return true
    end
    return false
end

-- 获取事件计时
local file_env = {
    TimeToString = TimeToString, -- 格式化时间
    StringToTime = StringToTime, -- 将字符串转换为时间
    SyncTimer = SyncTimer, -- 跨世界同步计时
    Upvaluehelper = Upvaluehelper,
    MOD_util = MOD_util,
    ReplacePrefabName = ReplacePrefabName, -- 填充Prefab名字
    Extract_by_format = Extract_by_format, -- 反向提取信息
    GetWorldtypeStr = GetWorldtypeStr, -- 根据世界类型返回一段字符串
    AddPrefabPostInit = AddPrefabPostInit,
    AddComponentPostInit = AddComponentPostInit,
    ---
    GetWorldSettingsTimeLeft = GetWorldSettingsTimeLeft, -- 从worldsettingstimer或TimerPrefabs获取倒计时
    CombineLines = CombineLines, -- 合并字符串
    ---
    ChangeanimByWintersFeast = ChangeanimByWintersFeast, -- 根据冬季盛宴活动决定anim
    ChangeimageByWorld = ChangeimageByWorld, -- 根据世界类型决定image
    ChangeanimByWorld = ChangeanimByWorld, -- 根据世界类型决定anim
    StringToFunction = StringToFunction, -- 将字符串打包为一个返回该字符串的函数
    JustEntered = JustEntered, -- 如果event_time > 0，在刚进入游戏的10秒内返回true
    ready_attack = ready_attack, -- 当time在0~2秒时返回true
}
if GLOBAL.TheNet:GetIsServer() then
    AddComponentPostInit("clock", function(self)
        file_env.CalcTimeOfDay = Upvaluehelper.GetUpvalue(self.Dump, "CalcTimeOfDay") -- 今天还剩多少时间
    end)
    AddPrefabPostInit("world", function(inst)
        file_env.TheWorld = inst
    end)
end

GLOBAL.setmetatable(file_env, {
    __index = function(t, k)
        return GLOBAL.rawget(GLOBAL, k)
    end
})
local RequireEvent_list = {}
function RequireEvent(file_name)
    if not GLOBAL.checkstring(file_name) then return end

    file_name = MODROOT .. "scripts/EventsTimer/" .. file_name .. ".lua"

    if not RequireEvent_list[file_name] then
	    RequireEvent_list[file_name] = { Import(file_name, file_env) }
    end
    return GLOBAL.unpack(RequireEvent_list[file_name])
end

----------------------------------------模组环境映射到全局环境---------------------------------------

local env = env
GLOBAL.EventTimer = {
    env = env,
    -- 服务端设置
    UpdateTime = GetModConfigData("UpdateTime", false), -- 服务器数据更新频率
    TimerMode = TimerMode, -- 倒计时格式
    SyncTimer = SyncTimer, -- 跨世界同步计时
    -- 客户端设置
    UIButton = GetModConfigData("UIButton", true), -- UI开关何时显示
    ClientPrediction = GetModConfigData("ClientPrediction", true), -- 客户端预测倒计时
    TimerTips = GetModConfigData("ShowTips", true), -- 醒目提示
}

----------------------------------------加载模组---------------------------------------

RW_Data = PersistentData('mod_config_data/Events_Timer.json') -- 存取数据
RW_Data:Load()

-- modimport("main/commands") -- 调试指令
modimport("main/warningevent") -- 事件计时功能
modimport("main/modcompat") -- 检测其它模组
modimport("keybind") -- 键位绑定优化

AddReplicableComponent("warningtimer") -- 事件计时组件

----------------------------------------鼠标跟随---------------------------------------

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

    self.BBGoat_FollowMouse = function(_self)
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
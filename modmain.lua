-- 以防万一
GLOBAL.setmetatable(env, {
    __index = function(t, k)
        -- local info = GLOBAL.debug.getinfo(2)
        -- print("[全局事件计时器 - 客户端版] 当前正在尝试从全局环境获取值", k, "调用于", info.source, info.currentline)
        return GLOBAL.rawget(GLOBAL, k)
    end
})

if TUNING.GlobalEventsTimerEnabled then
    print("[全局事件计时器 - 客户端版] 检测到服务器版全局事件计时器模组已启用，本模组停止加载")
    return
end

----------------------------------------加载我的工具---------------------------------------

if not GLOBAL.rawget(GLOBAL, "BBGOAT_utils") then
    if TUNING.suggest_to_subscribe_bbgoat_basementmod then
        return
    end
    TUNING.suggest_to_subscribe_bbgoat_basementmod = true

	local function should_show_dig()
		if TheNet:IsDedicated() then
			return false
		end
		if not TheFrontEnd then
			return false
		end
		if IsMigrating() then
			return false
		end
		return not InGamePlay()
	end

	local _languages = {
		zh = true, --Chinese for Steam
		zhr = true, --Chinese for WeGame
		ch = true, --Chinese mod
		chs = true, --Chinese mod
		sc = true, --simple Chinese
		chinese = true, --Chinese mod
		zht = true, --traditional Chinese for Steam
		tc = true, --traditional Chinese
		cht = true, --Chinese mod
	}
	local lang = _G.LanguageTranslator and _G.LanguageTranslator.defaultlang
	local isCH = lang and _languages[lang]

    AddGamePostInit(function()
        TheGlobalInstance:DoTaskInTime(0.1, function()
            if not should_show_dig() then return end
            local PopupDialogScreen = require "screens/redux/popupdialog"
            TheFrontEnd:PushScreen(PopupDialogScreen(
                modinfo.name,
                isCH and "模组基础运行库缺失！\n你缺少了模组基础运行库，你必须去订阅才能继续使用本模组" or
                        "Mod Runtime Library Missing!\nYou are missing the required runtime library for this mod. Please subscribe to it before continuing to use this mod.",
                {
                    {
                        text = isCH and "订阅/启用运行库模组" or "Subscribe/Enable mod",
                        cb = function()
                            local modname = "workshop-3750536829"
                            if table.contains(TheSim:GetModDirectoryNames(), modname) then
                                KnownModIndex:Enable(modname)
                                KnownModIndex:Save()
                                TheGlobalInstance:DoTaskInTime(0.5, function()
                                    TheNet:Disconnect(true)
                                    TheSim:ResetError()
                                    StartNextInstance()
                                end)
                            else
                                VisitURL("https://steamcommunity.com/sharedfiles/filedetails/?id=3750536829")
                                TheSim:SubscribeToMod("workshop-3750536829")
                                TheFrontEnd:PopScreen()
                                TheFrontEnd:PushScreen(PopupDialogScreen(
                                    isCH and "已订阅" or "Subscribed",
                                    isCH and "请前往模组列表启用【冰冰羊的模组运行库】模组" or "Please go to the mod list to enable the runtime library mod named\n\"BBGOAT Utils\"",
                                    {
                                        {
                                            text = isCH and "好的" or "OK",
                                            cb = function()
                                                TheFrontEnd:PopScreen()
                                            end
                                        }
                                    }
                                ))
                            end
                        end
                    },
                    {
                        text = isCH and "返回" or "Back",
                        cb = function()
                            TheFrontEnd:PopScreen()
                        end
                    },
                }
            ))
        end)
    end)
    return
end

Upvaluehelper = GLOBAL.BBGOAT_utils.Upvaluehelper
MOD_util = GLOBAL.BBGOAT_utils.MOD_util
BBGOAT_util = GLOBAL.BBGOAT_utils.BBGOAT_util

----------------------------------------判断某个模组是否加载---------------------------------------

function Ismodloaded(name)
	return GLOBAL.KnownModIndex:IsModEnabledAny(name)
end

----------------------------------------检查是否需要运行---------------------------------------

local mode_list = {
    OceanFishing = true, -- 海钓随机物品
    DC_FGC_PVP = true, -- 花花世界-淘汰系统
}
local modid_list = {
    3273001012, -- 欧皇模拟器
    3183295941, -- 新海难抽奖机（并非新，已经很久没维护了）
    3139858765, -- 无资源海钓
}

local server_info = GLOBAL.TheNet:GetServerListing()
if server_info and server_info.mode and mode_list[server_info.mode] then
    return
end
for _, modid in ipairs(modid_list) do
    if Ismodloaded("workshop-" .. modid) then
        return
    end
end

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
    Asset("ATLAS", "images/dyc_panel_shadow.xml"), -- 醒目提示部件背景，来自单机饥荒模组【全能信息面板】，感谢DYC
    Asset("IMAGE", "images/dyc_panel_shadow.tex"),
    Asset("ANIM", "anim/nigthmarephaseindicator_eventtimer_client.zip"), -- 远古遗迹阶段倒计时贴图，来自【Nightmare phase indicator】模组
}

----------------------------------------语言检测---------------------------------------

ModLanguage = GetModConfigData("language")

local _languages = {
    -- de = "de", -- german
    -- es = "es", -- spanish
    -- fr = "fr", -- french
    -- it = "it", -- italian
    -- ko = "ko", -- korean
    --Note: The only language mod I found that uses "pt" is also brazilian portuguese -M
    -- pt = "pt", -- portuguese
    -- br = "pt", -- brazilian portuguese
    -- pl = "pl", -- polish
    -- ru = "ru", -- russian
    zh = "zh", -- Chinese for Steam
    zhr = "zh", -- Chinese for WeGame
    ch = "zh", -- Chinese mod
    chs = "zh", -- Chinese mod
    sc = "zh", -- simple Chinese
    chinese = "zh", -- Chinese mod
    zht = "zh", -- traditional Chinese for Steam
    tc = "zh", -- traditional Chinese
    cht = "zh", -- Chinese mod
}

if _languages[ModLanguage] ~= nil then
    ModLanguage = _languages[ModLanguage]
else
    ModLanguage = "en"
end

local PersistentData = GLOBAL.BBGOAT_utils.PersistentData
RW_Data = PersistentData('mod_config_data/Events_Timer.json') -- 存取数据
RW_Data:Load()

----------------------------------------模组环境映射到全局环境---------------------------------------

local TimerMode = GetModConfigData("BossTimer")
local env = env
local EventTimer
EventTimer = {
    env = env,
    GetTimeFromServerMod = {}, -- 交给服务器模组提供数据的事件列表
    TimerMode = TimerMode, -- 倒计时格式
    UIButton = GetModConfigData("UIButton"), -- UI开关何时显示
    ClientPrediction = GetModConfigData("ClientPrediction"), -- 客户端预测倒计时
    TimerTips = GetModConfigData("ShowTips"), -- 醒目提示
}
-- 是否使用远程命令获取时间数据
EventTimer.GetTimeFromRemoteCommand = GetModConfigData("GetTimeFromRemoteCommand") and GLOBAL.TheNet:GetIsServerAdmin()

GLOBAL.EventTimer = EventTimer

modimport("Languages/" .. ModLanguage) -- 加载模组字符串

----------------------------------------定义模组环境函数---------------------------------------

function Import(file_name, file_env)
	local f = GLOBAL.kleiloadlua(file_name)
	if f and type(f) == "function" then
        GLOBAL.setfenv(f, file_env or env)
        return f()
	else
		local info = debug.getinfo(3)
		local filename, line = info.source or "???", info.currentline or "???"
		print("[警告] Import文件失败，文件名: " .. file_name .. "\n本函数调用于 " .. tostring(filename) .. ":" .. tostring(line))
	end
end

-- 获取其它MOD的env
function GetModenv(modname)
	return GLOBAL.ModManager:GetMod(modname) and GLOBAL.ModManager:GetMod(modname).env
end

local STRINGS = GLOBAL.STRINGS

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
local cache_world_type
function GetWorldtypeStr()
    local ThePlayer = GLOBAL.ThePlayer
    if TUNING.TROPICAL_ADVENTURE_ACTIVATED and ThePlayer then
        if ThePlayer.AwareInVolcanoArea and ThePlayer:AwareInVolcanoArea() then
            return "shipwrecked"
        elseif ThePlayer.AwareInShipwreckedArea and ThePlayer:AwareInShipwreckedArea() then
            return "shipwrecked"
        elseif ThePlayer.AwareInHamletArea and ThePlayer:AwareInHamletArea() then
            return "porkland"
        end
    end

    if not cache_world_type then
        local TheWorld = GLOBAL.TheWorld
        if not TheWorld then return end

        if TheWorld:HasTag("porkland") then
            cache_world_type = "porkland"
        elseif TheWorld:HasTag("island") or TheWorld:HasTag("volcano") then
            cache_world_type = "shipwrecked"
        elseif TheWorld:HasTag("cave") then
            cache_world_type = "cave"
        else
            cache_world_type = "forest"
        end
    end
    return cache_world_type
end

local client_prediction_tasks = {} -- 预测倒计时任务列表
local Getformat_format_1 = "(%d+)".. day_str .. "(%d+)" .. min_str .. "(%d+)" .. sec_str
local Getformat_format_2 = "(%d+)" .. hour_str .. "(%d+)" .. min_str .. "(%d+)" .. sec_str

local function Getformat(text)
    local format = TimerMode == 2 and Getformat_format_2 or Getformat_format_1
    return string.gsub(text, format, "%%s")
end

local function get_new_text(v, datatext)
    local results = { Extract_by_format(datatext, v) }
    if results[1] then
        for k1, v1 in pairs(results) do
            if string.find(v1, min_str .. "(.*)" .. sec_str) then
                v1 = StringToTime(v1) -- 尝试将字符串转为数字
                if type(v1) == "number" then
                    v1 = v1 - 1
                    if v1 < 0 then
                        results[k1] = TimeToString(0) -- 小于0时停止计算
                    else
                        results[k1] = TimeToString(v1) -- 减一后转换为字符串保存到results对应的值里
                    end
                end
            end
        end
        v = v:gsub("%%([^sd%%])", "%%%%%1")
        v = v:gsub("%%$", "%%%%")
        local new_text = string.format(ReplacePrefabName(v), unpack(results))
        return new_text
    else
        return
    end
end

-- 更新客户端预测倒计时
local function UpdateClientPrediction(name)
    local ThePlayer = GLOBAL.ThePlayer
    local ClientWarningEvents = GLOBAL.ClientWarningEvents

    if not (ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData) then
        return
    end

    -- time
    local time = ThePlayer.HUD.WarningEventTimeData[name .. "_time"]
    time = time - 1
    if time >= 0 then
        SaveTimeData(name, time, true)
    else
        -- 时间结束，清理任务
        ThePlayer.HUD.WarningEventTimeData[name .. "_time"] = 0

        -- 支持设置不清理文本
        if not (ClientWarningEvents[name] and ClientWarningEvents[name].DisableClientPredictionClearText) then
            ThePlayer.HUD.WarningEventTimeData[name .. "_text"] = ""
        end

        if client_prediction_tasks[name] then
            client_prediction_tasks[name]:Cancel()
            client_prediction_tasks[name] = nil
        end
        ThePlayer.HUD:UpdateWarningEvents()
    end

    -- text
    local datatext = ThePlayer.HUD.WarningEventTimeData[name .. "_text"]
    if datatext and datatext ~= "" then
        local new_text = get_new_text(Getformat(datatext), datatext)
        SaveTextData(name, new_text or "", true)
    end
end

-- 获取当前世界运行时间
local Last_time
function GetWorldTime()
    local world = GLOBAL.TheWorld
    local state_time = world.state.time
    local state_cycles = world.state.cycles
    local total_day_time = TUNING.TOTAL_DAY_TIME
    local sys_time = (state_cycles + state_time) * total_day_time

    if Last_time then
        local diff_time = sys_time - Last_time
        if state_time < 0.98 or diff_time > total_day_time + 5 or diff_time < total_day_time - 5 then
            Last_time = sys_time
        end
    else
        Last_time = sys_time
    end

    return Last_time
end

local SessionId
function SaveTimeData(name, time, from_prediction)
    local ThePlayer = GLOBAL.ThePlayer
    local TheWorld = GLOBAL.TheWorld
    local ClientWarningEvents = GLOBAL.ClientWarningEvents

    if not (ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData and GLOBAL.checknumber(time)) then
        return
    end

    ThePlayer.HUD.WarningEventTimeData[name .. "_time"] = math.floor(time)
    ThePlayer.HUD:UpdateWarningEvents()

    -- 存储倒计时数据至文件
    if not from_prediction and not (ClientWarningEvents[name] and ClientWarningEvents[name].DisableSaveTime) then
        local filedata = RW_Data:GetValue("WarningEventTimeData") or {}
        SessionId = SessionId or (TheWorld and TheWorld.net and TheWorld.net.components.shardstate and TheWorld.net.components.shardstate:GetMasterSessionId())
        local world_data = filedata[SessionId]
        if world_data then
            if time == 0 then
                world_data[name] = nil
            else
                local next_attack_time = GetWorldTime() + time -- 下次袭击的世界时间点
                world_data[name] = next_attack_time
            end
            world_data.save_time = GLOBAL.os.time() -- 记录此存档最后一次更新事件记录的时间，以便清理长期未游玩的存档数据
            RW_Data:SetValue("WarningEventTimeData", filedata)
        end
    end

    -- 预测倒计时功能
    if not (ClientWarningEvents[name] and ClientWarningEvents[name].DisableClientPrediction) then
        if not from_prediction and client_prediction_tasks[name] then
            client_prediction_tasks[name]:Cancel()
            client_prediction_tasks[name] = nil
        end
        if not client_prediction_tasks[name] then
            client_prediction_tasks[name] = TheWorld:DoPeriodicTask(1, function() UpdateClientPrediction(name) end)
        end
    end
end

-- 存储文本倒计时数据
function SaveTextData(name, text, from_prediction)
    local ThePlayer = GLOBAL.ThePlayer
    local TheWorld = GLOBAL.TheWorld
    local ClientWarningEvents = GLOBAL.ClientWarningEvents

    if not (ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData and GLOBAL.checkstring(text)) then
        return
    end

    ThePlayer.HUD.WarningEventTimeData[name .. "_text"] = text
    ThePlayer.HUD:UpdateWarningEvents()

    -- 预测倒计时功能
    if not (ClientWarningEvents[name] and ClientWarningEvents[name].DisableClientPrediction) then
        if not from_prediction and client_prediction_tasks[name] then
            client_prediction_tasks[name]:Cancel()
            client_prediction_tasks[name] = nil
        end
        if not client_prediction_tasks[name] then
            client_prediction_tasks[name] = TheWorld:DoPeriodicTask(1, function() UpdateClientPrediction(name) end)
        end
    end
end

-- 允许读取保存的自定义数据
DataFilePostInitFN = {}
function AddLoadDataFilePostInit(fn)
    table.insert(DataFilePostInitFN, fn)
end

----------------------------------------退出房间/穿越世界时写入数据到文件----------------------------------------

local _DoRestart = GLOBAL.DoRestart
function GLOBAL.DoRestart(...)
    RW_Data:Save()
    return _DoRestart(...)
end
Upvaluehelper.HideFn(GLOBAL.DoRestart, _DoRestart)

local _MigrateToServer = GLOBAL.MigrateToServer
function GLOBAL.MigrateToServer(ip, port, ...)
    RW_Data:Save()
    return _MigrateToServer(ip, port, ...)
end
Upvaluehelper.HideFn(GLOBAL.MigrateToServer, _MigrateToServer)

----------------------------------------事件计时需要用到的函数---------------------------------------

local function fmtval(v)
    if v == nil then
        return "nil"
    elseif type(v) == "string" then
        return string.format("%q", v)
    else
        return tostring(v)
    end
end

-- 从worldsettingstimer或TimerPrefabs获取倒计时
local function GetWorldSettingsTimeLeft(name, prefab, fn)
    local cmd = [[
local name = %s
local prefab = %s
local time, not_found = _G.EventTimerClient.GetWorldSettingsTimeLeft(name, prefab)
return DataDumper( { time = time, not_found = not_found } )
]]
    BBGOAT_util:remote(string.format(cmd, fmtval(name), fmtval(prefab)), nil, fn)
end

-- 合并字符串
function CombineLines(...)
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

-- 目标死亡时开始计时
local function HookDeath(prefab, event, func)
    AddPrefabPostInit(prefab, function(inst)
        SaveTimeData(event, 0)
        inst:ListenForEvent("onremove", function(inst)
            if inst and inst:IsValid() and inst.AnimState then
                local bank, anim, frame = inst.AnimState:GetHistoryData()
                if anim:find("death") then
                    func(event, inst)
                end
            end
        end)
    end)
end

-- 获取事件计时
local file_env = {
    EventTimer = EventTimer,
    GetWorldTime = GetWorldTime,
    SaveTimeData = SaveTimeData,
    SaveTextData = SaveTextData,
    AddLoadDataFilePostInit = AddLoadDataFilePostInit,
    HookDeath = HookDeath,
    TimeToString = TimeToString, -- 格式化时间
    StringToTime = StringToTime, -- 将字符串转换为时间
    Upvaluehelper = Upvaluehelper,
    MOD_util = MOD_util,
    BBGOAT_util = BBGOAT_util,
    RW_Data = RW_Data,
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

AddComponentPostInit('clock', function(clock)
    local SW = GLOBAL.TheWorld:HasTag("island") or GLOBAL.TheWorld:HasTag("volcano")
    local HAM = GLOBAL.TheWorld:HasTag("porkland")
    local oldGetDebugString = SW and clock.GetDebugString_tropical or HAM and clock.GetDebugString_plateau or clock.GetDebugString
    local oldDump = SW and clock.Dump_tropical or HAM and clock.Dump_plateau or clock.Dump

    local _phase = Upvaluehelper.GetUpvalue(oldGetDebugString, '_phase')
    local _remainingtimeinphase = Upvaluehelper.GetUpvalue(oldGetDebugString, '_remainingtimeinphase')

    local _segs = Upvaluehelper.GetUpvalue(oldDump, '_segs')
    local _totaltimeinphase = Upvaluehelper.GetUpvalue(oldDump,'_totaltimeinphase')

    if _totaltimeinphase and _remainingtimeinphase and _segs and _phase then
        file_env.CalcTimeOfDay = function()
            local time_of_day = _totaltimeinphase:value() - _remainingtimeinphase:value()
            for i = 1, _phase:value() - 1 do
                time_of_day = time_of_day + _segs[i]:value() * TUNING.SEG_TIME
            end
            return TUNING.TOTAL_DAY_TIME - time_of_day
        end
    end
end)

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

----------------------------------------加载模组---------------------------------------

modimport("main/fe_patches.lua") -- 动态模组图标
modimport("keybind") -- 键位绑定优化
-- modimport("main/commands") -- 调试指令
modimport("main/UI") -- 屏幕左上角倒计时/面板开关按钮/醒目提示UI
modimport("main/warningevents") -- 事件列表
modimport("main/modcompat") -- 检测其它模组
modimport("main/main") -- 获取各事件计时时间

----------------------------------------修改环境----------------------------------------

GLOBAL.setfenv(1, GLOBAL)

----------------------------------------鼠标跟随---------------------------------------

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
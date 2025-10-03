local Extract_by_format = EventTimer.env.Extract_by_format
local ReplacePrefabName = EventTimer.env.ReplacePrefabName
local TimerMode = EventTimer.TimerMode
local UpdateTime = EventTimer.UpdateTime
local TimeToString = EventTimer.env.TimeToString

local day_str = STRINGS.eventtimer.time.day
local hour_str = STRINGS.eventtimer.time.hour
local min_str = STRINGS.eventtimer.time.minutes
local sec_str = STRINGS.eventtimer.time.seconds

local StringToTime_format_1 = "(.*)".. day_str .. "(.*)" .. min_str .. "(.*)" .. sec_str
local StringToTime_format_2 = "(.*)" .. hour_str .. "(.*)" .. min_str .. "(.*)" .. sec_str

local Getformat_format_1 = "(%d+)".. day_str .. "(%d+)" .. min_str .. "(%d+)" .. sec_str
local Getformat_format_2 = "(%d+)" .. hour_str .. "(%d+)" .. min_str .. "(%d+)" .. sec_str

-- 反向格式化时间
local function StringToTime(string)
    if type(string) ~= "string" then return end
    local time = 0
    local daytime = TimerMode == 2 and 3600 or TUNING.TOTAL_DAY_TIME
    local format = TimerMode == 2 and StringToTime_format_2 or StringToTime_format_1
    local d,m,s = string.match(string, format)
    d = tonumber(d)
    m = tonumber(m)
    s = tonumber(s)
    if d and m and s then
        time = time + d * daytime
        time = time + m * 60
        time = time + s
        return time
    end
end

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

local WarningTimer = Class(function(self, inst)
	self.inst = inst

    for warningevent in pairs(WarningEvents) do
        self[warningevent .. "_time"] = net_shortint(inst.GUID, warningevent .. "_time",  warningevent .. "_time_dirty")
        self[warningevent .. "_time_shardrpc"] = net_shortint(inst.GUID, warningevent .. "_time_shardrpc", warningevent .. "_time_dirty")
        self[warningevent .. "_text"] = net_string(inst.GUID, warningevent .. "_text", warningevent .. "_text_dirty")
        self[warningevent .. "_text_shardrpc"] = net_string(inst.GUID, warningevent .. "_text_shardrpc", warningevent .. "_text_dirty")


        if not TheNet:IsDedicated() then
            inst:ListenForEvent(warningevent .. "_time_dirty", function(inst)
                self:OnWarningEventDirty(inst, warningevent, "time", true)
            end)

            inst:ListenForEvent(warningevent .. "_text_dirty", function(inst)
                self:OnWarningEventDirty(inst, warningevent, "text", true)
            end)
        end
    end

    if not TheNet:IsDedicated() then
        inst:DoPeriodicTask(0.5, function() self:OnUpdate() end)
    end
end)

local eventstime = {}
local client_prediction_tasks = {}
function WarningTimer:OnWarningEventDirty(inst, warningevent, type, fromserver)
    if type == "text" then
        eventstime[warningevent .. "_text"] = inst.replica.warningtimer[warningevent .. "_text"]:value() ~= "" and inst.replica.warningtimer[warningevent .. "_text"]:value()
                                            or inst.replica.warningtimer[warningevent .. "_text_shardrpc"]:value() ~= "" and inst.replica.warningtimer[warningevent .. "_text_shardrpc"]:value()
                                            or ""
    else
        eventstime[warningevent .. "_time"] = inst.replica.warningtimer[warningevent .. "_time"]:value() > 0 and inst.replica.warningtimer[warningevent .. "_time"]:value()
                                            or inst.replica.warningtimer[warningevent .. "_time_shardrpc"]:value() ~= 0 and inst.replica.warningtimer[warningevent .. "_time_shardrpc"]:value()
                                            or 0
    end

    if fromserver and client_prediction_tasks[warningevent] then
        client_prediction_tasks[warningevent]:Cancel()
        client_prediction_tasks[warningevent] = nil
    end

    if not client_prediction_tasks[warningevent] and UpdateTime > 1 then
        client_prediction_tasks[warningevent] = inst:DoPeriodicTask(1, function() self:UpdateClientPrediction(inst, warningevent) end)
    end
end

function WarningTimer:OnUpdate()
    if not ThePlayer or not ThePlayer.HUD then
        return
    end
    ThePlayer.HUD.WarningEventTimeData = eventstime
    ThePlayer.HUD:UpdateWarningEvents()
end

function WarningTimer:UpdateClientPrediction(inst, warningevent) -- 每个事件单独每秒运行一次
    if not EventTimer.ClientPrediction then return end
    local Dirty = false

    ----------------------------------------time---------------------------------------

    local time          = self[warningevent .. "_time"]:value() -- 本世界time
    local time_shardrpc = self[warningevent .. "_time_shardrpc"]:value() -- 其它世界time

    time = time - 1
    if time >= 0 then
        self[warningevent .. "_time"]:set_local(time)
        Dirty = true
    end

    time_shardrpc = time_shardrpc - 1
    if time_shardrpc >= 0 then
        self[warningevent .. "_time_shardrpc"]:set_local(time_shardrpc)
        Dirty = true
    end

    ----------------------------------------text---------------------------------------

    local new_text, shard_new_text

    local datatext = self[warningevent .. "_text"]:value() -- 本世界text

    local datatext_shardrpc  = self[warningevent .. "_text_shardrpc"]:value() -- 其它世界text
    local time_text_shardrpc -- 其它世界的time_text
    local time_text_fromShard -- 来自哪个世界

    if datatext ~= "" then
        new_text = get_new_text(Getformat(datatext), datatext)

        -- 如果上方的匹配失败了，直接使用上上方的time
        if not new_text then
            if time >= 0 then
                new_text = TimeToString(time)
            end
        end
    elseif datatext_shardrpc ~= "" then
        time_text_fromShard, time_text_shardrpc = string.match(datatext_shardrpc, "([^\n]*)\n(.*)" ) -- 提取出来自哪个世界，具体信息
        if time_text_fromShard and time_text_shardrpc then
            shard_new_text = get_new_text(Getformat(time_text_shardrpc), time_text_shardrpc)

            if not shard_new_text then
                if time_shardrpc >= 0 and time_text_fromShard then -- 如果上方的匹配失败了，直接使用上上方的time_shardrpc
                    shard_new_text = time_text_fromShard .. "\n" .. TimeToString(time_shardrpc)
                end
            else
                shard_new_text = time_text_fromShard .. "\n" .. shard_new_text
            end
        end
    end

    if new_text then
        self[warningevent .. "_text"]:set_local(new_text) -- 更新text
        Dirty = true
    elseif shard_new_text then
        self[warningevent .. "_text_shardrpc"]:set_local(shard_new_text) -- 更新text
        Dirty = true
    end

    if Dirty then
        -- 更新数据
        self:OnWarningEventDirty(inst, warningevent, "text")
        self:OnWarningEventDirty(inst, warningevent, "time")
    end
end

return WarningTimer
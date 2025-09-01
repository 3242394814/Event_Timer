local GetWorldtypeStr = EventTimer.env.GetWorldtypeStr
local Extract_by_format = EventTimer.env.Extract_by_format
local ReplacePrefabName = EventTimer.env.ReplacePrefabName
local ClientPrediction = EventTimer.ClientPrediction
local TimerMode = EventTimer.TimerMode
local UpdateTime = EventTimer.UpdateTime

-- 格式化时间
local function TimeToString(seconds)
    if type(seconds) ~= "number" then return seconds end
    local daytime = TimerMode == 2 and 3600 or TUNING.TOTAL_DAY_TIME
    local d = math.floor(seconds / daytime)
    local min = math.floor(seconds % daytime / 60)
    local s = math.floor(seconds % daytime % 60)

    if TimerMode == 2 then
        return d .. "时" .. min .. "分" .. s .. "秒"
    else
        return d .. "天" .. min .. "分" .. s .. "秒"
    end
end

-- 反向格式化时间
local function StringToTime(string)
    if type(string) ~= "string" then return end
    local time = 0
    local daytime = TimerMode == 2 and 3600 or TUNING.TOTAL_DAY_TIME
    local format = TimerMode == 2 and "(.*)时(.*)分(.*)秒" or "(.*)天(.*)分(.*)秒"
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
    local format = TimerMode == 2 and "(%d+)时(%d+)分(%d+)秒" or "(%d+)天(%d+)分(%d+)秒"
    return string.gsub(text, format, "%%s")
end

local function get_new_text(v, datatext)
    local results = { Extract_by_format(datatext, v) }
    if results[1] then
        for k1, v1 in pairs(results) do
            if string.find(v1,"分(.*)秒") then
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
        v = v:gsub("([%%])", "%%%1")
        v = v:gsub("%%%%s", "%%s")
        local new_text = string.format(ReplacePrefabName(v), unpack(results))
        return new_text
    else
        return
    end
end

local WaringTimer = Class(function(self, inst)
	self.inst = inst

    for waringevent in pairs(WaringEvents) do
        self[waringevent .. "_time"] = net_shortint(inst.GUID, waringevent .. "_time", "waringevent_dirty")
        self[waringevent .. "_time_shardrpc"] = net_shortint(inst.GUID, waringevent .. "_time_shardrpc", "waringevent_dirty")
        self[waringevent .. "_text"] = net_string(inst.GUID, waringevent .. "_text", "waringevent_dirty")
        self[waringevent .. "_text_shardrpc"] = net_string(inst.GUID, waringevent .. "_text_shardrpc", "waringevent_dirty")

        if not TheNet:IsDedicated() then
            inst:ListenForEvent("waringevent_dirty", function(inst) self:OnWaringEventDirty(inst) end)
        end
    end
end)

local update_task
function WaringTimer:OnWaringEventDirty(inst)
    if not ThePlayer or not ThePlayer.HUD then
        return
    end
    local eventstime = {}
    for waringevent in pairs(WaringEvents) do
        eventstime[waringevent .. "_text"] = inst.replica.waringtimer[waringevent .. "_text"]:value() ~= "" and inst.replica.waringtimer[waringevent .. "_text"]:value()
                                            or inst.replica.waringtimer[waringevent .. "_text_shardrpc"]:value() ~= "" and inst.replica.waringtimer[waringevent .. "_text_shardrpc"]:value()
                                            or ""

        eventstime[waringevent .. "_time"] = inst.replica.waringtimer[waringevent .. "_time"]:value() > 0 and inst.replica.waringtimer[waringevent .. "_time"]:value()
                                            or inst.replica.waringtimer[waringevent .. "_time_shardrpc"]:value() ~= 0 and inst.replica.waringtimer[waringevent .. "_time_shardrpc"]:value()
                                            or 0
    end
    ThePlayer.HUD.WaringEventTimeData = eventstime
    ThePlayer.HUD:UpdateWaringEvents()
    if not update_task and ClientPrediction and UpdateTime > 1 then
        print("[全局世界计时器] 开启客户端预测功能！")
        update_task = inst:DoPeriodicTask(1, function() self:OnUpdate(inst) end)
    end
end

function WaringTimer:OnUpdate(inst) -- 每秒运行一次
    local Dirty = false
    for waringevent in pairs(WaringEvents) do

        ----------------------------------------time---------------------------------------

        local time          = self[waringevent .. "_time"]:value() -- 本世界time
        local time_shardrpc = self[waringevent .. "_time_shardrpc"]:value() -- 其它世界time

        time = time - 1
        if time >= 0 then
            self[waringevent .. "_time"]:set_local(time)
            Dirty = true
        end

        time_shardrpc = time_shardrpc - 1
        if time_shardrpc >= 0 then
            self[waringevent .. "_time_shardrpc"]:set_local(time_shardrpc)
            Dirty = true
        end

        ----------------------------------------text---------------------------------------

        local new_text, shard_new_text

        local datatext = self[waringevent .. "_text"]:value() -- 本世界text

        local datatext_shardrpc  = self[waringevent .. "_text_shardrpc"]:value() -- 其它世界text
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
            self[waringevent .. "_text"]:set_local(new_text) -- 更新text
            Dirty = true
        elseif shard_new_text then
            self[waringevent .. "_text_shardrpc"]:set_local(shard_new_text) -- 更新text
            Dirty = true
        end
    end

    if Dirty then
        self:OnWaringEventDirty(inst) -- 更新数据
    end
end

return WaringTimer
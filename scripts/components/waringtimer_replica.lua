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
    if d and m and s then
        d = tonumber(d)
        m = tonumber(m)
        s = tonumber(s)

        time = time + d * daytime
        time = time + m * 60
        time = time + s
        return time
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

        local stringkey          = ReplacePrefabName(STRINGS.eventtimer[waringevent].cooldown) or ReplacePrefabName(STRINGS.eventtimer[waringevent].cooldowns[GetWorldtypeStr()]) -- 注意，目前只读cooldown和cooldown[世界类型]，且这里面必须包含%s，这样才能提取成功
        local datatext           = self[waringevent .. "_text"]:value() -- 本世界text
        local time_text -- 本世界time_text

        local datatext_shardrpc  = self[waringevent .. "_text_shardrpc"]:value() -- 其它世界text
        local time_text_shardrpc -- 其它世界的time_text
        local time_text_fromShard -- 来自哪个世界

        local need_format = false -- 最后是否需要使用string.format来格式化计时

        if datatext ~= "" then
            local extract_time_text = Extract_by_format(datatext, stringkey) -- 尝试按STRINGS格式提取时间信息，成功就标记need_format
            if extract_time_text then
                -- time_text = extract_time_text
                need_format = true
            end
            if time >= 0 then
                time_text = TimeToString(time) -- 直接引用上方time的值
            else
                time_text = nil
            end

            -- time_text = StringToTime(time_text) -- 将字符串转为数字
            -- if type(time_text) == "number" then
            --     time_text = time_text - 1
            --     if time_text < 0 then
            --         time_text = nil -- 小于0时停止计算
            --     else
            --         time_text = TimeToString(time_text) -- 减一后转换为字符串
            --     end
            -- else
            --     time_text = nil
            -- end
        elseif datatext_shardrpc ~= "" then
            time_text_fromShard, time_text_shardrpc = string.match(datatext_shardrpc, "([^\n]*)\n(.*)" ) -- 提取出来自哪个世界，具体信息
            if time_text_fromShard and time_text_shardrpc then
                local extract_time_text = Extract_by_format(time_text_shardrpc, stringkey) -- 尝试按STRINGS格式提取时间信息，成功就标记need_format
                if extract_time_text then
                    -- time_text_shardrpc = extract_time_text
                    need_format = true
                end
                if time_shardrpc >= 0 then
                    time_text_shardrpc = TimeToString(time_shardrpc) -- 直接引用上方time_shardrpc值
                else
                    time_text_shardrpc = nil
                end
                -- time_text_shardrpc = StringToTime(time_text_shardrpc) -- 将字符串转为数字
                -- if type(time_text_shardrpc) == "number" then
                --     time_text_shardrpc = time_text_shardrpc - 1
                --     if time_text_shardrpc < 0 then -- 小于0时停止计算
                --         time_text_shardrpc = nil
                --     else
                --         time_text_shardrpc = TimeToString(time_text_shardrpc) -- 减一后转换为字符串
                --     end
                -- else
                --     time_text_shardrpc = nil
                -- end
            else
                time_text_shardrpc = nil
            end
        end

        if time_text then
            local new_text = need_format and string.format(stringkey, time_text) or time_text
            self[waringevent .. "_text"]:set_local(new_text) -- 更新text
            Dirty = true
        elseif time_text_shardrpc then
            time_text_shardrpc = need_format and string.format(stringkey, time_text_shardrpc) or time_text_shardrpc
            local new_text = time_text_fromShard .. "\n" .. time_text_shardrpc
            self[waringevent .. "_text_shardrpc"]:set_local(new_text) -- 更新text
            Dirty = true
        end
    end

    if Dirty then
        self:OnWaringEventDirty(inst) -- 更新数据
    end
end

return WaringTimer
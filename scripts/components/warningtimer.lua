local UpdateTime = EventTimer.UpdateTime
local SyncTimer = EventTimer.SyncTimer
local function GetWorldType()
    if TheWorld:HasTag("porkland") then
        return STRINGS.eventtimer.worldtype.porkland
    elseif TheWorld:HasTag("island") then
        return STRINGS.eventtimer.worldtype.shipwrecked
    elseif TheWorld:HasTag("volcano") then
        return STRINGS.eventtimer.worldtype.volcano
    elseif TheWorld:HasTag("cave") then
        return STRINGS.eventtimer.worldtype.cave
    else
        return STRINGS.eventtimer.worldtype.forest
    end
end

 -- 记录数据重复次数
local valid_data = {}

local function OnUpdate(self)
    for warningevent, data in pairs(WarningEvents) do

        -- 初始化数据重复次数表
        if not valid_data[warningevent] then
            valid_data[warningevent] = {
                time_last = 0, -- 上次记录的时间
                time_sametick = 0, -- 重复次数
                time_valid = true, -- 数据是否有效

                text_sametick = 0,
                text_valid = true,
            }
        end

        local time
        if data.gettimefn then
            time = data.gettimefn()
            if time and time < 0 then time = 0 end -- 避免被负数影响

            if valid_data[warningevent].time_sametick > math.ceil(2 / UpdateTime) then -- 重复次数过多，删除数据
                if valid_data[warningevent].time_valid then
                    valid_data[warningevent].time_valid = false -- 标记数据无效
                    self.inst.replica.warningtimer[warningevent .. "_time"]:set(0) -- 更新本世界数据
                    if SyncTimer and not data.DisableShardRPC then -- 更新其它世界数据
                        SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_time_shardrpc"], nil, warningevent, 0, GetWorldType())
                    end
                end
            elseif time and time > 0  then -- 时间有效
                valid_data[warningevent].time_valid = true -- 标记数据有效
                self.inst.replica.warningtimer[warningevent .. "_time"]:set(time) -- 更新本世界数据
                if SyncTimer and not data.DisableShardRPC then -- 更新其它世界数据
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_time_shardrpc"], nil, warningevent, time, GetWorldType())
                end
            else
                self.inst.replica.warningtimer[warningevent .. "_time"]:set(time or 0)
            end

            -- 判断时间是否有变化
            if valid_data[warningevent].time_last == time then
                valid_data[warningevent].time_sametick = (valid_data[warningevent].time_sametick) + 1
            else
                valid_data[warningevent].time_sametick = 0
            end

            valid_data[warningevent].time_last = time -- 更新上次记录的时间
        end
        if data.gettextfn then
            local text = data.gettextfn(time)

            -- 更新本世界数据
            self.inst.replica.warningtimer[warningevent .. "_text"]:set(text or "")

            -- 更新其它世界数据
            if SyncTimer and not data.DisableShardRPC then
                if valid_data[warningevent].text_sametick > math.ceil(2 / UpdateTime) then -- 数据多次不变，删除其它世界的数据
                    if valid_data[warningevent].text_valid then
                        valid_data[warningevent].text_valid = false -- 标记数据无效
                        SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_text_shardrpc"], nil, warningevent, "", "")
                    end
                elseif text and text ~= "" then
                    valid_data[warningevent].text_valid = true -- 标记数据有效
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"]["event_text_shardrpc"], nil, warningevent, text, GetWorldType())
                end

                -- 标记无效数据
                if not text or text == "" then
                    valid_data[warningevent].text_sametick = (valid_data[warningevent].text_sametick) + 1
                else
                    valid_data[warningevent].text_sametick = 0
                end
            end
        end
    end
end

local WarningTimer = Class(function(self, inst)
    self.inst = inst

    -- 初始化数据
    for warningevent, data in pairs(WarningEvents) do
        self.inst.replica.warningtimer[warningevent .. "_time"]:set(0)
        self.inst.replica.warningtimer[warningevent .. "_text"]:set("")
        self.inst.replica.warningtimer[warningevent .. "_time_shardrpc"]:set(0)
        self.inst.replica.warningtimer[warningevent .. "_text_shardrpc"]:set("")
    end
    self.inst:DoPeriodicTask(UpdateTime , function() OnUpdate(self) end)
end)

return WarningTimer
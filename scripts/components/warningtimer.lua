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

 -- 记录数据是否有效、超过3次无效则清理
local valid_data = {}
for warningevent in pairs(WarningEvents) do
    valid_data[warningevent] = {
        time_valid = false,
        text_valid = false,

        time_notupdate = 0,
        text_notupdate = 0,
    }
end

local function MarkUnupdateData(warningevent, type)
    if type == 1 then
        if valid_data[warningevent].time_valid then
            local num = valid_data[warningevent].time_notupdate
            if num < 3 then
                num = num + 1
                valid_data[warningevent].time_notupdate = num
            else
                for id in pairs(Shard_GetConnectedShards()) do
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"][warningevent .. "_time_shardrpc"], id, 0)
                end
                valid_data[warningevent].time_valid = false
                valid_data[warningevent].time_notupdate = 0
            end
        end
    elseif type == 2 then
        if valid_data[warningevent].text_valid then
            local num = valid_data[warningevent].text_notupdate
            if num < 3 then
                num = num + 1
                valid_data[warningevent].text_notupdate = num
            else
                for id in pairs(Shard_GetConnectedShards()) do
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"][warningevent .. "_text_shardrpc"], id, "")
                end
                valid_data[warningevent].text_valid = false
                valid_data[warningevent].text_notupdate = 0
            end
        end
    end
end

local function OnUpdate(self)
    for warningevent, data in pairs(WarningEvents) do
        local time
        if data.gettimefn then
            time = data.gettimefn()
            if SyncTimer and time and time > 0 and not data.DisableShardRPC then
                valid_data[warningevent].time_valid = true

                for id in pairs(Shard_GetConnectedShards()) do
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"][warningevent .. "_time_shardrpc"], id, time , GetWorldType())
                end
            end

            self.inst.replica.warningtimer[warningevent .. "_time"]:set(time and time > 0 and time or 0)
            if not time or time == 0 and not data.DisableShardRPC then
                MarkUnupdateData(warningevent, 1) -- 标记并删除过期数据
            end
        end
        if data.gettextfn then
            local text = data.gettextfn(time)
            if SyncTimer and text and not data.DisableShardRPC then
                valid_data[warningevent].text_valid = true

                for id in pairs(Shard_GetConnectedShards()) do
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"][warningevent .. "_text_shardrpc"], id, text , GetWorldType())
                end
            end

            self.inst.replica.warningtimer[warningevent .. "_text"]:set(text or "")
            if not text and not data.DisableShardRPC then
                MarkUnupdateData(warningevent, 2) -- 标记并删除过期数据
            end
        end
    end
end

local WarningTimer = Class(function(self, inst)
    self.inst = inst
    self.inst:DoPeriodicTask(UpdateTime , function() OnUpdate(self) end)
end)

return WarningTimer
local SyncTimer = EventTimer.env.GetModConfigData("SyncTimer")
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

local function OnUpdate(self)
    for waringevent, data in pairs(WaringEvents) do
        local time
        if data.gettimefn then
            time = data.gettimefn()
            if SyncTimer and time and time > 0 and not data.DisableShardRPC then
                for id in pairs(Shard_GetConnectedShards()) do
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"][waringevent .. "_time_shardrpc"], id, time , GetWorldType())
                end
            end

            -- self.inst.replica.waringtimer[waringevent]:set_local(0)
            self.inst.replica.waringtimer[waringevent .. "_time"]:set(time or 0)
        end
        if data.gettextfn then
            local text = data.gettextfn(time)
            if SyncTimer and text and not data.DisableShardRPC then
                for id in pairs(Shard_GetConnectedShards()) do
                    SendModRPCToShard(SHARD_MOD_RPC["EventTimer"][waringevent .. "_text_shardrpc"], id, text , GetWorldType())
                end
            end

            self.inst.replica.waringtimer[waringevent .. "_text"]:set(text or "")
        end
    end
end

local WaringTimer = Class(function(self, inst)
    self.inst = inst
    self.inst:DoPeriodicTask(0.5, function() OnUpdate(self) end)
end)

return WaringTimer
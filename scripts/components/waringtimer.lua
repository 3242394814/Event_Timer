local function OnUpdate(self)
    for waringevent, data in pairs(WaringEvents) do
        if data.turn_on then
            while true do
                local time = data.gettimefn()
                if data.ShardRPC then
                    if data.ShardRPC.IsSendShard() then
                        for id in pairs(Shard_GetConnectedShards()) do
                            SendModRPCToShard(SHARD_MOD_RPC["Island Adventures Assistant"][waringevent], id, time)
                        end
                    else
                        break
                    end
                end

                -- self.inst.replica.waringtimer[waringevent]:set_local(0)
                self.inst.replica.waringtimer[waringevent]:set(time or 0)
                break
            end
        end
    end
end

local WaringTimer = Class(function(self, inst)
    self.inst = inst
    self.inst:DoPeriodicTask(0.5, function() OnUpdate(self) end)
end)

return WaringTimer
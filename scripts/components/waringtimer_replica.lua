local function OnWaringEventDirty(inst)
    if not ThePlayer or not ThePlayer.HUD then
        return
    end
    local eventstime = {}
    for waringevent, _ in pairs(WaringEvents) do
        eventstime[waringevent] = inst.replica.waringtimer[waringevent]:value()
    end
    ThePlayer.HUD:UpdateWaringEvents(eventstime)
end

local WaringTimer = Class(function(self, inst)
	self.inst = inst

    for waringevent, _ in pairs(WaringEvents) do
        self[waringevent] = net_shortint(inst.GUID, waringevent, "waringeventdirty")

        if not TheNet:IsDedicated() then
            inst:ListenForEvent("waringeventdirty", OnWaringEventDirty)
        end
    end
end)

return WaringTimer
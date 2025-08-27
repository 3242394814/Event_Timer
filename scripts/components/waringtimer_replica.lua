local function OnWaringEventDirty(inst)
    if not ThePlayer or not ThePlayer.HUD then
        return
    end
    local eventstime = {}
    for waringevent, tb in pairs(WaringEvents) do
        if tb.gettextfn then
            eventstime[waringevent .. "_text"] = inst.replica.waringtimer[waringevent .. "_text"]:value()
        end
        if tb.gettimefn then
            eventstime[waringevent .. "_time"] = inst.replica.waringtimer[waringevent .. "_time"]:value()
        end
    end
    ThePlayer.HUD.WaringEventTimeData = eventstime
    ThePlayer.HUD:UpdateWaringEvents()
end

local WaringTimer = Class(function(self, inst)
	self.inst = inst

    for waringevent, tb in pairs(WaringEvents) do
        if tb.gettextfn then
            self[waringevent .. "_text"] = net_string(inst.GUID, waringevent .. "_text", "waringevent_text_dirty")
        end
        if tb.gettimefn then
            self[waringevent .. "_time"] = net_shortint(inst.GUID, waringevent .. "_time", "waringevent_time_dirty")
        end

        if not TheNet:IsDedicated() then
            inst:ListenForEvent("waringevent_text_dirty", OnWaringEventDirty)
            inst:ListenForEvent("waringevent_time_dirty", OnWaringEventDirty)
        end
    end
end)

return WaringTimer
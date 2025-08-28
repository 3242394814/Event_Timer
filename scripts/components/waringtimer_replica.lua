local function OnWaringEventDirty(inst)
    if not ThePlayer or not ThePlayer.HUD then
        return
    end
    local eventstime = {}
    for waringevent, tb in pairs(WaringEvents) do
        if tb.gettextfn then
            eventstime[waringevent .. "_text"] = inst.replica.waringtimer[waringevent .. "_text"]:value() ~= "" and inst.replica.waringtimer[waringevent .. "_text"]:value()
                                              or inst.replica.waringtimer[waringevent .. "_text_shardrpc"]:value() ~= "" and inst.replica.waringtimer[waringevent .. "_text_shardrpc"]:value()
                                              or 0
        end
        if tb.gettimefn then
            eventstime[waringevent .. "_time"] = inst.replica.waringtimer[waringevent .. "_time"]:value() ~= 0 and inst.replica.waringtimer[waringevent .. "_time"]:value()
                                              or inst.replica.waringtimer[waringevent .. "_time_shardrpc"]:value() ~= 0 and inst.replica.waringtimer[waringevent .. "_time_shardrpc"]:value()
                                              or 0
        end
    end
    ThePlayer.HUD.WaringEventTimeData = eventstime
    ThePlayer.HUD:UpdateWaringEvents()
end

local WaringTimer = Class(function(self, inst)
	self.inst = inst

    for waringevent, tb in pairs(WaringEvents) do
        if tb.gettextfn then
            self[waringevent .. "_text"] = net_string(inst.GUID, waringevent .. "_text", "waringevent_dirty")
            self[waringevent .. "_text_shardrpc"] = net_string(inst.GUID, waringevent .. "_text_shardrpc", "waringevent_dirty")
        end
        if tb.gettimefn then
            self[waringevent .. "_time"] = net_shortint(inst.GUID, waringevent .. "_time", "waringevent_dirty")
            self[waringevent .. "_time_shardrpc"] = net_shortint(inst.GUID, waringevent .. "_time_shardrpc", "waringevent_dirty")
        end

        if not TheNet:IsDedicated() then
            inst:ListenForEvent("waringevent_dirty", OnWaringEventDirty)
        end
    end
end)

return WaringTimer
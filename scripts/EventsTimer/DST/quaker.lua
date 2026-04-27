-- 洞穴地震

local info
info = {
    gettimefn = function()
        local self = TheWorld.net.components.quaker
        if not self then return end
        local _task = Upvaluehelper.GetUpvalue(self.GetDebugString, "_task")
        if _task and GetTaskRemaining(_task) then
            return GetTaskRemaining(_task)
        end
    end,
    image = {
        atlas = "images/inventoryimages.xml",
        tex = "rocks.tex",
        scale = 0.8,
    },
    DisableShardRPC = true, -- 我觉得同步这个意义不大
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.quaker_time
        if time > 0 then
            return string.format(STRINGS.eventtimer.quaker.cooldown, TimeToString(time))
        end
    end,
}

return info
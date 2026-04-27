local info
info = {
    gettimefn = function()
        local self = TimerPrefabs["pugalisk_fountain"]
        return self and self.resettaskinfo and self:TimeRemainingInTask(self.resettaskinfo)
    end,
    image = {
        atlas = "images/lifeplant.xml",
        tex = "lifeplant.tex",
        scale = 0.8,
    },
    anim = {
        scale = 0.02,
        bank = "fountain",
        build = "python_fountain",
        animation = "flow_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = 0,
        }
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.pugalisk_fountain_time
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.pugalisk_fountain.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.pugalisk_fountain_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.pugalisk_fountain.tips)), 5, time, 1
        end
        return false
    end
}

return info
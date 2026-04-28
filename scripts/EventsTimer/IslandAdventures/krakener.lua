local info
info = {
    gettimefn = function()
        if TheWorld.components.krakener then
            return TheWorld.components.krakener:TimeUntilCanSpawn()
        end
    end,
    gettextfn = function(time)
        if time and time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.krakener.cooldown), TimeToString(time))
        end
        return ReplacePrefabName(STRINGS.eventtimer.krakener.ready)
    end,
    anim = {
        scale = 0.027,
        bank = "quacken",
        build = "quacken",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -6,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.krakener_time
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.krakener.cooldown), TimeToString(time))
        end
        return ReplacePrefabName(STRINGS.eventtimer.krakener.ready)
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.krakener_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.krakener.tips)), 10, time, 2
        end
        return false
    end
}

return info
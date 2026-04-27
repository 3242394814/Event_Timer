local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("rage", "antlion"),
    anim = {
        scale = 0.05,
        bank = "antlion",
        build = "antlion_build",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = -5,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.sinkholespawner_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.cooldown), TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.sinkholespawner_time
        if time > 2 and time <= 60 then
            return true, info.announcefn, time, nil, 2
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.attack)), 10, time, 3
        end
        return false
    end
}

return info
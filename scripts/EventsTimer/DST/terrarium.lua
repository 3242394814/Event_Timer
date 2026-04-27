local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("cooldown", "terrarium"),
    anim = {
        scale = 0.2,
        bank = "terrarium",
        build = "terrarium",
        animation = "idle",
        uioffset = {
            x = 0,
            y = -4,
        },
    },
    DisableShardRPC = true,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.terrarium_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.terrarium.cooldown), TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.terrarium_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.terrarium.tips)), 10, time, 2
        end
        return false
    end,
}

return info
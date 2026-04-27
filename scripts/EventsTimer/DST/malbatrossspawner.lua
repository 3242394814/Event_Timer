local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("malbatross_timetospawn"),
    anim = {
        scale = 0.035,
        bank = "malbatross",
        build = "malbatross_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 5,
            y = -10,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.malbatrossspawner_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.malbatrossspawner.cooldown), TimeToString(time))
    end
}

return info
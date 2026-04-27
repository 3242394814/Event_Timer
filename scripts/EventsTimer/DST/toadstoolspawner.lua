local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("toadstool_respawntask"),
    anim = {
        scale = 0.03,
        bank = "toadstool",
        build = "toadstool_build",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = -5,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.toadstoolspawner_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.toadstoolspawner.cooldown), TimeToString(time))
    end
}

return info
local info
info = {
    gettimefn = function()
        if TheWorld.components.deerherdspawner then
            local data = TheWorld.components.deerherdspawner:OnSave()
            return data and data._timetospawn
        end
    end,
    anim = {
        scale = 0.088,
        bank = "deer",
        build = "deer_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = -6,
            y = -6,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.deerherdspawner_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.deerherdspawner.cooldown), TimeToString(time))
    end
}

return info
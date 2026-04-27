local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("regen_crabking", "crabking_spawner"),
    anim = {
        scale = 0.022,
        bank = "king_crab",
        build = "crab_king_build",
        animation = "inert",
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.crabkingspawner_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.crabkingspawner.cooldown), TimeToString(time))
    end
}

return info
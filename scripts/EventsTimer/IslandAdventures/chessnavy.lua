local info
info = {
    gettimefn = function()
        if TheWorld.components.chessnavy then
            return TheWorld.components.chessnavy.spawn_timer
        end
    end,
    gettextfn = function(time)
        if not TheWorld.components.chessnavy then return end
        return time and time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.chessnavy.cooldown), TimeToString(time)) or STRINGS.eventtimer.chessnavy.readytext
    end,
    anim = {
        scale = 0.09,
        bank = "knightboat",
        build = "knightboat_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 7,
            y = -2,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.chessnavy_time
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.chessnavy.cooldown), TimeToString(time))
        end
        return ReplacePrefabName(STRINGS.eventtimer.chessnavy.ready)
    end
}

return info
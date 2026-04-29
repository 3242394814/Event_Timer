local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("twister_timetoattack"),
    gettextfn = function(time)
        local self = TheWorld.components.twisterspawner
        if not self then return end
        local description
        local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
        if time and target and target.name then
            description = string.format(STRINGS.eventtimer.twisterspawner.targeted, target.name, TimeToString(time))
        elseif time then
            description = string.format(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.cooldown), TimeToString(time))
        end

        return description
    end,
    image = {
        atlas = "images/Twister.xml",
        tex = "Twister.tex",
        scale = 0.35,
    },
    anim = {
        scale = 0.022,
        bank = "twister",
        build = "twister_build",
        animation = "idle_loop",
        loop = true
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.twisterspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.twisterspawner_text
        local target, _ = Extract_by_format(text, STRINGS.eventtimer.twisterspawner.targeted)
        if target and time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.target), target, TimeToString(time))
        elseif time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.twisterspawner_time
        if time > 2 and time <= 60 and GetWorldtypeStr() == "shipwrecked" then
            return true, info.announcefn, time, nil, 2
        elseif time == 480 or JustEntered(time) then
            return true, info.announcefn, 10, nil, 2
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.attack)), 10, time, 3
        end
        return false
    end
}

return info
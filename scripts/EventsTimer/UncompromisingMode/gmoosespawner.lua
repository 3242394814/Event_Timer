local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("mothergoose_timetoattack"),
    gettextfn = function(time)
        local self = TheWorld.components.gmoosespawner
        if not self then return end
        local description
        local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
        if time and target and target.name then
            description = string.format(STRINGS.eventtimer.gmoosespawner.targeted, target.name, TimeToString(time))
        elseif time then
            description = string.format(ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.cooldown), TimeToString(time))
        end

        return description
    end,
    image = {
        atlas = "images/Moose.xml",
        tex = "Moose.tex",
        scale = 0.2,
        offset = {
            x = 0,
            y = 15,
        }
    },
    anim = {
        scale = 0.044,
        bank = "goosemoose",
        build = "goosemoose_build",
        animation = "idle",
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.gmoosespawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.gmoosespawner_text
        local target, _ = Extract_by_format(text, STRINGS.eventtimer.gmoosespawner.targeted)
        if target and time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.target), target, TimeToString(time))
        elseif time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.gmoosespawner_time
        if time > 2 and time <= 60 then
            return true, info.announcefn, time, nil, 2
        elseif time == 480 or JustEntered(time) then
            return true, info.announcefn, 10, nil, 2
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.attack)), 10, time, 3
        end
        return false
    end
}

return info
local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("bearger_timetospawn"),
    gettextfn = function(time)
        local self = TheWorld.components.beargerspawner
        if not self then return end
        local description
        local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
        if time and target and target.name then
            description = string.format(STRINGS.eventtimer.beargerspawner.targeted, target.name, TimeToString(time))
        elseif time then
            description = string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.cooldown), TimeToString(time))
        end

        return description
    end,
    animchangefn = ChangeanimByWintersFeast,
    defaultanim = {
        scale = 0.035,
        bank = "bearger",
        build = "bearger_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -8,
        },
    },

    winterfeastanim = {
        scale = 0.035,
        bank = "bearger",
        build = "bearger_yule",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -8,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.beargerspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.beargerspawner_text
        local target, _ = Extract_by_format(text, STRINGS.eventtimer.beargerspawner.targeted)
        if target and time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.target), target, TimeToString(time))
        elseif time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.beargerspawner_time
        if time > 2 and time <= 60 and GetWorldtypeStr() == "forest" then
            return true, info.announcefn, time, nil, 2
        elseif time == 480 or JustEntered(time) then
            return true, info.announcefn, 10, nil, 2
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.attack)), 10, time, 3
        end
        return false
    end,
}

return info
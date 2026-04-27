local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("mockfly_timetoattack"),
    gettextfn = function(time)
        local self = TheWorld.components.mock_dragonflyspawner
        if not self then return end
        local description
        local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
        if time and target and target.name then
            description = string.format(STRINGS.eventtimer.mock_dragonflyspawner.targeted, target.name, TimeToString(time))
        elseif time then
            description = string.format(ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.cooldown), TimeToString(time))
        end

        return description
    end,
    image = {
        atlas = "images/Dragonfly.xml",
        tex = "Dragonfly.tex",
        scale = 0.2,
        offset = {
            x = 0,
            y = 13,
        }
    },
    anim = {
        scale = 0.044,
        bank = "dragonfly",
        build = "dragonfly_build",
        animation = "idle",
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.mock_dragonflyspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.mock_dragonflyspawner_text
        local target, _ = Extract_by_format(text, STRINGS.eventtimer.mock_dragonflyspawner.targeted)
        if target and time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.target), target, TimeToString(time))
        elseif time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.mock_dragonflyspawner_time
        if time > 2 and time <= 60 then
            return true, info.announcefn, time, nil, 2
        elseif time == 480 or JustEntered(time) then
            return true, info.announcefn, 10, nil, 2
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.attack)), 10, time, 3
        end
        return false
    end
}

return info
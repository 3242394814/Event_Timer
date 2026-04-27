-- 远古大门

local info
info = {
    gettimefn = function()
        if not (TimerPrefabs.atrium_gate and TimerPrefabs.atrium_gate.components.worldsettingstimer) then return end
        return GetWorldSettingsTimeLeft("cooldown", "atrium_gate")() or GetWorldSettingsTimeLeft("destabilizing", "atrium_gate")()
    end,
    gettextfn = function(time)
        if time and time > 0 then
            if GetWorldSettingsTimeLeft("cooldown", "atrium_gate")() then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.atrium_gate.cooldown), TimeToString(time))
            else
                return string.format(STRINGS.eventtimer.atrium_gate.destabilizing, TimeToString(time))
            end
        end
    end,
    anim = {
        scale = 0.055,
        bank = "atrium_gate",
        build = "atrium_gate",
        animation = "idle",
        uioffset = {
            x = -2,
            y = -5,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.atrium_gate_time
        local text = ThePlayer.HUD.WarningEventTimeData.atrium_gate_text
        if string.find(text, ReplacePrefabName("<prefab=atrium_gate>")) then
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.atrium_gate.cooldown), TimeToString(time))
        else
            return time and string.format(STRINGS.eventtimer.atrium_gate.destabilizing, TimeToString(time))
        end
    end,
}

return info
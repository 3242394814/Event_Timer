local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("pig_bandit_respawn_time_"),
    gettextfn = function(time)
        local self = TheWorld.components.banditmanager
        if not self then return end
        local str = self:GetDebugString()
        local stolen_oincs, active_bandit = string.match(str, "Stolen Oincs: (%d+) Active Bandit: (%a+) Respawns In")
        if not (stolen_oincs and active_bandit) then return end
        if active_bandit == "true" then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext), stolen_oincs)
        elseif time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.cooldown), TimeToString(time), stolen_oincs, active_bandit)
        end
    end,
    image = {
        atlas = "images/pig_bandit.xml",
        tex = "pig_bandit.tex",
        scale = 0.07,
    },
    anim = {
        scale = 0.07,
        build = "pig_bandit",
        bank = "townspig",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -15,
        }
    },
    DisableShardRPC = true,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.banditmanager_time
        local text = ThePlayer.HUD.WarningEventTimeData.banditmanager_text
        local _time, stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.cooldown))
        if stolen_oincs then
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.announce_cooldown), TimeToString(time), stolen_oincs)
        else
            stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext))
            return stolen_oincs and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.ready), stolen_oincs)
        end
    end,
    tipsfn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.banditmanager_text
        local ready = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext))
        if ready then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.banditmanager.tips)), 5, nil, 3
        end
        return false
    end
}

return info
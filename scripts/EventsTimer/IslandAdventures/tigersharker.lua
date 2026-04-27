local info
info = {
    gettimefn = function()
        local self = TheWorld.components.tigersharker
        if not self then return end
        local appear_time = self:TimeUntilCanAppear()
        local respawn_time = self:TimeUntilRespawn()
        return math.max(appear_time, respawn_time)
    end,
    gettextfn = function(time)
        local self = TheWorld.components.tigersharker
        if not self then return end
        if self.shark then
            return ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists)
        elseif self:CanSpawn(true, true) then
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.tigersharker.cooldown), TimeToString(time))
            else
                return STRINGS.eventtimer.tigersharker.readytext
            end
        end
        return ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn)
    end,
    anim = {
        scale = 0.03,
        bank = "tigershark",
        build = "tigershark_ground_build",
        animation = "taunt",
        loop = true,
        uioffset = {
            x = -6,
            y = -6,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.tigersharker_time
        local text = ThePlayer.HUD.WarningEventTimeData.tigersharker_text
        local exists = string.find(text, ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists))
        local nospawn = string.find(text, ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn))
        if exists then
            return ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists)
        elseif nospawn then
            return ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn)
        elseif time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.tigersharker.cooldown), TimeToString(time))
        else
            return ReplacePrefabName(STRINGS.eventtimer.tigersharker.ready)
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.tigersharker_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.tigersharker.tips)), 10, time, 2
        end
        return false
    end
}

return info
local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("klaussack_tropical_spawntimer"),
    gettextfn = function(time)
        local self = TheWorld.components.islandsklaussackspawner
        if not self then return end
        local function sack_can_despawn(inst)
            if not IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) and
                inst.components.entitytracker:GetEntity("klaus") == nil and
                inst.components.entitytracker:GetEntity("key") == nil then
                return true
            end
            return false
        end
        local sack = Upvaluehelper.GetUpvalue(self.GetDebugString, "_sack")
        if sack and sack:IsValid() and sack.despawnday and sack_can_despawn(sack) then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.islandsklaussackspawner.despawntext), sack.despawnday)
        else
            return time and TimeToString(time)
        end
    end,
    anim = {
        scale = 0.1,
        bank = "klaus_bag",
        build = "klaus_bag_tropical",
        animation = "idle",
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.islandsklaussackspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.islandsklaussackspawner_text
        local despawnday = Extract_by_format(text, STRINGS.eventtimer.islandsklaussackspawner.despawntext)
        if despawnday then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.islandsklaussackspawner.despawn), despawnday)
        elseif time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.islandsklaussackspawner.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.islandsklaussackspawner_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.islandsklaussackspawner.tips)), 10, time, 2
        end
        return false
    end
}

return info
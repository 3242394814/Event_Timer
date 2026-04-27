local info
info ={
    gettimefn = GetWorldSettingsTimeLeft("klaussack_spawntimer"),
    gettextfn = function(time)
        local function sack_can_despawn(inst)
            if not IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) and
                inst.components.entitytracker:GetEntity("klaus") == nil and
                inst.components.entitytracker:GetEntity("key") == nil then
                return true
            end
            return false
        end

        local self = TheWorld.components.klaussackspawner
        if not self then return end
        local sack = Upvaluehelper.GetUpvalue(self.GetDebugString, "_sack")
        if sack and sack:IsValid() and sack.despawnday and sack_can_despawn(sack) then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.despawntext), sack.despawnday)
        else
            return time and TimeToString(time)
        end
    end,
    anim = {
        scale = 0.1,
        bank = "klaus_bag",
        build = "klaus_bag",
        animation = "idle",
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.klaussackspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.klaussackspawner_text
        local despawnday = Extract_by_format(text, STRINGS.eventtimer.klaussackspawner.despawntext)
        if despawnday then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.despawn), despawnday)
        elseif time then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.klaussackspawner_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.tips)), 10, time, 2
        end
        return false
    end
}

return info
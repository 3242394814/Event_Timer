-- 梦魇疯猪

local info
info = {
    gettimefn = function()
        local self = TheWorld.components.daywalkerspawner
        if not self then return end
        local shard_daywalkerspawner = TheWorld.shard.components.shard_daywalkerspawner
        if shard_daywalkerspawner ~= nil and shard_daywalkerspawner:GetLocationName() ~= "cavejail" or self.daywalker ~= nil or not self.days_to_spawn or not CalcTimeOfDay then
            return
        end
        return (self.days_to_spawn + 1) * TUNING.TOTAL_DAY_TIME - CalcTimeOfDay()
    end,
    gettextfn = function()
        local self = TheWorld.components.daywalkerspawner
        if not self then return end
        if self.daywalker ~= nil then
            return ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.ready)
        end
    end,
    anim = {
        scale = 0.05,
        build = "daywalker_build",
        bank = "daywalker",
        animation = "idle_creepy_loop",
        uioffset = {
            x = -2,
            y = -7
        },
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.daywalkerspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.daywalkerspawner_text
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.cooldown), TimeToString(time))
        else
            text = string.gsub(text,"\n",": ")
            return text
        end
    end,
    tipsfn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.daywalkerspawner_text
        if string.find(text, ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.ready)) then
            return true, not (GetTime() < 10) and StringToFunction(ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.tips)), 10, nil, 2
        end
        return false
    end
}

return info
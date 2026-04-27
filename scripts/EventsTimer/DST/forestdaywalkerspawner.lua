-- 拾荒疯猪，参考了 饥饥事件计时器 的代码 https://steamcommunity.com/sharedfiles/filedetails/?id=3511498282 @不要看上我的菊

local info
info = {
    gettimefn = function()
        local self = TheWorld.components.forestdaywalkerspawner
        if not self then return end
        local shard_daywalkerspawner = TheWorld.shard.components.shard_daywalkerspawner
        if shard_daywalkerspawner ~= nil and shard_daywalkerspawner:GetLocationName() ~= "forestjunkpile" or self.daywalker ~= nil or self.bigjunk ~= nil or not self.days_to_spawn or not CalcTimeOfDay then
            return
        end
        return (self.days_to_spawn + 1) * TUNING.TOTAL_DAY_TIME - CalcTimeOfDay()
    end,
    gettextfn = function(time)
        local self = TheWorld.components.forestdaywalkerspawner
        if not self then return end
        if self.bigjunk ~= nil then
            return ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.ready)
        elseif self.daywalker ~= nil then
            return ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.exists)
        end
    end,
    anim = {
        scale = 0.05,
        build = "daywalker_build",
        bank = "daywalker",
        animation = "idle_creepy_loop",
        overridebuild = { "daywalker_phase3" },
        uioffset = {
            x = -2,
            y = -7
        },
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_text
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.cooldown), TimeToString(time))
        else
            text = string.gsub(text,"\n",": ")
            return text
        end
    end,
    tipsfn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_text
        if string.find(text, ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.ready)) then
            return true, not (GetTime() < 10) and StringToFunction(ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.tips)), 10, nil, 2
        end
        return false
    end
}

return info
local info
info = {
    remotegettimefn = function(Thread)
        GetWorldSettingsTimeLeft("rage", "antlion", function(res)
            if res and res.err then
                SaveTimeData("sinkholespawner", 0)
                print('[警告] sinkholespawner remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("sinkholespawner", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    anim = {
        scale = 0.05,
        bank = "antlion",
        build = "antlion_build",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = -5,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.sinkholespawner_time
        return time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.cooldown), TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.sinkholespawner_time
        if time > 2 and time <= 60 then
            return true, info.announcefn, time, nil, 2
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.attack)), 10, time, 3
        end
        return false
    end
}

return info
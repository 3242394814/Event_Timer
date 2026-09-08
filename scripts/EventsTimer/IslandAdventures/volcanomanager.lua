local info
info = {
    postinitfn = function()
        AddPrefabPostInit("world", function()
            if GetWorldtypeStr() ~= "shipwrecked" then
                info.tipsfn = nil -- 非海难火山世界不提示火山爆发
            end
        end)
    end,
    remotegettimefn = function(Thread)
        local cmd = [[
            local self = TheWorld.components.volcanomanager
            if not self then return DataDumper({ not_found = true }) end

            local ActualTime = (TUNING.TOTAL_DAY_TIME * (TheWorld.state.time * 100)) / 100
            local ActualSeg = math.floor(ActualTime / 30)
            local TimeInSeg = ActualTime - (ActualSeg * 30)
            local SegUntilEruption = self:GetNumSegmentsUntilEruption() or 0
            local SecondUntilEruption = math.floor((SegUntilEruption * 30) - TimeInSeg)

            return DataDumper({ time = SecondUntilEruption > 0 and SecondUntilEruption or 0 })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTimeData("volcanomanager", 0)
                print('[警告] volcanomanager remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("volcanomanager", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    anim = {
        scale = 0.0077,
        bank = "volcano",
        build = "volcano",
        animation = "active_idle_pst",
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.volcanomanager_time
        return time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.volcanomanager.cooldown), TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.volcanomanager_time
        if time > 2 and time <= 60 then
            return true, info.announcefn, time, nil, 2
        elseif JustEntered(time) and time <= 480 then
            return true, info.announcefn, 10, nil, 2
        elseif JustEntered(time) and time > 480 then
            return true, info.announcefn, 10, nil, 1
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.volcanomanager.attack)), 10, time, 3
        end
        return false
    end,
}

return info
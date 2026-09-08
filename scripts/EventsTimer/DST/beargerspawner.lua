-- 纯本地获取方式
local localgettimefn = function()
    -- 根据警告等级（2~4）和当前等级内的触发次数，估算 Boss 距离到达的秒数并播报
    -- 等级越高 = 越近；同一等级每次触发间隔约 15 秒
    local record_table = {}
    local function DoBossWarning(level, times)
        -- 特殊情况：level4 第 3 次触发意味着 Boss 即将到达
        local time
        if level == 4 and times == 3 then
            time = 3
        else
            -- 通用公式：(5 - level) * 30 - 15 * (times - 1)
            -- level=2,times=1 → 90s；level=4,times=1 → 30s；以此类推
            time = (5 - level) * 30 - 15 * (times - 1)
        end

        local data_time = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData["beargerspawner_time"]
        if data_time and (time < data_time) or (data_time == 0) then
            SaveTimeData("beargerspawner", time)
        end
    end

    for i = 2, 4 do
        local level = tostring(i)
        AddPrefabPostInit("beargerwarning_lvl" .. level, function(inst)
            -- 取消上一个重置任务（若存在），并重新设置 60 秒后的自动重置
            -- 作用：如果 60 秒内没有新警告触发，则清空计数，准备下一轮
            if record_table.task then
                record_table.task:Cancel()
                record_table.task = nil
            end

            -- 重置其他等级的计数
            for k, v in pairs(record_table) do
                if type(v) == "number" and k ~= level then
                    record_table[k] = 0
                end
            end

            -- 累加触发次数，超过上限则循环回 1
            -- 上限 = level - 1（lvl2 上限 1 次，lvl3 上限 2 次，lvl4 上限 3 次）
            record_table[level] = (record_table[level] or 0) + 1
            if record_table[level] > i - 1 then
                record_table[level] = 1
            end

            -- 发送警告消息
            DoBossWarning(i, record_table[level])

            record_table.task = TheWorld:DoTaskInTime(60, function()
                record_table.task = nil
                record_table = {} -- 重置状态
            end)
        end)
    end
end

----------------------------------------------------------------------------------------------

local target_name
local remotegettextfn = function(Thread)
    if ThePlayer.HUD.WarningEventTimeData.beargerspawner_time == 0 then return end

    local cmd = [[
        local self = TheWorld.components.beargerspawner
        if not self then return end

        local target = BBGOAT_FN.getval(self.OnUpdate, "_targetplayer")
        local name = target and target.name

        return DataDumper({target_name = name})
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            target_name = nil
            SaveTextData("beargerspawner", "")
            print('[警告] beargerspawner remotegettextfn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res then
            target_name = res.target_name
            if target_name then
                local str = string.format(STRINGS.eventtimer.beargerspawner.targeted, target_name, TimeToString(ThePlayer.HUD.WarningEventTimeData.beargerspawner_time))
                SaveTextData("beargerspawner", str)
            else
                local str = string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.cooldown), TimeToString(ThePlayer.HUD.WarningEventTimeData.beargerspawner_time))
                SaveTextData("beargerspawner", str)
            end
        else
            target_name = nil
            if Thread then KillThreadsWithID(Thread.id) end
        end
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        GetWorldSettingsTimeLeft("bearger_timetospawn", nil, function(res)
            if res and res.err then
                target_name = nil
                SaveTimeData("beargerspawner", 0)
                SaveTextData("beargerspawner", "")
                print('[警告] beargerspawner remotegettimefn error:', res.err)
                -- 同时删除Text线程
                local _, TextThreadList = GetRemoteThreadList()
                if TextThreadList and TextThreadList.beargerspawner then
                    KillThreadsWithID(TextThreadList.beargerspawner.id)
                end
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("beargerspawner", res.time)
            end
        end)
    end,
    remotegettextfn = remotegettextfn,
    remotegettextfninterval = function()
        local time = ThePlayer.HUD.WarningEventTimeData.beargerspawner_time
        if time > 55 then
            return time - 55
        end
    end,
    animchangefn = ChangeanimByWintersFeast,
    defaultanim = {
        scale = 0.035,
        bank = "bearger",
        build = "bearger_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -8,
        },
    },

    winterfeastanim = {
        scale = 0.035,
        bank = "bearger",
        build = "bearger_yule",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -8,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.beargerspawner_time
        local text = ThePlayer.HUD.WarningEventTimeData.beargerspawner_text
        local target, _ = Extract_by_format(text, STRINGS.eventtimer.beargerspawner.targeted)
        if target and time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.target), target, TimeToString(time))
        elseif time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.beargerspawner_time
        if time > 2 and time <= 60 and GetWorldtypeStr() == "forest" then
            return true, info.announcefn, time, nil, 2
        elseif time == 480 or JustEntered(time) then
            return true, info.announcefn, 10, nil, 2
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.attack)), 10, time, 3
        end
        return false
    end,
}

return info
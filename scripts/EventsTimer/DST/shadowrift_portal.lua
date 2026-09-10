-- 暗影裂隙信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616

local remotegettextfn = function(Thread)
    if not (TheWorld and TheWorld:HasTag("cave")) then -- 仅在洞穴世界更新数据
        -- 取消数据更新任务
        if Thread then KillThreadsWithID(Thread.id) end
        return
    end

    local cmd = [[
        local TimerPrefabs = _G.EventTimerClient.TimerPrefabs
        local HookPrefab = _G.EventTimerClient.HookPrefab
        local inst = TimerPrefabs["shadowrift_portal"] or HookPrefab("shadowrift_portal")
        if not inst then return DataDumper({ not_found = true }) end

        local STAGE_GROWTH_TIMER = "trynextstage"
        local RIFT_CLOSE_TIMER = "close"
        local rift_close_time
        local next_stage_time

        if inst.components.timer:TimerExists(RIFT_CLOSE_TIMER) then
            rift_close_time = inst.components.timer:GetTimeLeft(RIFT_CLOSE_TIMER)
        end

        if rift_close_time and inst._stage == TUNING.RIFT_SHADOW1_MAXSTAGE then
            
        elseif inst.components.timer and inst.components.timer:TimerExists(STAGE_GROWTH_TIMER) then
            next_stage_time = inst.components.timer:GetTimeLeft(STAGE_GROWTH_TIMER)
        end

        return DataDumper(
        {
        _stage = inst._stage, -- 当前阶段
        RIFT_SHADOW1_MAXSTAGE = TUNING.RIFT_SHADOW1_MAXSTAGE, -- 最大阶段
        rift_close_time = rift_close_time, -- 关闭时间
        next_stage_time = next_stage_time, -- 下一阶段时间
        }
        )
    ]]
    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            SaveTextData("shadowrift_portal", "")
            print('[警告] shadowrift_portal remotegettextfn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res and res._stage then
            local stage_info = string.format(ReplacePrefabName(STRINGS.eventtimer.riftspawner.stage), res._stage, res.RIFT_SHADOW1_MAXSTAGE)
            if res.rift_close_time and res._stage == res.RIFT_SHADOW1_MAXSTAGE then
                stage_info = stage_info .. ": " .. string.format(ReplacePrefabName(STRINGS.eventtimer.shadowrift_portal.close), TimeToString(res.rift_close_time))
            elseif res.next_stage_time then
                stage_info = stage_info .. ": " .. string.format(STRINGS.eventtimer.rift_portal.next_stage, TimeToString(res.next_stage_time))
            end
            SaveTextData("shadowrift_portal", stage_info)
        elseif res and res.not_found then -- 当前裂隙未生成
            SaveTextData("shadowrift_portal", "")
        end
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    remotegettextfn = remotegettextfn,
    DisableClientPredictionClearText = true, -- 没有time信息，需要此选项避免text被删除
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "shadowrift_portal.png",
        scale = 0.8,
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.shadowrift_portal_text
        text = string.gsub(text,"\n",", ")
        return STRINGS.eventtimer.shadowrift_portal.name .. ": " .. text
    end,
}

return info
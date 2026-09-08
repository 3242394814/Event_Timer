-- 纯本地获取方式
local localgettimefn = function()
    AddPrefabPostInit("shadowrift_portal", function() -- 暗影裂隙
        SaveTimeData("shadow_riftspawner", 0)
    end)
    AddPrefabPostInit("charlie_hand", function(inst) -- 召唤之手
        inst:DoTaskInTime(0.2, function(inst)
            inst:ListenForEvent("onremove", function(inst)
                if inst and inst:IsValid() and inst.AnimState then
                    local bank, anim, frame = inst.AnimState:GetHistoryData()
                    if anim:find("grab_pst") then
                        SaveTimeData("atrium_gate", TUNING.ATRIUM_GATE_COOLDOWN) -- 远古大门重置倒计时
                    end
                end
            end)
        end)
    end)
    AddPrefabPostInit("charlie_npc", function(inst) -- 查理
        inst:DoTaskInTime(0.2, function(inst)
            inst:ListenForEvent("onremove", function(inst)
                if inst and inst:IsValid() and inst.AnimState then
                    local bank, anim, frame = inst.AnimState:GetHistoryData()
                    if anim:find("spawn_out") then
                        SaveTimeData("shadow_riftspawner", TUNING.RIFTS_SPAWNDELAY) -- 暗影裂隙生成倒计时
                    end
                end
            end)
        end)
    end)
end

----------------------------------------------------------------------------------------------

-- 暗影裂隙生成倒计时
local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        if ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData and ThePlayer.HUD.WarningEventTimeData.shadowrift_portal_text ~= "" then -- 当裂隙出现时，不显示
            SaveTimeData("shadow_riftspawner", 0)
            return
        end

        GetWorldSettingsTimeLeft("rift_spawn_timer", nil, function(res)
            if res and res.err then
                SaveTimeData("shadow_riftspawner", 0)
                print('[警告] shadow_riftspawner remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("shadow_riftspawner", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "shadowrift_portal.png",
        scale = 0.8,
        offset = {
            x = 0,
            y = 13,
        },
    },
    -- anim = {
    --     scale = 0.05,
    --     build = "shadowrift_portal",
    --     bank = "shadowrift_portal",
    --     animation = "scrapbook",
    -- },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.shadow_riftspawner_time
        return time > 0 and string.format(STRINGS.eventtimer.riftspawner.shadow_cooldown, TimeToString(time))
    end,
}

return info
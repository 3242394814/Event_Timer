-- 纯本地获取方式
local localgettimefn = function()
    AddPrefabPostInit("lunarrift_portal", function()
        SaveTimeData("lunar_riftspawner", 0)
    end)

    local need_save = false
    AddPrefabPostInit("wagstaff_npc_pstboss", function(inst)
        need_save = true
        inst:DoTaskInTime(0.2, function(inst)
            if inst and inst.components and inst.components.talker and inst.components.talker.Say then
                local _Say = inst.components.talker.Say
                inst.components.talker.Say = function(self, str_say, ...)
                    for _, str in pairs({STRINGS.WAGSTAFF_NPC_CAPTURESTOP1, STRINGS.WAGSTAFF_NPC_CAPTURESTOP3}) do
                        if str == str_say and need_save then
                            need_save = false
                            SaveTimeData("lunar_riftspawner", TUNING.RIFTS_SPAWNDELAY)
                            break
                        end
                    end
                    return _Say(self, str_say, ...)
                end
            end
        end)
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        if ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData and ThePlayer.HUD.WarningEventTimeData.rift_portal_text ~= "" then -- 当裂隙出现时，不显示
            SaveTimeData("lunar_riftspawner", 0)
            return
        end

        if not (TheWorld and TheWorld:HasTag("forest")) then -- 仅在森林世界更新数据
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
            return
        end

        GetWorldSettingsTimeLeft("rift_spawn_timer", nil, function(res)
            if res and res.err then
                SaveTimeData("lunar_riftspawner", 0)
                print('[警告] lunar_riftspawner remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("lunar_riftspawner", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "lunarrift_portal.png",
        scale = 0.8,
        offset = {
            x = 0,
            y = 13,
        },
    },
    anim = {
        scale = 0.05,
        build = "lunar_rift_portal",
        bank = "lunar_rift_portal",
        animation = "stage_3_loop",
        offset = {
            x = 0,
            y = -16,
        },
        loop = true,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.lunar_riftspawner_time
        return time > 0 and string.format(STRINGS.eventtimer.riftspawner.lunar_cooldown, TimeToString(time))
    end,
}

return info
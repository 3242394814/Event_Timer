-- 果蝇王

local lordfruitfly_spawned -- 果蝇王是否已生成

local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddPrefabPostInit("lordfruitfly", function(inst)
            lordfruitfly_spawned = true
            inst:ListenForEvent("onremove", function()
                lordfruitfly_spawned = false
            end)
        end)
    end,
    gettimefn = GetWorldSettingsTimeLeft("lordfruitfly_spawntime"),
    gettextfn = function()
        if lordfruitfly_spawned then
            return ReplacePrefabName(STRINGS.eventtimer.farming_manager.ready)
        end
    end,
    anim = {
        scale = 0.2,
        build = "fruitfly_evil",
        bank = "fruitfly",
        animation = "idle",
        offset = {
            x = 0,
            y = -20
        },
        uioffset = {
            x = -2,
            y = -22
        },
        loop = true,
    },
    DisableShardRPC = true,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.farming_manager_time
        if time and time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.farming_manager.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.farming_manager_text
        local ready = text == ReplacePrefabName(STRINGS.eventtimer.farming_manager.ready)
        if ready then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.farming_manager.tips)), 5, nil, 3
        end
        return false
    end,
}

return info
-- 暗影裂隙生成倒计时（为了跨世界同步数据修改了事件名。原事件名 riftspawner）

local info
info = {
    gettimefn = function() -- 当裂隙出现时，不显示
        if TheWorld and TheWorld:HasTag("cave") and TheWorld.net.components.warningtimer.inst.replica.warningtimer.shadowrift_portal_text:value() == "" then
            return GetWorldSettingsTimeLeft("rift_spawn_timer")()
        end
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
        return time and time > 0 and string.format(STRINGS.eventtimer.riftspawner.shadow_cooldown, TimeToString(time))
    end,
}

return info
-- 暗影裂隙信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616

local STAGE_GROWTH_TIMER = "trynextstage"
local RIFT_CLOSE_TIMER = "close"

local info
info = {
    gettimefn = nil, -- gettimefn有必要吗？也许没必要
    gettextfn = function()
        local inst = TimerPrefabs["shadowrift_portal"]
        if not inst then return end

        local stage_info = string.format(ReplacePrefabName(STRINGS.eventtimer.riftspawner.stage), inst._stage, TUNING.RIFT_SHADOW1_MAXSTAGE)
        local rift_close_time

        if inst.components.timer:TimerExists(RIFT_CLOSE_TIMER) then
            rift_close_time = inst.components.timer:GetTimeLeft(RIFT_CLOSE_TIMER)
        end

        if rift_close_time and inst._stage == TUNING.RIFT_SHADOW1_MAXSTAGE then
            stage_info = stage_info .. ": " .. string.format(ReplacePrefabName(STRINGS.eventtimer.shadowrift_portal.close), TimeToString(rift_close_time))
        elseif inst.components.timer and inst.components.timer:TimerExists(STAGE_GROWTH_TIMER) then
            stage_info = stage_info .. ": " .. string.format(STRINGS.eventtimer.rift_portal.next_stage, TimeToString(inst.components.timer:GetTimeLeft(STAGE_GROWTH_TIMER)))
        end

        local description = stage_info
        return description
    end,
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
-- 月亮裂隙信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616 (爱死你了)

local STAGE_GROWTH_TIMER = "trynextstage"
local MAX_CRYSTAL_RING_COUNT_BY_STAGE -- = {0, 1, 3}
local CRYSTALS_PER_RING -- = 4
local MIN_CRYSTAL_DISTANCE -- = 3
local MAX_CRYSTAL_DISTANCE_BY_STAGE
local TERRAFORM_DELAY -- = TUNING.RIFT_LUNAR1_STAGEUP_BASE_TIME / 3

local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddPrefabPostInit("world", function()
            MAX_CRYSTAL_RING_COUNT_BY_STAGE = Upvaluehelper.GetUpvalue(_G.Prefabs.lunarrift_portal.fn, "MAX_CRYSTAL_RING_COUNT_BY_STAGE") -- {0, 1, 3}
            CRYSTALS_PER_RING = Upvaluehelper.GetUpvalue(_G.Prefabs.lunarrift_portal.fn, "CRYSTALS_PER_RING") -- 4
            MIN_CRYSTAL_DISTANCE = Upvaluehelper.GetUpvalue(_G.Prefabs.lunarrift_portal.fn, "MIN_CRYSTAL_DISTANCE") -- 3
            TERRAFORM_DELAY = Upvaluehelper.GetUpvalue(_G.Prefabs.lunarrift_portal.fn, "TERRAFORM_DELAY")
            MAX_CRYSTAL_DISTANCE_BY_STAGE = Upvaluehelper.GetUpvalue(_G.Prefabs.lunarrift_portal.fn, "MAX_CRYSTAL_DISTANCE_BY_STAGE") -- TUNING.RIFT_LUNAR1_STAGEUP_BASE_TIME / 3
        end)
    end,
    gettextfn = function()
        local inst = TimerPrefabs["lunarrift_portal"]
        if not inst then return end

        -- 裂隙阶段信息
        local stage_info = string.format(STRINGS.eventtimer.riftspawner.stage, inst._stage, TUNING.RIFT_LUNAR1_MAXSTAGE) -- 阶段信息，内容类似：阶段 1 / 3
        if inst.components.timer and inst.components.timer:TimerExists(STAGE_GROWTH_TIMER) and not (inst._stage == TUNING.RIFT_LUNAR1_MAXSTAGE) then
            stage_info = stage_info .. ": " .. string.format(STRINGS.eventtimer.rift_portal.next_stage, TimeToString(inst.components.timer:GetTimeLeft(STAGE_GROWTH_TIMER))) -- 补充信息：%s后进入下一阶段
        end

        -- 裂隙晶体信息
        local crystal_count_info -- 可用晶体的信息。内容类似：裂隙晶体：1可用 / 4总共 / 4最大
        local crystal_spawn_info -- 下一波晶体生成时间。内容类似：下一波裂隙晶体生成于0时3分3秒后

        local max_crystals = MAX_CRYSTAL_RING_COUNT_BY_STAGE[inst._stage] * CRYSTALS_PER_RING -- 最大晶体数量
        local current_crystals = 0 -- 当前晶体数量
        local available_crystals = 0 -- 可用晶体数量
        local quickest_time_to_available_crystal -- 下波晶体生成时间

        for crystal in pairs(inst._crystals) do
            current_crystals = current_crystals + 1
            if not crystal:IsInLimbo() then
                available_crystals = available_crystals + 1
            else
                if crystal.components.timer:TimerExists("finish_spawnin") then
                    local time = crystal.components.timer:GetTimeLeft("finish_spawnin")
                    if quickest_time_to_available_crystal == nil or time < quickest_time_to_available_crystal then
                        quickest_time_to_available_crystal = time
                    end
                end
            end
        end

        -- 显示可用晶体的数量
        if available_crystals > 0 then
            crystal_count_info = string.format(ReplacePrefabName(STRINGS.eventtimer.rift_portal.crystals), available_crystals, current_crystals, max_crystals)
        end

        -- 显示晶体再生时间
        local crystals_can_spawn = (max_crystals - current_crystals) >= CRYSTALS_PER_RING

        if (crystals_can_spawn or available_crystals < current_crystals) then
            local time

            if quickest_time_to_available_crystal  then
                time = quickest_time_to_available_crystal
            elseif crystals_can_spawn then
                -- 我们将展示一个近似的时间，因为它有一些随机性，但数量微不足道。
                if inst.components.timer:TimerExists("try_crystals") then
                    -- math复制自lunarrift_portal，并进行了一些调整。
                    local offset = MIN_CRYSTAL_DISTANCE + math.sqrt(1)*(MAX_CRYSTAL_DISTANCE_BY_STAGE[inst._stage] - MIN_CRYSTAL_DISTANCE)
                    local previous_max_crystal_distance = MAX_CRYSTAL_DISTANCE_BY_STAGE[inst._stage - 1] or 0
                    local time_delay = math.max(0, ((offset - previous_max_crystal_distance) / TILE_SCALE) * TERRAFORM_DELAY)

                    time = inst.components.timer:GetTimeLeft("try_crystals") + (time_delay + (2*1))
                end
            end

            if time then
                crystal_spawn_info = string.format(ReplacePrefabName(STRINGS.eventtimer.rift_portal.next_crystal), TimeToString(time))
            end
        end

        -- 合并信息
        local description = CombineLines(stage_info, crystal_count_info, crystal_spawn_info)
        return description
    end,
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "lunarrift_portal.png",
        scale = 0.8,
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.rift_portal_text
        text = string.gsub(text,"\n",", ")
        return STRINGS.eventtimer.rift_portal.name .. ": " .. text
    end
}

return info
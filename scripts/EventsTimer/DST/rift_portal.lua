-- 月亮裂隙信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616 (爱死你了)

-- 吓哭了
local remotegettextfn = function(Thread)
    if not (TheWorld and TheWorld:HasTag("forest")) then -- 仅在森林世界更新数据
        -- 取消数据更新任务
        if Thread then KillThreadsWithID(Thread.id) end
        return
    end

local cmd = [[
local STAGE_GROWTH_TIMER = "trynextstage"
local MAX_CRYSTAL_RING_COUNT_BY_STAGE = BBGOAT_FN.getval(_G.Prefabs.lunarrift_portal.fn, "MAX_CRYSTAL_RING_COUNT_BY_STAGE")
local CRYSTALS_PER_RING = BBGOAT_FN.getval(_G.Prefabs.lunarrift_portal.fn, "CRYSTALS_PER_RING")
local MIN_CRYSTAL_DISTANCE = BBGOAT_FN.getval(_G.Prefabs.lunarrift_portal.fn, "MIN_CRYSTAL_DISTANCE")
local TERRAFORM_DELAY = BBGOAT_FN.getval(_G.Prefabs.lunarrift_portal.fn, "TERRAFORM_DELAY")
local MAX_CRYSTAL_DISTANCE_BY_STAGE = BBGOAT_FN.getval(_G.Prefabs.lunarrift_portal.fn, "MAX_CRYSTAL_DISTANCE_BY_STAGE")
local TimerPrefabs = _G.EventTimerClient.TimerPrefabs
local HookPrefab = _G.EventTimerClient.HookPrefab
local inst = TimerPrefabs["lunarrift_portal"] or HookPrefab("lunarrift_portal")
if not inst then return DataDumper({ not_found = true }) end
local next_stage_time
if inst.components.timer and inst.components.timer:TimerExists(STAGE_GROWTH_TIMER) and not (inst._stage == TUNING.RIFT_LUNAR1_MAXSTAGE) then
    next_stage_time = inst.components.timer:GetTimeLeft(STAGE_GROWTH_TIMER)
end
local crystal_count_info
local crystal_spawn_info
local max_crystals = MAX_CRYSTAL_RING_COUNT_BY_STAGE[inst._stage] * CRYSTALS_PER_RING
local current_crystals = 0
local available_crystals = 0
local quickest_time_to_available_crystal
local crystal_spawn_time
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
local crystals_can_spawn = (max_crystals - current_crystals) >= CRYSTALS_PER_RING
if (crystals_can_spawn or available_crystals < current_crystals) then
    local time
    if quickest_time_to_available_crystal  then
        time = quickest_time_to_available_crystal
    elseif crystals_can_spawn then
        if inst.components.timer:TimerExists("try_crystals") then
            local offset = MIN_CRYSTAL_DISTANCE + math.sqrt(1)*(MAX_CRYSTAL_DISTANCE_BY_STAGE[inst._stage] - MIN_CRYSTAL_DISTANCE)
            local previous_max_crystal_distance = MAX_CRYSTAL_DISTANCE_BY_STAGE[inst._stage - 1] or 0
            local time_delay = math.max(0, ((offset - previous_max_crystal_distance) / TILE_SCALE) * TERRAFORM_DELAY)

            time = inst.components.timer:GetTimeLeft("try_crystals") + (time_delay + (2*1))
        end
    end
    if time then
        crystal_spawn_time = time
    end
end
return DataDumper(
{
_stage = inst._stage, -- 当前阶段
RIFT_LUNAR1_MAXSTAGE = TUNING.RIFT_LUNAR1_MAXSTAGE, -- 最大阶段
next_stage_time = next_stage_time, -- 多久进入下一阶段
available_crystals = available_crystals, -- 可用晶体数量
current_crystals = current_crystals, -- 当前晶体数量
max_crystals = max_crystals, -- 最大晶体数量
crystal_spawn_time = crystal_spawn_time, -- 下一波晶体生成时间
}
)
]]

    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res._stage then
            -- 裂隙阶段信息
            local stage_info = string.format(STRINGS.eventtimer.riftspawner.stage, res._stage, res.RIFT_LUNAR1_MAXSTAGE) -- 阶段信息，内容类似：阶段 1 / 3
            if res.next_stage_time then
                stage_info = stage_info .. ": " .. string.format(STRINGS.eventtimer.rift_portal.next_stage, TimeToString(res.next_stage_time)) -- 补充信息：%s后进入下一阶段
            end

            -- 裂隙晶体信息
            local crystal_count_info -- 可用晶体的信息。内容类似：裂隙晶体：1可用 / 4总共 / 4最大
            local crystal_spawn_info -- 下一波晶体生成时间。内容类似：下一波裂隙晶体生成于0时3分3秒后

            local max_crystals = res.max_crystals -- 最大晶体数量
            local current_crystals = res.current_crystals -- 当前晶体数量
            local available_crystals = res.available_crystals -- 可用晶体数量

            -- 显示可用晶体的数量
            if available_crystals > 0 then
                crystal_count_info = string.format(ReplacePrefabName(STRINGS.eventtimer.rift_portal.crystals), available_crystals, current_crystals, max_crystals)
            end

            -- 显示晶体再生时间
            if res.crystal_spawn_time then
                crystal_spawn_info = string.format(ReplacePrefabName(STRINGS.eventtimer.rift_portal.next_crystal), TimeToString(res.crystal_spawn_time))
            end

            -- 合并信息
            local description = CombineLines(stage_info, crystal_count_info, crystal_spawn_info)
            SaveTextData("rift_portal", description)
        elseif res and res.not_found then -- 当前裂隙未生成
            SaveTextData("rift_portal", "")
        else
            SaveTextData("rift_portal", "")
            if res and res.err then
                print('[警告] rift_portal remotegettextfn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            end
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
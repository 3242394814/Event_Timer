local stagetimne = TUNING.BEEQUEEN_RESPAWN_TIME / 3
local function BeequeenhiveGrown()
    local beequeenhive = TimerPrefabs["beequeenhive"]
    if not beequeenhive or not beequeenhive:IsValid() then
        return
    end

    local timer = beequeenhive.components.timer
    if not timer then
        return
    end

    if timer:GetTimeLeft("hivegrowth1") then
        return 2 * stagetimne + timer:GetTimeLeft("hivegrowth1")
    elseif TimerPrefabs["beequeenhive"].components.timer:GetTimeLeft("hivegrowth2") then
        return stagetimne + timer:GetTimeLeft("hivegrowth2")
    else
        return timer:GetTimeLeft("hivegrowth")
    end
end

local info
info = {
    gettimefn = BeequeenhiveGrown,
    anim = {
        scale = 0.055,
        bank = "bee_queen",
        build = "bee_queen_build",
        animation = "idle_loop",
        loop = true,
        uioffset = {
            x = 0,
            y = -10,
        },
    },
    DisableShardRPC = true,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.beequeenhive_time
        return time and string.format(ReplacePrefabName(STRINGS.eventtimer.beequeenhive.cooldown), TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.beequeenhive_time
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.beequeenhive.tips)), 10, time, 2
        end
        return false
    end,
}

return info
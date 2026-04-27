-- 镀金骑士冷却倒计时

local player_userid = TheNet:GetUserID()

local info
info = {
    gettextfn = function()
        local time_list = {}
        for _, player in pairs(AllPlayers) do
            if player and player:IsValid() and player.userid then
                local debuff = player.components.debuffable and player.components.debuffable:GetDebuff("yoth_princesscooldown_buff")
                if debuff then
                    local time = debuff.components and debuff.components.timer and debuff.components.timer:GetTimeLeft("buffover")
                    time_list[player.userid] = time and TimeToString(time)
                end
            end
        end
        return json.encode(time_list)
    end,
    anim = {
        scale = 0.08,
        bank = "knight",
        build = "knight_yoth_build",
        animation = "idle_loop",
        uioffset = {
            x = 0,
            y = -10,
        },
    },
    playerly = true, -- 指明是针对单个玩家的事件
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.yoth_knightmanager_text
        if not text or text == "" then return end

        local data = json.decode(text)
        if type(data) ~= "table" or not data[player_userid] then return end

        return string.format(ReplacePrefabName(STRINGS.eventtimer.yoth_knightmanager.announce), data[player_userid])
    end,
    tipsfn = function ()
        local text = ThePlayer.HUD.WarningEventTimeData.yoth_knightmanager_text
        if not text or text == "" then return end

        local data = json.decode(text)
        if type(data) ~= "table" or not data[player_userid] then return end

        local time = StringToTime(data[player_userid])
        if ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.yoth_knightmanager.tips)), 10, time, 2
        end
        return false
    end
}

return info
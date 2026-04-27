-- 海盗袭击，参考了 饥饥事件计时器 的代码 https://steamcommunity.com/sharedfiles/filedetails/?id=3511498282 @不要看上我的菊

-- 海盗袭击
local piratespawner_mult
local function PirateRaid()
    local self = TheWorld.components.piratespawner
    if not (self and self.queen) then return end
    local _nextpiratechance = Upvaluehelper.GetUpvalue(self.OnUpdate, "_nextpiratechance")
    local _activeplayers = Upvaluehelper.GetUpvalue(self.OnUpdate, "_activeplayers")
    local _lasttic_players = Upvaluehelper.GetUpvalue(self.OnUpdate, "_lasttic_players")
    local zones = Upvaluehelper.GetUpvalue(self.OnUpdate, "zones")
    if not (_nextpiratechance and _activeplayers and _lasttic_players and zones) then
        return
    end

    local mindist = math.huge
    piratespawner_mult = 0
    for i, v in ipairs(_activeplayers) do
        if not v.components.health:IsDead() and not TheWorld.Map:IsVisualGroundAtPoint(v.Transform:GetWorldPosition()) then
            if _lasttic_players and _lasttic_players[v] and _lasttic_players[v].time > 10 then
                if _lasttic_players[v].dist < mindist then
                    mindist = _lasttic_players[v].dist
                end
            end
        end
    end
    for i, band in ipairs(zones) do
        if band.max * band.max > mindist then
            piratespawner_mult = band.weight
            break
        end
    end
    if piratespawner_mult > 0 then
        local time = _nextpiratechance / piratespawner_mult -- 当前倍率下还需要多长时间尝试袭击
        return time
    end
end

local info
info = {
    gettimefn = PirateRaid,
    gettextfn = function(time)
        if time and time > 0 then
            return string.format(STRINGS.eventtimer.piratespawner.cooldown, TimeToString(time), piratespawner_mult)
        end
    end,
    anim = {
        scale = 0.12,
        build = "monkey_small",
        bank = "monkey_small",
        animation = "row_loop",
        loop = true,
        uioffset = {
            x = -2,
            y = -7,
        }
    },
    DisableShardRPC = true,
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.piratespawner_text
        text = string.gsub(text, "\n", ", ")
        return text
    end,
    tipsfn = nil -- 开始袭击的时候对应的玩家会说台词，不需要我来提醒
}

return info
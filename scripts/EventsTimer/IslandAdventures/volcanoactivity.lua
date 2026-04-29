local _eruption
local _eruption_timer

local info
info = {
    postinitfn = function()
        if TheNet:GetIsServer() then
            local network_worlds = {
                "shipwrecked",
                "volcanoworld",
            }
            for i, world in ipairs(network_worlds) do
                AddPrefabPostInit(world .. "_network", function()
                    local self = TheWorld.net.components.volcanoactivity
                    if not self then return end
                    _eruption = Upvaluehelper.GetUpvalue(self.OnUpdate, "_eruption") -- 火山是否正在爆发
                    _eruption_timer = Upvaluehelper.GetUpvalue(self.OnUpdate, "_eruption_timer")

                    info.DisableShardRPC = TheWorld:HasTag("volcano") -- 火山世界不同步倒计时，海难世界同步
                end)
            end
        else
            AddPrefabPostInit("world", function()
                if GetWorldtypeStr() ~= "shipwrecked" then
                    info.tipsfn = nil -- 非海难火山世界不提示火山爆发
                end
            end)
        end
    end,
    gettimefn = function()
        local self = TheWorld.net.components.volcanoactivity
        if not self then return end
        if not _eruption then return end

        local remaining_time
        local _firerain_duration = Upvaluehelper.GetUpvalue(self.OnUpdate, "_firerain_duration")

        if _eruption:value() then
            remaining_time = _firerain_duration - _eruption_timer:value()
        end

        return remaining_time
    end,
    gettextfn = function(remaining_time)
        return remaining_time and remaining_time > 0 and
            string.format(
                STRINGS.eventtimer.volcanoactivity.eruption,
                TimeToString(remaining_time)
        )
    end,
    image = {
        atlas = "images/Volcano_Active.xml",
        tex = "Volcano_Active.tex",
        scale = 0.8,
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.volcanoactivity_time
        return time > 0 and string.format(STRINGS.eventtimer.volcanoactivity.eruption, TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.volcanoactivity_time
        if time > 0 then
            return true, info.announcefn, time, nil, 1 -- 无声音 常驻显示爆发剩余时间
        end
    end
}

return info
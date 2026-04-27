-- 大灾变倒计时/大灾变期间的事件计时/蝙蝠袭击倒计时

local Next_Aporkalypse_Time

local aporkalypse, aporkalypse_attack, batted

-- 大灾变倒计时
aporkalypse = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddPrefabPostInit("world", function(inst)
            if inst:HasTag("porkland") then
                inst:ListenForEvent("aporkalypseclocktick", function(src, data)
                    Next_Aporkalypse_Time = data and data.timeuntilaporkalypse
                end)
            end
        end)
    end,
    gettimefn = function()
        return Next_Aporkalypse_Time
    end,
    gettextfn = function(time)
        if time and time > 0 then
            return string.format(STRINGS.eventtimer.aporkalypse.cooldown, TimeToString(time))
        end
    end,
    image = {
        atlas = "images/Aporkalypse_Clock.xml",
        tex = "Aporkalypse_Clock.tex",
        scale = 0.2
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.aporkalypse_time
        if time > 0 then
            return string.format(STRINGS.eventtimer.aporkalypse.cooldown, TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.aporkalypse_time

        if (JustEntered(time) and time < 2400) then
            return true, string.format(STRINGS.eventtimer.aporkalypse.cooldown, TimeToString(time)), 10, nil, 1
        elseif time == 480 then
            return true, string.format(STRINGS.eventtimer.aporkalypse.tips, TimeToString(time)), 10, nil, 2
        elseif time == 0 then -- 这个写法比较特殊..为了保证大灾变确实开始了
            return true, not (GetTime() < 10) and StringToFunction(STRINGS.eventtimer.aporkalypse.tips_ready), 5, 1, 3 -- 延迟1秒是因为大灾变在1秒后才真正开始
        end
        return false
    end
}

-- 大灾变中的事件倒计时（蝙蝠袭击、远古先驱袭击）
aporkalypse_attack = {
    gettimefn = function()
        if Next_Aporkalypse_Time and Next_Aporkalypse_Time == 0 then
            local self = TheWorld.net.components.aporkalypse
            if not self then return end
            local next_herald_attack = Upvaluehelper.GetUpvalue(self.OnUpdate, "_herald_time") -- 远古先驱袭击倒计时
            return next_herald_attack
        end
    end,
    gettextfn = function(next_herald_attack)
        local self = TheWorld.net.components.aporkalypse
        if not self then return end
        local next_bat_attack = Upvaluehelper.GetUpvalue(self.OnUpdate, "_bat_time") -- 蝙蝠袭击倒计时
        if not (next_bat_attack and next_herald_attack) then return end
        return string.format(ReplacePrefabName(STRINGS.eventtimer.aporkalypse.attack), TimeToString(next_bat_attack), TimeToString(next_herald_attack))
    end,
    image = {
        atlas = "images/Ancient_Herald.xml",
        tex = "Ancient_Herald.tex",
        scale = 0.2,
        offset = {
            x = 0,
            y = 7,
        }
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.aporkalypse_attack_text
        local next_bat_attack, next_herald_attack = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.aporkalypse.attack))
        if not (next_bat_attack and next_herald_attack) then return end
        return string.format(ReplacePrefabName(STRINGS.eventtimer.aporkalypse.announce_attack), next_bat_attack, next_herald_attack)
    end,
    tipsfn = nil, -- 几分钟就来一次，一直Tips不嫌烦么？
}

-- 蝙蝠袭击
batted = {
    gettimefn = function()
        if Next_Aporkalypse_Time and Next_Aporkalypse_Time > 0 then
            local self = TheWorld.components.batted
            if not self then return end
            local next_attack_in = Upvaluehelper.GetUpvalue(self.LongUpdate, "_bat_attack_time")
            return next_attack_in
        else
            local self = TheWorld.net.components.aporkalypse
            if not self then return end
            local time = Upvaluehelper.GetUpvalue(self.OnUpdate, "_bat_time")
            return time
        end
    end,
    gettextfn = function(next_attack_in)
        if Next_Aporkalypse_Time and Next_Aporkalypse_Time > 0 then
            local self = TheWorld.components.batted
            if not self then return end
            local bat_count = self:GetNumBats()
            local regen_in = Upvaluehelper.GetUpvalue(self.LongUpdate, "_bat_regen_time")
            if not (bat_count and regen_in and next_attack_in) then return end
            return string.format(STRINGS.eventtimer.batted.cooldowntext, TimeToString(next_attack_in), bat_count, TimeToString(regen_in))
        end
    end,
    anim = {
        scale = 0.08,
        build = "bat_vamp_build",
        bank = "bat_vamp",
        animation = "fly_loop",
        loop = true,
        uioffset = {
            x = 10,
            y = -15,
        },
        offset = {
            x = 0,
            y = -15,
        }
    },
    DisableShardRPC = true,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.batted_time
        if time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.batted.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.batted_time
        if time > 2 and time <= 90 then
            return true, batted.announcefn, time, nil, 2
        elseif JustEntered(time) and time < 960 then
            return true, batted.announcefn, 10, nil, 2
        elseif JustEntered(time) then
            return true, batted.announcefn, 10, nil, 1
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.batted.attack)), 10, time, 3
        end
        return false
    end
}

return aporkalypse, aporkalypse_attack, batted
-- 月相状态，参考了 饥饥事件计时器 的代码 https://steamcommunity.com/sharedfiles/filedetails/?id=3511498282 @不要看上我的菊

local second_world_moonphase -- 当前月相阶段(从世界使用)



local info
info = {
    postinitfn = function()
        AddComponentPostInit("shard_clock", function(self)
            if not TheNet:GetIsServer() then return end
            if not TheWorld.ismastershard then
                local IA_CORE = rawget(_G, "IA_CORE_HAS_LOADED")
                local world_type = ""

                if TheWorld:HasTag("porkland") then
                    world_type = "_plateau"
                elseif (not IA_CORE) or (IA_CORE and IsDSTWorld()) then
                    -- DST世界，什么也不做
                elseif IA_CORE and IsShipwreckedWorld() then
                    world_type = "_tropical"
                end

                local clockdirty = Upvaluehelper.GetEventHandle(self.inst, "clockdirty" .. world_type, "components/shard_clock")
                if not clockdirty then return end

                local _moonphase = Upvaluehelper.GetUpvalue(clockdirty, "_moonphase")
                if _moonphase and _moonphase:value() then
                    second_world_moonphase = _moonphase
                end
            end
        end)
    end,
    gettextfn = function()
        if TheWorld.ismastershard then -- 主世界
            local self = TheWorld.net.components.clock
            if not self then return end
            local MOON_PHASE_CYCLES
            local _mooniswaxing
            local _mooomphasecycle

            if TheWorld:HasTag("forest") or TheWorld:HasTag("cave") then
                MOON_PHASE_CYCLES = Upvaluehelper.FindUpvalue(self.OnLoad, "MOON_PHASE_CYCLES", "scripts/components/clock.lua")
                _mooniswaxing = Upvaluehelper.FindUpvalue(self.OnLoad, "_mooniswaxing", "scripts/components/clock.lua")
                _mooomphasecycle = Upvaluehelper.FindUpvalue(self.OnLoad, "_mooomphasecycle", "scripts/components/clock.lua")
            else
                MOON_PHASE_CYCLES = Upvaluehelper.GetUpvalue(self.OnLoad, "MOON_PHASE_CYCLES")
                _mooniswaxing = Upvaluehelper.GetUpvalue(self.OnLoad, "_mooniswaxing")
                _mooomphasecycle = Upvaluehelper.GetUpvalue(self.OnLoad, "_mooomphasecycle")
            end

            if not (MOON_PHASE_CYCLES and _mooniswaxing and _mooomphasecycle) then
                return
            end
            if _mooniswaxing:value() then -- 月黑 → 月圆
                return string.format(STRINGS.eventtimer.moon.moon_full, math.floor(#MOON_PHASE_CYCLES / 2 + 1 - _mooomphasecycle))
            else -- 月圆 → 月黑
                return string.format(STRINGS.eventtimer.moon.moon_new, math.floor(#MOON_PHASE_CYCLES + 1 - _mooomphasecycle))
            end
        elseif not TheWorld:HasTag("cave") then -- 从世界
            if not second_world_moonphase then return end
            if second_world_moonphase:value() == 1 then -- 新月
                return STRINGS.eventtimer.moon.moon_new_ready
            elseif second_world_moonphase:value() == 5 then -- 满月
                return STRINGS.eventtimer.moon.moon_full_ready
            end
        end
    end,
    imagechangefn = function(self)
        local text = ThePlayer.HUD.WarningEventTimeData.moon_text
        if not text or text == "" then return end
        if string.find(text, STRINGS.eventtimer.moon.str_full) then
            self.image = self.fullimage
        else
            self.image = self.newimage
        end
    end,
    fullimage = {
        scale = 1,
        atlas = "images/moon_full.xml",
        tex = "moon_full.tex",
    },
    newimage = {
        scale = 1,
        atlas = "images/moon_new.xml",
        tex = "moon_new.tex",
    },
    DisableShardRPC = true,
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.moon_text
        if not text or text == "" then return end
        if string.find(text, STRINGS.eventtimer.moon.str_full) then
            local day = Extract_by_format(text, STRINGS.eventtimer.moon.moon_full)
            if tonumber(day) == 10 then
                return STRINGS.eventtimer.moon.moon_new_ready .. " " .. text
            end
            return text
        else
            local day = Extract_by_format(text, STRINGS.eventtimer.moon.moon_new)
            if tonumber(day) == 10 then
                return STRINGS.eventtimer.moon.moon_full_ready .. " " .. text
            end
            return text
        end
    end,
    tipsfn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.moon_text
        if not text or text == "" then return end
        if string.find(text, STRINGS.eventtimer.moon.str_full) then
            local day = Extract_by_format(text, STRINGS.eventtimer.moon.moon_full)
            if tonumber(day) == 10 then
                return true, StringToFunction(STRINGS.eventtimer.moon.moon_new_ready), 10, nil, 1
            elseif text == STRINGS.eventtimer.moon.moon_full_ready then
                return true, StringToFunction(STRINGS.eventtimer.moon.moon_full_ready), 10, nil, 1
            end
        else
            local day = Extract_by_format(text, STRINGS.eventtimer.moon.moon_new)
            if tonumber(day) == 10 then
                return true, StringToFunction(STRINGS.eventtimer.moon.moon_full_ready), 10, nil, 1
            elseif text == STRINGS.eventtimer.moon.moon_new_ready then
                return true, StringToFunction(STRINGS.eventtimer.moon.moon_new_ready), 10, nil, 1
            end
        end
        return false
    end,
}

return info
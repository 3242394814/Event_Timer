local STATES = {
    none = "calm_loop", -- 默认
    calm = "calm_loop", -- 平静
    warn = "warn_loop", -- 警告
    wild = "wild_loop", -- 暴动
    dawn = "dawn_loop", -- 黎明
    lock = "wild_lock", -- 锁定暴动阶段
}

local locked -- 是否在暴动锁定阶段
local NightmareWildAnimChange_task
local function NightmareWildAnimChange(self)
    if TheNet:IsDedicated() then
        return
    end

    local last_anim
    if not NightmareWildAnimChange_task then
        NightmareWildAnimChange_task = TheWorld:DoPeriodicTask(1, function()
            if locked then
                self.anim.animation = STATES.wild -- 暴动锁定(因为计时器面板UI里的Anim是不会播放动画的，所以改用静态动画)
            elseif ThePlayer and ThePlayer.HUD.nightmareclock then
                self.anim.animation = STATES[TheWorld.state.nightmarephase]
            end

            if self.anim.animation ~= last_anim and ThePlayer and ThePlayer.HUD and ThePlayer.HUD.nightmareclock then
                last_anim = self.anim.animation
                ThePlayer.HUD.nightmareclock:SetEventAnim(self.anim) -- 屏幕左上角的倒计时不会自动刷新Anim，需要手动刷新
            end
        end)
    end
end

----------------------------------------------------------------------------------------------

local info
info = {
    anim = {
        scale = 0.5,
        bank = "nigthmarephaseindicator_eventtimer_client",
        build = "nigthmarephaseindicator_eventtimer_client",
        animation = "calm_loop",
        offset = {
            x = 0,
            y = 15,
        },
        uioffset = {
            x = 0,
            y = 15,
        },
    },
    animchangefn = NightmareWildAnimChange,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.nightmareclock_time
        local text = ThePlayer.HUD.WarningEventTimeData.nightmareclock_text
        if string.find(text, STRINGS.eventtimer.nightmareclock.phase_locked_text) then
            return STRINGS.eventtimer.nightmareclock.phase_locked
        end
        if TheWorld.state.nightmarephase == "none" then
            return time and string.format(STRINGS.eventtimer.nightmareclock.cooldown_none, TimeToString(time))
        else
            local phase = STRINGS.eventtimer.nightmareclock.phases[TheWorld.state.nightmarephase]
            return time and phase and string.format(STRINGS.eventtimer.nightmareclock.cooldown, phase, TimeToString(time))
        end
    end
}
----------------------------------------------------------------------------------------------

-- 纯本地获取方式
AddComponentPostInit('nightmareclock', function(clock)
    local _remainingtimeinphase = Upvaluehelper.GetUpvalue(clock.OnUpdate, "_remainingtimeinphase")
    local _totaltimeinphase = Upvaluehelper.GetUpvalue(clock.OnUpdate, "_totaltimeinphase")
    if not (_remainingtimeinphase and _totaltimeinphase) then return end

    info.DisableClientPrediction = true -- 满足条件，禁用预测倒计时功能，此事件本身每秒更新一次
    clock.inst:DoPeriodicTask(1, function()
        local remain = _remainingtimeinphase:value()
        local total = _totaltimeinphase:value()

        locked = remain == 0 and total ~= 0 -- 是否在暴动锁定阶段

        SaveTimeData("nightmareclock", remain)
        SaveTextData("nightmareclock", locked and STRINGS.eventtimer.nightmareclock.phase_locked_text or "")
    end)
end)

----------------------------------------------------------------------------------------------

return info
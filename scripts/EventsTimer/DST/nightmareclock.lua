local function NightmareWild()
    local nightmareclock = TheWorld.net.components.nightmareclock
    if not nightmareclock then
        return
    end

    local data = nightmareclock:OnSave()
    local locked = data.lockedphase
    local remainingtimeinphase = data.remainingtimeinphase

    if locked then return end

    return remainingtimeinphase
end

local STATES = {
    none = "calm_loop", -- 默认
    calm = "calm_loop", -- 平静
    warn = "warn_loop", -- 警告
    wild = "wild_loop", -- 暴动
    dawn = "dawn_loop", -- 黎明
    lock = "wild_lock", -- 锁定暴动阶段
}
local NightmareWildAnimChange_task
local function NightmareWildAnimChange(self)
    if TheNet:IsDedicated() then
        return
    end

    local last_anim
    if not NightmareWildAnimChange_task then
        NightmareWildAnimChange_task = TheWorld:DoPeriodicTask(1, function()
            local text = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData and ThePlayer.HUD.WarningEventTimeData.nightmareclock_text
            if text and string.find(text, STRINGS.eventtimer.nightmareclock.phase_locked_text) then
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

local info
info = {
    gettimefn = NightmareWild, -- 仅返回倒计时
    gettextfn = function() -- 仅锁定阶段返回
        local nightmareclock = TheWorld.net.components.nightmareclock
        if not nightmareclock then
            return
        end

        local data = nightmareclock:OnSave()
        return data.lockedphase and STRINGS.eventtimer.nightmareclock.phase_locked_text
    end,
    anim = {
        scale = 0.5,
        bank = "nigthmarephaseindicator",
        build = "nigthmarephaseindicator",
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
    DisableShardRPC = true,
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

return info
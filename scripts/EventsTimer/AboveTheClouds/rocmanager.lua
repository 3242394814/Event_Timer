local info
info = {
    gettimefn = GetWorldSettingsTimeLeft("ROC_RESPAWN_TIMER"),
    gettextfn = function(time)
        local self = TheWorld.components.rocmanager
        if not self then return end
        local data = self:OnSave()
        if data.roc then
            return  ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists)
        end
        if time and time > 0 then
            return TimeToString(time)
        end
    end,
    image = {
        atlas = "images/Roc.xml",
        tex = "Roc.tex",
    },
    anim = {
        scale = 0.008,
        build = "roc_head_build",
        bank = "head",
        animation = "idle_loop",
        loop = true,
        offset = {
            x = 0,
            y = -15,
        },
    },
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.rocmanager_time
        local text = ThePlayer.HUD.WarningEventTimeData.rocmanager_text
        if string.find(text, ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists)) then
            return ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists)
        elseif time > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.rocmanager.cooldown), TimeToString(time))
        end
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.rocmanager_time
        local text = ThePlayer.HUD.WarningEventTimeData.rocmanager_text
        if time > TUNING.SEG_TIME and time <= 90 then -- 如果没有目标玩家就从0变成30，为了防止重复tips需修改此处
            return true, info.announcefn, 10, nil, 2
        elseif JustEntered(time) and time < 960 then
            return true, info.announcefn, 10, nil, 2
        elseif text == ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.rocmanager.tips)), 10, nil, 3
        elseif JustEntered(time) then
            return true, info.announcefn, 10, nil, 1
        end
        return false
    end
}

return info
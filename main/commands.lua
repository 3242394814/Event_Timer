GLOBAL.setfenv(1, GLOBAL)

-- for master
function TurnOnAllWarning()
    if not TheWorld.ismastersim then
        return
    end

    for event, _ in pairs(WarningEvents) do
        WarningEvents[event].turn_on = true
    end
end

function TurnOffAllWarning()
    if not TheWorld.ismastersim then
        return
    end

    for event, _ in pairs(WarningEvents) do
        WarningEvents[event].turn_on = false
    end
end

function TurnOnWarning(event)
    if not TheWorld.ismastersim then
        return
    end

    if event and WarningEvents[event] then
        WarningEvents[event].turn_on = true
    end
end

function TurnOffWarning(event)
    if not TheWorld.ismastersim then
        return
    end
    if event and WarningEvents[event] then
        WarningEvents[event].turn_on = false
    end
end


local old_WarningEvents
function ShowAllEvent()
    if not old_WarningEvents then
        old_WarningEvents = deepcopy(WarningEvents)
    end

    for _, tb in pairs(WarningEvents) do
        tb.gettimefn = function(...)
            return 666
        end
        tb.gettextfn = function(...)
            return "测试测试(世界233)\n第一行长文字123\n第二行长文字长文字长文字长文字\n第三行最长最长最长最长最长最长的文字"
        end
    end
end

function DefaultEvent()
    if not old_WarningEvents then
        old_WarningEvents = deepcopy(WarningEvents)
    end
    WarningEvents = deepcopy(old_WarningEvents)

    for warningevent in pairs(WarningEvents) do
        local event_time = warningevent .. "_time"
        local event_text = warningevent .. "_text"
        local warningtimer = TheWorld.net.components.warningtimer
        warningtimer.inst.replica.warningtimer[event_time]:set(0)
        warningtimer.inst.replica.warningtimer[event_text]:set("")
    end
end

-- for client

function ShowAllWarning()
    if not ThePlayer then
        return
    end

    for event, _ in pairs(WarningEvents) do
        ThePlayer.HUD[event].force = true
    end
end

function HideAllWarning()
    if not ThePlayer then
        return
    end

    for event, _ in pairs(WarningEvents) do
        ThePlayer.HUD[event].force = false
    end
end

function DefaultWarning()
    HideAllWarning()
end

function ShowWarning(event)
    if not ThePlayer then
        return
    end

    if event and ThePlayer.HUD[event] then
        ThePlayer.HUD[event].force = true
    end
end

function HideWarning(event)
    if not ThePlayer then
        return
    end

    if event and ThePlayer.HUD[event] then
        ThePlayer.HUD[event].force = false
    end
end
GLOBAL.setfenv(1, GLOBAL)
local TimerMode = EventTimer.TimerMode

-- for master
function TurnOnAllWaring()
    if not TheWorld.ismastersim then
        return
    end

    for event, _ in pairs(WaringEvents) do
        WaringEvents[event].turn_on = true
    end
end

function TurnOffAllWaring()
    if not TheWorld.ismastersim then
        return
    end

    for event, _ in pairs(WaringEvents) do
        WaringEvents[event].turn_on = false
    end
end

function TurnOnWaring(event)
    if not TheWorld.ismastersim then
        return
    end

    if event and WaringEvents[event] then
        WaringEvents[event].turn_on = true
    end
end

function TurnOffWaring(event)
    if not TheWorld.ismastersim then
        return
    end
    if event and WaringEvents[event] then
        WaringEvents[event].turn_on = false
    end
end


local old_WaringEvents
function ShowAllEvent()
    if not old_WaringEvents then
        old_WaringEvents = deepcopy(WaringEvents)
    end

    for _, tb in pairs(WaringEvents) do
        tb.gettimefn = function(...)
            return 666
        end
        tb.gettextfn = function(...)
            return "测试测试(世界233)\n第一行长文字123\n第二行长文字长文字\n第三行最长最长最长最长的文字"
        end
    end
end

function DefaultEvent()
    WaringEvents = old_WaringEvents

    for waringevent in pairs(WaringEvents) do
        local event_time = waringevent .. "_time"
        local event_text = waringevent .. "_text"
        local waringtimer = TheWorld.net.components.waringtimer
        waringtimer.inst.replica.waringtimer[event_time]:set(0)
        waringtimer.inst.replica.waringtimer[event_text]:set("")
    end
end

-- for client

function ShowAllWaring()
    if not ThePlayer then
        return
    end

    for event, _ in pairs(WaringEvents) do
        ThePlayer.HUD[event].force = true
    end
end

function HideAllWaring()
    if not ThePlayer then
        return
    end

    for event, _ in pairs(WaringEvents) do
        ThePlayer.HUD[event].force = false
    end
end

function DefaultWaring()
    HideAllWaring()
end

function ShowWaring(event)
    if not ThePlayer then
        return
    end

    if event and ThePlayer.HUD[event] then
        ThePlayer.HUD[event].force = true
    end
end

function HideWaring(event)
    if not ThePlayer then
        return
    end

    if event and ThePlayer.HUD[event] then
        ThePlayer.HUD[event].force = false
    end
end

function SetTimeMode(mode)
    if not ThePlayer then
        return
    end

    TimerMode = mode
end

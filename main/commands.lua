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
    -- if not ThePlayer then
    --     return
    -- end

    -- for event, _ in pairs(WaringEvents) do
    --     ThePlayer.HUD[event].force = nil
    -- end
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

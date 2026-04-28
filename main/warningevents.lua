local TimeToString = TimeToString
local SyncTimer = GetModConfigData("SyncTimer")
local RequireEvent = RequireEvent

-- 判断某个模组是否加载
local function Ismodloaded(name)
	return KnownModIndex:IsModEnabledAny(name)
end

GLOBAL.setfenv(1, GLOBAL)

WarningEvents = rawget(_G, "WarningEvents") or {}
local GameEvents
GameEvents = {
    ---------------------------------------- Forest ---------------------------------------

    hounded = RequireEvent("DST/hounded"),
    deerclopsspawner = RequireEvent("DST/deerclopsspawner"),
    deerherdspawner = RequireEvent("DST/deerherdspawner"),
    klaussackspawner = RequireEvent("DST/klaussackspawner"),
    sinkholespawner = RequireEvent("DST/sinkholespawner"),
    beargerspawner = RequireEvent("DST/beargerspawner"),
    dragonfly_spawner = RequireEvent("DST/dragonfly_spawner"),
    beequeenhive = RequireEvent("DST/beequeenhive"),
    terrarium = RequireEvent("DST/terrarium"),
    malbatrossspawner = RequireEvent("DST/malbatrossspawner"),
    crabkingspawner = RequireEvent("DST/crabkingspawner"),
    moon = RequireEvent("DST/moon"),
    farming_manager = RequireEvent("DST/farming_manager"),
    piratespawner = RequireEvent("DST/piratespawner"),
    forestdaywalkerspawner = RequireEvent("DST/forestdaywalkerspawner"),
    messagebottlemanager = RequireEvent("DST/messagebottlemanager"),
    lunarthrall_plantspawner = RequireEvent("DST/lunarthrall_plantspawner"),
    lunar_riftspawner = RequireEvent("DST/lunar_riftspawner"),
    shadow_riftspawner = RequireEvent("DST/shadow_riftspawner"),
    rift_portal = RequireEvent("DST/rift_portal"),

    ---------------------------------------- Cave ----------------------------------------

    shadowrift_portal = RequireEvent("DST/shadowrift_portal"),
    daywalkerspawner = RequireEvent("DST/daywalkerspawner"),
    shadowthrallmanager = RequireEvent("DST/shadowthrallmanager"),
    toadstoolspawner = RequireEvent("DST/toadstoolspawner"),
    atrium_gate = RequireEvent("DST/atriium_gate"),
    nightmareclock = RequireEvent("DST/nightmareclock"),
    quaker = RequireEvent("DST/quaker"),

    ---------------------------------------- Player ----------------------------------------

    -- 针对单个玩家的事件，不支持gettimefn，gettextfn返回一个包含所有玩家信息的json字符串。不支持跨世界同步
    flotsamgenerator = RequireEvent("DST/flotsamgenerator"),
    yoth_knightmanager = RequireEvent("DST/yoth_knightmanager"),
}
for k, v in pairs(GameEvents) do
    WarningEvents[k] = v
end

local ShipwreckedEvents = rawget(_G, "IA_SW_ENABLED") and {
    ---------------------------------------- IA-SW ---------------------------------------
    chessnavy = RequireEvent("IslandAdventures/chessnavy"),
    volcanoactivity = RequireEvent("IslandAdventures/volcanoactivity"),
    volcanomanager = RequireEvent("IslandAdventures/volcanomanager"),
    twisterspawner = RequireEvent("IslandAdventures/twisterspawner"),
    krakener = RequireEvent("IslandAdventures/krakener"),
    tigersharker = RequireEvent("IslandAdventures/tigersharker"),
    islandsklaussackspawner = RequireEvent("IslandAdventures/islandsklaussackspawner"),
} or {}

-- 将海难计时添加到WarningEvents
for k, v in pairs(ShipwreckedEvents) do
    WarningEvents[k] = v
end

local HamletEvents = rawget(_G, "IA_HAM_ENABLED") and
{   ---------------------------------------- IA-HAM ---------------------------------------
    -- TODO
}
or Ismodloaded("workshop-3322803908") and
{   ---------------------------------------- Above The Clouds ---------------------------------------
    pugalisk_fountain = RequireEvent("AboveTheClouds/pugalisk_fountain"),
    banditmanager = RequireEvent("AboveTheClouds/banditmanager"),
    aporkalypse = RequireEvent("AboveTheClouds/aporkalypse"),
    aporkalypse_attack = select(2, RequireEvent("AboveTheClouds/aporkalypse")),
    batted = select(3, RequireEvent("AboveTheClouds/aporkalypse")),
    rocmanager = RequireEvent("AboveTheClouds/rocmanager"),
} or {}

-- 将猪镇计时添加到WarningEvents
for k, v in pairs(HamletEvents) do
    WarningEvents[k] = v
end

local UncompromisingEvents = TUNING.DSTU ~= nil and
{
    gmoosespawner = RequireEvent("UncompromisingMode/gmoosespawner"),
    mock_dragonflyspawner = RequireEvent("UncompromisingMode/mock_dragonflyspawner"),
    -- 巨鹿和原版的一样，不需要加
} or {}

-- 将永不妥协计时添加到WarningEvents
for k, v in pairs(UncompromisingEvents) do
    WarningEvents[k] = v
end

-- 初始化事件
for k, v in pairs(WarningEvents) do
    if v.postinitfn then
        v.postinitfn()
    end
end

AddShardModRPCHandler("EventTimer", "event_time_shardrpc", function(shardid, event, timedata, worldtype)
    if TheShard:GetShardId() == tostring(shardid) then return end
    if not SyncTimer then return end -- 未开启同步功能，取消同步
    if not rawget(_G, "TheWorld") then return end

    local event_time_shardrpc = event .. "_time_shardrpc"
    local event_text_shardrpc = event .. "_text_shardrpc"

    local warningtimer = TheWorld.net.components.warningtimer
    if timedata then
        if warningtimer.inst.replica.warningtimer[event_time_shardrpc] then
            warningtimer.inst.replica.warningtimer[event_time_shardrpc]:set(timedata or 0)
        end

        local textdata
        if timedata > 0 then
            textdata = TimeToString(timedata) -- 同时设置text，以显示来自哪个世界
            textdata = string.format(STRINGS.eventtimer.worldid, shardid) .. "(" .. worldtype .. ")\n" .. textdata
        end

        if warningtimer.inst.replica.warningtimer[event_text_shardrpc] then
            warningtimer.inst.replica.warningtimer[event_text_shardrpc]:set(textdata or "")
        end
    end
end)

AddShardModRPCHandler("EventTimer", "event_text_shardrpc", function(shardid, event, textdata, worldtype)
    if not rawget(_G, "TheWorld") then return end
    if TheShard:GetShardId() == tostring(shardid) then return end
    if not SyncTimer then return end -- 未开启同步功能，取消同步
    local event_text_shardrpc = event .. "_text_shardrpc"

    local warningtimer = TheWorld.net.components.warningtimer
    if textdata then
        textdata = textdata ~= "" and (string.format(STRINGS.eventtimer.worldid, shardid) .. "(" .. worldtype .. ")\n" .. textdata)
        if warningtimer.inst.replica.warningtimer[event_text_shardrpc] then
            warningtimer.inst.replica.warningtimer[event_text_shardrpc]:set(textdata or "")
        end
    end
end)
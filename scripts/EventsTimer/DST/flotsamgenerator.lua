-- 瓶中信
-- 参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616

local _guaranteed_spawn_tasks
local player_userid = TheNet:GetUserID()

local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        AddComponentPostInit("flotsamgenerator", function()
            if TheWorld.components.flotsamgenerator and TheWorld.components.flotsamgenerator.ScheduleGuaranteedSpawn then
                _guaranteed_spawn_tasks = Upvaluehelper.GetUpvalue(TheWorld.components.flotsamgenerator.ScheduleGuaranteedSpawn, "_guaranteed_spawn_tasks")
            end
        end)
    end,
    gettextfn = function()
        if not _guaranteed_spawn_tasks then return end
        local time_list = {}
        for _, player in pairs(AllPlayers) do
            if player and player:IsValid() and player.userid then
                local tasks = _guaranteed_spawn_tasks[player]
                if tasks then
                    for v, task in pairs(tasks) do
                        if v.prefabs[1] == "messagebottle" then
                            time_list[player.userid] = TimeToString(GetTaskRemaining(task))
                        end
                    end
                end
            end
        end
        return json.encode(time_list)
    end,
    image = {
        atlas = "images/inventoryimages2.xml",
        tex = "messagebottle.tex",
        scale = 0.9,
    },
    playerly = true, -- 指明是针对单个玩家的事件
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.flotsamgenerator_text
        if not text or text == "" then return end
        local data = json.decode(text)
        if type(data) ~= "table" or not data[player_userid] then return end
        return string.format(ReplacePrefabName(STRINGS.eventtimer.flotsamgenerator.announce), data[player_userid])
    end
}

return info
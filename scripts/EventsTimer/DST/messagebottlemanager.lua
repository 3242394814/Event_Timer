-- 待打捞宝藏数量信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616

local info
info = {
    gettextfn = function()
        local self = TheWorld.components.messagebottlemanager
        if not self then return end
        local count = 0
        for _ in pairs(self.active_treasure_hunt_markers) do
            count = count + 1
        end
        if count > 0 then
            return string.format(STRINGS.eventtimer.messagebottlemanager.text, count, TUNING.MAX_ACTIVE_TREASURE_HUNTS)
        end
    end,
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "messagebottletreasure_marker.png",
        scale = 0.9,
    },
    -- DisableShardRPC = true, -- 其它世界有宝藏吗？没有！
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.messagebottlemanager_text
        text = string.gsub(text, "\n", ": ")
        return text
    end,
}

return info
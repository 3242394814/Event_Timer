-- 致命亮茄信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616

local lunarthrall_plant_table = {} -- 储存致命亮茄数量

local info
info = {
    postinitfn = function()
        if not TheNet:GetIsServer() then return end
        -- 存储世界上亮茄的数量
        AddPrefabPostInit("lunarthrall_plant", function(inst)
            -- if not TheWorld.ismastersim then
            --     return
            -- end

            table.insert(lunarthrall_plant_table, inst)
            inst:ListenForEvent("onremove", function(inst)
                local index = table.reverselookup(lunarthrall_plant_table, inst)
                if index then
                    table.remove(lunarthrall_plant_table, index)
                end
            end)
        end)
    end,
    gettextfn = function()
        local self = TheWorld.components.lunarthrall_plantspawner
        if not self then return end
        local count = #lunarthrall_plant_table
        if count == 0 and not self.waves_to_release then
            return
        end
        local description = string.format(STRINGS.eventtimer.lunarthrall_plantspawner.infested_count, count)
        if self._nextspawn then
            description = description .. "\n" .. string.format(STRINGS.eventtimer.lunarthrall_plantspawner.spawn, TimeToString(GetTaskRemaining(self._nextspawn)))
        elseif self._spawntask then
            description = description .. "\n" .. string.format(STRINGS.eventtimer.lunarthrall_plantspawner.next_wave, TimeToString(GetTaskRemaining(self._spawntask)))
        end
        if self.waves_to_release and self.waves_to_release > 0 then
            description = description .. "\n" .. string.format(STRINGS.eventtimer.lunarthrall_plantspawner.remain_waves, self.waves_to_release)
        end
        return description
    end,
    image = {
        atlas = "minimap/minimap_data.xml",
        tex = "lunarthrall_plant.png",
        scale = 0.8,
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.lunarthrall_plantspawner_text
        text = string.gsub(text,"\n",", ")
        return STRINGS.NAMES.LUNARTHRALL_PLANT .. ": " .. text
    end,
}

return info
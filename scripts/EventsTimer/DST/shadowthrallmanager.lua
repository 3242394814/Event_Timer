-- 梦魇裂隙/墨荒信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616

local THRALL_NAMES = setmetatable({
    shadowthrall_hands = STRINGS.NAMES.SHADOWTHRALL_HANDS_ALLEGIANCE,
    shadowthrall_horns = STRINGS.NAMES.SHADOWTHRALL_HORNS_ALLEGIANCE,
    shadowthrall_wings = STRINGS.NAMES.SHADOWTHRALL_WINGS_ALLEGIANCE,
    shadowthrall_mouth = STRINGS.NAMES.SHADOWTHRALL_MOUTH_ALLEGIANCE,
}, {
    __index = function(self, index)
        rawset(self, index, "???")
        return rawget(self, index)
    end
})

local info
info = {
    gettextfn = function()
        local self = TheWorld.components.shadowthrallmanager
        if not self then return end

        local thrall_string -- 奴隶
        local fissure_string -- 裂隙

        local data = self:OnSave()
        local fissure = self:GetControlledFissure()

        -- 检查是否有裂缝（和奴隶）
        if fissure then
            local thralls_alive = {}
            local thralls_alive_string = {}

            if data.thrall_hands ~= nil then
                local ent = Ents[data.thrall_hands]
                thralls_alive[#thralls_alive+1] = ent
                if ent then
                    thralls_alive_string[#thralls_alive_string+1] = THRALL_NAMES[ent.prefab]
                end
            end
            if data.thrall_horns ~= nil then
                local ent = Ents[data.thrall_horns]
                thralls_alive[#thralls_alive+1] = ent
                if ent then
                    thralls_alive_string[#thralls_alive_string+1] = THRALL_NAMES[ent.prefab]
                end
            end
            if data.thrall_wings ~= nil then
                local ent = Ents[data.thrall_wings]
                thralls_alive[#thralls_alive+1] = ent
                if ent then
                    thralls_alive_string[#thralls_alive_string+1] = THRALL_NAMES[ent.prefab]
                end
            end

            thralls_alive_string = table.concat(thralls_alive_string, ", ")

            -- 裂缝可以“靠近”玩家，但如果玩家离得不够近，就不会产生墨荒。
            if #thralls_alive == 0 and data.spawnthrallstime then
                thrall_string = STRINGS.eventtimer.shadowthrallmanager.waiting_for_players
            else
                thrall_string = string.format(STRINGS.eventtimer.shadowthrallmanager.thralls_alive, #thralls_alive, thralls_alive_string)
            end

            if data.dreadstonecooldown then
                fissure_string = string.format(ReplacePrefabName(STRINGS.eventtimer.shadowthrallmanager.dreadstone_regen), TimeToString(data.dreadstonecooldown))
            end
        elseif data.cooldown then
            fissure_string = string.format(STRINGS.eventtimer.shadowthrallmanager.fissure_cooldown, TimeToString(data.cooldown))
        end

        local description = CombineLines(thrall_string, fissure_string)
        return description
    end,
    image = {
        atlas = "images/Dreadstone_Outcrop.xml",
        tex = "Dreadstone_Outcrop.tex",
        scale = 0.4,
        uioffset = {
            x = 0,
            y = -2,
        },
    },
    announcefn = function()
        local text = ThePlayer.HUD.WarningEventTimeData.shadowthrallmanager_text
        text = string.gsub(text,"\n",", ")
        return STRINGS.NAMES.SHADOWTHRALL_MOUTH .. ": " .. text
    end,
}

return info
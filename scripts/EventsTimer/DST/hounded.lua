-- 猎犬/洞穴蠕虫/鳄狗/巨大洞穴蠕虫 Anim刷新
local HoundedAnimChangeFn
local function HoundedAnimChange(self)
    if TheNet:IsDedicated() then
        return
    end

    local last_anim
    if not HoundedAnimChangeFn then
        HoundedAnimChangeFn = function()
            local text = ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData and ThePlayer.HUD.WarningEventTimeData.hounded_text
            local is_worm_boss = text and Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss))
            local worldtype = GetWorldtypeStr()
            if worldtype == "shipwrecked" then
                self.anim = self.islandanim
            elseif is_worm_boss then
                self.anim = self.wormbossanim
            elseif worldtype == "cave" then
                self.anim = self.caveanim
            elseif worldtype == "porkland" then
                self.anim = {
                    scale = 0.08,
                    build = "bat_vamp_build",
                    bank = "bat", -- 云霄国度是 bat_vamp
                    animation = "fly_loop",
                    loop = true,
                    uioffset = {
                        x = 10,
                        y = -15,
                    },
                    offset = {
                        x = 0,
                        y = -15,
                    }
                }
            else
                self.anim = self.forestanim
            end

            if (self.anim and self.anim.bank ~= last_anim) and ThePlayer and ThePlayer.HUD and ThePlayer.HUD.hounded then
                last_anim = self.anim.bank
                ThePlayer.HUD.hounded:SetEventAnim(self.anim)
            end
        end
    end
    HoundedAnimChangeFn()
end

-- 监听热带冒险的区域变化事件
MOD_util:AddPlayerPostInit(function(world, player)
    player:ListenForEvent("regionchange_client", function(inst, data)
        if HoundedAnimChangeFn then
            HoundedAnimChangeFn()
        end
    end)
end)

local info
info = {
    gettimefn = function()
        if TheWorld.components.hounded then
            local data = TheWorld.components.hounded:OnSave()
            return data and data.timetoattack
        end
    end,
    gettextfn = function(time)
        if not TheWorld:HasTag("cave") or not time then return end
        local self = TheWorld.components.hounded
        if not self then return end

        local next_wave_is_wormboss = Upvaluehelper.GetUpvalue(self.DoWarningSpeech, "_wave_pre_upgraded")
        local _wave_override_chance = self:OnSave().wave_override_chance

        if next_wave_is_wormboss then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss), TimeToString(time))
        elseif checknumber(_wave_override_chance) and _wave_override_chance > 0 then
            return string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.worm_boss_chance), TimeToString(time), _wave_override_chance * 100)
        end
    end,
    imagechangefn = function(self)
        local text = ThePlayer.HUD.WarningEventTimeData.hounded_text
        local is_worm_boss = text and Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss))
        local worldtype = GetWorldtypeStr()
        if worldtype == "porkland" then
            self.image = nil
        elseif worldtype == "shipwrecked" then
            self.image = self.islandimage
        elseif is_worm_boss then
            self.image = self.wormbossimage
        elseif worldtype == "cave" then
            self.image = self.caveimage
        else
            self.image = self.forestimage
        end
    end,
    forestimage = {
        atlas = "images/Hound.xml",
        tex = "Hound.tex",
        scale = 0.35,
    },
    caveimage = {
        atlas = "images/Depths_Worm.xml",
        tex = "Depths_Worm.tex",
        scale = 0.2,
    },
    wormbossimage = {
        atlas = "images/Worm_boss.xml",
        tex = "Worm_boss.tex",
        scale = 0.2,
    },
    animchangefn = HoundedAnimChange,
    forestanim = {
        scale = 0.099,
        bank = "hound",
        build = "hound_ocean",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 0,
            y = 0,
        },
        offset = {
            x = 0,
            y = 0,
        }
    },
    islandanim = {
        scale = 0.09,
        bank = "crocodog",
        build = "crocodog",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 6,
            y = 0,
        },
        offset = {
            x = 0,
            y = 0,
        }
    },
    caveanim = {
        scale = 0.066,
        bank = "worm",
        build = "worm",
        animation = "atk",
        loop = true,
        uioffset = {
            x = 0,
            y = 0,
        },
        offset = {
            x = 0,
            y = 0,
        }
    },
    wormbossanim = {
        scale = 0.066,
        bank = "worm_boss",
        build = "worm_boss",
        animation = "head_idle_loop",
        orientation = 1,
        loop = true,
        uioffset = {
            x = 0,
            y = 0,
        },
        offset = {
            x = 0,
            y = 0,
        }
    },
    DisableShardRPC = true,
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.hounded_time
        local text = ThePlayer.HUD.WarningEventTimeData.hounded_text
        local is_worm_boss = text ~= "" and Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss))
        return is_worm_boss and text or time and string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns[GetWorldtypeStr()]), TimeToString(time))
    end,
    tipsfn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.hounded_time
        local text = ThePlayer.HUD.WarningEventTimeData.hounded_text
        local is_worm_boss = text ~= "" and Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss))

        if time > 2 and time <= 90 then
            return true, info.announcefn, time, nil, 2
        elseif JustEntered(time) and time < 960 then
            return true, info.announcefn, 10, nil, 2
        elseif JustEntered(time) then
            return true, info.announcefn, 10, nil, 1
        elseif ready_attack(time) then
            return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.hounded.attack[is_worm_boss and "worm_boss" or GetWorldtypeStr()])), 10, time, 3
        end
        return false
    end
}

return info
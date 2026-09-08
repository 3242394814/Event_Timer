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

----------------------------------------------------------------------------------------------

-- 纯本地获取方式
local localgettimefn = function()
    local hounded_warning = {
        hound = true,
        worm  = true,
        crocodog = true,
    }
    local current_level
    for attacker in pairs(hounded_warning) do
        for i = 2, 4 do
            local level = tostring(i)
            AddPrefabPostInit(attacker .. "warning_lvl" .. level, function(inst)
                -- 初始时间 = (5 - level) * 30 （level=2→90s，level=3→60s，level=4→30s）
                if not current_level or current_level < i then
                    local initial_time = (5 - i) * 30
                    SaveTimeData("hounded", initial_time)

                    -- 猎犬袭击后 重置等级记录以便下次警告
                    if i == 4 then
                        if TheWorld then
                            TheWorld:DoTaskInTime(60, function()
                                current_level = nil
                            end)
                        end
                    end
                end
                current_level = i
            end)
        end
    end
end

----------------------------------------------------------------------------------------------

local next_wave_is_wormboss, _wave_override_chance
local remotegettextfn = function(Thread)
    if not TheWorld:HasTag("cave") then return end
    local cmd = [[
        local self = TheWorld.components.hounded
        if not self then return DataDumper({ not_found = true })end

        local next_wave_is_wormboss = BBGOAT_FN.getval(self.DoWarningSpeech, "_wave_pre_upgraded")
        local _wave_override_chance = self:OnSave().wave_override_chance

        return DataDumper({next_wave_is_wormboss = next_wave_is_wormboss, _wave_override_chance = _wave_override_chance})
    ]]

    BBGOAT_util:remote(cmd, nil, function(res)
        if res and res.err then
            SaveTextData("hounded", "")
            print('[警告] hounded remotegettextfn error:', res.err)
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res.not_found then
            -- 取消数据更新任务
            if Thread then KillThreadsWithID(Thread.id) end
        elseif res then
            next_wave_is_wormboss = res.next_wave_is_wormboss
            _wave_override_chance = res._wave_override_chance
            if next_wave_is_wormboss then
                local str = string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss), TimeToString(ThePlayer.HUD.WarningEventTimeData.hounded_time))
                SaveTextData("hounded", str, true)
            elseif checknumber(_wave_override_chance) and _wave_override_chance > 0 then
                local str = string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.worm_boss_chance), TimeToString(ThePlayer.HUD.WarningEventTimeData.hounded_time), _wave_override_chance * 100)
                SaveTextData("hounded", str, true)
            end
        end
    end)
end

----------------------------------------------------------------------------------------------

local info
info = {
    localgettimefn = localgettimefn,
    remotegettimefn = function(Thread)
        local cmd = [[
            if TheWorld.components.hounded then
                local data = TheWorld.components.hounded:OnSave()
                local time = data and data.timetoattack
                return DataDumper({ time = time })
            end
            return DataDumper({ not_found = true })
        ]]
        BBGOAT_util:remote(cmd, nil, function(res)
            if res and res.err then
                SaveTimeData("hounded", 0)
                print('[警告] hounded remotegettimefn error:', res.err)
                if Thread then KillThreadsWithID(Thread.id) end
            elseif res and res.time then
                SaveTimeData("hounded", res.time)
            elseif res and res.not_found then
                -- 取消数据更新任务
                if Thread then KillThreadsWithID(Thread.id) end
            end
        end)
    end,
    remotegettextfn = remotegettextfn,
    remotegettextfninterval = function()
        return ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData and (ThePlayer.HUD.WarningEventTimeData.hounded_time + 5)
    end,
    DisableSaveTime = true, -- 不同世界都有这个事件，保存了会数据冲突
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
    announcefn = function()
        local time = ThePlayer.HUD.WarningEventTimeData.hounded_time
        local text = ThePlayer.HUD.WarningEventTimeData.hounded_text
        local is_worm_boss = text ~= "" and Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss))
        return (is_worm_boss and text) or (time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns[GetWorldtypeStr()]), TimeToString(time)))
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
local modimport = modimport
local TimeToString = TimeToString
local SyncTimer = GetModConfigData("SyncTimer")
local Upvaluehelper = Upvaluehelper
local ReplacePrefabName = ReplacePrefabName
local Extract_by_format = Extract_by_format
local GetWorldtypeStr = GetWorldtypeStr
local AddPrefabPostInit = AddPrefabPostInit
local AddComponentPostInit = AddComponentPostInit

GLOBAL.setfenv(1, GLOBAL)

modimport("main/timerprefab")

local CalcTimeOfDay -- 今天还剩多少时间
AddComponentPostInit("clock", function(self)
    CalcTimeOfDay = Upvaluehelper.GetUpvalue(self.Dump, "CalcTimeOfDay")
end)

local lunarthrall_plant_table = {} -- 储存致命亮茄数量
-- 对致命亮茄的HOOK（存储世界上亮茄的数量）
AddPrefabPostInit("lunarthrall_plant", function(inst)
    if not TheWorld.ismastersim then
        return
    end

    table.insert(lunarthrall_plant_table, inst)
	inst:ListenForEvent("onremove", function(inst)
		local index = table.reverselookup(lunarthrall_plant_table, inst)
		if index then
			table.remove(lunarthrall_plant_table, index)
		end
	end)
end)

-- 对果蝇王的HOOK（方便Tips）
local lordfruitfly_spawned
AddPrefabPostInit("lordfruitfly", function(inst)
    lordfruitfly_spawned = true
    inst:ListenForEvent("onremove", function(inst)
        lordfruitfly_spawned = false
    end)
end)

-- 判断某个模组是否加载
local function Ismodloaded(name)
	return KnownModIndex:IsModEnabledAny(name)
end

-- 从worldsettingstimer或TimerPrefabs获取倒计时
local function GetWorldSettingsTimeLeft(name, prefab)
    return function()
        local ent = TheWorld
        if prefab then
            ent =  TimerPrefabs[prefab]
        end
        if ent and ent.components.worldsettingstimer then
            return (not ent.components.worldsettingstimer:IsPaused(name)) and ent.components.worldsettingstimer:GetTimeLeft(name)
        end
    end
end

-- 合并字符串
local function CombineLines(...)
    local lines, argnum = nil, select("#",...)

    for i = 1, argnum do
        local v = select(i, ...)

        if v ~= nil then
            lines = lines or {}
            lines[#lines+1] = tostring(v)
        end
    end

    return (lines and table.concat(lines, "\n")) or nil
end

-- 火山爆发倒计时
local function VolcanoEruption()
    if not TheWorld.components.volcanomanager then
        return
    end

    local ActualTime = (TUNING.TOTAL_DAY_TIME * (TheWorld.state.time * 100)) / 100
    local ActualSeg = math.floor(ActualTime / 30)
    local TimeInSeg = ActualTime - (ActualSeg * 30)
    local SegUntilEruption = TheWorld.components.volcanomanager:GetNumSegmentsUntilEruption() or 0
    local SecondUntilEruption = math.floor((SegUntilEruption * 30) - TimeInSeg)

    return SecondUntilEruption > 0 and SecondUntilEruption or 0
end

-- 蜂王
local stagetimne = TUNING.BEEQUEEN_RESPAWN_TIME / 3
local function BeequeenhiveGrown()
    local beequeenhive = TimerPrefabs["beequeenhive"]
    if not beequeenhive or not beequeenhive:IsValid() then
        return
    end

    local timer = beequeenhive.components.timer
    if not timer then
        return
    end

    if timer:GetTimeLeft("hivegrowth1") then
        return 2 * stagetimne + timer:GetTimeLeft("hivegrowth1")
    elseif TimerPrefabs["beequeenhive"].components.timer:GetTimeLeft("hivegrowth2") then
        return stagetimne + timer:GetTimeLeft("hivegrowth2")
    else
        return timer:GetTimeLeft("hivegrowth")
    end
end

-- 远古遗迹当前阶段
local function NightmareWild()
    local nightmareclock = TheWorld.net.components.nightmareclock
    if not nightmareclock then
        return
    end

    local data = nightmareclock:OnSave()
    local locked = data.lockedphase
    local remainingtimeinphase = data.remainingtimeinphase

    if locked then return end

    return remainingtimeinphase
end

-- 云霄国度 大灾变倒计时
local Next_Aporkalypse_Time
AddPrefabPostInit("world", function(inst)
    if inst:HasTag("porkland") then
        inst:ListenForEvent("aporkalypseclocktick", function(src, data)
            Next_Aporkalypse_Time = data and data.timeuntilaporkalypse
        end)
    end
end)

local STATES = {
    none = "idle_1", -- 默认
    calm = "idle_1", -- 平静
    warn = "idle_2", -- 警告
    wild = "idle_3", -- 暴动
    dawn = "idle_2", -- 黎明
}
local changeanim = nil
local function NightmareWildAnimChange(self)
    if TheWorld.ismastersim then
        return
    end

    if not changeanim then
        changeanim = TheWorld:DoPeriodicTask(1, function()
            if ThePlayer and ThePlayer.HUD.NightmareWild then
                self.anim.animation = STATES[TheWorld.state.nightmarephase]
                ThePlayer.HUD.NightmareWild:SetEventAnim(self.anim)
            end
        end)
    end
end

-- 根据冬季盛宴活动决定anim
local function ChangeanimByWintersFeast(self)
    if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
        self.anim = self.winterfeastanim
    else
        self.anim = self.defaultanim
    end
end

-- 根据世界类型决定image
local function ChangeimageByWorld(self)
    if TheWorld:HasTag("porkland") then
        self.image = self.porklandimage
    elseif TheWorld:HasTag("island") or TheWorld:HasTag("volcano") then
        self.image = self.islandimage
    elseif TheWorld:HasTag("cave") then
        self.image = self.caveimage
    else
        self.image = self.forestimage
    end
end

-- 根据世界类型决定anim
local function ChangeanimByWorld(self)
    if TheWorld:HasTag("porkland") then
        self.anim = self.porklandanim
    elseif TheWorld:HasTag("island") or TheWorld:HasTag("volcano") then
        self.anim = self.islandanim
    elseif TheWorld:HasTag("cave") then
        self.anim = self.caveanim
    else
        self.anim = self.forestanim
    end
end

-- 将字符串打包为一个返回该字符串的函数
local function StringToFunction(str)
    return function()
        return str
    end
end

-- 如果event_time > 0，在刚进入游戏的1~10秒内返回true
local function JustEntered(event_time)
    if type(event_time) ~= "number" then return end
    return GetTime() > 1 and GetTime() < 10 and event_time > 0
end

-- 当time在0~2秒时返回true
local function ready_attack(time)
    if type(time) ~= "number" then return end
    if time < 2 and time > 0 then
        return true
    end
    return false
end

WarningEvents = {

    ---------------------------------------- Forest ---------------------------------------

    hounded = {
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

            local next_wave_is_wormboss = Upvaluehelper.FindUpvalue(self.DoWarningSpeech, "_wave_pre_upgraded")
            local _wave_override_chance = self:OnSave().wave_override_chance

            if next_wave_is_wormboss then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss), TimeToString(time))
            elseif type(_wave_override_chance) == "number" then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.worm_boss_chance), TimeToString(time), _wave_override_chance * 100)
            end
        end,
        imagechangefn = function(self)
            local text = ThePlayer.HUD.WarningEventTimeData.hounded_text
            local is_worm_boss = text and Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss))
            if TheWorld:HasTag("porkland") then
                self.image = self.porklandimage
            elseif TheWorld:HasTag("island") or TheWorld:HasTag("volcano") then
                self.image = self.islandimage
            elseif is_worm_boss then
                self.image = self.wormbossimage
            elseif TheWorld:HasTag("cave") then
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
        animchangefn = ChangeanimByWorld,
        forestanim = {
            scale = 0.099,
            bank = "hound",
            build = "hound_ocean",
            animation = "idle",
            loop = true,
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
        },
        caveanim = {
            scale = 0.066,
            bank = "worm",
            build = "worm",
            animation = "atk",
            loop = true,
        },
        DisableShardRPC = true,
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.hounded_time
            local text = ThePlayer.HUD.WarningEventTimeData.hounded_text
            return text ~= "" and text or time and string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns[GetWorldtypeStr()]), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.hounded_time
            local text = ThePlayer.HUD.WarningEventTimeData.hounded_text
            local is_worm_boss = text ~= "" and Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns.worm_boss))

            if time > 2 and time <= 90 then
                return true, WarningEvents.hounded.announcefn, time
            elseif time == 120 or JustEntered(time) then
                return true, WarningEvents.hounded.announcefn, 10
            elseif ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.hounded.attack[is_worm_boss and "worm_boss" or GetWorldtypeStr()])), 10, time
            end
            return false
        end
    },
    deerclopsspawner = {
        gettimefn = GetWorldSettingsTimeLeft("deerclops_timetoattack"),
        gettextfn = function(time)
            local self = TheWorld.components.deerclopsspawner
            if not self then return end
            local description
            local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
            if time and target and target.name then
                description = string.format(STRINGS.eventtimer.deerclopsspawner.targeted, target.name, TimeToString(time))
            elseif time then
                description = string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.cooldown), TimeToString(time))
            end

            return description
        end,
        animchangefn = ChangeanimByWintersFeast,
        defaultanim = {
            scale = 0.044,
            bank = "deerclops",
            build = "deerclops_build",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = 0,
                y = -6,
            },
        },
        winterfeastanim = {
            scale = 0.046,
            bank = "deerclops",
            build = "deerclops_yule",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = -2,
                y = -8,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.deerclopsspawner_time
            local text = ThePlayer.HUD.WarningEventTimeData.deerclopsspawner_text
            local target, _ = Extract_by_format(text, STRINGS.eventtimer.deerclopsspawner.targeted)
            if target and time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.target), target, TimeToString(time))
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.deerclopsspawner_time
            if time > 2 and time <= 60 then
                return true, WarningEvents.deerclopsspawner.announcefn, time
            elseif time == 120 or JustEntered(time) then
                return true, WarningEvents.deerclopsspawner.announcefn, 10
            elseif ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.attack)), 10, time
            end
            return false
        end
    },
    deerherdspawner = {
        gettimefn = function()
            if TheWorld.components.deerherdspawner then
                local data = TheWorld.components.deerherdspawner:OnSave()
                return data and data._timetospawn
            end
        end,
        anim = {
            scale = 0.088,
            bank = "deer",
            build = "deer_build",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = -6,
                y = -6,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.deerherdspawner_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.deerherdspawner.cooldown), TimeToString(time))
        end
    },
    klaussackspawner = {
        gettimefn = GetWorldSettingsTimeLeft("klaussack_spawntimer"),
        gettextfn = function(time)
            local function sack_can_despawn(inst)
                if not IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) and
                    inst.components.entitytracker:GetEntity("klaus") == nil and
                    inst.components.entitytracker:GetEntity("key") == nil then
                    return true
                end
                return false
            end

            local self = TheWorld.components.klaussackspawner
            if not self then return end
            local sack = Upvaluehelper.FindUpvalue(self.GetDebugString, "_sack")
            if sack and sack:IsValid() and sack.despawnday and sack_can_despawn(sack) then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.despawntext), sack.despawnday)
            else
                return time and string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.cooldowntext), TimeToString(time))
            end
        end,
        anim = {
            scale = 0.1,
            bank = "klaus_bag",
            build = "klaus_bag",
            animation = "idle",
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.klaussackspawner_time
            local text = ThePlayer.HUD.WarningEventTimeData.klaussackspawner_text
            local despawnday = Extract_by_format(text, STRINGS.eventtimer.klaussackspawner.despawntext)
            if despawnday then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.despawn), despawnday)
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.klaussackspawner_time
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.tips)), 10, time
            end
            return false
        end
    },
    sinkholespawner = {
        gettimefn = GetWorldSettingsTimeLeft("rage", "antlion"),
        anim = {
            scale = 0.05,
            bank = "antlion",
            build = "antlion_build",
            animation = "idle",
            loop = true,
            uioffset = {
                x = 0,
                y = -5,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.sinkholespawner_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.cooldown), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.sinkholespawner_time
            if time > 2 and time <= 60 then
                return true, WarningEvents.sinkholespawner.announcefn, math.min(20, time)
            elseif ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.attack)), 10, time
            end
            return false
        end
    },
    beargerspawner = {
        gettimefn = GetWorldSettingsTimeLeft("bearger_timetospawn"),
        gettextfn = function(time)
            local self = TheWorld.components.beargerspawner
            if not self then return end
            local description
            local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
            if time and target and target.name then
                description = string.format(STRINGS.eventtimer.beargerspawner.targeted, target.name, TimeToString(time))
            elseif time then
                description = string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.cooldown), TimeToString(time))
            end

            return description
        end,
        animchangefn = ChangeanimByWintersFeast,
        defaultanim = {
            scale = 0.035,
            bank = "bearger",
            build = "bearger_build",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = 0,
                y = -8,
            },
        },

        winterfeastanim = {
            scale = 0.035,
            bank = "bearger",
            build = "bearger_yule",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = 0,
                y = -8,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.beargerspawner_time
            local text = ThePlayer.HUD.WarningEventTimeData.beargerspawner_text
            local target, _ = Extract_by_format(text, STRINGS.eventtimer.beargerspawner.targeted)
            if target and time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.target), target, TimeToString(time))
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.beargerspawner_time
            if time > 2 and time <= 60 then
                return true, WarningEvents.beargerspawner.announcefn, time
            elseif time == 120 or JustEntered(time) then
                return true, WarningEvents.beargerspawner.announcefn, 10
            elseif ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.attack)), 10, time
            end
            return false
        end,
    },
    dragonfly_spawner = {
        gettimefn = GetWorldSettingsTimeLeft("regen_dragonfly", "dragonfly_spawner"),
        animchangefn = ChangeanimByWintersFeast,
        defaultanim = {
            scale = 0.044,
            bank = "dragonfly",
            build = "dragonfly_build",
            animation = "idle",
            loop = true,
            uioffset = {
                x = 0,
                y = -4,
            },
        },

        winterfeastanim = {
            scale = 0.044,
            bank = "dragonfly",
            build = "dragonfly_yule_build",
            animation = "idle",
            loop = true,
            uioffset = {
                x = 0,
                y = -4,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.dragonfly_spawner_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.dragonfly_spawner.cooldown), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.dragonfly_spawner_time
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.dragonfly_spawner.tips)), 10, time
            end
            return false
        end,
    },
    beequeenhive = {
        gettimefn = BeequeenhiveGrown,
        anim = {
            scale = 0.055,
            bank = "bee_queen",
            build = "bee_queen_build",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = 0,
                y = -10,
            },
        },
        DisableShardRPC = true,
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.beequeenhive_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.beequeenhive.cooldown), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.beequeenhive_time
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.beequeenhive.tips)), 10, time
            end
            return false
        end,
    },
    terrarium = {
        gettimefn = GetWorldSettingsTimeLeft("cooldown", "terrarium"),
        anim = {
            scale = 0.2,
            bank = "terrarium",
            build = "terrarium",
            animation = "idle",
            uioffset = {
                x = 0,
                y = -4,
            },
        },
        DisableShardRPC = true,
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.terrarium_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.terrarium.cooldown), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.terrarium_time
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.terrarium.tips)), 10, time
            end
            return false
        end,
    },
    malbatrossspawner = {
        gettimefn = GetWorldSettingsTimeLeft("malbatross_timetospawn"),
        anim = {
            scale = 0.035,
            bank = "malbatross",
            build = "malbatross_build",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = 5,
                y = -10,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.malbatrossspawner_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.malbatrossspawner.cooldown), TimeToString(time))
        end
    },
    crabkingspawner = {
        gettimefn = GetWorldSettingsTimeLeft("regen_crabking", "crabking_spawner"),
        anim = {
            scale = 0.022,
            bank = "king_crab",
            build = "crab_king_build",
            animation = "inert",
            loop = true,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.crabkingspawner_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.crabkingspawner.cooldown), TimeToString(time))
        end
    },
    moon = {
        gettextfn = function()
            if TheWorld:HasTag("cave") or TheWorld:HasTag("volcano") then return end
            local self = TheWorld.net.components.clock
            if not self then return end
            local MOON_PHASE_CYCLES = Upvaluehelper.FindUpvalue(self.OnUpdate, "MOON_PHASE_CYCLES", nil, nil, nil, "scripts/components/clock.lua", nil)
            local _mooniswaxing = Upvaluehelper.FindUpvalue(self.OnUpdate, "_mooniswaxing", nil, nil, nil, "scripts/components/clock.lua", nil)
            local _mooomphasecycle = Upvaluehelper.FindUpvalue(self.OnUpdate, "_mooomphasecycle", nil, nil, nil, "scripts/components/clock.lua", nil)
            if not (MOON_PHASE_CYCLES and _mooniswaxing and _mooomphasecycle) then
                return
            end
            if _mooniswaxing:value() then -- 月黑 → 月圆
                return string.format(STRINGS.eventtimer.moon.moon_full, math.floor(#MOON_PHASE_CYCLES / 2 + 1 - _mooomphasecycle))
            else -- 月圆 → 月黑
                return string.format(STRINGS.eventtimer.moon.moon_new, math.floor(#MOON_PHASE_CYCLES + 1 - _mooomphasecycle))
            end
        end,
        imagechangefn = function(self)
            local text = ThePlayer.HUD.WarningEventTimeData.moon_text
            if not text then return end
            if string.find(text, STRINGS.eventtimer.moon.str_full) then
                self.image = self.fullimage
            else
                self.image = self.newimage
            end
        end,
        fullimage = {
            scale = 1,
            atlas = "images/moon_full.xml",
            tex = "moon_full.tex",
        },
        newimage = {
            scale = 1,
            atlas = "images/moon_new.xml",
            tex = "moon_new.tex",
        },
        DisableShardRPC = true,
        announcefn = function()
            local text = ThePlayer.HUD.WarningEventTimeData.moon_text
            if not text then return end
            if string.find(text, STRINGS.eventtimer.moon.str_full) then
                local day = Extract_by_format(text, STRINGS.eventtimer.moon.moon_full)
                if tonumber(day) == 10 then
                    return STRINGS.eventtimer.moon.moon_new_ready .. text
                end
                return text
            else
                local day = Extract_by_format(text, STRINGS.eventtimer.moon.moon_new)
                if tonumber(day) == 10 then
                    return STRINGS.eventtimer.moon.moon_full_ready .. text
                end
                return text
            end
        end,
        tipsfn = function()
            local text = ThePlayer.HUD.WarningEventTimeData.moon_text
            if not text then return end
            if string.find(text, STRINGS.eventtimer.moon.str_full) then
                local day = Extract_by_format(text, STRINGS.eventtimer.moon.moon_full)
                if tonumber(day) == 10 then
                    return true, StringToFunction(STRINGS.eventtimer.moon.moon_new_ready), 10
                end
            else
                local day = Extract_by_format(text, STRINGS.eventtimer.moon.moon_new)
                if tonumber(day) == 10 then
                    return true, StringToFunction(STRINGS.eventtimer.moon.moon_full_ready), 10
                end
            end
            return false
        end
    },
    farming_manager = { -- 果蝇王
        gettimefn = GetWorldSettingsTimeLeft("lordfruitfly_spawntime"),
        gettextfn = function(time)
            if lordfruitfly_spawned then
                return ReplacePrefabName(STRINGS.eventtimer.farming_manager.ready)
            end
        end,
        anim = {
            scale = 0.2,
            build = "fruitfly_evil",
            bank = "fruitfly",
            animation = "idle",
            offset = {
                x = 0,
                y = -20
            },
            uioffset = {
                x = -2,
                y = -22
            },
            loop = true,
        },
        DisableShardRPC = true,
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.farming_manager_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.farming_manager.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local text = ThePlayer.HUD.WarningEventTimeData.farming_manager_text
            local ready = text == ReplacePrefabName(STRINGS.eventtimer.farming_manager.ready)
            if ready then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.farming_manager.tips)), 5
            end
            return false
        end
    },
    piratespawner = nil, -- 海盗袭击，无法准确预判？不做
    forestdaywalkerspawner = { -- 拾荒疯猪
        gettimefn = function()
            local self = TheWorld.components.forestdaywalkerspawner
            if not self then return end
            local shard_daywalkerspawner = TheWorld.shard.components.shard_daywalkerspawner
            if shard_daywalkerspawner ~= nil and shard_daywalkerspawner:GetLocationName() ~= "forestjunkpile" or self.daywalker ~= nil or self.bigjunk ~= nil or not self.days_to_spawn or not CalcTimeOfDay then
                return
            end
            return (self.days_to_spawn + 1) * TUNING.TOTAL_DAY_TIME - CalcTimeOfDay()
        end,
        anim = {
            scale = 0.05,
            build = "daywalker_build",
            bank = "daywalker",
            animation = "idle_creepy_loop",
            overridebuild = { "daywalker_phase3" },
            uioffset = {
                x = -2,
                y = -7
            },
            loop = true,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.forestdaywalkerspawner_time
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.forestdaywalkerspawner.tips)), 10, time
            end
            return false
        end
    },
    lunarthrall_plantspawner = { -- 致命亮茄信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616
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
            if text then
                text = string.gsub(text,"\n",", ")
                return STRINGS.NAMES.LUNARTHRALL_PLANT .. ": " .. text
            end
        end,
    },
    riftspawner = { -- 裂隙生成倒计时
        gettimefn = function() -- 当裂隙出现时，不显示
            if TheWorld and TheWorld:HasTag("forest") and TheWorld.net.components.warningtimer.inst.replica.warningtimer.rift_portal_text:value() ~= "" then
                return
            elseif TheWorld and TheWorld:HasTag("cave") and TheWorld.net.components.warningtimer.inst.replica.warningtimer.shadowrift_portal_text:value() ~= "" then
                return
            end
            return GetWorldSettingsTimeLeft("rift_spawn_timer")()
        end,
        image = {
            atlas = "images/Rift_Split.xml",
            tex = "Rift_Split.tex",
            scale = 0.8,
            offset = {
                x = 0,
                y = 13,
            },
        },
        DisableShardRPC = true,
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.riftspawner_time
            return time and time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.riftspawner.cooldown), TimeToString(time))
        end,
    },
    rift_portal = { -- 月亮裂隙信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616 (爱死你了)
        gettextfn = function()
            local STAGE_GROWTH_TIMER = "trynextstage"
            local inst = TimerPrefabs["lunarrift_portal"]
            if not inst then return end

            -- 裂隙阶段信息
            local stage_info = string.format(STRINGS.eventtimer.riftspawner.stage, inst._stage, TUNING.RIFT_LUNAR1_MAXSTAGE) -- 阶段信息，内容类似：阶段 1 / 3
            if inst.components.timer:TimerExists(STAGE_GROWTH_TIMER) and not (inst._stage == TUNING.RIFT_LUNAR1_MAXSTAGE) then
                stage_info = stage_info .. ": " .. string.format(STRINGS.eventtimer.rift_portal.next_stage, TimeToString(inst.components.timer:GetTimeLeft(STAGE_GROWTH_TIMER))) -- 补充信息：%s后进入下一阶段
            end

            -- 裂隙晶体信息
            local crystal_count_info -- 可用晶体的信息。内容类似：裂隙晶体：1可用 / 4总共 / 4最大
            local crystal_spawn_info -- 下一波晶体生成时间。内容类似：下一波裂隙晶体生成于0时3分3秒后

            local MAX_CRYSTAL_RING_COUNT_BY_STAGE = Upvaluehelper.FindUpvalue(_G.Prefabs.lunarrift_portal.fn, "MAX_CRYSTAL_RING_COUNT_BY_STAGE") -- {0, 1, 3}
            local CRYSTALS_PER_RING = Upvaluehelper.FindUpvalue(_G.Prefabs.lunarrift_portal.fn, "CRYSTALS_PER_RING") -- 4
            local MIN_CRYSTAL_DISTANCE = Upvaluehelper.FindUpvalue(_G.Prefabs.lunarrift_portal.fn, "MIN_CRYSTAL_DISTANCE") -- 3
            local TERRAFORM_DELAY = Upvaluehelper.FindUpvalue(_G.Prefabs.lunarrift_portal.fn, "TERRAFORM_DELAY")
            local MAX_CRYSTAL_DISTANCE_BY_STAGE = Upvaluehelper.FindUpvalue(_G.Prefabs.lunarrift_portal.fn, "MAX_CRYSTAL_DISTANCE_BY_STAGE") -- TUNING.RIFT_LUNAR1_STAGEUP_BASE_TIME / 3

            local max_crystals = MAX_CRYSTAL_RING_COUNT_BY_STAGE[inst._stage] * CRYSTALS_PER_RING -- 最大晶体数量
            local current_crystals = 0 -- 当前晶体数量
            local available_crystals = 0 -- 可用晶体数量
            local quickest_time_to_available_crystal -- 下波晶体生成时间

            for crystal in pairs(inst._crystals) do
                current_crystals = current_crystals + 1
                if not crystal:IsInLimbo() then
                    available_crystals = available_crystals + 1
                else
                    if crystal.components.timer:TimerExists("finish_spawnin") then
                        local time = crystal.components.timer:GetTimeLeft("finish_spawnin")
                        if quickest_time_to_available_crystal == nil or time < quickest_time_to_available_crystal then
                            quickest_time_to_available_crystal = time
                        end
                    end
                end
            end

            -- 显示可用晶体的数量
            if available_crystals > 0 then
                crystal_count_info = string.format(ReplacePrefabName(STRINGS.eventtimer.rift_portal.crystals), available_crystals, current_crystals, max_crystals)
            end

            -- 显示晶体再生时间
            local crystals_can_spawn = (max_crystals - current_crystals) >= CRYSTALS_PER_RING

            if (crystals_can_spawn or available_crystals < current_crystals) then
                local time

                if quickest_time_to_available_crystal  then
                    time = quickest_time_to_available_crystal
                elseif crystals_can_spawn then
                    -- 我们将展示一个近似的时间，因为它有一些随机性，但数量微不足道。
                    if inst.components.timer:TimerExists("try_crystals") then
                        -- math复制自lunarrift_portal，并进行了一些调整。
                        local offset = MIN_CRYSTAL_DISTANCE + math.sqrt(1)*(MAX_CRYSTAL_DISTANCE_BY_STAGE[inst._stage] - MIN_CRYSTAL_DISTANCE)
                        local previous_max_crystal_distance = MAX_CRYSTAL_DISTANCE_BY_STAGE[inst._stage - 1] or 0
                        local time_delay = math.max(0, ((offset - previous_max_crystal_distance) / TILE_SCALE) * TERRAFORM_DELAY)

                        time = inst.components.timer:GetTimeLeft("try_crystals") + (time_delay + (2*1))
                    end
                end

                if time then
                    crystal_spawn_info = string.format(ReplacePrefabName(STRINGS.eventtimer.rift_portal.next_crystal), TimeToString(time))
                end
            end

            -- 合并信息
            local description = CombineLines(stage_info, crystal_count_info, crystal_spawn_info)
            return description
        end,
        image = {
            atlas = "minimap/minimap_data.xml",
			tex = "lunarrift_portal.png",
            scale = 0.8,
        },
        announcefn = function()
            local text = ThePlayer.HUD.WarningEventTimeData.rift_portal_text
            if text then
                text = string.gsub(text,"\n",", ")
                return STRINGS.eventtimer.rift_portal.name .. ": " .. text
            end
        end,
    },

    ---------------------------------------- Cave ----------------------------------------

    shadowrift_portal = { -- 暗影裂隙信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616
        gettimefn = nil, -- gettimefn有必要吗？也许没必要
        gettextfn = function()
            local inst = TimerPrefabs["shadowrift_portal"]
            if not inst then return end
            local STAGE_GROWTH_TIMER = "trynextstage"
            local RIFT_CLOSE_TIMER = "close"
            local stage_info = string.format(ReplacePrefabName(STRINGS.eventtimer.riftspawner.stage), inst._stage, TUNING.RIFT_SHADOW1_MAXSTAGE)
            local rift_close_time

            if inst.components.timer:TimerExists(RIFT_CLOSE_TIMER) then
                rift_close_time = inst.components.timer:GetTimeLeft(RIFT_CLOSE_TIMER)
            end

            if rift_close_time and inst._stage == TUNING.RIFT_SHADOW1_MAXSTAGE then
                stage_info = stage_info .. ": " .. string.format(ReplacePrefabName(STRINGS.eventtimer.shadowrift_portal.close), TimeToString(rift_close_time))
            elseif inst.components.timer:TimerExists(STAGE_GROWTH_TIMER) then
                stage_info = stage_info .. ": " .. string.format(STRINGS.eventtimer.rift_portal.next_stage, TimeToString(inst.components.timer:GetTimeLeft(STAGE_GROWTH_TIMER)))
            end

            local description = stage_info
            return description
        end,
        image = {
			atlas = "minimap/minimap_data.xml",
			tex = "shadowrift_portal.png",
            scale = 0.8,
        },
        announcefn = function()
            local text = ThePlayer.HUD.WarningEventTimeData.shadowrift_portal_text
            if text then
                text = string.gsub(text,"\n",", ")
                return STRINGS.eventtimer.shadowrift_portal.name .. ": " .. text
            end
        end,
    },
    daywalkerspawner = { -- 梦魇疯猪
        gettimefn = function()
            local self = TheWorld.components.daywalkerspawner
            if not self then return end
            local shard_daywalkerspawner = TheWorld.shard.components.shard_daywalkerspawner
            if shard_daywalkerspawner ~= nil and shard_daywalkerspawner:GetLocationName() ~= "cavejail" or self.daywalker ~= nil or not self.days_to_spawn or not CalcTimeOfDay then
                return
            end
            return (self.days_to_spawn + 1) * TUNING.TOTAL_DAY_TIME - CalcTimeOfDay()
        end,
        anim = {
            scale = 0.05,
            build = "daywalker_build",
            bank = "daywalker",
            animation = "idle_creepy_loop",
            uioffset = {
                x = -2,
                y = -7
            },
            loop = true,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.daywalkerspawner_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.daywalkerspawner_time
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.daywalkerspawner.tips)), 10, time
            end
            return false
        end
    },
    shadowthrallmanager = { -- 梦魇裂隙/墨荒信息，参考了Insight代码 https://steamcommunity.com/sharedfiles/filedetails/?id=2189004162 @penguin0616
        gettextfn = function()
            local self = TheWorld.components.shadowthrallmanager
            if not self then return end
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
            if text then
                text = string.gsub(text,"\n",", ")
                return STRINGS.NAMES.SHADOWTHRALL_MOUTH .. ": " .. text
            end
        end,
    },
    toadstoolspawner = {
        gettimefn = GetWorldSettingsTimeLeft("toadstool_respawntask"),
        anim = {
            scale = 0.03,
            bank = "toadstool",
            build = "toadstool_build",
            animation = "idle",
            loop = true,
            uioffset = {
                x = 0,
                y = -5,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.toadstoolspawner_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.toadstoolspawner.cooldown), TimeToString(time))
        end
    },
    atrium_gate = {
        gettimefn = function()
            if not (TimerPrefabs.atrium_gate and TimerPrefabs.atrium_gate.components.worldsettingstimer) then return end
            return GetWorldSettingsTimeLeft("cooldown", "atrium_gate")() or GetWorldSettingsTimeLeft("destabilizing", "atrium_gate")()
        end,
        gettextfn = function(time)
            if time and time > 0 then
                if GetWorldSettingsTimeLeft("cooldown", "atrium_gate")() then
                    return string.format(ReplacePrefabName(STRINGS.eventtimer.atrium_gate.cooldown), TimeToString(time))
                else
                    return string.format(STRINGS.eventtimer.atrium_gate.destabilizing, TimeToString(time))
                end
            end
        end,
        anim = {
            scale = 0.055,
            bank = "atrium_gate",
            build = "atrium_gate",
            animation = "idle",
            uioffset = {
                x = -2,
                y = -5,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.atrium_gate_time
            local text = ThePlayer.HUD.WarningEventTimeData.atrium_gate_text
            if text and string.find(text, ReplacePrefabName("<prefab=atrium_gate>")) then
                return time and string.format(ReplacePrefabName(STRINGS.eventtimer.atrium_gate.cooldown), TimeToString(time))
            else
                return time and string.format(STRINGS.eventtimer.atrium_gate.destabilizing, TimeToString(time))
            end
        end,
    },
    nightmareclock = {
        gettimefn = NightmareWild, -- 仅返回倒计时
        gettextfn = function(time) -- 仅锁定阶段返回
            local nightmareclock = TheWorld.net.components.nightmareclock
            if not nightmareclock then
                return
            end

            local data = nightmareclock:OnSave()
            return data.lockedphase and STRINGS.eventtimer.nightmareclock.phase_locked_text
        end,
        anim = {
            scale = 0.22,
            bank = "nightmare_watch",
            build = "nightmare_timepiece",
            animation = "idle_1",
            offset = {
                x = 0,
                y = 10,
            },
        },
        animchangefn = NightmareWildAnimChange,
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.nightmareclock_time
            local text = ThePlayer.HUD.WarningEventTimeData.nightmareclock_text
            if text and string.find(text, STRINGS.eventtimer.nightmareclock.phase_locked_text) then
                return STRINGS.eventtimer.nightmareclock.phase_locked
            end
            if TheWorld.state.nightmarephase == "none" then
                return time and string.format(STRINGS.eventtimer.nightmareclock.cooldown_none, TimeToString(time))
            else
                local phase = STRINGS.eventtimer.nightmareclock.phases[TheWorld.state.nightmarephase]
                return time and phase and string.format(STRINGS.eventtimer.nightmareclock.cooldown, phase, TimeToString(time))
            end
        end
    },
    quaker = {
        gettimefn = function()
            local self = TheWorld.net.components.quaker
            if not self then return end
            local _task = Upvaluehelper.GetUpvalue(self.GetDebugString, "_task")
            if _task and GetTaskRemaining(_task) then
                return GetTaskRemaining(_task)
            end
        end,
        image = {
            atlas = "images/inventoryimages.xml",
            tex = "rocks.tex",
            scale = 0.8,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.quaker_time
            if time and time > 0 then
                return string.format(STRINGS.eventtimer.quaker.cooldown, TimeToString(time))
            end
        end,
    },

    ---------------------------------------- IA-SW ---------------------------------------

    chessnavy = {
        gettimefn = function()
            if TheWorld.components.chessnavy then
                return TheWorld.components.chessnavy.spawn_timer
            end
        end,
        gettextfn = function(time)
            if not TheWorld.components.chessnavy then return end
            return time > 0 and string.format(ReplacePrefabName(STRINGS.eventtimer.chessnavy.cooldown), TimeToString(time)) or STRINGS.eventtimer.chessnavy.readytext
        end,
        anim = {
            scale = 0.09,
            bank = "knightboat",
            build = "knightboat_build",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = 7,
                y = -2,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.chessnavy_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.chessnavy.cooldown), TimeToString(time))
            end
            return ReplacePrefabName(STRINGS.eventtimer.chessnavy.ready)
        end
    },
    volcanomanager = {
        gettimefn = VolcanoEruption,
        anim = {
            scale = 0.0077,
            bank = "volcano",
            build = "volcano",
            animation = "active_idle_pst",
            -- loop = "",
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.volcanomanager_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.volcanomanager.cooldown), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.volcanomanager_time
            if time > 2 and time <= 60 then
                return true, WarningEvents.volcanomanager.announcefn, time
            elseif JustEntered(time) and time <= 480 then
                return true, WarningEvents.volcanomanager.announcefn, 10
            elseif time == 120 then
                return true, WarningEvents.volcanomanager.announcefn, 10
            elseif ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.volcanomanager.attack)), 10, time
            end
            return false
        end
    },
    twisterspawner = {
        gettimefn = GetWorldSettingsTimeLeft("twister_timetoattack"),
        gettextfn = function(time)
            local self = TheWorld.components.twisterspawner
            if not self then return end
            local description
            local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
            if time and target and target.name then
                description = string.format(STRINGS.eventtimer.twisterspawner.targeted, target.name, TimeToString(time))
            elseif time then
                description = string.format(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.cooldown), TimeToString(time))
            end

            return description
        end,
        image = {
            atlas = "images/Twister.xml",
            tex = "Twister.tex",
            scale = 0.35,
        },
        anim = {
            scale = 0.022,
            bank = "twister",
            build = "twister_build",
            animation = "idle_loop",
            loop = true
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.twisterspawner_time
            local text = ThePlayer.HUD.WarningEventTimeData.twisterspawner_text
            local target, _ = Extract_by_format(text, STRINGS.eventtimer.twisterspawner.targeted)
            if target and time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.target), target, TimeToString(time))
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.twisterspawner_time
            if time > 2 and time <= 60 then
                return true, WarningEvents.twisterspawner.announcefn, time
            elseif time == 120 or JustEntered(time) then
                return true, WarningEvents.twisterspawner.announcefn, 10
            elseif ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.attack)), 10, time
            end
            return false
        end
    },
    krakener = {
        gettimefn = function()
            if TheWorld.components.krakener then
                return TheWorld.components.krakener:TimeUntilCanSpawn()
            end
        end,
        gettextfn = function(time)
            if not TheWorld.components.krakener then return end
            if time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.krakener.cooldown), TimeToString(time))
            end
            return ReplacePrefabName(STRINGS.eventtimer.krakener.ready)
        end,
        anim = {
            scale = 0.027,
            bank = "quacken",
            build = "quacken",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = 0,
                y = -6,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.krakener_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.krakener.cooldown), TimeToString(time))
            end
            return ReplacePrefabName(STRINGS.eventtimer.krakener.ready)
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.krakener_time
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.krakener.tips)), 10, time
            end
            return false
        end
    },
    tigersharker = {
        gettimefn = function()
            local self = TheWorld.components.tigersharker
            if not self then return end
            local appear_time = self:TimeUntilCanAppear()
            local respawn_time = self:TimeUntilRespawn()
            return math.max(appear_time, respawn_time)
        end,
        gettextfn = function(time)
            local self = TheWorld.components.tigersharker
            if not self then return end
            if self.shark then
                return ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists)
            elseif self:CanSpawn(true, true) then
                if time > 0 then
                    return string.format(ReplacePrefabName(STRINGS.eventtimer.tigersharker.cooldown), TimeToString(time))
                else
                    return STRINGS.eventtimer.tigersharker.readytext
                end
            end
            return ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn)
        end,
        anim = {
            scale = 0.03,
            bank = "tigershark",
            build = "tigershark_ground_build",
            animation = "taunt",
            loop = true,
            uioffset = {
                x = -6,
                y = -6,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.tigersharker_time
            local text = ThePlayer.HUD.WarningEventTimeData.tigersharker_text
            local exists = string.find(text, ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists))
            local nospawn = string.find(text, ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn))
            if exists then
                return ReplacePrefabName(STRINGS.eventtimer.tigersharker.exists)
            elseif nospawn then
                return ReplacePrefabName(STRINGS.eventtimer.tigersharker.nospawn)
            elseif time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.tigersharker.cooldown), TimeToString(time))
            else
                return ReplacePrefabName(STRINGS.eventtimer.tigersharker.ready)
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.tigersharker_time
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.tigersharker.tips)), 10, time
            end
            return false
        end
    },

}

local HamletEvents = rawget(_G, "IA_HAM_ENABLED") and
{   ---------------------------------------- IA-HAM ---------------------------------------
    -- TODO
}
or Ismodloaded("workshop-3322803908") and
{   ---------------------------------------- Above The Clouds ---------------------------------------
    pugalisk_fountain = {
        gettimefn = function()
            local self = TimerPrefabs["pugalisk_fountain"]
            return self and self.resettaskinfo and self:TimeRemainingInTask(self.resettaskinfo)
        end,
        image = {
            atlas = "images/lifeplant.xml",
            tex = "lifeplant.tex",
            scale = 0.8,
        },
        anim = {
            scale = 0.02,
            bank = "fountain",
            build = "python_fountain",
            animation = "flow_loop",
            loop = true,
            uioffset = {
                x = 0,
                y = 0,
            }
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.pugalisk_fountain_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.pugalisk_fountain.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.pugalisk_fountain_time
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.pugalisk_fountain_time.ready)), 5, time
            end
            return false
        end
    },
    banditmanager = {
        gettimefn = GetWorldSettingsTimeLeft("pig_bandit_respawn_time_"),
        gettextfn = function(time)
            local self = TheWorld.components.banditmanager
            if not self then return end
            local str = self:GetDebugString()
            local stolen_oincs, active_bandit = string.match(str, "Stolen Oincs: (%d+) Active Bandit: (%a+) Respawns In")
            if not (stolen_oincs and active_bandit) then return end
            if active_bandit == "true" then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext), stolen_oincs)
            else
                return string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.cooldown), TimeToString(time), stolen_oincs, active_bandit)
            end
        end,
        image = {
			atlas = "images/pig_bandit.xml",
			tex = "pig_bandit.tex",
            scale = 0.07,
        },
        anim = {
            scale = 0.07,
            build = "pig_bandit",
            bank = "townspig",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = 0,
                y = -15,
            }
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.banditmanager_time
            local text = ThePlayer.HUD.WarningEventTimeData.banditmanager_text
            local _time, stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.cooldown))
            if stolen_oincs then
                return time and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.announce_cooldown), TimeToString(time), stolen_oincs)
            else
                stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext))
                return stolen_oincs and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.ready), stolen_oincs)
            end
        end,
        tipsfn = function()
            local text = ThePlayer.HUD.WarningEventTimeData.banditmanager_text
            local ready = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext))
            if ready then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.banditmanager.tips)), 5
            end
            return false
        end
    },
    aporkalypse = { -- 大灾变倒计时
        gettimefn = function()
            return Next_Aporkalypse_Time
        end,
        gettextfn = function(time)
            if time and time > 0 then
                return string.format(STRINGS.eventtimer.aporkalypse.cooldown, TimeToString(time))
            end
        end,
        image = {
			atlas = "images/Aporkalypse_Clock.xml",
			tex = "Aporkalypse_Clock.tex",
            scale = 0.2
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.aporkalypse_time
            if time and time > 0 then
                return string.format(STRINGS.eventtimer.aporkalypse.cooldown, TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.aporkalypse_time
            if time == 120 or JustEntered(time) then
                local function res_time()
                    return string.format(STRINGS.eventtimer.aporkalypse.tips, TimeToString(ThePlayer.HUD.WarningEventTimeData.aporkalypse_time))
                end
                return true, res_time, 10
            elseif ready_attack(time) then
                return true, StringToFunction(STRINGS.eventtimer.aporkalypse.tips_ready), 5, time + 1
            end
            return false
        end
    },
    aporkalypse_attack = { -- 大灾变中的事件倒计时（蝙蝠袭击、远古先驱袭击）
        gettimefn = function()
            if Next_Aporkalypse_Time and Next_Aporkalypse_Time == 0 then
                local self = TheWorld.net.components.aporkalypse
                if not self then return end
                local next_herald_attack = Upvaluehelper.GetUpvalue(self.OnUpdate, "_herald_time") -- 远古先驱袭击倒计时
                return next_herald_attack
            end
        end,
        gettextfn = function(next_herald_attack)
            local self = TheWorld.net.components.aporkalypse
            if not self then return end
            local next_bat_attack = Upvaluehelper.GetUpvalue(self.OnUpdate, "_bat_time") -- 蝙蝠袭击倒计时
            if not (next_bat_attack and next_herald_attack) then return end
            return string.format(ReplacePrefabName(STRINGS.eventtimer.aporkalypse.attack), TimeToString(next_bat_attack), TimeToString(next_herald_attack))
        end,
        image = {
			atlas = "images/Ancient_Herald.xml",
			tex = "Ancient_Herald.tex",
            scale = 0.2,
            offset = {
                x = 0,
                y = 7,
            }
        },
        announcefn = function()
            local text = ThePlayer.HUD.WarningEventTimeData.aporkalypse_attack_text
            local next_bat_attack, next_herald_attack = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.aporkalypse.attack))
            if not (next_bat_attack and next_herald_attack) then return end
            return string.format(ReplacePrefabName(STRINGS.eventtimer.aporkalypse.announce_attack), next_bat_attack, next_herald_attack)
        end,
        tipsfn = nil, -- 几分钟就来一次，一直Tips不嫌烦么？
    },
    batted = {
        gettimefn = function()
            if Next_Aporkalypse_Time and Next_Aporkalypse_Time > 0 then
                local self = TheWorld.components.batted
                if not self then return end
                local next_attack_in = Upvaluehelper.GetUpvalue(self.LongUpdate, "_bat_attack_time")
                return next_attack_in
            else
                local self = TheWorld.net.components.aporkalypse
                if not self then return end
                local time = Upvaluehelper.GetUpvalue(self.OnUpdate, "_bat_time")
                return time
            end
        end,
        gettextfn = function(next_attack_in)
            if Next_Aporkalypse_Time and Next_Aporkalypse_Time > 0 then
                local self = TheWorld.components.batted
                if not self then return end
                local bat_count = self:GetNumBats()
                local regen_in = Upvaluehelper.GetUpvalue(self.LongUpdate, "_bat_regen_time")
                if not (bat_count and regen_in and next_attack_in) then return end
                return string.format(STRINGS.eventtimer.batted.cooldowntext, TimeToString(next_attack_in), bat_count, TimeToString(regen_in))
            end
        end,
        anim = {
            scale = 0.08,
            build = "bat_vamp_build",
            bank = "bat_vamp",
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
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.batted_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.batted.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.batted_time
            if time == 120 or JustEntered(time) then
                return true, WarningEvents.batted.announcefn, 10
            elseif ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.batted.attack)), 10, time
            end
            return false
        end
    },
    rocmanager = {
        gettimefn = GetWorldSettingsTimeLeft("ROC_RESPAWN_TIMER"),
        gettextfn = function(time)
            local self = TheWorld.components.rocmanager
            if not self then return end
            local data = self:OnSave()
            if data.roc then
                return  ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists)
            end
            if time and time > 0 then
                return TimeToString(time)
            end
        end,
        image = {
			atlas = "images/Roc.xml",
			tex = "Roc.tex",
		},
        anim = {
            scale = 0.008,
            build = "roc_head_build",
            bank = "head",
            animation = "idle_loop",
            loop = true,
            offset = {
                x = 0,
                y = -15,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.rocmanager_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.rocmanager.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.rocmanager_time
            local text = ThePlayer.HUD.WarningEventTimeData.rocmanager_text
            if time > 2 and time <= 90 then
                return true, WarningEvents.rocmanager.announcefn, time
            elseif time == 120 or JustEntered(time) then
                return true, WarningEvents.rocmanager.announcefn, 10
            elseif text == ReplacePrefabName(STRINGS.eventtimer.rocmanager.exists) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.rocmanager.tips)), 10
            end
            return false
        end
    }
} or {}

-- 将猪镇计时添加到WarningEvents
for k, v in pairs(HamletEvents) do
    WarningEvents[k] = v
end

local UncompromisingEvents = Ismodloaded("workshop-2039181790") and
{
    gmoosespawner = {
        gettimefn = GetWorldSettingsTimeLeft("mothergoose_timetoattack"),
        gettextfn = function(time)
            local self = TheWorld.components.gmoosespawner
            if not self then return end
            local description
            local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
            if time and target and target.name then
                description = string.format(STRINGS.eventtimer.gmoosespawner.targeted, target.name, TimeToString(time))
            elseif time then
                description = string.format(ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.cooldown), TimeToString(time))
            end

            return description
        end,
        image = {
			atlas = "images/Moose.xml",
			tex = "Moose.tex",
            scale = 0.2,
            offset = {
                x = 0,
                y = 15,
            }
        },
        anim = {
            scale = 0.044,
            bank = "goosemoose",
            build = "goosemoose_build",
            animation = "idle",
            loop = true,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.gmoosespawner_time
            local text = ThePlayer.HUD.WarningEventTimeData.gmoosespawner_text
            local target, _ = Extract_by_format(text, STRINGS.eventtimer.gmoosespawner.targeted)
            if target and time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.target), target, TimeToString(time))
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.gmoosespawner_time
            if time > 2 and time <= 60 then
                return true, WarningEvents.gmoosespawner.announcefn, time
            elseif time == 120 or JustEntered(time) then
                return true, WarningEvents.gmoosespawner.announcefn, 10
            elseif ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.gmoosespawner.attack)), 10, time
            end
            return false
        end
    },
    mock_dragonflyspawner = {
        gettimefn = GetWorldSettingsTimeLeft("mockfly_timetoattack"),
        gettextfn = function(time)
            local self = TheWorld.components.mock_dragonflyspawner
            if not self then return end
            local description
            local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
            if time and target and target.name then
                description = string.format(STRINGS.eventtimer.mock_dragonflyspawner.targeted, target.name, TimeToString(time))
            elseif time then
                description = string.format(ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.cooldown), TimeToString(time))
            end

            return description
        end,
        image = {
			atlas = "images/Dragonfly.xml",
			tex = "Dragonfly.tex",
            scale = 0.2,
            offset = {
                x = 0,
                y = 13,
            }
        },
        anim = {
            scale = 0.044,
            bank = "dragonfly",
            build = "dragonfly_build",
            animation = "idle",
            loop = true,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.mock_dragonflyspawner_time
            local text = ThePlayer.HUD.WarningEventTimeData.mock_dragonflyspawner_text
            local target, _ = Extract_by_format(text, STRINGS.eventtimer.mock_dragonflyspawner.targeted)
            if target and time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.target), target, TimeToString(time))
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WarningEventTimeData.mock_dragonflyspawner_time
            if time > 2 and time <= 60 then
                return true, WarningEvents.mock_dragonflyspawner.announcefn, time
            elseif time == 120 or JustEntered(time) then
                return true, WarningEvents.mock_dragonflyspawner.announcefn, 10
            elseif ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.mock_dragonflyspawner.attack)), 10, time
            end
            return false
        end
    },
    -- 巨鹿和原版的一样，不需要加
} or {}

-- 将永不妥协计时添加到WarningEvents
for k, v in pairs(UncompromisingEvents) do
    WarningEvents[k] = v
end

for event in pairs(WarningEvents) do
    WarningEvents[event].name = event -- 给 WarningEventUI.lua 使用
end

--跨世界同步计时
for warningevent, data in pairs(WarningEvents) do
    local event_time_shardrpc = warningevent .. "_time_shardrpc"
    local event_text_shardrpc = warningevent .. "_text_shardrpc"

    AddShardModRPCHandler("EventTimer", event_time_shardrpc, function(shardid, timedata, worldtype)
        if not SyncTimer then return end -- 未开启同步功能，取消同步

        local warningtimer = TheWorld.net.components.warningtimer
        if timedata then
            warningtimer.inst.replica.warningtimer[event_time_shardrpc]:set(timedata or 0)

            if timedata > 0 then
                local textdata = TimeToString(timedata) -- 同时设置text，以显示来自哪个世界
                textdata = string.format(STRINGS.eventtimer.worldid, shardid) .. "(" .. worldtype .. ")\n" .. textdata
                warningtimer.inst.replica.warningtimer[event_text_shardrpc]:set(textdata or "")
            end
        end
    end)

    AddShardModRPCHandler("EventTimer", event_text_shardrpc, function(shardid, textdata, worldtype)
        if not SyncTimer then return end -- 未开启同步功能，取消同步

        local warningtimer = TheWorld.net.components.warningtimer
        if textdata then
            textdata = textdata ~= "" and (string.format(STRINGS.eventtimer.worldid, shardid) .. "(" .. worldtype .. ")\n" .. textdata)
            warningtimer.inst.replica.warningtimer[event_text_shardrpc]:set(textdata or "")
        end
    end)
end
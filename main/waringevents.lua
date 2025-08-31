local modimport = modimport
local SyncTimer = GetModConfigData("SyncTimer")
local Upvaluehelper = Upvaluehelper
local ReplacePrefabName = ReplacePrefabName
local Extract_by_format = Extract_by_format
local GetWorldtypeStr = GetWorldtypeStr
local AddPrefabPostInit = AddPrefabPostInit

GLOBAL.setfenv(1, GLOBAL)
local TimerMode = EventTimer.TimerMode
modimport("main/timerprefab")

-- 判断某个模组是否加载
local function Ismodloaded(name)
	return KnownModIndex:IsModEnabledAny(name)
end

-- 格式化时间
local function TimeToString(seconds)
    if type(seconds) ~= "number" then return seconds end
    local daytime = TimerMode == 2 and 3600 or TUNING.TOTAL_DAY_TIME
    local d = math.floor(seconds / daytime)
    local min = math.floor(seconds % daytime / 60)
    local s = math.floor(seconds % daytime % 60)

    if TimerMode == 2 then
        return d .. "时" .. min .. "分" .. s .. "秒"
    else
        return d .. "天" .. min .. "分" .. s .. "秒"
    end
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

    return SecondUntilEruption
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
    local lengths = data.lengths
    local phase = data.phase
    local remainingtimeinphase = data.remainingtimeinphase

        if locked then return end
        if phase == "calm" then
            remainingtimeinphase = remainingtimeinphase + lengths["warn"] * 30
        elseif phase == "wild" then
            remainingtimeinphase = remainingtimeinphase + lengths["dawn"] * 30
        end

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
    none = "idle_1",
    calm = "idle_1",
    warn = "idle_2",
    wild = "idle_3",
    dawn = "idle_2",
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

WaringEvents = {

    ---------------------------------------- Forest ---------------------------------------

    hounded = {
        gettimefn = function()
            if TheWorld.components.hounded then
                local data = TheWorld.components.hounded:OnSave()
                return data and data.timetoattack
            end
        end,
        imagechangefn = ChangeimageByWorld,
        forestimage = {
            atlas = "images/Hound.xml",
		    tex = "Hound.tex",
            scale = 0.4,
        },
        caveimage = {
            atlas = "images/Depths_Worm.xml",
            tex = "Depths_Worm.tex",
            scale = 0.25,
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
            build = "crocodog_poison",
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
            local time = ThePlayer.HUD.WaringEventTimeData.hounded_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.hounded.cooldowns[GetWorldtypeStr()]), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.hounded_time or 0
            if time == 120 or JustEntered(time) then
                return true, WaringEvents.hounded.announcefn, 10
            elseif time > 2 and time <= 60 then
                return true, WaringEvents.hounded.announcefn, time
            elseif ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.hounded.attack[GetWorldtypeStr()])), 10, time
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
            scale = 0.05,
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
            local time = ThePlayer.HUD.WaringEventTimeData.deerclopsspawner_time
            local text = ThePlayer.HUD.WaringEventTimeData.deerclopsspawner_text
            local target, _ = Extract_by_format(text, STRINGS.eventtimer.deerclopsspawner.targeted)
            if target and time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.target), target, TimeToString(time))
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsspawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.deerclopsspawner_time or 0
            if time == 120 or JustEntered(time) then
                return true, WaringEvents.deerclopsspawner.announcefn, 10
            elseif time > 2 and time <= 60 then
                return true, WaringEvents.deerclopsspawner.announcefn, time
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
            local time = ThePlayer.HUD.WaringEventTimeData.deerherdspawner_time
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
            scale = 0.11,
            bank = "klaus_bag",
            build = "klaus_bag",
            animation = "idle",
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.klaussackspawner_time
            local text = ThePlayer.HUD.WaringEventTimeData.klaussackspawner_text
            local despawnday = Extract_by_format(text, STRINGS.eventtimer.klaussackspawner.despawntext)
            if despawnday then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.despawn), despawnday)
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.klaussackspawner_time or 0
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.klaussackspawner.tips)), 10, time
            end
            return false
        end
    },
    sinkholespawner = {
        gettimefn = GetWorldSettingsTimeLeft("rage", "antlion"),
        anim = {
            scale = 0.055,
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
            local time = ThePlayer.HUD.WaringEventTimeData.sinkholespawner_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.cooldown), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.sinkholespawner_time or 0
            if time > 2 and time <= 60 then
                return true, WaringEvents.sinkholespawner.announcefn, math.min(20, time)
            elseif ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.sinkholespawner.attack)), 10, time
            end
            return false
        end
    },
    beargerspawner = {
        gettimefn = GetWorldSettingsTimeLeft("bearger_timetospawn"),
        gettextfn = function(time)
            local self = TheWorld.components.beargerspawn
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
            scale = 0.04,
            bank = "bearger",
            build = "bearger_build",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = 0,
                y = -10,
            },
        },

        winterfeastanim = {
            scale = 0.04,
            bank = "bearger",
            build = "bearger_yule",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = 0,
                y = -10,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.beargerspawner_time
            local text = ThePlayer.HUD.WaringEventTimeData.beargerspawner_text
            local target, _ = Extract_by_format(text, STRINGS.eventtimer.beargerspawner.targeted)
            if target and time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.target), target, TimeToString(time))
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.beargerspawner_time or 0
            if time == 120 or JustEntered(time) then
                return true, WaringEvents.beargerspawner.announcefn, 10
            elseif time > 2 and time <= 60 then
                return true, WaringEvents.beargerspawner.announcefn, time
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
            local time = ThePlayer.HUD.WaringEventTimeData.dragonfly_spawner_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.dragonfly_spawner.cooldown), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.dragonfly_spawner_time or 0
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.dragonfly_spawner.tips)), 10, time
            end
            return false
        end,
    },
    beequeenhive = {
        gettimefn = BeequeenhiveGrown,
        anim = {
            scale = 0.06,
            bank = "bee_queen",
            build = "bee_queen_build",
            animation = "idle_loop",
            loop = true,
            uioffset = {
                x = 0,
                y = -10,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.beequeenhive_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.beequeenhive.cooldown), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.beequeenhive_time or 0
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
            local time = ThePlayer.HUD.WaringEventTimeData.terrarium_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.terrarium.cooldown), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.terrarium_time or 0
            if ready_attack(time) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.terrarium.tips)), 10, time
            end
            return false
        end,
    },
    malbatrossspawner = {
        gettimefn = GetWorldSettingsTimeLeft("malbatross_timetospawn"),
        anim = {
            scale = 0.04,
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
            local time = ThePlayer.HUD.WaringEventTimeData.malbatrossspawner_time
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
            local time = ThePlayer.HUD.WaringEventTimeData.crabkingspawner_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.crabkingspawner.cooldown), TimeToString(time))
        end
    },

    ---------------------------------------- Cave ----------------------------------------

    toadstoolspawner = {
        gettimefn = GetWorldSettingsTimeLeft("toadstool_respawntask"),
        anim = {
            scale = 0.033,
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
            local time = ThePlayer.HUD.WaringEventTimeData.toadstoolspawner_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.toadstoolspawner.cooldown), TimeToString(time))
        end
    },
    atrium_gate = {
        gettimefn = GetWorldSettingsTimeLeft("cooldown", "atrium_gate"),
        anim = {
            scale = 0.06,
            bank = "atrium_gate",
            build = "atrium_gate",
            animation = "idle",
            uioffset = {
                x = 0,
                y = -5,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.atrium_gate_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.atrium_gate.cooldown), TimeToString(time))
        end
    },
    nightmareclock = {
        gettimefn = NightmareWild, -- 仅返回倒计时
        gettextfn = function(time) -- 仅锁定阶段返回
            local nightmareclock = TheWorld.net.components.nightmareclock
            if not nightmareclock then
                return
            end

            local data = nightmareclock:OnSave()
            return data.lockedphase and string.format(STRINGS.eventtimer.nightmareclock.phase_locked_text)
        end,
        anim = {
            scale = 0.25,
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
            local time = ThePlayer.HUD.WaringEventTimeData.nightmareclock_time
            local text = ThePlayer.HUD.WaringEventTimeData.nightmareclock_text
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
            scale = 0.095,
            bank = "knightboat",
            build = "knightboat_build",
            animation = "idle_loop",
            -- loop = "",
            uioffset = {
                x = 7,
                y = -2,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.chessnavy_time
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
            local time = ThePlayer.HUD.WaringEventTimeData.volcanomanager_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.volcanomanager.cooldown), TimeToString(time))
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.volcanomanager_time or 0
            if JustEntered(time) and time <= 480 then
                return true, WaringEvents.volcanomanager.announcefn, 10
            elseif time == 120 then
                return true, WaringEvents.volcanomanager.announcefn, 10
            elseif time > 2 and time <= 60 then
                return true, WaringEvents.volcanomanager.announcefn, time
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
            scale = 0.4,
        },
        anim = {
            scale = 0.022,
            bank = "twister",
            build = "twister_build",
            animation = "idle_loop",
            loop = true
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.twisterspawner_time
            local text = ThePlayer.HUD.WaringEventTimeData.twisterspawner_text
            local target, _ = Extract_by_format(text, STRINGS.eventtimer.twisterspawner.targeted)
            if target and time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.target), target, TimeToString(time))
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.twisterspawner.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.twisterspawner_time or 0
            if time == 120 or JustEntered(time) then
                return true, WaringEvents.twisterspawner.announcefn, 10
            elseif time > 2 and time <= 60 then
                return true, WaringEvents.twisterspawner.announcefn, time
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
            scale = 0.03,
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
            local time = ThePlayer.HUD.WaringEventTimeData.krakener_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.krakener.cooldown), TimeToString(time))
            end
            return ReplacePrefabName(STRINGS.eventtimer.krakener.ready)
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.krakener_time or 0
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
            scale = 0.033,
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
            local time = ThePlayer.HUD.WaringEventTimeData.tigersharker_time
            local text = ThePlayer.HUD.WaringEventTimeData.tigersharker_text
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
            local time = ThePlayer.HUD.WaringEventTimeData.tigersharker_time or 0
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
            scale = 0.025,
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
            local time = ThePlayer.HUD.WaringEventTimeData.pugalisk_fountain_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.pugalisk_fountain.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.pugalisk_fountain_time or 0
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
            scale = 0.08,
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
            local time = ThePlayer.HUD.WaringEventTimeData.banditmanager_time
            local text = ThePlayer.HUD.WaringEventTimeData.banditmanager_text
            local _time, stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.cooldown))
            if stolen_oincs then
                return time and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.announce_cooldown), TimeToString(time), stolen_oincs)
            else
                stolen_oincs = Extract_by_format(text, ReplacePrefabName(STRINGS.eventtimer.banditmanager.readytext))
                return stolen_oincs and string.format(ReplacePrefabName(STRINGS.eventtimer.banditmanager.ready), stolen_oincs)
            end
        end,
        tipsfn = function()
            local text = ThePlayer.HUD.WaringEventTimeData.banditmanager_text or ""
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
            scale = 0.25
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.aporkalypse_time
            if time and time > 0 then
                return string.format(STRINGS.eventtimer.aporkalypse.cooldown, TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.aporkalypse_time or 0
            if time == 120 or JustEntered(time) then
                local function res_time()
                    return string.format(STRINGS.eventtimer.aporkalypse.tips, TimeToString(ThePlayer.HUD.WaringEventTimeData.aporkalypse_time))
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
            scale = 0.25,
            offset = {
                x = 0,
                y = 15,
            }
        },
        announcefn = function()
            local text = ThePlayer.HUD.WaringEventTimeData.aporkalypse_attack_text
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
            scale = 0.09,
            build = "bat_vamp_build",
            bank = "bat_vamp",
            animation = "fly_loop",
            loop = true,
            uioffset = {
                x = 10,
                y = -18,
            },
            offset = {
                x = 0,
                y = -18,
            }
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.batted_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.batted.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.batted_time
            if time == 120 or JustEntered(time) then
                return true, WaringEvents.batted.announcefn, 10
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
                return  ReplacePrefabName(STRINGS.eventtimer.rocmanager.attack)
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
            scale = 0.01,
            build = "roc_head_build",
            bank = "head",
            animation = "idle_loop",
            loop = true,
            offset = {
                x = 0,
                y = -18,
            },
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.rocmanager_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.rocmanager.cooldown), TimeToString(time))
            end
        end,
        tipsfn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.rocmanager_time
            local text = ThePlayer.HUD.WaringEventTimeData.rocmanager_text
            if time == 120 or (JustEntered(time) and time > 30) then
                return true, WaringEvents.rocmanager.announcefn, 10
            elseif text == ReplacePrefabName(STRINGS.eventtimer.rocmanager.attack) then
                return true, StringToFunction(ReplacePrefabName(STRINGS.eventtimer.rocmanager.attack)), 10
            end
            return false
        end
    }
} or {}

-- 将猪镇计时添加到WaringEvents
for k, v in pairs(HamletEvents) do
    WaringEvents[k] = v
end

for event in pairs(WaringEvents) do
    WaringEvents[event].name = event -- 给 WaringEventUI.lua 使用
end

--跨世界同步计时
for waringevent, data in pairs(WaringEvents) do
    local event_time_shardrpc = waringevent .. "_time_shardrpc"
    local event_text_shardrpc = waringevent .. "_text_shardrpc"

    AddShardModRPCHandler("EventTimer", event_time_shardrpc, function(shardid, timedata, worldtype)
        if not SyncTimer then return end -- 未开启同步功能，取消同步

        local waringtimer = TheWorld.net.components.waringtimer
        if timedata then
            waringtimer.inst.replica.waringtimer[event_time_shardrpc]:set(timedata or 0)

            local textdata
            if timedata > 0 then
                textdata = TimeToString(timedata) -- 同时设置text，以显示来自哪个世界
                textdata = string.format(STRINGS.eventtimer.worldid, shardid) .. "(" .. worldtype .. ")\n" .. textdata
            end
            waringtimer.inst.replica.waringtimer[event_text_shardrpc]:set(textdata or "")
        end
    end)

    AddShardModRPCHandler("EventTimer", event_text_shardrpc, function(shardid, textdata, worldtype)
        if not SyncTimer then return end -- 未开启同步功能，取消同步

        local waringtimer = TheWorld.net.components.waringtimer
        if textdata then
            textdata = textdata ~= "" and (string.format(STRINGS.eventtimer.worldid, shardid) .. "(" .. worldtype .. ")\n" .. textdata)
            waringtimer.inst.replica.waringtimer[event_text_shardrpc]:set(textdata or "")
        end
    end)
end
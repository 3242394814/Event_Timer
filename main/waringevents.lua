local modimport = modimport
local GetModConfigData = GetModConfigData
local SyncTimer = GetModConfigData("SyncTimer")
local Upvaluehelper = Upvaluehelper
local ReplacePrefabName = ReplacePrefabName
local language = language

GLOBAL.setfenv(1, GLOBAL)
modimport("main/timerprefab")

-- 反向提取信息
local function extract_by_format(text, format_str)
    local safe = format_str:gsub("%-", "%%%1")
    local pattern = safe:gsub("%%s", "(.*)")
    return text:match(pattern)
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

-- 从worldsettingstimer获取倒计时
local function GetWorldSettingsTimeLeft(name, prefab)
    return function()
        local ent = TheWorld
        if prefab then
            ent =  TimerPrefabs[prefab]
        end
        if ent and ent.components.worldsettingstimer then
            return ent.components.worldsettingstimer:GetTimeLeft(name)
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

local function NightmareWild()
    local nightmareclock = TheWorld.net.components.nightmareclock
    if not nightmareclock then
        return
    end

    local data = nightmareclock:OnSave()
    local lengths = data.lengths
    local phase = data.phase
    local remainingtimeinphase = data.remainingtimeinphase
        if phase == "calm" then
            remainingtimeinphase = remainingtimeinphase + lengths["warn"] * 30
        elseif phase == "wild" then
            remainingtimeinphase = remainingtimeinphase + lengths["dawn"] * 30
        end

    return remainingtimeinphase
end

-- 根据冬季盛宴活动决定anim
local function ChangeanimByWintersFeast(self)
    if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
        self.anim = self.winterfeastanim
    else
        self.anim = self.defaultanim
    end
end

-- 根据世界类型决定anim
local function ChangeanimByWorld(self)
    if TheWorld:HasTag("porkland") then
        self.anim = self.porklandanim
    elseif TheWorld:HasTag("island") then
        self.anim = self.islandanim
    elseif TheWorld:HasTag("cave") then
        self.anim = self.caveanim
    else
        self.anim = self.forestanim
    end
end

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
            if ThePlayer then
                self.anim.animation = STATES[TheWorld.state.nightmarephase]
                ThePlayer.HUD.NightmareWild:SetEventAnim(self.anim)
            end
        end)
    end
end

WaringEvents = {
----------------------------------------island---------------------------------------
    ChessnavySpawn = {
        gettimefn = function()
            if TheWorld.components.chessnavy then
                return TheWorld.components.chessnavy.spawn_timer
            end
        end,
        gettextfn = function()
            if not TheWorld.components.chessnavy then return end
            local time = WaringEvents.ChessnavySpawn.gettimefn()
            return time > 0 and TimeToString(time) or STRINGS.eventtimer.chessnavyspawn.readytext
        end,
        anim = {
            scale = 0.095,
            bank = "knightboat",
            build = "knightboat_build",
            animation = "idle_loop",
            -- loop = "",
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.ChessnavySpawn_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.chessnavyspawn.cooldown), TimeToString(time))
            end
            return ReplacePrefabName(STRINGS.eventtimer.chessnavyspawn.ready)
        end
    },
    VolcanoEruption = {
        gettimefn = VolcanoEruption,
        anim = {
            scale = 0.0077,
            bank = "volcano",
            build = "volcano",
            animation = "active_idle_pst",
            -- loop = "",
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.VolcanoEruption_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.volcanoeruption.cooldown), TimeToString(time))
        end
    },
    TwisterAttack = {
        gettimefn = GetWorldSettingsTimeLeft("twister_timetoattack"),
        gettextfn = function()
            local self = TheWorld.components.twisterspawner
            if not self then return end
            local time = WaringEvents.TwisterAttack.gettimefn()
            local description
            local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
            if time and target and target.name then
                description = string.format(STRINGS.eventtimer.twisterattack.targeted, target.name, TimeToString(time))
            elseif time then
                description = string.format(ReplacePrefabName(STRINGS.eventtimer.twisterattack.cooldown), TimeToString(time))
            end

            return description
        end,
        anim = {
            scale = 0.022,
            bank = "twister",
            build = "twister_build",
            animation = "vacuum_loop",
            loop = true
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.TwisterAttack_time
            local text = ThePlayer.HUD.WaringEventTimeData.TwisterAttack_text
            local target, _ = extract_by_format(text, STRINGS.eventtimer.twisterattack.targeted)
            if target and time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.twisterattack.target), target, TimeToString(time))
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.twisterattack.cooldown), TimeToString(time))
            end
        end
    },
    KrakenCooldown = {
        gettimefn = function()
            if TheWorld.components.krakener then
                return TheWorld.components.krakener:TimeUntilCanSpawn()
            end
        end,
        gettextfn = function()
            if not TheWorld.components.krakener then return end
            local time = WaringEvents.KrakenCooldown.gettimefn()
            if time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.krakencooldown.cooldown), TimeToString(time))
            end
            return ReplacePrefabName(STRINGS.eventtimer.krakencooldown.ready)
        end,
        anim = {
            scale = 0.033,
            bank = "quacken",
            build = "quacken",
            animation = "idle_loop",
            loop = true
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.KrakenCooldown_time
            if time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.krakencooldown.cooldown), TimeToString(time))
            end
            return ReplacePrefabName(STRINGS.eventtimer.krakencooldown.ready)
        end
    },
    TigersharkCooldown = {
        gettimefn = function()
            if TheWorld.components.tigersharker then
                local self = TheWorld.components.tigersharker
                local appear_time = self:TimeUntilCanAppear()
                local respawn_time = self:TimeUntilRespawn()
                return math.max(appear_time, respawn_time)
            end
        end,
        gettextfn = function()
            local self = TheWorld.components.tigersharker
            if not self then return end
            local time = WaringEvents.TigersharkCooldown.gettimefn()
            if self.shark then
                return ReplacePrefabName(STRINGS.eventtimer.tigersharkcooldown.exists)
            elseif self:CanSpawn(true, true) then
                if time > 0 then
                    return string.format(ReplacePrefabName(STRINGS.eventtimer.tigersharkcooldown.cooldown), TimeToString(time))
                else
                    return STRINGS.eventtimer.tigersharkcooldown.readytext
                end
            end
            return ReplacePrefabName(STRINGS.eventtimer.tigersharkcooldown.nospawn)
        end,
        anim = {
            scale = 0.033,
            bank = "tigershark",
            build = "tigershark_ground_build",
            animation = "taunt",
            loop = true
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.TigersharkCooldown_time
            local text = ThePlayer.HUD.WaringEventTimeData.TigersharkCooldown_text
            local exists = string.find(text, ReplacePrefabName(STRINGS.eventtimer.tigersharkcooldown.exists))
            local nospawn = string.find(text, ReplacePrefabName(STRINGS.eventtimer.tigersharkcooldown.nospawn))
            if exists then
                return ReplacePrefabName(STRINGS.eventtimer.tigersharkcooldown.exists)
            elseif nospawn then
                return ReplacePrefabName(STRINGS.eventtimer.tigersharkcooldown.nospawn)
            elseif time and time > 0 then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.tigersharkcooldown.cooldown), TimeToString(time))
            else
                return ReplacePrefabName(STRINGS.eventtimer.tigersharkcooldown.ready)
            end
        end
    },

----------------------------------------forest---------------------------------------

    HoundAttack = {
        gettimefn = function()
            if TheWorld.components.hounded then
                local data = TheWorld.components.hounded:OnSave()
                return data and data.timetoattack or nil
            end
        end,
        animchangefn = ChangeanimByWorld,
        forestanim = {
            scale = 0.099,
            bank = "hound",
            build = "hound_ocean",
            animation = "idle",
        },
        islandanim = {
            scale = 0.099,
            bank = "crocodog",
            build = "crocodog_poison",
            animation = "idle",
            loop = true,
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
            local time = ThePlayer.HUD.WaringEventTimeData.HoundAttack_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.houndattack.cooldown), TimeToString(time))
        end
    },
    DeerclopsAttack = {
        gettimefn = GetWorldSettingsTimeLeft("deerclops_timetoattack"),
        gettextfn = function()
            local self = TheWorld.components.deerclopsspawner
            if not self then return end
            local time = WaringEvents.DeerclopsAttack.gettimefn()
            local description
            local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
            if time and target and target.name then
                description = string.format(STRINGS.eventtimer.deerclopsattack.targeted, target.name, TimeToString(time))
            elseif time then
                description = string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsattack.cooldown), TimeToString(time))
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
        },
        winterfeastanim = {
            scale = 0.044,
            bank = "deerclops",
            build = "deerclops_yule",
            animation = "idle_loop",
            loop = true,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.DeerclopsAttack_time
            local text = ThePlayer.HUD.WaringEventTimeData.DeerclopsAttack_text
            local target, _ = extract_by_format(text, STRINGS.eventtimer.deerclopsattack.targeted)
            if target and time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsattack.target), target, TimeToString(time))
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.deerclopsattack.cooldown), TimeToString(time))
            end
        end
    },
    DeerherdSpawn = {
        gettimefn = function()
            if TheWorld.components.deerherdspawner then
                local data = TheWorld.components.deerherdspawner:OnSave()
                return data and data._timetospawn or nil
            end
        end,
        anim = {
            scale = 0.088,
            bank = "deer",
            build = "deer_build",
            animation = "idle_loop",
            loop = true
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.DeerherdSpawn_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.deerheraspawn.cooldown), TimeToString(time))
        end
    },
    KlaussackSpawn = {
        gettimefn = GetWorldSettingsTimeLeft("klaussack_spawntimer"),
        gettextfn = function()
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
                return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawn.despawntext), sack.despawnday)
            else
                local time = WaringEvents.KlaussackSpawn.gettimefn()
                return time and string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawn.cooldowntext), TimeToString(time))
            end
        end,
        anim = {
            scale = 0.11,
            bank = "klaus_bag",
            build = "klaus_bag",
            animation = "idle",
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.KlaussackSpawn_time
            local text = ThePlayer.HUD.WaringEventTimeData.KlaussackSpawn_text
            local despawnday = extract_by_format(text, STRINGS.eventtimer.klaussackspawn.despawntext)
            if despawnday then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawn.despawn), despawnday)
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.klaussackspawn.cooldown), TimeToString(time))
            end
        end
    },
    AntlionAttack = {
        gettimefn = GetWorldSettingsTimeLeft("rage", "antlion"),
        anim = {
            scale = 0.055,
            bank = "antlion",
            build = "antlion_build",
            animation = "idle",
            loop = true
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.AntlionAttack_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.antlionattack.cooldown), TimeToString(time))
        end
    },
    BeargerSpawn = {
        gettimefn = GetWorldSettingsTimeLeft("bearger_timetospawn"),
        gettextfn = function()
            local self = TheWorld.components.beargerspawn
            if not self then return end
            local time = WaringEvents.BeargerSpawn.gettimefn()
            local description
            local target = Upvaluehelper.GetUpvalue(self.OnUpdate, "_targetplayer")
            if time and target and target.name then
                description = string.format(STRINGS.eventtimer.beargerspawn.targeted, target.name, TimeToString(time))
            elseif time then
                description = string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawn.cooldown), TimeToString(time))
            end

            return description
        end,
        animchangefn = ChangeanimByWintersFeast,
        defaultanim = {
            scale = 0.044,
            bank = "bearger",
            build = "bearger_build",
            animation = "idle_loop",
            loop = true,
        },

        winterfeastanim = {
            scale = 0.033,
            bank = "bearger",
            build = "bearger_yule",
            animation = "idle_loop",
            loop = true,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.BeargerSpawn_time
            local text = ThePlayer.HUD.WaringEventTimeData.BeargerSpawn_text
            local target, _ = extract_by_format(text, STRINGS.eventtimer.beargerspawn.targeted)
            if target and time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawn.target), target, TimeToString(time))
            elseif time then
                return string.format(ReplacePrefabName(STRINGS.eventtimer.beargerspawn.cooldown), TimeToString(time))
            end
        end
    },
    DragonflySpawn = {
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
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.DragonflySpawn_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.dragonflyspawn.cooldown), TimeToString(time))
        end
    },
    BeequeenhiveGrown = {
        gettimefn = BeequeenhiveGrown,
        anim = {
            scale = 0.044,
            bank = "bee_queen",
            build = "bee_queen_build",
            animation = "idle_loop",
            loop = true,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.BeequeenhiveGrown_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.beequeenhivegrown.cooldown), TimeToString(time))
        end
    },
    TerrariumCooldown = {
        gettimefn = GetWorldSettingsTimeLeft("cooldown", "terrarium"),
        anim = {
            scale = 0.2,
            bank = "terrarium",
            build = "terrarium",
            animation = "idle",
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.TerrariumCooldown_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.terrariumcooldown.cooldown), TimeToString(time))
        end
    },
    MalbatrossSpawn = {
        gettimefn = GetWorldSettingsTimeLeft("malbatross_timetospawn"),
        anim = {
            scale = 0.04,
            bank = "malbatross",
            build = "malbatross_build",
            animation = "idle_loop",
            loop = true,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.MalbatrossSpawn_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.malbatrossspawn.cooldown), TimeToString(time))
        end
    },
    CrabkingSpawn = {
        gettimefn = GetWorldSettingsTimeLeft("regen_crabking", "crabking_spawner"),
        anim = {
            scale = 0.022,
            bank = "king_crab",
            build = "crab_king_build",
            animation = "inert",
            loop = true,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.CrabkingSpawn_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.crabkingspawn.cooldown), TimeToString(time))
        end
    },

----------------------------------------cave----------------------------------------
    ToadstoolReSpawn = {
        gettimefn = GetWorldSettingsTimeLeft("toadstool_respawntask"),
        anim = {
            scale = 0.033,
            bank = "toadstool",
            build = "toadstool_build",
            animation = "idle",
            loop = true,
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.ToadstoolReSpawn_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.toadstoolrespawn.cooldown), TimeToString(time))
        end
    },
    AtriumgateCooldown = {
        gettimefn = GetWorldSettingsTimeLeft("cooldown", "atrium_gate"),
        anim = {
            scale = 0.06,
            bank = "atrium_gate",
            build = "atrium_gate",
            animation = "idle",
        },
        announcefn = function()
            local time = ThePlayer.HUD.WaringEventTimeData.AtriumgateCooldown_time
            return time and string.format(ReplacePrefabName(STRINGS.eventtimer.atriumgatecooldown.cooldown), TimeToString(time))
        end
    },
    NightmareWild = {
        gettimefn = NightmareWild,
        anim = {
            scale = 0.25,
            bank = "nightmare_watch",
            build = "nightmare_timepiece",
            animation = "idle_1",
            pos = {-45, -15}
        },
        animchangefn = NightmareWildAnimChange
    }
}

for event, _ in pairs(WaringEvents) do
    WaringEvents[event].name = event -- 给 WaringEventHUD.lua 使用
end

--跨世界同步计时
for waringevent, data in pairs(WaringEvents) do
    if data.gettextfn then
        local eventname = waringevent .. "_text"
        AddShardModRPCHandler("EventTimer", eventname, function(shardid, timedata, worldtype)
            if not SyncTimer then return end -- 未开启同步功能，取消同步

            local waringtimer = TheWorld.net.components.waringtimer
            if timedata then
                timedata = timedata ~= "" and (string.format(STRINGS.eventtimer.worldid, shardid) .. "(" .. worldtype .. ")\n" .. timedata)
                waringtimer[eventname] = timedata
                waringtimer.inst.replica.waringtimer[eventname]:set(waringtimer[eventname] or "")
            end
        end)
    end

    if data.gettimefn then
        local eventname = waringevent .. "_time"
        AddShardModRPCHandler("EventTimer", eventname, function(shardid, timedata)
            if not SyncTimer then return end -- 未开启同步功能，取消同步

            local waringtimer = TheWorld.net.components.waringtimer
            if timedata then
                waringtimer[eventname] = timedata
                waringtimer.inst.replica.waringtimer[eventname]:set(waringtimer[eventname] or 0)
            end
        end)
    end
end

-- 客户端：宣告服务器发送的内容
AddClientModRPCHandler("EventTimer", "announce", function(text)
    TheNet:Say(text)
end)

-- 获取宣告内容并宣告，在 WaringEventHUD.lua 使用
AddModRPCHandler("EventTimer", "getannounce", function(player, EventName)
    if WaringEvents[EventName] and WaringEvents[EventName].announcefn then
        local text = WaringEvents[EventName].announcefn()
        if text then
            SendModRPCToClient(CLIENT_MOD_RPC["EventTimer"]["announce"], player, text)
        end
    end
end)
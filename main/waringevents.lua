local modimport = modimport
local GetModConfigData = GetModConfigData
GLOBAL.setfenv(1, GLOBAL)

modimport("main/timerprefab")

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


local function ChangeanimByWintersFeast(self)
    if IsSpecialEventActive(SPECIAL_EVENTS.WINTERS_FEAST) then
        self.anim = self.winterfeastanim
    else
        self.anim = self.defaultanim
    end
end

local function ChangeanimByWorld(self)
    if TheWorld:HasTag("island") then
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
        anim = {
            scale = 0.095,
            bank = "knightboat",
            build = "knightboat_build",
            animation = "idle_loop",
            -- loop = "",
        }
    },
    VolcanoEruption = {
        gettimefn = VolcanoEruption,
        anim = {
            scale = 0.0077,
            bank = "volcano",
            build = "volcano",
            animation = "active_idle_pst",
            -- loop = "",
        }
    },
    TwisterAttack = {
        gettimefn = GetWorldSettingsTimeLeft("twister_timetoattack"),
        anim = {
            scale = 0.022,
            bank = "twister",
            build = "twister_build",
            animation = "vacuum_loop",
            loop = true
        }
    },
    KrakenCooldown = {
        gettimefn = function()
            if TheWorld.components.krakener then
                return TheWorld.components.krakener:TimeUntilCanSpawn()
            end
        end,
        anim = {
            scale = 0.033,
            bank = "quacken",
            build = "quacken",
            animation = "idle_loop",
            loop = true
        }
    },
    TigersharkCooldown = {
        gettimefn = function()
            if TheWorld.components.tigersharker then
                return TheWorld.components.tigersharker:TimeUntilRespawn()
            end
        end,
        anim = {
            scale = 0.033,
            bank = "tigershark",
            build = "tigershark_ground_build",
            animation = "taunt",
            loop = true
        }
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
        }
    },
    DeerclopsAttack = {
        gettimefn = GetWorldSettingsTimeLeft("deerclops_timetoattack"),
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
        }
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
        }
    },
    KlaussackSpawn = {
        gettimefn = GetWorldSettingsTimeLeft("klaussack_spawntimer"),
        anim = {
            scale = 0.11,
            bank = "klaus_bag",
            build = "klaus_bag",
            animation = "idle",
        }
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
        ShardRPC = {
            IsSendShard = function() return TheWorld:HasTag("forest") end
        }
    },
    BeargerSpawn = {
        gettimefn = GetWorldSettingsTimeLeft("bearger_timetospawn"),
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
        }
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
        }
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
    },
    TerrariumCooldown = {
        gettimefn = GetWorldSettingsTimeLeft("cooldown", "terrarium"),
        anim = {
            scale = 0.2,
            bank = "terrarium",
            build = "terrarium",
            animation = "idle",
        },
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
    },
    AtriumgateCooldown = {
        gettimefn = GetWorldSettingsTimeLeft("cooldown", "atrium_gate"),
        anim = {
            scale = 0.06,
            bank = "atrium_gate",
            build = "atrium_gate",
            animation = "idle",
        },
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
    WaringEvents[event].turn_on = true -- 决定是否开启对应的BOSS计时功能
end

AddShardModRPCHandler("Island Adventures Assistant", "AntlionAttack", function(shardid, time)
    if TheWorld:HasTag("cave") and WaringEvents["AntlionAttack"].turn_on then
        local waringtimer = TheWorld.net.components.waringtimer
        waringtimer["AntlionAttack"] = time
        -- waringtimer.inst.replica.waringtimer["AntlionAttack"]:set_local(0)
        waringtimer.inst.replica.waringtimer["AntlionAttack"]:set(waringtimer["AntlionAttack"] or 0)
    end
end)

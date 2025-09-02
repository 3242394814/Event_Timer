local STRINGS = GLOBAL.STRINGS
STRINGS.eventtimer = {
    ui_title = "Events Timer",
    ui_desc = "Events Timer\nRight click to drag",
    worldid = "World %s",
    worldtype = {
        forest = "Forest",
        cave = "Cave",
        shipwrecked = "Shipwrecked",
        volcano = "Volcano",
        porkland = "Hamlet",
    },
    time = {
        hour = " hour ",
        day = " day ",
        minutes = " min ",
        seconds = " sec"
    },

    ----------------------------------------Forest----------------------------------------

    hounded = {
        cooldowns = {
            forest = "<prefab=hound> will attack in %s.",
            cave = "<prefab=worm> will attack in %s.",
            worm_boss = "<prefab=worm_boss> will attack in %s.",
            shipwrecked = "<prefab=crocodog> will attack in %s.",
            volcano =  "<prefab=crocodog> will attack in %s.",
            porkland = "<prefab=vampirebat> will attack in %s.",
        },
        attack = {
            forest = "WARNING: <prefab=hound> attack starts!",
            cave = "WARNING: <prefab=worm> attack starts!",
            worm_boss = "WARNING: <prefab=worm_boss> attack starts!",
            shipwrecked = "WARNING: <prefab=crocodog> attack starts!",
            volcano =  "WARNING: <prefab=crocodog> attack starts!",
            porkland = "WARNING: <prefab=vampirebat> attack starts!",
        },
        worm_boss_chance = "<prefab=worm> will attack in %s.\n<prefab=worm_boss> chance: %s%%",
    },
    deerclopsspawner = {
        cooldown = "<prefab=deerclops> will attack in %s.",
        target = "<prefab=deerclops> will spawn on %s in %s.",
        targeted = "Target: %s -> %s",
        attack = "WARNING: <prefab=deerclops> attack starts!",
    },
    deerherdspawner = {
        cooldown = "<prefab=deer> will spawn in %s.",
    },
    klaussackspawner = {
        cooldown = "<prefab=klaus_sack> will spawn in %s.",
        cooldowntext = "%s",
        despawn = "<prefab=klaus_sack> will despawn on day %s.",
        despawntext = "Despawns on day: %s",
        tips = "<prefab=klaus_sack> has respawned!",
    },
    sinkholespawner = {
        cooldown = "<prefab=antlion>will rage in %s.",
        attack = "WARNING: <prefab=antlion> is starting to rage!",
    },
    beargerspawner = {
        cooldown = "<prefab=bearger> will attack in %s.",
        target = "<prefab=bearger> will spawn on %s in %s.",
        targeted = "Target: %s -> %s",
        attack = "WARNING: <prefab=bearger> attack starts!",
    },
    dragonfly_spawner = {
        cooldown = "<prefab=dragonfly> will respawn in %s.",
        tips = "<prefab=dragonfly> has respawned!",
    },
    beequeenhive = {
        cooldown = "<prefab=beequeen> will respawn in %s.",
        tips = "<prefab=beequeen> has respawned!",
    },
    terrarium = {
        cooldown = "<prefab=terrarium> will be ready in %s.",
        tips = "<prefab=terrarium> is ready.",
    },
    malbatrossspawner = {
        cooldown = "<prefab=malbatross> will respawn in %s.",
    },
    crabkingspawner = {
        cooldown = "<prefab=crabking> will respawn in %s.",
    },
    moon = {
        moon_full = "%s days until full moon",
        moon_new = "%s days until new moon",
        str_full = "full moon",
        moon_full_ready = "Tonight is the full moon! ",
        moon_new_ready = "Tonight is the new moon! ",
    },
    farming_manager = {
        cooldown = "<prefab=lordfruitfly> will be ready in %s.",
        ready = "<prefab=lordfruitfly> attack starts!",
        tips = "WARNING: <prefab=lordfruitfly> attack starts!"
    },
    piratespawner = {
        -- TODO
    },
    forestdaywalkerspawner = {
        cooldown = "<prefab=daywalker2 will respawn in %s.",
        tips = "<prefab=daywalker2> has respawned!",
    },
    riftspawner = {
        cooldown = "A <prefab=lunarrift_portal> will spawn in %s",
        stage = "Stage: %s / %s",
    },
	lunarthrall_plantspawner = {
		infested_count = "%s plants infested",
		spawn = "Gestalts spawn in %s",
		next_wave = "Next wave in %s",
		remain_waves = "%s waves remaining",
	},
    rift_portal = {
		next_stage = "Next stage in %s.",
		crystals = "<prefab=lunarrift_crystal_big>: %s available / %s total / %s max",
		next_crystal = "Next <prefab=lunarrift_crystal_big> spawns in %s",
	},
    shadowrift_portal = {
        close = "<prefab=shadowrift_portal> will close in %s",
    },

    ----------------------------------------Cave----------------------------------------

    daywalkerspawner = {
        cooldown = "<prefab=daywalker> will respawn in %s.",
        tips = "<prefab=daywalker> has respawned!",
    },
    shadowthrallmanager = {
		fissure_cooldown = "Next fissure will be ready for takeover in %s",
		waiting_for_players = "Waiting for a player to come near",
		thralls_alive = "Thralls alive (%s): %s",
		dreadstone_regen = "<prefab=dreadstone> will regenerate in %s",
	},
    toadstoolspawner = {
		cooldown = "<prefab=toadstool> will respawn in %s.",
    },
    atrium_gate = {
		cooldown = "<prefab=atrium_gate> will reset in %s.",
    },
    nightmareclock = {
        phase_locked_text = "Locked by the Ancient Key",
        phase_locked = "The ruins are currently locked in the nightmare phase.",
        phases = {
            calm = "Calm",
            warn = "Warning",
            wild = "Nightmare",
            dawn = "Dawn",
        },
        cooldown = "The ruins are in the %s phase (%s remaining).",
        cooldown_none = "%s remaining in the current ruins phase",
    },
    quaker = {
        cooldown = "The cave will earthquake in %s"
    },

    ----------------------------------------Shipwrecked----------------------------------------

    chessnavy = {
        cooldown = "<prefab=knightboat> will spawn in %s.",
        ready = "<prefab=knightboat> is waiting for you to return to the crime scene",
        readytext = "Waiting for you to return to a crime scene.",
    },
    volcanomanager = {
        cooldown = "<prefab=volcano> will erupt in %s.",
        attack = "WARNING: The <prefab=volcano> is erupting!",
    },
    twisterspawner = {
        cooldown = "<prefab=twister> will attack in %s.",
        target = "<prefab=twister> will spawn on %s in %s.",
        targeted = "Target: %s -> %s",
        attack = "WARNING: <prefab=twister> attack starts!",
    },
    krakener = {
        cooldown = "<prefab=kraken> will respawn in %s.",
        ready = "<prefab=kraken> is waiting for you to drag it out",
        tips = "<prefab=kraken> has respawned!",
    },
    tigersharker = {
        cooldown = "<prefab=tigershark> will respawn in %s.",
        ready = "<prefab=tigershark> ready to spawn",
        readytext = "Ready to spawn.",
        exists = "<prefab=tigershark> is present.",
        nospawn = "<prefab=tigershark>: ?No Spawn Possible?",
        tips = "<prefab=tigershark> ready to spawn.",
    },

    ----------------------------------------Hamlet----------------------------------------

    pugalisk_fountain = {
        cooldown = "<prefab=waterdrop> will regenerate in %s.",
        tips = "<prefab=waterdrop> has regenerate!",
    },
    banditmanager = {
        cooldown = "Next assessment in: %s\n[Stolen Oincs: %s , Active Bandit: %s]",
        announce_cooldown = "The next assessment by the <prefab=pigbandit> will be in %s. Currently stolen Oincs: %s",
        ready = "<prefab=pigbandit> is present. Currently stolen Oincs: %s",
        readytext = "<prefab=pigbandit> is present.\nCurrently stolen Oincs: %s",
        tips = "WARNING: <prefab=pigbandit> is present!",
    },
    aporkalypse = {
        cooldown = "The Aporkalypse will arrive in %s.",
        attack = "\nNext <prefab=vampirebat> attack: %s\nNext <prefab=ancient_herald> attack: %s",
        announce_attack = "Next <prefab=vampirebat>attack: %s    Next <prefab=ancient_herald> attack: %s",
        tips = "WARNING: The Aporkalypse will arrive in %s.",
        tips_ready = "Blood moon falls!",
        tips_attack = "WARNING: <prefab=ancient_herald> will spawn in %s.", -- Not in use
        tips_attack_ready = "WARNING: <prefab=ancient_herald> attack starts!", -- Not in use
    },
    batted = {
        cooldown = "<prefab=vampirebat> will attack in %s.",
        cooldowntext = "%s\n[count：%s , regen in：%s]",
        attack = "WARNING: <prefab=vampirebat> attack starts!",
    },
    rocmanager = {
        cooldown = "<prefab=roc_head> will arrive in %s.",
        exists = "<prefab=roc_head> is present.",
        tips = "WARNING: <prefab=roc_head> attack starts!"
    },

    ----------------------------------------Uncompromising Mode----------------------------------------

    gmoosespawner = {
        cooldown = "<prefab=moose1> will attack in %s.",
        target = "<prefab=moose1> will spawn on %s in %s.",
        targeted = "Target: %s -> %s",
        attack = "WARNING: <prefab=moose1> attack starts!",
    },
    mock_dragonflyspawner = {
        cooldown = "<prefab=dragonfly> will attack in %s.",
        target = "<prefab=dragonfly> will spawn on %s in %s.",
        targeted = "Target: %s -> %s",
        attack = "WARNING: <prefab=dragonfly> attack starts!",
    },
}
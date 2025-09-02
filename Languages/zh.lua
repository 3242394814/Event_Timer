local STRINGS = GLOBAL.STRINGS
STRINGS.eventtimer = {
    ui_title = "事件计时器",
    ui_desc = "事件计时器\n右键拖拽",
    worldid = "世界%s", -- 跨世界同步计时，文字添加前缀
    worldtype = {
        forest = "森林",
        cave = "洞穴",
        shipwrecked = "海难",
        volcano = "火山",
        porkland = "猪镇",
    },
    time = {
        hour = "小时",
        day = "天",
        minutes = "分",
        seconds = "秒"
    },

    ----------------------------------------森林----------------------------------------

    hounded = { -- 猎犬/洞穴蠕虫/鳄狗/吸血蝙蝠
        cooldowns = {
            forest = "<prefab=hound>将在%s后攻击",
            cave = "<prefab=worm>将在%s后攻击",
            worm_boss = "<prefab=worm_boss>将在%s后攻击",
            shipwrecked = "<prefab=crocodog>将在%s后攻击",
            volcano =  "<prefab=crocodog>将在%s后攻击",
            porkland = "<prefab=vampirebat>将在%s后攻击",
        },
        attack = {
            forest = "警告：<prefab=hound>攻击开始！！！",
            cave = "警告：<prefab=worm>攻击开始！！！",
            worm_boss = "警告：<prefab=worm_boss>攻击开始！！！",
            shipwrecked = "警告：<prefab=crocodog>攻击开始！！！",
            volcano =  "警告：<prefab=crocodog>攻击开始！！！",
            porkland = "警告：<prefab=vampirebat>攻击开始！！！",
        },
        worm_boss_chance = "<prefab=worm>会在%s后攻击\n<prefab=worm_boss> 概率: %s%%",
    },
    deerclopsspawner = { -- 独眼巨鹿
        cooldown = "<prefab=deerclops>会在%s后生成",
        target = "<prefab=deerclops>会生成在%s周围于%s后",
        targeted = "目标：%s -> %s",
        attack = "警告：<prefab=deerclops>已刷新！！！",
    },
    deerherdspawner = { -- 无眼鹿
        cooldown = "<prefab=deer>会刷新于%s后",
    },
    klaussackspawner = { -- 赃物袋
        cooldown = "<prefab=klaus_sack>会生成于%s后",
        cooldowntext = "%s",
        despawn = "<prefab=klaus_sack>将消失于第%s天",
        despawntext = "消失于第%s天",
        tips = "<prefab=klaus_sack>已刷新！",
    },
    sinkholespawner = { -- 蚁狮
        cooldown = "<prefab=antlion>会发怒于%s后",
        attack = "警告：<prefab=antlion>开始发怒",
    },
    beargerspawner = { -- 熊獾
        cooldown = "<prefab=bearger>会在%s后生成",
        target = "<prefab=bearger>会生成在%s周围于%s后",
        targeted = "目标：%s -> %s",
        attack = "警告：<prefab=bearger>已刷新！！！",
    },
    dragonfly_spawner = { -- 龙蝇
        cooldown = "<prefab=dragonfly>会重生于%s后",
        tips = "<prefab=dragonfly>已刷新！",
    },
    beequeenhive = { -- 蜂后
        cooldown = "<prefab=beequeen>会重生于%s后",
        tips = "<prefab=beequeen>已刷新！",
    },
    terrarium = { -- 盒中泰拉
        cooldown = "<prefab=terrarium>就绪于%s后",
        tips = "<prefab=terrarium>已准备就绪",
    },
    malbatrossspawner = { -- 邪天翁
        cooldown = "<prefab=malbatross>会重生于%s后",
    },
    crabkingspawner = { -- 帝王蟹
        cooldown = "<prefab=crabking>会重生于%s后",
    },
    moon = { -- 月相
        moon_full = "距离月圆还剩%s天",
        moon_new = "距离月黑还剩%s天",
        str_full = "月圆",
        moon_full_ready = "今晚月圆！",
        moon_new_ready = "今晚月黑！",
    },
    farming_manager = { -- 果蝇王
        cooldown = "<prefab=lordfruitfly>就绪于%s后",
        ready = "<prefab=lordfruitfly>已刷新！",
        tips = "警告：<prefab=lordfruitfly>已刷新！"
    },
    piratespawner = { -- 海盗袭击，暂时不做
        -- TODO
    },
    forestdaywalkerspawner = { -- 拾荒疯猪
        cooldown = "<prefab=daywalker2>会重生于%s后",
        tips = "<prefab=daywalker2>已刷新！",
    },
    riftspawner = {
        cooldown = "一个<prefab=lunarrift_portal>将生成于%s后",
        stage = "阶段: %s / %s",
    },
	lunarthrall_plantspawner = {
		infested_count = "已寄生%s株",
		spawn = "%s后开始寄生",
		next_wave = "%s后开始下一波",
		remain_waves = "剩余%s波",
	},
    rift_portal = { -- 月亮裂隙
		next_stage = "%s后进入下一阶段",
		crystals = "<prefab=lunarrift_crystal_big>: %s可用 / %s总共 / %s最大",
		next_crystal = "下一波<prefab=lunarrift_crystal_big>生成于%s后",
	},
    shadowrift_portal = { -- 暗影裂隙
        close = "<prefab=shadowrift_portal>将关闭于%s后",
    },

    ----------------------------------------洞穴----------------------------------------

    daywalkerspawner = { -- 梦魇疯猪
        cooldown = "<prefab=daywalker>会重生于%s后",
        tips = "<prefab=daywalker>已刷新！",
    },
    shadowthrallmanager = { -- 梦魇裂隙/墨荒
		fissure_cooldown = "%s后可控制下一裂隙",
		waiting_for_players = "等待一个玩家接近",
		thralls_alive = "活着的奴隶 (%s): %s",
		dreadstone_regen = "<prefab=dreadstone>会再生于%s后",
	},
    toadstoolspawner = { -- 毒菌蟾蜍
		cooldown = "<prefab=toadstool>会重生于%s后",
    },
    atrium_gate = { -- 远古大门
		cooldown = "<prefab=atrium_gate>会重置于%s后",
    },
    nightmareclock = { -- 遗迹当前阶段
        phase_locked_text = "被远古钥匙锁住",
        phase_locked = "远古遗迹现在锁定在暴动期",
        phases = {
            calm = "平静",
            warn = "警告",
            wild = "暴动",
            dawn = "黎明",
        },
        cooldown = "远古遗迹现在在%s期 (还剩%s)",
        cooldown_none = "远古遗迹当前阶段还剩%s",
    },
    quaker = { -- 地震
        cooldown = "洞穴将在%s后地震"
    },

    ----------------------------------------海难----------------------------------------

    chessnavy = { -- 浮船骑士
        cooldown = "<prefab=knightboat>会刷新于%s后",
        ready = "<prefab=knightboat>正在等待你回到罪行地点",
        readytext = "正在等待你回到罪行地点",
    },
    volcanomanager = { -- 火山爆发倒计时 VOLCANOMANAGER
        cooldown = "<prefab=volcano>将于%s后爆发。",
        attack = "警告：<prefab=volcano>爆发！！！",
    },
    twisterspawner = { -- 豹卷风
        cooldown = "<prefab=twister>会在%s后生成。",
        target = "<prefab=twister>会生成在%s周围于%s后",
        targeted = "目标：%s -> %s",
        attack = "警告：<prefab=twister>已刷新！！！",
    },
    krakener = { -- 海妖
        cooldown = "<prefab=kraken>会重生于%s后",
        ready = "<prefab=kraken>正在等你去拖出",
        tips = "<prefab=kraken>已重生！",
    },
    tigersharker = { -- 虎鲨
        cooldown = "<prefab=tigershark>会重生于%s后",
        ready = "<prefab=tigershark>正期待与你邂逅",
        readytext = "重生准备就绪",
        exists = "当前<prefab=tigershark>正在出没",
        nospawn = "<prefab=tigershark>：没有刷出的可能？",
        tips = "<prefab=tigershark>重生准备就绪",
    },

    ----------------------------------------猪镇----------------------------------------

    pugalisk_fountain = { -- 不老泉
        cooldown = "<prefab=waterdrop>会再生于%s后。",
        tips = "<prefab=waterdrop>已刷新！",
    },
    banditmanager = { -- 蒙面猪人
        cooldown = "尝试刷新于: %s后\n[被盗的呼噜币数量: %s，当前盗贼出没: %s]",
        announce_cooldown = "<prefab=pigbandit>将于%s后尝试刷新。当前已盗走%s个呼噜币。",
        ready = "<prefab=pigbandit>正在出没。当前盗走的呼噜币数量: %s",
        readytext = "<prefab=pigbandit>正在出没。\n当前盗走的呼噜币数量: %s",
        tips = "警告：<prefab=pigbandit>正在出没！！！",
    },
    aporkalypse = { -- 大灾变
        cooldown = "大灾变将在%s后到来。",
        attack = "\n下一次<prefab=vampirebat>袭击: %s后\n下一次<prefab=ancient_herald>袭击: %s后",
        announce_attack = "下一次<prefab=vampirebat>袭击: %s后    下一次<prefab=ancient_herald>袭击: %s后",
        tips = "警告：大灾变将在%s后到来！！！",
        tips_ready = "血月降临！",
        tips_attack = "警告：<prefab=ancient_herald>会在%s后生成。", -- 未使用
        tips_attack_ready = "警告：<prefab=ancient_herald>已刷新！！！", -- 未使用
    },
    batted = { -- 吸血蝙蝠
        cooldown = "<prefab=vampirebat>会在%s后攻击。",
        cooldowntext = "%s\n[数量: %s，下一只蝙蝠生成还需: %s]",
        attack = "警告：<prefab=vampirebat>攻击开始！！！",
    },
    rocmanager = { -- 友善的大鹏
        cooldown = "<prefab=roc_head>会在%s后到来。",
        exists = "<prefab=roc_head>正在出没",
        tips = "警告：<prefab=roc_head>已刷新！"
    },

    ----------------------------------------永不妥协----------------------------------------

    gmoosespawner = { -- 麋鹿鹅
        cooldown = "<prefab=moose1>会在%s后生成",
        target = "<prefab=moose1>会生成在%s周围于%s后",
        targeted = "目标：%s -> %s",
        attack = "警告：<prefab=moose1>已刷新！！！",
    },
    mock_dragonflyspawner = { -- 龙蝇
        cooldown = "<prefab=dragonfly>会在%s后生成",
        target = "<prefab=dragonfly>会生成在%s周围于%s后",
        targeted = "目标：%s -> %s",
        attack = "警告：<prefab=dragonfly>已刷新！！！",
    },
}
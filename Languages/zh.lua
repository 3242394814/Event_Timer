local STRINGS = GLOBAL.STRINGS
STRINGS.eventtimer = {
    worldid = "世界%s", -- 跨世界同步计时，文字添加前缀
    worldtype = {
        forest = "森林",
        cave = "洞穴",
        shipwrecked = "海难",
        volcano = "火山",
        porkland = "猪镇"
    },
----------------------------------------海难----------------------------------------

    chessnavyspawn = { -- 浮船骑士
        cooldown = "<prefab=knightboat>会刷新于%s后",
        ready = "<prefab=knightboat>正在等待你回到罪行地点",
        readytext = "正在等待你回到罪行地点",
    },
    volcanoeruption = { -- 火山爆发倒计时 VOLCANOMANAGER
        cooldown = "<prefab=volcano>将于%s后爆发。",
    },
    twisterattack = { -- 豹卷风
        cooldown = "<prefab=twister>会在%s后攻击。",
        target = "<prefab=twister>会生成在%s周围于%s后",
        targeted = "目标：%s -> %s",
    },
    krakencooldown = { -- 海妖
        cooldown = "<prefab=kraken>会重生于%s后",
        ready = "<prefab=kraken>正在等你去拖出",
    },
    tigersharkcooldown = { -- 虎鲨
        cooldown = "<prefab=tigershark>会重生于%s后",
        ready = "<prefab=tigershark>正期待与你邂逅",
        readytext = "重生准备就绪",
        exists = "当前<prefab=tigershark>出没",
        nospawn = "<prefab=tigershark>：没有刷出的可能？",
    },

----------------------------------------森林----------------------------------------

    houndattack = { -- 猎犬/鳄狗/吸血蝙蝠
        cooldown = "<prefab=hound>将在%s后攻击",
    },
    deerclopsattack = { -- 独眼巨鹿
        cooldown = "<prefab=deerclops>会在%s后攻击",
        target = "<prefab=deerclops>会生成在%s周围于%s后",
        targeted = "目标：%s -> %s"
    },
    deerheraspawn = { -- 无眼鹿
        cooldown = "<prefab=deer>会刷新于%s后",
    },
    klaussackspawn = { -- 赃物袋
        cooldown = "<prefab=klaus_sack>会生成于%s后",
        cooldowntext = "%s",
        despawn = "<prefab=klaus_sack>将消失于第%s天",
        despawntext = "消失于第%s天",
    },
    antlionattack = { -- 蚁狮
        cooldown = "<prefab=antlion>会发怒于%s后",
    },
    beargerspawn = { -- 熊獾
        cooldown = "<prefab=bearger>会在%s后攻击",
        target = "<prefab=bearger>会生成在%s周围于%s后",
        targeted = "目标：%s -> %s",
    },
    dragonflyspawn = { -- 龙蝇
        cooldown = "<prefab=dragonfly>会重生于%s后",
    },
    beequeenhivegrown = { -- 蜂后
        cooldown = "<prefab=beequeen>会重生于%s后",
    },
    terrariumcooldown = { -- 盒中泰拉
        cooldown = "<prefab=terrarium>会重生于%s后",
    },
    malbatrossspawn = { -- 邪天翁
        cooldown = "<prefab=malbatross>会重生于%s后",
    },
    crabkingspawn = { -- 帝王蟹
        cooldown = "<prefab=crabking>会重生于%s后",
    },
    ----------------------------------------洞穴----------------------------------------

    toadstoolrespawn = { -- 毒菌蟾蜍
		cooldown = "<prefab=toadstool>会重生于%s后",
    },
    atriumgatecooldown = { -- 远古大门
		cooldown = ((STRINGS.UI.CUSTOMIZATIONSCREEN and STRINGS.UI.CUSTOMIZATIONSCREEN.ATRIUMGATE) or "远古大门") .. "会重置于%s后",
    },
    nightmarewild = { -- 遗迹当前阶段
        -- cooldown = ""
        -- TODO
    },
}
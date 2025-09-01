<!-- · 进入游戏时/倒计时N分钟时(N = 事件列表自定义的数组 比如30、60、120)，左上角发出提示，配合提示音：TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/XP_bar_fill_unlock") -->
<!-- 支持关闭此提示，client = true -->
<!-- · 像Insight一样的BOSS倒计时面板 -->
<!-- · 支持宣告倒计时 -->
<!-- · 支持指定倒计时一直显示(勾选显示，不勾选不显示，支持长久保存数据) -->
<!-- · 跨世界同步倒计时（显示计时来自哪个世界，不兼容超多层世界，模组说明里要标注） -->
<!-- · 客户端预测功能，开启此功能后服务器5秒或更多秒刷新一次数据，刷新给客户端后，客户端自己减一减一，减轻服务器压力 -->
<!-- · 支持识别【已暂停】的倒计时 -->
<!-- · 修改【遗迹当前阶段】计时 -->
<!-- · 修改面板UI -->
<!-- · 自动清理过期的从世界计时数据 -->
<!-- · 进行功能验收/BUG测试 -->
<!-- · 检测到与其他计时模组一起开时，提示玩家关掉其它计时模组。与Insight一起开时，什么也不做（兼容不来） -->
<!-- · 添加猪镇计时器 -->
<!--
添加计时：
月相(新月满月) √
海盗袭击计时 ×
巨大蠕虫概率 √
裂隙/裂隙晶体计时 √
梦魇疯猪和拾荒疯猪 √
洞穴地震 √
亮茄 √
墨荒 √
果蝇王 √
-->
<!-- · 添加永不妥协计时器 -->
<!-- · 兼容【模组设置】，游戏内可实时开关预测倒计时功能 -->

· 模组英语翻译
· 在modmain写上模组API说明


gettimefn
gettextfn

image = {
    atlas = "images/Hound.xml",
    tex = "Hound.tex",
    scale = 0.4,
    uioffset = { -- 决定在UI的偏移量
        x = 0, -- 左减右加
        y = 0, -- 上加下减
    },
    offset = { -- 决定在屏幕左上角的位置
        x = 0, -- 左减右加
        y = 0, -- 上加下减
    }
},
imagechangefn
forestimage
caveimage
islandimage
porklandimage
ChangeimageByWorld

anim = {
    bank = "malbatross",
    build = "malbatross_build",
    animation = "idle_loop",
    loop = true,
    scale = 0.04,
    uioffset = { -- 决定在UI的偏移量
        x = 0, -- 左减右加
        y = 0, -- 上加下减
    },
    offset = { -- 决定在屏幕左上角的位置
        x = 0, -- 左减右加
        y = 0, -- 上加下减
    },
    
    可选参数
    overridebuild：类型是数组表，为事件的额外材质(必须搭配动画使用，表内依次填入build名称即可) 参数等同AddOverrideBuild
    overridesymbol：类型是键值表，替换事件的symbol(必须搭配动画使用，表内依次填入包含原有symbol与目标build和目标symbol组成的表) 参数等同OverrideSymbol
    hidesymbol：类型是数组表，隐藏事件的symbol(必须搭配动画使用，表内依次填入symbol名称) 参数等同HideSymbol
    anim和image格式至少要选一个
},
animchangefn
forestanim
caveanim
islandanim
porklandanim
ChangeanimByWorld

winterfeastanim
defaultanim
ChangeanimByWintersFeast

announcefn
tipsfn -- 返回参数为 need_tips, tipstextfn, tipstime, delay




· 进行功能验收/BUG测试
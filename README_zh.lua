-- 如何把你的事件加入到本模组中？

-- 1.在GLOBAL.WarningEvents中添加一个表，名称随意。示例与各项说明如下

local TimeToString = GLOBAL.EventTimer.env.TimeToString -- 获取全局事件计时器模组的格式化时间函数(将纯数字转换为X天X分X秒)
local Upvaluehelper = GLOBAL.EventTimer.env.Upvaluehelper -- 全局事件计时器模组的getupvalue工具，文件位于 当前目录\scripts\utils\bbgoat_upvaluehelper.lua

-- 完整版示例
GLOBAL.WarningEvents.hounded = { -- 这个事件名称为 hounded，事件名称可以随便填，注意你的事件名不要和原模组的冲突
    gettimefn = function() -- gettimefn：服务器执行的函数，返回一个数字表示倒计时还有多少秒。屏幕左上角的常驻倒计时显示的数字来自于此，若没有此项则事件不能被勾选并常驻屏幕左上角
        if GLOBAL.TheWorld.components.hounded then
            local data = GLOBAL.TheWorld.components.hounded:OnSave()
            return data and data.timetoattack -- 返回猎犬袭击的倒计时时间。类型必须为number。 同时保存在客户端的 GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_time 表中（GLOBAL.ThePlayer.HUD.WarningEventTimeData是固定的前缀，hounded为这个事件的名称，_time是固定后缀
        end
    end,
             -- 此处传入的time是上方gettimefn返回的数字
    gettextfn = function(time) -- gettextfn：服务器执行的函数，决定事件计时器面板里显示的文本内容，若没有此项/没有返回值则面板里只显示时间（X天X分X秒）。
        if not GLOBAL.TheWorld:HasTag("cave") or not time then return end
        local self = GLOBAL.TheWorld.components.hounded
        if not self then return end

        local next_wave_is_wormboss = Upvaluehelper.FindUpvalue(self.DoWarningSpeech, "_wave_pre_upgraded") -- 使用工具搜索GLOBAL.TheWorld.components.hounded.DoWarningSpeech的上值 _wave_pre_upgraded
        local _wave_override_chance = self:OnSave().wave_override_chance

        if next_wave_is_wormboss then
            return string.format("巨大洞穴蠕虫将在%s后攻击", TimeToString(time))
        elseif type(_wave_override_chance) == "number" then
            return string.format("洞穴蠕虫将在%s后攻击\n巨大洞穴蠕虫概率：%s%%", TimeToString(time), _wave_override_chance * 100)
        end
        -- 返回的类型必须为string。内容会同时保存在客户端的 GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_text 表中（GLOBAL.ThePlayer.HUD.WarningEventTimeData是固定的前缀，hounded为这个事件的名称，_text是固定后缀
    end,

    -- gettimefn 和 gettextfn 至少二选一 ，同时存在时事件计时器UI优先显示text，屏幕左上角常驻内容只会显示time

    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    -- image = {
    --     atlas = "images/Hound.xml",
    --     tex = "Hound.tex",
    --     scale = 0.4, -- 缩放比例
    --     以下是可选参数
    --     offset = { -- 在屏幕左上角常驻显示的位置偏移量
    --        x = 0  -- 左减右加
    --        y = 0  -- 上加下减
    --     },
    --     uioffset = { -- 在事件计时器面板的位置偏移量
    --        x = 0  -- 左减右加
    --        y = 0  -- 上加下减
    --     },
    -- },

    -- imagechangefn，客户端执行的函数，这是一个可选函数，根据不同情况选择不同的image图片。如果你只有一种image则可以按照上面的格式直接指定
    imagechangefn = function(self)
        local text = GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_text -- 获取服务器执行gettextfn的返回结果（也就是事件计时器面板里显示的文本内容）
        local is_worm_boss = text and string.find(text, "巨大洞穴蠕虫将在") -- 由于imagechangefn在客户端执行，所以只能使用string的匹配方法来判断，客户端不能执行 gettimefn 和 gettextfn
        if GLOBAL.TheWorld:HasTag("porkland") then
            self.image = self.porklandimage
        elseif GLOBAL.TheWorld:HasTag("island") or GLOBAL.TheWorld:HasTag("volcano") then
            self.image = self.islandimage
        elseif is_worm_boss then
            self.image = self.wormbossimage
        elseif GLOBAL.TheWorld:HasTag("cave") then
            self.image = self.caveimage
        else
            self.image = self.forestimage
        end
    end,
    forestimage = { -- imagechangefn中用到的表
        atlas = "images/Hound.xml",
        tex = "Hound.tex",
        scale = 0.4,
    },
    caveimage = { -- imagechangefn中用到的表
        atlas = "images/Depths_Worm.xml",
        tex = "Depths_Worm.tex",
        scale = 0.25,
    },
    wormbossimage = { -- imagechangefn中用到的表
        atlas = "images/Worm_boss.xml",
        tex = "Worm_boss.tex",
        scale = 0.25,
    },

    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    -- anim = {
    --     scale = 0.099, -- 缩放比例
    --     bank = "hound", -- 库名
    --     build = "hound_ocean", -- 材质
    --     animation = "idle", -- 动画
    --     loop = true, -- 是否循环播放动画
    --     以下是可选参数
    --     offset = { -- 在屏幕左上角常驻显示的位置偏移量
    --        x = 0  -- 左减右加
    --        y = 0  -- 上加下减
    --     },
    --     uioffset = { -- 在事件计时器面板的位置偏移量
    --        x = 0  -- 左减右加
    --        y = 0  -- 上加下减
    --     },
    --     overridebuild   --类型是数组表，为事件的额外材质(必须搭配动画使用，表内依次填入build名称即可) 参数等同AddOverrideBuild
    --     overridesymbol   --类型是键值表，替换事件的symbol(必须搭配动画使用，表内依次填入包含原有symbol与目标build和目标symbol组成的表) 参数等同OverrideSymbol
    --     hidesymbol       --类型是数组表，隐藏事件的symbol(必须搭配动画使用，表内依次填入symbol名称) 参数等同HideSymbol
    -- },


    -- animchangefn，与imagechangefn类似，在客户端执行的函数，这是一个可选函数，根据不同情况选择不同的anim动画。如果只有一种anim则可以按照上面的格式直接指定
    animchangefn = function(self)
        if GLOBAL.TheWorld:HasTag("porkland") then
            self.anim = self.porklandanim
        elseif GLOBAL.TheWorld:HasTag("island") or GLOBAL.TheWorld:HasTag("volcano") then
            self.anim = self.islandanim
        elseif GLOBAL.TheWorld:HasTag("cave") then
            self.anim = self.caveanim
        else
            self.anim = self.forestanim
        end
    end,
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

    -- image 和 anim 至少二选一，否则没有图片，事件计时器面板优先显示image，其次显示anim的第一帧动画。屏幕左上角的常驻计时优先显示anim，否则显示image

    DisableShardRPC = true, -- 强制禁用此事件的跨世界同步计时功能，防止数据冲突，适用于多世界都有同一个事件的情况

    -- 宣告功能，在客户端执行的函数，这是一个可选函数，返回值类型是string，作用是在事件计时器面板点击该事件时进行宣告
    announcefn = function()
        local time = GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_time
        local text = GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_text
        return text ~= "" and text or time and string.format("猎犬将在%s后攻击", TimeToString(time))
    end,

    -- 醒目提示功能，在客户端执行的函数，这是一个可选函数，返回值依次为：布尔值(为true时触发提示，为false时不提示并重置状态)，提示信息内容（必须为一个返回字符串的函数），提示持续时间（数字类型，单位秒），延迟多久显示（数字类型，单位秒，可不填），消息等级(1-静默提醒-白色 2-声音提醒-黄色 3-声音提醒-红色)
    -- boolean, function->string, number, number|nil, number
    -- 示例：return true, function() return "text" end, 10, 10, 3
    tipsfn = function()
        local time = GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_time

        if time == 120 or (GLOBAL.GetTime() > 1 and GLOBAL.GetTime() < 10 and time > 0 and time < 960) then -- 其中GetTime是科雷的函数，返回的是游戏本次加载后到现在的运行时间，重载游戏/进出房间/穿越世界 就会归0
            return true, GLOBAL.WarningEvents.hounded.announcefn, 10, nil, 2 -- true表示可以提醒玩家了，WarningEvents.hounded.announcefn是上面的宣告函数，10表示提示持续10秒，2表示中等消息等级
        elseif time == 120 or (GLOBAL.GetTime() > 1 and GLOBAL.GetTime() < 10 and time > 0) then -- 与上面一条的区别是少了 time < 960
            return true, GLOBAL.WarningEvents.hounded.announcefn, 10, nil, 1 -- 消息等级比上面的低
        elseif time > 2 and time <= 90 then -- 第二种情况：猎犬袭击倒计时在2~90秒内
            return true, GLOBAL.WarningEvents.hounded.announcefn, time, nil, 2
        elseif time < 2 and time > 0 then -- 因为gettimefn获取不到猎犬袭击信息时，会被视作倒计时0秒，所以这里的time判断不能等于0
            return true, (function() return "警告：猎犬正在袭击" end), 10, time, 3 -- 第二个返回值必须是一个“返回字符串的函数”。第四个值是延迟多少秒显示，这里设置为time就能刚好在倒计时结束时发出警告
        end
        return false -- 其余情况返回一个false，重置状态
    end
}

-- 最小化示例
GLOBAL.WarningEvents.hounded = { -- 这个事件名称为 hounded，事件名称可以随便填，注意你的事件名不要和原模组的冲突
    -- gettimefn：服务器执行的函数，返回一个数字表示倒计时还有多少秒。
    gettimefn = function()
        if GLOBAL.TheWorld.components.hounded then
            local data = GLOBAL.TheWorld.components.hounded:OnSave()
            return data and data.timetoattack
        end
    end,
    anim = {
        scale = 0.099, -- 缩放比例
        bank = "hound", -- 库名
        build = "hound_ocean", -- 材质
        animation = "idle", -- 动画
    },
}

-- 2.使用GLOBAL.EventTimer.Register_Event("事件名")函数注册你的事件
-- 上面的事件名为hounded，所以注册的方法为
-- GLOBAL.EventTimer.Register_Event("hounded")


-- 总结：gettimefn/gettextfn 在服务器执行，imagechangefn/animchangefn/announcefn/tipsfn 在客户端执行，客户端无法调用 gettimefn/gettextfn

-- gettimefn/gettextfn 的返回类型和保存位置要严格遵守：
-- gettimefn 必须返回 number（秒），同名数据保存到 GLOBAL.ThePlayer.HUD.WarningEventTimeData.<event>_time。
-- gettextfn 必须返回 string，保存到 GLOBAL.ThePlayer.HUD.WarningEventTimeData.<event>_text

-- 事件写完后使用GLOBAL.EventTimer.Register_Event注册事件，传入的参数为事件名的字符串
-- 最后，将本模组和你的模组一起启用即可
-- 注意，你的模组加载应晚于本模组
-- 本模组的各事件记录在 main/warningevents.lua 里
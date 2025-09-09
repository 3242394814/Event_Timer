local AddPrefabPostInit = AddPrefabPostInit
local AddGamePostInit = AddGamePostInit
local ModLanguage = ModLanguage
local zh = ModLanguage == "zh"
GLOBAL.setfenv(1, GLOBAL)

-- 判断某个模组是否加载
local function Ismodloaded(name)
	return KnownModIndex:IsModEnabledAny(name)
end

----------------------------------------检测重复功能的模组---------------------------------------

local function checkmod()
    local tips = zh and "[全局事件计时器] 检测到你开启了 %s 模组，与本模组功能重复，请关闭它" or "[Global Events Timer] Detected that you have enabled the %s mod, which has overlapping functions with this mod. Please disable it."

    if Ismodloaded("workshop-1898292532") then
        local text = string.format(tips, zh and "[Tips]提示猎狗和BOSS的攻击时间 " or "[Tips]Show attack time for hounds and bosses")
        c_announce(text)
    end

    if Ismodloaded("workshop-3478447677") then
        local text = string.format(tips, zh and "[Tips]提示系统(优化不卡顿版)" or "[Tips]提示系统(优化版)")
        c_announce(text)
    end

    if Ismodloaded("workshop-3059131690") then
        local text = string.format(tips, zh and "[Tips]刷新提示，优化版" or "Tips Optimized")
        c_announce(text)
    end

    if Ismodloaded("workshop-3511498282") then
        local text = string.format(tips, zh and "饥饥事件计时器" or "Don't Event Timer")
        c_announce(text)
    end

    if Ismodloaded("workshop-3517520518") then
        local text = string.format(tips, zh and "饥饥事件计时器加强" or "Don't Event Timer Plus")
        c_announce(text)
    end

    if Ismodloaded("workshop-3127230863") then
        local text = string.format(tips, zh and "Boss生成倒计时" or "Boss Spawn Countdown")
        c_announce(text)
    end

    if Ismodloaded("workshop-2510473186") then
        local text = string.format(tips, zh and "Boss预测器" or "Boss Attack Predictor")
        c_announce(text)
    end
end

AddPrefabPostInit("world", function(inst)
    if TheNet:GetIsServer() then
        inst:DoTaskInTime(5, checkmod)
    end
end)


----------------------------------------兼容萌萌的新的模组设置---------------------------------------

AddGamePostInit(function()
    local HasMOD_util, MOD_util = pcall(require, "utils/MOD_util")
    local iszh = EventTimer.env.ModLanguage == "zh"
    local function ChangeModConfig(name, saved)
        local config = KnownModIndex:LoadModConfigurationOptions(EventTimer.env.modname, true)
        for i,v in pairs(config) do
            if v.name == name then
                config[i].saved = saved
            end
        end

        KnownModIndex:SaveConfigurationOptions(function() end, EventTimer.env.modname, config, true)
    end


    if HasMOD_util and MOD_util:CanAddSetting() then
        local pagename = iszh and "事件计时器" or "Events Timer"
        local pageorder = 1
        local buttonname = pagename
        local pagetitle = iszh and "全局事件计时器模组设置" or "Global Events Timer Config"
        local enabledisableoption = {
            { text = iszh and "开启" or "Enabled", data = true },
            { text = iszh and "关闭" or "Disabled", data = false },
        }
        MOD_util:CreatePage(pagename, {
            title = pagetitle,
            buttondata = { name = buttonname },
            order = pageorder,
            all_options = {
                {
                    description = iszh and "客户端预测倒计时" or "Client Predicted Countdown", -- 名称
                    key = "EventsTimer_ClientPrediction", -- 对应设置项
                    default = true, -- 默认选项
                    options = enabledisableoption, -- 选项列表
                    onapplyfn = function()
                        EventTimer.ClientPrediction = MOD_util:GetMOption("EventsTimer_ClientPrediction", true)
                        ChangeModConfig("ClientPrediction", EventTimer.ClientPrediction)
                    end
                },
                {
                    description = iszh and "醒目提示" or "Highlight Tips",
                    key = "EventsTimer_ShowTips",
                    default = true,
                    options = enabledisableoption,
                    onapplyfn = function()
                        EventTimer.TimerTips = MOD_util:GetMOption("EventsTimer_ShowTips", true)
                        ChangeModConfig("ShowTips", EventTimer.TimerTips)
                    end
                },
                {
                    description = iszh and "UI开关何时显示" or "UI Button Visibility",
                    key = "EventsTimer_UIButton",
                    default = "always",
                    options = {
                        {text = iszh and "始终显示" or "Always Visible", data = "always"},
                        {text = iszh and "在暂停页面显示" or "Pause Menu", data = "pause_screen"},
                    },
                    onapplyfn = function()
                        EventTimer.UIButton = MOD_util:GetMOption("EventsTimer_UIButton", true)
                        ChangeModConfig("UIButton", EventTimer.UIButton)

                        if ThePlayer and ThePlayer.HUD and ThePlayer.HUD.EventTimerButton then
                            ThePlayer.HUD.EventTimerButton:Refresh()
                        end
                    end
                }
            }
        }
        )
    elseif TheNet:GetIsClient() then
        print("[全局事件计时器] 未检测到玩家开启萌萌的新的【模组设置】","HasMOD_util = ", HasMOD_util)
    end
end)
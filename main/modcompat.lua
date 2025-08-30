local AddPrefabPostInit = AddPrefabPostInit
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
    inst:DoTaskInTime(5, checkmod)
end)
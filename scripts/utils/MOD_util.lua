local MOD_util = {}

local allplayerfn = {}
local allplayerfn_once = {}

---@param fn fun(world: TheWorld, player: ThePlayer): nil 
---@param onlyonce boolean|nil 本局游戏只运行一次？即使换人也不重新触发
function MOD_util:AddPlayerPostInit(fn, onlyonce) -- 好处是不用官方的any接口，作为客机时其它玩家不会触发PlayerPostInit
    if onlyonce then
        allplayerfn_once[fn] = true
    else
        allplayerfn[fn] = true
    end
end

AddPrefabPostInit("world", function(world)
    local a = true
    world:ListenForEvent("playeractivated", function(self, data)
        if a then
            a = false
            for fn, v in pairs(allplayerfn_once) do
                fn(self, data)
            end
        end
        for fn, v in pairs(allplayerfn) do
            fn(self, data)
        end
    end)
end)

--- @param str any 需要打印的内容
--- @param level number|nil
function MOD_util:Warning(str, level)
    local info = debug.getinfo(level or 2)
    local filename, line = info.source or "???", info.currentline or "???"
    print("[警告] " .. tostring(str) .. "\n本函数调用于 " .. tostring(filename) .. ":" .. tostring(line))
end

----------------------------------------兼容萌萌的新的模组设置---------------------------------------

local status, settingscreen = GLOBAL.pcall(require, "screens/settingsscreen")
--获取设置
function MOD_util:GetMOption(key, default)
    if GLOBAL.rawget(GLOBAL, "m_options") and GLOBAL.m_options[key] ~= nil then
        return GLOBAL.m_options[key]
    else
        return default
    end
end

--修改设置 自带判空
function MOD_util:ChangeMOption(key, v)
    if not GLOBAL.rawget(GLOBAL, "m_options") then return end
    GLOBAL.m_options[key] = v
end

--模组添加设置
function MOD_util:CanAddSetting()
    return status, settingscreen
end

function MOD_util:CreatePage(pagename, pagedata, forcecreate)
    if not MOD_util:CanAddSetting() then
        return
    end
    settingscreen:CreatePage(pagename, pagedata, forcecreate)
end

--
function MOD_util:StandardPage(pagename, buttonname, order, pagetitle)
    if not MOD_util:CanAddSetting() then
        return
    end
    settingscreen:StandardPage(pagename, buttonname, order, pagetitle)
end

function MOD_util:AddEnableDisableOption(pagename, key, default, description, hover)
    if not MOD_util:CanAddSetting() then
        return
    end
    if default == nil then
        default = true
    end
    settingscreen:AddEnableDisableOption(pagename, key, default, description, hover)
end

function MOD_util:AddKeyBinds(pagename, key, default, description, hover)
    if not MOD_util:CanAddSetting() then
        return
    end
    if default == nil then
        default = true
    end
    settingscreen:AddKeyBinds(pagename, key, default, description, hover)
end

function MOD_util:AddOption(pagename, key, options, default, description, hover)
    if not MOD_util:CanAddSetting() then
        return
    end
    if default == nil then
        default = true
    end
    settingscreen:AddOption(pagename, key, options, default, description, hover)
end

function MOD_util:GetKeyFromConfig(name)
    local a = GetModConfigData(name)
    return a and GLOBAL.rawget(GLOBAL, a)
end

return MOD_util
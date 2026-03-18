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

return MOD_util
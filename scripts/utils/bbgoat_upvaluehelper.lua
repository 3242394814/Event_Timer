-- 此lua文件由冰冰羊参考其它模组的upvaluehelper代码制作，并进行了功能完善，如果你想使用我这个版本的upvaluehelper，建议去模组Chinese++ Pro模组的scripts/utils文件夹下获取最新版的
-- 创意工坊：https://steamcommunity.com/sharedfiles/filedetails/?id=2941527805
-- GitLab：https://gitlab.com/bbgoat/chinese-pro/-/blob/Beta/scripts/utils/bbgoat_upvaluehelper.lua


-- 加载此文件可使用下面的示例代码
--[[
local function Import(modulename)
	local f = GLOBAL.kleiloadlua(modulename)
	if f and type(f) == "function" then
        setfenv(f, env.env)
        return f()
	end
end

Upvaluehelper = Import(MODROOT .. "scripts/utils/bbgoat_upvaluehelper.lua") or require("utils/bbgoat_upvaluehelper") -- 前者可以防止引用到其它模组的同名文件发生意外情况，后者可以使Vscode识别并显示函数提示。你可以二选一或者像我一样都写上
]]


-- 查看函数里有哪些上值，方便调试
-- 调用示例
--[[
	local a = 1
	local function fn()
		a = a + 1
		return a
	end
	Upvaluehelper.LookUpvalue(fn)
]]
--- @param fn function 要被显示所有上值的函数
local function LookUpvalue(fn)
	if type(fn) ~= "function" then return end
	local i = 0
	local _value
	local _name = ''

	while _name do
		i = i + 1
		_name, _value = debug.getupvalue(fn, i)
		print(i, _name, _value) -- 将找到的信息打印出来
	end
end

-- 遍历搜索上值
---@param fn function 被搜索的函数
---@param name string 要搜索的上值名
---@param maxlevel integer|nil 最大递归层数（默认 5）
---@param max integer|nil 每层最大搜索多少个上值（默认 20）
---@param level integer|nil 当前层数（建议默认，不要传）
---@param fnfile string|nil 限定搜索的函数必须来源于某个文件
---@param valuefile string|nil 限定找到的上值（如果是函数）必须来源于某个文件
---@return any 找到的上值
---@return integer 上值在函数中的索引
---@return function 拥有该上值的函数
local function FindUpvalue(fn, name, maxlevel, max, level, fnfile, valuefile)
	if type(fn) ~= "function" then return end
	maxlevel = maxlevel or 5 	--默认最多追5层
	level = level or 0    	--当前层数 建议默认
	max = max or 20       	--最大变量的upvalue的数量 默认20
	for i = 1, max, 1 do
		local upname, upvalue = debug.getupvalue(fn, i)
		if upname and upname == name then
			if type(fnfile) == "string" then --限定文件 防止被别人提前hook导致取错
				local fninfo = debug.getinfo(fn)
				local valueinfo = type(upvalue) == "function" and debug.getinfo(upvalue)

				if (fninfo.source and fninfo.source:match(fnfile)) and (not valuefile or (valueinfo and valueinfo.source:match(valuefile))) then
					return upvalue, i, fn
				else
					if level < maxlevel and type(upvalue) == "function" then
						local upupvalue, upupi, upupfn = FindUpvalue(upvalue, name, maxlevel, max, level + 1, fnfile, valuefile) --找不到就递归查找
						if upupvalue ~= nil then
							return upupvalue, upupi, upupfn
						end
					end
				end
			elseif type(valuefile) == "string" and type(upvalue) == "function" then -- 限定获取到的上值来自某个文件
				local valueinfo = debug.getinfo(upvalue)

				if valueinfo and valueinfo.source:match(valuefile) then
					return upvalue, i ,fn
				else
					if level < maxlevel then
						local upupvalue, upupi, upupfn = FindUpvalue(upvalue, name, maxlevel, max, level + 1, fnfile, valuefile) --找不到就递归查找
						if upupvalue ~= nil then
							return upupvalue, upupi, upupfn
						end
					end
				end
			else
				return upvalue, i, fn
			end
		end
		if level < maxlevel and type(upvalue) == "function" then
			local upupvalue, upupi, upupfn = FindUpvalue(upvalue, name, maxlevel, max, level + 1, fnfile, valuefile) --找不到就递归查找
			if upupvalue ~= nil then
				return upupvalue, upupi, upupfn
			end
		end
	end
	return nil
end

---@param fn function
---@param name string
---@return any
---@return integer
---@return function
local function GetUpvalueHelper(fn, name)
    local i = 1
    while debug.getupvalue(fn, i) and debug.getupvalue(fn, i) ~= name do
        i = i + 1
    end
    local _, value = debug.getupvalue(fn, i)
	if value == nil then
		local found_value, found_i, found_fn = FindUpvalue(fn, name)
		if found_value then
			return found_value, found_i, found_fn
		end
	end
    return value, i, fn
end

-- 搜索上值（找不到时自动遍历）
-- 基础debug教程：https://atjiu.github.io/dstmod-tutorial/#/debug
-- 调用示例
--[[
	local containers = require "containers"
	local params = Upvaluehelper.GetUpvalue(containers.widgetsetup, "params") -- 获取containers.widgetsetup的名为params的上值，必须在containers.widgetsetup，或者他调用的程序里使用到了params
	if params then
		params.cookpot.itemtestfn = function() ... end -- 因为返回值是表 可以直接操作 否则需要使用SetUpvalue
	end
]]
---@param fn function 被搜索的函数
---@param ... string 搜索路径
---@return any 找到的上值
---@return integer 上值在函数中的索引
---@return function 拥有该上值的函数
local function GetUpvalue(fn, ...)
    local prv, i, prv_var = nil, nil, "(起点)"
    for j,var in ipairs({...}) do
        assert(type(fn) == "function", "我们正在寻找 "..var..", 但在它之前的值 "
            ..prv_var.." 不是function (它是一个 "..type(fn)
            ..") 这是完整的链条: "..table.concat({"(起点)", ...}, "→"))
        prv_var = var
        fn, i, prv= GetUpvalueHelper(fn, var)
    end
    return fn, i, prv
end

-- 替换上值
-- 调用示例
--[[
	local containers = require "containers"
	local newtable = {}
	local params = Upvaluehelper.SetUpvalue(containers.widgetsetup, newtable, "params") -- 获取containers.widgetsetup的名为params的上值，然后替换为newtable
]]
---@param start_fn function 被搜索的函数
---@param new_fn any 新的上值
---@param ... string 搜索路径
local function SetUpvalue(start_fn, new_fn, ...)
    local _fn, _fn_i, scope_fn = GetUpvalue(start_fn, ...)
    debug.setupvalue(scope_fn, _fn_i, new_fn)
end

--- @param stack number
local function LookLocal(stack)
    local i = 1
	while true do
		local n, v = debug.getlocal(stack + 1, i)
		if not n then break end
		print(i, n, v)
		i = i + 1
	end
end

--- @param stack number
--- @param var_name string
--- @return boolean
--- @return any
--- @return integer
local function GetLocal(stack, var_name)
    local i = 1
	while true do
		local n, v = debug.getlocal(stack + 1, i)
		if not n then break end
		if n == var_name then
			return true, v, i
		end
		i = i + 1
	end
end

--- @param stack number
--- @param var_name string
--- @param new_val any
--- @return boolean
--- @return any
local function SetLocal(stack, var_name, new_val)
    local i = 1
	while true do
		local n, v = debug.getlocal(stack + 1, i)
		if not n then break end
		if n == var_name then
			debug.setlocal(stack + 1, i, new_val)
			return true, v
		end
		i = i + 1
	end
end

-- 检索api注入的fns或data
---@param name string 模组ID
---@param cat "ModShadersInit"|"ComponentPostInit"|"RecipePostInit"|"TaskSetPreInitAny"|"PrefabPostInit"|"GamePostInit"|"ModShadersSortAndEnable"|"RecipePostInitAny"|"LevelPreInit"|"PrefabPostInitAny"|"SimPostInit"|"RoomPreInit"|"StategraphPostInit"|"LevelPreInitAny"|"TaskPreInit"|"TaskSetPreInit" 使用的API
---@param id string|nil
---@param ... string|nil 需要查找的上值路径
---@return any
local function Getmoddata(name, cat, id, ...)
	local result = nil
	local mod = ModManager:GetMod(name)
	if mod and mod.postinitfns[cat] then
		if id then
			result = mod.postinitfns[cat][id]
		else
			result = mod.postinitfns[cat]
		end
	end

	if ... then
		if result and type(result) == "table" then
			for _,v in ipairs(result) do
				if type(v) == "function" then
					local val = GetUpvalue(v, ...)
					if val then return val end
				end
			end
		end
	else
		return result
	end
end

local function FunctionTest(fn, file, test, source, listener)
	if fn and type(fn) ~= "function" then return false end
	local data = debug.getinfo(fn)
	if file and type(file) == "string" then		--文件名判定
		local matchstr = "/"..file..".lua"
		if not data.source or not data.source:match(matchstr) then
			return false
		end
	end
	if test and type(test) == "function" and  not test(data,source,listener) then return false end	--测试通过
	return true
end

-- 获取指定事件的函数 并移除
-- 调用示例
--[[
	local fn = Upvaluehelper.GetEventHandle(TheWorld, "ms_lightwildfireforplayer", "components/wildfires")

	if fn then
		TheWorld:RemoveEventCallback("ms_lightwildfireforplayer", fn)
	end
]]
local function GetEventHandle(inst, event, file, test)
	if type(inst) == "table" then
		if inst.event_listening and inst.event_listening[event] then -- 遍历他在监听的事件 我在监听谁
			local listenings = inst.event_listening[event]
			for listening, fns in pairs(listenings) do -- 遍历被监听者
				if fns and type(fns) == "table" then
					for _, fn in pairs(fns) do
						if FunctionTest(fn, file, test, listening, inst) then -- 寻找成功就返回
							return fn
						end
					end
				end
			end
		end

		if inst.event_listeners and inst.event_listeners[event] then -- 遍历监听他的事件的 谁在监听我
			local listeners = inst.event_listeners[event]
			for listener, fns in pairs(listeners) do -- 遍历监听者
				if fns and type(fns) == "table" then
					for _, fn in pairs(fns) do
						if FunctionTest(fn, file, test, inst, listener) then -- 寻找成功就返回
							return fn
						end
					end
				end
			end
		end
	end
end

-- 补充一下风铃草大佬没写的关于世界监听函数,随便写的,感觉太菜就憋着别说 -- 咸鱼说的
local function GetWorldHandle(inst, var, file)
	if type(inst) == "table" then
		local watchings = inst.worldstatewatching and inst.worldstatewatching[var] or nil
		if watchings then
			for _, fn in pairs(watchings) do
				if FunctionTest(fn, file) then -- 寻找成功就返回
					return fn
				end
			end
		end
		-- 另一个获取的路径是 TheWorld.components.worldstate 不过没差了
	end
end

return {
	LookUpvalue = LookUpvalue,
	FindUpvalue = FindUpvalue,
	GetUpvalue = GetUpvalue,
	SetUpvalue = SetUpvalue,
	LookLocal = LookLocal,
	GetLocal = GetLocal,
	SetLocal = SetLocal,
	Getmoddata = Getmoddata,
	GetEventHandle = GetEventHandle,
	GetWorldHandle = GetWorldHandle,
}
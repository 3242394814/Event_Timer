-- 此lua文件由冰冰羊参考其它模组的upvaluehelper.lua代码制作而成，如果你想使用我这个版本的upvaluehelper，建议去模组Chinese++ Pro模组的scripts/utils文件夹下获取最新版的
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2941527805
GLOBAL.setfenv(1, GLOBAL)
-- 查看函数里有哪些上值，方便调试
--- @param fn function
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

---@param fn function
---@param name string
---@param maxlevel integer|nil
---@param max integer|nil
---@param level integer|nil
---@param fnfile string|nil
---@param valuefile string|nil
---@return any
---@return integer
---@return function
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

---@param fn function
---@param ... string
---@return any
---@return integer
---@return function
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

---@param start_fn function
---@param new_fn any
---@param ... string
local function SetUpvalue(start_fn, new_fn, ...)
    local _fn, _fn_i, scope_fn = GetUpvalue(start_fn, ...)
    debug.setupvalue(scope_fn, _fn_i, new_fn)
end

-- 检索api注入的fns或data
---@param name string
---@param cat "ModShadersInit"|"ComponentPostInit"|"RecipePostInit"|"TaskSetPreInitAny"|"PrefabPostInit"|"GamePostInit"|"ModShadersSortAndEnable"|"RecipePostInitAny"|"LevelPreInit"|"PrefabPostInitAny"|"SimPostInit"|"RoomPreInit"|"StategraphPostInit"|"LevelPreInitAny"|"TaskPreInit"|"TaskSetPreInit"
---@param id string
---@param path string|nil
local function Getmoddata(name, cat, id, path)
	local result = nil
	local mod = ModManager:GetMod(name)
	if mod and mod.postinitfns[cat] then
		if id then
			result = mod.postinitfns[cat][id]
		else
			result = mod.postinitfns[cat]
		end
	end

	if path then
		if result and type(result)=="table" then
			for _,v in ipairs(result) do
				if type(v) == "function" then
					local val = GetUpvalue(v, path)
					if val then return val end
				end
			end
		end
	else
		return result
	end
end


local function FunctionTest(fn,file,test,source,listener)
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


--调用示例 获取指定事件的函数 并移除
--[[
	local fn = Upvaluehelper.GetEventHandle(TheWorld,"ms_lightwildfireforplayer","components/wildfires")

	if fn then
		TheWorld:RemoveEventCallback("ms_lightwildfireforplayer",fn)
	end
]]

local function GetEventHandle(inst,event,file,test)
	if type(inst) == "table" then
		if inst.event_listening and inst.event_listening[event] then		--遍历他在监听的事件 我在监听谁
			local listenings = inst.event_listening[event]
			for listening,fns in pairs(listenings) do		--遍历被监听者
				if fns and type(fns)=="table" then
					for _,fn in pairs(fns) do
						if FunctionTest(fn,file,test,listening,inst) then	--寻找成功就返回
							return fn
						end
					end
				end
			end
		end

		if inst.event_listeners and inst.event_listeners[event] then	--遍历监听他的事件的	谁在监听我
			local listeners = inst.event_listeners[event]
			for listener,fns in pairs(listeners) do		--遍历监听者
				if fns and type(fns)=="table" then
					for _,fn in pairs(fns) do
						if FunctionTest(fn,file,test,inst,listener) then	--寻找成功就返回
							return fn
						end
					end
				end
			end
		end
	end
end

local function GetWorldHandle(inst,var,file) --补充一下风铃草大佬没写的关于世界监听函数,随便写的,感觉太菜就憋着别说 --咸鱼说的
	if type(inst) == "table" then
		local watchings = inst.worldstatewatching and inst.worldstatewatching[var] or nil
		if watchings then
			for _,fn in pairs(watchings) do
				if FunctionTest(fn,file) then --寻找成功就返回
					return fn
				end
			end
		end
		--另一个获取的路径是 TheWorld.components.worldstate,不过没差了
	end
end

return {
	LookUpvalue = LookUpvalue,
	FindUpvalue = FindUpvalue,
	GetUpvalue = GetUpvalue,
	SetUpvalue = SetUpvalue,
	Getmoddata = Getmoddata,
	GetEventHandle = GetEventHandle,
	GetWorldHandle = GetWorldHandle,
}
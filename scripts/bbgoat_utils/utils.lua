function Import(file_name, file_env)
	local f = GLOBAL.kleiloadlua(file_name)
	if f and type(f) == "function" then
        GLOBAL.setfenv(f, file_env or env)
        return f()
	end
end

local function require_util(file_name, file_env)
	file_name = MODROOT .. "scripts/bbgoat_utils/" .. file_name
	return Import(file_name, file_env)
end

PersistentData = require_util("persistentdata.lua")
Upvaluehelper = require_util("bbgoat_upvaluehelper.lua", GLOBAL)
MOD_util = require_util("MOD_util.lua")
BBGOAT_util = require_util("BBGOAT_util.lua")
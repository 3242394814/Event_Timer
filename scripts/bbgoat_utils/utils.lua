function Import(file_name, file_env)
	local f = GLOBAL.kleiloadlua(file_name)
	if f and type(f) == "function" then
        GLOBAL.setfenv(f, file_env or env)
        return f()
	end
end

Upvaluehelper = Import(MODROOT .. "scripts/bbgoat_utils/bbgoat_upvaluehelper.lua", GLOBAL)
MOD_util = Import(MODROOT .. "scripts/bbgoat_utils/MOD_util.lua")
BBGOAT_util = Import(MODROOT .. "scripts/bbgoat_utils/BBGOAT_util.lua")
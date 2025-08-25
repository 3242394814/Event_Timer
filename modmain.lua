local function Import(modulename)
	local f = GLOBAL.kleiloadlua(modulename)
	if f and type(f) == "function" then
        GLOBAL.setfenv(f, env.env)
        return f()
	end
end

Upvaluehelper = Import(MODROOT .. "scripts/utils/bbgoat_upvaluehelper.lua")

AddReplicableComponent("waringtimer")

local IA_CONFIG = GLOBAL.rawget(GLOBAL, "IA_CONFIG")
if IA_CONFIG then
	IA_CONFIG.pondfishable = false
end

GLOBAL.TimerMode = GetModConfigData("BossTimer") -- 倒计时格式

modimport("main/commands")
modimport("main/waringevent")
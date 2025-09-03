local AddPrefabPostInit = AddPrefabPostInit
GLOBAL.setfenv(1, GLOBAL)


local TimerPrefabList = {
    "antlion",
    "dragonfly_spawner",
    "beequeenhive",
    "terrarium",
    "crabking_spawner",
    "crabking_spawner",
    "atrium_gate",
    "lunarrift_portal", -- 月亮裂隙
    "shadowrift_portal", -- 暗影裂隙
    "pugalisk_fountain", -- 猪镇：不老泉
}

TimerPrefabs = {}
for _, prefab in ipairs(TimerPrefabList) do
    AddPrefabPostInit(prefab, function(inst)
        if not TheWorld.ismastersim then
            return
        end

        TimerPrefabs[prefab] = inst

        inst:ListenForEvent("onremove", function()
            TimerPrefabs[prefab] = nil
        end)
    end)
end
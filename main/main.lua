-- main, what can i say?

-- 本地预测时间数据
for k, v in pairs(GLOBAL.ClientWarningEvents) do
    if not (GLOBAL.EventTimer.GetTimeFromServerMod[k] or GLOBAL.EventTimer.GetTimeFromRemoteCommand) then
        if v.localgettimefn then
            v.localgettimefn()
        end
    end
end

local function check_ThePlayer()
    local ThePlayer = GLOBAL.ThePlayer
    return ThePlayer and ThePlayer.HUD and ThePlayer.HUD.WarningEventTimeData ~= nil
end

MOD_util:AddPlayerPostInit(function(world, player)
    if player ~= GLOBAL.ThePlayer then return end
    -- 从远程命令获取时间数据
    if GLOBAL.EventTimer.GetTimeFromRemoteCommand then
        local MainThread
        local GetTimeThreadList, GetTextThreadList = {}, {}
        local MainFn = function()
            -- 首次加载（快速初始化）
            for warningevent, data in pairs(GLOBAL.ClientWarningEvents) do
                if data.remotegettimefn and (not GLOBAL.EventTimer.GetTimeFromServerMod[warningevent] or data.ForceEnableRemotegettimefn) then
                    data.remotegettimefn()
                    GLOBAL.Sleep(0.1)
                end
                if data.remotegettextfn and (not GLOBAL.EventTimer.GetTimeFromServerMod[warningevent] or data.ForceEnableRemotegettextfn) then
                    data.remotegettextfn()
                    GLOBAL.Sleep(0.1)
                end
            end

            -- 后续更新
            for warningevent, data in pairs(GLOBAL.ClientWarningEvents) do
                if data.remotegettimefn and (not GLOBAL.EventTimer.GetTimeFromServerMod[warningevent] or data.ForceEnableRemotegettimefn) then
                    GetTimeThreadList[warningevent] = GLOBAL.StartThread(function()
                        local co = GLOBAL.coroutine.running()
                        while true do
                            if not GLOBAL.scheduler.tasks[co] then break end
                            if check_ThePlayer() then
                                -- print("DEBUG: 正在触发事件" .. warningevent .. "的远程timefn")
                                data.remotegettimefn(GetTimeThreadList[warningevent]) -- 存数据的过程应该在fn内完成
                            end

                            if not GLOBAL.scheduler.tasks[co] then break end
                            GLOBAL.Sleep(0.5) -- 等待0.5秒以便sleep_time更新
                            local sleep_time = GLOBAL.type(data.remotegettimefninterval) == "number" and data.remotegettimefninterval
                                                or GLOBAL.type(data.remotegettimefninterval) == "function" and check_ThePlayer() and data.remotegettimefninterval()
                            -- print('DEBUG: remotegettimefn sleep', sleep_time, warningevent)
                            GLOBAL.Sleep(GLOBAL.checknumber(sleep_time) and sleep_time or 30)
                        end
                    end, "EventTimerModGetTimeFromRemoteCommand_" .. warningevent)

                    GLOBAL.Sleep(0.5) -- gettime 和 gettext 间隔0.5秒
                end
                if data.remotegettextfn and (not GLOBAL.EventTimer.GetTimeFromServerMod[warningevent] or data.ForceEnableRemotegettextfn) then
                    GetTextThreadList[warningevent] = GLOBAL.StartThread(function()
                        local co = GLOBAL.coroutine.running()
                        while true do
                            if not GLOBAL.scheduler.tasks[co] then break end
                            if check_ThePlayer() then
                                -- print("DEBUG: 正在触发事件" .. warningevent .. "的远程textfn")
                                data.remotegettextfn(GetTextThreadList[warningevent]) -- 存数据的过程应该在fn内完成
                            end

                            if not GLOBAL.scheduler.tasks[co] then break end
                            GLOBAL.Sleep(0.5) -- 等待0.5秒以便sleep_time更新
                            local sleep_time = GLOBAL.type(data.remotegettextfninterval) == "number" and data.remotegettextfninterval
                                                or GLOBAL.type(data.remotegettextfninterval) == "function" and check_ThePlayer() and data.remotegettextfninterval()
                            -- print('DEBUG: remotegettextfn sleep', sleep_time, warningevent)
                            GLOBAL.Sleep(GLOBAL.checknumber(sleep_time) and sleep_time or 30)
                        end
                    end, "EventTimerModGetTextFromRemoteCommand_" .. warningevent)

                    GLOBAL.Sleep(1) -- 每个事件至少间隔1秒请求
                end
            end

            -- 主线程执行完成，自我销毁
            print("[全局事件计时器 - 客户端版] 初始化远程请求线程完成")
            GLOBAL.KillThreadsWithID(MainThread.id)
            MainThread = nil
        end

        function GetRemoteThreadList() -- 用于给其它代码获取线程列表
            return GetTimeThreadList, GetTextThreadList
        end

        local function fn()
            local cmd = [[
                local code_version = 1
                if not rawget(_G, "EventTimerClient") or not _G.EventTimerClient.version or _G.EventTimerClient.version < code_version then
                    rawset(_G, "EventTimerClient" , {})
                    _G.EventTimerClient.version = code_version
                    _G.EventTimerClient.TimerPrefabs = {}
                    local function HookPrefab(prefab)
                        for guid, ent in pairs(Ents) do
                            if ent.prefab == prefab then
                                _G.EventTimerClient.TimerPrefabs[prefab] = ent
                                ent:ListenForEvent("onremove", function()
                                    _G.EventTimerClient.TimerPrefabs[prefab] = nil
                                end)
                                return ent
                            end
                        end
                    end
                    _G.EventTimerClient.HookPrefab = HookPrefab
                    _G.EventTimerClient.GetWorldSettingsTimeLeft = function(name, prefab)
                        local ent = TheWorld
                        if prefab then
                            ent = _G.EventTimerClient.TimerPrefabs[prefab] or HookPrefab(prefab)
                        end
                        if ent and ent.components.worldsettingstimer then
                            if not ent.components.worldsettingstimer:IsPaused(name) then
                                local time = ent.components.worldsettingstimer:GetTimeLeft(name)
                                return time or 0
                            end
                        end
                        return 0, true
                    end
                end
                return DataDumper({success = true})
            ]]
            BBGOAT_util:remote(cmd, nil, function(res)
                if res and res.err then
                    print("[警告] 在服务器初始化EventTimerClient失败：\n" .. tostring(res.err))
                elseif res and res.success then
                    MainThread = GLOBAL.StartThread(MainFn, "EventTimerModMainThread")
                    print("[全局事件计时器 - 客户端版] 正在初始化远程请求线程")
                end
            end) -- 初始化工具
        end
        player:DoTaskInTime(1, fn)

        -- 支持后加载
        if rawget(_G, "GetedAdminPostInitFns") then
            table.insert(_G.GetedAdminPostInitFns, function()
                if MainThread then
                    GLOBAL.KillThreadsWithID(MainThread.id)
                    MainThread = nil
                end
                for warningevent, thread in pairs(GetTimeThreadList) do
                    GLOBAL.KillThreadsWithID(thread.id)
                    GetTimeThreadList[warningevent] = nil
                end
                for warningevent, thread in pairs(GetTextThreadList) do
                    GLOBAL.KillThreadsWithID(thread.id)
                    GetTextThreadList[warningevent] = nil
                end
                fn()
            end)
        end
    end
end, true) -- 换人后不重复执行

-- 更新面板UI标题
local remote_mode = GLOBAL.EventTimer.GetTimeFromRemoteCommand
local from_server_mod_mode
for _ in pairs(GLOBAL.EventTimer.GetTimeFromServerMod) do
    from_server_mod_mode = true
    break
end

if ModLanguage == "zh" then
    GLOBAL.STRINGS.eventtimer.ui_title = "事件计时器 (" .. (remote_mode and "服务器数据" or from_server_mod_mode and "服务器模组 + 本地预测" or "本地预测") .. ")"
elseif ModLanguage == "en" then
    GLOBAL.STRINGS.eventtimer.ui_title = "Event Timer (" .. (remote_mode and "Server Data" or from_server_mod_mode and "Server Mod + Local Prediction" or "Local Prediction") .. ")"
end
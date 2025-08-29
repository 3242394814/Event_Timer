local AddClassPostConstruct = AddClassPostConstruct
local AddPrefabPostInit = AddPrefabPostInit
local MODROOT = MODROOT
local modimport = modimport
local Import = Import
GLOBAL.setfenv(1, GLOBAL)

modimport("main/waringevents")
local WaringEvent = require("widgets/waringevent")
local WaringTips = require("widgets/waringtips")
local game_ready = false

local function AddWaringEvents(self)
    self.inst:DoTaskInTime(2,function()
        game_ready = true
    end)

    self.WaringEventTimeData = {}

    for waringevent, data in pairs(WaringEvents) do
        self[waringevent] = self:AddChild(WaringEvent(data.anim))
        self[waringevent]:Hide()
        self[waringevent].force = EventTimer.env.RW_Data:LoadData()[waringevent] -- 读取存储的数据来决定是否显示计时器在屏幕左上角
    end

    -- 屏幕左上角提示（出现时伴随提示音）
    local waringtips_messages = {}
    local msgnum = 0

    function self:ShowTips(timefn, second)
        if not EventTimer.TimerTips then return end -- 判断模组设置是否开启了醒目提示功能
        if type(timefn) ~= "function" then return end
        -- 创建新的 widget
        local message = self:AddChild(WaringTips(self.owner, timefn(), msgnum))

        -- 插入到旧消息列表
        table.insert(waringtips_messages, message)

        -- 启动定时器
        message.inst:DoPeriodicTask(0.5, function() -- 更新倒计时时间
            message:OnUpdate(timefn())
        end)

        message.inst:DoTaskInTime((second or 10) - 0.5, function() -- 更新透明度
            message.AlphaMode = false
        end)

        message.inst:DoTaskInTime(second or 10, function() -- 定时销毁
            message:Kill()
            for i = #waringtips_messages, 1, -1 do
                local msg = waringtips_messages[i]
                if msg == message then
                    table.remove(waringtips_messages, i)
                elseif msg and msg.Move then
                    msg:Move()
                end
            end
            msgnum = msgnum - 1
        end)

        msgnum = msgnum + 1
    end

    ---------------------------------------------------------------------------------------------------------------

    -- 屏幕左上角倒计时
    function self:UpdateWaringEvents()
        local eventsdata = self.WaringEventTimeData
        local i = 0
        local line_num = 2
        local scale = TheFrontEnd:GetHUDScale()
        for waringevent, data in pairs(WaringEvents) do
            local row = math.floor(i/line_num)
            local line = i - row * line_num
            local x = (row * 150 + 80) * scale
            local y = (-line * 70 - 30) * scale

            self[waringevent]:SetPosition(x, y, 0)
            local time = eventsdata[waringevent .. "_time"] -- 屏幕左上角倒计时只显示time，不显示text，因为text内容太多

            if self[waringevent].last_time == time then
                self[waringevent].sametick = (self[waringevent].sametick or 0) + 1
            else
                self[waringevent].sametick = 0
            end

            if data.gettimefn then
                if not self[waringevent].force or ((time and time <= 0)or self[waringevent].sametick >= 100) then
                    if self[waringevent].shown then
                        self[waringevent]:Hide()
                    end
                else
                    if not self[waringevent].shown then
                        if data.animchangefn then
                            data:animchangefn()
                            self[waringevent]:SetEventAnim(data.anim)
                        end
                        self[waringevent]:Show()
                    end
                    self[waringevent].last_time = time

                    self[waringevent]:OnUpdate(time)

                    i = i + 1
                end
            end

            if time and data.tipsfn and game_ready then
                local need_tips, tipstextfn, tipstime, delay = data.tipsfn()
                self[waringevent].last_tips = self[waringevent].last_tips or false
                if need_tips and not self[waringevent].last_tips then
                    self[waringevent].last_tips = true
                    if delay and TheWorld then
                        TheWorld:DoTaskInTime(delay, function() -- 延迟提示
                            self:ShowTips(tipstextfn, tipstime)
                        end)
                    else
                        self:ShowTips(tipstextfn, tipstime)
                    end
                elseif not need_tips then
                    self[waringevent].last_tips = false
                end
            end
        end
    end
end

AddClassPostConstruct("screens/playerhud", AddWaringEvents)

local network_worlds = {
    "forest",
    "cave",
    "shipwrecked",
    "volcanoworld",
    "porkland"
}

for i, world in ipairs(network_worlds) do
    AddPrefabPostInit(world .. "_network", function(inst)
        if not TheWorld.ismastersim then
            return
        end

        inst:AddComponent("waringtimer")
    end)
end

local TEMPLATES = require "widgets/redux/templates"
local TarnsferPanel = require("screens/WaringEventHUD")
local function AddWaringEventsHUD(self)
    -- 在屏幕顶部添加一个按钮，用来触发面板的显示与关闭
    self.openbutton = self:AddChild(TEMPLATES.StandardButton(function() self:ChangeTransferPanelState() end , "打开", {100, 50}))
    self.openbutton:SetPosition(0, -40, 0)
    self.openbutton:SetVAnchor(ANCHOR_TOP)
    self.openbutton:SetHAnchor(ANCHOR_MIDDLE)
    self.openbutton:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.openbutton:SetMaxPropUpscale(MAX_HUD_SCALE)

    function self:ChangeTransferPanelState()
        self:ShowTarnsferPanel()
    end

    -- 显示面板
    self.ShowTarnsferPanel = function(_, attach)
        self.transferpanel = TarnsferPanel(self.owner)
        self:OpenScreenUnderPause(self.transferpanel)
        return self.transferpanel
    end

    -- 关闭面板
    self.CloseTarnsferPanel = function(_)
        if self.transferpanel then
            self.transferpanel:Close()
            self.transferpanel = nil
        end
    end
end

AddClassPostConstruct("screens/playerhud", AddWaringEventsHUD)
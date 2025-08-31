local AddClassPostConstruct = AddClassPostConstruct
local AddPrefabPostInit = AddPrefabPostInit
local modimport = modimport
local RW_Data = RW_Data
GLOBAL.setfenv(1, GLOBAL)

modimport("main/waringevents")
local WaringEvent = require("widgets/waringevent")
local WaringTips = require("widgets/waringtips")
local game_ready = false

local function AddWaringEvents(self)
    self.inst:DoTaskInTime(2,function()
        game_ready = true
    end)

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
    self.WaringEventTimeData = {}
    local save_data = EventTimer.env.RW_Data:LoadData()
    for waringevent, data in pairs(WaringEvents) do
        self[waringevent] = self:AddChild(WaringEvent(data.anim, data.image))
        self[waringevent]:Hide()
        self[waringevent].force = save_data[waringevent] -- 读取存储的数据来决定是否显示计时器在屏幕左上角
    end

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
                        elseif data.imagechangefn then
                            data:imagechangefn()
                            self[waringevent]:SetEventImage(data.image)
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

---------------------------------------------------------------------------------------------------------------

local TarnsferPanel = require("widgets/WaringEventUI")
local UIAnim = require "widgets/uianim"
local Button = require("widgets/button")
local EventUIButton = Class(Button, function(self, owner)
    Button._ctor(self)
    self.owner = owner

    self:SetVAnchor(ANCHOR_RIGHT)
    self:SetHAnchor(ANCHOR_BOTTOM)

    -- 在屏幕顶部添加一个按钮，用来触发面板的显示与关闭
    self.openbutton = self:AddChild(UIAnim())

    -- 设置位置
    local save_data = RW_Data:LoadData()
    if save_data.pos and save_data.pos.x and save_data.pos.y then
        self.openbutton:SetPosition(save_data.pos.x, save_data.pos.y , 0)
    else
        self.openbutton:SetPosition(-75, 250 , 0)
    end

    -- 动画
    self.openbutton:GetAnimState():SetBuild("pocketwatch_marble")
    self.openbutton:GetAnimState():SetBank("pocketwatch")
    self.openbutton:GetAnimState():PlayAnimation("cooldown_long", true)
    self.openbutton:GetAnimState():Pause() -- 默认暂停动画
    self.openbutton:SetScale(0.45, 0.45) -- 设置缩放比
    self.openbutton:SetHoverText("事件计时器\n右键拖拽", { offset_y = 70 })
    self.openbutton.hovertext:SetScale(0.9,0.9) -- 重新设置提示大小

    self:SetClickable(true)
    self:SetOnClick(function()
        self:ToggleEventTimerUI()
    end)

    -- 鼠标右键拖拽
    self.openbutton.OnMouseButton = function(_self, button, down, x, y)
        if button == MOUSEBUTTON_RIGHT and down then
            _self:FollowMouse()
            _self.hovertext_root:Hide()
            _self.hovertext:Hide()
        elseif button == MOUSEBUTTON_RIGHT then
            _self:StopFollowMouse()
            local pos = _self:GetPosition()
            local world_pos = _self:GetWorldPosition()

            _self.hovertext_root:Show()
            _self.hovertext_root:SetPosition(world_pos.x, world_pos.y + 70)
            _self.hovertext:Show()

            save_data = RW_Data:LoadData()
            save_data.pos = { x = pos.x, y = pos.y}
            RW_Data:SaveData(save_data)
            save_data = nil
        end
    end
end)

function EventUIButton:OnGainFocus() -- 鼠标对准时播放动画
    self.openbutton:GetAnimState():Resume()
end

function EventUIButton:OnLoseFocus() -- 鼠标离开时暂停动画
    self.openbutton:GetAnimState():Pause()
end

-- 开关面板
function EventUIButton:ToggleEventTimerUI()
    if self.eventui then
        self.eventui:Close()
        self.eventui = nil
    else
        self.eventui = self.owner:AddChild(TarnsferPanel(self.owner))
    end
end

local function AddWaringEventsHUD(self)
    self.EventTimerButton = self:AddChild(EventUIButton(self))
end

AddClassPostConstruct("screens/playerhud", AddWaringEventsHUD)
local AddClassPostConstruct = AddClassPostConstruct
local AddPrefabPostInit = AddPrefabPostInit
local modimport = modimport
local RW_Data = RW_Data
GLOBAL.setfenv(1, GLOBAL)

modimport("main/warningevents")
local WarningEvent = require("widgets/warningevent")
local WarningTips = require("widgets/warningtips")
local game_ready = false

local function AddWarningEvents(self)
    self.inst:DoTaskInTime(2,function()
        game_ready = true
    end)

    local warningtips_messages = {}
    local function sort_message()
        for i, msg in ipairs(warningtips_messages) do
            local w, h = msg.text:GetRegionSize() -- 获取当前消息文字区域大小
            msg.target_x = w + 40

            if i > 1 then -- 其它消息，依次根据上个消息的位置调整坐标
                local up_y = warningtips_messages[i - 1].target_y
                local up_w, up_h = warningtips_messages[i - 1].text:GetRegionSize()
                msg.target_y = up_y - up_h - h - 50
            else
                msg.target_y = msg.base_y -- 第一条消息，Y轴设为基础坐标
            end

            local pos = msg:GetPosition()
            msg:MoveTo(
                { x = pos.x, y = pos.y, z = 0 },
                { x = msg.target_x, y = msg.target_y, z = 0},
                0.5,
                nil
            )
        end
    end

    -- 醒目提示
    function self:ShowTips(timefn, second)
        if not EventTimer.TimerTips then return end -- 判断模组设置是否开启了醒目提示功能
        if type(timefn) ~= "function" then return end

        -- 获取上一条消息的信息
        local up_info = #warningtips_messages > 0 and warningtips_messages[#warningtips_messages]

        local message = self:AddChild(WarningTips(timefn(), up_info)) -- 创建新的 widget

        -- 插入到旧消息列表
        table.insert(warningtips_messages, message)

        -- 启动定时器
        message.inst:DoPeriodicTask(0.5, function() -- 更新倒计时时间
            message.text:SetString(timefn())
            local w, h = message.text:GetRegionSize() -- 获取文字区域大小
            message.bg:SetSize( -- 刷新背景大小
                w + 5,
                h
            )

            sort_message() -- 整理所有消息
        end)

        -- 更新透明度
        message.inst:DoTaskInTime((second or 10) - 0.5, function()
            message.AlphaMode = false
        end)

        -- 定时销毁与整理其它消息
        message.inst:DoTaskInTime(second or 10, function()
            message:Kill()
            for i = #warningtips_messages, 1, -1 do
                local msg = warningtips_messages[i]
                if msg == message then
                    table.remove(warningtips_messages, i)
                    break
                end
            end

            sort_message()
        end)
    end

    ---------------------------------------------------------------------------------------------------------------

    -- 屏幕左上角倒计时
    self.WarningEventTimeData = {}
    local save_data = EventTimer.env.RW_Data:LoadData()
    for warningevent, data in pairs(WarningEvents) do
        self[warningevent] = self:AddChild(WarningEvent(data.anim, data.image))
        self[warningevent]:Hide()
        self[warningevent].force = save_data[warningevent] -- 读取存储的数据来决定是否显示计时器在屏幕左上角
    end

    function self:UpdateWarningEvents()
        local eventsdata = self.WarningEventTimeData
        local i = 0
        local line_num = 2
        local scale = TheFrontEnd:GetHUDScale()
        for warningevent, data in pairs(WarningEvents) do
            local row = math.floor(i/line_num)
            local line = i - row * line_num
            local x = (row * 150 + 80) * scale
            local y = (-line * 70 - 30) * scale

            self[warningevent]:SetPosition(x, y, 0)
            local time = eventsdata[warningevent .. "_time"] -- 屏幕左上角倒计时只显示time，不显示text，因为text内容太多

            -- if self[warningevent].last_time == time then
            --     self[warningevent].sametick = (self[warningevent].sametick or 0) + 1
            -- else
            --     self[warningevent].sametick = 0
            -- end

            if data.gettimefn then
                if not self[warningevent].force or ((not time or time and time <= 0) --[[or self[warningevent].sametick >= 100]]) then
                    if self[warningevent].shown then
                        self[warningevent]:Hide()
                    end
                else
                    if not self[warningevent].shown then
                        if data.animchangefn then
                            data:animchangefn()
                            self[warningevent]:SetEventAnim(data.anim)
                        elseif data.imagechangefn then
                            data:imagechangefn()
                            self[warningevent]:SetEventImage(data.image)
                        end
                        self[warningevent]:Show()
                    end
                    -- self[warningevent].last_time = time

                    self[warningevent]:OnUpdate(time)

                    i = i + 1
                end
            end

            if time and data.tipsfn and game_ready then
                local need_tips, tipstextfn, tipstime, delay = data.tipsfn()
                self[warningevent].last_tips = self[warningevent].last_tips or false
                if need_tips and not self[warningevent].last_tips then
                    self[warningevent].last_tips = true
                    if delay and TheWorld then
                        TheWorld:DoTaskInTime(delay, function() -- 延迟提示
                            self:ShowTips(tipstextfn, tipstime)
                        end)
                    else
                        self:ShowTips(tipstextfn, tipstime)
                    end
                elseif not need_tips then
                    self[warningevent].last_tips = false
                end
            end
        end
    end
end

AddClassPostConstruct("screens/playerhud", AddWarningEvents)

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

        inst:AddComponent("warningtimer")
    end)
end

---------------------------------------------------------------------------------------------------------------

local TarnsferPanel = require("widgets/WarningEventUI")
local UIAnimButton = require("widgets/uianimbutton")
local Button = require("widgets/button")
local EventUIButton = Class(Button, function(self, owner)
    Button._ctor(self)
    self.owner = owner

    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetVAnchor(ANCHOR_RIGHT)
    self:SetHAnchor(ANCHOR_BOTTOM)

    -- 在屏幕添加一个按钮，用来触发面板的显示与关闭
    self.openbutton = self:AddChild(UIAnimButton("pocketwatch","pocketwatch_marble","cooldown_long"))

    -- 设置位置
    local save_data = RW_Data:LoadData()
    if save_data.pos and save_data.pos.x and save_data.pos.y then
        self.openbutton:SetPosition(save_data.pos.x, save_data.pos.y, 0)
    else
        self.openbutton:SetPosition(-55, 200, 0)
    end
    self.openbutton:SetFocusAnim("cooldown_long", true) -- 设置鼠标对准时播放的动画
    self.openbutton.animstate:Pause() -- 默认暂停动画
    self.openbutton:SetScale(0.3, 0.3) -- 设置缩放比
    self.openbutton:SetHoverText(STRINGS.eventtimer.ui_desc, { offset_y = 70 })
    self.openbutton.hovertext:SetScale(0.9, 0.9) -- 重新设置提示大小
    self.openbutton.onclick = function()
        self:ToggleEventTimerUI()
    end

    self.openbutton.OnControl = self.OnControl -- 将UIAnimButton的OnControl 改为 Button的OnControl

    -- 鼠标对准时播放动画
    self.openbutton:SetOnFocus(function()
        self.openbutton.animstate:Resume()
    end)

    -- 鼠标离开时暂停动画
    self.openbutton:SetOnLoseFocus(function()
        self.openbutton.animstate:Pause()
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

    self:Refresh()
end)

-- 开关面板
function EventUIButton:ToggleEventTimerUI()
    if self.eventui then
        self.eventui:Close()
        self.eventui = nil
    else
        self.eventui = self.owner:AddChild(TarnsferPanel(self.owner))
    end
end

-- 刷新UI按钮显示状态
function EventUIButton:Refresh()
    if EventTimer.UIButton ~= "always" then
        self.openbutton:Hide()
    else
        self.openbutton:Show()
    end
end

AddClassPostConstruct("screens/playerhud", function(self)
    self.EventTimerButton = self:AddChild(EventUIButton(self))
end)

-- 为暂停页面添加按钮
AddClassPostConstruct("screens/redux/pausescreen", function(self)
    local EventUIButton = self.menu:AddChild(UIAnimButton("pocketwatch","pocketwatch_marble","cooldown_long"))

    EventUIButton:SetFocusAnim("cooldown_long", true) -- 设置鼠标对准时播放的动画
    EventUIButton.animstate:Pause()
    EventUIButton:SetScale(0.5)

    EventUIButton:SetClickable(true)
    EventUIButton.onclick = function()
        self:unpause()
        ThePlayer.HUD.EventTimerButton:ToggleEventTimerUI()
    end

    EventUIButton.OnControl = Button.OnControl -- 将UIAnimButton的OnControl 改为 Button的OnControl

    EventUIButton:SetHoverText(STRINGS.LMB .. STRINGS.eventtimer.ui_title, { offset_y = 70 })
    EventUIButton:SetPosition(-RESOLUTION_X * 0.17, -RESOLUTION_Y * 0.35, 0)

    -- 鼠标对准时播放动画
    EventUIButton:SetOnFocus(function()
        EventUIButton.animstate:Resume()
    end)

    -- 鼠标离开时暂停动画
    EventUIButton:SetOnLoseFocus(function()
        EventUIButton.animstate:Pause()
    end)

    if EventTimer.UIButton == "pause_screen" then
        EventUIButton:Show()
    else
        EventUIButton:Hide()
    end
end)
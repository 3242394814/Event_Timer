local RW_Data = EventTimer.env.RW_Data
local TimerMode = EventTimer.TimerMode
local save_data = RW_Data:LoadData()

local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local Screen = require "widgets/screen"
local TEMPLATES = require "widgets/redux/templates"
local UIAnim = require("widgets/uianim")

local WaringEventHUD = Class(Screen, function(self, owner)
    Screen._ctor(self, "WaringEventHUD")
    self.owner = owner
    self.isopen = true
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)
    -- TEMPLATES.RectangleWindow() 方法的构造方法参数如下
    -- TEMPLATES.RectangleWindow(sizeX, sizeY, title_text, bottom_buttons, button_spacing, body_text)
    -- sizeX: 宽
    -- sizeY: 高
    -- title_text 面板title
    -- bottom_buttons 底部按钮
    -- button_spacing 按钮间距
    -- body_text 面板的文本
    self.panel = self:AddChild(TEMPLATES.RectangleWindow(500, 650, "事件计时器",
    {
        {
            text = "关闭",
            cb = function()
                self.owner.HUD:CloseTarnsferPanel()
            end,
            offset = nil
        },
    }))

    ------------------------------------scroll-----------------------------------------
    -- 初始化每一项的方法
    local function DestItemCtor(content, index)
        local widget = Widget("widget-"..index)

        widget:SetOnGainFocus(function()
            self.scrollpanel:OnWidgetFocus(widget)
        end)
        -- self:InitDestItem() 每一项里的控件布局
        widget.destitem = widget:AddChild(self:InitDestItem())

        return widget
    end

    -- 给每一项赋值，添加事件的方法
    local function DestApply(context, widget, data, index)
        widget.destitem:Hide()
        if widget.destitem.anim then
            widget.destitem.anim:Kill()
        end

        local text = data and data.text
        if text then
            -- 设置文字
            widget.destitem.describe:SetString(text)

            if data.animchangefn then
                data.animchangefn(data)
            end

            -- 设置动画
            if data.anim then
                widget.destitem.anim = widget.destitem:AddChild(UIAnim())
                widget.destitem.anim:SetPosition(-150, -10, 0)

                local scale = (data.anim.scale or 0.099)
                widget.destitem.anim:SetScale(scale)
                widget.destitem.anim:GetAnimState():SetBank(data.anim.bank)
                widget.destitem.anim:GetAnimState():SetBuild(data.anim.build)
                widget.destitem.anim:GetAnimState():PlayAnimation(data.anim.animation or "idle", data.anim.loop)
                widget.destitem.anim:GetAnimState():Pause()
            end

            if data.gettimefn then
                -- 更新复选框状态
                if ThePlayer.HUD[data.name].force then
                    widget.destitem.checkbox:SetTextures( "images/global_redux.xml", "checkbox_normal_check.tex", "checkbox_focus_check.tex", "checkbox_focus.tex" )
                else
                    widget.destitem.checkbox:SetTextures( "images/global_redux.xml", "checkbox_normal.tex", "checkbox_focus.tex", "checkbox_focus_check.tex" )
                end

                -- 设置复选框按下后执行的函数
                widget.destitem.checkbox:SetOnClick(function()
                    ThePlayer.HUD[data.name].force = not ThePlayer.HUD[data.name].force

                    -- 根据切换结果设置 checkbox 状态
                    if ThePlayer.HUD[data.name].force then
                        save_data[data.name] = true
                        widget.destitem.checkbox:SetTextures( "images/global_redux.xml", "checkbox_normal_check.tex", "checkbox_focus_check.tex", "checkbox_focus.tex" )
                    else
                        save_data[data.name] = false
                        widget.destitem.checkbox:SetTextures( "images/global_redux.xml", "checkbox_normal.tex", "checkbox_focus.tex", "checkbox_focus_check.tex" )
                    end

                    RW_Data:SaveData(save_data)
                end)
            elseif widget.destitem.checkbox then
                widget.destitem.checkbox:Kill()
                widget.destitem.checkbox = nil
            end

            -- 点击倒计时后触发的事件
            widget.destitem.backing:SetOnClick(function()
                if type(data.announcefn) == "function" and type(data.announcefn()) == "string" then
                    TheNet:Say(STRINGS.LMB .. ' ' .. data.announcefn())
                end
            end)

            widget.destitem:Show()
            widget.destitem.describe._index = data.index
        end
    end

    -- 将滚动条添加到self.panel里去
    self.scrollpanel = self.panel:AddChild(TEMPLATES.ScrollingGrid({}, {
        num_columns = 1,             -- 有几个滚动条
        num_visible_rows = 5,        -- 滚动条内最多显示多少行
        item_ctor_fn = DestItemCtor, -- 每一项的构造方法
        apply_fn = DestApply,        -- 给每一项赋值，添加事件等
        widget_width = 400,          -- 每一项的宽
        widget_height = 100,          -- 每一项的高
        end_offset = nil,
    }))
    -----------------------------------------------------------------------------------
    self:UpdateDestItem() -- 立刻更新一次数据，防止暂停时没数据
    -- Scheduler:ExecutePeriodic(period, fn, limit, initialdelay, id, ...)
    self.updatetask = scheduler:ExecutePeriodic(FRAMES * 10, self.UpdateDestItem, nil, 0, "updatedestitems", self) -- 持续刷新数据

    -- 最后要把滚动条挂到父组件上的 self.default_focus 对象上去
    self.default_focus = self.scrollpanel
end)

-- 更新数据
function WaringEventHUD:UpdateDestItem()
    local data_list = {}
    local eventsdata = ThePlayer.HUD.WaringEventTimeData
    for name, value in pairs(WaringEvents) do
        local datatext = eventsdata[name .. "_text"]
        local datatime = eventsdata[name .. "_time"]
        if type(datatext) == "string" and datatext ~= "" then
            value.text = datatext
            data_list[#data_list + 1] = value
        elseif type(datatime) == "number" and datatime > 0 then
            value.text = self:TimeToString(datatime)
            data_list[#data_list + 1] = value
        end
    end
    self.scrollpanel:SetItemsData(data_list)
end

-- 格式化时间
function WaringEventHUD:TimeToString(seconds)
    local daytime = TimerMode == 2 and 3600 or TUNING.TOTAL_DAY_TIME
    local d = math.floor(seconds / daytime)
    local min = math.floor(seconds % daytime / 60)
    local s = seconds % daytime % 60

    if TimerMode == 2 then
        return d .. "时" .. min .. "分" .. s .. "秒"
    else
        return d .. "天" .. min .. "分" .. s .. "秒"
    end
end

-- 关闭面板
function WaringEventHUD:Close()
    if self.isopen then
        self.attach = nil
        self.panel:Kill()
        self.isopen = false
        self.updatetask:Cancel()
        self.updatetask = nil

        self.inst:DoTaskInTime(0, function() TheFrontEnd:PopScreen(self) end)
    end
end

-- 定义每一项内的控件布局
function WaringEventHUD:InitDestItem()
    local dest = Widget("destination")
    local width, height = 400, 100
    dest.backing = dest:AddChild(TEMPLATES.ListItemBackground(width, height, function() end))
    dest.backing.move_on_click = true -- 按下后有视觉反馈

    -- TEXT控件
    dest.describe = dest:AddChild(Text(BODYTEXTFONT, 30)) -- 添加TEXT控件 字体，大小，文字
    dest.describe:SetColour(255, 255, 255, 1)
    dest.describe:SetVAlign(ANCHOR_MIDDLE) -- 设置上下对齐
    dest.describe:SetHAlign(ANCHOR_MIDDLE) -- 设置左右对齐
    dest.describe:SetPosition(10, 0, 0) -- 设置坐标 X，Y，Z
    dest.describe:SetRegionSize(300, 80) -- 设置文字区域大小

    -- 复选框
    dest.checkbox = dest:AddChild(ImageButton(
        "images/global_redux.xml","checkbox_normal.tex", "checkbox_focus.tex", "checkbox_focus_check.tex", nil, nil, {1,1}, {0,0}
    ))
    dest.checkbox:SetPosition(160, 0)
    dest.checkbox:SetScale(1)

    -- 将定义好的组件返回
    return dest
end

return WaringEventHUD
local RW_Data = EventTimer.env.RW_Data
local TimeToString = EventTimer.env.TimeToString
local save_data = RW_Data:LoadData()

local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Text = require "widgets/text"
local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local UIAnim = require "widgets/uianim"

local WarningEventHUD = Class(Widget, function(self, owner)
    Widget._ctor(self, "WarningEventHUD")
    self.owner = owner
    self.isopen = true
    self:SetScaleMode(SCALEMODE_FIXEDPROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
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
    self.panel = self:AddChild(TEMPLATES.RectangleWindow(380, 480, STRINGS.eventtimer.ui_title,
    {
        {
            text = STRINGS.UI.OPTIONS.CLOSE,
            cb = function()
                self.owner.EventTimerButton:ToggleEventTimerUI()
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

        if widget.destitem.image then
            widget.destitem.image:Kill()
        end
        if widget.destitem.anim then
            widget.destitem.anim:Kill()
        end

        local text = data and data.text
        if text then
            -- 设置文字
            widget.destitem.describe:SetString(text)

            if data.animchangefn then
                data:animchangefn()
            end

            if data.imagechangefn then
                data:imagechangefn()
            end

            if data.nobackground and widget.destitem.background then
                widget.destitem.background:Kill()
            end

            if data.image and data.image.atlas and data.image.tex then -- 设置图片
                local pos = { -- 默认位置
                    x = -140,
                    y = 0
                }
                if data.image.uioffset then -- 偏移位置
                    pos.x = pos.x + (data.image.uioffset.x or 0)
                    pos.y = pos.y + (data.image.uioffset.y or 0)
                end

                widget.destitem.image = widget.destitem:AddChild(Image(
                    data.image.atlas,
                    data.image.tex
                ))
                widget.destitem.image:SetPosition(pos.x, pos.y, 0)
                widget.destitem.image:SetScale(data.image.scale or 0.099)
            elseif data.anim then -- 设置动画
                local pos = { -- 默认位置
                    x = -140,
                    y = -15,
                }
                if data.anim.uioffset then -- 偏移位置
                    pos.x = pos.x + (data.anim.uioffset.x or 0)
                    pos.y = pos.y + (data.anim.uioffset.y or 0)
                end
                widget.destitem.anim = widget.destitem:AddChild(UIAnim())
                widget.destitem.anim:SetPosition(pos.x, pos.y, 0)
                widget.destitem.anim:SetScale(data.anim.scale or 0.099)
                widget.destitem.anim:GetAnimState():SetBank(data.anim.bank)
                widget.destitem.anim:GetAnimState():SetBuild(data.anim.build)
                widget.destitem.anim:GetAnimState():PlayAnimation(data.anim.animation or "idle", data.anim.loop)
                if data.anim.hidesymbol then
                    for _, s in ipairs(data.anim.hidesymbol) do
                        widget.destitem.anim:GetAnimState():HideSymbol(s)
                    end
                end
                if data.anim.overridesymbol then
                    for _, v in pairs(data.anim.overridesymbol) do
                        widget.destitem.anim:GetAnimState():OverrideSymbol(v[1], v[2], v[3])
                    end
                end
                if data.anim.overridebuild then
                    for _, b in pairs(data.anim.overridebuild) do
                        widget.destitem.anim:GetAnimState():AddOverrideBuild(b)
                    end
                end
                if data.anim.orientation then
                    widget.destitem.anim:GetAnimState():SetOrientation(data.anim.orientation)
                end
                widget.destitem.anim:GetAnimState():Pause()
            end

            if data.gettimefn then
                if not widget.destitem.checkbox then
                    widget.destitem.checkbox = widget.destitem:AddChild(ImageButton(
                        "images/global_redux.xml","checkbox_normal.tex", "checkbox_focus.tex", "checkbox_focus_check.tex", nil, nil, {1,1}, {0,0}
                    ))
                    widget.destitem.checkbox:SetPosition(160, 0)
                    widget.destitem.checkbox:SetScale(1)
                end

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
                if type(data.announcefn) == "function" then
                    local res = data.announcefn()
                    if type(res) == "string" then
                        TheNet:Say(STRINGS.LMB .. ' ' .. res)
                    end
                end
            end)

            widget.destitem:Show()
            widget.destitem.describe._index = data.index
        end
    end

    -- 将滚动条添加到self.panel里去
    self.scrollpanel = self.panel:AddChild(TEMPLATES.ScrollingGrid({}, {
        num_columns = 1,             -- 有几个滚动条
        num_visible_rows = 4,        -- 滚动条内最多显示多少行
        item_ctor_fn = DestItemCtor, -- 每一项的构造方法
        apply_fn = DestApply,        -- 给每一项赋值，添加事件等
        widget_width = 370,          -- 每一项的宽
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
function WarningEventHUD:UpdateDestItem()
    local data_list = {}
    local eventsdata = ThePlayer.HUD.WarningEventTimeData
    for name, value in pairs(WarningEvents) do
        local datatext = eventsdata[name .. "_text"]
        local datatime = eventsdata[name .. "_time"]
        if type(datatext) == "string" and datatext ~= "" then
            value.text = datatext
            data_list[#data_list + 1] = value
        elseif type(datatime) == "number" and datatime > 0 then
            value.text = TimeToString(datatime)
            data_list[#data_list + 1] = value
        end
    end
    self.scrollpanel:SetItemsData(data_list)
end

-- 关闭面板
function WarningEventHUD:Close()
    if self.isopen then
        self.attach = nil
        self.panel:Kill()
        self.isopen = false
        self.updatetask:Cancel()
        self.updatetask = nil
    end
end

-- 定义每一项内的控件布局
function WarningEventHUD:InitDestItem()
    local dest = Widget("destination")
    local width, height = 370, 100
    dest.backing = dest:AddChild(TEMPLATES.ListItemBackground(width, height, function() end))
    dest.backing.move_on_click = true -- 按下后有视觉反馈

    -- 图片/动画背景
    dest.background = dest:AddChild(Image("images/scrapbook.xml", "inv_item_background.tex"))
    dest.background:SetPosition(-140, 0, 0)
    dest.background:SetScale(0.5, 0.5)

    -- TEXT控件
    dest.describe = dest:AddChild(Text(BODYTEXTFONT, 30)) -- 添加TEXT控件 字体，大小，文字
    dest.describe:SetColour(255, 255, 255, 1)
    dest.describe:SetVAlign(ANCHOR_MIDDLE) -- 设置上下对齐
    dest.describe:SetHAlign(ANCHOR_MIDDLE) -- 设置左右对齐
    dest.describe:SetPosition(10, 0, 0) -- 设置坐标 X，Y，Z
    dest.describe:SetRegionSize(350, 100) -- 设置文字区域大小
    dest.describe:SetScale(0.7, 0.7) -- 设置文字大小

    -- 复选框
    dest.checkbox = dest:AddChild(ImageButton(
        "images/global_redux.xml","checkbox_normal.tex", "checkbox_focus.tex", "checkbox_focus_check.tex", nil, nil, {1,1}, {0,0}
    ))
    dest.checkbox:SetPosition(160, 0)
    dest.checkbox:SetScale(0.8)

    -- 将定义好的组件返回
    return dest
end

return WarningEventHUD
local NineSlice = require "widgets/nineslice"
local Widget = require("widgets/widget")
local Text = require("widgets/text")

local WarningTips = Class(Widget, function(self, text, up_info)
    Widget._ctor(self, "WarningTips")
    self:SetScale(2, 2)
    self:SetClickable(false)
    self.Alpha = 0
    self.text = self:AddChild(Text(NUMBERFONT, 20, text or "", WEBCOLOURS["ORANGE"]))
    local w, h = self.text:GetRegionSize() -- 获取文字区域大小

    local new_start_y
    if up_info then
        local up_y = up_info.target_y
        local up_w, up_h = up_info.text:GetRegionSize()
        new_start_y = up_y - up_h - h - 50
    end

    self.bg = self:AddChild(NineSlice(
        "images/dyc_panel_shadow.xml", -- atlas
        "dyc_panel_shadow_31.tex", -- top_left
        "dyc_panel_shadow_32.tex", -- top_center
        "dyc_panel_shadow_33.tex", -- top_right
        "dyc_panel_shadow_21.tex", -- mid_left
        "dyc_panel_shadow_22.tex", -- mid_center
        "dyc_panel_shadow_23.tex", -- mid_right
        "dyc_panel_shadow_11.tex", -- bottom_left
        "dyc_panel_shadow_12.tex", -- bottom_center
        "dyc_panel_shadow_13.tex"  -- bottom_right
    ))
    self.bg:SetSize(
        w + 5,
        h
    )
    self.bg:SetScale(0.5, 0.5)
    self.bg:SetPosition(0, -2.5)

    self.text:MoveToFront() -- 将文字移动到前面

    self.start_x = w + 100 -- 起始X轴位置
    self.target_x = w + 40 -- 目标X轴位置
    self.base_y = (h / 2 - 160) -- 原始Y轴位置
    self.start_y = new_start_y or (h / 2 - 160) -- 起始Y轴位置
    self.target_y = self.start_y -- 目标Y轴位置

    -- 设置锚点
    self:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
    self:SetVAnchor(1) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
    self.text:SetHAlign(1) -- 设置左对齐

    -- 调整透明度
    self.text:UpdateAlpha(0)
    self.bg:SetTint(1,1,1,0)

    self.inst:StartWallUpdatingComponent(self) -- 更新透明度
    self.AlphaMode = 1

    -- 开始显示，以移动动画形式出现
    self:MoveTo(
        { x = self.start_x, y = self.start_y, z = 0 }, -- 开始位置 from
        { x = self.target_x, y = self.start_y, z = 0}, -- 结束位置 to
        0.5, -- 移动时长 time
        nil -- 移动完成后执行的函数 fn
    )

    TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/XP_bar_fill_unlock") -- 播放提示音
end)

function WarningTips:OnWallUpdate(dt)
    if self.AlphaMode then -- 淡入
        self.Alpha = self.Alpha + 0.02
    else -- 淡出
        self.Alpha = self.Alpha - 0.02
    end

    if self.Alpha > 1 then
        self.Alpha = 1
    elseif self.Alpha < 0 then
        self.Alpha = 0
    end

    self.text:UpdateAlpha(self.Alpha)
    self.bg:SetTint(1,1,1,self.Alpha)
end

return WarningTips
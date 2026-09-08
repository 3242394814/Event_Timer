local NineSlice = require "widgets/nineslice"
local Widget = require("widgets/widget")
local Text = require("widgets/text")

local TypewriterText = Class(Text, function(self, font, size, text, color)
    Text._ctor(self, font, size, text, color)
end)

function TypewriterText:AnimateIn(speed)
    self.textString = self.string or ""
    self.animSpeed = speed or 60
    self.animIndex = 0
    self.animTimer = 0
    self:SetString("")
    self:StartUpdating()
end

function TypewriterText:OnUpdate(dt) -- 每秒执行【游戏刷新率】次
    if dt > 0 and self.animIndex and self.textString and #self.textString > 0 then
        self.animTimer = self.animTimer + dt

        -- 每次更新添加一个字符
        if self.animTimer > 1 / self.animSpeed then
            self.animTimer = 0
            self.animIndex = self.animIndex + 1

            if self.animIndex > #self.textString then
                self.animIndex = nil
                self:SetString(self.textString)
                self:StopUpdating()
            else
                local byte = string.byte(self.textString, self.animIndex)
                if byte and byte > 0x7F then
                    self.animIndex = self.animIndex + 2
                end
                self:SetString(string.sub(self.textString, 1, self.animIndex))
            end
        end
    end
end

--- @param text string|nil 消息内容
--- @param level number|nil 1-静默提醒-白色 2-声音提醒-黄色 3-声音提醒-红色
local WarningTips = Class(Widget, function(self, text, level)
    Widget._ctor(self, "WarningTips")
    self:SetScale(2, 2)
    self:SetClickable(false)
    self.Alpha = 0

    level = type(level) == "number" and level or 2
    local color = {
        [1] = RGB(255, 255, 255), -- 白色
        [2] = RGB(255, 165, 0), -- 黄色
        [3] = RGB(255, 0, 0), -- 红色
    }
    self.text = self:AddChild(TypewriterText(NUMBERFONT, 20, text or "", color[level] or color[2]))
    local w, h = self.text:GetRegionSize() -- 获取文字区域大小
    self.text_width = w
    self.text_height = h

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

    self.start_x = w + 340 -- 起始X轴位置
    self.target_x = w + 40 -- 目标X轴位置
    self.base_y = (h / 2 - 160) -- 原始Y轴位置
    self.start_y = h / 2 - 160 -- 起始Y轴位置
    self.target_y = self.start_y -- 目标Y轴位置

    -- 设置锚点
    self:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
    self:SetVAnchor(1) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下
    self.text:SetHAlign(1) -- 设置左对齐

    -- 调整透明度
    self.text:UpdateAlpha(0)
    self.bg:SetTint(1,1,1,0)

    self.inst:StartWallUpdatingComponent(self) -- 更新透明度
    self.AlphaMode = true
    self.text:AnimateIn()

    -- 开始显示，以移动动画形式出现
    self:MoveTo(
        { x = self.start_x, y = self.start_y, z = 0 }, -- 开始位置 from
        { x = self.target_x, y = self.start_y, z = 0}, -- 结束位置 to
        1, -- 移动时长 time
        nil -- 移动完成后执行的函数 fn
    )
    if level > 1 then
        TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/XP_bar_fill_unlock") -- 播放提示音
    end
end)

function WarningTips:GetTextSize()
    return self.text_width, self.text_height
end

function WarningTips:RefreshTextSize()
    local w, h = self.text:GetRegionSize()
    self.text_width = w
    self.text_height = h
    self.bg:SetSize(w + 5, h)
end

function WarningTips:SetText(text)
    if type(text) ~= "string" or text == "" then
        return false
    end

    self.text.textString = text
    if not self.text.animIndex then
        self.text:SetString(self.text.textString)
        self:RefreshTextSize()
    end
    return true
end

function WarningTips:FadeOut()
    self.AlphaMode = false
    self.inst:StartWallUpdatingComponent(self)
end

function WarningTips:OnWallUpdate(dt) -- 每秒执行【游戏刷新率】次
    if self.AlphaMode then -- 淡入
        self.Alpha = math.min(1, self.Alpha + dt * 3)
    else -- 淡出
        self.Alpha = math.max(0, self.Alpha - dt)
    end

    self.text:UpdateAlpha(self.Alpha)
    self.bg:SetTint(1,1,1,self.Alpha)

    if (self.AlphaMode and self.Alpha >= 1) or (not self.AlphaMode and self.Alpha <= 0) then
        self.inst:StopWallUpdatingComponent(self)
    end
end

return WarningTips
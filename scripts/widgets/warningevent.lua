local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local UIAnim = require("widgets/uianim")

local WarningEvent = Class(Widget, function(self, anim_data, image_data)
    Widget._ctor(self, "WarningEvent")

    self:SetClickable(false)
    self:SetScale(TheFrontEnd:GetHUDScale())
    self:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
    self:SetVAnchor(1) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下

    self.timer = self:AddChild(Text(BODYTEXTFONT, 36))
    self.timer:SetPosition(25, -12)

    self.anim = self:AddChild(UIAnim())
    self.anim:SetPosition(-45, -25)

    self.image = self:AddChild(Image())
    self.image:SetPosition(-45, -25)
    if anim_data then
        self:SetEventAnim(anim_data)
    elseif image_data then
        self:SetEventImage(image_data)
    end
end)

local function TimeToString(t)
    local daytime = EventTimer.TimerMode == 2 and 3600 or TUNING.TOTAL_DAY_TIME

    if t < 60 then
        return math.floor(t) .. STRINGS.eventtimer.time.seconds -- 秒
    elseif t < 480 then
        return math.floor(t / 60 * 10) / 10 .. STRINGS.eventtimer.time.minutes -- 分
    elseif EventTimer.TimerMode == 2 and t < 3600 then -- 小时模式下但不足一小时，显示分钟
        return math.floor(t / 60 * 10) / 10 .. STRINGS.eventtimer.time.minutes
    else
        return math.floor(t / daytime * 10) / 10 .. (EventTimer.TimerMode == 2 and STRINGS.eventtimer.time.hour --[[小时]] or STRINGS.eventtimer.time.day) -- 天
    end
end

local function ConversionTime(data)
    if type(data) == "number" then
        if data < 0 then
            data = 0
        end
        return TimeToString(data)
    elseif type(data) == "string" then
        return data
    end
end

function WarningEvent:OnUpdate(data)
    self.timer:SetString(ConversionTime(data))
end

function WarningEvent:SetEventAnim(data)
    if not data then return end
    local scale = (data.scale or 0.099)
    self.anim:SetScale(scale)
    self.anim:GetAnimState():SetBank(data.bank)
    self.anim:GetAnimState():SetBuild(data.build)
    self.anim:GetAnimState():PlayAnimation(data.animation or "idle", data.loop)
    if data.hidesymbol then
        for _, s in ipairs(data.hidesymbol) do
            self.anim:GetAnimState():HideSymbol(s)
        end
    end
    if data.overridesymbol then
        for _, v in pairs(data.overridesymbol) do
            self.anim:GetAnimState():OverrideSymbol(v[1], v[2], v[3])
        end
    end
    if data.overridebuild then
        for _, b in pairs(data.overridebuild) do
            self.anim:GetAnimState():AddOverrideBuild(b)
        end
    end
    if data.orientation then
        self.anim:GetAnimState():SetOrientation(data.orientation)
    end

    if data.offset then
        self.anim:SetPosition(-45 + data.offset.x, -25 + data.offset.y)
    end
end

function WarningEvent:SetEventImage(data)
    local scale = (data.scale or 0.099)
    self.image:SetScale(scale)
    self.image:SetTexture(data.atlas, data.tex)
    if data.offset then
        self.image:SetPosition(-45 + data.offset.x, -25 + data.offset.y)
    end
end

return WarningEvent

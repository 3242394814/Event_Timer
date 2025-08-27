local Widget = require("widgets/widget")
local Text = require("widgets/text")
local UIAnim = require("widgets/uianim")

local WaringEvent = Class(Widget, function(self, anim_data)
    Widget._ctor(self, "WaringEvent")

    self:SetScale(TheFrontEnd:GetHUDScale())
    self:SetHAnchor(1) -- 设置原点x坐标位置，0、1、2分别对应屏幕中、左、右
    self:SetVAnchor(1) -- 设置原点y坐标位置，0、1、2分别对应屏幕中、上、下

    self.timer = self:AddChild(Text(BODYTEXTFONT, 36))
    self.timer:SetPosition(25, -12)

    self.anim = self:AddChild(UIAnim())
    self.anim:SetPosition(-45, -25)

    if anim_data then
        self:SetEventAnim(anim_data)
    end
end)

local function TimeToString(t)
    if t < 60 then
        return math.floor(t) .. STRINGS.SCRAPBOOK.DATA_SECONDS -- 秒
    elseif t < 480 then
        return math.floor(t / 60 * 10) / 10 .. STRINGS.SCRAPBOOK.DATA_MINUTE -- 分
    else
        return math.floor(t / TUNING.TOTAL_DAY_TIME * 10) / 10 .. STRINGS.SCRAPBOOK.DATA_DAY -- 天
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

function WaringEvent:OnUpdate(data)
    self.timer:SetString(ConversionTime(data))
end

function WaringEvent:SetEventAnim(data)
    local scale = (data.scale or 0.099)
    self.anim:SetScale(scale)
    self.anim:GetAnimState():SetBank(data.bank)
    self.anim:GetAnimState():SetBuild(data.build)
    self.anim:GetAnimState():PlayAnimation(data.animation or "idle", data.loop)

    if data.pos then
        self.anim:SetPosition(data.pos[1], data.pos[2])
    end
end

return WaringEvent

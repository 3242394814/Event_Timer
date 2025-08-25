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

local function ConversionTime(seconds)
    if seconds < 0 then
        seconds = 0
    end

    local daytime = TimerMode == 2 and 3600 or TUNING.TOTAL_DAY_TIME
    local d = math.floor(seconds / daytime)
    local min = math.floor(seconds % daytime / 60)
    local s = seconds % daytime % 60

    d = d < 10 and ("0" .. d) or d
    min = min < 10 and ("0" .. min) or min
    s = s < 10 and ("0" .. s) or s

    return d .. ":" .. min .. ":" .. s
end

function WaringEvent:OnUpdate(seconds)
    self.timer:SetString(ConversionTime(seconds))
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

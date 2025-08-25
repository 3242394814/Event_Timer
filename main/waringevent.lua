local AddClassPostConstruct = AddClassPostConstruct
local AddPrefabPostInit = AddPrefabPostInit
local modimport = modimport
GLOBAL.setfenv(1, GLOBAL)

modimport("main/waringevents")
local WaringEvent = require("widgets/waringevent")

local function AddWaringEvents(self)
    for waringevent, data in pairs(WaringEvents) do
        self[waringevent] = self:AddChild(WaringEvent(data.anim))
        self[waringevent]:Hide()
    end

    function self:UpdateWaringEvents(eventstime)
        local i = 0
        local line_num = 2
        local scale = TheFrontEnd:GetHUDScale()
        for waringevent, data in pairs(WaringEvents) do
            local row = math.floor(i/line_num)
            local line = i - row * line_num
            local x = (row * 150 + 80) * scale
            local y = (-line * 70 - 30) * scale

            self[waringevent]:SetPosition(x, y, 0)
            local time = eventstime[waringevent]

            if self[waringevent].last_time == time then
                self[waringevent].sametick = (self[waringevent].sametick or 0) + 1
            else
                self[waringevent].sametick = 0
            end


            if (self[waringevent].force == "hide") or
                (self[waringevent].force ~= "show" and (time <= 0 or self[waringevent].sametick >= 100)) then
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
    end
end

AddClassPostConstruct("screens/playerhud", AddWaringEvents)

local network_worlds = {
    "forest",
    "cave",
    "shipwrecked",
    "volcano",
}

for i, world in ipairs(network_worlds) do
    AddPrefabPostInit(world .. "_network", function(inst)
        if not TheWorld.ismastersim then
            return
        end

        inst:AddComponent("waringtimer")
    end)
end

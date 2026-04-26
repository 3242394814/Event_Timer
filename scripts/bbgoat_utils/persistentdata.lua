-- 原作者 Blueberrys
-- https://forums.kleientertainment.com/files/file/1150-persistent-data

local PersistentData = Class(function(self, id)
    self.persistdata = {}
    self.dirty = true
    self.id = id
end)

local function trim(s) return s:match('^%s*(.*%S)%s*$') or '' end

function PersistentData:SetValue(key, value)
    self.persistdata[key] = value
    self.dirty = true
end

function PersistentData:GetValue(key) return self.persistdata[key] end

function PersistentData:Save(callback)
    if self.dirty then
        local str = json.encode(self.persistdata)
        SavePersistentString(self.id, str, false, callback)
    elseif callback then
        callback(true)
    end
end

function PersistentData:Load(callback)
    TheSim:GetPersistentString(self.id, function(load_success, str)
        if load_success then self:Set(str, callback) end
    end, false)
end

function PersistentData:Set(str, callback)
    if str and trim(str) ~= '' then
        self.persistdata = json.decode(str)
        self.dirty = false
    end

    if callback then callback(true) end
end

return PersistentData

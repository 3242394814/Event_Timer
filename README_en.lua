-- This README_en.md was translated by ChatGPT

-- How to add your event to this mod

-- 1.Add a table to GLOBAL.WarningEvents. The event name can be anything you like. Example and field explanations are below.

local TimeToString = GLOBAL.EventTimer.env.TimeToString -- Get the global events timer mod's time formatting function (converts a raw number into "Xday Xmin Xsec")
local Upvaluehelper = GLOBAL.EventTimer.env.Upvaluehelper -- Global events timer mod's get-upvalue helper. File located at ./scripts/utils/bbgoat_upvaluehelper.lua

-- Full example
GLOBAL.WarningEvents.hounded = { -- This event is named "hounded". Event names are arbitrary — avoid conflicts with the base mod.
    gettimefn = function() -- gettimefn: runs on the server. Returns a number representing how many seconds remain on the countdown.
        -- The persistent countdown in the top-left of the screen uses this value.
        -- If this is missing the event cannot be pinned to the top-left.
        if GLOBAL.TheWorld.components.hounded then
            local data = GLOBAL.TheWorld.components.hounded:OnSave()
            return data and data.timetoattack -- Return the hound attack countdown (must be a number).
            -- This value is also saved to the client at:
            -- GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_time
            -- (prefix is fixed: GLOBAL.ThePlayer.HUD.WarningEventTimeData, event name, and suffix "_time").
        end
    end,

    -- The "time" parameter passed below is the number returned by gettimefn above.
    gettextfn = function(time) -- gettextfn: runs on the server. Decides the text shown in the event-timer panel.
        -- If missing or if it returns nil, the panel will only show the time ("Xd Xm Xs").
        if not GLOBAL.TheWorld:HasTag("cave") or not time then return end
        local self = GLOBAL.TheWorld.components.hounded
        if not self then return end

        local next_wave_is_wormboss = Upvaluehelper.FindUpvalue(self.DoWarningSpeech, "_wave_pre_upgraded") -- Use helper to find the upvalue _wave_pre_upgraded in DoWarningSpeech
        local _wave_override_chance = self:OnSave().wave_override_chance

        if next_wave_is_wormboss then
            return string.format("Great Depths Worm will attack in %s", TimeToString(time))
        elseif type(_wave_override_chance) == "number" then
            return string.format("Depths Worm will attack in %s.\nGreat Depths Worm chance: %s%%", TimeToString(time), _wave_override_chance * 100)
        end
        -- Return type must be a string. The returned text is also saved to the client at:
        -- GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_text
        -- (prefix fixed, event name, suffix "_text").
    end,

    -- At least one of gettimefn or gettextfn must be provided.
    -- If both exist, the event-timer UI prefers to display text; the top-left persistent display only shows the time.

    ------------------------------------------------------------------------------------------------------------------------------------

    -- image = {
    --     atlas = "images/Hound.xml",
    --     tex = "Hound.tex",
    --     scale = 0.4, -- scale factor
    --     optional fields below:
    --     offset = { -- offset for the top-left persistent display
    --        x = 0  -- left minus, right plus
    --        y = 0  -- up plus, down minus
    --     },
    --     uioffset = { -- offset for the event-timer panel
    --        x = 0
    --        y = 0
    --     },
    -- },

    -- imagechangefn: client-side optional function. Choose different image tables depending on conditions.
    -- If you only have one image, set the "image" table directly as above.
    imagechangefn = function(self)
        local text = GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_text -- The text returned by server gettextfn (the panel display text)
        local is_worm_boss = text and string.find(text, "Great Depths Worm will attack") -- imagechangefn runs on client, so use string matching. Client cannot run gettimefn/gettextfn.
        if GLOBAL.TheWorld:HasTag("porkland") then
            self.image = self.porklandimage
        elseif GLOBAL.TheWorld:HasTag("island") or GLOBAL.TheWorld:HasTag("volcano") then
            self.image = self.islandimage
        elseif is_worm_boss then
            self.image = self.wormbossimage
        elseif GLOBAL.TheWorld:HasTag("cave") then
            self.image = self.caveimage
        else
            self.image = self.forestimage
        end
    end,
    forestimage = { -- image tables referenced by imagechangefn
        atlas = "images/Hound.xml",
        tex = "Hound.tex",
        scale = 0.4,
    },
    caveimage = {
        atlas = "images/Depths_Worm.xml",
        tex = "Depths_Worm.tex",
        scale = 0.25,
    },
    wormbossimage = {
        atlas = "images/Worm_boss.xml",
        tex = "Worm_boss.tex",
        scale = 0.25,
    },

    ------------------------------------------------------------------------------------------------------------------------------------

    -- anim = {
    --     scale = 0.099, -- scale factor
    --     bank = "hound", -- ANIM bank
    --     build = "hound_ocean", -- build
    --     animation = "idle", -- animation name
    --     loop = true, -- loop animation
    --     optional:
    --     offset = { -- offset for top-left persistent display
    --        x = 0
    --        y = 0
    --     },
    --     uioffset = { -- offset for the event-timer panel
    --        x = 0
    --        y = 0
    --     },
    --     overridebuild   -- array: extra builds (must be used with animation). Same as AddOverrideBuild.
    --     overridesymbol  -- map: symbol replacements (must be used with animation). Same as OverrideSymbol.
    --     hidesymbol      -- array: symbols to hide (must be used with animation). Same as HideSymbol.
    -- },

    -- animchangefn: client-side optional function similar to imagechangefn. Select different anim tables depending on conditions.
    -- If you only have one anim, set the "anim" table directly as above.
    animchangefn = function(self)
        if GLOBAL.TheWorld:HasTag("porkland") then
            self.anim = self.porklandanim
        elseif GLOBAL.TheWorld:HasTag("island") or GLOBAL.TheWorld:HasTag("volcano") then
            self.anim = self.islandanim
        elseif GLOBAL.TheWorld:HasTag("cave") then
            self.anim = self.caveanim
        else
            self.anim = self.forestanim
        end
    end,
    forestanim = {
        scale = 0.099,
        bank = "hound",
        build = "hound_ocean",
        animation = "idle",
        loop = true,
    },
    islandanim = {
        scale = 0.09,
        bank = "crocodog",
        build = "crocodog_poison",
        animation = "idle",
        loop = true,
        uioffset = {
            x = 6,
            y = 0,
        },
    },
    caveanim = {
        scale = 0.066,
        bank = "worm",
        build = "worm",
        animation = "atk",
        loop = true,
    },

    -- At least one of `image` or `anim` must be provided or there will be no visual.
    -- Event-timer panel prefers `image`. If absent, it shows the first frame of `anim`.
    -- Top-left persistent display prefers `anim`. If absent, it shows `image`.

    DisableShardRPC = true, -- Force-disable shard RPC sync for this event to avoid data conflicts. Useful when the same event exists across multiple worlds.

    -- announcefn: optional client-side function. Returns a string. Called when clicking the event in the event-timer panel to "announce" the event text.
    announcefn = function()
        local time = GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_time
        local text = GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_text
        return text ~= "" and text or time and string.format("Hound will attack in %s.", TimeToString(time))
    end,

    -- tipsfn: optional client-side "Highlight Tips" function.
    -- Return values (in order): boolean (true to trigger tip; false to not trigger and reset state),
    -- a function that returns the tip string (function -> string),
    -- duration (number, seconds),
    -- delay before showing (number, seconds or nil).
    -- Message Level (1 - Silent Alert - White, 2 - Sound Alert - Yellow, 3 - Sound Alert - Red)
    -- Signature: boolean, function->string, number, number|nil, number
    -- Example: return true, function() return "text" end, 10, 10, 3
    tipsfn = function()
        local time = GLOBAL.ThePlayer.HUD.WarningEventTimeData.hounded_time

        if time == 120 or (GLOBAL.GetTime() > 1 and GLOBAL.GetTime() < 10 and time > 0 and time < 960) then
            -- GLOBAL.GetTime returns time since this game load; reloading/entering world/reseting will reset it to 0.
            return true, GLOBAL.WarningEvents.hounded.announcefn, 10, nil, 2 -- true = tip triggers; announcefn provides text; 10 = duration (seconds); 2 = Message Level
        elseif time == 120 or (GLOBAL.GetTime() > 1 and GLOBAL.GetTime() < 10 and time > 0) then -- The difference from the one above is that this one is missing time < 960
            return true, GLOBAL.WarningEvents.hounded.announcefn, 10, nil, 1 -- The message level is lower than the one above.
        elseif time > 2 and time <= 90 then
            return true, GLOBAL.WarningEvents.hounded.announcefn, time, nil, 2
        elseif time < 2 and time > 0 then -- when gettimefn can't fetch hound info it's treated as 0, so avoid checking equality with 0
            return true, (function() return "WARNING: Hound attack starts!" end), 10, time, 3 -- second return must be a function returning a string; fourth value is delay (seconds)
        end
        return false -- otherwise return false to reset state
    end
}


-- Minimal example
GLOBAL.WarningEvents.hounded = { -- This event is named "hounded". Event names are arbitrary — avoid conflicts with the base mod.
    -- gettimefn: server-side. Return a number representing how many seconds remain.
    gettimefn = function()
        if GLOBAL.TheWorld.components.hounded then
            local data = GLOBAL.TheWorld.components.hounded:OnSave()
            return data and data.timetoattack
        end
    end,
    anim = {
        scale = 0.099, -- scale factor
        bank = "hound", -- anim bank
        build = "hound_ocean", -- build
        animation = "idle", -- animation name
    },
}

-- 2.Use the GLOBAL.EventTimer.Register_Event("EventName") function to register your event.
-- In the example above, the event name is hounded, so the registration method is:
-- GLOBAL.EventTimer.Register_Event("hounded")

-- Summary / Important notes
-- gettimefn / gettextfn run on the server.
-- imagechangefn / animchangefn / announcefn / tipsfn run on the client. The client cannot call gettimefn or gettextfn

-- Return types and save locations must be strictly followed:
-- gettimefn must return a number (seconds). The value is saved to GLOBAL.ThePlayer.HUD.WarningEventTimeData.<event>_time
-- gettextfn must return a string. The value is saved to GLOBAL.ThePlayer.HUD.WarningEventTimeData.<event>_text

-- After writing the event, use GLOBAL.EventTimer.Register_Event to register it.
-- The parameter you pass in should be the event name as a string.

-- Finally, enable this mod and your mod together. Your mod must load after this mod.
-- The events of this mod are recorded in main/warningevents.lua
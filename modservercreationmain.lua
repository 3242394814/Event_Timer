local menv = env
GLOBAL.setfenv(1, GLOBAL)

local eventname = "fe_unload_".. menv.modname
local UIAnim = require("widgets/uianim")

menv.FrontEndAssets = {
    Asset("ANIM", "anim/global_events_timer_dynamic_icon.zip"),
}

local function DoFnForCurrentScreen(fn)
	local CurrentScreen = TheFrontEnd:GetActiveScreen()
	if CurrentScreen then
		fn(CurrentScreen)
	end
end

local function AddDynamicIcon(self, root, s, x, y)
	if self.global_events_timer_dynamic_icon then
		return
	end

	self.global_events_timer_dynamic_icon = self[root]:AddChild(UIAnim())
	self.global_events_timer_dynamic_icon:GetAnimState():SetBuild("global_events_timer_dynamic_icon")
	self.global_events_timer_dynamic_icon:GetAnimState():SetBank("global_events_timer_dynamic_icon")
	self.global_events_timer_dynamic_icon:GetAnimState():PlayAnimation("global_events_timer_dynamic_icon", true)
    -- self.global_events_timer_dynamic_icon:GetAnimState():PushAnimation("", true)
    -- self.global_events_timer_dynamic_icon:GetAnimState():SetTime(22 * FRAMES)
    self.global_events_timer_dynamic_icon:SetPosition(x or 0, y or 0)
	if s then
		self.global_events_timer_dynamic_icon:SetScale(s)
	end

	self.global_events_timer_dynamic_icon.inst:ListenForEvent(eventname, function()
		self.global_events_timer_dynamic_icon:Kill()
		self.global_events_timer_dynamic_icon = nil
	end, TheGlobalInstance)
end

local function PatchModDetails(self)
	if self.currentmodname == menv.modname then
		AddDynamicIcon(self, "detailimage", 0.55, 3, 2.5)
	elseif self.global_events_timer_dynamic_icon then
		self.global_events_timer_dynamic_icon:Kill()
		self.global_events_timer_dynamic_icon = nil
	end
end

local function PatchModIcon(widget, data)
	local opt = widget.moditem
	local mod_data = (data or widget.data)
	if mod_data and mod_data.mod and mod_data.mod.modname == menv.modname then
		-- Fox: It seems that it triggers too fast if we change world tabs
		if not data and opt.global_events_timer_dynamic_icon then
			opt.global_events_timer_dynamic_icon:Kill()
			opt.global_events_timer_dynamic_icon = nil
		end
		AddDynamicIcon(opt, "image", 0.45, 3, 0)
	elseif opt.global_events_timer_dynamic_icon then
		opt.global_events_timer_dynamic_icon:Kill()
		opt.global_events_timer_dynamic_icon = nil
	end
end

if not rawget(_G, "global_events_timer_dynamic_icon_res") then
    local _FrontendUnloadMod = ModManager.FrontendUnloadMod
    ModManager.FrontendUnloadMod = function(self, unloaded_modname, ...)
        if not unloaded_modname or unloaded_modname == menv.modname then
            TheGlobalInstance:PushEvent(eventname)
        end
        return _FrontendUnloadMod(self, unloaded_modname, ...)
    end
    rawset(_G, "global_events_timer_dynamic_icon_res", true)
end

local function PreLoad(self)
    local _update_fn
    local mods_page

	if self.mods_tab then -- 创建世界的模组列表页面
        mods_page = self.mods_tab
    else
        return
	end

    if mods_page.mods_scroll_list then
        for i, widget in ipairs(mods_page.mods_scroll_list:GetListWidgets()) do
            PatchModIcon(widget)
        end
    end

    local _ShowModDetails = mods_page.ShowModDetails
    mods_page.ShowModDetails = function(self, idx, ...)
        _ShowModDetails(self, idx, ...)
        PatchModDetails(self)
    end

    if mods_page.mods_scroll_list.update_fn and not _update_fn then
        _update_fn = mods_page.mods_scroll_list.update_fn
        mods_page.mods_scroll_list.update_fn = function(context, widget, data, index, ...)
            _update_fn(context, widget, data, index, ...)
            PatchModIcon(widget, data)
        end
    end

    TheGlobalInstance:ListenForEvent(eventname, function()
        mods_page.mods_scroll_list.update_fn = _update_fn
        mods_page.ShowModDetails = _ShowModDetails
        ModUnloadFrontEndAssets(menv.modname)
    end)

    PatchModDetails(mods_page)
end

if rawget(_G, "TheFrontEnd") then
    menv.ReloadFrontEndAssets()
    DoFnForCurrentScreen(PreLoad)
end
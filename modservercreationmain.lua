local menv = env
GLOBAL.setfenv(1, GLOBAL)

local eventname = "fe_unload_".. menv.modname
local iconname = menv.modname .. "_dynamic_icon"
local UIAnim = require("widgets/uianim")

menv.FrontEndAssets = {
    Asset("ANIM", "anim/global_events_timer_dynamic_icon.zip"),
}

local function DoFnForCurrentScreen(fn)
	scheduler:ExecuteInTime(0, function()
		for _, screen in ipairs(TheFrontEnd.screenstack) do
			if screen.name == "ServerCreationScreen" then
				fn(screen)
				break
			end
		end
	end)
end

local function AddDynamicIcon(self, root, s, x, y)
	if self[iconname] then
		return
	end

	self[iconname] = self[root]:AddChild(UIAnim())
	self[iconname]:GetAnimState():SetBuild("global_events_timer_dynamic_icon")
	self[iconname]:GetAnimState():SetBank("global_events_timer_dynamic_icon")
	self[iconname]:GetAnimState():PlayAnimation("global_events_timer_dynamic_icon", true)
    -- self[iconname]:GetAnimState():PushAnimation("", true)
    -- self[iconname]:GetAnimState():SetTime(22 * FRAMES)
    self[iconname]:SetPosition(x or 0, y or 0)
	if s then
		self[iconname]:SetScale(s)
	end

	self[iconname].inst:ListenForEvent(eventname, function()
		self[iconname]:Kill()
		self[iconname] = nil
	end, TheGlobalInstance)
end

local function PatchModDetails(self)
	if self.currentmodname == menv.modname then
		AddDynamicIcon(self, "detailimage", 0.55, 3, 2.5)
	elseif self[iconname] then
		self[iconname]:Kill()
		self[iconname] = nil
	end
end

local function PatchModIcon(widget, data)
	local opt = widget.moditem
	local mod_data = (data or widget.data)
	if mod_data and mod_data.mod and mod_data.mod.modname == menv.modname then
		-- Fox: It seems that it triggers too fast if we change world tabs
		if not data and opt[iconname] then
			opt[iconname]:Kill()
			opt[iconname] = nil
		end
		AddDynamicIcon(opt, "image", 0.45, 3, 0)
	elseif opt[iconname] then
		opt[iconname]:Kill()
		opt[iconname] = nil
	end
end


if not rawget(_G, menv.modname .. "_dynamic_icon_res") then
    local _FrontendUnloadMod = ModManager.FrontendUnloadMod
    ModManager.FrontendUnloadMod = function(self, unloaded_modname, ...)
        if not unloaded_modname or unloaded_modname == menv.modname then
            TheGlobalInstance:PushEvent(eventname)
        end
        return _FrontendUnloadMod(self, unloaded_modname, ...)
    end
    rawset(_G, menv.modname .. "_dynamic_icon_res", true)
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
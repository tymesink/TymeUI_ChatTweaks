-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'ChatTabs';
local displayName = 'Chat Tabs';
local _G = getfenv(0)

-----------------------------------------------------------------------
-- internal libraries
-----------------------------------------------------------------------
local CTConstants = private.ImportLib('CTConstants')
local CTLogger = private.ImportLib('CTLogger')
local CTUtils = private.ImportLib('CTUtils')

-----------------------------------------------------------------------
-- external libraries
-----------------------------------------------------------------------
local LibStub = _G.LibStub
local AceAddon = LibStub('AceAddon-3.0')
-----------------------------------------------------------------------
-- 
-----------------------------------------------------------------------
local CT = AceAddon:GetAddon(CTConstants.ADDON_NAME)
local Module = CT:NewModule(moduleName, 'AceHook-3.0', 'AceTimer-3.0', 'AceConsole-3.0')
Module.name = moduleName
Module.displayName = displayName
Module.TempChatFrames = {}
Module.AddTempChat = function(self,name) table.insert(self.TempChatFrames,name) end;
-----------------------------------------------------------------------
-- local variable / methods
-----------------------------------------------------------------------
local db, options
local font = GameFontNormalSmall
local defaults = {
	profile = {
		height = 29,
		chattabs = false,
		tabFlash = true,
		alpha = 0,
	}
}

local function SetFontSizes()
	for i = 1, NUM_CHAT_WINDOWS do
		local tab = _G["ChatFrame"..i.."Tab"]
		Module:OnLeave(tab)
	end
	for index,name in ipairs(Module.TempChatFrames) do
		local tab = _G[name.."Tab"]
		Module:OnLeave(tab)
	end
end

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	self:DecorateTabs()
	for i = 1, NUM_CHAT_WINDOWS do
		local chat = _G["ChatFrame"..i]
		local tab = _G["ChatFrame"..i.."Tab"]
		tab:SetHeight(db.height)
		tab.Right:Hide()
		tab.Left:Hide()
		tab.Middle:Hide()
		tab.ActiveLeft:SetAlpha(0)
		tab.ActiveRight:SetAlpha(0)
		tab.ActiveMiddle:SetAlpha(0)
		tab.HighlightLeft:SetTexture(nil)
		tab.HighlightRight:SetTexture(nil)
		tab.HighlightMiddle:SetTexture([[Interface\BUTTONS\CheckButtonGlow]])
		tab.HighlightMiddle:SetWidth(76)
		tab.HighlightMiddle:SetTexCoord(0, 0, 1, 0.5)
		tab.ActiveLeft:SetAlpha(0)
		tab.ActiveRight:SetAlpha(0)
		tab.ActiveMiddle:SetAlpha(0)
		--[[ TODO: Grum @ 18/10/2008
		    There seems to be a bug with certain fonts/fontObjects which prevents
		    tab:GetNormalFontObject() to return anything sensible
		    The buttons now have font objects. If you change the size on one it will change on
		    the other tabs as well. However assigning a new font object seems to go wrong with
		    the default ChatFrame$Tab font-object. This will need further investigation

		    For now I just disabled all the font-changing mechanics.
		--]]
		tab:EnableMouseWheel(true)
		self:HookScript(tab, "OnMouseWheel")
		if (db.chattabs) then
			Module:HideTab(tab)
		end
		tab.noMouseAlpha=db.alpha
		tab:SetAlpha(db.alpha)
	end
	for index,name in ipairs(self.TempChatFrames) do
		local chat = _G[name]
		local tab = _G[name.."Tab"]
		tab:SetHeight(db.height)
		tab.Right:Hide()
		tab.Left:Hide()
		tab.Middle:Hide()
		tab.ActiveLeft:SetAlpha(0)
		tab.ActiveRight:SetAlpha(0)
		tab.ActiveMiddle:SetAlpha(0)
		tab.HighlightLeft:SetTexture(nil)
		tab.HighlightRight:SetTexture(nil)
		tab.HighlightMiddle:SetTexture([[Interface\BUTTONS\CheckButtonGlow]])
		tab.HighlightMiddle:SetWidth(76)
		tab.HighlightMiddle:SetTexCoord(0, 0, 1, 0.5)
		tab.ActiveLeft:SetAlpha(0)
		tab.ActiveRight:SetAlpha(0)
		tab.ActiveMiddle:SetAlpha(0)
		tab:EnableMouseWheel(true)
		if not self:IsHooked(tab,"OnMouseWheel") then
			self:HookScript(tab, "OnMouseWheel")
		end
		if (db.chattabs) then
			Module:HideTab(tab)
		end
		tab.noMouseAlpha=db.alpha
		tab:SetAlpha(db.alpha)
	end
	self:DecorateTabs()
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	for i = 1, NUM_CHAT_WINDOWS do
		local chat = _G["ChatFrame"..i]
		local tab = _G["ChatFrame"..i.."Tab"]
		tab:SetHeight(32)
		tab.Right:Hide()
		tab.Left:Hide()
		tab.Middle:Hide()
		tab:EnableMouseWheel(false)
		tab:Hide()
		tab.noMousealpha=0.2
		tab:SetAlpha(0.2)
	end
	for index,name in ipairs(self.TempChatFrames) do
		local chat = _G[name]
		local tab = _G[name.."Tab"]
		tab:SetHeight(32)
		tab.Right:Hide()
		tab.Left:Hide()
		tab.Middle:Hide()
		tab:EnableMouseWheel(false)
		tab:Hide()
		tab.noMousealpha=0.2
		tab:SetAlpha(0.2)
	end
	self:UndecorateTabs()
end

function Module:GetOptions()
	if not options then
		options = {
			height = {
				order = 101,
				type = "range",
				max = 60,
				min = 16,
				name = 'Button Height',
				desc = 'Button\'s height, and text offset from the frame',
				step = 1,
				bigStep = 1,
				get = function() return db.height end,
				set = function(info, v)
					db.height = v
					for i = 1, NUM_CHAT_WINDOWS do
						local tab = _G["ChatFrame"..i.."Tab"]
						tab:SetHeight(v)
					end
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			chattabs = {
				order = 102,
				type = "toggle",
				name = 'Hide Tabs',
				desc = 'Hides chat frame tabs',
				get = function() return db.chattabs end,
				set = function(info, v) db.chattabs = not db.chattabs; Module:ToggleTabShow() end,
				disabled = function() return not Module:IsEnabled() end
			},
			tabFlash = {
				order = 103,
				type = "toggle",
				name = 'Enable Tab Flashing',
				desc = 'Enables the Tab to flash when you miss a message',
				get = function() return db.tabFlash end,
				set = function(info, v) db.tabFlash = not db.tabFlash; Module:DecorateTabs() end,
				disabled = function() return not Module:IsEnabled() end
			},
			alpha = {
				order = 104,
				type = "range",
				name = 'Tab Alpha',
				min = 0,
				max = 1,
				step = 0.1,
				desc = 'Sets the alpha value for your chat tabs',
				get = function() return db.alpha end,
				set = function(info,v) db.alpha = v; Module:DecorateTabs();  FCFDock_UpdateTabs(GeneralDockManager, true) end,
				disabled = function() return not Module:IsEnabled() end
			}
		}
	end
	return options
end

function Module:Info()
	return 'Customizes the tabs on the chat window'
end

function Module:Decorate(frame)
	local name = frame:GetName()
	local tab = _G[name.."Tab"]
	tab:SetHeight(db.height)
	tab.Right:Hide()
	tab.Left:Hide()
	tab.Middle:Hide()
	tab.ActiveLeft:SetAlpha(0)
	tab.ActiveRight:SetAlpha(0)
	tab.ActiveMiddle:SetAlpha(0)
	tab.HighlightLeft:SetTexture(nil)
	tab.HighlightRight:SetTexture(nil)
	tab.HighlightMiddle:SetTexture([[Interface\BUTTONS\CheckButtonGlow]])
	tab.HighlightMiddle:SetWidth(76)
	tab.HighlightMiddle:SetTexCoord(0, 0, 1, 0.5)
	tab.ActiveLeft:SetAlpha(0)
	tab.ActiveRight:SetAlpha(0)
	tab.ActiveMiddle:SetAlpha(0)
	tab:EnableMouseWheel(true)
	self:HookScript(tab, "OnMouseWheel")
	tab:Show()
	if (db.chattabs) then
		self:HideTab(tab)
	end
end

function Module:DecorateTabs()
	CHAT_FRAME_FADE_OUT_TIME = 0.5
	CHAT_TAB_HIDE_DELAY = 0
	CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1
	CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = db.alpha
	CHAT_FRAME_TAB_ALERTING_MOUSEOVER_ALPHA = 1
	if db.tabFlash then		
		CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = 1
	else
		CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = db.alpha
	end
	CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA = 1
	CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = db.alpha
	for i = 1, NUM_CHAT_WINDOWS do
		local tab = _G["ChatFrame"..i.."Tab"]
		local chat = _G["ChatFrame"..i]
		if not chat.dock then
			tab.mouseOverAlpha = 1
			tab.noMouseAlpha = db.alpha
			tab:SetAlpha(db.alpha)
		end
	end
	for index,name in ipairs(self.TempChatFrames) do
		local chat = _G[name]
		local tab = _G[name.."Tab"]
		if not chat.dock then
			tab.mouseOverAlpha = 1
			tab.noMouseAlpha = db.alpha
			tab:SetAlpha(db.alpha)
		end
	end
end

function Module:UndecorateTabs()
	CHAT_FRAME_FADE_OUT_TIME = 2
	CHAT_TAB_HIDE_DELAY = 1
	CHAT_FRAME_TAB_SELECTED_MOUSEOVER_ALPHA = 1
	CHAT_FRAME_TAB_SELECTED_NOMOUSE_ALPHA = 0.4
	CHAT_FRAME_TAB_ALERTING_MOUSEOVER_ALPHA = 1
	CHAT_FRAME_TAB_ALERTING_NOMOUSE_ALPHA = 1
	CHAT_FRAME_TAB_NORMAL_MOUSEOVER_ALPHA = 0.6
	CHAT_FRAME_TAB_NORMAL_NOMOUSE_ALPHA = 0.2
	for i = 1, NUM_CHAT_WINDOWS do
		local tab = _G["ChatFrame"..i.."Tab"]
		local chat = _G["ChatFrame"..i]
		if not chat.dock then
			tab.mouseOverAlpha = 1
			tab.noMouseAlpha = 0.2
			tab:SetAlpha(0.2)
		end
	end
	for index,name in ipairs(self.TempChatFrames) do
		local chat = _G[name]
		local tab = _G[name.."Tab"]
		if not chat.dock then
			tab.mouseOverAlpha = 1
			tab.noMouseAlpha = 0.2
			tab:SetAlpha(0.2)
		end
	end
end

function Module:FCF_Close(f)
	_G[f:GetName() .. "Tab"]:Hide()
end

function Module:OnClick(f, button, ...)
	if button == "LeftButton" then
		SetFontSizes(f)
	end
end

function Module:ToggleTabShow()
	for i = 1, NUM_CHAT_WINDOWS do
		local tab = _G["ChatFrame"..i.."Tab"]
		local chat = _G["ChatFrame"..i]
		if (db.chattabs) then
			tab:SetScript("OnShow", function(...) tab:Hide() end)
		else
			tab:SetScript("OnShow", function(...) tab:Show() end)
		end
		tab:Show()
		tab:Hide()
		if chat.isDocked or chat:IsVisible() then
			tab:Show()
		end
	end
	for index,name in ipairs(self.TempChatFrames) do
		local tab = _G[name.."Tab"]
		local chat = _G[name]
		if (db.chattabs) then
			tab:SetScript("OnShow", function(...) tab:Hide() end)
		else
			tab:SetScript("OnShow", function(...) tab:Show() end)
		end
		tab:Show()
		tab:Hide()
		if chat.isDocked or chat:IsVisible() then
			tab:Show()
		end
	end
end

function Module:HideTab(tab)
	tab:SetScript("OnShow", function(...) tab:Hide() end)
	tab:Show()
	if tab:IsVisible() then
		tab:Hide()
	end
end

function Module:OnMouseWheel(frame, dir)
	local chat = _G["ChatFrame" .. frame:GetID()]
	if not chat.isDocked then return end

	local t
	for i = 1, #GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES do
		if GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES[i]:IsVisible() then
			t = i
			break
		end
	end

	if t == 1 and dir > 0 then
		t = #GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES
	elseif t == #GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES and dir < 0 then
		t = 1
	elseif t then
		t = t + (dir < 0 and 1 or -1)
	end
	if t then
		_G[GENERAL_CHAT_DOCK.DOCKED_CHAT_FRAMES[t]:GetName() .. "Tab"]:Click()
	end
	--SetFontSizes()
end

function Module:OnEnter(frame)
	local f, s = font:GetFont()
	frame:SetFont(f, s + 2, "")
end

function Module:OnLeave(frame)
	local f, s = font:GetFont()
	if(_G["ChatFrame" .. frame:GetID()]:IsVisible()) then
		frame:SetFont(f, s + 2, "")
	else
		frame:SetFont(f, s - 1, "")
	end
end

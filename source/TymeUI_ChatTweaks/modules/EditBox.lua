-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'EditBox';
local displayName = 'EditBox';
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
local LSM = LibStub('LibSharedMedia-3.0')
-----------------------------------------------------------------------
-- Module Framework
-----------------------------------------------------------------------
local CT = AceAddon:GetAddon(CTConstants.ADDON_NAME)
local Module = CT:NewModule(moduleName, 'AceHook-3.0', 'AceEvent-3.0')
Module.name = moduleName
Module.displayName = displayName
Module.callbacks = LibStub("CallbackHandler-1.0"):New(CT, "RegisterChatEvent", "UnregisterChatEvent", "UnregisterAllChatEvents")

local mod = Module
local db, options
local defaults = {
	profile = {
		on = true,
		background = 'Blizzard Tooltip',
		border = 'Blizzard Tooltip',
		backgroundColor = { r = 0, g = 0, b = 0, a = 1 },
		borderColor = { r = 1, g = 1, b = 1, a = 1 },
		inset = 3,
		edgeSize = 12,
		tileSize = 16,
		height = 22,
		attach = 'BOTTOM',
		colorByChannel = true,
		useAltKey = false,
		font = (function()
			for i = 1, NUM_CHAT_WINDOWS do
				local ff = _G['ChatFrame'..i..'EditBox']
				local f = ff:GetFont()
				for k,v in pairs(LSM:HashTable('font')) do
					if v == f then return k end
				end
			end
		end)()
	}
}
local events = {
	FRAMES_UPDATED = "ChatEvent_FramesUpdated",
}
local mustUseAlt = true -- select(4, _G.GetBuildInfo()) >= 50400
local backgrounds, borders, fonts = {}, {}, {}
local CreateFrame = _G.CreateFrame
local max = _G.max
local pairs = _G.pairs
local select = _G.select

local VALID_ATTACH_POINTS = {
	TOP = 'Top',
	BOTTOM = 'Bottom',
	FREE = 'Free-floating',
	LOCK = 'Free-floating, Locked'
}

local function updateEditBox(method, ...)
	for i = 1, #CHAT_FRAMES do
		local f = _G["ChatFrame" .. i .. "EditBox"]
		f[method](f, ...)
	end
end

local function MakePratEditbox(self, i)
	if not self.frames[i] then
		local parent = _G["ChatFrame" .. i .. "EditBox"]

		local frame = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate")
		frame:SetFrameStrata("DIALOG")
		frame:SetFrameLevel(parent:GetFrameLevel() - 1)
		frame:SetAllPoints(parent)
		frame:Hide()
		parent.pratFrame = frame
		self.frames[i] = frame

		parent.lDrag = CreateFrame("Frame", nil, parent)
		parent.lDrag:SetWidth(15)
		parent.lDrag:SetPoint("TOPLEFT", parent, "TOPLEFT")
		parent.lDrag:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT")
		parent.lDrag.left = true

		parent.rDrag = CreateFrame("Frame", nil, parent)
		parent.rDrag:SetWidth(15)
		parent.rDrag:SetPoint("TOPRIGHT", parent, "TOPRIGHT")
		parent.rDrag:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT")
	end
end

local function OnArrowPressed(self, key)
	if #self.history_lines == 0 then
		return
	end

	if key == "DOWN" then
		self.history_index = self.history_index - 1

		if self.history_index < 1 then
		self.history_index = #self.history_lines
		end
	elseif key == "UP" then
		self.history_index = self.history_index + 1

		if self.history_index > #self.history_lines then
		self.history_index = 1
		end
	else
		return -- We don't want to interfere with LEFT/RIGHT because the tab-complete stuff might use it; we're already killing the other two.
	end
	self:SetText(self.history_lines[self.history_index])
end

local function enableArrowKeys(e)
	e.history_lines = e.history_lines or {}
	e.history_index = e.history_index or 0
	e:HookScript("OnArrowPressed", OnArrowPressed)
end

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging

	LSM.RegisterCallback(self, 'LibSharedMedia_Registered')
	self.frames = {}

	self:LibSharedMedia_Registered()

	for i = 1, #CHAT_FRAMES do
	MakePratEditbox(self, i)
	end
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	self:LibSharedMedia_Registered();
	for i = 1, #CHAT_FRAMES do
		local f = _G["ChatFrame" .. i .. "EditBox"]
		_G["ChatFrame" .. i .. "EditBoxLeft"]:Hide()
		_G["ChatFrame" .. i .. "EditBoxRight"]:Hide()
		_G["ChatFrame" .. i .. "EditBoxMid"]:Hide()
		if f.focusLeft then f.focusLeft:SetAlpha(0) end
		if f.focusRight then f.focusRight:SetAlpha(0) end
		if f.focusMid then f.focusMid:SetAlpha(0) end
		f:Hide()

		-- Prevent an error in FloatingChatFrame FCF_FadeOutChatFrame() (blizz bug)
		f:SetAlpha(f:GetAlpha() or 0)

		MakePratEditbox(self, i) -- For new temporary chat frames created between init and now
		self.frames[i]:Show()
		local font, s, m = f:GetFont()
		f:SetFont(LSM:Fetch("font", self.db.profile.font), s, m)

		local header = _G[f:GetName() .. "Header"]
		local font, s, m = header:GetFont()
		header:SetFont(LSM:Fetch("font", self.db.profile.font), s, m)

		f:SetAltArrowKeyMode(mod.db.profile.useAltKey and 1 or nil)
		if (not mod.db.profile.useAltKey) then
		enableArrowKeys(f)
		end
	end

	self:SetBackdrop()

	self:SetAttach(nil, self.db.profile.editX, self.db.profile.editY, self.db.profile.editW)
	self:SecureHook("ChatEdit_DeactivateChat")
	self:SecureHook("ChatEdit_SetLastActiveWindow")
	self:SecureHook("ChatFrame_OpenChat")

	self:SetBackdrop()
	self:UpdateHeight()
	if self.db.profile.colorByChannel then
		self:RawHook("ChatEdit_UpdateHeader", "SetBorderByChannel", true)
	end
	self:SecureHook("FCF_Tab_OnClick")

	CT.RegisterChatEvent(self, events.FRAMES_UPDATED)
	--self:RegisterChatEvent(events.FRAMES_UPDATED, 'ChatEvent_FramesUpdated')
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	self:SetAttach("BOTTOM") -- clear move/resize handlers
	for i = 1, #CHAT_FRAMES do
		local f = _G["ChatFrame" .. i .. "EditBox"]
		_G["ChatFrame" .. i .. "EditBoxLeft"]:Show()
		_G["ChatFrame" .. i .. "EditBoxRight"]:Show()
		_G["ChatFrame" .. i .. "EditBoxMid"]:Show()
		if f.focusLeft then f.focusLeft:SetAlpha(1) end
		if f.focusRight then f.focusRight:SetAlpha(1) end
		if f.focusMid then f.focusMid:SetAlpha(1) end
		f:SetAltArrowKeyMode(true)
		f:EnableMouse(true)
		f.pratFrame:Hide()
		-- restore Blizz size/position
		f:ClearAllPoints()
		f:SetHeight(32)
		f:SetPoint("TOPLEFT", f.chatFrame, "BOTTOMLEFT", -5, -2)
		f:SetPoint("RIGHT", f.chatFrame.ScrollBar, "RIGHT", 5, 0)
	end
end

function Module:GetOptions()
	if not options then
		options = {
			background = {
				type = 'select',
				name = 'Background texture',
				desc = 'Background texture',
				values = LSM:HashTable('background'),
				dialogControl = 'LSM30_Background',
				get = function() return mod.db.profile.background end,
				set = function(info, v)
					mod.db.profile.background = v
					mod:SetBackdrop()
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			border = {
				type = 'select',
				name = 'Border texture',
				desc = 'Border texture',
				dialogControl = "LSM30_Border",
				values = LSM:HashTable("border"),
				get = function() return mod.db.profile.border end,
				set = function(info, v)
					mod.db.profile.border = v
					mod:SetBackdrop()
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			backgroundColor = {
				type = 'color',
				name = 'Background color',
				desc = 'Background color',
				hasAlpha = true,
				get = function()
					local c = mod.db.profile.backgroundColor
					return c.r, c.g, c.b, c.a
				end,
				set = function(info, r, g, b, a)
					local c = mod.db.profile.backgroundColor
					c.r, c.g, c.b, c.a = r, g, b, a
					mod:SetBackdrop()
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			borderColor = {
				type = 'color',
				name = 'Border color',
				desc = 'Border color',
				hasAlpha = true,
				get = function()
					local c = mod.db.profile.borderColor
					return c.r, c.g, c.b, c.a
				end,
				set = function(info, r, g, b, a)
					local c = mod.db.profile.borderColor
					c.r, c.g, c.b, c.a = r, g, b, a
					mod:SetBackdrop()
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			inset = {
				type = 'range',
				name = 'Background Inset',
				desc = 'Background Inset',
				min = 1,
				max = 64,
				step = 1,
				bigStep = 1,
				get = function() return mod.db.profile.inset end,
				set = function(info, v)
					mod.db.profile.inset = v
					mod:SetBackdrop()
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			tileSize = {
				type = 'range',
				name = 'Tile Size',
				desc = 'Tile Size',
				min = 1,
				max = 64,
				step = 1,
				bigStep = 1,
				get = function() return mod.db.profile.tileSize end,
				set = function(info, v)
					mod.db.profile.tileSize = v
					mod:SetBackdrop()
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			edgeSize = {
				type = 'range',
				name = 'Edge Size',
				desc = 'Edge Size',
				min = 1,
				max = 64,
				step = 1,
				bigStep = 1,
				get = function() return mod.db.profile.edgeSize end,
				set = function(info, v)
					mod.db.profile.edgeSize = v
					mod:SetBackdrop()
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			attach = {
				type = 'select',
				name = 'Attach to...',
				desc = 'Attach edit box to...',
				get = function() return mod.db.profile.attach end,
				values = VALID_ATTACH_POINTS,
				set = function(info, v)
					mod.db.profile.attach = v
					mod:SetAttach()
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			colorByChannel = {
				type = 'toggle',
				name = 'Color border by channel',
				desc = 'Sets the frame\'s border color to the color of your currently active channel',
				get = function()
					return mod.db.profile.colorByChannel
				end,
				set = function(info, v)
					mod.db.profile.colorByChannel = v
					if v then
					mod:RawHook("ChatEdit_UpdateHeader", "SetBorderByChannel", true)
					else
					if mod:IsHooked("ChatEdit_UpdateHeader") then
						mod:Unhook("ChatEdit_UpdateHeader")
						local c = mod.db.profile.borderColor
						for _, frame in ipairs(mod.frames) do
							frame:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
						end
					end
					end
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			useAltKey = {
				type = 'toggle',
				name = 'Use Alt key for cursor movement',
				desc = 'Requires the Alt key to be held down to move the cursor in chat',
				get = function()
					return mod.db.profile.useAltKey
				end,
				set = function(info, v)
					mod.db.profile.useAltKey = v
					updateEditBox("SetAltArrowKeyMode", v)
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			font = {
				type = 'select',
				name = 'Font',
				desc = 'Select the font to use for the edit box',
				values = LSM:HashTable('font'),
				dialogControl = "LSM30_Font",
				get = function() return mod.db.profile.font end,
				set = function(i, v)
					mod.db.profile.font = v
					for i = 1, #CHAT_FRAMES do
						local ff = _G["ChatFrame" .. i .. "EditBox"]
						local header = _G[ff:GetName() .. "Header"]
						local _, s, m = ff:GetFont()
						local font = LSM:Fetch("font", v)
						ff:SetFont(font, s, m)
						header:SetFont(font, s, m)
					end
					-- for i = 1, NUM_CHAT_WINDOWS do
					-- 	local ff = _G["ChatFrame"..i.."EditBox"]
					-- 	local _, s, m = ff:GetFont()
					-- 	ff:SetFont(LSM:Fetch("font", v), s, m)
					-- end
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			height = {
				type = 'range',
				name = 'Height',
				desc = 'Select the height of the edit box',
				min = 5,
				max = 50,
				step = 1,
				bigStep = 1,
				get = function() return mod.db.profile.height end,
				set = function(i, v)
					mod.db.profile.height = v
					mod:UpdateHeight()
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			info = {
				name = 'Arrow key behaviour broken in current WoW client, Use ALT-UP and ALT-DOWN instead of just UP DOWN to access history';
				type = "description",
				hidden = not mustUseAlt;
				order = 1000;
			},
		}
    end
    return options
end

function Module:Info()
	return 'Lets you customize the position and look of the edit box'
end
-----------------------------------------------------------------------
-- Addon Logic
-----------------------------------------------------------------------
function mod:LibSharedMedia_Registered()
	for k, v in pairs(LSM:List("background")) do
		backgrounds[v] = v
	end
	for k, v in pairs(LSM:List("border")) do
		borders[v] = v
	end
	for k, v in pairs(LSM:List("font")) do
		fonts[v] = v
	end
end

function mod:ChatEvent_FramesUpdated(info, name, chatFrame, ...)
	local i = chatFrame:GetID()
	local f = _G["ChatFrame" .. i .. "EditBox"]
	_G["ChatFrame" .. i .. "EditBoxLeft"]:Hide()
	_G["ChatFrame" .. i .. "EditBoxRight"]:Hide()
	_G["ChatFrame" .. i .. "EditBoxMid"]:Hide()
	if f.focusLeft then f.focusLeft:SetAlpha(0) end
	if f.focusRight then f.focusRight:SetAlpha(0) end
	if f.focusMid then f.focusMid:SetAlpha(0) end
	f:Hide()

	MakePratEditbox(self, i)
	self.frames[i]:Show()

	local font, s, m = f:GetFont()
	f:SetFont(LSM:Fetch("font", self.db.profile.font), s, m)

	local header = _G[f:GetName() .. "Header"]
	local font, s, m = header:GetFont()
	header:SetFont(LSM:Fetch("font", self.db.profile.font), s, m)

	f:SetAltArrowKeyMode(mod.db.profile.useAltKey and 1 or nil)
	if (not mod.db.profile.useAltKey) then
		enableArrowKeys(f)
	end
	self:SetBackdrop()
	self:UpdateHeight()
	self:SetAttach(nil, self.db.profile.editX, self.db.profile.editY, self.db.profile.editW)
end

function mod:ChatFrame_OpenChat(text, chatFrame)
	if not self.db.profile.useAltKey then
		local frame = ChatEdit_ChooseBoxForSend(chatFrame)

		frame.history_index = 0
	end
end

function mod:FCF_Tab_OnClick(frame, button)
	if self.db.profile.attach == "TOP" and GetCVar("chatStyle") ~= "classic" then
		local chatFrame = _G["ChatFrame" .. frame:GetID()];
		ChatEdit_DeactivateChat(chatFrame.editBox)
	end
end

-- changed the Hide to SetAlpha(0), the new ChatSystem OnHide handlers go though some looping
-- when in IM style and Classic style, cause heavy delays on the chat edit box.
function mod:ChatEdit_SetLastActiveWindow(frame)
	if frame:IsShown() then
		frame:SetAlpha(0)
	else
		frame:SetAlpha(1)
	end
	frame:EnableMouse(true)
end

function mod:ChatEdit_DeactivateChat(frame)
	if frame:IsShown() then
		frame:SetAlpha(0)
		frame:EnableMouse(false)
	end
end

function mod:SetBackdrop()
	for _, frame in ipairs(self.frames) do
		frame:SetBackdrop({
		bgFile = LSM:Fetch("background", self.db.profile.background),
		edgeFile = LSM:Fetch("border", self.db.profile.border),
		tile = true,
		tileSize = self.db.profile.tileSize,
		edgeSize = self.db.profile.edgeSize,
		insets = {
			left = self.db.profile.inset,
			right = self.db.profile.inset,
			top = self.db.profile.inset,
			bottom = self.db.profile.inset
		}
		})
		local c = self.db.profile.backgroundColor
		frame:SetBackdropColor(c.r, c.g, c.b, c.a)

		local c = self.db.profile.borderColor
		frame:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
	end
end

function mod:SetBorderByChannel(...)
	self.hooks.ChatEdit_UpdateHeader(...)
	for index, frame in ipairs(self.frames) do
		local f = _G["ChatFrame" .. index .. "EditBox"]
		local attr = f:GetAttribute("chatType")
		if attr == "CHANNEL" then
		local chan = f:GetAttribute("channelTarget")
		if chan == 0 then
			local c = self.db.profile.borderColor
			frame:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
		elseif chan and ChatTypeInfo["CHANNEL" .. chan] then
			local r, g, b = GetMessageTypeColor("CHANNEL" .. chan)
			frame:SetBackdropBorderColor(r, g, b, 1)
		end
		else
		local r, g, b = GetMessageTypeColor(attr)
		frame:SetBackdropBorderColor(r, g, b, 1)
		end
	end
end

do
	local function startMoving(self)
		self:StartMoving()
	end

	local function stopMoving(self)
		self:StopMovingOrSizing()
		mod.db.profile.editX = self:GetLeft()
		mod.db.profile.editY = self:GetTop()
		mod.db.profile.editW = self:GetRight() - self:GetLeft()
	end

	local cfHeight
	local function constrainHeight(self)
		self:GetParent():SetHeight(cfHeight)
	end

	local function startDragging(self)
		cfHeight = self:GetParent():GetHeight()
		self:GetParent():StartSizing(not self.left and "TOPRIGHT" or "TOPLEFT")
		self:SetScript("OnUpdate", constrainHeight)
	end

	local function stopDragging(self)
		local parent = self:GetParent()
		parent:StopMovingOrSizing()
		self:SetScript("OnUpdate", nil)
		mod.db.profile.editX = parent:GetLeft()
		mod.db.profile.editY = parent:GetTop()
		mod.db.profile.editW = parent:GetWidth()
	end

	function mod:SetAttach(val, x, y, w)
		for i = 1, #CHAT_FRAMES do
			local frame = _G["ChatFrame" .. i .. "EditBox"]
			local val = val or self.db.profile.attach
			if not x and val == "FREE" then
				if self.db.profile.editX and self.db.profile.editY then
					x, y, w = self.db.profile.editX, self.db.profile.editY, self.db.profile.editW
				else
					x, y, w = frame:GetLeft(), frame:GetTop(), max(frame:GetWidth(), (frame:GetRight() or 0) - (frame:GetLeft() or 0))
				end
			end
			if not w or w < 10 then w = 100 end
			frame:ClearAllPoints()
			if val ~= "FREE" then
				frame:SetMovable(false)
				frame.lDrag:EnableMouse(false)
				frame.rDrag:EnableMouse(false)
				frame:SetScript("OnMouseDown", nil)
				frame:SetScript("OnMouseUp", nil)
				frame.lDrag:EnableMouse(false)
				frame.rDrag:EnableMouse(false)
				frame.lDrag:SetScript("OnMouseDown", nil)
				frame.rDrag:SetScript("OnMouseDown", nil)
				frame.lDrag:SetScript("OnMouseUp", nil)
				frame.rDrag:SetScript("OnMouseUp", nil)
			end

			local scrollbarWidth = frame.chatFrame.ScrollBar and frame.chatFrame.ScrollBar:GetWidth() or 0
			if val == "TOP" then
				frame:SetPoint("BOTTOMLEFT", frame.chatFrame, "TOPLEFT", 0, 3)
				frame:SetPoint("BOTTOMRIGHT", frame.chatFrame, "TOPRIGHT", scrollbarWidth, 3)
			elseif val == "BOTTOM" then
				frame:SetPoint("TOPLEFT", frame.chatFrame, "BOTTOMLEFT", 0, -8)
				frame:SetPoint("TOPRIGHT", frame.chatFrame, "BOTTOMRIGHT", scrollbarWidth, -8)
			elseif val == "FREE" then
				frame:EnableMouse(true)
				frame:SetMovable(true)
				frame:SetResizable(true)
				frame:SetScript("OnMouseDown", startMoving)
				frame:SetScript("OnMouseUp", stopMoving)
				frame:SetWidth(w)
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
				local minWidth, minHeight = 40, 1
				if frame.SetResizeBounds then
					frame:SetResizeBounds(minWidth, minHeight)
				else
					frame:SetMinResize(minWidth, minHeight)
				end

				frame.lDrag:EnableMouse(true)
				frame.rDrag:EnableMouse(true)

				frame.lDrag:SetScript("OnMouseDown", startDragging)
				frame.rDrag:SetScript("OnMouseDown", startDragging)

				frame.lDrag:SetScript("OnMouseUp", stopDragging)
				frame.rDrag:SetScript("OnMouseUp", stopDragging)
			elseif val == "LOCK" then
				frame:SetWidth(self.db.profile.editW or w)
				frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", self.db.profile.editX or x, self.db.profile.editY or y)
			end
		end
	end
end

function mod:UpdateHeight()
	for i, frame in ipairs(self.frames) do
		local ff = _G["ChatFrame" .. i .. "EditBox"]
		ff:SetHeight(mod.db.profile.height)
	end
end
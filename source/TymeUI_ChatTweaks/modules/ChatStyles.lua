-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'ChatStyles';
local displayName = 'Chat Styles';
local _G = getfenv(0)
local GetPhysicalScreenSize = GetPhysicalScreenSize

-----------------------------------------------------------------------
-- internal libraries
-----------------------------------------------------------------------
local CTConstants = private.ImportLib('CTConstants')
local CTLogger = private.ImportLib('CTLogger')

-----------------------------------------------------------------------
-- external libraries
-----------------------------------------------------------------------
local LibStub = _G.LibStub
local AceAddon = LibStub('AceAddon-3.0')
local LSM = LibStub('LibSharedMedia-3.0')
-----------------------------------------------------------------------
-- Module Methods
-----------------------------------------------------------------------
local CT = AceAddon:GetAddon(CTConstants.ADDON_NAME)
local Module = CT:NewModule(moduleName, 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0');
local Chat = Module;
Module.name = moduleName
Module.displayName = displayName

local db, options

local defaults = {
	profile = {
		fade = true,
		inactivityTimer = 100,
		font = 'PT Sans Narrow',
		fontOutline = 'NONE',
		fontSize = 10,
		fontStyle = 'OUTLINE',
		maxLines = 100,
		historySize = 100,
		editboxHistorySize = 20,
		tabFont = 'PT Sans Narrow',
		tabFontSize = 12,
		tabFontOutline = 'NONE',
	}
}

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable');
	Chat:SetupChat()
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	self:UnregisterAllEvents()
	StaticPopup_Show('CONFIG_RL')
end

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging
end

function Module:Info()
	return "Override blizzard default chat style/skin"
end

function Module:GetOptions()
	if not options then
		options = {}
	end
	return options
end
-----------------------------------------------------------------------
-- Addon Logic
-----------------------------------------------------------------------
Chat.HiddenFrame = CreateFrame('Frame', nil, _G.UIParent)
Chat.HiddenFrame:SetPoint('BOTTOM')
Chat.HiddenFrame:SetSize(1,1)
Chat.HiddenFrame:Hide()
Chat.media = {
	normFont = LSM:Fetch('font', CTConstants.general.font)
}
Chat.texts = {}
Chat.physicalWidth, Chat.physicalHeight = GetPhysicalScreenSize()
Chat.perfect = 768 / Chat.physicalHeight
Chat.mult = Chat.perfect / CTConstants.general.UIScale

Chat.Scale = function(x)
	local m = Chat.mult
	if m == 1 or x == 0 then
		return x
	else
		local y = m > 1 and m or -m
		return x - x % (x < 0 and y or -y)
	end
end

local tabTexs = {
	'',
	'Selected',
	'Active',
	'Highlight'
}

local StripTexturesBlizzFrames = {
	'Inset',
	'inset',
	'InsetFrame',
	'LeftInset',
	'RightInset',
	'NineSlice',
	'BG',
	'border',
	'Border',
	'BorderFrame',
	'bottomInset',
	'BottomInset',
	'bgLeft',
	'bgRight',
	'FilligreeOverlay',
	'PortraitOverlay',
	'ArtOverlayFrame',
	'Portrait',
	'portrait',
	'ScrollFrameBorder',
}

local STRIP_TEX = 'Texture'
local STRIP_FONT = 'FontString'

local function Point(obj, arg1, arg2, arg3, arg4, arg5, ...)
	if not arg2 then arg2 = obj:GetParent() end

	if type(arg2)=='number' then arg2 = Chat.Scale(arg2) end
	if type(arg3)=='number' then arg3 = Chat.Scale(arg3) end
	if type(arg4)=='number' then arg4 = Chat.Scale(arg4) end
	if type(arg5)=='number' then arg5 = Chat.Scale(arg5) end

	obj:SetPoint(arg1, arg2, arg3, arg4, arg5, ...)
end

local function Width(frame, width, ...)
	frame:SetWidth(Chat.Scale(width), ...)
end

local function Height(frame, height, ...)
	frame:SetHeight(Chat.Scale(height), ...)
end

local function Kill(object)
	if object.UnregisterAllEvents then
		object:UnregisterAllEvents()
		object:SetParent(Chat.HiddenFrame)
	else
		object.Show = object.Hide
	end

	object:Hide()
end

local function StripRegion(which, object, kill, zero)
	if kill then
		object:Kill()
	elseif zero then
		object:SetAlpha(0)
	elseif which == STRIP_TEX then
		object:SetTexture('')
		object:SetAtlas('')
	elseif which == STRIP_FONT then
		object:SetText('')
	end
end

local function StripType(which, object, kill, zero)
	if object:IsObjectType(which) then
		StripRegion(which, object, kill, zero)
	else
		if which == STRIP_TEX then
			local FrameName = object.GetName and object:GetName()
			for _, Blizzard in pairs(StripTexturesBlizzFrames) do
				local BlizzFrame = object[Blizzard] or (FrameName and _G[FrameName..Blizzard])
				if BlizzFrame and BlizzFrame.StripTextures then
					BlizzFrame:StripTextures(kill, zero)
				end
			end
		end

		if object.GetNumRegions then
			for _, region in next, { object:GetRegions() } do
				if region and region.IsObjectType and region:IsObjectType(which) then
					StripRegion(which, region, kill, zero)
				end
			end
		end
	end
end

local function StripTextures(object, kill, zero)
	StripType(STRIP_TEX, object, kill, zero)
end

local function FontTemplate(fs, font, size, style, skip)
	if not skip then -- ignore updates from UpdateFontTemplates
		fs.font, fs.fontSize, fs.fontStyle = font, size, style
	end

	-- grab values from profile before conversion
	if not style then style = db.fontStyle or CTConstants.general.fontStyle end
	if not size then size = db.fontSize or CTConstants.general.fontSize end

	-- shadow mode when using 'NONE'
	if style == 'NONE' then
		fs:SetShadowOffset(1, -0.5)
		fs:SetShadowColor(0, 0, 0, 1)
	else
		fs:SetShadowOffset(0, 0)
		fs:SetShadowColor(0, 0, 0, 0)
	end

	-- convert because of bad values between versions
	if style == 'NONE' and CTConstants.Retail then
		style = ''
	elseif style == '' and not CTConstants.Retail then
		style = 'NONE'
	end

	fs:SetFont(font or Chat.media.normFont, size, style)

	Chat.texts[fs] = true
end

local function addapi(object)
	local mk = getmetatable(object).__index

	if not object.Point then mk.Point = Point end
	if not object.Width then mk.Width = Width end
	if not object.Height then mk.Height = Height end
	if not object.Kill then mk.Kill = Kill end
	if not object.FontTemplate then mk.FontTemplate = FontTemplate end
	if not object.StripTextures then mk.StripTextures = StripTextures end
end

function Chat:GetOwner(tab)
	if not tab.owner then
		tab.owner = _G[format('ChatFrame%s', tab:GetID())]
	end

	return tab.owner
end

function Chat:UpdateFontTemplates()
	for text in pairs(Chat.texts) do
		if text then
			text:FontTemplate(text.font, text.fontSize, text.fontStyle, true)
		else
			Chat.texts[text] = nil
		end
	end
end

function Chat:ChatFrameTab_SetAlpha(_, skip)
	if skip then return end
	local chat = Chat:GetOwner(self)
	self:SetAlpha((not chat.isDocked or self.selected) and 1 or 0.6, true)
end

function Chat:GetTab(chat)
	if not chat.tab then
		chat.tab = _G[format('ChatFrame%sTab', chat:GetID())]
	end

	return chat.tab
end

function Chat:StyleChat(frame)
	local name = frame:GetName()
	local tab = self:GetTab(frame)
	local id = frame:GetID()
	local _, fontSize = _G.FCF_GetChatWindowInfo(id);
	local font, size, outline = LSM:Fetch('font', db.font), fontSize, db.fontOutline
	
	frame:FontTemplate(font, size, outline)
	frame:SetTimeVisible(db.inactivityTimer)
	frame:SetMaxLines(db.maxLines)
	frame:SetFading(db.fade)

	tab.Text:FontTemplate(LSM:Fetch('font', db.tabFont), db.tabFontSize, db.tabFontOutline)

	if frame.styled then return end

	frame:SetFrameLevel(4)
	frame:SetClampRectInsets(0,0,0,0)
	frame:SetClampedToScreen(false)
	frame:StripTextures(true)

	_G[name..'ButtonFrame']:Kill()

	local scrollTex = _G[name..'ThumbTexture']
	local scrollToBottom = frame.ScrollToBottomButton
	local scroll = frame.ScrollBar
	local editbox = frame.editBox

	if scroll then
		scroll:Kill()
		scrollToBottom:Kill()
		scrollTex:Kill()
	end

	--Character count
	local charCount = editbox:CreateFontString(nil, 'ARTWORK')
	charCount:FontTemplate()
	charCount:SetTextColor(190, 190, 190, 0.4)
	charCount:Point('TOPRIGHT', editbox, 'TOPRIGHT', -5, 0)
	charCount:Point('BOTTOMRIGHT', editbox, 'BOTTOMRIGHT', -5, 0)
	charCount:SetJustifyH('CENTER')
	charCount:Width(40)
	editbox.characterCount = charCount

	for _, texName in pairs(tabTexs) do
		local t, l, m, r = name..'Tab', texName..'Left', texName..'Middle', texName..'Right'
		local main = _G[t]
		local left = _G[t..l] or (main and main[l])
		local middle = _G[t..m] or (main and main[m])
		local right = _G[t..r] or (main and main[r])

		if left then left:SetTexture() end
		if middle then middle:SetTexture() end
		if right then right:SetTexture() end
	end

	hooksecurefunc(tab, 'SetAlpha', Chat.ChatFrameTab_SetAlpha)

	if not tab.Left then
		tab.Left = _G[name..'TabLeft'] or _G[name..'Tab'].Left
	end

	tab.Text:ClearAllPoints()
	tab.Text:Point('LEFT', tab, 'LEFT', tab.Left:GetWidth(), 0)
	tab:Height(22)

	if tab.conversationIcon then
		tab.conversationIcon:ClearAllPoints()
		tab.conversationIcon:Point('RIGHT', tab.Text, 'LEFT', -1, 0)
	end

	if CTConstants.Retail then -- wtf is this lol
		local a, b, c = select(6, editbox:GetRegions())
		a:Kill()
		b:Kill()
		c:Kill()
	end

	--_G[name..'EditBoxLeft']:Kill()
	--_G[name..'EditBoxMid']:Kill()
	--_G[name..'EditBoxRight']:Kill()

	--editbox:SetAltArrowKeyMode(db.useAltKey)
	--editbox:SetAllPoints(_G.LeftChatDataPanel)
	-- editbox:HookScript('OnTextChanged', Chat.EditBoxOnTextChanged)
	-- editbox:HookScript('OnEditFocusGained', Chat.EditBoxFocusGained)
	-- editbox:HookScript('OnEditFocusLost', Chat.EditBoxFocusLost)
	-- editbox:HookScript('OnKeyDown', Chat.EditBoxOnKeyDown)
	--editbox:Hide()

	--Work around broken SetAltArrowKeyMode API
	-- editbox.historyLines = ChatTweaksCharacterDB.ChatEditHistory
	-- editbox.historyIndex = 0

	--[[ Don't need to do this since SetAltArrowKeyMode is broken, keep before AddHistory hook
	for _, text in ipairs(editbox.historyLines) do
			editbox:AddHistoryLine(text)
	end]]

	--Chat:SecureHook(editbox, 'AddHistoryLine', 'ChatEdit_AddHistory')

	--copy chat button
	-- local copyButton = CreateFrame('Frame', format('ElvUI_CopyChatButton%d', id), frame)
	-- copyButton:EnableMouse(true)
	-- copyButton:SetAlpha(0.35)
	-- copyButton:Size(20, 22)
	-- copyButton:Point('TOPRIGHT', 0, -4)
	-- copyButton:SetFrameLevel(frame:GetFrameLevel() + 5)
	-- frame.copyButton = copyButton

	-- local copyTexture = frame.copyButton:CreateTexture(nil, 'OVERLAY')
	-- copyTexture:SetInside()
	-- copyTexture:SetTexture(E.Media.Textures.Copy)
	-- copyButton.texture = copyTexture

	-- copyButton:SetScript('OnMouseUp', CH.CopyButtonOnMouseUp)
	-- copyButton:SetScript('OnEnter', CH.CopyButtonOnEnter)
	-- copyButton:SetScript('OnLeave', CH.CopyButtonOnLeave)
	-- CH:ToggleChatButton(copyButton)
	frame.styled = true
end

function Chat:SetupChat()
	
	for _, frameName in ipairs(_G.CHAT_FRAMES) do
		local frame = _G[frameName]
		local id = frame:GetID()
		Chat:StyleChat(frame)

		_G.FCFTab_UpdateAlpha(frame)
	end
end


local handled = {Frame = true}
local object = CreateFrame('Frame')
addapi(object)
addapi(object:CreateTexture())
addapi(object:CreateFontString())
addapi(object:CreateMaskTexture())

object = EnumerateFrames()
while object do
	local objType = object:GetObjectType()
	if not object:IsForbidden() and not handled[objType] then
		addapi(object)
		handled[objType] = true
	end

	object = EnumerateFrames(object)
end
addapi(_G.GameFontNormal) --Add API to `CreateFont` objects without actually creating one
addapi(CreateFrame('ScrollFrame')) --Hacky fix for issue on 7.1 PTR where scroll frames no longer seem to inherit the methods from the 'Frame' widget
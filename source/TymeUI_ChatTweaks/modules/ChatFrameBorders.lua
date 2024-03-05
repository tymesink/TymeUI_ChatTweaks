-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------local ADDON_NAME, private = ...
local ADDON_NAME, private = ...
local moduleName = 'ChatFrameBorders';
local displayName = 'Borders/Background';
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
local LSM = LibStub("LibSharedMedia-3.0")
-----------------------------------------------------------------------
-- Module Methods
-----------------------------------------------------------------------
local CT = AceAddon:GetAddon(CTConstants.ADDON_NAME)
local Module = CT:NewModule(moduleName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
Module.name = moduleName
Module.displayName = displayName
Module.frames = {}

local createFrame = _G.CreateFrame
local pairs = _G.pairs
local tinsert = _G.tinsert
local type = _G.type
local db
local options = {}
local defaults = {
	profile = {
		frames = {}
	}
}

local frame_defaults = {
	enable = false,
	combatLogFix = false,
	background = "Blizzard Tooltip",
	border = "Blizzard Tooltip",
	inset = 3,
	edgeSize = 12,
	backgroundColor = { r = 0, g = 0, b = 0, a = 1 },
	borderColor = { r = 1, g = 1, b = 1, a = 1 },
}

local function deepcopy(tbl)
   local new = {}
   for key,value in pairs(tbl) do
      new[key] = type(value) == "table" and deepcopy(value) or value -- if it's a table, run deepCopy on it too, so we get a copy and not the original
   end
   return new
end

function Module:OnInitialize()
	for i = 1, NUM_CHAT_WINDOWS do
		defaults.profile.frames["FRAME_" .. i] = deepcopy(frame_defaults)
		if _G["ChatFrame" .. i] == COMBATLOG then
			defaults.profile.frames["FRAME_" .. i].enable = false
		end
	end
	defaults.profile.frames.FRAME_2.combatLogFix = true

	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging

	LSM.RegisterCallback(Module, "LibSharedMedia_Registered")
	for i = 1, NUM_CHAT_WINDOWS do
		local cf = _G["ChatFrame" .. i]
		local frame = createFrame("Frame", nil, cf, "ChatFrameBorderTemplate")
		frame:EnableMouse(false)
		cf:SetFrameStrata("LOW")
		frame:SetFrameStrata("BACKGROUND")
		frame:SetFrameLevel(1)
		frame:Hide()
		frame.id = "FRAME_" .. i
		tinsert(self.frames, frame)
		local t = {
			type = 'group',
			name = 'Chat Frame ' .. i,
			desc = 'Chat Frame ' .. i,
			disabled = function() return not Module:IsEnabled() end,
			args = {
				enable = {
					type = 'toggle',
					name = 'Enable',
					desc = 'Enable borders on this frame',
					order = 1,
					get = function()
						return db.frames[frame.id].enable
					end,
					set = function(info, v)
						db.frames[frame.id].enable = v
						if v then
							frame:Show()
						else
							frame:Hide()
						end
					end
				},
				combatLogFix = {
					type = 'toggle',
					name = 'Combat Log Fix',
					desc = 'Resize this border to fit the new combat log',
					get = function() return db.frames[frame.id].combatLogFix end,
					set = function(info, v)
						db.frames[frame.id].combatLogFix = v
						Module:SetAnchors(frame, v)
					end
				},
				background = {
					type = "select",
					name = 'Background texture',
					desc = 'Background texture',
					dialogControl = "LSM30_Background",
					values = LSM:HashTable("background"),
					get = function() return db.frames[frame.id].background end,
					set = function(info, v)
						db.frames[frame.id].background = v
						Module:SetBackdrop(frame)
					end
				},
				border = {
					type = "select",
					name = 'Border texture',
					desc = 'Border texture',
					dialogControl = "LSM30_Border",
					values = LSM:HashTable("border"),
					get = function() return db.frames[frame.id].border end,
					set = function(info, v)
						db.frames[frame.id].border = v
						Module:SetBackdrop(frame)
					end
				},
				backgroundColor = {
					type = "color",
					name = 'Background color',
					desc = 'Background color',
					hasAlpha = true,
					get = function()
						local c = db.frames[frame.id].backgroundColor
						return c.r, c.g, c.b, c.a
					end,
					set = function(info, r, g, b, a)
						local c = db.frames[frame.id].backgroundColor
						c.r, c.g, c.b, c.a = r, g, b, a
						Module:SetBackdrop(frame)
					end
				},
				borderColor = {
					type = "color",
					name = 'Border color',
					desc = 'Border color',
					hasAlpha = true,
					get = function()
						local c = db.frames[frame.id].borderColor
						return c.r, c.g, c.b, c.a
					end,
					set = function(info, r, g, b, a)
						local c = db.frames[frame.id].borderColor
						c.r, c.g, c.b, c.a = r, g, b, a
						Module:SetBackdrop(frame)
					end
				},
				inset = {
					type = "range",
					name = 'Background Inset',
					desc = 'Background Inset',
					min = 1,
					max = 64,
					step = 1,
					bigStep = 1,
					get = function() return db.frames[frame.id].inset end,
					set = function(info, v)
						db.frames[frame.id].inset = v
						Module:SetBackdrop(frame)
					end
				},
				tileSize = {
					type = "range",
					name = 'Tile Size',
					desc = 'Tile Size',
					min = 1,
					max = 64,
					step = 1,
					bigStep = 1,
					get = function() return db.frames[frame.id].tileSize end,
					set = function(info, v)
						db.frames[frame.id].tileSize = v
						Module:SetBackdrop(frame)
					end
				},
				edgeSize = {
					type = "range",
					name = 'Edge Size',
					desc = 'Edge Size',
					min = 1,
					max = 64,
					step = 1,
					bigStep = 1,
					get = function() return db.frames[frame.id].edgeSize end,
					set = function(info, v)
						db.frames[frame.id].edgeSize = v
						Module:SetBackdrop(frame)
					end
				}
			}
		}
		options[frame.id] = t
	end
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	self:LibSharedMedia_Registered()
	self:SetBackdrops()
	for i = 1, #self.frames do
		if db.frames and db.frames["FRAME_" .. i].enable then
			self.frames[i]:Show()
		end
		Module:SetAnchors(Module.frames[i], db.frames["FRAME_" .. i].combatLogFix)
	end
	LSM.RegisterCallback(Module, "LibSharedMedia_Registered")
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	for i = 1, #self.frames do
		self.frames[i]:Hide()
	end
end

function Module:GetOptions()
	return options
end

function Module:Info()
	return 'Gives you finer control over the chat frame\'s background and border colors'
end

function Module:LibSharedMedia_Registered()
	Module:SetBackdrops()
end

function Module:Decorate(cf)
	local frame = createFrame("Frame", nil, cf, "ChatFrameBorderTemplate")
	frame:EnableMouse(false)
	cf:SetFrameStrata("LOW")
	frame:SetFrameStrata("BACKGROUND")
	frame:SetFrameLevel(1)
	frame:Hide()
	frame.id = "FRAME_1"
	tinsert(self.frames, frame)
	self:SetBackdrops()
	frame:Show()
	Module:SetAnchors(frame, db.frames["FRAME_1"].combatLogFix)
end

function Module:SetBackdrops()
	for i = 1, #self.frames do
		self:SetBackdrop(self.frames[i])
	end
end

do
	function Module:SetBackdrop(frame)
		local profile = db.frames[frame.id]
		local doTile = false
		if profile and profile.tileSize and profile.tileSize > 1 then
			doTile = true
		end
		-- Restore pre 9.0 backdrop functionality
		if not frame.SetBackdrop then
			Mixin(frame, BackdropTemplateMixin)
		end
		frame:SetBackdrop({
			bgFile = LSM:Fetch("background", profile.background),
			edgeFile = LSM:Fetch("border", profile.border),
			tile = doTile,
			tileSize = profile.tileSize,
			edgeSize = profile.edgeSize,
			insets = {left = profile.inset, right = profile.inset, top = profile.inset, bottom = profile.inset}
		})
		local cbackdrop = profile.backgroundColor
		frame:SetBackdropColor(cbackdrop.r, cbackdrop.g, cbackdrop.b, cbackdrop.a)

		local cborder = profile.borderColor
		frame:SetBackdropBorderColor(cborder.r, cborder.g, cborder.b, cborder.a)
	end
end

function Module:SetAnchors(frame, fix)
	local p = frame:GetParent()
	frame:ClearAllPoints()
	if fix then
		frame:SetPoint("TOPLEFT", p, "TOPLEFT", -5, 30)
		frame:SetPoint("TOPRIGHT", p, "TOPRIGHT", 5, 30)
		frame:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", -5, -10)
		frame:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 5, -10)
	else
		frame:SetPoint("TOPLEFT", p, "TOPLEFT", -5, 5)
		frame:SetPoint("TOPRIGHT", p, "TOPRIGHT", 5, 5)
		frame:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", -5, -10)
		frame:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 5, -10)
	end
end

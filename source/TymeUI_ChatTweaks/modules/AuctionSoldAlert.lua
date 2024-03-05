-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-- Auction Created/Removed additions courtesy of chutwig.
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'AuctionSoldAlert';
local displayName = 'Auction Sold Alert';
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
-- 
-----------------------------------------------------------------------
local CT = AceAddon:GetAddon(CTConstants.ADDON_NAME)
local Module = CT:NewModule(moduleName)
Module.name = moduleName
Module.displayName = displayName

-----------------------------------------------------------------------
-- local variable / methods
-----------------------------------------------------------------------
local ChatFrame_AddMessageEventFilter = _G["ChatFrame_AddMessageEventFilter"]
local ChatFrame_RemoveMessageEventFilter = _G["ChatFrame_RemoveMessageEventFilter"]

local format = string.format

local db
local options
local defaults = {
	profile = {
		sound = 'Alert',
		master = true,
	}
}

-- regular expressions to use
local AUCTION_SOLD = format(ERR_AUCTION_SOLD_S, "(.+)")

local function filterAuctionMessages(self, event, message)
	if not message then return end
	
	-- do the filtering
	if message:match(AUCTION_SOLD) then 
		if db.sound and db.sound ~= "None" and LSM:IsValid("sound", db.sound) then
			PlaySoundFile(LSM:Fetch("sound", db.sound), db.master and "Master" or nil)
		end
		return true 
	end
	
	return false
end

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", filterAuctionMessages)
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", filterAuctionMessages)
end

function Module:Info()
	return "Notifies when an auction has sold";
end

function Module:GetOptions()
	if not options then
		options = {
			sound = {
				type = "select",
				order = 13,
				dialogControl = "LSM30_Sound",
				name = "Sound",
				desc = "Set the sound to play.",
				values = AceGUIWidgetLSMlists.sound,
				get = function() return db.sound end,
				set = function(_, value) db.sound = value end,
				disabled = function() return not Module:IsEnabled() end
			},
			master = {
				type = "toggle",
				order = 14,
				name = "Use Master Channel",
				desc = "Use the master channel when playing the sound.",
				get = function() return db.master end,
				set = function(_, value) db.master = value end,
				disabled = function() return not Module:IsEnabled() end
			},
		}
	end
	return options
end

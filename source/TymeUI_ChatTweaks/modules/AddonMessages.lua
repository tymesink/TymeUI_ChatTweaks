-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'AddonMessages';
local displayName = 'Addon Messages';
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
local Module = CT:NewModule(moduleName, "AceConsole-3.0", "AceEvent-3.0")
Module.name = moduleName
Module.displayName = displayName

-----------------------------------------------------------------------
-- local variable / methods
-----------------------------------------------------------------------
local db, options
local defaults = {
	profile = {
		frame = "ChatFrame3",
	}
}

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	self:RegisterEvent("CHAT_MSG_ADDON")
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	self:UnregisterAllEvents()
end

function Module:GetOptions()
	if not options then
		options = {
			frame = {
				type = "select",
				order = 13,
				name = "Output Frame",
				desc = "Frame to send the addon messages to.",
				values = function()
					local frames = {}
					for i = 1, 18 do
						local cf = _G[("ChatFrame%d"):format(i)]
						if cf ~= COMBATLOG then
							frames[("ChatFrame%d"):format(i)] = ("Chat Frame %d"):format(i)
						end
					end
					return frames
				end,
				get = function() return db.frame end,
				set = function(_, value) db.frame = value end,
				disabled = function() return not Module:IsEnabled() end
			}
		}
	end
	return options
end

function Module:Info()
	return "Print hidden addon messages in a chat frame.  This can be useful to debugging addon issues."
end

function Module:CHAT_MSG_ADDON(event, arg1, arg2, arg3, arg4)
	if _G[db.frame] then
		_G[db.frame]:AddMessage(("[|cffffff40%s|r][|cffa0a0a0%s|r][|cff40ff40%s|r][|cff4040ff%s|r]"):format(arg1, arg2, arg3, arg4))
	end
end
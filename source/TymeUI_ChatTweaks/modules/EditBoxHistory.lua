-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'EditboxHistory';
local displayName = 'Editbox History';
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

local options, history, enabled
local defaults = { realm = { history = { } } }
local editbox = DEFAULT_CHAT_FRAME.editBox

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	self.debug = CT.db.profile.debugging
	history = self.db.realm.history

	-- Hook adding lines
	self:SecureHook(editbox, "AddHistoryLine" )
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	-- Keeping state if we're enabled or not
	enabled = false
	for _, line in ipairs( history ) do
		editbox:AddHistoryLine( line )
	end
	enabled = true
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	enabled = false
end

function Module:AddHistoryLine( object, line )
	-- While in 'OnEnable' this code just returns
	if not self:IsEnabled() or not enabled then return end

	local history = history
	tinsert( history, line )

	-- clear out the excess values
	for i=1, #history - object:GetHistoryLines() do
		tremove( history, 1 )
	end
end

function Module:GetOptions()
	if not options then
		options = {}
	end
	return options
end

function Module:Info()
	return "Remembers the history of the editbox across sessions."
end

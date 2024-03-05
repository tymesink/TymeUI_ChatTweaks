-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'AchievementFilter';
local displayName = 'Achievement Filter'
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
local Module = CT:NewModule(moduleName, 'AceConsole-3.0')
Module.name = moduleName
Module.displayName = displayName

-----------------------------------------------------------------------
-- local variable / methods
-----------------------------------------------------------------------
local ChatFrame_AddMessageEventFilter = _G["ChatFrame_AddMessageEventFilter"]
local ChatFrame_RemoveMessageEventFilter = _G["ChatFrame_RemoveMessageEventFilter"]
local GetMaxPlayerLevel = _G["GetMaxPlayerLevel"]

local format = string.format

local db, options
local defaults = {
	profile = {
		guild = false,
		nearby = true,
		byLevel = true,
		level = 60,
	}
}

local achievement = format(ACHIEVEMENT_BROADCAST, "(.+)", ".+")
local playerLink = ("|Hplayer:%s|h[%s]|h"):format("(.+)", ".+")

local chatfilter = function(self, event, message)
	if not message or (not db.guild and not db.nearby) then return end

	-- guild achievements
	if db.guild and event == "CHAT_MSG_GUILD_ACHIEVEMENT" and message:match(achievement) then
		if not db.byLevel then
			if Module.debug then Module:Print(message) end
			return true
		else
			-- determine level and filter
			local name = message:match(achievement)
			if not name then return true end -- can't pull name, so just filter
			if name:match(playerLink) then
				local temp = name:match(playerLink)
				name = temp
			end
			local level = UnitLevel(name)

			-- debugging
			if Module.debug then Module:Print(('Level: |cffffff00%s|r, Message: |cffffff00%s|r'):format(level, message)) end

			-- UnitLevel will return -1 if the character we queried is > 10 levels higher than the player
			if level == -1 then
				return true
			elseif level < db.level then
				return true
			else
				return false
			end
		end
	elseif db.nearby and event == "CHAT_MSG_ACHIEVEMENT" and message:match(achievement) then
		if not db.byLevel then
			if Module.debug then Module:Print(message) end
			return true
		else
			-- determine level and filter
			local name = message:match(achievement)
			if not name then return true end -- can't pull name, so just filter
			if name:match(playerLink) then
				local temp = name:match(playerLink)
				name = temp
			end
			local level = UnitLevel(name)

			-- debugging
			if Module.debug then Module:Print(('Level: |cffffff00%s|r, Message: |cffffff00%s|r'):format(level, message)) end

			-- UnitLevel will return -1 if the character we queried is > 10 levels higher than the player
			if level == -1 then
				return true
			elseif level < db.level then
				return true
			else
				return false
			end
		end
	end

	return false
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD_ACHIEVEMENT", chatfilter)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_ACHIEVEMENT", chatfilter)
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_GUILD_ACHIEVEMENT", chatfilter)
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_ACHIEVEMENT", chatfilter)
end

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging
end

function Module:Info()
	return "Filter achievement message spam!"
end

function Module:GetOptions()
	if not options then
		options = {
			guild = {
				type = "toggle",
				order = 13,
				name = "Filter Guild Achievements",
				desc = "Filter achievements earned by guildmates.",
				get = function() return db.guild end,
				set = function(_, value) db.guild = value end,
				disabled = function() return not Module:IsEnabled() end
			},
			nearby = {
				type = "toggle",
				order = 14,
				name = "Filter Nearby Achievements",
				desc = "Filter achievements earned by nearby people.",
				get = function() return db.nearby end,
				set = function(_, value) db.nearby = value end,
				disabled = function() return not Module:IsEnabled() end
			},
			levelOptions = {
				type = "group",
				order = 100,
				guiInline = true,
				name = "Filter by Player Level",
				args = {
					byLevel = {
						type = "toggle",
						order = 1,
						name = "Use Level Threshold",
						desc = "Only filter achievements earned by players below a certain level.",
						get = function() return db.byLevel end,
						set = function(_, value) db.byLevel = value end,
						disabled = function() return not Module:IsEnabled() end
					},
					level = {
						type = "range",
						order = 2,
						name = "Minimum Level",
						desc = "Minimum level required for an achievement to not be filtered.",
						get = function() return db.level end,
						set = function(_, value) db.level = value end,
						min = 1, max = GetMaxPlayerLevel(), step = 1,
						disabled = function()
							if not Module:IsEnabled() then
								return true;
							else
								return not db.byLevel;
							end

						end,
					}
				}
			}
		}
	end
	return options
end

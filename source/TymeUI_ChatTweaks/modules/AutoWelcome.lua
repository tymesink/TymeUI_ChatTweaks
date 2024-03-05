-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'AutoWelcome';
local displayName = 'Auto Welcome';
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
local Module = CT:NewModule(moduleName, "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
Module.name = moduleName
Module.displayName = displayName

-----------------------------------------------------------------------
-- local variable / methods
-----------------------------------------------------------------------
local IsInGuild = _G["IsInGuild"]
local UnitIsAFK = _G["UnitIsAFK"]
local UnitIsDND = _G["UnitIsDND"]
local GetGuildInfo = _G["GetGuildInfo"]

local format = string.format

local db, options
local defaults = {
	profile = {
		dontAlways = true,
		chance = 50,
		minDelay = 1,
		maxDelay = 5,
		phrases = {"Welcome #name#!"},
		afk = true,
		dnd = true,
	}
}

local guildJoin = format(ERR_GUILD_JOIN_S, "(.+)")

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	self:RegisterEvent("CHAT_MSG_SYSTEM")
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
end

function Module:Info()
	return 'Automatically welcomes someone to your guild.'
end

function Module:GetOptions()
	if not options then
		options = {
			dontAlways = {
				type = "toggle",
				order = 13,
				name = 'Dont Always Run',
				desc = 'Enable this to give the module a percent chance to run to prevent spam/annoyances.  If disabled the module will always welcome.',
				get = function() return db.dontAlways end,
				set = function(_, value) db.dontAlways = value end,
				disabled = function() return not Module:IsEnabled() end
			},
			chance = {
				type = "range",
				order = 14,
				name = 'Percent Chance',
				desc = 'The percent chance the module has to welcome someone.  Higher the chance, the more likely it is to run.  This is a means to throttle, so as to prevent spam/annoyances.',
				get = function() return db.chance end,
				set = function(_, value) db.chance = value end,
				min = 0, max = 100, step = 10,
				disabled = function()
					if not Module:IsEnabled() then
						return true;
					else
						return not db.dontAlways;
					end
				end,
			},
			minDelay = {
				type = "range",
				order = 15,
				name = 'Minimum Delay',
				desc = 'Minimum time, in seconds, to wait before welcoming someone.',
				get = function() return db.minDelay end,
				set = function(_, value)
					db.minDelay = value
					options.maxDelay.min = value
				end,
				min = 0, max = 30, step = 1,
				disabled = function() return not Module:IsEnabled() end
			},
			maxDelay = {
				type = "range",
				order = 16,
				name = 'Maximum Delay',
				desc = 'Maximum time, in seconds, to wait before welcoming someone.',
				get = function() return db.maxDelay end,
				set = function(_, value)
					db.maxDelay = value
					options.minDelay.max = value
				end,
				min = 0, max = 30, step = 1,
				disabled = function() return not Module:IsEnabled() end
			},
			disableIf = {
				type = "group",
				order = 99,
				name = 'Disable if...',
				guiInline = true,
				disabled = function() return not Module:IsEnabled() end,
				args = {
					afk = {
						type = "toggle",
						order = 1,
						name = 'AFK',
						desc = 'Disable while you\'re AFK flagged.',
						get = function() return db.afk end,
						set = function(_, value) db.afk = value end,
					},
					dnd = {
						type = "toggle",
						order = 2,
						name = 'Busy',
						desc = 'Disable while you\'re DND flagged.',
						get = function() return db.dnd end,
						set = function(_, value) db.dbd = value end,
					},
				}
			},
			phrases = {
				type = "input",
				order = 100,
				multiline = true,
				width = "full",
				name = 'Welcome Messages',
				desc = 'Messages to use when someone joins your guild.\n\n|cffFA6400Wildcards|r\n|cff00ff00#name#|r - Person who joined.\n|cff00ff00#guild#|r - Name of your guild.',
				get = function() return Module:FiltersToString("phrases") end,
				set = function(_, value) Module:PopulateFilters("phrases", {strsplit("\n", value:trim())}) end,
				disabled = function() return not Module:IsEnabled() end
			}
		}
	end
	return options
end

function Module:PopulateFilters(tbl, filters)
	db[tbl] = {}
	for _, value in pairs(filters) do
		if value ~= "" and value ~= nil then
			db[tbl][#db[tbl] + 1] = value
		end
	end
end

function Module:FiltersToString(tbl)
	if not db[tbl] or #db[tbl] == 0 then return "" end
	local trigs = ""
	for i = 1, #db[tbl] do
		if db[tbl][i]:trim() ~= "" then
			trigs = trigs .. db[tbl][i] .. "\n"
		end
	end
	return trigs
end

function Module:SendWelcome(settings)
	SendChatMessage(db.phrases[random(1, #db.phrases)]:gsub("#name#", settings[1]):gsub("#guild#", settings[2]), "GUILD", nil)
end

function Module:CHAT_MSG_SYSTEM(event, message, ...)
	if not IsInGuild() or not message then return end
	
	-- dont run if afk/dnd and appropriate setting is enabled
	if db.afk and UnitIsAFK("player") then return end
	if db.dnd and UnitIsDND("player") then return end
	
	-- sometimes (randomly) the function will return to prevent annoyances
	if db.dontAlways then
		local number, percent = random(1, 10), db.chance / 10
		if type(number) == "number" and type(percent) == "number" then
			if number > percent then return end	-- stop execution
		end
	end
	
	local who = message:match(guildJoin)
	if who ~= nil then
		local guildName, _, _ = GetGuildInfo("player")
		self:ScheduleTimer("SendWelcome", random(db.minDelay, db.maxDelay), {who, guildName})
	end
end
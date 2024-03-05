-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'AutoCongratulate';
local displayName = 'Auto Congratulate';
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
local GetAchievementLink = _G["GetAchievementLink"]
local UnitIsAFK = _G["UnitIsAFK"]
local UnitIsDND = _G["UnitIsDND"]
local UnitName = _G["UnitName"]
local UnitInParty = _G["UnitInParty"]
local UnitInRaid = _G["UnitInRaid"]

local gsub = string.gsub

local db, options
local defaults = {
	profile = {
		dontAlways = true,
		chance = 50,
		minDelay = 1,
		maxDelay = 5,
		afk = true,
		dnd = true,
		player = true,
		nearby = true,
		party = true,
		raid = true,
		guild = true,
		single = {"Congrats #name# on #achieve#!"},
		multiple = {"Congrats everyone!"}
	}
}

local last = {
	nearby = nil,
	party = nil,
	raid = nil,
	guild = nil,
}

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	self:RegisterEvent("CHAT_MSG_ACHIEVEMENT", "Achievement")
	self:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT", "Achievement")
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	self:UnregisterAllEvents()
end

function Module:Info()
	return "Automatically congratulate someone when they, or others, complete an achievement."
end

function Module:GetOptions()
	if not options then
		options = {
			dontAlways = {
				type = "toggle",
				order = 13,
				name = "Dont Always Run",
				desc = "Enable this to give the module a percent chance to run to prevent spam/annoyances.  If disabled the module will always congratulate.",
				get = function() return db.dontAlways end,
				set = function(_, value) db.dontAlways = value end,
				disabled = function() return not Module:IsEnabled() end
			},
			chance = {
				type = "range",
				order = 14,
				name = "Percent Chance",
				desc = "The percent chance the module has to congratulate someone.  Higher the chance, the more likely it is to run.  This is a means to throttle, so as to prevent spam/annoyances.",
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
				name = "Minimum Delay",
				desc = "Minimum time, in seconds, to wait before congratulating someone.",
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
				name = "Maximum Delay",
				desc = "Maximum time, in seconds, to wait before congratulating someone.",
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
				order = 98,
				name = "Disable if...",
				guiInline = true,
				disabled = function() return not Module:IsEnabled() end,
				args = {
					afk = {
						type = "toggle",
						order = 1,
						name = "AFK",
						desc = "Disable while you're AFK flagged.",
						get = function() return db.afk end,
						set = function(_, value) db.afk = value end,
					},
					dnd = {
						type = "toggle",
						order = 2,
						name = "Busy",
						desc = "Disable while you're DND flagged.",
						get = function() return db.dnd end,
						set = function(_, value) db.dnd = value end,
					},
					player = {
						type = "toggle",
						order = 3,
						name = "Self",
						desc = "Disable if you completed the achievement.",
						get = function() return db.player end,
						set = function(_, value) db.player = value end,
					},
				}
			},
			whoToGrts = {
				type = "group",
				order = 99,
				name = "Who to Congratulate?",
				guiInline = true,
				disabled = function() return not Module:IsEnabled() end,
				args = {
					nearby = {
						type = "toggle",
						name = "Nearby People",
						desc = "Congratulate achievements earned by people near you.",
						get = function() return db.nearby end,
						set = function(_, value) db.nearby = value end
					},
					raid = {
						type = "toggle",
						name = "Raid Members",
						desc = "Congratulate achievements earned by people in your raid.",
						get = function() return db.raid end,
						set = function(_, value) db.raid = value end,
					},
					guild = {
						type = "toggle",
						name = "Guildmates",
						desc = "Congratulate achievements earned by guildmates.",
						get = function() return db.guild end,
						set = function(_, value) db.guild = value end,
					},
					party = {
						type = "toggle",
						name = "Party Members",
						desc = "Congratulate achievements earned by people in your party.",
						get = function() return db.party end,
						set = function(_, value) db.party = value end,
					},
				},
			},
			messages = {
				type = "group",
				order = 100,
				name = "Congratulations Messages",
				guiInline = true,
				disabled = function() return not Module:IsEnabled() end,
				args = {
					singleMessages = {
						type = "input",
						order = 1,
						multiline = true,
						width = "full",
						name = "Achievement Messages",
						desc = "Messages for when someone completes an achievement.  A random one will always be selected.\n\n|cffFA6400Wildcards|r\n|cff00ff00#name#|r  - Name of the person.\n|cff00ff00#achieve#|r - Achievement they completed.",
						get = function() return Module:FiltersToString("single") end,
						set = function(_, value) Module:PopulateFilters("single", {strsplit("\n", value:trim())}) end,
					},
					multiMessages = {
						type = "input",
						order = 2,
						multiline = true,
						width = "full",
						name = "Multiple Achievement Messages",
						desc = "Messages for when multiple people complete achievements.  A random one will always be selected.\n\n|cffff0000Wildcards do not apply for multiple achievements.|r",
						get = function() return Module:FiltersToString("multiple") end,
						set = function(_, value) Module:PopulateFilters("multiple", {strsplit("\n", value:trim())}) end,
					}
				}
			},
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

function Module:SendCongrats(settings)
	if settings[2] == true then
		if not db.multiple or #db.multiple == 0 then return end
		-- multiple
		SendChatMessage(db.multiple[random(1, #db.multiple)], settings[3], nil)
	else
		-- remove realm from cross-realm achievements
		local temp = {strsplit("-", settings[1])}
		local sender = temp[1]
		if not db.single or #db.single == 0 then return end
		
		-- some error checking to stop the gsub errors
		if not sender or sender == "" then return end
		if not settings[4] or settings[4] == "" or settings[4] == 0 then return end
		-- single
		SendChatMessage(db.single[random(1, #db.single)]:gsub("#name#", sender):gsub("#achieve#", GetAchievementLink(settings[4])), settings[3], nil)
	end
end

function Module:Achievement(event, message, sender)
	local temp = {strsplit("-", sender)}
	local senderName = temp[1]
	
	-- dont run if afk/dnd and appropriate setting is enabled
	if db.afk and UnitIsAFK("player") then return end
	if db.dnd and UnitIsDND("player") then return end
	if db.player and senderName == UnitName("player") then return end

	
	-- sometimes (randomly) the function will return to prevent annoyances
	if db.dontAlways then
		local number, percent = random(1, 10), db.chance / 10
		if type(number) == "number" and type(percent) == "number" then
			if number > percent then return end	-- stop execution
		end
	end
	
	local delay = random(db.minDelay, db.maxDelay) -- get a random delay
	
	-- pull the achievemt ID from the achievement link
	--local id = message:match("^.+\124c%w%w%w%w%w%w%w%w\124Hachievement:(%-?%d-):%w-:%d-:%d-:%d-:%-?%d-:%d-:%d-:%d-:%d-\124h%[.-%]\124h\124r") or 0
	local id = message:match("|cffffff00|Hachievement:([0-9]+):.+:[%-0-9]+:[%-0-9]+:[%-0-9]+:[%-0-9]+:[%-0-9]+:[%-0-9]+:[%-0-9]+:[%-0-9]+|h%[[^]]+%]|h|r")
	
	-- party/raid or nearby
	if event == "CHAT_MSG_ACHIEVEMENT" then
		-- nearby
		if db.nearby and not UnitInParty(sender) and not UnitInRaid(sender) then
			if self:CancelTimer(self.nearbyHandle, true) == true and last.nearby ~= sender then
				self.nearbyHandle = self:ScheduleTimer("SendCongrats", delay, {sender, true, "SAY"})
			else
				self.nearbyHandle = self:ScheduleTimer("SendCongrats", delay, {sender, false, "SAY", id})
			end
			last.nearby = sender
		-- party
		elseif db.party and UnitInParty(sender) and not UnitInRaid(sender) then
			if self:CancelTimer(self.partyHandle, true) == true and last.party ~= sender then
				self.partyHandle = self:ScheduleTimer("SendCongrats", delay, {sender, true, "PARTY"})
			else
				self.partyHandle = self:ScheduleTimer("SendCongrats", delay, {sender, false, "PARTY", id})
			end
			last.party = sender
		-- raid
		elseif db.raid and UnitInRaid(sender) then
			if self:CancelTimer(self.raidHandle, true) == true and last.raid ~= sender then
				self.raidHandle = self:ScheduleTimer("SendCongrats", delay, {sender, true, "RAID"})
			else
				self.raidHandle = self:ScheduleTimer("SendCongrats", delay, {sender, false, "RAID", id})
			end
			last.raid = sender
		end
	-- guild
	elseif event == "CHAT_MSG_GUILD_ACHIEVEMENT" and db.guild then
		if self:CancelTimer(self.guildHandle, true) == true and last.guild ~= sender then
			self.guildHandle = self:ScheduleTimer("SendCongrats", delay, {sender, true, "GUILD"})
		else
			self.guildHandle = self:ScheduleTimer("SendCongrats", delay, {sender, false, "GUILD", id})
		end
		last.guild = sender
	end
	
end
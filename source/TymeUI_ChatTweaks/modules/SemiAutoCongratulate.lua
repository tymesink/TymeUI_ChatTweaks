-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'SemiAutoCongratulate';
local displayName = 'Semi-Auto Congratulate';
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
local Module = CT:NewModule(moduleName, "AceEvent-3.0", "AceHook-3.0", "AceTimer-3.0", "AceConsole-3.0")
Module.name = moduleName
Module.displayName = displayName

-----------------------------------------------------------------------
-- local variable / methods
-----------------------------------------------------------------------
local GetAchievementInfo = _G["GetAchievementInfo"]
local GetAchievementLink = _G["GetAchievementLink"]
local random = math.random
local strsplit = _G["strsplit"]
local UnitIsAFK = _G["UnitIsAFK"]
local UnitIsDND = _G["UnitIsDND"]
local UnitName = _G["UnitName"]
local UnitInParty = _G["UnitInParty"]
local UnitInRaid = _G["UnitInRaid"]

local chatLink = "|HECT_GRATS:%1$d:%2$s:%3$s|h|cFFFFFF00[Congratulate %4$s on %5$s]|r|h"
local achievementPattern = "|cffffff00|Hachievement:([0-9]+):.+:[%-0-9]+:[%-0-9]+:[%-0-9]+:[%-0-9]+:[%-0-9]+:[%-0-9]+:[%-0-9]+:[%-0-9]+|h%[[^]]+%]|h|r"

local db, options
local defaults = {
	profile = {
		afk = true,
		dnd = true,
		nearby = true,
		party = true,
		raid = true,
		guild = true,
		phrases = {"Congrats #name# on #achieve#!"},
	}
}

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(Module.name, defaults)
	db = self.db.profile
	self.debug = CT.db.debugging
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	self:RegisterEvent("CHAT_MSG_ACHIEVEMENT", "Achievement")
	self:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT", "Achievement")
	self:RawHook("SetItemRef", "ParseLink", true)
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	self:UnregisterEvent("CHAT_MSG_ACHIEVEMENT")
	self:UnregisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
	self:Unhook("SetItemRef")
end

function Module:GetOptions()
	if not options then
		options = {
			disableIf = {
				type = "group",
				order = 98,
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
						set = function(_, value) db.dnd = value end,
					},
				}
			},
			whoToGrts = {
				type = "group",
				order = 99,
				name = 'Who to Congratulate?',
				guiInline = true,
				disabled = function() return not Module:IsEnabled() end,
				args = {
					nearby = {
						type = "toggle",
						name = 'Nearby People',
						desc = 'Congratulate achievements earned by people near you.',
						get = function() return db.nearby end,
						set = function(_, value) db.nearby = value end
					},
					raid = {
						type = "toggle",
						name = 'Raid Members',
						desc = 'Congratulate achievements earned by people in your raid.',
						get = function() return db.raid end,
						set = function(_, value) db.raid = value end,
					},
					guild = {
						type = "toggle",
						name = 'Guildmates',
						desc = 'Congratulate achievements earned by guildmates.',
						get = function() return db.guild end,
						set = function(_, value) db.guild = value end,
					},
					party = {
						type = "toggle",
						name = 'Party Members',
						desc = 'Congratulate achievements earned by people in your party.',
						get = function() return db.party end,
						set = function(_, value) db.party = value end,
					},
				},
			},
			messages = {
				type = "group",
				order = 100,
				name = 'Congratulations Messages',
				guiInline = true,
				disabled = function() return not Module:IsEnabled() end,
				args = {
					singleMessages = {
						type = "input",
						order = 1,
						multiline = true,
						width = "full",
						name = 'Achievement Messages',
						desc = 'Messages for when someone completes an achievement.  A random one will always be selected.\n\n|cffFA6400Wildcards|r\n|cff00ff00#name#|r  - Name of the person.\n|cff00ff00#achieve#|r - Achievement they completed.',
						get = function() return Module:FiltersToString("phrases") end,
						set = function(_, value) Module:PopulateFilters("phrases", {strsplit("\n", value:trim())}) end,
					},
				}
			},
		}
	end
	return options
end

function Module:Info()
	return 'Prints a link you can click to congratulate when someone obtains an achievement.'
end

function Module:Achievement(event, message, sender, dummy, channel, ...)
	local temp = {strsplit("-", sender)}
	local senderName = temp[1]
	
	-- dont run if afk/dnd and appropriate setting is enabled
	if db.afk and UnitIsAFK("player") then return end
	if db.dnd and UnitIsDND("player") then return end
	if senderName == UnitName("player") then return end

	local id = message:match(achievementPattern)
	if not id then return end

	local _, name, _, _, _, _, _, _, _, _, _, _, _, _ = GetAchievementInfo(id)

	-- nearby
	if event == "CHAT_MSG_ACHIEVEMENT" and db.nearby and not UnitInParty(sender) and not UnitInRaid(sender) then
		self:Print(chatLink:format(id, senderName, channel, senderName, name))
	-- party
	elseif event == "CHAT_MSG_ACHIEVEMENT" and db.party and UnitInParty(sender) and not UnitInRaid(sender) then
		self:Print(chatLink:format(id, senderName, channel, senderName, name))
	-- raid
	elseif event == "CHAT_MSG_ACHIEVEMENT" and db.raid and UnitInRaid(sender) then
		self:Print(chatLink:format(id, senderName, channel, senderName, name))
	-- guild
	elseif db.guild and event == "CHAT_MSG_GUILD_ACHIEVEMENT" then
		self:Print(chatLink:format(id, senderName, "GUILD", senderName, name))
	end
end

function Module:ParseLink(link, text, button, frame)
	local linkType, id, sender, channel = strsplit(":", link)
	if linkType == "ECT_GRATS" and id and sender and channel then
		if not db.phrases or #db.phrases == 0 then return end
		SendChatMessage(db.phrases[random(1, #db.phrases)]:gsub("#name#", sender):gsub("#achieve#", GetAchievementLink(id)), channel, nil)
	else 
		return self.hooks["SetItemRef"](link, text, button, frame)
	end
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
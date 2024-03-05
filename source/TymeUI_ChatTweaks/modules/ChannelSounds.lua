-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'ChannelSounds';
local displayName = 'Channel Sounds';
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
local Module = CT:NewModule(moduleName, 'AceEvent-3.0', 'AceConsole-3.0');
Module.name = moduleName
Module.displayName = displayName

-----------------------------------------------------------------------
-- local variable / methods
-----------------------------------------------------------------------
local PlaySoundFile = _G["PlaySoundFile"]
local format = string.format
local upper = string.upper

local db
local options = {}
local channelString = "CHAT_MSG_%s"
local channelPattern = "CHAT_MSG_(.+)"
local soundChannels 		= {
	["Guild"]				= "GUILD",
	["Officer"] 			= "OFFICER",
	["Party"] 				= "PARTY",
	["Party Leader"] 		= "PARTY_LEADER",
	["Raid"] 				= "RAID",
	["Raid Leader"] 		= "RAID_LEADER",
	["Instance"]			= "INSTANCE_CHAT",
	["Instance Leader"]		= "INSTANCE_CHAT_LEADER",
	["Say"] 				= "SAY",
	["Yell"]				= "YELL",
	["Emote"] 				= "EMOTE",
	["Monster Emote"] 		= "MONSTER_EMOTE",
	["Monster Say"]			= "MONSTER_SAY",
	["Raid Boss Emote"] 	= "RAID_BOSS_EMOTE"
}

local defaults = {
	profile = {
		guildSound = "None",
		officerSound = "None",
		partySound = "None",
		partyLeaderSound = "None",
		raidSound = "None",
		raidLeaderSound = "None",
		instanceSound = "None",
		instanceLeaderSound = "None",
		battlegroundSound = "None",
		battlegroundLeaderSound = "None",
		bgSystemAlliance = "None",
		bgSystemHorde = "None",
		bgSystemNeutral = "None",
		saySound = "None",
		yellSound = "None",
		emoteSound = "None",
		monsterEmoteSound = "None",
		monsterSaySound = "None",
		raidBossEmoteSound = "None"
	}
}

local capitalize = function(str)
    return str:gsub("^%l", upper)
end

local getSettingName = function(str)
	if not str:find("_") then
		return str:lower() .. "Sound"
	else
		local first, temp = false, ""
		for word in str:gmatch("%w+") do
			if word:lower() ~= "chat" then
				if not first then
					temp = word:lower()
					first = true
				else
					temp = temp .. capitalize(word:lower())
				end
			end
		end
		return temp .. "Sound"
	end
end

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	for _, value in pairs(soundChannels) do
		self:RegisterEvent(channelString:format(value), "ChannelSounds")
	end
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	for _, value in pairs(soundChannels) do
		self:UnregisterEvent(channelString:format(value))
	end
end

function Module:GetOptions()
	for name, value in pairs(soundChannels) do
		local setting = getSettingName(value)
		if not options[setting] then
			options[setting] = {
				type = "select",
				dialogControl = "LSM30_Sound",
				name = name,
				desc = format("Sound to play when a message in %s is received.\n\n|cff00ff00To disable set to \"None\"|r.", name:lower()),
				values = AceGUIWidgetLSMlists.sound,
				--values = LSM:HashTable("sound"),
				get = function() return db[setting] or "None" end,
				set = function(_, value) db[setting] = value end,
				disabled = function() return not Module:IsEnabled() end
			}
		end
	end
	return options
end

function Module:Info()
	return "Plays a sound, of your choosing (via LibSharedMedia-3.0), whenever a message is received in a given channel."
end

function Module:ChannelSounds(event, ...)
	local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9 = ...;
	CTLogger:PrintDebugMessage('Module:ChannelSounds Event: '..event)
	local channel = event:match(channelPattern)
	if not channel then return end
	local setting = getSettingName(channel)
	if db[setting] and db[setting] ~= "None" and arg2 ~= CTUtils.GetCharacterRealmName(false) then
		PlaySoundFile(LSM:Fetch("sound", db[setting]))
	end
end

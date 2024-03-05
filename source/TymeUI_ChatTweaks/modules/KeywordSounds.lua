-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------
local ADDON_NAME, private = ...
local moduleName = 'KeywordSounds';
local displayName = 'Keyword Sounds';
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
local Module = CT:NewModule(moduleName, 'AceEvent-3.0', 'AceConsole-3.0')
Module.name = moduleName
Module.displayName = displayName
Module.characterName = CTUtils.GetCharacterName();
Module.characterNameRealm = CTUtils.GetCharacterRealmName();
Module.Keywords = {};

-----------------------------------------------------------------------
-- local variable / methods
-----------------------------------------------------------------------
local UnitName = _G['UnitName']
local IsValid = _G['IsValid']
local PlaySoundFile = _G['PlaySoundFile']
local ChatFrame_AddMessageEventFilter = _G['ChatFrame_AddMessageEventFilter']
local ChatFrame_RemoveMessageEventFilter = _G['ChatFrame_RemoveMessageEventFilter']

local db, options
local defaults = {
	profile = {
		sound = 'Alert',
		master = true,
		ignoreYours = true,
		keywords = Module.characterName,
		channels = {
			["CHANNEL"] = true,
			["EMOTE"] = true,
			["GUILD"] = true,
			["OFFICER"] = false,
			["PARTY"] = false,
			["PARTY_LEADER"] = false,
			["RAID"] = false,
			["RAID_LEADER"] = false,
			["RAID_WARNING"] = false,
			["INSTANCE_CHAT"] = false,
			["INSTANCE_CHAT_LEADER"] = false,
			["SAY"] = true,
			["YELL"] = true,
			["WHISPER"] = true,
		},
	}
}

local findKeywords = function(self, event, text, author, ...)
	if db.ignoreYours and author == Module.characterNameRealm then return end
	for i = 1, #{string.split(" ", text)} do
		local word = select(i, string.split(" ", text))
		if not word:find("|") then
			for keyword, _ in pairs(Module.Keywords) do
				if word:lower() == keyword:lower() then
					if db.sound and db.sound ~= "None" and LSM:IsValid("sound", db.sound) then
						PlaySoundFile(LSM:Fetch("sound", db.sound), db.master and "Master" or nil)
						return -- only play the sound once
					end
				end
			end
		end
	end
end

local updateChatKeywords = function()
	wipe(Module.Keywords);
	local keywords = db.keywords;
	if CTUtils.IsNilOrEmpty(keywords) == false then
		for stringValue in gmatch(keywords, '[^,]+') do
			if CTUtils.IsNilOrEmpty(stringValue) == false then
				if stringValue == '%MYNAME%' then
					stringValue = Module.characterName;
				end
				Module.Keywords[stringValue] = true
			end
		end
	end
end

local refreshChannels = function()
	for index, value in pairs(db.channels) do
		if value == true then
			ChatFrame_AddMessageEventFilter(("CHAT_MSG_%s"):format(index:upper()), findKeywords)
		else
			ChatFrame_RemoveMessageEventFilter(("CHAT_MSG_%s"):format(index:upper()), findKeywords)
		end
	end
end

-----------------------------------------------------------------------
-- public methods
-----------------------------------------------------------------------
function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging
	updateChatKeywords()
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	for index, value in pairs(db.channels) do
		if index and value == true then			
			local channel = index:upper();			
			local chateventfilter = ('CHAT_MSG_%s'):format(channel);
			ChatFrame_AddMessageEventFilter(chateventfilter, findKeywords)
		end
	end
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	for index, value in pairs(db.channels) do
		if index and value == true then
			local channel = index:upper();
			local chateventfilter = ('CHAT_MSG_%s'):format(channel);
			ChatFrame_RemoveMessageEventFilter(chateventfilter, findKeywords)
		end
	end
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
			ignoreYours = {
				type = "toggle",
				order = 15,
				name = "Ignore Your Messages",
				desc = "Ignore any messages you send containing keywords.",
				get = function() return db.ignoreYours end,
				set = function(_, value) db.ignoreYours = value end,
				disabled = function() return not Module:IsEnabled() end
			},
			keywords = {
				type = "input",
				order = 16,
				multiline = true,
				width = "full",
				name = "Keywords",
				desc = "List of words to sound an alert in chat if found in a message. If you wish to add multiple words you must separate the word with a comma. To search for your current name you can use %MYNAME%.\n\nExample:\n%MYNAME%, ElvUI, RBGs, Tank",
				get = function() 
					local keywords = db.keywords;
					if CTUtils.IsNilOrEmpty(keywords) == false then
						local output = keywords:gsub(',','\n');
						return output;
					else
						return '';
					end
				end,
				set = function(_, value) 
					if CTUtils.IsNilOrEmpty(value) == false then
						db.keywords = value:gsub('[\n]',',');
					else
						db.keywords = '';
					end
					updateChatKeywords();
				end,
				disabled = function() return not Module:IsEnabled() end
			},
			channels = {
				type = "multiselect",
				order = -1,
				name = "Channels to Monitor",
				desc = "Select the channels you want monitored.",
				values = {
					["CHANNEL"] = "Channel",
					["EMOTE"] = CHAT_MSG_EMOTE,
					["GUILD"] = CHAT_MSG_GUILD,
					["OFFICER"] = CHAT_MSG_OFFICER,
					["PARTY"] = CHAT_MSG_PARTY,
					["PARTY_LEADER"] = CHAT_MSG_PARTY_LEADER,
					["RAID"] = CHAT_MSG_RAID,
					["RAID_LEADER"] = CHAT_MSG_RAID_LEADER,
					["RAID_WARNING"] = CHAT_MSG_RAID_WARNING,
					["INSTANCE_CHAT"] = INSTANCE_CHAT,
					["INSTANCE_CHAT_LEADER"] = INSTANCE_CHAT_LEADER,
					["SAY"] = CHAT_MSG_SAY,
					["YELL"] = CHAT_MSG_YELL,
					["WHISPER"] = CHAT_MSG_WHISPER_INFORM,
				},
				get = function(_, key) return db.channels[key] end,
				set = function(_, key, value)
					db.channels[key] = value
					refreshChannels()
				end,
				disabled = function() return not Module:IsEnabled() end
			},
		}
	end
	return options;
end

function Module:Info()
	return "Plays a sound when one of your keywords is found."
end



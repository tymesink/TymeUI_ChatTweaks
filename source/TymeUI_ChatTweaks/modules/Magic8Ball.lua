-------------------------------------------------------------------------------
-- ElvUI Chat Tweaks By Crackpot (US, Thrall)
-- Based on functionality provided by Prat and/or Chatter
-------------------------------------------------------------------------------local ADDON_NAME, private = ...
local ADDON_NAME, private = ...
local moduleName = 'Magic8Ball';
local displayName = 'Magic 8-Ball';
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
-- Module Methods
-----------------------------------------------------------------------
local CT = AceAddon:GetAddon(CTConstants.ADDON_NAME)
local Module = CT:NewModule(moduleName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
Module.name = moduleName
Module.displayName = displayName

local ChatFrame_AddMessageEventFilter = _G["ChatFrame_AddMessageEventFilter"]
local ChatFrame_RemoveMessageEventFilter = _G["ChatFrame_RemoveMessageEventFilter"]

local db, options
local defaults = {
	profile = {
		trigger = "!8ball",
		whisper = true,
		throttle = 5,
		filter = true,
		repeatQuestion = false,
		channels = {
			["GUILD"] = true,
			["OFFICER"] = false,
			["PARTY"] = false,
			["RAID"] = false,
			["INSTANCE_CHAT"] = false,
			["CHANNEL"] = false,
			["SAY"] = true,
			["YELL"] = true,
		},
		reminder = {
			channel = "GUILD",
		},
	}
}

local phrases = {
	-- affirmative phrases
	'It is certain.',
	'It is decidedly so.',
	'Without a doubt.',
	'Yes, definitely.',
	'You may rely on it.',
	'As I see it, yes.',
	'Most likely.',
	'Outlook good.',
	'Yes',
	'Signs point to yes.',

	-- non-commital phrases
	'Reply hazy, try again.',
	'Ask again later.',
	'Better not tell you now.',
	'Cannot predict now.',
	'Concentrate and ask again.',

	-- negative phrases
	'Don\'t count on it.',
	'My reply is no.',
	'My sources say no.',
	'Outlook not so good.',
	'Very doubtful.',
}

local function RegexEscape(inStr)
	return inStr:gsub("%p", "%%%1")
end

local function MonitorChannel(self, event, message, author, ...)
	if not message or not author then return false end

	-- check to see if the message has the trigger
	if not Module.waiting and message:sub(1, #db.trigger) == db.trigger then
		local question = message:match(("%s (.+)"):format(RegexEscape(db.trigger)))
		local response = phrases[math.random(1, #phrases)]

		-- debugging
		if Module.debug then
			self:Print(question)
			self:Print(response)
		end

		-- send the response
		if db.whisper then
			if db.repeatQuestion then
				-- repeat the question
				SendChatMessage(('You asked: %s'):format(question), "WHISPER", nil, author)
			end
			SendChatMessage(('Magic 8-Ball says: %s'):format(response), "WHISPER", nil, author)
		else
			local channel = event:match("CHAT_MSG_(.+)")
			if channel then
				if db.repeatQuestion then
					SendChatMessage(('You asked: %s'):format(question), channel:upper(), nil, channel == "CHANNEL" and select(6, ...) or nil)
				end
				SendChatMessage(('Magic 8-Ball says: %s'):format(response), channel:upper(), nil, channel == "CHANNEL" and select(6, ...) or nil)
			elseif Module.debug and not channel then
				-- something happened
				self:Print(event)
			end
		end

		-- start the timer to throttle the responses
		self.waiting = true
		Module:ScheduleTimer(function() self.waiting = false end, db.throttle)

		return db.filter
	end
	return false
end

function Module:OnInitialize()
	self.db = CT.db:RegisterNamespace(self.name, defaults)
	db = self.db.profile
	self.debug = CT.db.profile.debugging
	self.waiting = false	-- for our throttle
end

function Module:OnEnable()
	CTLogger:PrintDebugMessage(self.name..' - OnEnable')
	self:UpdateChannels()
end

function Module:OnDisable()
	CTLogger:PrintDebugMessage(self.name..' - OnDisable')
	for channel, _ in pairs(db.channels) do
		ChatFrame_RemoveMessageEventFilter(("CHAT_MSG_%s"):format(channel:upper()), MonitorChannel)
	end
end

function Module:GetOptions()
	if not options then
		options = {
			trigger = {
				type = "input",
				order = 13,
				name = 'Trigger',
				desc = 'Text to trigger the addon to answer a question.',
				get = function() return db.trigger end,
				set = function(_, value) db.trigger = value end,
				disabled = function() return not Module:IsEnabled() end
			},
			whisper = {
				type = "toggle",
				order = 14,
				name = 'Whisper Answer',
				desc = 'Whisper the response to the person.  Otherwise it will be answered in the same channel the request was sent.',
				get = function() return db.whisper end,
				set = function(_, value) db.whisper = value end,
				disabled = function() return not Module:IsEnabled() end
			},
			throttle = {
				type = "range",
				order = 15,
				name = 'Throttle',
				desc = 'Throttle to only answer a question every X seconds, to prevent spam.\n\n|cffff0000Not recommended to disable this.|r',
				get = function() return db.throttle end,
				set = function(_, value) db.throttle = value end,
				min = 0, max = 120, step = 5, bigStep = 10,
				disabled = function() return not Module:IsEnabled() end
			},
			filter = {
				type = "toggle",
				order = 16,
				name = 'Filter Line',
				desc = 'Filter the line containing the question.',
				get = function() return db.filter end,
				set = function(_, value) db.filter = value end,
				disabled = function() return not Module:IsEnabled() end
			},
			repeatQuestion = {
				type = "toggle",
				order = 17,
				name = 'Repeat Question',
				desc = 'Repeat the question when giving a response.',
				get = function() return db.repeatQuestion end,
				set = function(_, value) db.repeatQuestion = value end,
				disabled = function() return not Module:IsEnabled() end
			},
			channels = {
				type = "multiselect",
				order = 50,
				name = 'Channels to Monitor',
				desc = 'Channels to look for questions.',
				values = {
					["GUILD"] = CHAT_MSG_GUILD,
					["OFFICER"] = CHAT_MSG_OFFICER,
					["PARTY"] = CHAT_MSG_PARTY,
					["RAID"] = CHAT_MSG_RAID,
					["INSTANCE_CHAT"] = INSTANCE_CHAT,
					["CHANNEL"] = 'Numbered Channels',
					["SAY"] = CHAT_MSG_SAY,
					["YELL"] = CHAT_MSG_YELL,
				},
				get = function(_, key) return db.channels[key] end,
				set = function(_, key, value) db.channels[key] = value; Module:UpdateChannels(); end,
				disabled = function() return not Module:IsEnabled() end
			},
			reminder = {
				type = "group",
				order = 99,
				name = 'Reminder',
				disabled = function() return not Module:IsEnabled() end,
				args = {
					channel = {
						type = "select",
						order = 1,
						name = 'Output Channel',
						desc = 'Channel to send the reminder to.',
						values = {
							["GUILD"] = CHAT_MSG_GUILD,
							["OFFICER"] = CHAT_MSG_OFFICER,
							["PARTY"] = CHAT_MSG_PARTY,
							["RAID"] = CHAT_MSG_RAID,
							["INSTANCE_CHAT"] = INSTANCE_CHAT,
							["SAY"] = CHAT_MSG_SAY,
							["YELL"] = CHAT_MSG_YELL,
						},
						get = function() return db.reminder.channel end,
						set = function(_, value) db.reminder.channel = value end,
					},
					send = {
						type = "execute",
						order = 2,
						name = 'Send Reminder',
						desc = 'Click to send the reminder to the select channel that the Magic 8-Ball is listening.',
						func = function() SendChatMessage(('Magic 8-Ball Says: I am ready to answer your questions!  Do \"%s <question>\" to ask me a question.'):format(db.trigger), db.reminder.channel) end,
					},
				},
			},
		}
	end
	return options
end

function Module:Info()
	return 'The classic Magic 8-Ball brought to World of Warcraft!'
end

function Module:UpdateChannels()
	for index, value in pairs(db.channels) do
		local channel = ("CHAT_MSG_%s"):format(index:upper())
		if value then
			ChatFrame_AddMessageEventFilter(channel, MonitorChannel)
		else
			ChatFrame_RemoveMessageEventFilter(channel, MonitorChannel)
		end
	end
end

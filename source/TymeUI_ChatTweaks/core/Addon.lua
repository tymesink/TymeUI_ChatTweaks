-----------------------------------------------------------------------
-- addOn namespace
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

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
local AceAddon = LibStub('AceAddon-3.0');
local AceDB = LibStub('AceDB-3.0');
local AceDBOptions = LibStub('AceDBOptions-3.0');

-----------------------------------------------------------------------
-- Addon Setup
-----------------------------------------------------------------------
local CT = AceAddon:NewAddon(CTConstants.ADDON_NAME, 'AceConsole-3.0', 'AceEvent-3.0', 'AceTimer-3.0', 'AceHook-3.0');
CT.version = CTUtils.GetAddOnMetadata(CTConstants.ADDON_NAME, 'Version')
CT:SetDefaultModuleState(false);

local defaults = {
	profile = {
		welcome = true,
		debugging = false,
		modules  = {
			--modules disabled by default
			['AchievementFilter'] = false,
			['AddonMessages'] = false,
			['AuctionSoldAlert'] = false,
			['AutoCongratulate'] = false,
			['AutoDing'] = false,
			['AutoWelcome'] = false,
			['ChannelSounds'] = false,
			['ChatFrameBorders'] = false,
			['ChatStyles'] = false,
			['ChatTabs'] = false,
			['DamageMeters'] = false,
			['EditBox'] = false,
			['EditBoxHistory'] = false,
			['KeywordSounds'] = false,
			['Magic8Ball'] = false,
			['SemiAutoCongratulate'] = false
		}
	},
}
-----------------------------------------------------------------------
-- Main Addon Methods
-----------------------------------------------------------------------
function CT:OnInitialize()
    -- Called when the addon is loaded
	self.db = AceDB:New(CTConstants.ADDON_DBNAME, defaults);
	self.db.RegisterCallback(self, 'OnProfileChanged', 'RefreshOptions')
	self.db.RegisterCallback(self, 'OnProfileCopied', 'RefreshOptions')
	self.db.RegisterCallback(self, 'OnProfileReset', 'RefreshOptions')

    self:RegisterChatCommand(CTConstants.CMD_CONFIG, 'ChatCommand');
    self:RegisterChatCommand(CTConstants.CMD_RELOADUI, 'ChatCommand_ReloadUI');
	self:RegisterChatCommand(CTConstants.CMD_OPTIONS1, 'ChatCommand_Options');
	self:RegisterChatCommand(CTConstants.CMD_OPTIONS2, 'ChatCommand_Options');

	CTConstants.DEBUG_MODE = self.db.profile.debugging;
						
	-- Initialize setup panels
	self:SetupOptions()
end

function CT:GetOptionsTable()
	return AceDBOptions:GetOptionsTable(self.db, CTConstants.PROFILE_DEFAULTS)
end

function CT:OnEnable()
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
end

function CT:ChatCommand(cmd)
    if not cmd or cmd:trim() == '' then
		InterfaceOptionsFrame_OpenToCategory(CTConstants.ADDON_ABBREV)
    elseif cmd == 'version' or cmd == 'ver' then
		self:Print(('You are running version |cff1784d1%s|r.'):format(self.version))
	elseif cmd == 'modules' or cmd == 'mods' then
		local modStatus, enabled, disabled = {}, 0, 0
		for name, module in self:IterateModules() do
			modStatus[name] = module:IsEnabled() and true or false
			if module:IsEnabled() then enabled = enabled + 1
			else disabled = disabled + 1 end
		end
		
		if not modStatus then
			self:Print('|cffff0000No modules found.|r')
		else
			local moduleName = '    +|cff00ffff%s|r - %s'
			local enabledModule  = '|cff00ff00Enabled|r'
			local disabledModule = '|cffff0000Disabled|r'
			self:Print(format(' |cffffff00%d|r Total Modules (|cff00ff00%d|r Enabled, |cffff0000%d|r Disabled)', (enabled + disabled), enabled, disabled))
			for name, status in CTUtils.PairsByKeys(modStatus) do
				print(format(moduleName, name, status == true and enabledModule or disabledModule))
			end
		end
	elseif cmd == 'help'  or cmd == '?' then
		self:PrintHelp()
	end
end

function CT:ChatCommand_ReloadUI()
    ReloadUI();
end

function CT:ChatCommand_Options()
	InterfaceOptionsFrame_OpenToCategory('none')
end

function CT:PLAYER_ENTERING_WORLD(event, ...)
	if self.db.profile.welcome == true then
		local colors = CTConstants.COLORS_HEX;
		local msg = ('Version %s%s|r is loaded. Type %s/ct|r if you need help.'):format(colors.brightblue, self.version, colors.brightgreen);
		CTLogger:PrintMessage(msg)
	end
	self:UnregisterEvent('PLAYER_ENTERING_WORLD')
end

function CT:PrintHelp()
	local argStr  = '   |cff00ff00/ct %s|r - %s'
	local arg2Str = '   |cff00ff00/ct %s|r or |cff00ff00%s|r - %s'
	local clrStr  = '   |cff00ff00%s|r or |cff00ff00%s|r - %s'
	local cmdStr  = '   |cff00ff00%s|r - %s'
	CTLogger:PrintMessage('Available Chat Command Arguments')
	print(format(argStr, 'config', 'Opens configuration window.'))
	print(format(arg2Str, 'modules', 'mods', 'Prints module status.'))
	print(format(arg2Str, 'help', '?', 'Print this again.'))
	print(format(arg2Str, 'version', 'ver', 'Print Addon Version'))
	-- determine if clear chat command module is enabled
	
	for name, module in self:IterateModules() do
		if module:IsEnabled() and name == 'Clear Chat Commands' then
			print(format(clrStr, '/clr', '/clear', 'Clear current chat.'))
			print(format(clrStr, '/clrall', '/clearall', 'Clear all chat windows.'))
		elseif module:IsEnabled() and name == 'GKick Command' then
			print(format(cmdStr, '/gkick', 'Alternate command to kick someone from guild.'))
		elseif module:IsEnabled() and name == 'Group Say Command' then
			print(format(cmdStr, '/gs', 'Talk to your group based on party/raid status.'))
		elseif module:IsEnabled() and name == 'Tell Target' then
			print(format(cmdStr, '/tt', 'Send a tell to your target.'))
		elseif module:IsEnabled() and name == 'Developer Tools' then
			print(format(cmdStr, '/ctdev', 'Various Developer Tools'))
		elseif module:IsEnabled() and name == 'Fake Achievement' then
			print(format(cmdStr, '/fake', 'Generate fake achievement links.'))
		elseif module:IsEnabled() and name == 'Token Price' then
			print(format(clrStr, '/tp', '/token', 'Show current token price.'))
		elseif module:IsEnabled() and name == 'Who Whispered Me' then
			print(format(cmdStr, '/ws', 'Show how many whispers you\'ve received this session.'))
		elseif module:IsEnabled() and name == 'Keystone Progress' then
			print(format(cmdStr, '/ksm', 'Display Keystone Master achievement progress.'))
			print(format(cmdStr, '/ksc', 'Display Keystone Conqueror achievement progress.'))
		end
	end
end
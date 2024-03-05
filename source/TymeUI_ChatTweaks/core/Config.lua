-----------------------------------------------------------------------
-- AddOn namespace.
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
local _G = getfenv(0)
local LibStub = _G.LibStub
local AceAddon = LibStub('AceAddon-3.0')
local AceDB = LibStub("AceDB-3.0");
local AceConfig = LibStub('AceConfig-3.0')
local AceConfigDialog = LibStub('AceConfigDialog-3.0')
local LibAboutPanel = LibStub:GetLibrary('LibAboutPanel-2.0', true);

-----------------------------------------------------------------------
-- local variable / methods
-----------------------------------------------------------------------
local CT = AceAddon:GetAddon(CTConstants.ADDON_NAME)

local getOptions = function()
	local options = {
		name = CTConstants.ADDON_ABBREV,
		handler = CT,
		type = 'group',
		order = 1,
		args = {
			heading = {
				type = "description",
				name = 'Settings for various ChatTweak features.',
				fontSize = "medium",
				order = 1,
				width = "full",
			},
			modules = {
				type = 'group',
				name = 'Modules',
				desc = 'Modules',
				args = {}
			}
		}
	}

	-- Adds about panel to wow options
	--local optframe = LibAboutPanel:CreateAboutPanel(CTConstants.ADDON_NAME)
	--optframe.name = CTConstants.ADDON_ABBREV;
	--InterfaceOptions_AddCategory(optframe);

	--options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	--options.args.profiles = CT:GetOptionsTable();
	options.args.aboutTab = LibAboutPanel:AboutOptionsTable(CTConstants.ADDON_NAME)
	options.args.aboutTab.order = -1
	return options;
end

local getModuleOptions = function(key, mod)
	local options
	if mod.GetOptions then
		options = mod:GetOptions();
		if options == nil then
			options = {}
		end
		options.settingsHeader = {
			type = 'header',
			name = 'Settings',
			order = 12
		}
	end
	options = options or {}
	options.toggle = {
		type = 'toggle',
		name = mod.toggleLabel or ('Enable ' .. (mod.name or key)),
		width = 'double',
		desc = mod:Info() and mod:Info() or ('Enable ' .. (mod.name or key)),
		order = 11,
		get = function() return CT.db.profile.modules[key] ~= false or false end,
		set = function(_, value)
			CT.db.profile.modules[key] = value
			if value then
				CT:EnableModule(key)
				CTLogger:PrintMessage(('Enabled %s%s|r module.'):format(CTConstants.COLORS_HEX.brightblue, key))
			else
				CT:DisableModule(key)
				CTLogger:PrintMessage(('Disabled %s%s|r module.'):format(CTConstants.COLORS_HEX.brightblue, key))
			end
		end
	}

	options.header = {
		type = 'header',
		name = mod.name or key,
		order = 9
	}

	if mod.Info then
		options.description = {
			type = 'description',
			name = mod:Info() .. "\n\n",
			order = 10
		}
	end
	return options
end

local getGeneralOptions = function()
	local options = {
			type = "group",
			order = 1,
			name = _G.GENERAL_LABEL,
			desc = 'General settings',
			args = {
				header = {
					type = 'header',
					order = 1,
					name = 'Version' .. (': |cff99ff33%s|r'):format(CT.version),
					width = 'full',
				},
				description = {
					type = 'description',
					order = 2,
					name = 'This addon is designed to add a lot of the functionality of full fledged chat addons like Prat or Chatter, but without a lot of the unneeded bloat.  I wrote it to be as lightweight as possible, while still powerful enough to accomplish it\'s intended function.\n',
					width = 'full',
				},
				welcome = {
					type = 'toggle',
					order = 3,
					name = 'Welcome Message',
					desc = 'Show welcome message when logging in.',
					get = function() return CT.db.profile.welcome end,
					set = function(_, value) CT.db.profile.welcome = value end,
				},
				debugging = {
					type = 'toggle',
					order = 4,
					name = 'Enable Debugging',
					desc = 'Enable various debugging messages to help with errors or undesired functioning.',
					get = function() return CT.db.profile.debugging end,
					set = function(_, value) 
						CT.db.profile.debugging = value;
						CTConstants.DEBUG_MODE = value;
					end,
				},
				Space1 = {
					order = 5,
					type = 'description',
					name = '',
				},
				enableAll = {
					type = 'execute',
					order = 6,
					name = 'Enable All Modules',
					func = function() StaticPopup_Show('ECT_ENABLE_ALL') end,
				},
				disableAll = {
					type = 'execute',
					order = 9,
					name = 'Disable All Modules',
					func = function() StaticPopup_Show('ECT_DISABLE_ALL') end,
				},
			}
		}
	return options
end

local hookModulePrint = function(module)
	-- hook every module's print function
	module.Print_ = module.Print
	module.Print = function(self, ...)
		local out = string.join("", CTConstants.COLORS_HEX.brightblue, CTConstants.ADDON_ABBREV, "|r: %s")
		DEFAULT_CHAT_FRAME:AddMessage(out:format(tostring(select(1, ...))))
	end
end

-----------------------------------------------------------------------
-- public methods
-----------------------------------------------------------------------
function CT:SetupOptions()
	local options = getOptions();
	options.args.general = getGeneralOptions();
	AceConfig:RegisterOptionsTable(CTConstants.ADDON_ABBREV, options)
	AceConfig:RegisterOptionsTable(CTConstants.ADDON_ABBREV..'Modules', options.args.modules)
	self.optionsFrame = AceConfigDialog:AddToBlizOptions(CTConstants.ADDON_ABBREV, CTConstants.ADDON_ABBREV)

	-- AceConfig:RegisterOptionsTable(CTConstants.ADDON_ABBREV..' General', getGeneralOptions())
	-- AceConfigDialog:AddToBlizOptions(CTConstants.ADDON_ABBREV..' General', _G.GENERAL_LABEL, CTConstants.ADDON_ABBREV)

	-----------------------------------------------------------------------
	-- IterateModules and build option table
	-----------------------------------------------------------------------
	local moduleList = {}
	local moduleNames = {}
	for key, mod in self:IterateModules() do
		moduleList[mod.displayName] = key;
		tinsert(moduleNames, mod.displayName);
		local opts = {
			type = 'group',
			name = mod.name or key,
			args = nil
		}
		opts.args = getModuleOptions(key, mod);
		options.args.modules.args[key] = opts;
	end

	-----------------------------------------------------------------------
	-- Set Module order and add it to Bliz Options UI
	-----------------------------------------------------------------------
	table.sort(moduleNames);
	for _, name in ipairs(moduleNames) do
		AceConfigDialog:AddToBlizOptions(CTConstants.ADDON_ABBREV..'Modules', name, CTConstants.ADDON_ABBREV, moduleList[name]);
	end

	-----------------------------------------------------------------------
	-- Profile RegisterOptionsTable
	-----------------------------------------------------------------------
	AceConfig:RegisterOptionsTable(CTConstants.ADDON_ABBREV..' Profiles', CT:GetOptionsTable());
	AceConfigDialog:AddToBlizOptions(CTConstants.ADDON_ABBREV..' Profiles', 'Profiles', CTConstants.ADDON_ABBREV);

	--CTUtils.PrintTable(self.db.profile.modules)

	for key, module in self:IterateModules() do
		if self.db.profile.modules[key] ~= false then module:Enable(); end
		hookModulePrint(module);
	end
end

function CT:RefreshOptions(event, database, newProfileKey)
	private.db = database.profile
	CTLogger:PrintDebugMessage('CT:RefreshOptions')
	self:DisableAllModules()
	self.db = AceDB:New(CTConstants.ADDON_DBNAME, CTConstants.PROFILE_DEFAULTS)
	for modkey, mod in self:IterateModules() do
		mod:OnInitialize()
		if self.db.profile.modules[modkey] ~= false then
			mod:Enable()
		else
			mod:Disable()
		end
	end
	CTUtils.Collectgarbage('collect');
end

function CT:UpdateConfig()
	CTLogger:PrintDebugMessage('CT:UpdateConfig')
	for _, mod in self:IterateModules() do
		if mod:IsEnabled() then
			mod:Disable()
			mod:Enable()
		end
	end
end

function CT:ModuleEnabled(module)
	CTLogger:PrintDebugMessage('CT:ModuleEnabled: '..module)
	for key, mod in self:IterateModules() do
		if key:lower():gsub(" ", "") == module:lower():gsub(" ", "") then
			return mod:IsEnabled()
		end
	end
	return false
end

function CT:GetModuleStatus()
	local active, inactive, total = 0, 0, 0
	for _, value in self:IterateModules() do
		if value:IsEnabled() then
			active = active + 1
		else
			inactive = inactive + 1
		end
		total = total + 1
	end
	return active, inactive, total
end

function CT:NumModules()
	local total = 0
	for _, value in self:IterateModules() do
		total = total + 1
	end
	return total
end

function CT:EnableAllModules()
	for name, module in self:IterateModules() do
		if self.db.profile.debugging then
			CTLogger:PrintDebugMessage(("Enabled %s%s|r module."):format(CTConstants.COLORS_HEX.brightblue, name))
		end
		module:Enable()
	end
end

function CT:DisableAllModules()
	for name, module in self:IterateModules() do
		if self.db.profile.debugging then
			CTLogger:PrintDebugMessage(("Disabled %s%s|r module."):format(CTConstants.COLORS_HEX.brightblue, name))
		end
		module:Disable()
	end
end
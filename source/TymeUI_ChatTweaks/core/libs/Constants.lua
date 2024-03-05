-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local CTConstants = private.NewLib('CTConstants');
local _G = getfenv(0)
local LibStub = _G.LibStub
local LSM = LibStub('LibSharedMedia-3.0');
local westAndRU = LSM.LOCALE_BIT_ruRU + LSM.LOCALE_BIT_western

local ReloadUI, PlaySound, StopMusic = ReloadUI, PlaySound, StopMusic
local YES, NO, OKAY, CANCEL, ACCEPT, DECLINE = YES, NO, OKAY, CANCEL, ACCEPT, DECLINE
local StaticPopupDialogs = StaticPopupDialogs

---============================================================================
-- AddonName
---============================================================================
CTConstants.ADDON_NAME = 'TymeUI_ChatTweaks';
CTConstants.ADDON_NAME_COLOR = "|cff0062ffChat|r|cff0DEB11Tweaks|r";
CTConstants.ADDON_DBNAME = 'ChatTweaksDB';
CTConstants.ADDON_DBNAME_CHAR = 'ChatTweaksCharacterDB';
CTConstants.ADDON_ABBREV = 'ChatTweaks';
CTConstants.Retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
CTConstants.Classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
CTConstants.TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC -- not used
CTConstants.Wrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

---============================================================================
-- DEBUG MODE
---============================================================================
CTConstants.DEBUG_MODE = false
---============================================================================
-- Colors
---============================================================================
CTConstants.COLORS_RGB = {
	["red"] = {143, 10, 13},
	["blue"] = {10, 12, 150},
	["cyan"] = {16, 211, 255},
	["teal"] = {0, 150, 89},
	["green"] = {20, 150, 10},
	["grassgreen"] = {50,150,50},
	["darkgreen"] = {5,107,0},
	["yellow"] = {255, 255, 0},
	["white"] = {255, 255, 255},
	["black"] = {0, 0, 0}
}

CTConstants.COLORS = {
	[1] = "red",
	[2] = "blue",
	[3] = "cyan",
	[4] = "teal",
	[5] = "green",
	[6] = "grassgreen",
	[7] = "yellow",
	[8] = "white",
	[9] = "black"
}

CTConstants.COLORS_HEX = {
	["orange"] = "|cFFFF8000",
	["purple"] = "|cFFA335EE",
	["brightblue"] = "|cFF0070DE",
	["brightgreen"] = "|cFF1EFF00",
	["white"] = "|cFFFFFFFF",
	["close"] = "|r"
}

---============================================================================
-- DEFAULT MEDIA
---============================================================================
CTConstants.DEFAULT_SOUNDS = {
	['Alert'] ='Popup.ogg',
	['CashRegister'] = 'CashRegister.mp3',
	['Choo'] = 'choo.mp3',
	['Dirty'] = 'dirty.mp3',
	['Doublehit'] = 'doublehit.mp3',
	['Dullhit'] = 'dullhit.mp3',
	['Gasp'] = 'gasp.mp3',
	['Heart'] = 'heart.mp3',
	['Himetal'] = 'himetal.mp3',
	['Hit'] = 'hit.mp3',
	['Kachink'] = 'kachink.mp3',
	['Link'] = 'link.mp3',
	['Pop1'] = 'pop1.mp3',
	['Pop2'] = 'pop2.mp3',
	['Shaker'] = 'shaker.mp3',
	['Switchy'] = 'switchy.mp3',
	['Text1'] = 'text1.mp3',
	['Text2'] = 'text2.mp3'
}

CTConstants.DEFAULT_FONTS = {
	['ActionMan.ttf'] = {'Action Man'},
	['ContinuumMedium.ttf'] = {'Continuum Medium'},
	['DieDieDie.ttf'] = {'Die Die Die!'},
	['PTSansNarrow.ttf'] = { 'PT Sans Narrow', nil, westAndRU },
	['Expressway.ttf'] = { true, nil, westAndRU },
	['Homespun.ttf'] = { true, nil, westAndRU },
	['Invisible.ttf'] = {}
}

---============================================================================
-- CMD commands
---============================================================================

CTConstants.CMD_CONFIG = "ct"
CTConstants.CMD_RELOADUI = "rl"
CTConstants.CMD_OPTIONS1 = "options"
CTConstants.CMD_OPTIONS2 = "opt"

CTConstants.general = {
	UIScale = 0.64,
	fontSize = 12,
	font = 'PT Sans Narrow',
	fontStyle = 'OUTLINE',
	bordercolor = { r = 0, g = 0, b = 0 },
	backdropcolor = { r = 0.1, g = 0.1, b = 0.1 },
	backdropfadecolor = { r = .06, g = .06, b = .06, a = 0.8 },
	valuecolor = { r = 0.09, g = 0.52, b = 0.82 },
}

StaticPopupDialogs['CONFIG_RL'] = {
    text = 'One or more of the changes you have made require a ReloadUI.',
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = ReloadUI,
	whileDead = 1,
	hideOnEscape = false,
}
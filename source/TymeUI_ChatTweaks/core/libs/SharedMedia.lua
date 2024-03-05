-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...
local _G = getfenv(0)
local LibStub = _G.LibStub

local CTSharedMedia = private.NewLib('CTSharedMedia');
local CTConstants = private.ImportLib('CTConstants');
local CTLogger = private.ImportLib('CTLogger');
local LSM = LibStub('LibSharedMedia-3.0');
local westAndRU = LSM.LOCALE_BIT_ruRU + LSM.LOCALE_BIT_western

CTSharedMedia.Media = {
	Fonts = {},
	Sounds = {},
}

local MediaKeys = {
	font	= 'Fonts',
	sound	= 'Sounds',
}

local MediaPaths = {
	font	= [[Interface\AddOns\TymeUI_ChatTweaks\media\Fonts\]],
	sound	= [[Interface\AddOns\TymeUI_ChatTweaks\media\Sounds\]],
}

function CTSharedMedia:TextureString(texture, data)
	local t, d = '|T%s%s|t', ''
	return format(t, texture, data or d)
end

CTSharedMedia.AddMedia = function(Type, File, Name, CustomType, Mask)
	local path = MediaPaths[Type]
	if path then
		local key = File:gsub('%.%w-$','')
		local file = path .. File
		local pathKey = MediaKeys[Type]
		if pathKey then CTSharedMedia.Media[pathKey][key] = file end
		if Name then -- Register to LSM
			local nameKey = (Name == true and key) or Name
			if type(CustomType) == 'table' then
				for _, name in ipairs(CustomType) do
					LSM:Register(name, nameKey, file, Mask)
				end
			else
				LSM:Register(CustomType or Type, nameKey, file, Mask)
			end
		end
	end
end

CTSharedMedia.Initialize = function()
	for k, v in pairs(CTConstants.DEFAULT_SOUNDS) do
		CTSharedMedia.AddMedia('sound',v,k)
	end

	for k, v in pairs(CTConstants.DEFAULT_FONTS) do
		CTSharedMedia.AddMedia('font',k,v[1],v[2],v[3])
	end
	
	local preloader = CreateFrame('Frame')
	preloader:SetPoint('TOP', UIParent, 'BOTTOM', 0, -500)
	preloader:SetSize(100, 100)

	local cacheFont = function(key, data)
		local loadFont = preloader:CreateFontString()
		loadFont:SetAllPoints()

		if pcall(loadFont.SetFont, loadFont, data, 14) then
			pcall(loadFont.SetText, loadFont, 'cache')
		end
	end

	-- Preload ElvUI Invisible
	cacheFont('Invisible', CTSharedMedia.Media.Fonts.Invisible)

	-- Lets load all the fonts in LSM to prevent fonts not being ready
	local sharedFonts = LSM:HashTable('font')
	for key, data in next, sharedFonts do
		cacheFont(key, data)
	end

	-- this helps fix most of the issues with fonts or textures reverting to default because the addon providing them is loading after ElvUI
	local callMedia = function(mediaType) CTSharedMedia:UpdateMedia(mediaType) end

	-- Now lets hook it so we can preload any other AddOns add to LSM
	hooksecurefunc(LSM, 'Register', function(_, mediaType, key, data)
		if not mediaType or type(mediaType) ~= 'string' then return end

		local mtype = mediaType:lower()
		if mtype == 'font' then
			cacheFont(key, data)
			callMedia(mtype)
		elseif mtype == 'background' or mtype == 'statusbar' then
			callMedia(mtype)
		end
	end)

	CTLogger:PrintDebugMessage('Media registration complete')
end

function CTSharedMedia:UpdateMedia(mediaType)
	
end
CTSharedMedia.Initialize();
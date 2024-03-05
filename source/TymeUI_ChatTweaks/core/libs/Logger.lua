-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...

local CTLogger = private.NewLib('CTLogger')
local CTConstants = private.ImportLib('CTConstants')
local CTUtils = private.ImportLib('CTUtils')

function CTLogger:PrintMessage(message)
	print('['..CTConstants.ADDON_NAME_COLOR..']: '..message)
end

function CTLogger:PrintDebugMessage(message)
	if (CTConstants.DEBUG_MODE) then
		print('|cFFDC143C['..CTConstants.ADDON_ABBREV..']: |cFFFFFFFF'..tostring(message))
	end
end
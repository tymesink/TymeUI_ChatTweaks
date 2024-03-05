-----------------------------------------------------------------------
-- AddOn namespace.
-----------------------------------------------------------------------
local ADDON_NAME, private = ...
local _G = getfenv(0)
local CTUtils = private.NewLib('CTUtils');
local CTConstants = private.ImportLib('CTConstants');
local CTLogger = private.ImportLib('CTLogger');

CTUtils.GetAddOnMetadata = _G['GetAddOnMetadata'];
CTUtils.Collectgarbage = _G['collectgarbage'];

CTUtils.RGBToHex = function(r, g, b, header, ending)
	r = r <= 1 and r >= 0 and r or 1
	g = g <= 1 and g >= 0 and g or 1
	b = b <= 1 and b >= 0 and b or 1
	return format('%s%02x%02x%02x%s', header or '|cff', r*255, g*255, b*255, ending or '')
end

CTUtils.HexToRGB = function(hex)
	local a, r, g, b = strmatch(hex, '^|?c?(%x%x)(%x%x)(%x%x)(%x?%x?)|?r?$')
	if not a then return 0, 0, 0, 0 end
	if b == '' then r, g, b, a = a, r, g, 'ff' end

	return tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), tonumber(a, 16)
end

CTUtils.SetColorTable = function(t, data)
	if not data.r or not data.g or not data.b then
		CTUtils.Print('error','SetColorTable: Could not unpack color values.')
	end

	if t and (type(t) == 'table') then
		local r, g, b, a = CTUtils.UpdateColorTable(data)

		t.r, t.g, t.b, t.a = r, g, b, a
		t[1], t[2], t[3], t[4] = r, g, b, a
	else
		t = CTUtils.GetColorTable(data)
	end

	return t
end

CTUtils.UpdateColorTable = function(data)
	if not data.r or not data.g or not data.b then
		CTUtils.Print('error','UpdateColorTable: Could not unpack color values.')
	end

	CTUtils.VerifyColorTable(data)

	return data.r, data.g, data.b, data.a
end

CTUtils.GetColorTable = function(data)
	if not data.r or not data.g or not data.b then
		CTUtils.Print('error','GetColorTable: Could not unpack color values.')
	end

	CTUtils.VerifyColorTable(data)

	local r, g, b, a = data.r, data.g, data.b, data.a
	return { r, g, b, a, r = r, g = g, b = b, a = a }
end

CTUtils.VerifyColorTable = function(data)
	if data.r > 1 or data.r < 0 then data.r = 1 end
	if data.g > 1 or data.g < 0 then data.g = 1 end
	if data.b > 1 or data.b < 0 then data.b = 1 end
	if data.a and (data.a > 1 or data.a < 0) then data.a = 1 end
end

---============================================================================
-- Character Name
---============================================================================
CTUtils.GetCharacterName = function(lowercase)
	local charname = UnitName('player');
	if lowercase == true and charname ~= nil then
		return string.lower(charname)
	else
		return charname;
	end
end

CTUtils.GetCharacterRealmName = function(addSpace)
	local charname = UnitName('player');
	local realmname = GetRealmName();
	if charname == nil or realmname == nil then
		return '';
	end

	if(addSpace == true) then
		return charname..' - '..realmname;
	else
		return charname..'-'..realmname;
	end
end

---============================================================================
-- PairsByKeys
---============================================================================
CTUtils.PairsByKeys = function(t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0
	local iter = function()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iter
end

---============================================================================
-- GetTable - Returns the value in a table
---============================================================================
CTUtils.GetTable = function(what, where)
	if (type(where) == 'table') then
		for index,value in pairs(where) do
			if (what == index) then
				return value;
			elseif (what == value) then
				return index;
			elseif (type(value) == 'table') then
				for index2,value2 in pairs(value) do
					if (what == index2) then
						return value2;
					elseif (what == value2) then
						return index2;
						end
				end
			end
		end
	else
		CTLogger.PrintDebugMessage('No table for GetTable')
		return nil;
	end
end

---============================================================================
-- FindTable - Returns if a value is found in a table
---============================================================================
CTUtils.FindTable = function(what, where)
	local isFound = false;
	if (type(where) == 'table') then
		for index,value in pairs(where) do
			if (value == what) then
				isFound=true;
			elseif (index == what) then
				isFound=true;
			end
		end
		for index,value in pairs(where) do
			if (type(value) == 'table') then
				for index2,value2 in pairs(value) do
					if (value2 == what) then
						isFound = true;
					elseif (index2 == what) then
						isFound=true;
					end
				end
			end
		end
	else
		CTLogger.PrintDebugMessage('No table for FindTable')
		return nil;
	end
	return isFound;
end

---============================================================================
-- SplitTable - Splits a RGB table into WoW values
---============================================================================
CTUtils.SplitTable = function (arg)
	local val1, val2, val3;
	if (type(arg) == 'table') then
		for index,value in pairs(arg) do
			if (index == 1) then
				val1 = tonumber(value/255);
			elseif (index == 2) then
				val2 = tonumber(value/255);
			elseif (index == 3) then
				val3 = tonumber(value/255);
			end
		end
	end
	return val1, val2, val3;
end

---============================================================================
-- ClearTable - Clears an array (table)
---============================================================================
CTUtils.ClearTable = function (arg)
	arg = table.wipe(arg);
end

---============================================================================
-- CopyTable - Copies a table for safe resetting or other uses
---============================================================================
-- CTUtils.CopyTable = function (arg)
-- 	local newTable;
-- 	if (type(arg) == 'table') then
-- 		newTable = {};
-- 		for index,value in pairs(arg) do
-- 			newTable[index] = value;
-- 		end
-- 	end
-- 	return newTable;
-- end

CTUtils.CopyTable = function(current, default)
	if type(current) ~= 'table' then
		current = {}
	end

	if type(default) == 'table' then
		for option, value in pairs(default) do
			current[option] = (type(value) == 'table' and CTUtils.CopyTable(current[option], value)) or value
		end
	end

	return current
end

---============================================================================
-- MergeTable - Makes sure settings are in one array from another array
---============================================================================
CTUtils.MergeTable = function(arrayTo, arrayFrom)
	local newArray;

	if (type(arrayTo) ~= 'table') or (type(arrayFrom) ~= 'table') then
		return nil;
	else
		newArray = CTUtils.CopyTable(arrayTo);
	end

	for index,value in pairs(arrayFrom) do
		local isThere = CTUtils.FindTable(index, newArray);
		if (not isThere) then
			newArray[index]=value;
		end
	end

	return newArray;
end

---============================================================================
-- PrintTable - Debug feature. Dumps the values of the table to the UI
---============================================================================
CTUtils.PrintTable = function(s, l, i) -- recursive Print (structure, limit, indent)
	l = (l) or 100; i = i or "";	-- default item limit, indent string
	if (l<1) then print "ERROR: Item limit reached."; return l-1 end;
	local ts = type(s);
	if (ts ~= "table") then print (i,ts,s); return l-1 end
	print (i,ts);           -- print "table"
	for k,v in pairs(s) do  -- print "[KEY] VALUE"
		l = CTUtils.PrintTable(v, l, i.."\t["..tostring(k).."]");
		if (l < 0) then break end
	end
	return l
end

---============================================================================
-- Print - Outputs a message to the UI
---============================================================================
CTUtils.Print = function(msgType, msg, colors)
	local valR, valG, valB;

	if (type(msg) ~= 'string') then return nil; end
	if msg == nil then return nil; end

	if (type(colors) == 'table') then
		valR, valG, valB = CTUtils.SplitTable(colors);
	elseif (CTUtils.FindTable(colors, CTConstants.COLORS_RGB)) then
		valR,valG,valB = CTUtils.SplitTable(CTUtils.GetTable(colors, CTConstants.COLORS_RGB));
	else
		valR, valG, valB = CTUtils.SplitTable(CTConstants.COLORS_RGB.yellow);
	end

	if msgType == 'error' then
		UIErrorsFrame:AddMessage('<'..CTConstants.ADDON_ABBREV..'> '..msg, valR, valG, valB, 1, 10)
	end

	if msgType == 'chat' then
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage(CTConstants.ADDON_NAME_COLOR..': '..msg, valR, valG, valB)
		end
	end

	if msgType == 'debug' and CTConstants.DEBUG_MODE == true then
		if DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage(CTConstants.ADDON_ABBREV..': '..msg, valR, valG, valB)
		end
	end

	if msgType == 'debugerror' then
		UIErrorsFrame:AddMessage('<'..CTConstants.ADDON_ABBREV..'> '..msg, valR, valG, valB, 1, 10)
	end
 end

---============================================================================
-- IsNilOrEmpty
---============================================================================
CTUtils.IsNilOrEmpty = function(stringValue)
	return stringValue == nil or stringValue == '';
end
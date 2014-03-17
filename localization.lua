-- To add a localized string, uncomment it then enter the translated string after the =
-- Don't localize command names (such as /wxp ask)

local _, namespace = ...

local L = setmetatable({}, { __index = function(t, k)
	local v = tostring(k)
	rawset(t, k, v)
	return v
end })

namespace.L = L

local LOCALE = GetLocale()

if LOCALE:match("^en") then
	return

elseif LOCALE == "esES" or LOCALE == "esMX" then -- Spanish
	--L["%s is using an outdated version of WatchXP! Tell them to update it or it won't work with you. Type |cffff7f00/wxp updatewarning|r to disable these messages."]= ""
	--L["Got XP response from %s (%s). This blip will not automatically update. To remove the blip, type /wxp clear."]= ""
	
	--L["Debug output %s"]			= ""
	--L["enabled"]					= ""
	--L["disabled"]					= ""
	--L["Update warning %s"]			= ""
	--L["Version: %s (%s)"]			= ""
	
	--L["Show the options panel"]		= ""
	--L["Request a marker for a player not in your group (they still need WatchXP)"]= ""
	--L["Request a marker for a Battle.net friend (they still need WatchXP)"]= ""
	--L["Request a marker for the nth online Battle.net friend in your friends list (they still need WatchXP)"]= ""
	--L["Toggle visibility of WatchXP"]= ""
	--L["Refreshes the display and forces an update from all party members. Also removes leftover markers or markers added with /wxp ask"]= ""
	--L["Toggle debug output"]		= ""
	--L["Toggle warning when other players are using an older, incompatible version"]= ""
	--L["Display addon version"]		= ""
	
	--L["Hiding WatchXP"]				= ""
	--L["Showing WatchXP"]			= ""
	--L["Sending XP request to %s"]	= ""
	--L["You must be connected to Battle.net to do that"]= ""
	--L["Sending XP request to %s"]	= ""
	
	--L["Label font size"]			= ""
	--L["Blip vertical offset"]		= ""
	--L["Label vertical offset"]		= ""
	--L["Blip size"]					= ""
	
	--L["Level %i"]					= ""
	--L["XP: %s / %s (%s%%)"]			= ""
	--L["Labels"]						= ""
	
	--L["Example!"]					= ""
	--L["RealmName"]					= ""
	
	--L["Shows markers on the experience bar for party members"] = ""
	--L["Blip Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Blip Texture"]				= ""
	--L["Show WatchXP"]				= ""
	--L["Animate Blips"]				= ""
	--L["Label Settings"]				= ""
	
	--L["Control display of labels next to markers"]= ""
	--L["Label Color"]				= ""
	--L["Label Font"]					= ""
	--L["Font Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Show Level in Label"]		= ""
	--L["Show Realm in Label"]		= ""
	--L["Show Labels"]				= ""
	
	--L["Never"]						= ""
	--L["Different"]					= ""
	--L["Always"]						= ""

elseif LOCALE == "deDE" then -- German
	--L["%s is using an outdated version of WatchXP! Tell them to update it or it won't work with you. Type |cffff7f00/wxp updatewarning|r to disable these messages."]= ""
	--L["Got XP response from %s (%s). This blip will not automatically update. To remove the blip, type /wxp clear."]= ""
	
	--L["Debug output %s"]			= ""
	--L["enabled"]					= ""
	--L["disabled"]					= ""
	--L["Update warning %s"]			= ""
	--L["Version: %s (%s)"]			= ""
	
	--L["Show the options panel"]		= ""
	--L["Request a marker for a player not in your group (they still need WatchXP)"]= ""
	--L["Request a marker for a Battle.net friend (they still need WatchXP)"]= ""
	--L["Request a marker for the nth online Battle.net friend in your friends list (they still need WatchXP)"]= ""
	--L["Toggle visibility of WatchXP"]= ""
	--L["Refreshes the display and forces an update from all party members. Also removes leftover markers or markers added with /wxp ask"]= ""
	--L["Toggle debug output"]		= ""
	--L["Toggle warning when other players are using an older, incompatible version"]= ""
	--L["Display addon version"]		= ""
	
	--L["Hiding WatchXP"]				= ""
	--L["Showing WatchXP"]			= ""
	--L["Sending XP request to %s"]	= ""
	--L["You must be connected to Battle.net to do that"]= ""
	--L["Sending XP request to %s"]	= ""
	
	--L["Label font size"]			= ""
	--L["Blip vertical offset"]		= ""
	--L["Label vertical offset"]		= ""
	--L["Blip size"]					= ""
	
	--L["Level %i"]					= ""
	--L["XP: %s / %s (%s%%)"]			= ""
	--L["Labels"]						= ""
	
	--L["Example!"]					= ""
	--L["RealmName"]					= ""
	
	--L["Shows markers on the experience bar for party members"] = ""
	--L["Blip Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Blip Texture"]				= ""
	--L["Show WatchXP"]				= ""
	--L["Animate Blips"]				= ""
	--L["Label Settings"]				= ""
	
	--L["Control display of labels next to markers"]= ""
	--L["Label Color"]				= ""
	--L["Label Font"]					= ""
	--L["Font Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Show Level in Label"]		= ""
	--L["Show Realm in Label"]		= ""
	--L["Show Labels"]				= ""
	
	--L["Never"]						= ""
	--L["Different"]					= ""
	--L["Always"]						= ""

elseif LOCALE == "frFR" then -- French
	--L["%s is using an outdated version of WatchXP! Tell them to update it or it won't work with you. Type |cffff7f00/wxp updatewarning|r to disable these messages."]= ""
	--L["Got XP response from %s (%s). This blip will not automatically update. To remove the blip, type /wxp clear."]= ""
	
	--L["Debug output %s"]			= ""
	--L["enabled"]					= ""
	--L["disabled"]					= ""
	--L["Update warning %s"]			= ""
	--L["Version: %s (%s)"]			= ""
	
	--L["Show the options panel"]		= ""
	--L["Request a marker for a player not in your group (they still need WatchXP)"]= ""
	--L["Request a marker for a Battle.net friend (they still need WatchXP)"]= ""
	--L["Request a marker for the nth online Battle.net friend in your friends list (they still need WatchXP)"]= ""
	--L["Toggle visibility of WatchXP"]= ""
	--L["Refreshes the display and forces an update from all party members. Also removes leftover markers or markers added with /wxp ask"]= ""
	--L["Toggle debug output"]		= ""
	--L["Toggle warning when other players are using an older, incompatible version"]= ""
	--L["Display addon version"]		= ""
	
	--L["Hiding WatchXP"]				= ""
	--L["Showing WatchXP"]			= ""
	--L["Sending XP request to %s"]	= ""
	--L["You must be connected to Battle.net to do that"]= ""
	--L["Sending XP request to %s"]	= ""
	
	--L["Label font size"]			= ""
	--L["Blip vertical offset"]		= ""
	--L["Label vertical offset"]		= ""
	--L["Blip size"]					= ""
	
	--L["Level %i"]					= ""
	--L["XP: %s / %s (%s%%)"]			= ""
	--L["Labels"]						= ""
	
	--L["Example!"]					= ""
	--L["RealmName"]					= ""
	
	--L["Shows markers on the experience bar for party members"] = ""
	--L["Blip Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Blip Texture"]				= ""
	--L["Show WatchXP"]				= ""
	--L["Animate Blips"]				= ""
	--L["Label Settings"]				= ""
	
	--L["Control display of labels next to markers"]= ""
	--L["Label Color"]				= ""
	--L["Label Font"]					= ""
	--L["Font Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Show Level in Label"]		= ""
	--L["Show Realm in Label"]		= ""
	--L["Show Labels"]				= ""
	
	--L["Never"]						= ""
	--L["Different"]					= ""
	--L["Always"]						= ""

elseif LOCALE == "ptBR" then -- Brazilian Portugese
	--L["%s is using an outdated version of WatchXP! Tell them to update it or it won't work with you. Type |cffff7f00/wxp updatewarning|r to disable these messages."]= ""
	--L["Got XP response from %s (%s). This blip will not automatically update. To remove the blip, type /wxp clear."]= ""
	
	--L["Debug output %s"]			= ""
	--L["enabled"]					= ""
	--L["disabled"]					= ""
	--L["Update warning %s"]			= ""
	--L["Version: %s (%s)"]			= ""
	
	--L["Show the options panel"]		= ""
	--L["Request a marker for a player not in your group (they still need WatchXP)"]= ""
	--L["Request a marker for a Battle.net friend (they still need WatchXP)"]= ""
	--L["Request a marker for the nth online Battle.net friend in your friends list (they still need WatchXP)"]= ""
	--L["Toggle visibility of WatchXP"]= ""
	--L["Refreshes the display and forces an update from all party members. Also removes leftover markers or markers added with /wxp ask"]= ""
	--L["Toggle debug output"]		= ""
	--L["Toggle warning when other players are using an older, incompatible version"]= ""
	--L["Display addon version"]		= ""
	
	--L["Hiding WatchXP"]				= ""
	--L["Showing WatchXP"]			= ""
	--L["Sending XP request to %s"]	= ""
	--L["You must be connected to Battle.net to do that"]= ""
	--L["Sending XP request to %s"]	= ""
	
	--L["Label font size"]			= ""
	--L["Blip vertical offset"]		= ""
	--L["Label vertical offset"]		= ""
	--L["Blip size"]					= ""
	
	--L["Level %i"]					= ""
	--L["XP: %s / %s (%s%%)"]			= ""
	--L["Labels"]						= ""
	
	--L["Example!"]					= ""
	--L["RealmName"]					= ""
	
	--L["Shows markers on the experience bar for party members"] = ""
	--L["Blip Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Blip Texture"]				= ""
	--L["Show WatchXP"]				= ""
	--L["Animate Blips"]				= ""
	--L["Label Settings"]				= ""
	
	--L["Control display of labels next to markers"]= ""
	--L["Label Color"]				= ""
	--L["Label Font"]					= ""
	--L["Font Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Show Level in Label"]		= ""
	--L["Show Realm in Label"]		= ""
	--L["Show Labels"]				= ""
	
	--L["Never"]						= ""
	--L["Different"]					= ""
	--L["Always"]						= ""

elseif LOCALE == "ruRU" then -- Russian
	--L["%s is using an outdated version of WatchXP! Tell them to update it or it won't work with you. Type |cffff7f00/wxp updatewarning|r to disable these messages."]= ""
	--L["Got XP response from %s (%s). This blip will not automatically update. To remove the blip, type /wxp clear."]= ""
	
	--L["Debug output %s"]			= ""
	--L["enabled"]					= ""
	--L["disabled"]					= ""
	--L["Update warning %s"]			= ""
	--L["Version: %s (%s)"]			= ""
	
	--L["Show the options panel"]		= ""
	--L["Request a marker for a player not in your group (they still need WatchXP)"]= ""
	--L["Request a marker for a Battle.net friend (they still need WatchXP)"]= ""
	--L["Request a marker for the nth online Battle.net friend in your friends list (they still need WatchXP)"]= ""
	--L["Toggle visibility of WatchXP"]= ""
	--L["Refreshes the display and forces an update from all party members. Also removes leftover markers or markers added with /wxp ask"]= ""
	--L["Toggle debug output"]		= ""
	--L["Toggle warning when other players are using an older, incompatible version"]= ""
	--L["Display addon version"]		= ""
	
	--L["Hiding WatchXP"]				= ""
	--L["Showing WatchXP"]			= ""
	--L["Sending XP request to %s"]	= ""
	--L["You must be connected to Battle.net to do that"]= ""
	--L["Sending XP request to %s"]	= ""
	
	--L["Label font size"]			= ""
	--L["Blip vertical offset"]		= ""
	--L["Label vertical offset"]		= ""
	--L["Blip size"]					= ""
	
	--L["Level %i"]					= ""
	--L["XP: %s / %s (%s%%)"]			= ""
	--L["Labels"]						= ""
	
	--L["Example!"]					= ""
	--L["RealmName"]					= ""
	
	--L["Shows markers on the experience bar for party members"] = ""
	--L["Blip Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Blip Texture"]				= ""
	--L["Show WatchXP"]				= ""
	--L["Animate Blips"]				= ""
	--L["Label Settings"]				= ""
	
	--L["Control display of labels next to markers"]= ""
	--L["Label Color"]				= ""
	--L["Label Font"]					= ""
	--L["Font Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Show Level in Label"]		= ""
	--L["Show Realm in Label"]		= ""
	--L["Show Labels"]				= ""
	
	--L["Never"]						= ""
	--L["Different"]					= ""
	--L["Always"]						= ""

elseif LOCALE == "koKR" then -- Korean
	--L["%s is using an outdated version of WatchXP! Tell them to update it or it won't work with you. Type |cffff7f00/wxp updatewarning|r to disable these messages."]= ""
	--L["Got XP response from %s (%s). This blip will not automatically update. To remove the blip, type /wxp clear."]= ""
	
	--L["Debug output %s"]			= ""
	--L["enabled"]					= ""
	--L["disabled"]					= ""
	--L["Update warning %s"]			= ""
	--L["Version: %s (%s)"]			= ""
	
	--L["Show the options panel"]		= ""
	--L["Request a marker for a player not in your group (they still need WatchXP)"]= ""
	--L["Request a marker for a Battle.net friend (they still need WatchXP)"]= ""
	--L["Request a marker for the nth online Battle.net friend in your friends list (they still need WatchXP)"]= ""
	--L["Toggle visibility of WatchXP"]= ""
	--L["Refreshes the display and forces an update from all party members. Also removes leftover markers or markers added with /wxp ask"]= ""
	--L["Toggle debug output"]		= ""
	--L["Toggle warning when other players are using an older, incompatible version"]= ""
	--L["Display addon version"]		= ""
	
	--L["Hiding WatchXP"]				= ""
	--L["Showing WatchXP"]			= ""
	--L["Sending XP request to %s"]	= ""
	--L["You must be connected to Battle.net to do that"]= ""
	--L["Sending XP request to %s"]	= ""
	
	--L["Label font size"]			= ""
	--L["Blip vertical offset"]		= ""
	--L["Label vertical offset"]		= ""
	--L["Blip size"]					= ""
	
	--L["Level %i"]					= ""
	--L["XP: %s / %s (%s%%)"]			= ""
	--L["Labels"]						= ""
	
	--L["Example!"]					= ""
	--L["RealmName"]					= ""
	
	--L["Shows markers on the experience bar for party members"] = ""
	--L["Blip Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Blip Texture"]				= ""
	--L["Show WatchXP"]				= ""
	--L["Animate Blips"]				= ""
	--L["Label Settings"]				= ""
	
	--L["Control display of labels next to markers"]= ""
	--L["Label Color"]				= ""
	--L["Label Font"]					= ""
	--L["Font Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Show Level in Label"]		= ""
	--L["Show Realm in Label"]		= ""
	--L["Show Labels"]				= ""
	
	--L["Never"]						= ""
	--L["Different"]					= ""
	--L["Always"]						= ""

elseif LOCALE == "zhCN" then -- Simplified Chinese
	--L["%s is using an outdated version of WatchXP! Tell them to update it or it won't work with you. Type |cffff7f00/wxp updatewarning|r to disable these messages."]= ""
	--L["Got XP response from %s (%s). This blip will not automatically update. To remove the blip, type /wxp clear."]= ""
	
	--L["Debug output %s"]			= ""
	--L["enabled"]					= ""
	--L["disabled"]					= ""
	--L["Update warning %s"]			= ""
	--L["Version: %s (%s)"]			= ""
	
	--L["Show the options panel"]		= ""
	--L["Request a marker for a player not in your group (they still need WatchXP)"]= ""
	--L["Request a marker for a Battle.net friend (they still need WatchXP)"]= ""
	--L["Request a marker for the nth online Battle.net friend in your friends list (they still need WatchXP)"]= ""
	--L["Toggle visibility of WatchXP"]= ""
	--L["Refreshes the display and forces an update from all party members. Also removes leftover markers or markers added with /wxp ask"]= ""
	--L["Toggle debug output"]		= ""
	--L["Toggle warning when other players are using an older, incompatible version"]= ""
	--L["Display addon version"]		= ""
	
	--L["Hiding WatchXP"]				= ""
	--L["Showing WatchXP"]			= ""
	--L["Sending XP request to %s"]	= ""
	--L["You must be connected to Battle.net to do that"]= ""
	--L["Sending XP request to %s"]	= ""
	
	--L["Label font size"]			= ""
	--L["Blip vertical offset"]		= ""
	--L["Label vertical offset"]		= ""
	--L["Blip size"]					= ""
	
	--L["Level %i"]					= ""
	--L["XP: %s / %s (%s%%)"]			= ""
	--L["Labels"]						= ""
	
	--L["Example!"]					= ""
	--L["RealmName"]					= ""
	
	--L["Shows markers on the experience bar for party members"] = ""
	--L["Blip Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Blip Texture"]				= ""
	--L["Show WatchXP"]				= ""
	--L["Animate Blips"]				= ""
	--L["Label Settings"]				= ""
	
	--L["Control display of labels next to markers"]= ""
	--L["Label Color"]				= ""
	--L["Label Font"]					= ""
	--L["Font Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Show Level in Label"]		= ""
	--L["Show Realm in Label"]		= ""
	--L["Show Labels"]				= ""
	
	--L["Never"]						= ""
	--L["Different"]					= ""
	--L["Always"]						= ""

elseif LOCALE == "zhTW" then -- Traditional Chinese
	--L["%s is using an outdated version of WatchXP! Tell them to update it or it won't work with you. Type |cffff7f00/wxp updatewarning|r to disable these messages."]= ""
	--L["Got XP response from %s (%s). This blip will not automatically update. To remove the blip, type /wxp clear."]= ""
	
	--L["Debug output %s"]			= ""
	--L["enabled"]					= ""
	--L["disabled"]					= ""
	--L["Update warning %s"]			= ""
	--L["Version: %s (%s)"]			= ""
	
	--L["Show the options panel"]		= ""
	--L["Request a marker for a player not in your group (they still need WatchXP)"]= ""
	--L["Request a marker for a Battle.net friend (they still need WatchXP)"]= ""
	--L["Request a marker for the nth online Battle.net friend in your friends list (they still need WatchXP)"]= ""
	--L["Toggle visibility of WatchXP"]= ""
	--L["Refreshes the display and forces an update from all party members. Also removes leftover markers or markers added with /wxp ask"]= ""
	--L["Toggle debug output"]		= ""
	--L["Toggle warning when other players are using an older, incompatible version"]= ""
	--L["Display addon version"]		= ""
	
	--L["Hiding WatchXP"]				= ""
	--L["Showing WatchXP"]			= ""
	--L["Sending XP request to %s"]	= ""
	--L["You must be connected to Battle.net to do that"]= ""
	--L["Sending XP request to %s"]	= ""
	
	--L["Label font size"]			= ""
	--L["Blip vertical offset"]		= ""
	--L["Label vertical offset"]		= ""
	--L["Blip size"]					= ""
	
	--L["Level %i"]					= ""
	--L["XP: %s / %s (%s%%)"]			= ""
	--L["Labels"]						= ""
	
	--L["Example!"]					= ""
	--L["RealmName"]					= ""
	
	--L["Shows markers on the experience bar for party members"] = ""
	--L["Blip Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Blip Texture"]				= ""
	--L["Show WatchXP"]				= ""
	--L["Animate Blips"]				= ""
	--L["Label Settings"]				= ""
	
	--L["Control display of labels next to markers"]= ""
	--L["Label Color"]				= ""
	--L["Label Font"]					= ""
	--L["Font Size"]					= ""
	--L["Vertical Offset"]			= ""
	--L["Show Level in Label"]		= ""
	--L["Show Realm in Label"]		= ""
	--L["Show Labels"]				= ""
	
	--L["Never"]						= ""
	--L["Different"]					= ""
	--L["Always"]						= ""

end

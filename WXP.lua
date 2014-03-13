--[[
		1.31: Thought I fixed it, didn't
		1.32: Fixed and bumped toc to 40000 (for real this time)
		1.35: Added /wxp ask [player] command to get a marker for a person not in your group
		1.4 : Changed max level from 80 to 85 for Cataclysm and hid the addon load message (who wants those anyway?)
		1.41: Updated toc version to 4.2
		1.42: Fixed problem (probably missing RegisterAddonMessagePrefix) preventing addon from working, and hid the loaded message for real this time
		2.0 : Revamped addon to use blips instead of text, Changed config blip to "Example!" so people with the character name "Example" don't break everything, Redesigned options panel, Removed commands to change settings, just use the config panel
		2.01: TOC update for 4.3
		2.1 : Added RealID support for /wxp ask (use /wxp ask firstname lastname OR /wxp ask [position in friends list], it will detect the space in the name and use RealID instead of a character name)
		2.11: Updated for 5.0.4
		2.12: Fixed issue with blips showing up for max-level characters
		2.13: Removed a debug print
		2.14: Fixed an issue with the "Show Level in label" option not working correctly
		2.2 : Maximum level is now determined automatically, instead of being hard-coded, so it will now start working again with MoP
		2.21: Fixed "Whisper message missing target player!" error
		2.22: Fixed markers not disappearing when someone leaves the group
		2.23: Updated TOC version to 5.1
		2.24: Updated TOC version to 5.2
		2.25: Updated TOC version to 5.3
		2.26: Updated TOC version to 5.4
		3.0 : Rewrote how WatchXP shares data, fixed some cross-realm stuff
]]--

--- Events ---

WXP = {}

WXP.version = GetAddOnMetadata("WatchXP","Version")
WXP.date = GetAddOnMetadata("WatchXP","X-Date")

WXP.default_settings = {
	debug = false,
	updatewarning = true,
	
	blip = {
		show = true,
		id = 6,
		size = 16,
		
		offset = {
			y = 0
		}
	},
	
	label = {
		show = true,
		showlevel = "different",
		showrealm = "different",
		
		offset = {
			y = 0
		},
		
		color = {
			r = 1,
			g = 1,
			b = 1,
			a = 1
		},
		
		font = {
			face = "friz",
			size = 12
		}
	}
}

function WXP.OnLoad(self)				-- Fired when addon is loaded
	SlashCmdList["WXP"] = WXP.OnCommand;
	SLASH_WXP1 = "/watchxp";
	SLASH_WXP2 = "/wxp";
	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("CHAT_MSG_BN_WHISPER")
	self:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM") -- When you send a RealID message
	RegisterAddonMessagePrefix("WXP")
	
	if UnitLevel("player") == WXP.GetMaxLevel() then
		WXP_Frame:SetParent("ReputationWatchBar")
		WXP_Frame:SetAllPoints()
	end
end

function WXP.OnEvent(self, event, ...)	-- Fired when a registered event is triggered
	if event == "PLAYER_XP_UPDATE" then
		WXP.SendExpToParty()
	
	elseif event == "ADDON_LOADED" then
		local addonName = ...
		if addonName ~= "WatchXP" then return end
		
		-- Insert missing values from the default settings, and upgrade from older settings
		if not WXP_Settings then WXP_Settings = {} end
		WXP_Settings = WXP.InsertDefaultSettings(WXP_Settings,WXP.default_settings)
		WXP.ImportOlderSettings()
		WXP_Settings.version = WXP.version
		
		-- Initialize UI stuff
		WXP.InitializeWidgets()
		if not WXP_Settings.blip.show then WXP_Frame:Hide() end
		
		-- Blizzard bug: options panel's OnShow doesn't trigger unless we hide it first (even though it starts out hidden)
		WXP_Options:Hide()
		WXP_Options_Label:Hide()
		
		-- Add a chat filter so RealID /wxp ask messages aren't shown
		ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER", WXP.BNMessageFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_BN_WHISPER_INFORM", WXP.BNMessageFilter)
		
		-- Finally, poll the party to get experience from party members
		WXP.PollParty()
	
	elseif event == "CHAT_MSG_ADDON" then
		local addonName, args, channel, sender = ...;
		if addonName ~= "WXP" then return end
		
		WXP.Debug("|cffcccccc[AddonMessage]|r|cffaaaaaa", args)
		
		local msgArgs = {strsplit(",", args)}
		
		if msgArgs[1] == "party-xp" or msgArgs[1] == "ask-xp" then
			local name  = msgArgs[2]
			local realm = msgArgs[3]
			local level = msgArgs[4]
			local xp    = msgArgs[5]
			local xpmax = msgArgs[6]
			
			if not (name == UnitName("player") and realm == GetRealmName("player")) then -- if both character and realm name are same as ours, ignore it
				if msgArgs[1] == "xp" then
					WXP.Debug(format("|cff8888ff<<< Got party XP: %s %s / %s through %s", WXP.PlayerLink(name,realm), WXP.format_thousand(xp), WXP.format_thousand(xpmax), level))
				elseif msgArgs[1] == "askxp" then
					WXP.Debug(format("|cffd24cff<<< Got player XP: %s %s / %s through %s", WXP.PlayerLink(name,realm), WXP.format_thousand(xp), WXP.format_thousand(xpmax), level))
				end
				
				local marker = WXPMarker.Find(name,realm)
				if marker then
					marker:Update({name=name, realm=realm, level=level, xp=xp, xpmax=xpmax})
				else
					WXPMarker.new({name=name, realm=realm, level=level, xp=xp, xpmax=xpmax})
				end
			end
		
		elseif msgArgs[1] == "NEWXP" and WXP_Settings.updatewarning then -- Show a deprecation warning
			local name = msgArgs[4]
			WXP.Msg(name.." is using an outdated version of WatchXP! Tell them to update it or it won't work with you. Type |cffff7f00/wxp updatewarning|r to disable these messages.")
		
		end
		
		if msgArgs[1] == "party-req" then
			if not (msgArgs[2] == UnitName("player") and msgArgs[3] == GetRealmName("player")) then -- if both character and realm name are same as ours, ignore it
				WXP.Debug("|cff4444ff<<< Got party XP request from:|r", args)
				WXP.SendExpToParty()
			end
		end
		
		if msgArgs[1] == "ask-req" then
			local name = msgArgs[2]
			local realm = msgArgs[3]
			WXP.SendExpToPlayer(name.."-"..realm)
		end
	
	--if event == "RAID_ROSTER_UPDATE" then
	elseif event == "GROUP_ROSTER_UPDATE" then
		WXP.Debug("|cff8888ffParty altered!|r")
		WXPMarker.RemoveAll()
		
		if GetNumSubgroupMembers() > 0 then -- If we're in a group, request everything again
			WXP.PollParty()
		end
	
	elseif event == "CHAT_MSG_BN_WHISPER" then
		local msg,name,_,_,_,_,_,_,_,_,_,_,pid = ...
		if msg:find("wxp-bn-xp") then
			local _,xp,xpmax,name,level = strsplit(",", msg)
			
			local num = WXP.GetFrameFromName(name,realm)
			if num then
				WXP.Update({name=name, realm=realm, level=level, xp=xp, xpmax=xpmax}, num)
			else
				WXP.Create({name=name, realm=realm, level=level, xp=xp, xpmax=xpmax})
			end
		elseif msg:find("wxp-bn-req") then
			WXP.SendExpToBNFriend(pid)
		end
	
	end
end

function WXP.OnCommand(cmd)				-- Fired when the player enters a command starting with /wxp
	if cmd == "config" or cmd == "options" or cmd == "settings" or cmd == "opt" or cmd == "cfg" or cmd == "win" then
		InterfaceOptionsFrame_OpenToCategory("WatchXP")
		InterfaceOptionsFrame_OpenToCategory("WatchXP") -- The first call to OpenToCategory after login/reloadui doesn't work properly due to a blizzard bug
	
	elseif cmd == "toggle" then
		WXP.ToggleDisplay()
	
	elseif cmd == "debug" then
		WXP_Settings.debug = not WXP_Settings.debug
		WXP.Msg("Debug output "..(WXP_Settings.debug and "enabled." or "disabled."))
	
	elseif cmd == "updatewarning" or cmd == "updwarn" then
		WXP_Settings.updatewarning = not WXP_Settings.updatewarning
		WXP.Msg("Update warning "..(WXP_Settings.updatewarning and "enabled." or "disabled."))
	
	elseif cmd == "version" or cmd == "vers" or cmd == "ver" or cmd == "v" then
		WXP.Msg(format("Version: %s (%s)", WXP.version, WXP.date))
	
	elseif cmd == "refresh" or cmd == "clear" or cmd == "wipe" then
		WXPMarker.RemoveAll()
		WXP.PollParty()
	
	elseif strmatch(cmd,"ask ") then
		local askname = strmatch(cmd,"ask (.*)")
		
		if strmatch(askname," ") or strmatch(askname,"^%d+$") then -- First and last name
			WXP.PollBNFriend(askname)
		else
			WXP.PollPlayer(askname)
		end
		
	else
		WXP.Msg("|cffffc445/wxp config|r : Show the configuration panel")
		WXP.Msg("|cffffc445/wxp ask player|r : Request a marker for a player not in your group (they still need WatchXP)")
		WXP.Msg("|cffffc445/wxp ask FirstName LastName|r : Request a marker for a RealID friend (they still need WatchXP)")
		WXP.Msg("|cffffc445/wxp ask n|r : Request a marker for the |cffffc445n|rth online RealID friend in your friends list (they still need WatchXP)")
		WXP.Msg("|cffffc445/wxp toggle|r : Toggle displaying of WatchXP")
		WXP.Msg("|cffffc445/wxp refresh|r : Refreshes the display and forces an update from all party members. Also removes leftover markers or markers added with /wxp ask")
		WXP.Msg("|cffffc445/wxp debug|r : Toggle debugging output")
		WXP.Msg("|cffffc445/wxp updatewarning|r : Toggle warning when other players are using an older, incompatible version")
		WXP.Msg("|cffffc445/wxp version|r : Display addon version")
	end
end

--- Core functions ---

function WXP.Msg(msg)					-- Message output function
	DEFAULT_CHAT_FRAME:AddMessage("|cffd2b48c[WatchXP]|r "..msg)
end

function WXP.Debug(...)					-- Debug message output function
	if WXP_Settings.debug then
		local str = table.concat({...}, " ")
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[WXP]|r " .. str)
	end
end

function WXP.ToggleDisplay()			-- Toggle display of addon
	if WXP_Settings.blip.show then
		WXP.Msg("Hiding WatchXP")
		WXP_Frame:Hide()
		WXP_Settings.blip.show = false
	else
		WXP.Msg("Showing WatchXP")
		WXP_Frame:Show()
		WXP_Settings.blip.show = true
	end
end


function WXP.PollParty()				-- Send out XP req to party
	if GetNumSubgroupMembers("LE_PARTY_CATEGORY_HOME") == 0 then return end
	WXP.Debug("|cff8888ff>>> Sending XP request to party|r")
	local reqstr = string.format("party-req,%s,%s", UnitName("player"), GetRealmName("player"))
	SendAddonMessage("WXP",reqstr,"PARTY")
end

function WXP.PollPlayer(name)			-- Send out XP req to player
	WXP.Msg("Sending XP request to "..WXP.PlayerLink(name))
	local str = string.format("ask-req,%s,%s", UnitName("player"), GetRealmName("player"))
	SendAddonMessage("WXP", str, "WHISPER", name)
end

function WXP.PollBNFriend(ident)		-- Send out XP req to Battle.net friend
	if not BNConnected() then WXP.Msg("Must be connected to RealID to use that feature") return end
	
	local pid
	if strmatch(ident," ") then -- ident is first and last name
		pid = BNet_GetPresenceID(ident)
	elseif strmatch(ident,"^%d+$") then -- ident is a number
		pid = BNGetFriendInfo(ident)
	end
	
	if not pid then WXP.Msg("That is not a valid RealID friend") return end
	BNSendWhisper(pid,"wxp-bn-req - I just sent you an experience request for WatchXP. If you're seeing this message, you don't have WatchXP!")
end


function WXP.SendExpToParty()			-- Send out new XP value to party (response to WXP.PollParty)
	if GetNumSubgroupMembers("LE_PARTY_CATEGORY_HOME") == 0 then return end
	
	if UnitLevel("player") == WXP.GetMaxLevel() then -- Don't send out info if we're max level
		WXP.Debug("|cff8888ff>>> Skipping SendExpToParty, we're max level|r")
		return
	end
	
	WXP.Debug("|cff8888ff>>> Sending XP to party|r")
	local str = string.format("party-xp,%s,%s,%s,%s,%s", UnitName("player"), GetRealmName("player"), UnitLevel("player"), UnitXP("player"), UnitXPMax("player"))
	SendAddonMessage("WXP", str, "PARTY")
end

function WXP.SendExpToPlayer(name)		-- Send out new XP value to player (response to WXP.PollPlayer)
	if UnitLevel("player") == WXP.GetMaxLevel() then -- Don't send out info if we're max level
		WXP.Debug("|cffd24cff>>> Skipping SendExpToPlayer, we're max level|r")
		return
	end
	
	WXP.Debug("|cffd24cff>>> Sending XP to|r", WXP.PlayerLink(name))
	local str = string.format("ask-xp,%s,%s,%s,%s,%s", UnitName("player"), GetRealmName("player"), UnitLevel("player"), UnitXP("player"), UnitXPMax("player"))
	WXP.Debug(str)
	SendAddonMessage("WXP", str, "WHISPER", name)
end

function WXP.SendExpToBNFriend(pid)		-- Send out new XP value to Battle.net friend (response to WXP.PollBNFriend)
	if UnitLevel("player") == WXP.GetMaxLevel() then -- Don't send out info if we're max level
		return
	end
	
	local str = string.format("wxp-bn-xp,%s,%s,%s,%s,%s", UnitName("player"), GetRealmName("player"), UnitLevel("player"), UnitXP("player"), UnitXPMax("player"))
	BNSendWhisper(pid,str)
end


function WXP.GetIconXYFromID(id)		-- Return the x,y texture coordinates of a blip icon with the given id
	local x = 0
	local y = 0
	
	if     id == 0  then x = 0; y = 0
	elseif id == 1  then x = 1; y = 0
	elseif id == 2  then x = 2; y = 0
	elseif id == 3  then x = 3; y = 0
	elseif id == 4  then x = 4; y = 0
	elseif id == 5  then x = 5; y = 0
	elseif id == 6  then x = 6; y = 0
	elseif id == 7  then x = 7; y = 0
	elseif id == 8  then x = 0; y = 1
	elseif id == 9  then x = 1; y = 1
	elseif id == 10 then x = 2; y = 1
	elseif id == 11 then x = 3; y = 1
	elseif id == 12 then x = 4; y = 1
	elseif id == 13 then x = 5; y = 1
	elseif id == 14 then x = 6; y = 1
	elseif id == 15 then x = 7; y = 1
	elseif id == 16 then x = 0; y = 2
	elseif id == 17 then x = 1; y = 2
	elseif id == 18 then x = 2; y = 2
	elseif id == 19 then x = 3; y = 2
	elseif id == 20 then x = 4; y = 2
	elseif id == 21 then x = 5; y = 2
	elseif id == 22 then x = 6; y = 2
	elseif id == 23 then x = 7; y = 2
	elseif id == 24 then x = 0; y = 3
	elseif id == 25 then x = 1; y = 3
	elseif id == 26 then x = 2; y = 3
	elseif id == 27 then x = 3; y = 3
	elseif id == 28 then x = 4; y = 3
	elseif id == 29 then x = 5; y = 3
	elseif id == 30 then x = 0; y = 4
	elseif id == 31 then x = 1; y = 4
	elseif id == 32 then x = 2; y = 4
	elseif id == 33 then x = 3; y = 4
	elseif id == 34 then x = 4; y = 4
	elseif id == 35 then x = 5; y = 4
	elseif id == 36 then x = 6; y = 4
	elseif id == 37 then x = 7; y = 4
	end
	
	return x,y
end

function WXP.GetIconCoord(x,y)			-- Get coordinates of an icon at x,y position
	local l = x * .125
	local r = l + .125
	local t = y * .125
	local b = t + .125
	return l,r,t,b
end

function WXP.PlayerLink(name,realm)		-- Create a player link from a given name and realm
	if realm and realm ~= GetRealmName("player") then
		return format("|Hplayer:%s:123|h|cffffbf00[%s]|r|h", name.."-"..realm, name.."-"..realm)
	else
		return format("|Hplayer:%s:123|h|cffffbf00[%s]|r|h", name, name)
	end
end

function WXP.GetMaxLevel()
	return MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
end

function WXP.BNMessageFilter(self,event,msg) -- Filter function to hide WXP RealID messages
	if msg:find("wxp-bn-xp,") or msg:find("wxp-bn-req,") then
		return true
	end
end

function WXP.InsertDefaultSettings(tbl, def) -- Copies missing settings into WXP_Settings
	local newtable = tbl
	for k,v in pairs(def) do
		if type(v) == "table" then
			newtable[k] = WXP.InsertDefaultSettings(newtable[k] or {}, v)
		else
			if newtable[k] == nil then
				newtable[k] = v
			end
		end
	end
	
	return newtable
end

function WXP.ImportOlderSettings()		-- Upgrades older versions of settings
	if not WXP_Settings.version then -- pre 3.0
		
		if WXP_Settings.Show then
			WXP_Settings.blip.show = (WXP_Settings.Show == 1 and true or false)
			WXP_Settings.Show = nil
		end
		
		if WXP_Settings.ShowLabels then
			WXP_Settings.label.show = (WXP_Settings.ShowLabels == 1 and true or false)
			WXP_Settings.ShowLabels = nil
		end
		
		if WXP_Settings.offsetY then
			WXP_Settings.blip.offset.y = WXP_Settings.offsetY
			WXP_Settings.offsetY = nil
		end
	
		if WXP_Settings.LabelOffsetY then
			WXP_Settings.label.offset.y = WXP_Settings.LabelOffsetY
			WXP_Settings.LabelOffsetY = nil
		end
		
		if WXP_Settings.Blip then
			WXP_Settings.blip.id = WXP_Settings.Blip
			WXP_Settings.Blip = nil
		end
		
		if WXP_Settings.BlipSize then
			WXP_Settings.blip.size = WXP_Settings.BlipSize
			WXP_Settings.BlipSize = nil
		end
		
		if WXP_Settings.ShowLevel then
			if WXP_Settings.ShowLevel == 0 then
				WXP_Settings.label.showlevel = "never"
			elseif WXP_Settings.ShowLevel == 1 then
				WXP_Settings.label.showlevel = "always"
			elseif WXP_Settings.ShowLevel == 2 then
				WXP_Settings.label.showlevel = "different"
			end
			
			WXP_Settings.ShowLevel = nil
		end
		
		if WXP_Settings.Font then
			WXP_Settings.label.font.size = WXP_Settings.Font.Size
			
			if WXP_Settings.Font.Face == 1 then
				WXP_Settings.label.font.face = "friz"
			elseif WXP_Settings.Font.Face == 1 then
				WXP_Settings.label.font.face = "arial"
			elseif WXP_Settings.Font.Face == 1 then
				WXP_Settings.label.font.face = "morpheus"
			elseif WXP_Settings.Font.Face == 1 then
				WXP_Settings.label.font.face = "skurri"
			end
			
			WXP_Settings.Font = nil
		end
		
		if WXP_Settings.Colors then
			WXP_Settings.label.color.r = WXP_Settings.Colors.R
			WXP_Settings.label.color.g = WXP_Settings.Colors.G
			WXP_Settings.label.color.b = WXP_Settings.Colors.B
			WXP_Settings.label.color.a = WXP_Settings.Colors.A
			WXP_Settings.Colors = nil
		end
		
	end
end

--- UI events ---

function WXP.InitializeWidgets()		-- Initialize options panel widgets
	WXP.Debug("Initializing widgets")
	
	WXP.UpdateBlipSelector(WXP_Settings.blip.id)
	WXP_OptBut_Show:SetChecked(WXP_Settings.blip.show)
	WXP_OptBut_ShowLabels:SetChecked(WXP_Settings.label.show)
	
	WXP_OptBut_FontSize:SetValue(WXP_Settings.label.font.size)
	WXP_OptBut_FontSize.tooltipText = "Change the size of the label text"
	WXP_OptBut_FontSizeLow:SetText("4")
	WXP_OptBut_FontSizeHigh:SetText("36")
	WXP_OptBut_FontSizeText:SetText(WXP_OptBut_FontSize:GetValue())
	
	WXP_OptBut_OffsetY:SetValue(WXP_Settings.blip.offset.y)
	WXP_OptBut_OffsetY.tooltipText = "Change the vertical offset of the blips"
	WXP_OptBut_OffsetYLow:SetText("-100")
	WXP_OptBut_OffsetYHigh:SetText("100")
	WXP_OptBut_OffsetYText:SetText(WXP_OptBut_OffsetY:GetValue())
	
	WXP_OptBut_LabelOffsetY:SetValue(WXP_Settings.label.offset.y)
	WXP_OptBut_LabelOffsetY.tooltipText = "Change the vertical offset of the labels"
	WXP_OptBut_LabelOffsetYLow:SetText("-100")
	WXP_OptBut_LabelOffsetYHigh:SetText("100")
	WXP_OptBut_LabelOffsetYText:SetText(WXP_OptBut_LabelOffsetY:GetValue())
	
	WXP_OptBut_BlipSize:SetValue(WXP_Settings.blip.size)
	WXP_OptBut_BlipSize.tooltipText = "Size of the blips"
	WXP_OptBut_BlipSizeLow:SetText("8")
	WXP_OptBut_BlipSizeHigh:SetText("64")
	WXP_OptBut_BlipSizeText:SetText(WXP_OptBut_BlipSize:GetValue())
	
	WXP_OptBut_Font1:SetChecked(WXP_Settings.label.font.face == "friz")
	WXP_OptBut_Font2:SetChecked(WXP_Settings.label.font.face == "arial")
	WXP_OptBut_Font3:SetChecked(WXP_Settings.label.font.face == "morpheus")
	WXP_OptBut_Font4:SetChecked(WXP_Settings.label.font.face == "skurri")
	
	WXP_OptBut_ShowLevel1:SetChecked(WXP_Settings.label.showlevel == "never")
	WXP_OptBut_ShowLevel2:SetChecked(WXP_Settings.label.showlevel == "different")
	WXP_OptBut_ShowLevel3:SetChecked(WXP_Settings.label.showlevel == "always")
	
	WXP_OptBut_ShowRealm1:SetChecked(WXP_Settings.label.showrealm == "never")
	WXP_OptBut_ShowRealm2:SetChecked(WXP_Settings.label.showrealm == "different")
	WXP_OptBut_ShowRealm3:SetChecked(WXP_Settings.label.showrealm == "always")
end

function WXP.OnBlipMouseEnter()			-- Fired when mouse enters a blip
	local id = GetMouseFocus():GetID()
	local marker = WXPMarker.instances[id]
	
	local name  = marker.player.name  or "Unknown"
	local realm = marker.player.realm or "Unknown"
	local xp    = marker.player.xp    or 0
	local xpmax = marker.player.xpmax or 0
	local level = marker.player.level or 0
	
	local pct = math.floor((xp/xpmax)*100)
	
	GameTooltip:SetOwner(WXP_Frame,"ANCHOR_CURSOR")
	GameTooltip:SetText(name .. "-" .. realm)
	GameTooltip:AddLine("Level "..level)
	GameTooltip:AddLine("XP: "..WXP.format_thousand(xp).." / "..WXP.format_thousand(xpmax).." ("..pct.."%)")
	GameTooltip:Show()
	
	--[[
	for i,mrk in ipairs(WXPMarker.instances) do
		mrk.blip.fontstring:Hide()
	end
	
	marker.blip.fontstring:Show()
	]]
end

function WXP.OnBlipMouseLeave()			-- Fired when mouse leaves a blip
	GameTooltip:Hide()
	
	--[[
	if WXP_Settings.label.show then
		for i,marker in ipairs(WXPMarker.instances) do
			marker.blip.fontstring:Show()
		end
	end
	]]
end

function WXP.OnOptionsLoaded(self)		-- Initialize Options panel
	if self:GetName() == "WXP_Options" then
		self.name = "WatchXP"
		self.default = WXP.OnDefaultsClicked
		InterfaceOptions_AddCategory(self)
	else
		self.name = "Labels"
		self.parent = "WatchXP"
		self.default = WXP.OnDefaultsClicked
		InterfaceOptions_AddCategory(self)
	end
end

function WXP.OnOptionsShown()			-- Fired when options panel opens
	if not WXP_Settings then return end
	WXPMarker.new({name="Example!", realm="RealmName", level=1, xp=1, xpmax=4})
end

function WXP.OnOptionsHidden()			-- Fired when options panel closes
	if not WXP_Settings then return end
	
	local marker = WXPMarker.Find("Example!", "RealmName")
	if marker then
		marker:Remove()
	end
end

function WXP.OnWidgetUsed(self)			-- Fired when an options panel widget (button, slider, etc.) is used
	if not WXP_Settings then return end
	
	if self:GetObjectType() ~= "Slider" then
		PlaySound("igMainMenuOptionCheckBoxOn")
	end
	
	if self:GetName() == "WXP_OptBut_Show" then
		if WXP_OptBut_Show:GetChecked() then
			WXP_Settings.blip.show = true
			WXP_Frame:Show()
		else
			WXP_Settings.blip.show = false
			WXP_Frame:Hide()
		end
	
	elseif self:GetName() == "WXP_OptBut_ShowLabels" then
		if WXP_OptBut_ShowLabels:GetChecked() then
			WXP_Settings.label.show = true
		else
			WXP_Settings.label.show = false
		end
	
	elseif self:GetName() == "WXP_OptBut_ShowLevel1" then	-- Never show level
		WXP_Settings.label.showlevel = "never"
		WXP_OptBut_ShowLevel1:SetChecked(1)
		WXP_OptBut_ShowLevel2:SetChecked(nil)
		WXP_OptBut_ShowLevel3:SetChecked(nil)
	
	elseif self:GetName() == "WXP_OptBut_ShowLevel2" then	-- Show level if different
		WXP_Settings.label.showlevel = "different"
		WXP_OptBut_ShowLevel1:SetChecked(nil)
		WXP_OptBut_ShowLevel2:SetChecked(1)
		WXP_OptBut_ShowLevel3:SetChecked(nil)
	
	elseif self:GetName() == "WXP_OptBut_ShowLevel3" then	-- Always
		WXP_Settings.label.showlevel = "always"
		WXP_OptBut_ShowLevel1:SetChecked(nil)
		WXP_OptBut_ShowLevel2:SetChecked(nil)
		WXP_OptBut_ShowLevel3:SetChecked(1)
	
	--- ShowRealm ---
	
	elseif self:GetName() == "WXP_OptBut_ShowRealm1" then	-- Never show realm
		WXP_Settings.label.showrealm = "never"
		WXP_OptBut_ShowRealm1:SetChecked(1)
		WXP_OptBut_ShowRealm2:SetChecked(nil)
		WXP_OptBut_ShowRealm3:SetChecked(nil)
	
	elseif self:GetName() == "WXP_OptBut_ShowRealm2" then	-- Show realm if different
		WXP_Settings.label.showrealm = "different"
		WXP_OptBut_ShowRealm1:SetChecked(nil)
		WXP_OptBut_ShowRealm2:SetChecked(1)
		WXP_OptBut_ShowRealm3:SetChecked(nil)
	
	elseif self:GetName() == "WXP_OptBut_ShowRealm3" then	-- Always show realm
		WXP_Settings.label.showrealm = "always"
		WXP_OptBut_ShowRealm1:SetChecked(nil)
		WXP_OptBut_ShowRealm2:SetChecked(nil)
		WXP_OptBut_ShowRealm3:SetChecked(1)
		
	--- End ShowRealm ---
	
	elseif self:GetName() == "WXP_OptBut_Font1" then		-- Friz Quadrata
		WXP_Settings.label.font.face = "friz"
		WXP_OptBut_Font1:SetChecked(1)
		WXP_OptBut_Font2:SetChecked(nil)
		WXP_OptBut_Font3:SetChecked(nil)
		WXP_OptBut_Font4:SetChecked(nil)
	
	elseif self:GetName() == "WXP_OptBut_Font2" then		-- Arial
		WXP_Settings.label.font.face = "arial"
		WXP_OptBut_Font1:SetChecked(nil)
		WXP_OptBut_Font2:SetChecked(1)
		WXP_OptBut_Font3:SetChecked(nil)
		WXP_OptBut_Font4:SetChecked(nil)
	
	elseif self:GetName() == "WXP_OptBut_Font3" then		-- Morpheus
		WXP_Settings.label.font.face = "morpheus"
		WXP_OptBut_Font1:SetChecked(nil)
		WXP_OptBut_Font2:SetChecked(nil)
		WXP_OptBut_Font3:SetChecked(1)
		WXP_OptBut_Font4:SetChecked(nil)
	
	elseif self:GetName() == "WXP_OptBut_Font4" then		-- Skurri
		WXP_Settings.label.font.face = "skurri"
		WXP_OptBut_Font1:SetChecked(nil)
		WXP_OptBut_Font2:SetChecked(nil)
		WXP_OptBut_Font3:SetChecked(nil)
		WXP_OptBut_Font4:SetChecked(1)
		
	elseif self:GetName() == "WXP_OptBut_OffsetY" then
		WXP_Settings.blip.offset.y = self:GetValue()
	
	elseif self:GetName() == "WXP_OptBut_BlipSize" then
		WXP_Settings.blip.size = self:GetValue()
	
	elseif self:GetName() == "WXP_OptBut_LabelOffsetY" then
		WXP_Settings.label.offset.y = self:GetValue()
		
	elseif self:GetName() == "WXP_OptBut_FontSize" then
		WXP_Settings.label.font.size = self:GetValue()
	
	end
	
	WXPMarker.RedrawAll()
end

function WXP.OnBlipSelected(self,id)	-- Fired when a blip button is clicked
	WXP_Settings.blip.id = id
	WXP.UpdateBlipSelector(id)
	WXPMarker.RedrawAll()
end

function WXP.OnColorPickerChanged()		-- Fired when color picker is changed
	WXP_Settings.label.color.r, WXP_Settings.label.color.g, WXP_Settings.label.color.b = ColorPickerFrame:GetColorRGB()
	WXP_Settings.label.color.a = 1 - OpacitySliderFrame:GetValue()
	WXPMarker.RedrawAll()
end

function WXP.OnColorPickerCanceled(prevValues) -- Fired when the color picker is closed with "Cancel"
	WXP_Settings.label.color = prevValues
	WXPMarker.RedrawAll()
end

function WXP.OnSliderScroll(slider, delta) -- Fired when a slider is scrolled with the mouse wheel
	slider:SetValue(slider:GetValue() + delta)
end

function WXP.OnDefaultsClicked()		-- Reset all settings to default when "Defaults" button is clicked
	WXP.Debug("Defaults button clicked")
	
	local debug_enabled = WXP_Settings.debug
	WXP_Settings = WXP.deepcopy(WXP.default_settings)
	if debug_enabled then WXP_Settings.debug = true end
	WXP_Settings.version = WXP.version
	WXP.InitializeWidgets()
	WXPMarker.RedrawAll()
end

--- UI functions ---

function WXP.ShowColorPicker()			-- Show the color picker
	local r = WXP_Settings.label.color.r
	local g = WXP_Settings.label.color.g
	local b = WXP_Settings.label.color.b
	local a = WXP_Settings.label.color.a
	ColorPickerFrame.hasOpacity = true;
	ColorPickerFrame.opacity = 1 - a;
	ColorPickerFrame:SetColorRGB(r,g,b);
	ColorPickerFrame.previousValues = {r=r, g=g, b=b, a=a}
	ColorPickerFrame.func = WXP.OnColorPickerChanged
	ColorPickerFrame.opacityFunc = WXP.OnColorPickerChanged
	ColorPickerFrame.cancelFunc = WXP.OnColorPickerCanceled
	
	ColorPickerFrame:Show();
end

function WXP.UpdateBlipSelector(id)		-- Initialize blip buttons (hide all, show given id)
	local disabled_alpha = "0.6"
	WXP_OptBut_Icon0:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon1:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon2:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon3:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon4:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon5:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon6:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon7:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon8:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon9:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon10:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon11:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon12:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon13:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon14:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon15:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon16:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon17:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon18:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon19:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon20:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon21:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon22:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon23:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon24:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon25:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon26:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon27:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon28:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon29:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon30:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon31:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon32:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon33:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon34:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon35:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon36:SetAlpha(disabled_alpha)
	WXP_OptBut_Icon37:SetAlpha(disabled_alpha)
	_G["WXP_OptBut_Icon"..id]:SetAlpha("0")
end

--- Miscellaneous functions ---

function WXP.format_thousand(v)			-- Adds thousands-separator (,) to a number
	local s = string.format("%d", math.floor(v))
	local pos = string.len(s) % 3
	if pos == 0 then pos = 3 end
	return string.sub(s, 1, pos)
		.. string.gsub(string.sub(s, pos+1), "(...)", ",%1")
		.. string.sub(string.format("%.0f", v - math.floor(v)), 2)
end

function WXP.deepcopy(orig)				-- Clones a table
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[WXP.deepcopy(orig_key)] = WXP.deepcopy(orig_value)
        end
        setmetatable(copy, WXP.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function WXP.print_r (t, indent, done)	-- Prints a table and all its values
  done = done or {}
  indent = indent or ''
  local nextIndent -- Storage for next indentation value
  for key, value in pairs (t) do
    if type (value) == "table" and not done [value] then
      nextIndent = nextIndent or
          (indent .. string.rep(' ',string.len(tostring (key))+2))
          -- Shortcut conditional allocation
      done [value] = true
      print (indent .. "[" .. tostring (key) .. "] => Table {");
      print  (nextIndent .. "{");
      WXP.print_r (value, nextIndent .. string.rep(' ',2), done)
      print  (nextIndent .. "}");
    else
      print  (indent .. "[" .. tostring (key) .. "] => " .. tostring (value).."")
    end
  end
end

function WXP.add(pct, name)				-- Debug function to add or update a marker
	pct = pct or 25
	name = name or "Marker"
	local marker = WXPMarker.new({name=name, realm="Test", xp=pct, xpmax=100, level=10})
end

function WXP.pop()						-- Debug function to add a bunch of markers
	WXP.add(25, "1")
	WXP.add(40, "2")
	WXP.add(35, "3")
	WXP.add(30, "4")
end
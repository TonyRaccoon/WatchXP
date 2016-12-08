WXP = {}
WXP.version = GetAddOnMetadata("WatchXP","Version")
WXP.date = GetAddOnMetadata("WatchXP","X-Date")

local ADDON_NAME, namespace = ...
local L = namespace.L

WXP.default_settings = {
	debug = false,
	updatewarning = true,
	
	blip = {
		show = true,
		animate = true,
		size = 20,
		texture = "INTERFACE\\BUTTONS\\JumpUpArrow.blp",
		
		texoffset = {
			x1 = 0,
			x2 = 1,
			y1 = 1,
			y2 = 0
		},
		
		offset = {
			y = 15
		}
	},
	
	label = {
		show = true,
		showlevel = "different",
		showrealm = "different",
		
		offset = {
			y = 5
		},
		
		color = {
			r = 1,
			g = 0.8824,
			b = 0,
			a = 1
		},
		
		font = {
			face = "Fonts\\ARIALN.TTF",
			size = 12
		}
	}
}

--- Events ---

function WXP.OnLoad(self)						-- Fired when addon is loaded
	SlashCmdList["WXP"] = WXP.OnCommand;
	SLASH_WXP1 = "/watchxp";
	SLASH_WXP2 = "/wxp";
	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("CHAT_MSG_ADDON")
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PARTY_MEMBER_DISABLE")
	self:RegisterEvent("PARTY_MEMBER_ENABLE")
	self:RegisterEvent("BN_CHAT_MSG_ADDON")
	RegisterAddonMessagePrefix("WXP")
	
	if UnitLevel("player") == WXP.GetMaxLevel() or IsXPUserDisabled() then
		WXP_Frame:SetParent("ReputationWatchBar")
		WXP_Frame:SetAllPoints()
	end
end

function WXP.OnEvent(self, event, ...)			-- Fired when a registered event is triggered
	if     event == "PLAYER_XP_UPDATE" then
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
		WXP.LoadBlipButtons()
		if not WXP_Settings.blip.show then WXP_Frame:Hide() end
		
		-- Blizzard bug: options panel's OnShow doesn't trigger unless we hide it first (even though it starts out hidden)
		WXP_Options:Hide()
		WXP_Options_Label:Hide()
		
		-- Finally, poll the party to get experience from party members
		WXP.PollParty()
	
	elseif event == "CHAT_MSG_ADDON" then
		local addonName, args, channel, sender = ...;
		WXP.Debug("|cffcccccc[AddonMessage]|r|cffaaaaaa", addonName, args, channel, sender)
		if sender == UnitName("player").."-"..GetRealmName("player"):gsub("[%s%-]", "") then return end -- Ignore messages from ourselves (gsub is to remove hyphens and spaces from GetRealmName; sender does not include those (MoonGuard, AzjolNerub)
		local msgArgs = {strsplit(",", args)}
		
		if msgArgs[1] == "party-xp" or msgArgs[1] == "ask-xp" then
			local remotever = msgArgs[2]
			local name      = msgArgs[3]
			local realm     = msgArgs[4]
			local level     = tonumber(msgArgs[5])
			local xp        = tonumber(msgArgs[6])
			local xpmax     = tonumber(msgArgs[7])
			WXP.Debug(format("|cff8888ff<<< Got %s XP: %s %s / %s through %s", (msgArgs[1] == "party-xp" and "party" or "player"), WXP.PlayerLink(name,realm), WXP.format_thousand(xp), WXP.format_thousand(xpmax), level))
			WXPMarker.new({name=name, realm=realm, level=level, xp=xp, xpmax=xpmax})
		elseif msgArgs[1] == "party-req" then
			WXP.Debug("|cff4444ff<<< Got party XP request from:|r", args)
			WXP.SendExpToParty()
		elseif msgArgs[1] == "ask-req" then
			local remotever = msgArgs[2]
			local name      = msgArgs[3]
			local realm     = msgArgs[4]
			WXP.SendExpToPlayer(name.."-"..realm)
		elseif msgArgs[1] == "NEWXP" and WXP_Settings.updatewarning then -- Show a deprecation warning
			local name = msgArgs[4]
			WXP.Msg(format(L["%s is using an outdated version of WatchXP! Tell them to update it or it won't work with you. Type |cffff7f00/wxp updatewarning|r to disable these messages."], name))
		end
	
	elseif event == "BN_CHAT_MSG_ADDON" then
		local addonName, args, channel, toonid = ...
		local pid = WXP.PresenceIDFromToonID(toonid)
		WXP.Debug("|cffcccccc[BNAddonMessage]|r|cffaaaaaa", addonName, args, channel, toonid)
		local msgArgs = {strsplit(",", args)}
		
		if msgArgs[1] == "bn-xp" then
			local remotever = msgArgs[2]
			local name      = msgArgs[3]
			local realm     = msgArgs[4]
			local level     = tonumber(msgArgs[5])
			local xp        = tonumber(msgArgs[6])
			local xpmax     = tonumber(msgArgs[7])
			WXP.Debug(format("|cff00D9D9<<< Got BN XP: %s %s / %s through %s", WXP.PlayerLink(name,realm), WXP.format_thousand(xp), WXP.format_thousand(xpmax), level))
			local _,bnname = BNGetFriendInfoByID(pid)
			WXP.Msg(format("Got XP response from %s (%s). This blip will not automatically update. To remove the blip, type /wxp clear.", bnname, WXP.PlayerLink(name,realm)))
			WXPMarker.new({name=name, realm=realm, level=level, xp=xp, xpmax=xpmax})
		elseif msgArgs[1] == "bn-req" then
			WXP.Debug("|cff00D9D9<<< Got BN XP request from:|r "..args)
			WXP.SendExpToBNFriend(toonid)
		end
	
	
	elseif event == "GROUP_ROSTER_UPDATE" then -- or event == "RAID_ROSTER_UPDATE
		WXP.Debug("|cff8888ffParty altered!|r")
		WXPMarker.RemoveAll()
		
		if GetNumSubgroupMembers() > 0 then -- If we're in a group, request everything again
			WXP.PollParty()
		end
	
	end
end

function WXP.OnCommand(cmd)						-- Fired when the player enters a command starting with /wxp
	cmd = cmd:lower()
	if cmd == "config" or cmd == "options" or cmd == "settings" or cmd == "opt" or cmd == "cfg" or cmd == "win" then
		InterfaceOptionsFrame_OpenToCategory("WatchXP")
		InterfaceOptionsFrame_OpenToCategory("WatchXP") -- The first call to OpenToCategory after login/reloadui doesn't work properly due to a blizzard bug
	
	elseif cmd == "label" or cmd == "labels" then
		InterfaceOptionsFrame_OpenToCategory(WXP_Options_Label)
		InterfaceOptionsFrame_OpenToCategory(WXP_Options_Label) -- The first call to OpenToCategory after login/reloadui doesn't work properly due to a blizzard bug
	
	elseif cmd == "toggle" then
		WXP.ToggleDisplay()
	
	elseif cmd == "debug" then
		WXP_Settings.debug = not WXP_Settings.debug
		WXP.Msg(format(L["Debug output %s"], WXP_Settings.debug and L["enabled"] or L["disabled"]))
	
	elseif cmd == "updatewarning" or cmd == "updwarn" then
		WXP_Settings.updatewarning = not WXP_Settings.updatewarning
		WXP.Msg(format(L["Update warning %s"], WXP_Settings.updatewarning and L["enabled"] or L["disabled"]))
	
	elseif cmd == "version" or cmd == "vers" or cmd == "ver" or cmd == "v" then
		WXP.Msg(format(L["Version: %s (%s)"], WXP.version, WXP.date))
	
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
		WXP.Msg("|cffffc445/wxp config|r : "				.. L["Show the options panel"])
		WXP.Msg("|cffffc445/wxp ask player|r : "			.. L["Request a marker for a player not in your group (they still need WatchXP)"])
		WXP.Msg("|cffffc445/wxp ask FirstName LastName|r : ".. L["Request a marker for a Battle.net friend (they still need WatchXP)"])
		WXP.Msg("|cffffc445/wxp ask n|r : "					.. L["Request a marker for the nth online Battle.net friend in your friends list (they still need WatchXP)"])
		WXP.Msg("|cffffc445/wxp toggle|r : "				.. L["Toggle visibility of WatchXP"])
		WXP.Msg("|cffffc445/wxp refresh|r : "				.. L["Refreshes the display and forces an update from all party members. Also removes leftover markers or markers added with /wxp ask"])
		WXP.Msg("|cffffc445/wxp debug|r : "					.. L["Toggle debug output"])
		WXP.Msg("|cffffc445/wxp updatewarning|r : "			.. L["Toggle warning when other players are using an older, incompatible version"])
		WXP.Msg("|cffffc445/wxp version|r : "				.. L["Display addon version"])
	end
end

--- Core functions ---

function WXP.Msg(msg)							-- Message output function
	DEFAULT_CHAT_FRAME:AddMessage("|cffd2b48c[WatchXP]|r "..msg)
end

function WXP.Debug(...)							-- Debug message output function
	if WXP_Settings.debug then
		local str = table.concat({...}, " ")
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[WXP]|r " .. str)
	end
end

function WXP.ToggleDisplay()					-- Toggle display of addon
	if WXP_Settings.blip.show then
		WXP.Msg(L["Hiding WatchXP"])
		WXP_Frame:Hide()
		WXP_Settings.blip.show = false
	else
		WXP.Msg(L["Showing WatchXP"])
		WXP_Frame:Show()
		WXP_Settings.blip.show = true
	end
end


function WXP.PollParty()						-- Send out XP req to party
	if GetNumSubgroupMembers("LE_PARTY_CATEGORY_HOME") == 0 then return end
	WXP.Debug("|cff8888ff>>> Sending XP request to party|r")
	local reqstr = string.format("party-req,%s,%s,%s", WXP.version, UnitName("player"), GetRealmName("player"))
	SendAddonMessage("WXP",reqstr,"PARTY")
end

function WXP.PollPlayer(name)					-- Send out XP req to player
	WXP.Msg(format(L["Sending XP request to %s"], WXP.PlayerLink(name)))
	local str = string.format("ask-req,%s,%s,%s", WXP.version, UnitName("player"), GetRealmName("player"))
	SendAddonMessage("WXP", str, "WHISPER", name)
end

function WXP.PollBNFriend(ident)				-- Send out XP req to Battle.net friend
	if not BNConnected() or not BNFeaturesEnabled() then
		WXP.Msg(L["You must be connected to Battle.net to do that"])
		return
	end
	
	local pid
	
	if strmatch(ident,"^%d+$") then -- ident is a number, assume it's friend #x in the BN list
		pid = BNGetFriendInfo(ident)
	else
		pid = GetAutoCompletePresenceID(ident)
	end
	
	local _,name = BNGetFriendInfoByID(pid)
	
	if not pid then WXP.Msg("That is not a valid RealID friend") return end
	WXP.Msg(format(L["Sending XP request to %s"], name))
	BNSendGameData(pid, "WXP", "bn-req,"..WXP.version)
end


function WXP.SendExpToParty()					-- Send out new XP value to party (response to WXP.PollParty)
	if GetNumSubgroupMembers("LE_PARTY_CATEGORY_HOME") == 0 then return end
	
	if UnitLevel("player") == WXP.GetMaxLevel() then -- Don't send out info if we're max level
		WXP.Debug("|cff8888ff>>> Skipping SendExpToParty, we're max level|r")
		return
	end
	
	WXP.Debug("|cff8888ff>>> Sending XP to party|r")
	local str = string.format("party-xp,%s,%s,%s,%s,%s,%s", WXP.version, UnitName("player"), GetRealmName("player"), UnitLevel("player"), UnitXP("player"), UnitXPMax("player"))
	SendAddonMessage("WXP", str, "PARTY")
end

function WXP.SendExpToPlayer(name)				-- Send out new XP value to player (response to WXP.PollPlayer)
	if UnitLevel("player") == WXP.GetMaxLevel() then -- Don't send out info if we're max level
		WXP.Debug("|cffd24cff>>> Skipping SendExpToPlayer, we're max level|r")
		return
	end
	
	WXP.Debug("|cffd24cff>>> Sending XP to|r", WXP.PlayerLink(name))
	local str = string.format("ask-xp,%s,%s,%s,%s,%s,%s", WXP.version, UnitName("player"), GetRealmName("player"), UnitLevel("player"), UnitXP("player"), UnitXPMax("player"))
	WXP.Debug(str)
	SendAddonMessage("WXP", str, "WHISPER", name)
end

function WXP.SendExpToBNFriend(pid)				-- Send out new XP value to Battle.net friend (response to WXP.PollBNFriend)
	if UnitLevel("player") == WXP.GetMaxLevel() then -- Don't send out info if we're max level
		return
	end
	
	local str = string.format("bn-xp,%s,%s,%s,%s,%s,%s", WXP.version, UnitName("player"), GetRealmName("player"), UnitLevel("player"), UnitXP("player"), UnitXPMax("player"))
	BNSendGameData(pid, "WXP", str)
end


function WXP.PlayerLink(name,realm)				-- Create a player link from a given name and realm
	if realm and realm ~= GetRealmName("player") then
		return format("|Hplayer:%s:123|h|cffffbf00[%s]|r|h", name.."-"..realm, name.."-"..realm)
	else
		return format("|Hplayer:%s:123|h|cffffbf00[%s]|r|h", name, name)
	end
end

function WXP.GetMaxLevel()
	return MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]
end

function WXP.InsertDefaultSettings(tbl, def) 	-- Copies missing settings into WXP_Settings
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

function WXP.ImportOlderSettings()				-- Upgrades older versions of settings
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
			local id = WXP_Settings.Blip
			local x1, x2, y1, y2, texture = 0, 1, 0, 1
			
			if     id == 0
				or id == 1
				or id == 15 then texture,x1,x2,y1,y2 = "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP", .875, 1, 0, .25 -- Blue dot
			
			elseif id == 2
				or id == 5  then texture,x1,x2,y1,y2 = "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",.625,.75, 0,.25  -- Red dot
			
			elseif id == 3
				or id == 6
				or id == 8  then texture,x1,x2,y1,y2 = "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",.375,.5,  0,.25  -- Yellow dot
			
			elseif id == 4
				or id == 7  then texture,x1,x2,y1,y2 = "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",.25, .375,0,.25  -- Green dot
			
			elseif id == 9
				or id == 10
				or id == 11
				or id == 12
				or id == 13
				or id == 28  then texture,x1,x2,y1,y2 = "INTERFACE\\MINIMAP\\OBJECTICONS.BLP",.125,.25,.125,.25 -- Gold exclamation mark
			
			elseif id == 30  then texture,x1,x2,y1,y2 = "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",0,  .25,0,  .25 -- Raid star
			elseif id == 31  then texture,x1,x2,y1,y2 = "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",.25,.5, 0,  .25 -- Raid circle
			elseif id == 32  then texture,x1,x2,y1,y2 = "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",.5, .75,0,  .25 -- Raid diamond
			elseif id == 33  then texture,x1,x2,y1,y2 = "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",.75,1,  0,  .25 -- Raid triangle
			elseif id == 34  then texture,x1,x2,y1,y2 = "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",0,  .25,.25,.5  -- Raid moon
			elseif id == 35  then texture,x1,x2,y1,y2 = "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",.25,.5, .25,.5  -- Raid square
			elseif id == 36  then texture,x1,x2,y1,y2 = "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",.5, .75,.25,.5  -- Raid cross
			
			elseif id == 29
				or id == 37 then texture,x1,x2,y1,y2 = "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",.75,1,  .25,.5  -- Raid skull
			
			end
			
			WXP_Settings.blip.texture = texture
			WXP_Settings.blip.texoffset = {x1=x1, x2=x2, y1=y1, y2=y2}
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
				WXP_Settings.label.font.face = "Fonts\\FRIZQT__.TTF"
			elseif WXP_Settings.Font.Face == 1 then
				WXP_Settings.label.font.face = "Fonts\\ARIALN.TTF"
			elseif WXP_Settings.Font.Face == 1 then
				WXP_Settings.label.font.face = "Fonts\\MORPHEUS.TTF"
			elseif WXP_Settings.Font.Face == 1 then
				WXP_Settings.label.font.face = "Fonts\\SKURRI.TTF"
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

function WXP.PresenceIDFromToonID(toonid)		-- Get a Battle.net Presence ID from a given Toon ID
	local friends,friendsonline = BNGetNumFriends()
	
	for i=1,friends do
		local pid,_,_,_,_,tid = BNGetFriendInfo(i)
		if tid == toonid then
			return pid
		end
	end
	
	return false
end

--- UI functions ---

function WXP.InitializeWidgets()				-- Initialize options panel widgets
	WXP.Debug("Initializing widgets")
	
	WXP_OptBut_Show:SetChecked(WXP_Settings.blip.show)
	WXP_OptBut_Animate:SetChecked(WXP_Settings.blip.animate)
	WXP_OptBut_ShowLabels:SetChecked(WXP_Settings.label.show)
	
	WXP_OptBut_FontSize:SetValue(WXP_Settings.label.font.size)
	WXP_OptBut_FontSize.tooltipText = L["Label font size"]
	WXP_OptBut_FontSizeLow:SetText("4")
	WXP_OptBut_FontSizeHigh:SetText("36")
	WXP_OptBut_FontSizeText:SetText(WXP_OptBut_FontSize:GetValue())
	
	WXP_OptBut_OffsetY:SetValue(WXP_Settings.blip.offset.y)
	WXP_OptBut_OffsetY.tooltipText = L["Blip vertical offset"]
	WXP_OptBut_OffsetYLow:SetText("-100")
	WXP_OptBut_OffsetYHigh:SetText("100")
	WXP_OptBut_OffsetYText:SetText(WXP_OptBut_OffsetY:GetValue())
	
	WXP_OptBut_LabelOffsetY:SetValue(WXP_Settings.label.offset.y)
	WXP_OptBut_LabelOffsetY.tooltipText = L["Label vertical offset"]
	WXP_OptBut_LabelOffsetYLow:SetText("-100")
	WXP_OptBut_LabelOffsetYHigh:SetText("100")
	WXP_OptBut_LabelOffsetYText:SetText(WXP_OptBut_LabelOffsetY:GetValue())
	
	WXP_OptBut_BlipSize:SetValue(WXP_Settings.blip.size)
	WXP_OptBut_BlipSize.tooltipText = L["Blip size"]
	WXP_OptBut_BlipSizeLow:SetText("8")
	WXP_OptBut_BlipSizeHigh:SetText("64")
	WXP_OptBut_BlipSizeText:SetText(WXP_OptBut_BlipSize:GetValue())
	
	WXP_OptBut_Color:SetColorTexture(WXP_Settings.label.color.r, WXP_Settings.label.color.g, WXP_Settings.label.color.b)
	
	WXP_OptBut_Font1:SetChecked(WXP_Settings.label.font.face == "Fonts\\FRIZQT__.TTF")
	WXP_OptBut_Font2:SetChecked(WXP_Settings.label.font.face == "Fonts\\ARIALN.TTF")
	WXP_OptBut_Font3:SetChecked(WXP_Settings.label.font.face == "Fonts\\MORPHEUS.TTF")
	WXP_OptBut_Font4:SetChecked(WXP_Settings.label.font.face == "Fonts\\SKURRI.TTF")
	
	WXP_OptBut_ShowLevel1:SetChecked(WXP_Settings.label.showlevel == "never")
	WXP_OptBut_ShowLevel2:SetChecked(WXP_Settings.label.showlevel == "different")
	WXP_OptBut_ShowLevel3:SetChecked(WXP_Settings.label.showlevel == "always")
	
	WXP_OptBut_ShowRealm1:SetChecked(WXP_Settings.label.showrealm == "never")
	WXP_OptBut_ShowRealm2:SetChecked(WXP_Settings.label.showrealm == "different")
	WXP_OptBut_ShowRealm3:SetChecked(WXP_Settings.label.showrealm == "always")
end

function WXP.LocalizeXML(frame)						-- Set XML strings to localized versions
	if frame == "WatchXP" then
		WXP_Opt_Subtitle:SetText(			L[WXP_Opt_Subtitle:GetText()])
		WXP_Opt_BlipSize:SetText(			L[WXP_Opt_BlipSize:GetText()])
		WXP_Opt_Offset:SetText(				L[WXP_Opt_Offset:GetText()])
		WXP_Opt_BlipTexture:SetText(		L[WXP_Opt_BlipTexture:GetText()])
		WXP_OptBut_ShowText:SetText(		L[WXP_OptBut_ShowText:GetText()])
		WXP_OptBut_AnimateText:SetText(		L[WXP_OptBut_AnimateText:GetText()])
		WXP_OptBut_OpenLabels:SetText(		L[WXP_OptBut_OpenLabels:GetText()])
	
	elseif frame == "Labels" then
		WXP_LabelOpt_Subtitle:SetText(		L[WXP_LabelOpt_Subtitle:GetText()])
		WXP_Opt_LabelColorTexture:SetText(	L[WXP_Opt_LabelColorTexture:GetText()])
		WXP_Opt_Font:SetText(				L[WXP_Opt_Font:GetText()])
		WXP_Opt_FontSize:SetText(			L[WXP_Opt_FontSize:GetText()])
		WXP_Opt_LabelOffset:SetText(		L[WXP_Opt_LabelOffset:GetText()])
		WXP_Opt_ShowLevel:SetText(			L[WXP_Opt_ShowLevel:GetText()])
		WXP_Opt_ShowRealm:SetText(			L[WXP_Opt_ShowRealm:GetText()])
		WXP_OptBut_ShowLabelsText:SetText(	L[WXP_OptBut_ShowLabelsText:GetText()])
		
		WXP_OptBut_ShowLevel1Text:SetText(	L[WXP_OptBut_ShowLevel1Text:GetText()])
		WXP_OptBut_ShowLevel2Text:SetText(	L[WXP_OptBut_ShowLevel2Text:GetText()])
		WXP_OptBut_ShowLevel3Text:SetText(	L[WXP_OptBut_ShowLevel3Text:GetText()])
		
		WXP_OptBut_ShowRealm1Text:SetText(	L[WXP_OptBut_ShowRealm1Text:GetText()])
		WXP_OptBut_ShowRealm2Text:SetText(	L[WXP_OptBut_ShowRealm2Text:GetText()])
		WXP_OptBut_ShowRealm3Text:SetText(	L[WXP_OptBut_ShowRealm3Text:GetText()])
	end
end

function WXP.LoadBlipButtons()					-- Initialize blip buttons
	--																x1		x2		y1		y2
	WXPBlipButton.new(0,0, "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",		0.625,	0.75,	0,		0.25)	-- Flat color circles
	WXPBlipButton.new(1,0, "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",		0.375,	0.5,	0,		0.25)
	WXPBlipButton.new(2,0, "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",		0.25,	0.375,	0,		0.25)
	WXPBlipButton.new(3,0, "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",		0.875,	1,		0,		0.25)
	WXPBlipButton.new(4,0, "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",		0.5,	0.625,	0,		0.25)
	WXPBlipButton.new(5,0, "INTERFACE\\MINIMAP\\OBJECTICONS.BLP",		0.25, 	0.375,	0.5,	0.625)	-- Speech Bubble
	WXPBlipButton.new(6,0, "INTERFACE\\BUTTONS\\UI-GroupLoot-Coin-Up.blp")
	WXPBlipButton.new(7,0, "INTERFACE\\MINIMAP\\Vehicle-GrummleConvoy.blp")
	
	WXPBlipButton.new(0,1, "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",		0.625,	0.75,	0.5,	0.75)	-- Dotted color circles
	WXPBlipButton.new(1,1, "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",		0.375,	0.5,	0.5,	0.75)
	WXPBlipButton.new(2,1, "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",		0.25,	0.375,	0.5,	0.75)
	WXPBlipButton.new(3,1, "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",		0.875,	1,		0.5,	0.75)
	WXPBlipButton.new(4,1, "INTERFACE\\MINIMAP\\PARTYRAIDBLIPS.BLP",		0.5,	0.625,	0.5,	0.75)
	WXPBlipButton.new(5,1, "INTERFACE\\MINIMAP\\TRACKING\\Target.blp")
	WXPBlipButton.new(6,1, "INTERFACE\\MINIMAP\\OBJECTICONS.BLP",		0.125, 	0.25,	0.5,	0.625)	-- Gear
	WXPBlipButton.new(7,1, "INTERFACE\\MINIMAP\\TRACKING\\Focus.blp")
	
	WXPBlipButton.new(0,2, "INTERFACE\\WorldStateFrame\\AllianceFlag.blp")
	WXPBlipButton.new(1,2, "INTERFACE\\WorldStateFrame\\HordeFlag.blp")
	WXPBlipButton.new(2,2, "INTERFACE\\BattlefieldFrame\\Battleground-Alliance.blp")
	WXPBlipButton.new(3,2, "INTERFACE\\BattlefieldFrame\\Battleground-Horde.blp")
	WXPBlipButton.new(4,2, "INTERFACE\\MINIMAP\\UI-Minimap-ZoomInButton-Up.blp")
	WXPBlipButton.new(5,2, "INTERFACE\\MINIMAP\\UI-Minimap-ZoomOutButton-Up.blp")
	WXPBlipButton.new(6,2, "INTERFACE\\BUTTONS\\UI-SliderBar-Button-Horizontal.blp")
	WXPBlipButton.new(7,2, "INTERFACE\\MINIMAP\\OBJECTICONS.BLP",		0.625,	0.75,	0.375,	0.5)	-- Skull
	
	WXPBlipButton.new(0,3, "INTERFACE\\MINIMAP\\TempleofKotmogu_ball_cyan.blp")
	WXPBlipButton.new(1,3, "INTERFACE\\MINIMAP\\TempleofKotmogu_ball_green.blp")
	WXPBlipButton.new(2,3, "INTERFACE\\MINIMAP\\TempleofKotmogu_ball_orange.blp")
	WXPBlipButton.new(3,3, "INTERFACE\\MINIMAP\\TempleofKotmogu_ball_purple.blp")
	WXPBlipButton.new(4,3, "INTERFACE\\MINIMAP\\OBJECTICONS.BLP",		0.125,	0.25,	0.125,	0.25)	-- Exclamation Mark
	WXPBlipButton.new(5,3, "INTERFACE\\MINIMAP\\MapQuestHub_Icon32.blp")
	WXPBlipButton.new(6,3, "INTERFACE\\TARGETINGFRAME\\PortraitQuestBadge.blp")
	WXPBlipButton.new(7,3, "INTERFACE\\MINIMAP\\TRACKING\\QuestBlob.blp")
	
	WXPBlipButton.new(0,4, "INTERFACE\\MINIMAP\\Vehicle-Ground-Occupied.blp", 0,1,1,0)
	WXPBlipButton.new(1,4, "INTERFACE\\MINIMAP\\MiniMap-QuestArrow.blp", 0,1,1,0)
	WXPBlipButton.new(2,4, "INTERFACE\\BUTTONS\\UI-MicroStream-Yellow.blp")
	WXPBlipButton.new(3,4, "INTERFACE\\MINIMAP\\TRACKING\\POIArrow.blp", 0,1,1,0)
	WXPBlipButton.new(4,4, "INTERFACE\\PvPRankBadges\\PvPRank01.blp")
	WXPBlipButton.new(5,4, "INTERFACE\\MINIMAP\\Vehicle-SilvershardMines-Arrow.blp", 0,1,1,0)
	WXPBlipButton.new(6,4, "INTERFACE\\BUTTONS\\JumpUpArrow.blp", 0,1,1,0)
	WXPBlipButton.new(7,4, "INTERFACE\\COMMON\\VOICECHAT-MUTED.BLP")
	
	WXPBlipButton.new(0,5, "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",		0, 		0.25,	0,		0.25)	-- Raid icons
	WXPBlipButton.new(1,5, "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",		0.25, 	0.5,	0,		0.25)
	WXPBlipButton.new(2,5, "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",		0.5, 	0.75,	0,		0.25)
	WXPBlipButton.new(3,5, "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",		0.75, 	1,		0,		0.25)
	WXPBlipButton.new(4,5, "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",		0, 		0.25,	0.25,	0.5)
	WXPBlipButton.new(5,5, "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",		0.25, 	0.5,	0.25,	0.5)
	WXPBlipButton.new(6,5, "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",		0.5, 	0.75,	0.25,	0.5)
	WXPBlipButton.new(7,5, "INTERFACE\\TARGETINGFRAME\\UI-RaidTargetingIcons.blp",		0.75, 	1,		0.25,	0.5)
end

function WXP.ShowColorPicker()					-- Show the color picker
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

--- UI events ---

function WXP.OnBlipMouseEnter()					-- Fired when mouse enters a blip
	local marker = GetMouseFocus().blip.marker
	
	local name  = marker.player.name  or "Unknown"
	local realm = marker.player.realm or "Unknown"
	local xp    = marker.player.xp    or 0
	local xpmax = marker.player.xpmax or 0
	local level = marker.player.level or 0
	
	local pct = math.floor((xp/xpmax)*100)
	
	GameTooltip:SetOwner(WXP_Frame,"ANCHOR_CURSOR")
	GameTooltip:SetText(format("%s-%s", name, realm))
	GameTooltip:AddLine(format(L["Level %i"], level))
	GameTooltip:AddLine(format(L["XP: %s / %s (%s%%)"], WXP.format_thousand(xp), WXP.format_thousand(xpmax), pct))
	GameTooltip:Show()
end

function WXP.OnBlipMouseLeave()					-- Fired when mouse leaves a blip
	GameTooltip:Hide()
end

function WXP.OnOptionsLoaded(self)				-- Initialize Options panel
	if self:GetName() == "WXP_Options" then
		self.name = "WatchXP"
		self.default = WXP.OnDefaultsClicked
		InterfaceOptions_AddCategory(self)
		WXP.LocalizeXML("WatchXP")
	else
		self.name = L["Labels"]
		self.parent = "WatchXP"
		self.default = WXP.OnDefaultsClicked
		InterfaceOptions_AddCategory(self)
		WXP.LocalizeXML("Labels")
	end
	
	
end

function WXP.OnOptionsShown()					-- Fired when options panel opens
	if not WXP_Settings then return end
	if WXPMarker.Count() == 0 then
		WXPMarker.new({name=L["Example!"], realm=L["RealmName"], level=1, xp=1, xpmax=4})
	end
end

function WXP.OnOptionsHidden()					-- Fired when options panel closes
	if not WXP_Settings then return end
	
	local marker = WXPMarker.Find(L["Example!"], L["RealmName"])
	if marker then
		marker:Remove()
	end
end

function WXP.OnWidgetUsed(self)					-- Fired when an options panel widget (button, slider, etc.) is used
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
	
	elseif self:GetName() == "WXP_OptBut_Animate" then
		if WXP_OptBut_Animate:GetChecked() then
			WXP_Settings.blip.animate = true
		else
			WXP_Settings.blip.animate = false
		end
	
	elseif self:GetName() == "WXP_OptBut_ShowLabels" then
		if WXP_OptBut_ShowLabels:GetChecked() then
			WXP_Settings.label.show = true
		else
			WXP_Settings.label.show = false
		end
	
	elseif self:GetName() == "WXP_OptBut_ShowLevel1" then	-- Never show level
		WXP_Settings.label.showlevel = "never"
		WXP_OptBut_ShowLevel1:SetChecked(true)
		WXP_OptBut_ShowLevel2:SetChecked(false)
		WXP_OptBut_ShowLevel3:SetChecked(false)
	
	elseif self:GetName() == "WXP_OptBut_ShowLevel2" then	-- Show level if different
		WXP_Settings.label.showlevel = "different"
		WXP_OptBut_ShowLevel1:SetChecked(false)
		WXP_OptBut_ShowLevel2:SetChecked(true)
		WXP_OptBut_ShowLevel3:SetChecked(false)
	
	elseif self:GetName() == "WXP_OptBut_ShowLevel3" then	-- Always
		WXP_Settings.label.showlevel = "always"
		WXP_OptBut_ShowLevel1:SetChecked(false)
		WXP_OptBut_ShowLevel2:SetChecked(false)
		WXP_OptBut_ShowLevel3:SetChecked(true)
	
	--- ShowRealm ---
	
	elseif self:GetName() == "WXP_OptBut_ShowRealm1" then	-- Never show realm
		WXP_Settings.label.showrealm = "never"
		WXP_OptBut_ShowRealm1:SetChecked(true)
		WXP_OptBut_ShowRealm2:SetChecked(false)
		WXP_OptBut_ShowRealm3:SetChecked(false)
	
	elseif self:GetName() == "WXP_OptBut_ShowRealm2" then	-- Show realm if different
		WXP_Settings.label.showrealm = "different"
		WXP_OptBut_ShowRealm1:SetChecked(false)
		WXP_OptBut_ShowRealm2:SetChecked(true)
		WXP_OptBut_ShowRealm3:SetChecked(false)
	
	elseif self:GetName() == "WXP_OptBut_ShowRealm3" then	-- Always show realm
		WXP_Settings.label.showrealm = "always"
		WXP_OptBut_ShowRealm1:SetChecked(false)
		WXP_OptBut_ShowRealm2:SetChecked(false)
		WXP_OptBut_ShowRealm3:SetChecked(true)
		
	--- End ShowRealm ---
	
	elseif self:GetName() == "WXP_OptBut_Font1" then		-- Friz Quadrata
		WXP_Settings.label.font.face = "Fonts\\FRIZQT__.TTF"
		WXP_OptBut_Font1:SetChecked(true)
		WXP_OptBut_Font2:SetChecked(false)
		WXP_OptBut_Font3:SetChecked(false)
		WXP_OptBut_Font4:SetChecked(false)
		WXP_OptBut_Font5:SetChecked(false)
		WXP_OptBut_Font6:SetChecked(false)
	
	elseif self:GetName() == "WXP_OptBut_Font2" then		-- Arial
		WXP_Settings.label.font.face = "Fonts\\ARIALN.TTF"
		WXP_OptBut_Font1:SetChecked(false)
		WXP_OptBut_Font2:SetChecked(true)
		WXP_OptBut_Font3:SetChecked(false)
		WXP_OptBut_Font4:SetChecked(false)
		WXP_OptBut_Font5:SetChecked(false)
		WXP_OptBut_Font6:SetChecked(false)
	
	elseif self:GetName() == "WXP_OptBut_Font3" then		-- Morpheus
		WXP_Settings.label.font.face = "Fonts\\MORPHEUS.TTF"
		WXP_OptBut_Font1:SetChecked(false)
		WXP_OptBut_Font2:SetChecked(false)
		WXP_OptBut_Font3:SetChecked(true)
		WXP_OptBut_Font4:SetChecked(false)
		WXP_OptBut_Font5:SetChecked(false)
		WXP_OptBut_Font6:SetChecked(false)
	
	elseif self:GetName() == "WXP_OptBut_Font4" then		-- Skurri
		WXP_Settings.label.font.face = "Fonts\\SKURRI.TTF"
		WXP_OptBut_Font1:SetChecked(false)
		WXP_OptBut_Font2:SetChecked(false)
		WXP_OptBut_Font3:SetChecked(false)
		WXP_OptBut_Font4:SetChecked(true)
		WXP_OptBut_Font5:SetChecked(false)
		WXP_OptBut_Font6:SetChecked(false)
	
	elseif self:GetName() == "WXP_OptBut_Font5" then		-- Nimrod
		WXP_Settings.label.font.face = "Fonts\\NIM_____.ttf"
		WXP_OptBut_Font1:SetChecked(false)
		WXP_OptBut_Font2:SetChecked(false)
		WXP_OptBut_Font3:SetChecked(false)
		WXP_OptBut_Font4:SetChecked(false)
		WXP_OptBut_Font5:SetChecked(true)
		WXP_OptBut_Font6:SetChecked(false)
	
	elseif self:GetName() == "WXP_OptBut_Font6" then		-- Mok
		WXP_Settings.label.font.face = "Fonts\\K_Pagetext.TTF"
		WXP_OptBut_Font1:SetChecked(false)
		WXP_OptBut_Font2:SetChecked(false)
		WXP_OptBut_Font3:SetChecked(false)
		WXP_OptBut_Font4:SetChecked(false)
		WXP_OptBut_Font5:SetChecked(false)
		WXP_OptBut_Font6:SetChecked(true)
		
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

function WXP.OnBlipSelected(self,id)			-- Fired when a blip button is clicked
	WXP_Settings.blip.id = id
	WXP.UpdateBlipSelector(id)
	WXPMarker.RedrawAll()
end

function WXP.OnColorPickerChanged()				-- Fired when color picker is changed
	WXP_Settings.label.color.r, WXP_Settings.label.color.g, WXP_Settings.label.color.b = ColorPickerFrame:GetColorRGB()
	WXP_Settings.label.color.a = 1 - OpacitySliderFrame:GetValue()
	WXP_OptBut_Color:SetColorTexture(ColorPickerFrame:GetColorRGB())
	WXPMarker.RedrawAll()
end

function WXP.OnColorPickerCanceled(prevValues) 	-- Fired when the color picker is closed with "Cancel"
	WXP_Settings.label.color = prevValues
	WXP_OptBut_Color:SetColorTexture(prevValues.r, prevValues.g, prevValues.b)
	WXPMarker.RedrawAll()
end

function WXP.OnSliderScroll(slider, delta) 		-- Fired when a slider is scrolled with the mouse wheel
	slider:SetValue(slider:GetValue() + delta)
end

function WXP.OnDefaultsClicked()				-- Reset all settings to default when "Defaults" button is clicked
	WXP.Debug("Defaults button clicked")
	
	local debug_enabled = WXP_Settings.debug
	WXP_Settings = WXP.deepcopy(WXP.default_settings)
	if debug_enabled then WXP_Settings.debug = true end
	WXP_Settings.version = WXP.version
	WXP.InitializeWidgets()
	WXPBlipButton.UpdateAll()
	WXPMarker.RedrawAll()
end

--- Debug functions ---

function WXP.add(pct, name)						-- Debug function to add a marker
	pct = pct or 25
	name = name or "Marker"
	local marker = WXPMarker.new({name=name, realm="Test", xp=pct, xpmax=100, level=10})
end

function WXP.pop()								-- Debug function to add a bunch of markers
	WXP.add(25, "1")
	WXP.add(40, "2")
	WXP.add(35, "3")
	WXP.add(30, "4")
end

function WXP.xp(name,realm,level,xp,xpmax)		-- Debug function to update a marker
	WXPMarker.Find(name,realm):Update({level=level,xp=xp,xpmax=xpmax})
end

--- Miscellaneous functions ---

function WXP.format_thousand(v)					-- Adds thousands-separator (,) to a number
	local s = string.format("%d", math.floor(v))
	local pos = string.len(s) % 3
	if pos == 0 then pos = 3 end
	return string.sub(s, 1, pos)
		.. string.gsub(string.sub(s, pos+1), "(...)", ",%1")
		.. string.sub(string.format("%.0f", v - math.floor(v)), 2)
end

function WXP.deepcopy(orig)						-- Clones a table
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

function WXP.print_r(t, indent, done)			-- Prints a table and all its values
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

function WXP.round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

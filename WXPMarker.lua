-- Represents an object made up of both a Blip (the frame, fontstring, and texture) and player data (name, realm, level, xp, xpmax)

WXPMarker = {}
WXPMarker.instances = {}
WXPMarker.__index = WXPMarker

----- Class methods -----

function WXPMarker.new(args)			-- Create a new marker
	WXP.Debug("|cffff9326[Marker]|r Creating new marker for", WXP.PlayerLink(args.name,args.realm))
	local self = {} -- Create the instance
	setmetatable(self, WXPMarker) -- Make an instance of WXPMarker
	self.blip = WXPBlip.GetFree() -- Get a free (or new) blip
	self.player = {name = args.name, realm = args.realm, level = args.level, xp = args.xp, xpmax = args.xpmax}
	tinsert(WXPMarker.instances, self) -- Insert this instance into WXPMarker's instance container
	self:Redraw()
	WXPMarker.RedrawAll()
	return self
end

function WXPMarker.RedrawAll()			-- Redraw all markers
	WXP.Debug("|cffff9326[Marker]|r Redrawing all markers")
	for marker in WXPMarker.All("rtl") do
		marker:Redraw(true)
	end
end

function WXPMarker.RemoveAll()			-- Remove all markers
	WXP.Debug("|cffff9326[Marker]|r Removing all markers")
	
	for i,marker in pairs(WXPMarker.instances) do
		marker:Remove()
	end
end

function WXPMarker.Find(name, realm)	-- Find a marker by player name and realm
	if WXPMarker.Count() == 0 then return nil end
	
	WXP.Debug("|cffff9326[Marker]|r Finding marker for", WXP.PlayerLink(name,realm))
	for i,marker in pairs(WXPMarker.instances) do
		if marker.player.name:lower() == name:lower() and marker.player.realm:lower() == realm:lower() then
			WXP.Debug("|cffff9326[Marker]|r Marker #"..i, "found for", WXP.PlayerLink(name,realm))
			return marker
		end
	end
	
	WXP.Debug("|cffff9326[Marker]|r No marker found for", WXP.PlayerLink(name,realm))
	return nil
end

function WXPMarker.All(sortmethod)		-- Returns an iterator containing all WXPMarkers, optionally sorted (rtl = right to left)
	local sortedmarkers = {}
	
	for k,marker in pairs(WXPMarker.instances) do
		tinsert(sortedmarkers, {id=k, pos = marker.player.xp/marker.player.xpmax})
	end
	
	if sortmethod == "rtl" then -- Return all markers, from rightmost to leftmost
		table.sort(sortedmarkers,function(a,b) return a.pos > b.pos end)
	end
	
	local i = 0
	local len = #sortedmarkers
	
	return function()
		i = i+1
		if i <= len then
			return WXPMarker.instances[sortedmarkers[i].id]
		end
	end
end

function WXPMarker.Count()
	local count = 0
	
	for i,marker in pairs(WXPMarker.instances) do
		count = count+1
	end
	WXP.Debug("WXPMarker count is " .. count)
	return count
end

----- Instance methods -----

function WXPMarker:Update(args)			-- Update the data of an existing marker
	WXP.Debug("|cffff9326[Marker]|r Updating marker for", WXP.PlayerLink(args.name,args.realm))
	if args.name  then  self.player.name  = args.name   end
	if args.realm then  self.player.realm = args.realm  end
	if args.level then  self.player.level = args.level  end
	if args.xp    then  self.player.xp    = args.xp     end
	if args.xpmax then  self.player.xpmax = args.xpmax  end
	self:Redraw()
	WXPMarker.RedrawAll()
end

function WXPMarker:Redraw(checkflip)	-- Redraw a marker
	WXP.Debug("Redrawing " .. self.player.name)
	local label = self.player.name or "Unknown"
	
	if WXP_Settings.label.showrealm == "always" or (WXP_Settings.label.showrealm == "different" and self.player.realm ~= GetRealmName("player")) then
		label = label.."-"..self.player.realm
	end
	
	if WXP_Settings.label.showlevel == "always" or (WXP_Settings.label.showlevel == "different" and tonumber(self.player.level) ~= tonumber(UnitLevel("player"))) then
		label = label.." ("..self.player.level..")"
	end
	
	self.blip.fontstring:SetText(label)
	
	local _,_,_,xoff = self.blip.frame:GetPoint()
	self.blip.frame:SetPoint("CENTER",WXP_Frame,"LEFT",xoff,WXP_Settings.blip.offset.y)
	self.blip.fontstring:ClearAllPoints()
	self.blip.fontstring:SetPoint("LEFT",self.blip.frame,"RIGHT",0,WXP_Settings.label.offset.y)
	self.blip.orientation = "right"
	
	--self.blip.texture:SetTexture("Interface\\Addons\\WatchXP\\blips\\" .. WXP_Settings.blip.texture .. ".tga")
	self.blip.texture:SetTexture(WXP_Settings.blip.texture)
	self.blip.texture:SetTexCoord(WXP_Settings.blip.texoffset.x1, WXP_Settings.blip.texoffset.x2,WXP_Settings.blip.texoffset.y1,WXP_Settings.blip.texoffset.y2)
	
	self.blip.frame:SetSize(WXP_Settings.blip.size,WXP_Settings.blip.size)
	self.blip.texture:SetSize(WXP_Settings.blip.size,WXP_Settings.blip.size)
	
	if WXP_Settings.label.font.face == "friz" then
		self.blip.fontstring:SetFont("Fonts\\FRIZQT__.TTF",WXP_Settings.label.font.size)
	elseif WXP_Settings.label.font.face == "arial" then
		self.blip.fontstring:SetFont("Fonts\\\ARIALN.TTF",WXP_Settings.label.font.size)
	elseif WXP_Settings.label.font.face == "morpheus" then
		self.blip.fontstring:SetFont("Fonts\\MORPHEUS.TTF",WXP_Settings.label.font.size)
	elseif WXP_Settings.label.font.face == "skurri" then
		self.blip.fontstring:SetFont("Fonts\\SKURRI.TTF",WXP_Settings.label.font.size)
	else
		self.blip.fontstring:SetFont("Fonts\\FRIZQT__.TTF",WXP_Settings.label.font.size)
	end
	
	self.blip.fontstring:SetTextColor(WXP_Settings.label.color.r,WXP_Settings.label.color.g,WXP_Settings.label.color.b,WXP_Settings.label.color.a)
	
	if not WXP_Settings.label.show then
		self.blip.fontstring:Hide()
	else
		self.blip.fontstring:Show()
	end
	
	local barwidth = WXP_Frame:GetParent():GetWidth()
	local xpwidth
	
	if self.player.xpmax == 0 then
		xpwidth = 0
	else
		xpwidth = barwidth * (self.player.xp / self.player.xpmax)
	end
	
	self.blip.frame:SetPoint("CENTER",WXP_Frame,"LEFT",xpwidth,WXP_Settings.blip.offset.y)
	
	self.blip.frame:Show()
	
	if checkflip then
		if self:CheckFlip() then
			self.blip.fontstring:ClearAllPoints()
			self.blip.fontstring:SetPoint("RIGHT",self.blip.frame,"LEFT",0,WXP_Settings.label.offset.y)
			self.blip.orientation = "left"
		end
	end
end

function WXPMarker:Remove()				-- Remove a marker
	if not self then return false end
	self.blip.free = true
	self.blip.frame:Hide()
	WXPMarker.instances[self:GetIndex()] = nil
	WXPMarker.RedrawAll()
end

function WXPMarker:CheckFlip()			-- Check if a label should be flipped (near end of bar or next to another blip)
	local width = self.blip.fontstring:GetStringWidth() * WXP_Frame:GetEffectiveScale()
	local pos = self.blip.frame:GetRight() * WXP_Frame:GetEffectiveScale()
	local rightpos = pos+width
	local bar_right_edge = WXP_Frame:GetRight() * WXP_Frame:GetEffectiveScale()
	
	if rightpos > bar_right_edge then return true end -- label goes off right edge of experience bar
	
	for k,marker in pairs(WXPMarker.instances) do
		WXP.Debug(marker.player.xp / marker.player.xpmax, self.player.xp / self.player.xpmax)
		if marker.player.xp/marker.player.xpmax > self.player.xp/self.player.xpmax then -- Only test against this blip if it's further to the right
			WXP.Debug("Checking " .. self.player.xp .. " (right is " .. math.floor(rightpos) .. ") against " .. marker.player.xp)
			WXP.Debug("   new is oriented: " .. marker.blip.orientation)
			if marker.blip.orientation == "left" then -- label is on left side
				local mrkpos = marker.blip.frame:GetLeft() * WXP_Frame:GetEffectiveScale()
				local mrkwidth = marker.blip.fontstring:GetStringWidth() * WXP_Frame:GetEffectiveScale()
				if rightpos > mrkpos-mrkwidth then
					return true
				end
			elseif marker.blip.orientation == "right" then -- label is on right side
				local mrkpos = marker.blip.frame:GetLeft() * WXP_Frame:GetEffectiveScale()
				WXP.Debug("   new's left is " .. math.floor(mrkpos))
				if rightpos > mrkpos then
					return true
				end
			end
		end
	end
	
	return false
end

function WXPMarker:GetIndex()			-- Get this marker's index in WXPMarker.instances
	for k,marker in pairs(WXPMarker.instances) do
		if marker == self then
			return k
		end
	end
	
	return nil
end

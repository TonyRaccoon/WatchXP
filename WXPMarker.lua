-- Represents an object made up of both a Blip (the frame, fontstring, and texture) and player data (name, realm, level, xp, xpmax)

WXPMarker = {}
WXPMarker.instances = {}
WXPMarker.__index = WXPMarker
WXPMarker.debug = "|cffff9326[Marker]|r "

--- Class functions ---

function WXPMarker.new(args)			-- Create a new marker
	local existingmarker = WXPMarker.Find(args.name, args.realm)
	if existingmarker then -- If the marker already exists, update it instead
		existingmarker:Update({level=args.level, xp=args.xp, xpmax=args.xpmax})
		return
	end
	
	WXP.Debug(WXPMarker.debug, "Creating new marker for " .. WXP.PlayerLink(args.name,args.realm))
	
	local self = {}
	setmetatable(self, WXPMarker)
	tinsert(WXPMarker.instances, self)
	
	self.blip = WXPBlip.GetFree()
	self.blip.marker = self
	self.player = {name = args.name, realm = args.realm, level = args.level, xp = args.xp, xpmax = args.xpmax}
	
	self:Redraw()
	WXPMarker.RedrawAll()
	
	return self
end

function WXPMarker.RedrawAll()			-- Redraw all markers
	WXP.Debug(WXPMarker.debug, "Redrawing all markers")
	
	for marker in WXPMarker.All("rtl") do
		marker.blip.fontstring:Hide() -- Hide the fontstring (it gets shown again in :Redraw() to avoid it flickering for some reason
		marker:Redraw(true)
	end
end

function WXPMarker.RemoveAll()			-- Remove all markers
	WXP.Debug(WXPMarker.debug, "Removing all markers")
	
	for i,marker in pairs(WXPMarker.instances) do
		marker:Remove()
	end
end

function WXPMarker.Find(name, realm)	-- Find a marker by player name and realm
	if WXPMarker.Count() == 0 then return nil end
	
	for i,marker in pairs(WXPMarker.instances) do
		if marker.player.name:lower() == name:lower() and marker.player.realm:lower() == realm:lower() then
			return marker
		end
	end
	
	WXP.Debug(WXPMarker.debug, "No existing marker found for", WXP.PlayerLink(name,realm))
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
		if i <= len then return WXPMarker.instances[sortedmarkers[i].id] end
	end
end

function WXPMarker.Count()				-- Returns the number of markers
	local count = 0
	
	for i,marker in pairs(WXPMarker.instances) do
		count = count+1
	end
	
	WXP.Debug(WXPMarker.debug, "WXPMarker count is " .. count)
	return count
end

--- Instance functions ---

function WXPMarker:Update(args)			-- Update the data of an existing marker
	WXP.Debug(WXPMarker.debug, "Updating marker for", WXP.PlayerLink(self.player.name,self.player.realm))
	
	if WXP_Settings.blip.animate then -- if animation is enabled, and an animation is necessary
		local animated = self.blip:AnimateTo(args.level, args.xp, args.xpmax)
		
		self.player.level = args.level
		self.player.xp    = args.xp
		self.player.xpmax = args.xpmax
		
		if not animated then -- If the animation wasn't necessary then we'll have to redraw the marker manually
			self:Redraw()
			WXPMarker.RedrawAll()
		end
	else
		self.player.level = args.level
		self.player.xp    = args.xp
		self.player.xpmax = args.xpmax
		
		self:Redraw()
		WXPMarker.RedrawAll()
	end
end

function WXPMarker:Redraw(checkflip)	-- Redraw a marker
	if self.blip.animation and self.blip.animation:IsPlaying() then -- Don't move this marker around if it's busy animating
		WXP.Debug(WXPMarker.debug, "Attempted to redraw " .. self.player.name .. ", but it was animating, so skipped it")
		
		if WXP_Settings.label.show then -- We still have to show the label (if enabled) though, since it's always hidden before a :Redraw() to avoid flickering
			self.blip.fontstring:Show()
		else
			self.blip.fontstring:Hide()
		end
	
		return
	end
	
	WXP.Debug(WXPMarker.debug, "Redrawing " .. self.player.name)
	
	-- Update frame
	
	local leftpos = WXP_Frame:GetWidth() * (self.player.xp / self.player.xpmax)
	self.blip.frame:SetPoint("CENTER",WXP_Frame,"LEFT",leftpos,WXP_Settings.blip.offset.y)
	self.blip.frame:SetSize(WXP_Settings.blip.size,WXP_Settings.blip.size)
	
	-- Update fontstring
	
	local label = self.player.name
	
	if WXP_Settings.label.showrealm == "always" or (WXP_Settings.label.showrealm == "different" and self.player.realm ~= GetRealmName("player")) then
		label = label.."-"..self.player.realm
	end
	
	if WXP_Settings.label.showlevel == "always" or (WXP_Settings.label.showlevel == "different" and tonumber(self.player.level) ~= tonumber(UnitLevel("player"))) then
		label = label.." ("..self.player.level..")"
	end
	
	self.blip.fontstring:SetText(label)
	self.blip.fontstring:SetFont(WXP_Settings.label.font.face, WXP_Settings.label.font.size)
	self.blip.fontstring:SetTextColor(WXP_Settings.label.color.r,WXP_Settings.label.color.g,WXP_Settings.label.color.b,WXP_Settings.label.color.a)
	
	self.blip.fontstring:ClearAllPoints()
	
	if checkflip and self:CheckFlip() then
		self.blip.orientation = "left"
		self.blip.fontstring:SetPoint("RIGHT",self.blip.frame,"LEFT",0,WXP_Settings.label.offset.y)
	else
		self.blip.orientation = "right"
		self.blip.fontstring:SetPoint("LEFT",self.blip.frame,"RIGHT",0,WXP_Settings.label.offset.y)
	end
	
	if WXP_Settings.label.show then
		self.blip.fontstring:Show()
	else
		self.blip.fontstring:Hide()
	end
	
	-- Update texture
	
	self.blip.texture:SetTexture(WXP_Settings.blip.texture)
	self.blip.texture:SetTexCoord(WXP_Settings.blip.texoffset.x1, WXP_Settings.blip.texoffset.x2,WXP_Settings.blip.texoffset.y1,WXP_Settings.blip.texoffset.y2)
	self.blip.texture:SetSize(WXP_Settings.blip.size,WXP_Settings.blip.size)

	self.blip.frame:Show()
end

function WXPMarker:Remove()				-- Remove a marker
	self.blip.free = true
	self.blip.marker = nil
	self.blip.frame:Hide()
	self.blip:CancelAnimation()
	WXPMarker.instances[self:GetIndex()] = nil
	WXPMarker.RedrawAll()
end

function WXPMarker:CheckFlip()			-- Check if a label should be flipped (near end of bar or next to another blip)
	local rightpos = self.blip.frame:GetRight() + self.blip.fontstring:GetStringWidth()
	
	if rightpos > WXP_Frame:GetRight() then
		local blip_nearby_left = false
		
		-- Check to see if there are any blips just to the left of this one. If there are, then ignore the right side of the bar and don't flip/overlap the one to the left
		for k,marker in pairs(WXPMarker.instances) do
			if marker ~= self then
				if marker.blip.orientation == "left" then
					if marker.blip.frame:GetRight() > self.blip.frame:GetLeft() - self.blip.fontstring:GetStringWidth() then
						blip_nearby_left = true
					end
				else
					if marker.blip.frame:GetRight() + marker.blip.fontstring:GetStringWidth() > self.blip.frame:GetLeft() - self.blip.fontstring:GetStringWidth() then
						blip_nearby_left = true
					end
				end
			end
		end
		
		if blip_nearby_left then
			return false
		else
			return true
		end
	end -- label goes off right edge of experience bar
	
	for k,marker in pairs(WXPMarker.instances) do
		if marker.player.xp/marker.player.xpmax > self.player.xp/self.player.xpmax then -- Only test against this blip if it's further to the right
			WXP.Debug("Checking " .. self.player.xp .. " (right is " .. math.floor(rightpos  * WXP_Frame:GetEffectiveScale()) .. ") against " .. marker.player.xp)
			WXP.Debug("   new is oriented: " .. marker.blip.orientation)
			
			local mrkpos = marker.blip.frame:GetLeft()
			
			if marker.blip.orientation == "left" then
				local mrkwidth = marker.blip.fontstring:GetStringWidth()
				if rightpos > mrkpos-mrkwidth then
					return true
				end
			elseif marker.blip.orientation == "right" then
				WXP.Debug("   new's left is " .. math.floor(mrkpos * WXP_Frame:GetEffectiveScale()))
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

function WXPMarker:GetXPFromPosition() -- Return the xp based on where the marker currently is (used in animation)
	local _,_,_,xoff,yoff = self.blip.frame:GetPoint("CENTER")
	return xoff / WXP_Frame:GetWidth() * self.player.xpmax
end

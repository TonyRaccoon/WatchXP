-- Represents a blip comprised of a Frame, a FontString (the blip's label) attached to the frame, and a Texture (the blip's dot)
-- Frames can never be deleted, so when a new blip is needed, we first try returning the first unused blip before creating a new one

WXPBlip = {}
WXPBlip.instances = {}
WXPBlip.__index = WXPBlip
WXPBlip.debug = "|cffff0080[Blip]|r"

--- Class functions ---

function WXPBlip.new()		-- Create a new blip
	WXP.Debug(WXPBlip.debug, "Creating new blip")
	local self = {}
	self.id = #WXPBlip.instances + 1
	setmetatable(self, WXPBlip)
	tinsert(WXPBlip.instances, self)
	
	self.orientation = "right"
	self.free = false
	
	self.frame = CreateFrame("Frame", "WXP_Frame_"..self.id, WXP_Frame, nil, self.id)
	self.frame:SetPoint("CENTER", WXP_Frame, "LEFT", 0, WXP_Settings.blip.offset.y)
	self.frame:SetSize(WXP_Settings.blip.size, WXP_Settings.blip.size)
	self.frame:SetScript("OnEnter", WXP.OnBlipMouseEnter)
	self.frame:SetScript("OnLeave", WXP.OnBlipMouseLeave)
	self.frame.blip = self
	
	self.texture = self.frame:CreateTexture("WXP_Tex_"..self.id,"ARTWORK")
	self.texture:SetTexture(WXP_Settings.blip.texture)
	self.texture:SetTexCoord(WXP_Settings.blip.texoffset.x1, WXP_Settings.blip.texoffset.x2,WXP_Settings.blip.texoffset.y1,WXP_Settings.blip.texoffset.y2)
	self.texture:SetAllPoints()
	
	self.fontstring = self.frame:CreateFontString("WXP_Text_"..self.id,"ARTWORK","GameFontNormal")
	
	return self
end

function WXPBlip.GetFree()	-- Get the first free blip, or create one if none are free
	WXP.Debug(WXPBlip.debug, "Finding first free blip")
	for i,blip in ipairs(WXPBlip.instances) do
		if blip.free then
			WXP.Debug(WXPBlip.debug, "Blip #"..i, "is free")
			blip.free = false
			return blip
		end
	end
	
	-- None free, so create a new blip
	WXP.Debug(WXPBlip.debug, "No free blips, creating a new one")
	return WXPBlip.new()
end

--- Instance functions ---

function WXPBlip:AnimateTo(level,newxp,newxpmax)
	WXP.Debug(WXPAnim.debug, "AnimateTo "..newxp)
	if level > self.marker.player.level then -- Just skip animations between levels, too much work to handle
		WXP.Debug(WXPAnim.debug, "  New level, skipping")
		self:CancelAnimation()
		return false
	elseif WXP.round(self.marker:GetXPFromPosition(), 4) == newxp then -- We're already here, don't do a pointless 0-pixel animation
		WXP.Debug(WXPAnim.debug, "  No position change, skipping")
		return false
	elseif newxp < self.marker.player.xp then -- We'd be going backwards, so just move it manually
		self:CancelAnimation()
		self.marker:Redraw()
		WXPMarker.RedrawAll()
		return false
	end
	
	local oldxp = self.marker.player.xp
	local oldxpmax = self.marker.player.xpmax
	
	WXP.Debug(WXPAnim.debug, "  oldxp = "..oldxp)
	
	if self.animation then
		self:CancelAnimation()
		oldxp = self.marker:GetXPFromPosition()
		WXP.Debug(WXPAnim.debug, "  Canceling previous animation, new oldxp = "..oldxp)
	end
	
	self.animation = self.frame:CreateAnimationGroup()
	self.animation.blip = self
	
	local distance = WXPAnim.GetDistance(oldxp, oldxpmax, newxp, newxpmax)
	
	self.animation.translation = self.animation:CreateAnimation("Translation")
	self.animation.translation:SetDuration(WXPAnim.GetDuration(distance))
	self.animation.translation:SetSmoothing("IN_OUT")
	
	self.animation.translation:SetOffset(distance, 0)
	
	self.animation:SetScript("OnFinished", function(self)
		self:GetParent():SetScript("OnUpdate", WXPAnim.OnUpdate)
	end)
	
	self.animation:Play()
	
	return true
end

function WXPBlip:CancelAnimation()
	if not self.animation then
		return
	end
	
	local currentoffset = WXPAnim.GetCurrentOffset(self.animation)
	self.frame:SetPoint("CENTER", WXP_Frame, "LEFT", currentoffset, WXP_Settings.blip.offset.y)
	
	self.animation:Stop()
	self.animation = nil
end

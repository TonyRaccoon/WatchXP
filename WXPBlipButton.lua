-- Represents a frame/button in the options to select a blip texture

WXPBlipButton = {}
WXPBlipButton.instances = {}
WXPBlipButton.__index = WXPBlipButton

WXPBlipButton.hoverAlpha = 0.6
WXPBlipButton.inactiveAlpha = 0.3
WXPBlipButton.columns = 8
WXPBlipButton.offset = {x = 0, y = -10}

----- Class methods -----

function WXPBlipButton.new(texturename,offx1,offx2,offy1,offy2)	-- Creates a new WXPBlipButton (offx/offy specify position of 32x32 blip in texture)
	self = {}
	setmetatable(self, WXPBlipButton)
	
	offx1 = offx1 or 0
	offx2 = offx2 or 1
	offy1 = offy1 or 0
	offy2 = offy2 or 1
	
	local x,y = WXPBlipButton.GetNextXY()
	local id = #WXPBlipButton.instances + 1
	
	self.frame = CreateFrame("Frame", "WXP_BS_Frame_" .. id, WXP_Options)
	self.frame:SetPoint("TOPLEFT", "WXP_Opt_BlipTexture", "BOTTOMLEFT", x, y)
	self.frame:SetSize(32,32)
	self.frame.buttonid = id
	
	self.texture = self.frame:CreateTexture("WXP_BS_Tex_" .. id, "ARTWORK")
	self.texture:SetAllPoints()
	self.texture:SetTexture(texturename)
	self.texture:SetTexCoord(offx1,offx2,offy1,offy2)
	
	self.frame:SetScript("OnMouseDown", function(self, button)
		local blipbutton = WXPBlipButton.GetByFrame(self)
		if blipbutton then blipbutton:OnClick(button) end
	end)
	
	self.frame:SetScript("OnEnter", function(self)
		local blipbutton = WXPBlipButton.GetByFrame(self)
		if blipbutton then blipbutton:OnMouseEnter() end
	end)
	
	self.frame:SetScript("OnLeave", function(self)
		local blipbutton = WXPBlipButton.GetByFrame(self)
		if blipbutton then blipbutton:OnMouseLeave() end
	end)
	
	if texturename == WXP_Settings.blip.texture
	and offx1 == WXP_Settings.blip.texoffset.x1 and offy1 == WXP_Settings.blip.texoffset.y1
	and offx2 == WXP_Settings.blip.texoffset.x2 and offy2 == WXP_Settings.blip.texoffset.y2 then
		self.active = true
	else
		self.active = false
		self.frame:SetAlpha(WXPBlipButton.inactiveAlpha)
	end
	
	self.id = id
	self.texoffset = {x1=offx1, x2=offx2, y1=offy1, y2=offy2}
	self.texturename = texturename
	tinsert(WXPBlipButton.instances, self)
	return self
end

function WXPBlipButton.GetByFrame(frame)			-- Returns the WXPBlipButton for the given texture
	for i,button in ipairs(WXPBlipButton.instances) do
		if frame.buttonid == button.id then
			return button
		end
	end
	
	return false
end

function WXPBlipButton.GetNextXY()					-- Returns the X/Y coordinates the next blip button should be placed at in the options frame
	local buttoncount = #WXPBlipButton.instances
	
	local row = math.floor(buttoncount/WXPBlipButton.columns)
	local column = buttoncount - (row * WXPBlipButton.columns)
	
	local x = column * 32
	local y = row * 32
	y = y * -1 -- Reverse up/down
	
	x = x + WXPBlipButton.offset.x
	y = y + WXPBlipButton.offset.y
	
	return x,y
end

function WXPBlipButton.All()						-- Returns an iterator containing all WXPBlipButtons
	local i = 0
	local len = #WXPBlipButton.instances
	
	return function()
		i = i+1
		if i <= len then return WXPBlipButton.instances[i] end
	end
end

----- Instance methods -----

function WXPBlipButton:OnClick(button)				-- Fired when the button is clicked
	if button ~= "LeftButton" then return end -- Only do something on left click
	if self.active then return end -- Don't need to do anything if it's already selected
	
	for blipbutton in WXPBlipButton.All() do
		blipbutton.active = false
		blipbutton.frame:SetAlpha(WXPBlipButton.inactiveAlpha)
	end
	
	self.active = true
	self.frame:SetAlpha(1)
	WXP_Settings.blip.texture = self.texturename
	WXP_Settings.blip.texoffset.x1 = self.texoffset.x1
	WXP_Settings.blip.texoffset.x2 = self.texoffset.x2
	WXP_Settings.blip.texoffset.y1 = self.texoffset.y1
	WXP_Settings.blip.texoffset.y2 = self.texoffset.y2
	WXPMarker.RedrawAll()
end

function WXPBlipButton:OnMouseEnter(button)			-- Fired when the button is hovered over
	if not self.active then
		self.frame:SetAlpha(WXPBlipButton.hoverAlpha)
	end
end

function WXPBlipButton:OnMouseLeave(button)			-- Fired when the button is unhovered
	if not self.active then
		self.frame:SetAlpha(WXPBlipButton.inactiveAlpha)
	end
end

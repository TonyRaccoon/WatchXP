-- Represents a blip comprised of a Frame, a FontString (the blip's label) attached to the frame, and a Texture (the blip's dot)
-- Frames can never be deleted, so when a new blip is needed, we first try returning the first unused blip before creating a new one

WXPBlip = {}
WXPBlip.instances = {}
WXPBlip.__index = WXPBlip

----- Class Methods -----

function WXPBlip.new()		-- Create a new blip
	WXP.Debug("|cffff0080[Blip]|r Creating new blip")
	local self = {} -- Create the instance
	setmetatable(self, WXPBlip) -- Make an instance of WXPBlip
	
	local id = #WXPBlip.instances + 1
	
	local frame = CreateFrame("Frame", "WXP_Frame_"..id, WXP_Frame, nil, id)
	frame:SetPoint("CENTER", WXP_Frame, "LEFT", 0, WXP_Settings.blip.offset.y)
	frame:SetSize(WXP_Settings.blip.size, WXP_Settings.blip.size)
	frame:SetScript("OnEnter", WXP.OnBlipMouseEnter)
	frame:SetScript("OnLeave", WXP.OnBlipMouseLeave)
	
	local texture = frame:CreateTexture("WXP_Tex_"..id,"ARTWORK")
	texture:SetAllPoints()
	
	texture:SetTexture(WXP_Settings.blip.texture)
	texture:SetTexCoord(WXP_Settings.blip.texoffset.x1, WXP_Settings.blip.texoffset.x2,WXP_Settings.blip.texoffset.y1,WXP_Settings.blip.texoffset.y2)
	
	local fontstring = frame:CreateFontString("WXP_Text_"..id,"ARTWORK","GameFontNormal")
	
	self.free = false
	self.id = id
	self.orientation = "right"
	self.frame = frame
	self.texture = texture
	self.fontstring = fontstring
	
	tinsert(WXPBlip.instances, self)
	return self
end

function WXPBlip.GetFree()	-- Get the first free blip, or create one if none are free
	WXP.Debug("|cffff0080[Blip]|r Finding first free blip")
	for i,blip in ipairs(WXPBlip.instances) do
		if blip.free then
			WXP.Debug("|cffff0080[Blip]|r Blip #"..i, "is free")
			blip.free = false
			return blip
		end
	end
	
	-- None free, so create a new blip
	WXP.Debug("|cffff0080[Blip]|r No free blips, creating a new one")
	return WXPBlip.new()
end

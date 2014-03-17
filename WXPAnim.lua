WXPAnim = {}
WXPAnim.debug = "|cffff0080[Anim]|r"

function WXPAnim.GetDuration(distance)		-- Return the number of seconds an animation with a given distance should run
	return distance / (100+distance/5)
end

function WXPAnim.GetEase(x)					-- Converts animation:GetProgress() to an ease-in-out progress, because animation:GetSmoothProgress() doesn't exist?
	return x*x*(3-2*x)
end

function WXPAnim.OnUpdate(self)
	WXP.Debug(WXPAnim.debug, "Animation finished")
	self:SetScript("OnUpdate", nil)
	self.blip.animation = nil
	self.blip.marker:Redraw(false)
	WXPMarker.RedrawAll()
end

function WXPAnim.GetCurrentOffset(animation)
	local progress = animation.translation:GetSmoothProgress()
	local xoff = animation.translation:GetOffset()
	xoff = xoff / WXP_Frame:GetEffectiveScale()
	
	local _,_,_,animxoff = animation:GetParent():GetPoint("CENTER")
	WXP.Debug(WXPAnim.debug, "    Distance this animation was to move: " .. xoff)
	WXP.Debug(WXPAnim.debug, "    Animation progress: " .. progress)
	WXP.Debug(WXPAnim.debug, "    Which means current offset is: " .. xoff * progress)
	return xoff * progress + (animxoff)
end

function WXPAnim.GetDistance(oldxp, oldxpmax, newxp, newxpmax) -- Returns how far (in scaled pixels) the animation needs to slide
	local oldpos = WXP_Frame:GetWidth() * (oldxp / oldxpmax)
	local newpos = WXP_Frame:GetWidth() * (newxp / newxpmax)
	return (newpos-oldpos) * WXP_Frame:GetEffectiveScale()
end

WXPAnim = {}

function WXPAnim.AnimTime(distance)		-- Return the number of seconds an animation with a given distance should run
	return distance / (100+distance/5)
end

function WXPAnim.GetEase(x)				-- Converts animation:GetProgress() to an ease-in-out progress, because animation:GetSmoothProgress() doesn't exist?
	return x*x*(3-2*x)
end

function WXPAnim.OnAnimationFinished(blip) -- Don't use this, make it an inline function in marker:Update
	-- Schedule the redraw for one frame from now, instead of now, due to a blizzard bug
	-- anim:OnFinished runs DURING the last animation frame instead of AFTER it, so moving the frame during the event causes a one-frame position flicker
	blip.frame:SetScript("OnUpdate", function(frame) WXPAnim.OnUpdate(frame.blip) end)
end

function WXPAnim.OnUpdate(blip)
	blip.frame:SetScript("OnUpdate", nil)
	blip.fontstring:Hide() -- Hide the label, then show it again in Redraw() to avoid a problem with it flickering too far to the right
	blip.marker:Redraw(false, true)
	WXPMarker.RedrawAll()
end

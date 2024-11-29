local orig = FangsHeist.require "Modules/Variables/net"

function FangsHeist.isMode()
	return gametype == GT_FANGSHEIST or (gamestate == GS_LEVEL and not multiplayer)
end

function FangsHeist.isPlayerAlive(p)
	return p and p.mo and p.mo.health and p.heist and not p.heist.spectator
end

function FangsHeist.isPlayerAtGate(p)
	local exit = FangsHeist.Net.exit

	local dist = R_PointToDist2(p.mo.x, p.mo.y, exit.x, exit.y)
	local heightdist = abs(p.mo.z-exit.z)

	if dist < 128*FU
	and heightdist < 200*FU then
		return true
	end
	
	return false
end

function FangsHeist.canUseAbility(p)
	if not FangsHeist.isMode() then
		return true
	end

	if not (p and p.heist) then
		return true
	end

	if not FangsHeist.playerHasSign(p) then
		return true
	end

	return false
end

local HURRY_LENGTH = 2693

// Check if the time is in the "Hurry Up" segment.
function FangsHeist.isHurryUp()
	if not FangsHeist.Net.escape then
		return false
	end

	local choice = FangsHeist.Net.escape_choice or 1

	if not (FangsHeist.escapeThemes[choice][2]) then
		return false
	end

	if (orig.time_left-FangsHeist.Net.time_left)*MUSICRATE/TICRATE > HURRY_LENGTH then
		return false
	end

	return true
end

function FangsHeist.isPlayerUnconscious(p)
	return p and p.heist and not (p.heist.conscious_meter)
end
function FangsHeist.isPlayerPickedUp(p)
	return FangsHeist.isPlayerUnconscious(p) and p.heist.picked_up_by and p.heist.picked_up_by.valid
end
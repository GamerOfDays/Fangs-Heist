states[freeslot "S_FH_PANIC"] = {
	sprite = SPR_PLAY,
	frame = SPR2_CNT1,
	tics = 4,
	nextstate = S_FH_PANIC
}

// Handle player hook.
addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end

	if not (p and p.heist) then
		FangsHeist.initPlayer(p)
	end

	if FangsHeist.Net.escape then
		if p.mo.state == S_PLAY_STND then
			p.mo.state = S_FH_PANIC
		end
		if p.mo.state == S_FH_PANIC then
			if FixedHypot(p.rmomx, p.rmomy) then
				p.mo.state = S_PLAY_WALK
			end
		end
	end
end)

local function return_score(mo)
	if mo.flags & MF_MONITOR then
		return 12
	end

	if mo.flags & MF_ENEMY then
		return 35
	end

	return 0
end

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end

	if not (s and s.player and s.player.heist) then return end

	s.player.heist.scraps = $+return_score(t)
end)
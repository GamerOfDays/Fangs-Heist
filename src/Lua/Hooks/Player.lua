local dialogue = FangsHeist.require "Modules/Handlers/dialogue"
local fang = FangsHeist.require "Modules/Movesets/fang"

local ringsling = FangsHeist.require "Modules/Handlers/ringsling"
local weaponmenu = FangsHeist.require"Modules/Handlers/weaponmenu"

FangsHeist.panicBlacklist = {
	takisthefox = true
}

states[freeslot "S_FH_PANIC"] = {
	sprite = SPR_PLAY,
	frame = SPR2_CNT1,
	tics = 4,
	nextstate = S_FH_PANIC
}

// Handle player hook.
addHook("PlayerThink", function(p)
	if not FangsHeist.isMode() then return end
	if not (p and p.valid) then return end

	if not (p and p.heist) then
		FangsHeist.initPlayer(p)
	end

	if p.heist.spectator then
		p.heist.treasure_time = 0
		return
	end

	p.charflags = $ & ~SF_DASHMODE
	p.heist.treasure_time = max(0, $-1)

	fang.playerThinker(p)
	fang.kickThinker(p)

	if p.heist.weapon
	and p.mo.health
	and not P_PlayerInPain(p)
	and p.rings
	and p.cmd.buttons & BT_ATTACK
	and not (p.lastbuttons & BT_ATTACK) then
		ringsling.fireRing(p, p.heist.weapon)
	end

	if p.heist.weapon_cooldown then
		p.heist.weapon_cooldown = max(0, $-1)
	end

	if leveltime % TICRATE*5 == 0 then
		local count = #p.heist.treasures

		p.heist.generated_profit = min(1000, $+4*count)
	end

	if FangsHeist.Net.escape
	and not FangsHeist.panicBlacklist[p.mo.skin] then
		if p.mo.state == S_PLAY_STND then
			p.mo.state = S_FH_PANIC
		end
		if p.mo.state == S_FH_PANIC then
			if FixedHypot(p.rmomx, p.rmomy) then
				p.mo.state = S_PLAY_WALK
			end
		end
	end

	weaponmenu(p)

	if not (p.heist.exiting) then
		p.score = FangsHeist.returnProfit(p)
	end
end)


addHook("ThinkFrame", do
	if not FangsHeist.isMode() then return end

	for p in players.iterate do
		if not (p and p.heist) then continue end

		if p.heist.spectator then
			if p.mo then
				if p.mo.health then
					p.spectator = true
				end
				continue
			end

			p.spectator = true
			continue
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

	if t.flags & MF_ENEMY then
		s.player.heist.enemies = $+1
	end
	if t.flags & MF_MONITOR then
		s.player.heist.monitors = $+1
	end
end)

addHook("MobjDeath", function(t,i,s)
	if not FangsHeist.isMode() then return end
	if not FangsHeist.Net.escape then return end
	if not (t and t.player and t.player.heist) then return end

	t.player.heist.spectator = true
end, MT_PLAYER)

addHook("ShouldDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end
	

	if t.player.heist.exiting then
		return false
	end

	if i
	and i.valid
	and i.type == MT_CORK then
		if t.player.powers[pw_flashing] then
			return false
		end
		if t.player.powers[pw_invulnerability] then
			return false
		end
	end
end, MT_PLAYER)

addHook("MobjDamage", function(t,i,s,dmg,dt)
	if not FangsHeist.isMode() then return end
	if not (t and t.player and t.player.heist) then return end

	for _,tres in pairs(t.player.heist.treasures) do
		if not (tres.mobj.valid) then continue end

		local angle = FixedAngle(P_RandomRange(1, 360)*FU)

		P_InstaThrust(tres.mobj, angle, 12*FU)
		P_SetObjectMomZ(tres.mobj, 4*FU)

		tres.mobj.target = nil
	end
	t.player.heist.treasures = {}

	if dt & DMG_DEATHMASK then return end

	if s
	and s.player
	and s.player.heist then
		if FangsHeist.playerHasSign(t.player) then
			FangsHeist.giveSignTo(s.player)
		end

		if not (t.player.rings)
		and not (t.player.powers[pw_shield]) then
			s.player.heist.deadplayers = $+1
		else
			s.player.heist.hitplayers = $+1
		end
	end

	if t.player.powers[pw_shield] then return end
	if not t.player.rings then return end


	local rings_spill = min(5, t.player.rings)

	S_StartSound(t, sfx_s3kb9)

	P_PlayerRingBurst(t.player, rings_spill)
	
	t.player.rings = $-rings_spill
	t.player.powers[pw_shield] = 0

	P_DoPlayerPain(t.player, s, i)

	return true
end, MT_PLAYER)

// UNUSED
local function thokNerf(p)
	local speed = FixedHypot(p.rmomx, p.rmomy)
	local angle = (p.cmd.angleturn<<16)+R_PointToAngle2(0, 0, p.cmd.forwardmove*FU, -p.cmd.sidemove*FU)

	P_InstaThrust(p.mo, angle, max(speed, 12*p.mo.scale))
	p.pflags = $|PF_THOKKED & ~PF_JUMPED
	p.mo.state = S_PLAY_FALL
	P_SpawnThokMobj(p)
	S_StartSound(p.mo, sfx_thok)
end

addHook("ShieldSpecial", function(p)
	if not FangsHeist.isMode() then return end

	if fang.isGunslinger(p) then
		return true
	end
end)

addHook("AbilitySpecial", function (p)
	if FangsHeist.canUseAbility(p)
	and FangsHeist.isPlayerAlive(p)
	and p.charability == CA_THOK
	and not (p.pflags & PF_THOKKED) then
		p.actionspd = 40*FU
	end

	if FangsHeist.canUseAbility(p)
	and FangsHeist.isPlayerAlive(p)
	and not (p.pflags & PF_THOKKED)
	and fang.isBounce(p) then
		fang.doAirKick(p)
		return true
	end

	return not FangsHeist.canUseAbility(p)
end)
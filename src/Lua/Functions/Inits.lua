local files = {}
// Used internally to get modules from the mod.
function FangsHeist.require(path)
	if not (files[path]) then
		files[path] = dofile(path)
	end

	return files[path]
end

local copy = FangsHeist.require "Modules/Libraries/copy"
local spawnpos = FangsHeist.require "Modules/Libraries/spawnpos"

local orig_net = FangsHeist.require "Modules/Variables/net"
local orig_plyr = FangsHeist.require "Modules/Variables/player"
local orig_hud = FangsHeist.require "Modules/Variables/hud"

// Initalize player.
function FangsHeist.initPlayer(p)
	p.heist = copy(orig_plyr)
	p.heist.spectator = FangsHeist.Net.escape
end

function FangsHeist.initMode()
	FangsHeist.Net = copy(orig_net)
	FangsHeist.HUD = copy(orig_hud)

	for p in players.iterate do
		p.camerascale = FU
		FangsHeist.initPlayer(p)
	end

	for _,obj in ipairs(FangsHeist.Objects) do
		local object = obj[2]

		if object.init then
			object.init()
		end
	end
end

function FangsHeist.loadMap()
	if FangsHeist.spawnSign() then
		print "Spawned sign!"
	end

	local exit = false
	for thing in mapthings.iterate do
		if thing.mobj
		and thing.mobj.valid
		and thing.mobj.type == MT_ATTRACT_BOX then
			P_RemoveMobj(thing.mobj)
		end

		if thing.type == 1
		and not exit then
			local x = thing.x*FU
			local y = thing.y*FU
			local z = spawnpos.getThingSpawnHeight(MT_FH_SIGN, thing, x, y)
			local a = FixedAngle(thing.angle*FU)

			FangsHeist.defineExit(x, y, z, a)
			exit = true
		end
	end
end
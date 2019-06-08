--[[function Spiral(X, Y)
    local x = 0
    local y = 0
    local dx = 0
    local dy = -1;
    local t = math.max(X, Y);
    local maxI = t * t;

    for i = 0, maxI, 1 do
        if ((-X/2 <= x) and (x <= X/2) and (-Y/2 <= y) and (y <= Y/2)) then
            table.insert(pathway, 
            {
            	x = x,
            	y = y,
            	z = 503,
            	id = i
            })
        end

        if( (x == y) or ((x < 0) and (x == -y)) or ((x > 0) and (x == 1-y))) then
            t = dx;
            dx = -dy;
            dy = t;
        end

        x = x + dx;
        y = y + dy;
    end

    coroutine.yield()
end

local tick = getTickCount()
local co = coroutine.create(Spiral)
coroutine.resume(co, 100, 100)

if ( fileExists("nodes.lua") ) then
	fileDelete("nodes.lua")
end

local file = fileCreate("nodes.lua")

fileWrite(file, "local pathway = {}\n\n")

if (file) then
	for index, node in ipairs(pathway) do
		fileWrite(file, "pathway[" .. index .. "] = { x = " .. node.x .. ", y = " .. node.y .. ", z = " .. node.z ..", id = " .. node.id .. "}\n")
	end

	fileClose(file);
end


outputDebugString("Done (".. ((getTickCount() - tick ) / 1000) .. " seconds)")
]]--

--[[
local valid_node_func = function ( node, neighbor ) 

	local MAX_DIST = 4
		
	if distance( node.x, node.y, 503, neighbor.x, neighbor.y, 503 ) < MAX_DIST then
		--Check here if nodes are obstructed
		return true
	end
	return false
end

local paths = path ( pathway[1], pathway[2], pathway, true, valid_node_func )
local tick = getTickCount()

function renderPath()
	local seconds = ( getTickCount() - tick ) / 1000

	if ( seconds > 5 ) then
		local x, y, z = getElementPosition(localPlayer)
		local node = nearest_node(x, y, z)

		paths = path ( pathway[1], node, pathway, true, valid_node_func )
		tick = getTickCount()
	end

	if not paths then
		dxDrawText("NO PATH", 300, 300)
	else
		for i, node in ipairs ( paths ) do
			if ( paths[i+1] ) then
				local neighbor = paths[i+1];

				dxDrawLine3D( node.x, node.y, node.z, neighbor.x, neighbor.y, neighbor.z, tocolor(255,200,0,200), 1.0)
			end
		end
	end

	dxDrawText(#paths, 300, 320)
end

addEventHandler("onClientPreRender", root, renderPath)
]]--

addEvent("pathfinding:onPedDamage", true)

nodeList = {}

local debugTimer
local paths = {}
local maxZombies = 30
local currentZombies = 0

function onResourceStart(resource)

	local nodes = getElementsByType("node", source)

	if ( #nodes > 0 ) then
		outputDebugString("Found " .. #nodes .. " nodes in resource " .. getResourceName(resource) .. ".")
		addNodesToList(nodes)
	end
end

function addNodesToList(nodes)

	for index, node in ipairs(nodes) do
		nodeList[index] = {}
		
		nodeList[index].id = index
		nodeList[index].x = node:getData("posX")
		nodeList[index].y = node:getData("posY")
		nodeList[index].z = node:getData("posZ")
	end

	triggerClientEvent(root, "pathfinding:sendNodesToClient", resourceRoot, nodeList)

	--test
	spawnTestDummy()
end

local valid_node_func = function ( node, neighbor ) 

	local MAX_DIST = 6
		
	if distance( node.x, node.y, node.z, neighbor.x, neighbor.y, node.z ) <= MAX_DIST then
		return true
	end
	return false
end

function calculatePath( zombie, endX, endY, endZ )
	
	local startX, startY, startZ = getElementPosition(zombie)
	local startNode = nearest_node( startX, startY, startZ )
	local endNode = nearest_node( endX + math.random( 1, 3 ), endY - math.random( 1, 3 ), endZ )
	local currentDistance = getDistanceBetweenPoints3D( startX, startY, startZ, endX, endY, endZ )

	if ( currentDistance <= 7 ) then
		return false
	end

	if ( startNode and endNode ) then
		local newPath = path( startNode, endNode, nodeList, true, valid_node_func )

		if ( newPath and #newPath > 0 ) then
			local zombieId = zombie:getData("zombieId")
			zombie:setData("targetNode", 1)

			paths[zombie] = newPath

			--triggerClientEvent(root, "pathfinding:sendPathToClient", resourceRoot, zombieId, newPath)
		else
			outputDebugString("Could not determine path")
		end
	end
end

local updateTimer = nil
local zombieSpawns = {
	{ -164.3929, 25.62389, 503.249664 },
	{ -125.14426, 4.6317, 503.309631 },
	{ -85.36963, 25.11468, 503.167877 },
	{ -60.26727, 64.3479, 503.358673 },
	{ -72.54577, 103.91753, 502.73703 },
	{ -104.5975, 127.43274, 502.920776 },
	{ -146.86301, 134.76721, 502.916046 }
}

function spawnTestDummy()

	if ( currentZombies >= maxZombies ) then
		return false
	end

	for i, spawn in ipairs(zombieSpawns) do
		local x, y, z = unpack(zombieSpawns[i])
		local nearestNode = nearest_node( x, y, z )

		local dummy = createPed(math.random(115, 118), nearestNode.x + math.random( 2, 4 ), nearestNode.y - math.random( 2, 4 ), nearestNode.z + 2)
		--giveWeapon(dummy, 31, 9999, true)
		dummy:setData("zombie", true)
		dummy:setData("zombieId", i)
		dummy:setData("fired", false)

		currentZombies = currentZombies + 1
	end

	if ( not updateTimer ) then
		updateTimer = setTimer(onZombieUpdate, 250, 0)
		setTimer(spawnTestDummy, 2500, 0)
	end
end

function onZombieUpdate()

	for i, ped in ipairs(getElementsByType("ped")) do
		if ( ped:getData("zombie")) then
			if ( findZombieTarget(ped) ) then
				updateZombieMovement(ped)
			end
		end
	end
end

function findZombieTarget(zombie)

	local zx, zy, zz = getElementPosition(zombie)
	local nearestPlayer = getNearestPlayer(zx, zy, zz)

	if ( isElement(nearestPlayer) ) then
		zombie:setData("target", nearestPlayer, true)
		return true
	end

	return false
end

function updateZombieMovement(zombie)
	local target = zombie:getData("target")

	if ( not isElement(target)) then
		zombie:setData("target", nil)

		return false
	end

	local px, py, pz = getElementPosition(target)

	if ( isElement(target)) then
		local zombieEndNode = nil
		local nx, ny, nz = nil, nil, nil
		local distance = 0

		if ( paths[zombie] ) then
			zombieEndNode = paths[zombie][#paths[zombie]]
			nx, ny, nz = zombieEndNode.x, zombieEndNode.y, zombieEndNode.z
			distance = getDistanceBetweenPoints3D(px, py, pz, nx, ny, nz)
		end

		if ( not zombie:getData("targetNode") or distance >= 7 )then
			calculatePath( zombie, px, py, pz )
		end
	end

	if ( paths[zombie] ) then
		for _, node in ipairs(paths[zombie]) do
			local targetNode = zombie:getData("targetNode")

			if (paths[zombie][targetNode]) then
				local tx, ty, tz = paths[zombie][targetNode].x, paths[zombie][targetNode].y, paths[zombie][targetNode].z
				local sx, sy, sz = getElementPosition(zombie)
				local rz = findRotation(sx, sy, tx, ty)
				local nodeDistance = getDistanceBetweenPoints3D(sx, sy, sz, tx, ty, tz)

				zombie:setRotation( 0, 0, rz )
				zombie:setAnimation("PED", "RUN_CIVI")

				if ( nodeDistance < 2 and paths[zombie][targetNode+1]) then
					zombie:setData("targetNode", targetNode+1)
				elseif ( not paths[zombie][targetNode+1] ) then
					local distance = getDistanceBetweenPoints3D(px, py, pz, sx, sy, sz)

					zombie:setAnimation(false)
					zombie:setData("targetNode", nil)
					zombie:setData("targetPlayer", target)
				end
			end

			if ( zombie:getData("targetPlayer")) then
				local x, y, z = getElementPosition(zombie:getData("targetPlayer"))
				local zx, zy, zz = getElementPosition(zombie)
				local rz = findRotation(zx, zy, x, y)
				local distance = getDistanceBetweenPoints3D(x, y, z, zx, zy, zz)

				if( distance > 1.5 and distance <= 7 ) then
					zombie:setAnimation("PED", "RUN_CIVI")
				elseif ( distance <= 1.5 ) then
					local fired = zombie:getData("fired")
					local pHealth = getElementHealth(target)

					if ( pHealth > 0 ) then
						setElementRotation(zombie, 0, 0, rz)
						zombie:setAnimation(false)
						setElementHealth(target, math.max(0, getElementHealth(target) - 1))

						triggerClientEvent(root, "pathfinding:onPedWeaponFire", zombie, target, fired)
						zombie:setData("fired", not fired)
					else
						--todo, start idling
					end
				elseif ( distance > 7 ) then
					zombie:setData("targetPlayer", nil)
				end

				setElementRotation(zombie, 0, 0, rz)
			end
		end
	end
end

function getNearestPlayer(x, y, z)

	local distanceToBeat = 9999
	local selectedPlayer = nil

	for _, player in ipairs(getElementsByType("player")) do
		local px, py, pz = getElementPosition(player)
		local distance = getDistanceBetweenPoints3D(x, y, z, px, py, pz)

		if ( distance < distanceToBeat ) then
			distanceToBeat = distance
			selectedPlayer = player
		end
	end

	return selectedPlayer or nil
end

function findRotation( x1, y1, x2, y2 ) 
    local t = -math.deg( math.atan2( x2 - x1, y2 - y1 ) )
    return t < 0 and t + 360 or t
end

function onPedDamage(ped, attacker, weapon, bodypart)
	if ( ped:getData("zombie")) then
		local health = getElementHealth(ped)
		
		if ( bodypart == 9 ) then
			setPedHeadless(ped, true)
			killPed(ped, attacker, weapon)
		end

		if ( health > 0 ) then
			setElementHealth(ped, health - math.random(40, 80))
		end
	end
end

setTimer(function()
	for i,v in ipairs(getElementsByType("ped")) do
		if ( v:getData("zombie") and v.health <= 0 ) then
			outputDebugString("wasted");
			v:setData("zombie", false)
			v:setData("target", false)
			v:setData("targetNode", false)
			v:setCollisionsEnabled(false)
			paths[v] = nil

			currentZombies = currentZombies - 1
		end
	end
end, 1234, 0)

setTimer(function()
	local bodyCount = 0

	for i,v in ipairs(getElementsByType("ped")) do
		if ( v.health <= 0 ) then
			destroyElement(v)
			outputDebugString("Removed dead bodies");

			--bodyCount = bodyCount + 1
		end
	end

	--currentZombies = currentZombies - bodyCount
end, 60000, 0)

addEventHandler("pathfinding:onPedDamage", root, onPedDamage)
addEventHandler("onResourceStart", root, onResourceStart)
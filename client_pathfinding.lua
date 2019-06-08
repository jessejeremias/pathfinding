addEvent("pathfinding:sendNodesToClient", true)
addEvent("pathfinding:sendPathToClient", true)
addEvent("pathfinding:onPedWeaponFire", true)

local nodeList = {}
local path = {}
local pathCount = 0

function onSendNodesToClient(nodes)

	if ( #nodes > 0 ) then
		nodeList = nodes
	end

	outputChatBox("Received " .. #nodes .. " from server.")
end

function onSendPathToClient(zombieId, newPath)

	if ( #newPath > 0 ) then
		path[zombieId] = newPath
	end
end

function onClientPreRender()

	if ( #nodeList > 0 ) then
		for zombieId, zombiePath in ipairs(path) do
			for _, node in ipairs(zombiePath) do
				local nodeId, nodeX, nodeY, nodeZ = node.id, node.x, node.y, node.z
				local screenX, screenY = getScreenFromWorldPosition( nodeX, nodeY, nodeZ + 1 )

				if ( screenX ) then
					dxDrawLine3D( nodeX, nodeY, nodeZ + 1, nodeX, nodeY, nodeZ - 3, tocolor( 255, 255, 255, 255 ), 2 )
					dxDrawText( "#" .. nodeId, screenX, screenY, screenX, screenY, tocolor( 255, 255, 255, 255 ), 0.8, "default-bold", "center", "center" )
				end
			end
		end
	end

	-- Renders path
	if ( path ) then
		dxDrawText("render path", 300, 300)
	end
end

addEventHandler("onClientPreRender", root,
	function()

		local px, py, pz = getElementPosition(localPlayer)
		local nodes = getElementsByType("node")
		local nodeCount = 0;

		for i, node in ipairs(nodes) do
			local nx, ny, nz = getElementPosition(node)
			local playerDistance = getDistanceBetweenPoints3D(px, py, pz, nx, ny, nz)

			if ( playerDistance <= 20 ) then
				-- If a player is close to a node, retrieve all neighbour nodes from selected node
				for nIndex, nNode in ipairs(nodes) do
					local nodeX, nodeY, nodeZ = getElementPosition(nNode)
					local neighbourDistance = getDistanceBetweenPoints3D(nx, ny, nz, nodeX, nodeY, nodeZ)

					if ( neighbourDistance <= 6 ) then
						dxDrawLine3D(nx, ny, nz - 0.4, nodeX, nodeY, nodeZ - 0.4, tocolor(0, 255, 0, 20), 5.0)
					end
				end
			end

			nodeCount = nodeCount + 1
		end

		dxDrawText(nodeCount, 300, 300)
	end)

addEventHandler("onClientPedDamage", root,
	function(attacker, weapon, bodypart)
		triggerServerEvent("pathfinding:onPedDamage", root, source, attacker, weapon, bodypart)
	end)

function onPedWeaponFire(target, state)
	setPedControlState(source, "fire", state)
	setPedControlState(source, "fire", not state)
end


addEventHandler("onClientPreRender", root, onClientPreRender)
addEventHandler("pathfinding:sendNodesToClient", root, onSendNodesToClient)
addEventHandler("pathfinding:sendPathToClient", root, onSendPathToClient)
addEventHandler("pathfinding:onPedWeaponFire", root, onPedWeaponFire)
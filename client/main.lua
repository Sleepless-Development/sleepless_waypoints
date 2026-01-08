local Waypoint = require 'client.modules.Waypoint'
local config = require 'config'

-------------------------------------------------
-- Main Render Loops
-------------------------------------------------
local shouldRender = {}
local currentlyRendering = {}
local drawRunning = false

local function drawLoop()
    if drawRunning then return end
    drawRunning = true

    CreateThread(function()
        while #shouldRender > 0 do
            local camPos = GetFinalRenderedCamCoord()
            local playerPos = GetEntityCoords(cache.ped)

            for i = 1, #shouldRender do
                local waypoint = shouldRender[i]
                Waypoint.render(waypoint, camPos, playerPos)
            end

            Wait(0)
        end

        drawRunning = false
    end)
end

local currentWayPointMarker = nil
CreateThread(function()
    while true do
        if config.syncToWayPoint then
            if not currentWayPointMarker and IsWaypointActive() then
                local blipCoord = GetBlipInfoIdCoord(GetFirstBlipInfoId(8))

                currentWayPointMarker = Waypoint.create({
                    coords = blipCoord,
                    type = config.mapWaypoint.type,
                    label = config.mapWaypoint.label,
                    color = config.mapWaypoint.color,
                    size = config.mapWaypoint.size,
                    drawDistance = config.mapWaypoint.drawDistance,
                })
            elseif not IsWaypointActive() and currentWayPointMarker then
                Waypoint.remove(currentWayPointMarker)
                currentWayPointMarker = nil
            end
        end


        local newShouldRender = {}
        local newCurrentlyRendering = {}
        local camPos = GetFinalRenderedCamCoord()

        local waypointArray = Waypoint.getArray()

        for i = 1, #waypointArray do
            local waypoint = waypointArray[i]
            if Waypoint.shouldRender(waypoint, camPos) then

                if not waypoint.isRendering then
                    Waypoint.acquireForRendering(waypoint)
                end

                if waypoint.isRendering then
                    newShouldRender[#newShouldRender + 1] = waypoint
                    newCurrentlyRendering[waypoint.id] = true
                end
            end
        end

        local releasedCount = 0
        for id, _ in pairs(currentlyRendering) do
            if not newCurrentlyRendering[id] then
                local waypoint = Waypoint.get(id)
                if waypoint then
                    Waypoint.releaseFromRendering(waypoint)
                    releasedCount = releasedCount + 1
                end
            end
        end

        local prevCount = #shouldRender
        if #newShouldRender ~= prevCount or releasedCount > 0 then
            lib.print.debug(('[RENDER LOOP] Visible: %d | Released: %d | Total waypoints: %d'):format(
                #newShouldRender,
                releasedCount,
                #waypointArray
            ))
        end

        shouldRender = newShouldRender
        currentlyRendering = newCurrentlyRendering

        if #shouldRender > 0 and not drawRunning then
            drawLoop()
        end

        Wait(config.rendering.updateInterval)
    end
end)

-------------------------------------------------
-- Exports
-------------------------------------------------
exports('create', Waypoint.create)
exports('update', Waypoint.update)
exports('remove', Waypoint.remove)
exports('removeAll', Waypoint.removeAll)
exports('get', Waypoint.get)

-------------------------------------------------
-- Server Event Handlers
-------------------------------------------------

-- Maps server waypoint IDs to client waypoint IDs
local serverToClientId = {}

RegisterNetEvent('sleepless_waypoints:create', function(serverId, data)
    local clientId = Waypoint.create(data)
    serverToClientId[serverId] = clientId
end)

RegisterNetEvent('sleepless_waypoints:update', function(serverId, data)
    local clientId = serverToClientId[serverId]
    if clientId then
        Waypoint.update(clientId, data)
    end
end)

RegisterNetEvent('sleepless_waypoints:remove', function(serverId)
    local clientId = serverToClientId[serverId]
    if clientId then
        Waypoint.remove(clientId)
        serverToClientId[serverId] = nil
    end
end)

RegisterNetEvent('sleepless_waypoints:removeAll', function()
    Waypoint.removeAll()
    serverToClientId = {}
end)

-------------------------------------------------
-- Cleanup
-------------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then
        Waypoint.removeAll()
    end
end)

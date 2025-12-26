local utils = require 'client.modules.utils'
local config = require 'config'

---@class WaypointManager
local WaypointManager = {}

---@type table<number, WaypointInstance>
local waypointsById = {}
local idToIndex = {} -- maps waypoint id -> array index
local waypointArray = {}
local waypointId = 0

-- DUI Pool Management
local poolAvailable = {}
local poolInUse = {}
local poolNextId = 0
local waitingForDuiLoad = {}

RegisterNUICallback('load', function(data, cb)
    local id = tonumber(data.id)
    waitingForDuiLoad[id] = nil
    cb({})
end)

--- Creates a new DUI instance
---@param id number The ID to use for this DUI
---@return table duiInstance The created DUI wrapper
local function createDui(id)
    local dui = lib.dui:new({
        url = ('nui://%s/web/index.html'):format(cache.resource),
        width = config.dui.width,
        height = config.dui.height,
        debug = false
    })

    waitingForDuiLoad[id] = true

    while waitingForDuiLoad[id] do
        dui:sendMessage({ action = 'load', id = id })
        Wait(100)
    end

    return {
        id = id,
        dui = dui,
    }
end

--- Resets a DUI to its default state for reuse
---@param duiWrapper table The DUI wrapper to reset
local function resetDui(duiWrapper)
    local dui = duiWrapper.dui
    dui:sendMessage({ action = 'reset' })
end

--- Acquire a DUI from the pool (creates new one if pool is empty)
---@return table duiWrapper The acquired DUI wrapper
---@return number id The ID of the acquired DUI
local function acquireDui()
    if #poolAvailable > 0 then
        local duiWrapper = table.remove(poolAvailable)
        poolInUse[duiWrapper.id] = duiWrapper
        lib.print.debug('Acquired pooled DUI', duiWrapper.id, '- Available:', #poolAvailable)
        return duiWrapper, duiWrapper.id
    end

    poolNextId = poolNextId + 1
    local id = poolNextId
    local duiWrapper = createDui(id)
    poolInUse[id] = duiWrapper

    lib.print.debug('Created new DUI', id, '(pool will grow as needed)')
    return duiWrapper, id
end

---@param id number The ID of the DUI to release
local function releaseDui(id)
    local duiWrapper = poolInUse[id]
    if not duiWrapper then
        lib.print.debug('Attempted to release unknown DUI', id)
        return
    end

    poolInUse[id] = nil

    resetDui(duiWrapper)
    poolAvailable[#poolAvailable + 1] = duiWrapper
    lib.print.debug('Released DUI', id, 'back to pool - Available:', #poolAvailable)
end

--- Cleanup all DUIs (call on resource stop)
local function cleanupPool()
    lib.print.debug('Cleaning up DUI pool...')

    for id, duiWrapper in pairs(poolInUse) do
        duiWrapper.dui:remove()
    end
    poolInUse = {}

    for _, duiWrapper in ipairs(poolAvailable) do
        duiWrapper.dui:remove()
    end
    poolAvailable = {}

    lib.print.debug('DUI pool cleanup complete')
end

print('Sleepless Waypoints - Client started')

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == cache.resource then
        cleanupPool()
    end
end)

function WaypointManager.create(data)
    waypointId = waypointId + 1
    local id = waypointId

    local waypointType = data.type or 'small'

    local duiWrapper, duiId = acquireDui()
    if not duiWrapper then
        lib.print.error('Failed to acquire DUI from pool for waypoint', id)
        return nil
    end

    local dui = duiWrapper.dui
    dui:sendMessage({ action = 'setType', type = waypointType })

    if data.color then
        dui:sendMessage({ action = 'setColor', color = data.color })
    end

    if data.label then
        dui:sendMessage({ action = 'setLabel', text = data.label })
    end

    if data.icon then
        dui:sendMessage({ action = 'setIcon', icon = data.icon })
    end

    if data.image then
        dui:sendMessage({ action = 'setImage', url = data.image })
    end

    if data.displayDistance == nil then
        data.displayDistance = true
    end

    dui:sendMessage({ action = 'showDistance', show = data.displayDistance })

    local waypoint = {
        id = id,
        data = {
            coords = data.coords,
            type = waypointType,
            color = data.color or config.defaults.color,
            label = data.label or config.defaults.label,
            icon = data.icon,
            size = data.size or config.defaults.size,
            drawDistance = data.drawDistance or config.defaults.drawDistance,
            fadeDistance = data.fadeDistance or config.defaults.fadeDistance,
            minHeight = data.minHeight or config.defaults.minHeight,
            maxHeight = data.maxHeight or config.defaults.maxHeight,
            groundZ = data.groundZ or (data.coords.z + config.defaults.groundZOffset),
            removeDistance = data.removeDistance,
            displayDistance = data.displayDistance,
        },
        dui = dui,
        duiId = duiId,
        active = true,
    }

    local index = #waypointArray + 1
    waypointArray[index] = waypoint
    waypointsById[id] = waypoint
    idToIndex[id] = index

    return id
end

function WaypointManager.update(id, data)
    local waypoint = waypointsById[id]
    if not waypoint then return end

    if data.coords then
        waypoint.data.coords = data.coords
    end

    if data.color then
        waypoint.data.color = data.color
        waypoint.dui:sendMessage({ action = 'setColor', color = data.color })
    end

    if data.label then
        waypoint.data.label = data.label
        waypoint.dui:sendMessage({ action = 'setLabel', text = data.label })
    end

    if data.icon then
        waypoint.data.icon = data.icon
        waypoint.dui:sendMessage({ action = 'setIcon', url = data.icon })
    end

    if data.size then waypoint.data.size = data.size end
    if data.drawDistance then waypoint.data.drawDistance = data.drawDistance end
    if data.fadeDistance then waypoint.data.fadeDistance = data.fadeDistance end
    if data.minHeight then waypoint.data.minHeight = data.minHeight end
    if data.maxHeight then waypoint.data.maxHeight = data.maxHeight end
    if data.groundZ then waypoint.data.groundZ = data.groundZ end
end

function WaypointManager.remove(id)
    local waypoint = waypointsById[id]
    if not waypoint then return end
    waypoint.active = false

    if waypoint.duiId then
        releaseDui(waypoint.duiId)
    end

    local index = idToIndex[id]
    local lastIndex = #waypointArray

    if index ~= lastIndex then
        local lastWaypoint = waypointArray[lastIndex]
        waypointArray[index] = lastWaypoint
        idToIndex[lastWaypoint.id] = index
    end

    waypointArray[lastIndex] = nil
    waypointsById[id] = nil
    idToIndex[id] = nil
end

function WaypointManager.removeAll()
    for i = #waypointArray, 1, -1 do
        local waypoint = waypointArray[i]
        if waypoint then
            WaypointManager.remove(waypoint.id)
        end
    end
end

function WaypointManager.get(id)
    return waypointsById[id]
end

function WaypointManager.getAll()
    return waypointsById
end

function WaypointManager.getArray()
    return waypointArray
end

function WaypointManager.shouldRender(waypoint, camPos)
    if not waypoint.active or not waypoint.dui then
        lib.print.debug('Waypoint inactive or missing dui:', waypoint.id)
        return false
    end

    local data = waypoint.data
    local camDist = #(camPos - data.coords)

    if camDist > data.drawDistance then
        lib.print.debug('Waypoint too far:', waypoint.id, camDist, data.drawDistance)
        return false
    end

    local onScreen, x, y

    if data.type == "checkpoint" then
        onScreen, x, y = GetScreenCoordFromWorldCoord(data.coords.x, data.coords.y, data.coords.z)
        if not onScreen then
            local markerCenterPos = vec3(data.coords.x, data.coords.y,
                data.groundZ + (data.size * config.rendering.checkpointBaseMultiplier))
            onScreen, x, y = GetScreenCoordFromWorldCoord(markerCenterPos.x, markerCenterPos.y, markerCenterPos.z)
        end
    else
        onScreen, x, y = GetScreenCoordFromWorldCoord(data.coords.x, data.coords.y, data.coords.z)
    end


    if onScreen ~= 1 then
        lib.print.debug('Waypoint off screen:', waypoint.id)
        return false
    end

    return true
end

function WaypointManager.render(waypoint, camPos, playerPos)
    if not waypoint.active or not waypoint.dui then return false end

    local success = pcall(IsDuiAvailable, waypoint.dui.duiObject)

    if not success then return false end

    local data = waypoint.data
    local camDist = #(camPos - data.coords)
    local playerDist = #(playerPos - data.coords)

    local alpha = 255
    if camDist > data.fadeDistance then
        local fadeRange = data.drawDistance - data.fadeDistance
        local fadeDist = camDist - data.fadeDistance
        alpha = math.floor(255 * (1 - (fadeDist / fadeRange)))
    end

    if not waypoint.dui.dictName or not waypoint.dui.txtName then return false end

    if data.displayDistance and (not waypoint.nextDistanceUpdate or GetGameTimer() >= waypoint.nextDistanceUpdate) and (waypoint.lastDistance ~= math.floor(playerDist)) then
        waypoint.nextDistanceUpdate = GetGameTimer() + config.rendering.distanceUpdateInterval
        waypoint.lastDistance = math.floor(playerDist)

        waypoint.dui:sendMessage({
            action = 'setDistance',
            value = tostring(math.floor(playerDist)),
            duration = config.rendering.distanceUpdateInterval
        })
    end

    if data.type == 'checkpoint' then
        local baseSize = data.size * config.rendering.checkpointBaseMultiplier
        local perspectiveScale = camDist / config.rendering.perspectiveDivisor
        local size = baseSize * math.max(config.rendering.checkpointMinScale, perspectiveScale)

        local quadWidth = size
        local quadHeight = size * config.rendering.checkpointAspectRatio
        local markerPos = vec3(data.coords.x, data.coords.y, data.groundZ)

        utils.drawTexturedTriangle(
            markerPos,
            quadWidth,
            quadHeight,
            255, 255, 255, alpha,
            waypoint.dui.dictName,
            waypoint.dui.txtName
        )
    else
        local baseSize = data.size * config.rendering.checkpointBaseMultiplier
        local perspectiveScale = camDist / config.rendering.perspectiveDivisor
        local size = baseSize * math.max(config.rendering.smallMinScale, perspectiveScale)
        local height = size * config.rendering.smallAspectRatio

        local markerPos = vec3(data.coords.x, data.coords.y, data.coords.z - (height / 2))

        utils.drawTexturedTriangle(
            markerPos,
            size,
            height,
            255, 255, 255, alpha,
            waypoint.dui.dictName,
            waypoint.dui.txtName
        )
    end

    if data.removeDistance and playerDist <= data.removeDistance then
        WaypointManager.remove(waypoint.id)
        lib.print.debug('Removed waypoint for being close:', waypoint.id)
        return false
    end

    return true
end

return WaypointManager

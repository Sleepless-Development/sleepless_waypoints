local WaypointManager = {}

local waypointId = 0

---@type table<number, table<number, boolean>>
local waypointsByPlayer = {}

---@type table<number, ServerWaypointEntry>
local waypointsById = {}

---@param target TargetType
---@param eventName string
---@param ... any
local function triggerWaypointEvent(target, eventName, ...)
    local fullEventName = ('sleepless_waypoints:%s'):format(eventName)

    if type(target) == 'number' then
        TriggerClientEvent(fullEventName, target, ...)
    elseif type(target) == 'table' then
        lib.triggerClientEvent(fullEventName, target, ...)
    end
end

---@param target TargetType
---@return number[]
local function resolveTargets(target)
    if target == -1 then
        local players = GetPlayers()
        local result = {}
        for i = 1, #players do
            result[i] = tonumber(players[i])
        end
        return result
    elseif type(target) == 'table' then
        return target
    else
        return { target }
    end
end

---@param target TargetType
---@param data WaypointData Waypoint data (coords, type, color, label, icon, size, etc.)
---@return number serverId The server-side waypoint ID
function WaypointManager.create(target, data)
    waypointId = waypointId + 1
    local id = waypointId

    waypointsById[id] = {
        target = target,
        data = data,
        clientIds = {},
    }

    local targets = resolveTargets(target)
    for i = 1, #targets do
        local playerId = targets[i]
        if not waypointsByPlayer[playerId] then
            waypointsByPlayer[playerId] = {}
        end
        waypointsByPlayer[playerId][id] = true
    end

    triggerWaypointEvent(target, 'create', id, data)

    return id
end

---@param id number The server-side waypoint ID
---@param data WaypointData The data to update (coords, color, label, icon, size, etc.)
function WaypointManager.update(id, data)
    local waypoint = waypointsById[id]
    if not waypoint then return end

    for key, value in pairs(data) do
        waypoint.data[key] = value
    end

    triggerWaypointEvent(waypoint.target, 'update', id, data)
end

---@param id number The server-side waypoint ID
function WaypointManager.remove(id)
    local waypoint = waypointsById[id]
    if not waypoint then return end

    triggerWaypointEvent(waypoint.target, 'remove', id)

    local targets = resolveTargets(waypoint.target)
    for i = 1, #targets do
        local playerId = targets[i]
        if waypointsByPlayer[playerId] then
            waypointsByPlayer[playerId][id] = nil
        end
    end

    waypointsById[id] = nil
end

---@param playerId? number Optional player server ID
function WaypointManager.removeAll(playerId)
    if playerId then
        local playerWaypoints = waypointsByPlayer[playerId]
        if playerWaypoints then
            for id in pairs(playerWaypoints) do
                local waypoint = waypointsById[id]
                if waypoint then
                    local targets = resolveTargets(waypoint.target)
                    if #targets == 1 then
                        waypointsById[id] = nil
                    end
                end
            end
            waypointsByPlayer[playerId] = nil
        end
        TriggerClientEvent('sleepless_waypoints:removeAll', playerId)
    else
        for id, waypoint in pairs(waypointsById) do
            triggerWaypointEvent(waypoint.target, 'remove', id)
        end
        waypointsById = {}
        waypointsByPlayer = {}
    end
end

---@param playerId number Player server ID
function WaypointManager.removeForPlayer(playerId)
    local playerWaypoints = waypointsByPlayer[playerId]
    if not playerWaypoints then return end

    for id in pairs(playerWaypoints) do
        local waypoint = waypointsById[id]
        if waypoint then
            local targets = resolveTargets(waypoint.target)
            if #targets == 1 then
                waypointsById[id] = nil
            end
        end
    end

    waypointsByPlayer[playerId] = nil
end

---@param id number The server-side waypoint ID
---@return ServerWaypointEntry? waypoint The waypoint data, or nil if not found
function WaypointManager.get(id)
    return waypointsById[id]
end

---@return table<number, ServerWaypointEntry> waypoints All waypoints indexed by server ID
function WaypointManager.getAll()
    return waypointsById
end

---@param playerId number Player server ID
---@return table<number, ServerWaypointEntry> waypoints Waypoints for this player indexed by server ID
function WaypointManager.getForPlayer(playerId)
    local result = {}
    local playerWaypoints = waypointsByPlayer[playerId]
    if playerWaypoints then
        for id in pairs(playerWaypoints) do
            result[id] = waypointsById[id]
        end
    end
    return result
end

function WaypointManager.getAllByPlayers()
    return waypointsByPlayer
end

return WaypointManager

local timerClock = require 'shared.timerClock'

local TimerManager = {}

local timerId = 0

---@type table<number, table<number, boolean>>
local timersByPlayer = {}

---@type table<number, table>
local timersById = {}

---@param target TargetType
---@param eventName string
---@param ... any
local function triggerTimerEvent(target, eventName, ...)
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
    end

    return { target }
end

local function track(id, target)
    local targets = resolveTargets(target)
    for i = 1, #targets do
        local playerId = targets[i]
        if not timersByPlayer[playerId] then
            timersByPlayer[playerId] = {}
        end
        timersByPlayer[playerId][id] = true
    end
end

---@param target TargetType
---@param data table
---@return number serverId
function TimerManager.create(target, data)
    assert(type(data) == 'table', 'timer data must be a table')
    assert(data.coords, 'timer coords are required')

    local style = data.style or 'pill'
    assert(timerClock.isStyle(style), ('unknown timer style: %s'):format(tostring(style)))

    timerId = timerId + 1
    local id = timerId

    timersById[id] = {
        target = target,
        data = data,
    }

    track(id, target)
    triggerTimerEvent(target, 'createTimer', id, data)
    return id
end

function TimerManager.update(id, data)
    local timer = timersById[id]
    if not timer or type(data) ~= 'table' then return end

    if data.style then
        assert(timerClock.isStyle(data.style), ('unknown timer style: %s'):format(tostring(data.style)))
    end

    for key, value in pairs(data) do
        timer.data[key] = value
    end

    triggerTimerEvent(timer.target, 'updateTimer', id, data)
end

function TimerManager.remove(id)
    local timer = timersById[id]
    if not timer then return end

    triggerTimerEvent(timer.target, 'removeTimer', id)

    local targets = resolveTargets(timer.target)
    for i = 1, #targets do
        local playerId = targets[i]
        if timersByPlayer[playerId] then
            timersByPlayer[playerId][id] = nil
        end
    end

    timersById[id] = nil
end

function TimerManager.removeAll(playerId)
    if playerId then
        local mine = timersByPlayer[playerId]
        if not mine then return end

        local drop = {}
        for id in pairs(mine) do
            local timer = timersById[id]
            if timer then
                local targets = resolveTargets(timer.target)
                if #targets == 1 then
                    drop[#drop + 1] = id
                end
            end
        end

        for i = 1, #drop do
            local id = drop[i]
            mine[id] = nil
            timersById[id] = nil
            TriggerClientEvent('sleepless_waypoints:removeTimer', playerId, id)
        end

        return
    end

    for id, timer in pairs(timersById) do
        triggerTimerEvent(timer.target, 'removeTimer', id)
    end

    timersById = {}
    timersByPlayer = {}
end

function TimerManager.removeForPlayer(playerId)
    local mine = timersByPlayer[playerId]
    if not mine then return end

    for id in pairs(mine) do
        local timer = timersById[id]
        if timer then
            local targets = resolveTargets(timer.target)
            if #targets == 1 then
                timersById[id] = nil
            end
        end
    end

    timersByPlayer[playerId] = nil
end

function TimerManager.get(id)
    return timersById[id]
end

function TimerManager.getAll()
    return timersById
end

function TimerManager.getForPlayer(playerId)
    local result = {}
    local mine = timersByPlayer[playerId]
    if mine then
        for id in pairs(mine) do
            result[id] = timersById[id]
        end
    end
    return result
end

function TimerManager.getAllByPlayers()
    return timersByPlayer
end

return TimerManager

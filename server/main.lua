local Waypoint = require 'server.modules.Waypoint'
local Timer = require 'server.modules.Timer'
local config = require 'config'

-------------------------------------------------
-- Cleanup
-------------------------------------------------
AddEventHandler('playerDropped', function()
    local playerId = source
    Waypoint.removeForPlayer(playerId)
    Timer.removeForPlayer(playerId)
end)


CreateThread(function()
    while true do
        Wait(config.server.cleanupInterval)
        local seen = {}

        for playerId in pairs(Waypoint.getAllByPlayers()) do
            seen[playerId] = true
        end

        for playerId in pairs(Timer.getAllByPlayers()) do
            seen[playerId] = true
        end

        for playerId in pairs(seen) do
            if GetPlayerPing(playerId) == 0 then
                Waypoint.removeForPlayer(playerId)
                Timer.removeForPlayer(playerId)
            end
        end
    end
end)


-------------------------------------------------
-- Exports
-------------------------------------------------
exports('create', Waypoint.create)
exports('update', Waypoint.update)
exports('remove', Waypoint.remove)
exports('removeAll', Waypoint.removeAll)
exports('removeForPlayer', Waypoint.removeForPlayer)
exports('get', Waypoint.get)
exports('getAll', Waypoint.getAll)
exports('getForPlayer', Waypoint.getForPlayer)

exports('createTimer', Timer.create)
exports('updateTimer', Timer.update)
exports('removeTimer', Timer.remove)
exports('removeAllTimers', Timer.removeAll)
exports('getTimer', Timer.get)
exports('getAllTimers', Timer.getAll)
exports('getTimersForPlayer', Timer.getForPlayer)
-------------------------------------------------

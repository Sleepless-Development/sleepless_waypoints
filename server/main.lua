local Waypoint = require 'server.modules.Waypoint'
local config = require 'config'

-------------------------------------------------
-- Cleanup
-------------------------------------------------
AddEventHandler('playerDropped', function()
    local playerId = source
    Waypoint.removeForPlayer(playerId)
end)


CreateThread(function()
    while true do
        Wait(config.server.cleanupInterval)
        for playerId in pairs(Waypoint.getAllByPlayers()) do
            if GetPlayerPing(playerId) == 0 then
                Waypoint.removeForPlayer(playerId)
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
-------------------------------------------------

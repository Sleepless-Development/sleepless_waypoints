local config = require 'config'

if not config.server.versionCheckEnabled then
    return
end

lib.versionCheck("Sleepless-Development/sleepless_waypoints")

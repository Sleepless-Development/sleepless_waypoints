local config = {}

-------------------------------------------------
-- Map Waypoint Sync
-------------------------------------------------
-- When enabled, a waypoint marker will be created at the player's map waypoint
config.syncToWayPoint = true

-- Settings for the auto-created map waypoint marker
config.mapWaypoint = {
    type = 'checkpoint',
    label = 'WAYPOINT',
    color = '#f500fc',
    size = 1.0,
    drawDistance = 1000.0,
}

-------------------------------------------------
-- Default Waypoint Settings
-------------------------------------------------
-- These values are used when not specified in waypoint creation
config.defaults = {
    -- Rendering
    drawDistance = 500.0, -- Maximum distance to render the waypoint
    fadeDistance = 400.0, -- Distance at which waypoint starts fading
    size = 1.0,           -- Base size multiplier

    -- Height settings (for checkpoint type)
    minHeight = 0.5,      -- Minimum marker height
    maxHeight = 50.0,     -- Maximum marker height
    groundZOffset = -2.0, -- Offset from coords.z for ground position

    -- Appearance
    color = '#f5a623',      -- Default marker color (hex)
    label = 'CHECKPOINT',   -- Default label text
    displayDistance = true, -- Show distance on marker by default
}

-------------------------------------------------
-- DUI Settings
-------------------------------------------------
config.dui = {
    width = 512,     -- DUI texture width in pixels
    height = 1024,   -- DUI texture height in pixels
}

-------------------------------------------------
-- Rendering Settings
-------------------------------------------------
config.rendering = {
    -- Main loop update interval (ms) - how often to check which waypoints should render
    updateInterval = 100,

    -- Perspective scaling
    perspectiveDivisor = 20.0, -- Divides camera distance to calculate perspective scale

    -- Checkpoint type scaling
    checkpointBaseMultiplier = 4.0, -- Multiplier for checkpoint base size
    checkpointMinScale = 0.1,       -- Minimum perspective scale for checkpoints
    checkpointAspectRatio = 2.0,    -- Height to width ratio for checkpoint quads

    -- Small type scaling
    smallMinScale = 1.0,    -- Minimum perspective scale for small markers
    smallAspectRatio = 2.0, -- Height to width ratio for small marker quads
}

-------------------------------------------------
-- Server Settings
-------------------------------------------------
config.server = {
    -- Cleanup interval for checking disconnected players (ms)
    cleanupInterval = 60000,
}

return config

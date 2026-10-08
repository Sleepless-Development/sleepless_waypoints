---@meta

---@alias WaypointType 'small' | 'checkpoint'

---@alias TargetType number | number[]

---@class WaypointData
---@field coords vector3 The 3D position of the waypoint
---@field type? WaypointType Waypoint type: 'small' or 'checkpoint' (default: 'small')
---@field color? string Hex color for the waypoint (default: '#f5a623')
---@field label? string Text label (for checkpoint type)
---@field icon? string Icon URL (optional)
---@field iconColor? string Hex color for the icon (optional)
---@field image? string Image URL (optional)
---@field size? number Size multiplier (default: 1.0)
---@field displayDistance? boolean Whether to show distance text (default: true)
---@field drawDistance? number Max distance to render (default: 500.0)
---@field drawDistanceSq? number Squared draw distance (pre-calculated for optimization)
---@field fadeDistance? number Distance to start fading (default: 400.0)
---@field fadeDistanceSq? number Squared fade distance (pre-calculated for optimization)
---@field minHeight? number Minimum height for checkpoint line (default: 0.5)
---@field maxHeight? number Maximum height for checkpoint line (default: 50.0)
---@field groundZ? number Ground Z coordinate for the line (default: coords.z - 2)
---@field removeDistance? number Distance to player for auto-removal (optional)
---@field removeDistanceSq? number Squared remove distance (pre-calculated for optimization)

---@class WaypointInstance
---@field id number Unique waypoint identifier
---@field data WaypointData Waypoint configuration data
---@field dui Dui? The DUI instance for rendering (nil when not rendering)
---@field duiId number? The DUI pool ID for releasing back to pool (nil when not rendering)
---@field active boolean Whether the waypoint is active
---@field isRendering boolean Whether the waypoint currently has a DUI acquired for rendering
---@field nextDistanceUpdate number? Next timestamp to update distance text
---@field lastDistance number? Last distance value shown
---@field cachedCamDistSq number? Cached squared camera distance from shouldRender check

---@class WaypointManager
---@field create fun(data: WaypointData): number? Create a new waypoint, returns waypoint ID
---@field update fun(id: number, data: WaypointData) Update waypoint properties
---@field remove fun(id: number) Remove a waypoint by ID
---@field removeAll fun() Remove all active waypoints
---@field get fun(id: number): WaypointInstance? Get waypoint by ID
---@field getAll fun(): table<number, WaypointInstance> Get all active waypoints
---@field getArray fun(): WaypointInstance[] Get all waypoints as array
---@field shouldRender fun(waypoint: WaypointInstance, camPos: vector3): boolean Check if waypoint should render
---@field acquireForRendering fun(waypoint: WaypointInstance): boolean Acquire a DUI for rendering
---@field releaseFromRendering fun(waypoint: WaypointInstance) Release DUI when no longer visible
---@field render fun(waypoint: WaypointInstance, camPos: vector3, playerPos: vector3): boolean Render a waypoint

---@class WaypointUtils
---@field hexToRgb fun(hex: string): number, number, number Parse hex color to RGB
---@field drawTexturedQuad fun(pos: vector3, width: number, height: number, r: number, g: number, b: number, a: number, txd: string, txn: string, u0: number, v0: number, u1: number, v1: number) Draw a textured billboard quad
---@field isQuadOnScreen fun(pos: vector3, width: number, height: number, camPos: vector3): boolean
---@class ServerWaypointManager
---@field create fun(target: TargetType, data: WaypointData): number Create a waypoint for specified player(s), returns server ID
---@field update fun(id: number, data: WaypointData) Update waypoint data
---@field remove fun(id: number) Remove a waypoint
---@field removeAll fun(playerId?: number) Remove all waypoints, or for specific player
---@field removeForPlayer fun(playerId: number) Remove waypoints for player on disconnect
---@field get fun(id: number): ServerWaypointEntry? Get waypoint by server ID
---@field getAll fun(): table<number, ServerWaypointEntry> Get all waypoints
---@field getForPlayer fun(playerId: number): table<number, ServerWaypointEntry> Get waypoints for player
---@class ServerWaypointEntry
---@field target TargetType
---@field data WaypointData
---@field clientIds table<number, number>

-------------------------------------------------
-- Exports
-------------------------------------------------

exports.sleepless_waypoints = {}


--- `client`
--- Create a new 3D waypoint
---@param data WaypointData
---@return number waypointId
function exports.sleepless_waypoints:create(data) end

--- `client`
--- Update waypoint properties
---@param id number
---@param data WaypointData
function exports.sleepless_waypoints:update(id, data) end

--- `client`
--- Remove a waypoint by ID
---@param id number
function exports.sleepless_waypoints:remove(id) end

--- `client`
--- Remove all active waypoints
function exports.sleepless_waypoints:removeAll() end

--- `client`
--- Get waypoint by ID
---@param id number
---@return WaypointInstance?
function exports.sleepless_waypoints:get(id) end

--- `server`
--- Create a waypoint for specified player(s)
---@param target TargetType
---@param data WaypointData
---@return number serverId
function exports.sleepless_waypoints:create(target, data) end

--- `server`
--- Update waypoint data
---@param id number
---@param data WaypointData
function exports.sleepless_waypoints:update(id, data) end

--- `server`
--- Remove a waypoint
---@param id number
function exports.sleepless_waypoints:remove(id) end

--- `server`
--- Remove all waypoints, or for specific player
---@param playerId? number
function exports.sleepless_waypoints:removeAll(playerId) end

--- `server`
--- Remove waypoints for player on disconnect
---@param playerId number
function exports.sleepless_waypoints:removeForPlayer(playerId) end

--- `server`
--- Get waypoint by server ID
---@param id number
---@return ServerWaypointEntry?
function exports.sleepless_waypoints:get(id) end

--- `server`
--- Get all waypoints
---@return table<number, ServerWaypointEntry>
function exports.sleepless_waypoints:getAll() end

--- `server`
--- Get waypoints for player
---@param playerId number
---@return table<number, ServerWaypointEntry>
function exports.sleepless_waypoints:getForPlayer(playerId) end

---@alias TimerStyle 'pill' | 'bar' | 'chip' | 'stack' | 'dial' | 'pie' | 'donut' | 'gauge' | 'clock' | 'dots' | 'signal'

---@class TimerColorStop
---@field at number Progress from 0.0 to 1.0 where this colour takes over.
---@field color string `#rrggbb`

---@class TimerData
---@field coords vector3 World position. The plate is centered here.
---@field style? TimerStyle Visual style. Default 'pill'.
---@field label? string Caption. Default 'TIMER'.
---@field showLabel? boolean Draw the caption. Default true.
---@field showValue? boolean Draw the remaining time or percent. Default true.
---@field duration? number Countdown length in milliseconds. Omit to drive `progress` yourself.
---@field progress? number Script progress from 0.0 to 1.0. Also seeks a duration timer.
---@field elapsed? number Milliseconds already elapsed when a duration timer is created.
---@field color? string Progress colour as `#rrggbb`. Default `#31a4fc`. Ignored while `colors` is set.
---@field colors? TimerColorStop[] Colour at each progress breakpoint. The fill holds a colour until the next stop.
---@field blend? boolean Ease into the next colour near that stop. Default false, which switches hard at the stop.
---@field background? boolean Draw the black plate. Default true.
---@field paused? boolean Freeze a duration timer. Default false.
---@field size? number Scale multiplier. Default 1.0.
---@field drawDistance? number Metres before the timer hides. Default 12.
---@field fadeDistance? number Metres before it starts fading. Default 9.
---@field removeOnComplete? boolean Remove a duration timer at zero. Default true.
---@field onEnd? fun(id: number) Client only. Called when a duration timer reaches zero, before the plate is removed.

--- `client`
--- Create a world-space DUI timer. Returns the client timer id.
---@param data TimerData
---@return number timerId
function exports.sleepless_waypoints:createTimer(data) end

--- `client`
--- Update a timer. Only the fields you pass are changed.
---@param id number
---@param data TimerData
function exports.sleepless_waypoints:updateTimer(id, data) end

--- `client`
--- Remove a timer by client id.
---@param id number
function exports.sleepless_waypoints:removeTimer(id) end

--- `client`
--- Remove every timer on this client.
function exports.sleepless_waypoints:removeAllTimers() end

--- `client`
--- Get a timer created on this client.
---@param id number
---@return table?
function exports.sleepless_waypoints:getTimer(id) end

--- `server`
--- Create a timer for one player, a list of players, or `-1` for everyone online.
---@param target TargetType
---@param data TimerData
---@return number serverId
function exports.sleepless_waypoints:createTimer(target, data) end

--- `server`
--- Update a server timer and forward the change to its targets.
---@param id number
---@param data TimerData
function exports.sleepless_waypoints:updateTimer(id, data) end

--- `server`
--- Remove a server timer from every target that can see it.
---@param id number
function exports.sleepless_waypoints:removeTimer(id) end

--- `server`
--- Remove server timers. Pass a player id to remove only the timers aimed at that player.
---@param playerId? number
function exports.sleepless_waypoints:removeAllTimers(playerId) end

--- `server`
--- Get one server timer record.
---@param id number
---@return table?
function exports.sleepless_waypoints:getTimer(id) end

--- `server`
--- Get every server timer, keyed by server id.
---@return table<number, table>
function exports.sleepless_waypoints:getAllTimers() end

--- `server`
--- Get the server timers tracked for one player.
---@param playerId number
---@return table<number, table>
function exports.sleepless_waypoints:getTimersForPlayer(playerId) end

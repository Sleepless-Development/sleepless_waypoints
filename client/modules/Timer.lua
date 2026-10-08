local utils = require 'client.modules.utils'
local DuiPool = require 'client.modules.duiPool'
local config = require 'config'
local timerClock = require 'shared.timerClock'

---@class TimerManager
local TimerManager = {}

---@type table<number, table>
local timersById = {}
local idToIndex = {}
local timerArray = {}
local timerId = 0

-- Pixel boxes match the #timer rules in web/timer.css. The quad UVs crop to the same box.
local FRAME = {
    pill = { x = 8, y = 170, w = 496, h = 172 },
    bar = { x = 8, y = 178, w = 496, h = 156 },
    chip = { x = 36, y = 196, w = 440, h = 120 },
    stack = { x = 131, y = 141, w = 250, h = 230 },
    dial = { x = 91, y = 86, w = 330, h = 340 },
    pie = { x = 91, y = 76, w = 330, h = 360 },
    donut = { x = 91, y = 106, w = 330, h = 300 },
    gauge = { x = 36, y = 96, w = 440, h = 320 },
    clock = { x = 91, y = 66, w = 330, h = 380 },
    dots = { x = 8, y = 178, w = 496, h = 156 },
    signal = { x = 8, y = 158, w = 496, h = 196 },
}

local timerPool = DuiPool.create({
    name = 'timer',
    url = ('nui://%s/web/timer.html'):format(cache.resource),
    width = config.timerDui.width,
    height = config.timerDui.height,
})

local function colorOrDefault(color)
    if type(color) == 'string' and color:match('^#%x%x%x%x%x%x$') then
        return color
    end

    if type(color) == 'string' then
        lib.print.error(('timer color must be #rrggbb, got %s'):format(color))
    end

    return config.timer.color
end

local function normalizeColors(colors)
    if type(colors) ~= 'table' then
        return nil
    end

    local byAt = {}
    local ats = {}

    for i = 1, #colors do
        local stop = colors[i]
        local at = type(stop) == 'table' and tonumber(stop.at) or nil
        local color = type(stop) == 'table' and stop.color or nil
        local valid = at ~= nil and type(color) == 'string' and color:match('^#%x%x%x%x%x%x$')

        if valid then
            if at < 0 then at = 0 end
            if at > 1 then at = 1 end
            if byAt[at] == nil then
                ats[#ats + 1] = at
            end
            byAt[at] = color:lower()
        else
            lib.print.error('timer color stop needs at between 0 and 1 and color #rrggbb')
        end
    end

    if #ats == 0 then
        return nil
    end

    table.sort(ats)

    local stops = {}
    for i = 1, #ats do
        local at = ats[i]
        stops[i] = { at = at, color = byAt[at] }
    end

    return stops
end

local function clampProgress(value)
    if type(value) ~= 'number' then
        return 0
    end

    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function push(timer)
    if not timer.dui then return end

    local now = GetGameTimer()
    local state = timer.state

    timer.dui:sendMessage({
        action = 'setTimer',
        style = timer.data.style,
        label = timer.data.label,
        showLabel = timer.data.showLabel,
        showValue = timer.data.showValue,
        color = timer.data.color,
        colors = timer.data.colors,
        blend = timer.data.blend,
        background = timer.data.background,
        mode = state.mode,
        duration = state.duration,
        elapsed = timerClock.elapsed(state, now),
        paused = state.paused,
        progress = timerClock.progress(state, now),
    })
end

local function worldSize(timer, camDist)
    local frame = FRAME[timer.data.style] or FRAME.pill
    local perspective = camDist / config.rendering.timerPerspectiveDivisor
    local pixel = config.rendering.timerPixelScale
        * timer.data.size
        * math.max(config.rendering.timerMinScale, perspective)

    return frame, frame.w * pixel, frame.h * pixel
end

---@param data table
---@return number id
function TimerManager.create(data)
    assert(type(data) == 'table', 'timer data must be a table')
    assert(data.coords, 'timer coords are required')

    local style = data.style or 'pill'
    assert(timerClock.isStyle(style), ('unknown timer style: %s'):format(tostring(style)))

    local duration = type(data.duration) == 'number' and data.duration or 0
    local mode = duration > 0 and 'timer' or 'script'
    local now = GetGameTimer()
    local paused = data.paused and true or false
    local elapsed = 0

    if mode == 'timer' and type(data.elapsed) == 'number' and data.elapsed > 0 then
        elapsed = data.elapsed
    elseif mode == 'timer' and type(data.progress) == 'number' then
        elapsed = math.floor(clampProgress(data.progress) * duration)
    end

    local drawDist = data.drawDistance or config.timer.drawDistance
    local fadeDist = data.fadeDistance or config.timer.fadeDistance
    if fadeDist > drawDist then
        fadeDist = drawDist
    end

    local removeOnComplete = data.removeOnComplete
    if removeOnComplete == nil then
        removeOnComplete = config.timer.removeOnComplete
    end

    timerId = timerId + 1
    local id = timerId

    local timer = {
        id = id,
        data = {
            coords = data.coords,
            style = style,
            label = data.label or config.timer.label,
            showLabel = data.showLabel ~= false,
            showValue = data.showValue ~= false,
            color = colorOrDefault(data.color),
            colors = normalizeColors(data.colors),
            blend = data.blend and true or false,
            background = data.background == nil and config.timer.background or (data.background and true or false),
            size = data.size or config.timer.size,
            drawDistance = drawDist,
            drawDistanceSq = drawDist * drawDist,
            fadeDistance = fadeDist,
            fadeDistanceSq = fadeDist * fadeDist,
            removeOnComplete = removeOnComplete and true or false,
        },
        state = {
            mode = mode,
            duration = duration,
            elapsed = elapsed,
            paused = paused,
            resumedAt = paused and nil or now,
            progress = clampProgress(data.progress),
        },
        dui = nil,
        duiId = nil,
        active = true,
        isRendering = false,
        ended = false,
        onEnd = type(data.onEnd) == 'function' and data.onEnd or nil,
    }

    local index = #timerArray + 1
    timerArray[index] = timer
    timersById[id] = timer
    idToIndex[id] = index

    lib.print.debug(('[TIMER #%d] Created style=%s | Total timers: %d'):format(id, style, #timerArray))
    return id
end

function TimerManager.update(id, data)
    local timer = timersById[id]
    if not timer or type(data) ~= 'table' then return end

    local now = GetGameTimer()
    local state = timer.state

    if data.coords then
        timer.data.coords = data.coords
    end

    if data.style then
        assert(timerClock.isStyle(data.style), ('unknown timer style: %s'):format(tostring(data.style)))
        timer.data.style = data.style
    end

    if data.label ~= nil then
        timer.data.label = data.label
    end

    if data.showLabel ~= nil then
        timer.data.showLabel = data.showLabel and true or false
    end

    if data.showValue ~= nil then
        timer.data.showValue = data.showValue and true or false
    end

    if data.color then
        timer.data.color = colorOrDefault(data.color)
    end

    if data.colors ~= nil then
        timer.data.colors = normalizeColors(data.colors)
    end

    if data.blend ~= nil then
        timer.data.blend = data.blend and true or false
    end

    if data.background ~= nil then
        timer.data.background = data.background and true or false
    end

    if data.size then
        timer.data.size = data.size
    end

    if data.drawDistance then
        timer.data.drawDistance = data.drawDistance
        timer.data.drawDistanceSq = data.drawDistance * data.drawDistance
    end

    if data.fadeDistance then
        timer.data.fadeDistance = data.fadeDistance
        timer.data.fadeDistanceSq = data.fadeDistance * data.fadeDistance
    end

    if data.removeOnComplete ~= nil then
        timer.data.removeOnComplete = data.removeOnComplete and true or false
    end

    if data.onEnd ~= nil then
        timer.onEnd = type(data.onEnd) == 'function' and data.onEnd or nil
    end

    if type(data.duration) == 'number' and data.duration > 0 then
        state.mode = 'timer'
        state.duration = data.duration
        state.elapsed = 0
        state.resumedAt = state.paused and nil or now
    end

    if data.progress ~= nil then
        local progress = clampProgress(data.progress)
        if state.mode == 'timer' then
            state.elapsed = math.floor(progress * state.duration)
            state.resumedAt = state.paused and nil or now
        else
            state.progress = progress
        end
    end

    if data.paused ~= nil then
        local pause = data.paused and true or false
        if pause and not state.paused then
            state.elapsed = timerClock.elapsed(state, now)
            state.resumedAt = nil
            state.paused = true
        elseif not pause and state.paused then
            state.paused = false
            state.resumedAt = now
        end
    end

    if not timerClock.isComplete(state, now) then
        timer.ended = false
    end

    push(timer)
end

function TimerManager.acquireForRendering(timer)
    if timer.isRendering and timer.dui then
        return true
    end

    local duiWrapper, duiId = timerPool.acquire()
    if not duiWrapper then
        lib.print.error(('[TIMER #%d] Failed to acquire a DUI'):format(timer.id))
        return false
    end

    timer.dui = duiWrapper.dui
    timer.duiId = duiId
    timer.isRendering = true
    push(timer)
    return true
end

function TimerManager.releaseFromRendering(timer)
    if not timer.isRendering then
        return
    end

    if timer.duiId then
        timerPool.release(timer.duiId)
    end

    timer.dui = nil
    timer.duiId = nil
    timer.isRendering = false
end

function TimerManager.remove(id)
    local timer = timersById[id]
    if not timer then return end

    timer.active = false

    if timer.isRendering and timer.duiId then
        timerPool.release(timer.duiId)
    end

    local index = idToIndex[id]
    local lastIndex = #timerArray

    if index ~= lastIndex then
        local lastTimer = timerArray[lastIndex]
        timerArray[index] = lastTimer
        idToIndex[lastTimer.id] = index
    end

    timerArray[lastIndex] = nil
    timersById[id] = nil
    idToIndex[id] = nil
end

function TimerManager.removeAll()
    for i = #timerArray, 1, -1 do
        local timer = timerArray[i]
        if timer then
            TimerManager.remove(timer.id)
        end
    end
end

function TimerManager.get(id)
    return timersById[id]
end

function TimerManager.getArray()
    return timerArray
end

function TimerManager.tick()
    local now = GetGameTimer()
    local finished = {}

    for i = 1, #timerArray do
        local timer = timerArray[i]
        if timer.state.mode == 'timer' and not timer.ended and timerClock.isComplete(timer.state, now) then
            timer.ended = true
            finished[#finished + 1] = timer.id
        end
    end

    for i = 1, #finished do
        local id = finished[i]
        local timer = timersById[id]
        if timer and type(timer.onEnd) == 'function' then
            local ok, err = pcall(timer.onEnd, id)
            if not ok then
                lib.print.error(('timer #%s onEnd failed: %s'):format(id, err))
            end
        end

        TriggerEvent('sleepless_waypoints:client:timerEnded', id)

        timer = timersById[id]
        if timer and timer.data.removeOnComplete then
            TimerManager.remove(id)
        end
    end
end

function TimerManager.shouldRender(timer, camPos)
    if not timer.active then
        return false
    end

    local data = timer.data
    local diff = camPos - data.coords
    local camDistSq = (diff.x * diff.x) + (diff.y * diff.y) + (diff.z * diff.z)

    if camDistSq > data.drawDistanceSq then
        return false
    end

    local _, width, height = worldSize(timer, math.sqrt(camDistSq))
    return utils.isQuadOnScreen(data.coords, width, height, camPos)
end

function TimerManager.render(timer)
    if not timer.active or not timer.dui then
        return false
    end

    local success = pcall(IsDuiAvailable, timer.dui.duiObject)
    if not success then
        return false
    end

    if not timer.dui.dictName or not timer.dui.txtName then
        return false
    end

    local data = timer.data
    local camPos = GetFinalRenderedCamCoord()
    local diff = camPos - data.coords
    local camDist = math.sqrt((diff.x * diff.x) + (diff.y * diff.y) + (diff.z * diff.z))

    local alpha = 255
    if data.drawDistance > data.fadeDistance and camDist > data.fadeDistance then
        local fadeRange = data.drawDistance - data.fadeDistance
        local fadeDist = camDist - data.fadeDistance
        alpha = math.floor(255 * (1 - (fadeDist / fadeRange)))
        if alpha < 0 then
            alpha = 0
        end
    end

    local frame, width, height = worldSize(timer, camDist)
    local u0 = frame.x / config.timerDui.width
    local v0 = frame.y / config.timerDui.height
    local u1 = (frame.x + frame.w) / config.timerDui.width
    local v1 = (frame.y + frame.h) / config.timerDui.height

    utils.drawTexturedQuad(
        data.coords,
        width,
        height,
        255, 255, 255, alpha,
        timer.dui.dictName,
        timer.dui.txtName,
        u0, v0, u1, v1
    )

    return true
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    TimerManager.removeAll()
    timerPool.cleanup()
end)

return TimerManager

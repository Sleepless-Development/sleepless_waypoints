local clock = {}

local STYLE_LIST = { 'pill', 'bar', 'chip', 'stack', 'dial', 'pie', 'donut', 'gauge', 'clock', 'dots', 'signal' }

local styles = {}
for i = 1, #STYLE_LIST do
    styles[STYLE_LIST[i]] = true
end

function clock.isStyle(style)
    return styles[style] == true
end

function clock.styles()
    return STYLE_LIST
end

---@param state table
---@param now number
---@return number
function clock.elapsed(state, now)
    if state.mode ~= 'timer' then
        return 0
    end

    if state.paused or not state.resumedAt then
        return state.elapsed
    end

    return state.elapsed + (now - state.resumedAt)
end

---@param state table
---@param now number
---@return number
function clock.progress(state, now)
    if state.mode ~= 'timer' then
        return state.progress or 0
    end

    if not state.duration or state.duration <= 0 then
        return 1
    end

    local elapsed = clock.elapsed(state, now)
    if elapsed >= state.duration then
        return 1
    end

    return elapsed / state.duration
end

---@param state table
---@param now number
---@return boolean
function clock.isComplete(state, now)
    if state.mode ~= 'timer' or state.paused then
        return false
    end

    return clock.elapsed(state, now) >= (state.duration or 0)
end

return clock

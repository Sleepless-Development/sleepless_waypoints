---@class WaypointUtils
local utils = {}

function utils.hexToRgb(hex)
    hex = hex:gsub('#', '')
    return tonumber(hex:sub(1, 2), 16) or 255,
        tonumber(hex:sub(3, 4), 16) or 255,
        tonumber(hex:sub(5, 6), 16) or 255
end

local function billboardAxes(pos, camPos)
    local up = vec3(0.0, 0.0, 1.0)
    local toCamera = camPos - pos
    local flatX = toCamera.x
    local flatY = toCamera.y
    local flatLen = math.sqrt((flatX * flatX) + (flatY * flatY))

    if flatLen < 0.001 then
        flatX = 0.0
        flatY = 1.0
        flatLen = 1.0
    end

    local forward = vec3(flatX / flatLen, flatY / flatLen, 0.0)
    local right = norm(cross(up, forward))
    return right, up
end

function utils.drawTexturedQuad(pos, width, height, r, g, b, a, txd, txn, u0, v0, u1, v1)
    local camPos = GetFinalRenderedCamCoord()
    local halfW = width / 2
    local halfH = height / 2
    local right, up = billboardAxes(pos, camPos)

    local topLeft = pos - (right * halfW) + (up * halfH)
    local topRight = pos + (right * halfW) + (up * halfH)
    local bottomLeft = pos - (right * halfW) - (up * halfH)
    local bottomRight = pos + (right * halfW) - (up * halfH)

    DrawTexturedPoly(
        topRight.x, topRight.y, topRight.z,
        topLeft.x, topLeft.y, topLeft.z,
        bottomLeft.x, bottomLeft.y, bottomLeft.z,
        r, g, b, a,
        txd, txn,
        u1, v0, 0.0,
        u0, v0, 0.0,
        u0, v1, 0.0
    )

    DrawTexturedPoly(
        topRight.x, topRight.y, topRight.z,
        bottomLeft.x, bottomLeft.y, bottomLeft.z,
        bottomRight.x, bottomRight.y, bottomRight.z,
        r, g, b, a,
        txd, txn,
        u1, v0, 0.0,
        u0, v1, 0.0,
        u1, v1, 0.0
    )
end

function utils.isQuadOnScreen(pos, width, height, camPos)
    local halfW = width / 2
    local halfH = height / 2
    local right, up = billboardAxes(pos, camPos)

    local points = {
        pos,
        pos - (right * halfW) + (up * halfH),
        pos + (right * halfW) + (up * halfH),
        pos - (right * halfW) - (up * halfH),
        pos + (right * halfW) - (up * halfH),
    }

    for i = 1, #points do
        local point = points[i]
        local onScreen = GetScreenCoordFromWorldCoord(point.x, point.y, point.z)
        if onScreen == 1 then
            return true
        end
    end

    return false
end

function utils.drawTexturedTriangle(pos, width, height, r, g, b, a, txd, txn)
    local camPos = GetFinalRenderedCamCoord()
    local halfW = width / 2

    local up = vec3(0.0, 0.0, 1.0)
    local toCamera = camPos - pos
    local forward = norm(vec3(toCamera.x, toCamera.y, 0.0))
    local right = norm(cross(up, forward))

    local topLeft = pos - (right * halfW) + (up * height)
    local topRight = pos + (right * halfW) + (up * height)
    local bottom = pos

    DrawTexturedPoly(
        topRight.x, topRight.y, topRight.z,
        topLeft.x, topLeft.y, topLeft.z,
        bottom.x, bottom.y, bottom.z,
        r, g, b, a,
        txd, txn,
        1.0, 0.0, 0.0, -- topRight UV
        0.0, 0.0, 0.0, -- topLeft UV
        0.5, 1.0, 0.0  -- bottom UV (centered horizontally)
    )
end

-- function utils.drawTexturedQuad(pos, width, height, r, g, b, a, txd, txn)
--     local camPos = GetFinalRenderedCamCoord()
--     local halfW = width / 2
--     local halfH = height / 2
--
--     local up = vec3(0.0, 0.0, 1.0)
--     local toCamera = camPos - pos
--     local forward = norm(vec3(toCamera.x, toCamera.y, 0.0))
--     local right = norm(cross(up, forward))
--
--     local topLeft = pos - (right * halfW) + (up * halfH)
--     local topRight = pos + (right * halfW) + (up * halfH)
--     local bottomLeft = pos - (right * halfW) - (up * halfH)
--     local bottomRight = pos + (right * halfW) - (up * halfH)
--
--     DrawTexturedPoly(
--         bottomRight.x, bottomRight.y, bottomRight.z,
--         topRight.x, topRight.y, topRight.z,
--         bottomLeft.x, bottomLeft.y, bottomLeft.z,
--         r, g, b, a,
--         txd, txn,
--         1.0, 1.0, 0.0,
--         1.0, 0.0, 0.0,
--         0.0, 1.0, 0.0
--     )
-- end

return utils

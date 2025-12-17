---@class WaypointUtils
local utils = {}

function utils.hexToRgb(hex)
    hex = hex:gsub('#', '')
    return tonumber(hex:sub(1, 2), 16) or 255,
        tonumber(hex:sub(3, 4), 16) or 255,
        tonumber(hex:sub(5, 6), 16) or 255
end

function utils.drawTexturedQuad(pos, width, height, r, g, b, a, txd, txn)
    local camPos = GetFinalRenderedCamCoord()
    local halfW = width / 2
    local halfH = height / 2

    local up = vec3(0.0, 0.0, 1.0)
    local toCamera = camPos - pos
    local forward = norm(vec3(toCamera.x, toCamera.y, 0.0))
    local right = norm(cross(up, forward))

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
        1.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.0, 1.0, 0.0
    )

    DrawTexturedPoly(
        bottomRight.x, bottomRight.y, bottomRight.z,
        topRight.x, topRight.y, topRight.z,
        bottomLeft.x, bottomLeft.y, bottomLeft.z,
        r, g, b, a,
        txd, txn,
        1.0, 1.0, 0.0,
        1.0, 0.0, 0.0,
        0.0, 1.0, 0.0
    )
end

return utils

if lib.context == "client" then
    -------------------------------------------------
    -- Client Test Commands
    -------------------------------------------------
    ---
    local Waypoint = require 'client.modules.Waypoint'
    local Timer = require 'client.modules.Timer'


    -- Test small marker
    RegisterCommand('testsmall', function()
        local playerPos = GetEntityCoords(cache.ped)
        local testPos = playerPos + GetEntityForwardVector(cache.ped) * 5.0

        local id = Waypoint.create({
            coords = testPos,
            type = 'small',
            color = '#ff6b6b',
            -- image = 'nui://ox_inventory/web/images/copper_ore.webp',
            icon = "hand",
            size = 0.25,
            drawDistance = 100.0,
            removeWhenClose = true,
            removeDistance = 1.0,
            displayDistance = true,
        })

        print('Created small waypoint:', id)

        SetTimeout(30000, function()
            Waypoint.remove(id)
            print('Removed waypoint:', id)
        end)
    end, false)

    -- Test checkpoint marker
    RegisterCommand('testcheckpoint', function()
        local playerPos = GetEntityCoords(cache.ped)
        local testPos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 20.0, -1.0)

        local id = Waypoint.create({
            coords = testPos,
            type = 'checkpoint',
            color = '#f5a623',
            label = 'CHECKPOINT',
            -- image = 'nui://ox_inventory/web/images/copper_ore.webp',
            icon = "hand",
            size = 1.0,
            drawDistance = 500.0,
            groundZ = playerPos.z - 1,
            minHeight = 5.0,
            maxHeight = 80.0,
            displayDistance = true,
        })

        print('Created checkpoint waypoint:', id)

        SetTimeout(10000, function()
            Waypoint.remove(id)
            print('Removed waypoint:', id)
        end)
    end, false)

    -- Test multiple checkpoints
    RegisterCommand('testcheckpoints', function()
        local playerPos = GetEntityCoords(cache.ped)
        local groundZ = playerPos.z - 1

        local colors = { '#f5a623', '#4ecdc4', '#9b59b6' }
        local labels = { 'CHECKPOINT', 'DESTINATION', 'OBJECTIVE' }

        for i = 1, 3 do
            local angle = (i - 1) * 120 * (math.pi / 180)
            local distance = 150 + (i * 50)
            local testPos = playerPos + vec3(
                math.sin(angle) * distance,
                math.cos(angle) * distance,
                0
            )

            Waypoint.create({
                coords = testPos,
                type = 'checkpoint',
                color = colors[i],
                label = labels[i],
                size = 1.0,
                drawDistance = 600.0,
                groundZ = groundZ,
            })
        end

        print('Created 3 checkpoint waypoints')
    end, false)

    -- Test waypoints in a line
    RegisterCommand('testline', function()
        local playerPos = GetEntityCoords(cache.ped)
        local groundZ = playerPos.z - 1

        local waypoints = {
            { type = 'small',      color = '#ff6b6b', icon = 'hand',   size = 0.15, label = nil },
            { type = 'small',      color = '#4ecdc4', icon = 'circle', size = 0.2,  label = nil },
            { type = 'checkpoint', color = '#f5a623', icon = nil,      size = 0.8,  label = 'POINT A' },
            { type = 'small',      color = '#9b59b6', icon = 'star',   size = 0.25, label = nil },
            { type = 'checkpoint', color = '#3498db', icon = nil,      size = 1.0,  label = 'POINT B' },
            { type = 'small',      color = '#2ecc71', icon = 'check',  size = 0.15, label = nil },
            { type = 'checkpoint', color = '#e74c3c', icon = nil,      size = 1.2,  label = 'DESTINATION' },
        }

        for i, wp in ipairs(waypoints) do
            local testPos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 10.0 * i, 0.0)

            Waypoint.create({
                coords = testPos,
                type = wp.type,
                color = wp.color,
                icon = wp.icon,
                label = wp.label,
                size = wp.size,
                drawDistance = 500.0,
                groundZ = groundZ,
            })
        end

        print('Created ' .. #waypoints .. ' waypoints in a line')
    end, false)

    RegisterCommand('testtimer', function()
        local styles = { 'pill', 'bar', 'chip', 'stack', 'dial', 'pie', 'donut', 'gauge', 'clock', 'dots', 'signal' }

        for i = 1, #styles do
            local style = styles[i]
            local ramp = style == 'dots' or style == 'signal'
            Timer.create({
                coords = GetOffsetFromEntityInWorldCoords(cache.ped, (i - 4.5) * 0.75, 2.4, 0.55),
                style = style,
                label = style,
                duration = 8000 + (i * 1500),
                color = '#31a4fc',
                colors = ramp and {
                    { at = 0.0, color = '#31a4fc' },
                    { at = 0.45, color = '#f5a623' },
                    { at = 0.75, color = '#b83e3e' },
                } or nil,
                blend = style == 'signal',
                drawDistance = 25.0,
                onEnd = function(timerId)
                    print(('timer finished: %s'):format(timerId))
                end,
            })
        end

        print('Created a row of timers')
    end, false)

    RegisterCommand('testtimerprogress', function()
        local pos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.55)
        local id = Timer.create({
            coords = pos,
            style = 'stack',
            label = 'Filling',
            progress = 0.0,
            color = '#31a4fc',
            drawDistance = 25.0,
        })

        CreateThread(function()
            for step = 1, 20 do
                Wait(400)
                Timer.update(id, { progress = step / 20 })
            end
        end)

        print('Created a script-driven timer:', id)
    end, false)

    -- Clear all waypoints
    RegisterCommand('clearwaypoints', function()
        Waypoint.removeAll()
        Timer.removeAll()
        print('All waypoints cleared')
    end, false)
else
    -------------------------------------------------
    -- Server Test Commands
    -------------------------------------------------

    local Waypoint = require 'server.modules.Waypoint'

    RegisterCommand('sv_testwaypoint', function(source)
        if source == 0 then
            print('This command must be run by a player')
            return
        end

        local ped = GetPlayerPed(source)
        local coords = GetEntityCoords(ped)
        local testPos = vector3(coords.x, coords.y + 50.0, coords.z)

        local id = Waypoint.create(source, {
            coords = testPos,
            type = 'checkpoint',
            color = '#4ecdc4',
            label = 'SERVER WAYPOINT',
            size = 1.0,
            drawDistance = 500.0,
            groundZ = coords.z,
        })

        print(('Created server waypoint %d for player %d'):format(id, source))

        SetTimeout(30000, function()
            Waypoint.remove(id)
            print(('Removed server waypoint %d'):format(id))
        end)
    end, false)

    -- Test waypoint for all players
    RegisterCommand('sv_testwaypointall', function(source)
        local coords = vector3(0, 0, 72) -- Center of map

        local id = Waypoint.create(-1, {
            coords = coords,
            type = 'checkpoint',
            color = '#9b59b6',
            label = 'GLOBAL WAYPOINT',
            size = 1.0,
            drawDistance = 5000.0,
            groundZ = 70.0,
        })

        print(('Created global server waypoint %d'):format(id))

        SetTimeout(60000, function()
            Waypoint.remove(id)
            print(('Removed global server waypoint %d'):format(id))
        end)
    end, true) -- Admin only
end

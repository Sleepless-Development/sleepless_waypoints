local DuiPool = {}

local waitingForDuiLoad = {}
local nextId = 0

RegisterNUICallback('load', function(data, cb)
    local id = tonumber(data.id)
    if id then
        waitingForDuiLoad[id] = nil
    end
    cb({})
end)

---@param options { name: string, url: string, width: number, height: number }
---@return table
function DuiPool.create(options)
    local available = {}
    local inUse = {}
    local created = 0

    local function status(context)
        local inUseCount = 0
        for _ in pairs(inUse) do
            inUseCount = inUseCount + 1
        end

        lib.print.debug(('[POOL:%s] %s | In use: %d | Available: %d | Created: %d'):format(
            options.name,
            context,
            inUseCount,
            #available,
            created
        ))
    end

    local function createDui(id)
        local dui = lib.dui:new({
            url = options.url,
            width = options.width,
            height = options.height,
            debug = false,
        })

        waitingForDuiLoad[id] = true

        while waitingForDuiLoad[id] do
            dui:sendMessage({ action = 'load', id = id })
            Wait(100)
        end

        return {
            id = id,
            dui = dui,
        }
    end

    local api = {}

    function api.acquire()
        if #available > 0 then
            local wrapper = table.remove(available)
            inUse[wrapper.id] = wrapper
            lib.print.debug(('[POOL:%s] Reusing DUI #%d'):format(options.name, wrapper.id))
            status('After acquire')
            return wrapper, wrapper.id
        end

        nextId = nextId + 1
        created = created + 1
        local id = nextId
        local wrapper = createDui(id)
        inUse[id] = wrapper
        lib.print.debug(('[POOL:%s] Created DUI #%d'):format(options.name, id))
        status('After acquire')
        return wrapper, id
    end

    function api.release(id)
        local wrapper = inUse[id]
        if not wrapper then
            lib.print.debug(('[POOL:%s] Release missed DUI #%d'):format(options.name, id))
            return
        end

        inUse[id] = nil
        wrapper.dui:sendMessage({ action = 'reset' })
        available[#available + 1] = wrapper
        lib.print.debug(('[POOL:%s] Released DUI #%d'):format(options.name, id))
        status('After release')
    end

    function api.cleanup()
        for _, wrapper in pairs(inUse) do
            wrapper.dui:remove()
        end

        for i = 1, #available do
            available[i].dui:remove()
        end

        inUse = {}
        available = {}
    end

    return api
end

return DuiPool

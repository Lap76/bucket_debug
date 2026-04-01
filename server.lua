local lastBucket = {}
local lastContext = {}

local function now()
    return os.date('%Y-%m-%d %H:%M:%S')
end

local function coordsOf(src)
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local c = GetEntityCoords(ped)
        return ('vec3(%.2f, %.2f, %.2f)'):format(c.x, c.y, c.z)
    end
    return 'unknown'
end

local function log(msg)
    print(('[BUCKET-DEBUG %s] %s'):format(now(), msg))
end

local function setContext(src, context)
    lastContext[src] = {
        text = context,
        time = now()
    }
    log(('CONTEXT player=%s(%s) %s coords=%s bucket=%s'):format(
        GetPlayerName(src) or 'unknown',
        src,
        context,
        coordsOf(src),
        GetPlayerRoutingBucket(src)
    ))
end

exports('SetBucketContext', setContext)

RegisterCommand('bucketctx', function(source, args)
    local src = source
    if src == 0 then return end
    setContext(src, table.concat(args, ' '))
end, false)

AddEventHandler('playerJoining', function()
    local src = source
    CreateThread(function()
        Wait(1000)
        if GetPlayerName(src) then
            local bucket = GetPlayerRoutingBucket(src)
            lastBucket[src] = bucket
            log(('JOIN player=%s(%s) bucket=%s coords=%s'):format(
                GetPlayerName(src),
                src,
                bucket,
                coordsOf(src)
            ))
        end
    end)
end)

AddEventHandler('playerDropped', function()
    lastBucket[source] = nil
    lastContext[source] = nil
end)

CreateThread(function()
    while true do
        Wait(200)

        for _, id in ipairs(GetPlayers()) do
            local src = tonumber(id)
            local current = GetPlayerRoutingBucket(src)
            local previous = lastBucket[src]

            if previous == nil then
                lastBucket[src] = current
            elseif previous ~= current then
                local ctx = lastContext[src] and lastContext[src].text or 'no context'
                local ctxTime = lastContext[src] and lastContext[src].time or 'unknown'

                log(('CHANGE player=%s(%s) %s -> %s coords=%s lastContext="%s" ctxTime=%s'):format(
                    GetPlayerName(src) or 'unknown',
                    src,
                    previous,
                    current,
                    coordsOf(src),
                    ctx,
                    ctxTime
                ))

                lastBucket[src] = current
            end
        end
    end
end)
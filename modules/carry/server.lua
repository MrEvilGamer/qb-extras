local cfg = Config.Carry
if not cfg.Enabled then return end

local MAX_DISTANCE = cfg.MaxDistance + 1.0

local carrying = {}
local carriedBy = {}
local pending = {}

local function busy(id)
    return carrying[id] or carriedBy[id]
end

local function inRange(a, b)
    local distance = Utils.playerDistance(a, b)
    return distance and distance <= MAX_DISTANCE
end

local function start(carrier, target)
    carrying[carrier], carriedBy[target] = target, carrier
    TriggerClientEvent(Utils.event('carry:start'), carrier, 'carrier', target)
    TriggerClientEvent(Utils.event('carry:start'), target, 'carried', carrier)
end

local function stop(id)
    local other = carrying[id] or carriedBy[id]
    if not other then return end

    carrying[id], carriedBy[id] = nil, nil
    carrying[other], carriedBy[other] = nil, nil
    TriggerClientEvent(Utils.event('carry:stopped'), id)
    TriggerClientEvent(Utils.event('carry:stopped'), other)
end

RegisterNetEvent(Utils.event('carry:request'), function(target)
    local src = source
    target = tonumber(target)
    if not target or target == src or not GetPlayerName(target) then return end
    if not inRange(src, target) then return end

    if busy(src) or busy(target) then
        Bridge.notify(src, 'That person is busy', 'error')
        return
    end

    if not cfg.RequireConsent or Bridge.isDowned(target) then
        start(src, target)
        return
    end

    if pending[target] then
        Bridge.notify(src, 'That person already has a pending request', 'error')
        return
    end

    pending[target] = src
    Bridge.notify(src, 'Carry request sent', 'inform')
    TriggerClientEvent(Utils.event('carry:prompt'), target, src)

    SetTimeout((cfg.RequestTimeout + 2) * 1000, function()
        if pending[target] == src then pending[target] = nil end
    end)
end)

RegisterNetEvent(Utils.event('carry:respond'), function(accepted)
    local src = source
    local requester = pending[src]
    if not requester then return end
    pending[src] = nil

    if accepted ~= true then
        Bridge.notify(requester, 'Carry request declined', 'error')
        return
    end

    if not GetPlayerName(requester) or busy(requester) or busy(src) then return end
    if not inRange(src, requester) then
        Bridge.notify(requester, 'You moved too far away', 'error')
        return
    end

    start(requester, src)
end)

RegisterNetEvent(Utils.event('carry:stop'), function()
    stop(source)
end)

AddEventHandler('playerDropped', function()
    local src = source
    stop(src)
    pending[src] = nil
    for target, requester in pairs(pending) do
        if requester == src then pending[target] = nil end
    end
end)

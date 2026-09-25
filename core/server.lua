local resource = GetCurrentResourceName()

Utils = {}

function Utils.event(name)
    return ('%s:%s'):format(resource, name)
end

function Utils.playerDistance(a, b)
    local pedA, pedB = GetPlayerPed(a), GetPlayerPed(b)
    if pedA == 0 or pedB == 0 then return nil end
    return #(GetEntityCoords(pedA) - GetEntityCoords(pedB))
end

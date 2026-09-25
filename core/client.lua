local resource = GetCurrentResourceName()

Cache = {
    resource = resource,
    playerId = PlayerId(),
    serverId = GetPlayerServerId(PlayerId()),
    ped = PlayerPedId(),
    vehicle = false,
    seat = false,
}

local listeners = {}

function OnCache(key, cb)
    listeners[key] = listeners[key] or {}
    listeners[key][#listeners[key] + 1] = cb
end

local function set(key, value)
    local old = Cache[key]
    if old == value then return end

    Cache[key] = value
    for _, cb in ipairs(listeners[key] or {}) do
        CreateThread(function() cb(value, old) end)
    end
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()

        if ped ~= 0 then
            set('ped', ped)

            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 then
                if vehicle ~= Cache.vehicle then set('seat', false) end
                set('vehicle', vehicle)

                if not Cache.seat or GetPedInVehicleSeat(vehicle, Cache.seat) ~= ped then
                    for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                        if GetPedInVehicleSeat(vehicle, seat) == ped then
                            set('seat', seat)
                            break
                        end
                    end
                end
            else
                set('vehicle', false)
                set('seat', false)
            end
        end

        Wait(100)
    end
end)

Utils = {}

function Utils.event(name)
    return ('%s:%s'):format(resource, name)
end

function Utils.requestAnimDict(dict, timeout)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)

    local expires = GetGameTimer() + (timeout or 3000)
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > expires then return false end
        Wait(0)
    end
    return true
end

function Utils.requestModel(model, timeout)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return nil end
    if HasModelLoaded(hash) then return hash end
    RequestModel(hash)

    local expires = GetGameTimer() + (timeout or 5000)
    while not HasModelLoaded(hash) do
        if GetGameTimer() > expires then return nil end
        Wait(0)
    end
    return hash
end

function Utils.helpText(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

function Utils.drawText3D(coords, text, scale)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextScale(0.0, scale or 0.35)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextOutline()
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

function Utils.closestPlayer(radius)
    local coords = GetEntityCoords(Cache.ped)
    local closest, closestDistance

    for _, player in ipairs(GetActivePlayers()) do
        if player ~= Cache.playerId then
            local distance = #(GetEntityCoords(GetPlayerPed(player)) - coords)
            if distance <= radius and (not closestDistance or distance < closestDistance) then
                closest, closestDistance = player, distance
            end
        end
    end

    return closest, closestDistance
end

function Utils.keybind(command, description, key)
    RegisterKeyMapping(command, description, 'keyboard', key or '')
end

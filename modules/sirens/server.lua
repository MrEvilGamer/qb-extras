local cfg = Config.Sirens
if not cfg.Enabled then return end

local VEHICLE_TYPE = 2

local function isState(value)
    return value == 0 or value == 1 or value == 2 or value == 3
end

local validators = {
    valIndicator = isState,
    valSiren = isState,
    valHorn = isState,
    valPowercall = function(value) return type(value) == 'boolean' end,
}

RegisterNetEvent(Utils.event('sirens:set'), function(netId, key, value)
    local validate = validators[key]
    if type(netId) ~= 'number' or not validate or not validate(value) then return end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if vehicle == 0 or GetEntityType(vehicle) ~= VEHICLE_TYPE then return end
    if GetPedInVehicleSeat(vehicle, -1) ~= GetPlayerPed(source) then return end

    local state = Entity(vehicle).state
    if state[key] ~= value then state:set(key, value, true) end
end)

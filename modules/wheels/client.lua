local cfg = Config.KeepWheelsTurned
if not cfg.Enabled then return end

local SAMPLE_INTERVAL = 100
local STRAIGHT_SPEED = 1.0

local function track(vehicle)
    local ped = Cache.ped
    local angle

    while DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == ped do
        local current = GetVehicleSteeringAngle(vehicle)

        if math.abs(current) >= cfg.MinAngle then
            angle = current
        elseif GetEntitySpeed(vehicle) > STRAIGHT_SPEED then
            angle = nil
        end

        Wait(SAMPLE_INTERVAL)
    end

    if not angle or not DoesEntityExist(vehicle) then return end

    local holdUntil = GetGameTimer() + cfg.RestoreFor
    while GetGameTimer() < holdUntil
        and DoesEntityExist(vehicle)
        and GetPedInVehicleSeat(vehicle, -1) == 0
        and GetEntitySpeed(vehicle) <= 0.1 do
        SetVehicleSteeringAngle(vehicle, angle)
        Wait(0)
    end
end

OnCache('seat', function(seat)
    if seat == -1 and Cache.vehicle then track(Cache.vehicle) end
end)

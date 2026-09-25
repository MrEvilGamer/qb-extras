local cfg = Config.Tweaks
if not cfg.Enabled then return end

local FLAG_PUT_ON_MOTORCYCLE_HELMET = 35
local INPUT_VEH_MOVE_LR = 59
local INPUT_VEH_MOVE_UD = 60
local AIR_CONTROL_EXEMPT = { [8] = true, [13] = true, [14] = true, [15] = true, [16] = true, [21] = true }

local function applyPed(ped)
    if cfg.NoBikeHelmet then SetPedConfigFlag(ped, FLAG_PUT_ON_MOTORCYCLE_HELMET, false) end
    if cfg.KeepHatsOnHit then SetPedCanLosePropsOnDamage(ped, false, 0) end
end

local function applyWorld()
    if cfg.DisableIdleCam then
        DisableIdleCamera(true)
        DisableVehiclePassengerIdleCamera(true)
    end

    if cfg.NoWantedLevel then
        SetMaxWantedLevel(0)
        SetPlayerWantedLevel(Cache.playerId, 0, false)
        SetPlayerWantedLevelNow(Cache.playerId, false)
        for service = 1, 15 do EnableDispatchService(service, false) end
        SetAudioFlag('PoliceScannerDisabled', true)
    end

    if cfg.DisableRadio then SetUserRadioControlEnabled(false) end
end

applyPed(Cache.ped)
applyWorld()
OnCache('ped', applyPed)
Bridge.onLoaded(function()
    applyPed(Cache.ped)
    applyWorld()
end)

if cfg.DisableRadio then
    OnCache('vehicle', function(vehicle)
        if not vehicle then return end
        SetUserRadioControlEnabled(false)
        SetVehRadioStation(vehicle, 'OFF')
        SetVehicleRadioEnabled(vehicle, false)
    end)
end

local density = cfg.Density
if not (density or cfg.NoVehicleRewards or cfg.NoAirControl) then return end

CreateThread(function()
    while true do
        local sleep = 250
        local ped, vehicle = Cache.ped, Cache.vehicle

        if density then
            sleep = 0
            SetPedDensityMultiplierThisFrame(density.Peds)
            SetScenarioPedDensityMultiplierThisFrame(density.Scenario, density.Scenario)
            SetVehicleDensityMultiplierThisFrame(density.Vehicles)
            SetRandomVehicleDensityMultiplierThisFrame(density.Vehicles)
            SetParkedVehicleDensityMultiplierThisFrame(density.Parked)
        end

        if cfg.NoVehicleRewards and (vehicle or GetVehiclePedIsTryingToEnter(ped) ~= 0) then
            sleep = 0
            DisablePlayerVehicleRewards(Cache.playerId)
        end

        if cfg.NoAirControl and vehicle and not AIR_CONTROL_EXEMPT[GetVehicleClass(vehicle)] then
            sleep = 0
            if IsEntityInAir(vehicle) then
                DisableControlAction(0, INPUT_VEH_MOVE_LR, true)
                DisableControlAction(0, INPUT_VEH_MOVE_UD, true)
            end
        end

        Wait(sleep)
    end
end)

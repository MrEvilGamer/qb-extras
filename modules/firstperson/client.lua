local cfg = Config.FirstPersonAim
if not cfg.Enabled then return end

local FIRST_PERSON = 4
local GUNS_AND_THROWABLES = 6

local saved

local function getMode(inVehicle)
    return inVehicle and GetFollowVehicleCamViewMode() or GetFollowPedCamViewMode()
end

local function setMode(inVehicle, mode)
    if inVehicle then
        SetFollowVehicleCamViewMode(mode)
    else
        SetFollowPedCamViewMode(mode)
    end
end

local function restoreView()
    if not saved then return end
    setMode(saved.inVehicle, saved.mode)
    saved = nil
end

CreateThread(function()
    while true do
        local sleep = 250
        local inVehicle = Cache.vehicle ~= false

        if (inVehicle or cfg.OnFoot) and IsPedArmed(Cache.ped, GUNS_AND_THROWABLES) then
            sleep = 0

            if IsPlayerFreeAiming(Cache.playerId) then
                if saved and saved.inVehicle ~= inVehicle then restoreView() end
                if not saved then saved = { inVehicle = inVehicle, mode = getMode(inVehicle) } end

                if getMode(inVehicle) ~= FIRST_PERSON then setMode(inVehicle, FIRST_PERSON) end
            else
                restoreView()
            end
        else
            restoreView()
        end

        Wait(sleep)
    end
end)

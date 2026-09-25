local cfg = Config.PauseMap
if not cfg.Enabled then return end

local DICT = 'amb@world_human_tourist_map@male@idle_b'
local ANIM = 'idle_d'
local PROP = `p_tourist_map_01_s`
local BONE = 28422

local prop

local function canHoldMap(ped)
    return not Cache.vehicle
        and IsPedOnFoot(ped)
        and not Bridge.isDowned()
        and not IsPedRagdoll(ped)
        and not IsPedSwimming(ped)
        and not IsPedFalling(ped)
        and not IsPedCuffed(ped)
        and not IsEntityAttached(ped)
end

local function start()
    local ped = Cache.ped
    if not canHoldMap(ped) then return end
    if not Utils.requestAnimDict(DICT) or not Utils.requestModel(PROP) then return end

    local coords = GetEntityCoords(ped)
    prop = CreateObject(PROP, coords.x, coords.y, coords.z + 0.2, true, true, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, BONE), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(PROP)

    TaskPlayAnim(ped, DICT, ANIM, 2.0, 8.0, -1, 53, 0, false, false, false)
    RemoveAnimDict(DICT)
end

local function stop()
    if not prop then return end

    DeleteEntity(prop)
    prop = nil
    StopAnimTask(Cache.ped, DICT, ANIM, 2.0)
end

CreateThread(function()
    local paused = false

    while true do
        Wait(500)

        if IsPauseMenuActive() then
            if not paused then
                paused = true
                start()
            end
        elseif paused then
            paused = false
            stop()
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name == Cache.resource then stop() end
end)

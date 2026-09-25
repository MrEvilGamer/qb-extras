local cfg = Config.Sirens
if not cfg.Enabled then return end

local SetSirenMuted = SetVehicleHasMutedSirens or DisableVehicleImpactExplosionActivation

local IND_OFF, IND_LEFT, IND_RIGHT, IND_HAZARD = 0, 1, 2, 3
local EMERGENCY_CLASS = 18
local SKIPPED_CLASSES = { [14] = true, [15] = true, [16] = true, [21] = true }
local AUTO_OFF_SPEED = 6.0
local RESYNC_INTERVAL = 2000

local BAG = {
    indicator = 'valIndicator',
    siren = 'valSiren',
    powercall = 'valPowercall',
    horn = 'valHorn',
}

local fireModels, powercallModels = {}, {}
for _, model in ipairs(cfg.FireSirenModels) do fireModels[joaat(model)] = true end
for _, model in ipairs(cfg.PowercallModels) do powercallModels[joaat(model)] = true end

local state = { indicator = {}, siren = {}, powercall = {}, horn = {} }
local sounds = { siren = {}, powercall = {}, horn = {} }
local playingSiren = {}

local driving
local manualHeld, airhornHeld = false, false

local function exists(veh)
    return veh and DoesEntityExist(veh) and not IsEntityDead(veh)
end

local function isFire(veh)
    return fireModels[GetEntityModel(veh)] == true
end

local function beep(on)
    PlaySoundFrontend(-1, on and 'NAV_LEFT_RIGHT' or 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end

local function stopSound(kind, veh)
    local id = sounds[kind][veh]
    if not id then return end
    StopSound(id)
    ReleaseSoundId(id)
    sounds[kind][veh] = nil
end

local function playSound(kind, veh, name)
    stopSound(kind, veh)
    local id = GetSoundId()
    PlaySoundFromEntity(id, name, veh, 0, 0, 0)
    sounds[kind][veh] = id
end

local function sirenSoundFor(veh)
    local tone = state.siren[veh] or 0
    local fire = isFire(veh)

    if tone == 0 or (state.horn[veh] == 1 and not fire) then return nil end
    if tone == 1 then return not fire and 'VEHICLES_HORNS_SIREN_1' or nil end
    if tone == 2 then return 'VEHICLES_HORNS_SIREN_2' end
    return fire and 'VEHICLES_HORNS_AMBULANCE_WARNING' or 'VEHICLES_HORNS_POLICE_WARNING'
end

local function refreshSiren(veh)
    local wanted = sirenSoundFor(veh)
    if playingSiren[veh] ~= wanted then
        stopSound('siren', veh)
        if wanted then playSound('siren', veh, wanted) end
        playingSiren[veh] = wanted
    end

    SetSirenMuted(veh, not (isFire(veh) and state.siren[veh] == 1))
end

local apply = {}

function apply.indicator(veh, value)
    SetVehicleIndicatorLights(veh, 0, value == IND_RIGHT or value == IND_HAZARD)
    SetVehicleIndicatorLights(veh, 1, value == IND_LEFT or value == IND_HAZARD)
    state.indicator[veh] = value
end

function apply.siren(veh, value)
    state.siren[veh] = value
    refreshSiren(veh)
end

function apply.powercall(veh, value)
    if value and not sounds.powercall[veh] then
        local sound = powercallModels[GetEntityModel(veh)] and 'VEHICLES_HORNS_AMBULANCE_WARNING' or 'VEHICLES_HORNS_SIREN_1'
        playSound('powercall', veh, sound)
    elseif not value then
        stopSound('powercall', veh)
    end
    state.powercall[veh] = value
end

function apply.horn(veh, value)
    if state.horn[veh] ~= value then
        stopSound('horn', veh)
        if value == 1 then
            playSound('horn', veh, isFire(veh) and 'VEHICLES_HORNS_FIRETRUCK_WARNING' or 'SIRENS_AIRHORN')
        elseif value == 2 then
            playSound('horn', veh, 'VEHICLES_HORNS_SIREN_1')
        elseif value == 3 then
            playSound('horn', veh, 'VEHICLES_HORNS_SIREN_2')
        end
        state.horn[veh] = value
    end
    refreshSiren(veh)
end

local function send(veh, key, value)
    if NetworkGetEntityIsNetworked(veh) then
        TriggerServerEvent(Utils.event('sirens:set'), VehToNet(veh), BAG[key], value)
    end
end

local function set(veh, key, value)
    if not exists(veh) then return end
    apply[key](veh, value)
    send(veh, key, value)
end

local function resync(veh, emergency)
    if not NetworkGetEntityIsNetworked(veh) then return end
    local bag = Entity(veh).state

    local function check(key, default)
        local value = state[key][veh]
        local synced = bag[BAG[key]]
        if value == nil or synced == value then return end
        if synced == nil and value == default and not (emergency and key == 'siren') then return end
        send(veh, key, value)
    end

    check('indicator', IND_OFF)
    if emergency then
        check('siren', 0)
        check('powercall', false)
        check('horn', 0)
    end
end

local function hornState(veh)
    local manual = manualHeld and (state.siren[veh] or 0) == 0
    if airhornHeld and manual then return 3 end
    if manual then return 2 end
    if airhornHeld then return 1 end
    return 0
end

local function driveLoop(veh)
    if driving == veh or not exists(veh) then return end

    local class = GetVehicleClass(veh)
    if SKIPPED_CLASSES[class] then return end

    local emergency = class == EMERGENCY_CLASS
    driving = veh

    state.indicator[veh] = state.indicator[veh] or IND_OFF
    if emergency then
        state.siren[veh] = state.siren[veh] or 0
        state.powercall[veh] = state.powercall[veh] or false
        state.horn[veh] = state.horn[veh] or 0
        SetVehRadioStation(veh, 'OFF')
        SetVehicleRadioEnabled(veh, false)
        refreshSiren(veh)
    end

    local movingSince
    local resyncAt = 0

    while Cache.vehicle == veh and Cache.seat == -1 and exists(veh) do
        DisableControlAction(0, 83, true)
        DisableControlAction(0, 84, true)

        if emergency then
            DisableControlAction(0, 19, true)
            DisableControlAction(0, 80, true)
            DisableControlAction(0, 81, true)
            DisableControlAction(0, 82, true)
            DisableControlAction(0, 85, true)
            DisableControlAction(0, 86, true)
            DisableControlAction(0, 172, true)

            if not IsVehicleSirenOn(veh) then
                if state.siren[veh] > 0 then
                    beep(false)
                    set(veh, 'siren', 0)
                end
                if state.powercall[veh] then
                    beep(false)
                    set(veh, 'powercall', false)
                end
            end

            local horn = IsPauseMenuActive() and 0 or hornState(veh)
            if horn ~= state.horn[veh] then set(veh, 'horn', horn) end
        end

        local now = GetGameTimer()
        local signal = state.indicator[veh]

        if cfg.IndicatorAutoOff > 0 and (signal == IND_LEFT or signal == IND_RIGHT) then
            if GetEntitySpeed(veh) < AUTO_OFF_SPEED then
                movingSince = nil
            elseif not movingSince then
                movingSince = now
            elseif now - movingSince > cfg.IndicatorAutoOff then
                movingSince = nil
                beep(false)
                set(veh, 'indicator', IND_OFF)
            end
        else
            movingSince = nil
        end

        if now >= resyncAt then
            resyncAt = now + RESYNC_INTERVAL
            resync(veh, emergency)
        end

        Wait(0)
    end

    manualHeld, airhornHeld = false, false
    if emergency and exists(veh) and state.horn[veh] ~= 0 then apply.horn(veh, 0) end
    driving = nil
end

OnCache('seat', function(seat)
    if seat == -1 and Cache.vehicle then driveLoop(Cache.vehicle) end
end)

for key, bagKey in pairs(BAG) do
    AddStateBagChangeHandler(bagKey, nil, function(bagName, _, value)
        if value == nil then return end

        CreateThread(function()
            local veh = GetEntityFromStateBagName(bagName)
            local giveUpAt = GetGameTimer() + 2000
            while veh == 0 do
                if GetGameTimer() > giveUpAt then return end
                Wait(0)
                veh = GetEntityFromStateBagName(bagName)
            end

            if not exists(veh) or GetPedInVehicleSeat(veh, -1) == Cache.ped then return end
            apply[key](veh, value)
        end)
    end)
end

CreateThread(function()
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if NetworkGetEntityIsNetworked(veh) and exists(veh) and GetPedInVehicleSeat(veh, -1) ~= Cache.ped then
            local bag = Entity(veh).state
            for key, bagKey in pairs(BAG) do
                local value = bag[bagKey]
                if value ~= nil then apply[key](veh, value) end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(2000)

        for kind, list in pairs(sounds) do
            for veh in pairs(list) do
                if not exists(veh) then
                    stopSound(kind, veh)
                elseif kind == 'horn' and IsVehicleSeatFree(veh, -1) then
                    apply.horn(veh, 0)
                end
            end
        end

        for _, list in pairs(state) do
            for veh in pairs(list) do
                if not DoesEntityExist(veh) then list[veh] = nil end
            end
        end
        for veh in pairs(playingSiren) do
            if not DoesEntityExist(veh) then playingSiren[veh] = nil end
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= Cache.resource then return end
    for kind, list in pairs(sounds) do
        for veh in pairs(list) do stopSound(kind, veh) end
    end
end)

local keys = cfg.Keys

local function controlledVehicle(emergencyOnly)
    local veh = driving
    if not veh or IsPauseMenuActive() then return nil end
    if emergencyOnly and GetVehicleClass(veh) ~= EMERGENCY_CLASS then return nil end
    return veh
end

local function toggleIndicator(value)
    local veh = controlledVehicle(false)
    if not veh then return end

    local new = state.indicator[veh] == value and IND_OFF or value
    beep(new ~= IND_OFF)
    set(veh, 'indicator', new)
end

local function command(name, description, key, handler)
    RegisterCommand(name, handler, false)
    Utils.keybind(name, description, key)
end

command('val_indicator_left', 'Vehicle: left indicator', keys.IndicatorLeft, function()
    toggleIndicator(IND_LEFT)
end)

command('val_indicator_right', 'Vehicle: right indicator', keys.IndicatorRight, function()
    toggleIndicator(IND_RIGHT)
end)

command('val_hazards', 'Vehicle: hazard lights', keys.Hazards, function()
    toggleIndicator(IND_HAZARD)
end)

command('val_lights', 'Emergency: lights on/off', keys.Lights, function()
    local veh = controlledVehicle(true)
    if not veh then return end

    local on = not IsVehicleSirenOn(veh)
    beep(on)
    SetVehicleSiren(veh, on)
end)

command('val_siren', 'Emergency: siren on/off', keys.Siren, function()
    local veh = controlledVehicle(true)
    if not veh then return end

    if state.siren[veh] == 0 then
        if not IsVehicleSirenOn(veh) then return end
        beep(true)
        set(veh, 'siren', 1)
    else
        beep(false)
        set(veh, 'siren', 0)
    end
end)

command('val_powercall', 'Emergency: auxiliary siren', keys.Powercall, function()
    local veh = controlledVehicle(true)
    if not veh then return end

    if state.powercall[veh] then
        beep(false)
        set(veh, 'powercall', false)
    elseif IsVehicleSirenOn(veh) then
        beep(true)
        set(veh, 'powercall', true)
    end
end)

command('+val_tone', 'Emergency: siren tone / manual siren', keys.Tone, function()
    local veh = controlledVehicle(true)
    if veh and state.siren[veh] == 0 then manualHeld = true end
end)

RegisterCommand('-val_tone', function()
    if manualHeld then
        manualHeld = false
        return
    end

    local veh = controlledVehicle(true)
    if not veh or state.siren[veh] == 0 or not IsVehicleSirenOn(veh) then return end

    beep(true)
    set(veh, 'siren', state.siren[veh] % 3 + 1)
end, false)

command('+val_airhorn', 'Emergency: airhorn', keys.Airhorn, function()
    airhornHeld = true
end)

RegisterCommand('-val_airhorn', function()
    airhornHeld = false
end, false)

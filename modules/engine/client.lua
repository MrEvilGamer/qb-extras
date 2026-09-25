local cfg = Config.Engine
if not cfg.Enabled then return end

RegisterCommand(cfg.Command, function()
    local vehicle = Cache.vehicle
    if not vehicle or Cache.seat ~= -1 then return end

    if not cfg.CanToggle(vehicle) then
        Bridge.notify("You don't have the keys to this vehicle", 'error')
        return
    end

    SetVehicleEngineOn(vehicle, not GetIsVehicleEngineRunning(vehicle), false, true)
end, false)

TriggerEvent('chat:addSuggestion', '/' .. cfg.Command, 'Turn the engine of your vehicle on or off')

if cfg.Key and cfg.Key ~= '' then
    Utils.keybind(cfg.Command, 'Vehicle: engine on/off', cfg.Key)
end

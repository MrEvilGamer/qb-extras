local cfg = Config.PropFix
if not cfg.Enabled then return end

RegisterCommand(cfg.Command, function()
    local ped = Cache.ped
    local removed = 0

    for _, object in ipairs(GetGamePool('CObject')) do
        if IsEntityAttachedToEntity(object, ped) then
            DetachEntity(object, true, true)
            SetEntityAsMissionEntity(object, true, true)
            DeleteObject(object)
            removed = removed + 1
        end
    end

    if cfg.ClearTasks then ClearPedTasks(ped) end

    Bridge.notify(('Removed %d stuck prop(s)'):format(removed), 'success')
end, false)

TriggerEvent('chat:addSuggestion', '/' .. cfg.Command, 'Remove props stuck to your character')

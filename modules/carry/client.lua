local cfg = Config.Carry
if not cfg.Enabled then return end

local INPUT_ACCEPT = 246
local INPUT_DECLINE = 73

local ANIMS = {
    carrier = { dict = 'missfinale_c2mcs_1', name = 'fin_c2_mcs_1_camman', flag = 49 },
    carried = { dict = 'nm', name = 'firemans_carry', flag = 33 },
}
local CARRIED_OFFSET = vec3(0.27, 0.15, 0.63)
local CARRIED_ROTATION = vec3(0.5, 0.5, 180.0)

local role, partner

local function stopLocal()
    if not role then return end

    local anim = ANIMS[role]
    StopAnimTask(Cache.ped, anim.dict, anim.name, 1.0)
    if role == 'carried' then DetachEntity(Cache.ped, true, false) end
    RemoveAnimDict(anim.dict)
    role, partner = nil, nil
end

RegisterCommand(cfg.Command, function()
    if role then
        TriggerServerEvent(Utils.event('carry:stop'))
        return
    end

    if Cache.vehicle or Bridge.isDowned() then return end

    local player = Utils.closestPlayer(cfg.MaxDistance)
    if not player then
        Bridge.notify('No one close enough to carry', 'error')
        return
    end

    TriggerServerEvent(Utils.event('carry:request'), GetPlayerServerId(player))
end, false)

TriggerEvent('chat:addSuggestion', '/' .. cfg.Command, 'Carry the closest player, or put them down')

RegisterNetEvent(Utils.event('carry:prompt'), function(from)
    local expires = GetGameTimer() + cfg.RequestTimeout * 1000
    local accepted = false

    while GetGameTimer() < expires do
        Utils.helpText(('[%s] wants to carry you~n~~INPUT_MP_TEXT_CHAT_TEAM~ Accept   ~INPUT_VEH_DUCK~ Decline'):format(from))

        if IsControlJustPressed(0, INPUT_ACCEPT) then
            accepted = true
            break
        elseif IsControlJustPressed(0, INPUT_DECLINE) then
            break
        end
        Wait(0)
    end

    TriggerServerEvent(Utils.event('carry:respond'), accepted)
end)

RegisterNetEvent(Utils.event('carry:start'), function(newRole, other)
    stopLocal()
    role, partner = newRole, other

    local anim = ANIMS[role]
    Utils.requestAnimDict(anim.dict)

    if role == 'carried' then
        local carrierPed = GetPlayerPed(GetPlayerFromServerId(other))
        AttachEntityToEntity(Cache.ped, carrierPed, 0,
            CARRIED_OFFSET.x, CARRIED_OFFSET.y, CARRIED_OFFSET.z,
            CARRIED_ROTATION.x, CARRIED_ROTATION.y, CARRIED_ROTATION.z,
            false, false, false, false, 2, false)
    end

    while role == newRole and partner == other do
        local ped = Cache.ped

        local lost = GetPlayerFromServerId(other) == -1
        local unable = role == 'carrier' and (Cache.vehicle or IsPedRagdoll(ped) or IsEntityDead(ped))
        if lost or unable then
            TriggerServerEvent(Utils.event('carry:stop'))
            break
        end

        if not IsEntityPlayingAnim(ped, anim.dict, anim.name, 3) then
            TaskPlayAnim(ped, anim.dict, anim.name, 8.0, -8.0, -1, anim.flag, 0, false, false, false)
        end
        Wait(250)
    end
end)

RegisterNetEvent(Utils.event('carry:stopped'), stopLocal)

AddEventHandler('onResourceStop', function(name)
    if name == Cache.resource then stopLocal() end
end)

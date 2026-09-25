local function isStarted(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local function detect()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if isStarted('qbx_core') then return 'qbx' end
    if isStarted('qb-core') then return 'qb' end
    return 'standalone'
end

local framework = detect()
local QBCore = framework == 'qb' and exports['qb-core']:GetCoreObject() or nil

Bridge = {
    framework = framework,
}

local function getPlayer(source)
    if framework == 'qbx' then return exports.qbx_core:GetPlayer(source) end
    if framework == 'qb' then return QBCore.Functions.GetPlayer(source) end
end

function Bridge.notify(source, message, kind, duration)
    kind = kind or 'inform'

    if framework == 'qbx' then
        exports.qbx_core:Notify(source, message, kind, duration)
    elseif framework == 'qb' then
        TriggerClientEvent('QBCore:Notify', source, message, kind == 'inform' and 'primary' or kind, duration)
    else
        TriggerClientEvent(Utils.event('notify'), source, message, kind, duration)
    end
end

function Bridge.isDowned(source)
    local player = getPlayer(source)
    local metadata = player and player.PlayerData.metadata
    return metadata and (metadata.isdead or metadata.inlaststand) or false
end

print(('[%s] running with framework: %s'):format(GetCurrentResourceName(), framework))

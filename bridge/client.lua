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
local hasOxInventory = isStarted('ox_inventory')

Bridge = {
    framework = framework,
    PlayerData = {},
}

local loadedHandlers, unloadedHandlers, dataHandlers = {}, {}, {}
local loaded = false

local function fetchPlayerData()
    if framework == 'qbx' then return exports.qbx_core:GetPlayerData() or {} end
    if framework == 'qb' then return QBCore.Functions.GetPlayerData() or {} end
    return {}
end

local function markLoaded()
    if loaded then return end
    loaded = true
    for _, cb in ipairs(loadedHandlers) do CreateThread(cb) end
end

function Bridge.onLoaded(cb)
    loadedHandlers[#loadedHandlers + 1] = cb
    if loaded then CreateThread(cb) end
end

function Bridge.onUnloaded(cb)
    unloadedHandlers[#unloadedHandlers + 1] = cb
end

function Bridge.onPlayerData(cb)
    dataHandlers[#dataHandlers + 1] = cb
end

function Bridge.isLoaded()
    return loaded
end

if framework == 'standalone' then
    CreateThread(markLoaded)
else
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Bridge.PlayerData = fetchPlayerData()
        markLoaded()
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        loaded = false
        Bridge.PlayerData = {}
        for _, cb in ipairs(unloadedHandlers) do CreateThread(cb) end
    end)

    RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
        Bridge.PlayerData = data or {}
        for _, cb in ipairs(dataHandlers) do CreateThread(function() cb(Bridge.PlayerData) end) end
    end)

    CreateThread(function()
        local data = fetchPlayerData()
        if data.citizenid then
            Bridge.PlayerData = data
            markLoaded()
        end
    end)
end

function Bridge.notify(message, kind, duration)
    kind = kind or 'inform'

    if framework == 'qbx' then
        exports.qbx_core:Notify(message, kind, duration)
    elseif framework == 'qb' then
        QBCore.Functions.Notify(message, kind == 'inform' and 'primary' or kind, duration)
    elseif isStarted('ox_lib') then
        TriggerEvent('ox_lib:notify', { description = message, type = kind, duration = duration })
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

RegisterNetEvent(Utils.event('notify'), Bridge.notify)

function Bridge.isDowned()
    local metadata = Bridge.PlayerData.metadata
    if metadata and (metadata.isdead or metadata.inlaststand) then return true end
    return IsEntityDead(Cache.ped)
end

function Bridge.getNeeds()
    if framework == 'qbx' then
        local state = LocalPlayer.state
        return state.hunger, state.thirst
    end

    local metadata = Bridge.PlayerData.metadata
    if metadata then return metadata.hunger, metadata.thirst end
end

function Bridge.getItems()
    local items = {}
    local source

    if hasOxInventory then
        source = exports.ox_inventory:GetPlayerItems()
    else
        source = Bridge.PlayerData.items
    end

    for _, item in pairs(source or {}) do
        if item and item.name then
            local name = item.name:lower()
            items[name] = (items[name] or 0) + (item.count or item.amount or 1)
        end
    end

    return items
end

function Bridge.onItemsChanged(cb)
    if hasOxInventory then
        AddEventHandler('ox_inventory:updateInventory', function() cb() end)
    elseif framework ~= 'standalone' then
        Bridge.onPlayerData(function() cb() end)
    end
end

function Bridge.hasInventory()
    return hasOxInventory or framework == 'qb'
end

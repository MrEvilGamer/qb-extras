local cfg = Config.PlayerIds
if not cfg.Enabled then return end

local HEAD_BONE = 31086
local LOS_FLAGS = 17

local showing = false

local function collectNearby()
    local list = {}
    local ownPed = Cache.ped
    local coords = GetEntityCoords(ownPed)

    for _, player in ipairs(GetActivePlayers()) do
        local isSelf = player == Cache.playerId
        if not isSelf or cfg.ShowOwn then
            local ped = GetPlayerPed(player)
            local visible = IsEntityVisible(ped) and #(GetEntityCoords(ped) - coords) <= cfg.Distance
            if visible and (isSelf or HasEntityClearLosToEntity(ownPed, ped, LOS_FLAGS)) then
                list[#list + 1] = { ped = ped, player = player, id = tostring(GetPlayerServerId(player)) }
            end
        end
    end

    return list
end

local function drawLoop()
    local nearby, refreshAt = {}, 0

    while showing do
        if GetGameTimer() >= refreshAt then
            nearby = collectNearby()
            refreshAt = GetGameTimer() + 250
        end

        for i = 1, #nearby do
            local entry = nearby[i]
            if DoesEntityExist(entry.ped) then
                local head = GetPedBoneCoords(entry.ped, HEAD_BONE, 0.0, 0.0, 0.0)
                local label = NetworkIsPlayerTalking(entry.player) and ('~b~%s'):format(entry.id) or entry.id
                Utils.drawText3D(head + vector3(0.0, 0.0, 0.35), label, 0.45)
            end
        end

        Wait(0)
    end
end

RegisterCommand('+val_playerids', function()
    if showing then return end
    showing = true
    CreateThread(drawLoop)
end, false)

RegisterCommand('-val_playerids', function()
    showing = false
end, false)

Utils.keybind('+val_playerids', 'Show player IDs (hold)', cfg.Key)

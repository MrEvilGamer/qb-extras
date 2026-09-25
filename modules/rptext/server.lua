local cfg = Config.RpText
if not cfg.Enabled then return end

local lastUse = {}

local function broadcast(source, kind, text)
    local now = GetGameTimer()
    if lastUse[source] and now - lastUse[source] < cfg.Cooldown then return end
    lastUse[source] = now

    text = text:gsub('~', ''):sub(1, cfg.MaxLength)
    if text == '' then return end

    local coords = GetEntityCoords(GetPlayerPed(source))
    for _, player in ipairs(GetPlayers()) do
        local ped = GetPlayerPed(player)
        if ped ~= 0 and #(GetEntityCoords(ped) - coords) <= cfg.Distance then
            TriggerClientEvent(Utils.event('rptext:show'), player, source, kind, text)
        end
    end
end

for kind, command in pairs(cfg.Commands) do
    RegisterCommand(command, function(source, args)
        if source == 0 then return end
        broadcast(source, kind, table.concat(args, ' '))
    end, false)
end

AddEventHandler('playerDropped', function()
    lastUse[source] = nil
end)

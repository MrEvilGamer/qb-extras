local cfg = Config.RpText
if not cfg.Enabled then return end

local HEAD_BONE = 31086
local STACK_SPACING = 0.12

local COLORS = {
    me = '~p~',
    ['do'] = '~o~',
}

local messages = {}
local drawing = false

local function drawLoop()
    drawing = true

    while #messages > 0 do
        local now = GetGameTimer()
        local stacks = {}

        for i = #messages, 1, -1 do
            local message = messages[i]
            local player = GetPlayerFromServerId(message.source)

            if now > message.expires or player == -1 then
                table.remove(messages, i)
            else
                local ped = GetPlayerPed(player)
                local offset = stacks[ped] or 0
                stacks[ped] = offset + 1

                local head = GetPedBoneCoords(ped, HEAD_BONE, 0.0, 0.0, 0.0)
                Utils.drawText3D(head + vector3(0.0, 0.0, 0.45 + offset * STACK_SPACING), message.text, 0.35)
            end
        end

        Wait(0)
    end

    drawing = false
end

RegisterNetEvent(Utils.event('rptext:show'), function(source, kind, text)
    messages[#messages + 1] = {
        source = source,
        text = ('%s* %s *'):format(COLORS[kind] or '', text),
        expires = GetGameTimer() + cfg.Duration,
    }

    if not drawing then CreateThread(drawLoop) end
end)

for kind, command in pairs(cfg.Commands) do
    TriggerEvent('chat:addSuggestion', '/' .. command, kind == 'me' and 'Describe an action' or 'Describe the scene', {
        { name = 'text', help = 'What people nearby will see' },
    })
end

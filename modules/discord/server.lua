local cfg = Config.DiscordPresence
if not cfg.Enabled then return end

GlobalState[Utils.event('maxPlayers')] = GetConvarInt('sv_maxclients', 48)

CreateThread(function()
    while true do
        GlobalState[Utils.event('players')] = #GetPlayers()
        Wait(30000)
    end
end)

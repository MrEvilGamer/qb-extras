QBCore = exports['qb-core']:GetCoreObject()

QBCore.Commands.Add("poop", "Cant make me poop?", {{name = "id", help = "Player ID"}}, false, function(source, args)
	local src = source
    local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
	if args[1] then
		if Player then
            TriggerClientEvent('just-poop-it', Player.PlayerData.source)
		else
			TriggerClientEvent('QBCore:Notify', src, 'Player Not Online!', "error")
		end
	else
		TriggerClientEvent('just-poop-it', src)
	end
    Wait(60000)
    TriggerClientEvent('chat:addMessage', Player.PlayerData.source, {
        color = {255, 0, 0},
        multiline = true,
        args = {'You are Feeling Relaxed :)'}
    })
end, "god")
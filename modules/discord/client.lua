local cfg = Config.DiscordPresence
if not cfg.Enabled or cfg.AppId == '' then return end

local function format(text)
    return (text:gsub('{(%w+)}', {
        name = GetPlayerName(Cache.playerId),
        id = tostring(Cache.serverId),
        players = tostring(GlobalState[Utils.event('players')] or #GetActivePlayers()),
        max = tostring(GlobalState[Utils.event('maxPlayers')] or '?'),
    }))
end

SetDiscordAppId(cfg.AppId)
SetDiscordRichPresenceAsset(cfg.LargeImage)
SetDiscordRichPresenceAssetText(cfg.LargeText)

for index, button in ipairs(cfg.Buttons) do
    if index > 2 then break end
    SetDiscordRichPresenceAction(index - 1, button.label, button.url)
end

CreateThread(function()
    while true do
        SetRichPresence(format(cfg.Text))
        Wait(cfg.UpdateInterval * 1000)
    end
end)

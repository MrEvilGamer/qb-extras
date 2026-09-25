local cfg = Config.NeedsAlerts
if not cfg.Enabled or Bridge.framework == 'standalone' then return end

local function warn(value, message)
    if not value or value <= 0 or value > cfg.Threshold then return false end
    Bridge.notify(message, 'warning', 4000)
    return true
end

CreateThread(function()
    while true do
        Wait(cfg.Interval * 1000)

        if Bridge.isLoaded() and not Bridge.isDowned() then
            local hunger, thirst = Bridge.getNeeds()
            local warned = warn(hunger, 'You are getting hungry...')
            warned = warn(thirst, 'You are getting thirsty...') or warned

            if warned and cfg.Sound then
                PlaySoundFrontend(-1, 'CHECKPOINT_MISSED', 'HUD_MINI_GAME_SOUNDSET', true)
            end
        end
    end
end)

local cfg = Config.FpsBooster
if not cfg.Enabled then return end

local KVP_KEY = 'fps_preset'

local PRESETS = {
    { id = 'ultralow', label = 'Ultra Low', lod = 0.4, decals = false,
        shadows = { rope = false, aircraft = false, dynamicDepth = false, trackerScale = 0.0, depth = 0.0, bounds = 0.0 } },
    { id = 'low', label = 'Low', lod = 0.6, decals = false,
        shadows = { rope = false, aircraft = false, dynamicDepth = false, trackerScale = 0.0, depth = 0.0, bounds = 0.0 } },
    { id = 'medium', label = 'Medium', lod = 0.8, decals = true,
        shadows = { rope = true, aircraft = false, dynamicDepth = false, trackerScale = 5.0, depth = 3.0, bounds = 3.0 } },
}

local presetsById = {}
for _, preset in ipairs(PRESETS) do presetsById[preset.id] = preset end

local active

local function applyShadows(shadows)
    if not shadows then
        CascadeShadowsInitSession()
        RopeDrawShadowEnabled(true)
        return
    end

    RopeDrawShadowEnabled(shadows.rope)
    CascadeShadowsClearShadowSampleType()
    CascadeShadowsSetAircraftMode(shadows.aircraft)
    CascadeShadowsEnableEntityTracker(true)
    CascadeShadowsSetDynamicDepthMode(shadows.dynamicDepth)
    CascadeShadowsSetEntityTrackerScale(shadows.trackerScale)
    CascadeShadowsSetDynamicDepthValue(shadows.depth)
    CascadeShadowsSetCascadeBoundsScale(shadows.bounds)
end

local function frameLoop()
    while active do
        OverrideLodscaleThisFrame(active.lod)
        if not active.decals then SetDisableDecalRenderingThisFrame() end
        Wait(0)
    end
end

local function setPreset(id, silent)
    local preset = presetsById[id]
    local wasActive = active ~= nil

    active = preset
    applyShadows(preset and preset.shadows)

    if preset then
        SetResourceKvp(KVP_KEY, id)
        if not wasActive then CreateThread(frameLoop) end
    else
        DeleteResourceKvp(KVP_KEY)
    end

    if not silent then
        Bridge.notify(('Graphics preset: %s'):format(preset and preset.label or 'Default'), 'success')
    end
end

AddEventHandler(Utils.event('fps:set'), function(data)
    setPreset(data.preset)
end)

local function openMenu()
    if GetResourceState('ox_lib') == 'started' then
        local options = {}
        for _, preset in ipairs(PRESETS) do
            options[#options + 1] = { title = preset.label, onSelect = function() setPreset(preset.id) end }
        end
        options[#options + 1] = { title = 'Default', description = 'Back to your game settings', onSelect = function() setPreset('reset') end }

        exports.ox_lib:registerContext({ id = 'val_fps', title = 'FPS Booster', options = options })
        exports.ox_lib:showContext('val_fps')
    elseif GetResourceState('qb-menu') == 'started' then
        local menu = { { header = 'FPS Booster', isMenuHeader = true } }
        for _, preset in ipairs(PRESETS) do
            menu[#menu + 1] = { header = preset.label, params = { event = Utils.event('fps:set'), args = { preset = preset.id } } }
        end
        menu[#menu + 1] = { header = 'Default', txt = 'Back to your game settings', params = { event = Utils.event('fps:set'), args = { preset = 'reset' } } }

        exports['qb-menu']:openMenu(menu)
    else
        Bridge.notify(('Usage: /%s ultralow | low | medium | reset'):format(cfg.Command), 'inform')
    end
end

RegisterCommand(cfg.Command, function(_, args)
    local id = args[1] and args[1]:lower()
    if id and (presetsById[id] or id == 'reset') then
        setPreset(id)
    else
        openMenu()
    end
end, false)

TriggerEvent('chat:addSuggestion', '/' .. cfg.Command, 'Graphics presets for more FPS', {
    { name = 'preset', help = 'ultralow, low, medium or reset (leave empty for the menu)' },
})

local saved = GetResourceKvpString(KVP_KEY)
if saved and presetsById[saved] then setPreset(saved, true) end

Config = {}

Config.Framework = 'auto'

Config.AntiHop = {
    Enabled = true,
    Chance = 0.5,
    RagdollDelay = 600,
    RagdollTime = 5000,
    RepeatedJumpsOnly = true,
    RepeatWindow = 3000,
}

Config.Climbing = {
    Enabled = true,
    Cooldown = 900,
    FailedGrabCooldown = 450,
    DetectDistance = 3.0,
    ArmReachDistance = 1.15,
    TopMinOffset = -0.35,
    TopMaxOffset = 2.15,
    MaxScanHeight = 3.55,
    MinHorizontalSpeed = 0.45,
    VelocityAssist = 1.05,
    UpwardAssist = 0.18,
    LandingForwardOffset = 0.35,
    NativeStartTimeout = 420,
    NativeClimbTimeout = 1150,
    UseFallbackPlacement = false,
    FallbackDuration = 450,
    AllowedMaterials = nil,
}

Config.Carry = {
    Enabled = true,
    Command = 'carry',
    MaxDistance = 3.0,
    RequireConsent = true,
    RequestTimeout = 10,
}

Config.RpText = {
    Enabled = true,
    Commands = { me = 'me', ['do'] = 'do' },
    Distance = 15.0,
    Duration = 7000,
    MaxLength = 120,
    Cooldown = 1000,
}

Config.PauseMap = {
    Enabled = true,
}

Config.PropFix = {
    Enabled = true,
    Command = 'propfix',
    ClearTasks = true,
}

Config.PlayerIds = {
    Enabled = true,
    Key = 'HOME',
    Distance = 20.0,
    ShowOwn = true,
}

Config.NeedsAlerts = {
    Enabled = true,
    Interval = 120,
    Threshold = 30,
    Sound = true,
}

Config.BackItems = {
    Enabled = true,
    MaxItems = 2,
    FemaleOffset = 0.035,
    Items = {
        markedbills = { model = 'prop_money_bag_01', bone = 24818, pos = vec3(-0.4, -0.17, -0.12), rot = vec3(0.0, 90.0, 0.0) },
        meth = { model = 'hei_prop_pill_bag_01', bone = 24818, pos = vec3(-0.1, -0.17, 0.12), rot = vec3(0.0, 90.0, 0.0) },
        coke_brick = { model = 'bkr_prop_coke_cutblock_01', bone = 24818, pos = vec3(-0.2, -0.17, 0.0), rot = vec3(0.0, 90.0, 90.0) },
        weed_bud = { model = 'bkr_prop_weed_drying_01a', bone = 24818, pos = vec3(-0.2, -0.17, 0.0), rot = vec3(0.0, 90.0, 0.0) },
        weapon_smg = { model = 'w_sb_smg', bone = 24818, pos = vec3(0.0, -0.17, -0.12), rot = vec3(0.0, -180.0, 180.0) },
        weapon_assaultrifle = { model = 'w_ar_assaultrifle', bone = 24818, pos = vec3(0.0, -0.17, -0.05), rot = vec3(0.0, -180.0, 180.0) },
        weapon_carbinerifle = { model = 'w_ar_carbinerifle', bone = 24818, pos = vec3(0.0, -0.17, 0.08), rot = vec3(0.0, -180.0, 180.0) },
        weapon_rpg = { model = 'w_lr_rpg', bone = 24818, pos = vec3(0.2, -0.17, 0.0), rot = vec3(0.0, 180.0, 180.0) },
    },
}

Config.Sirens = {
    Enabled = true,
    IndicatorAutoOff = 3000,
    Keys = {
        IndicatorLeft = 'MINUS',
        IndicatorRight = 'EQUALS',
        Hazards = 'BACK',
        Lights = 'Q',
        Siren = 'LMENU',
        Tone = 'R',
        Powercall = 'UP',
        Airhorn = 'E',
    },
    FireSirenModels = { 'firetruk' },
    PowercallModels = { 'ambulance', 'firetruk', 'lguard' },
}

Config.Engine = {
    Enabled = true,
    Command = 'engine',
    Key = '',
    CanToggle = function(vehicle)
        if GetResourceState('qb-vehiclekeys') == 'started' then
            return exports['qb-vehiclekeys']:HasKeys(GetVehicleNumberPlateText(vehicle))
        end
        return true
    end,
}

Config.KeepWheelsTurned = {
    Enabled = true,
    MinAngle = 2.0,
    RestoreFor = 1500,
}

Config.FirstPersonAim = {
    Enabled = true,
    OnFoot = false,
}

Config.Combat = {
    Enabled = true,
    NoPistolWhip = true,
    NoCombatRoll = true,
    NoBlindFire = false,
    DamageModifiers = {
        Enabled = false,
        Weapons = {
            WEAPON_UNARMED = 0.2,
            WEAPON_NIGHTSTICK = 0.3,
            WEAPON_FLASHLIGHT = 0.3,
            WEAPON_BOTTLE = 0.3,
            WEAPON_KNUCKLE = 0.4,
            WEAPON_HAMMER = 0.4,
            WEAPON_CROWBAR = 0.4,
            WEAPON_BAT = 0.4,
            WEAPON_GOLFCLUB = 0.4,
            WEAPON_POOLCUE = 0.4,
            WEAPON_KNIFE = 0.6,
            WEAPON_DAGGER = 0.6,
            WEAPON_SWITCHBLADE = 0.6,
            WEAPON_MACHETE = 0.7,
            WEAPON_HATCHET = 0.7,
            WEAPON_SNOWBALL = 0.0,
            WEAPON_HIT_BY_WATER_CANNON = 0.0,
        },
    },
}

Config.Tweaks = {
    Enabled = true,
    NoBikeHelmet = true,
    KeepHatsOnHit = true,
    DisableIdleCam = true,
    NoWantedLevel = true,
    NoVehicleRewards = true,
    NoAirControl = true,
    DisableRadio = false,
    Density = false,
}

Config.FpsBooster = {
    Enabled = true,
    Command = 'fps',
}

Config.DiscordPresence = {
    Enabled = false,
    AppId = '',
    LargeImage = 'logo',
    LargeText = 'My Server',
    Text = '{name} [{id}] - {players}/{max} players',
    Buttons = {},
    UpdateInterval = 60,
}

local cfg = Config.Combat
if not cfg.Enabled then return end

local GUNS_AND_THROWABLES = 6

local INPUT_JUMP = 22
local INPUT_ATTACK = 24
local INPUT_AIM = 25
local INPUT_MELEE_LIGHT = 140
local INPUT_MELEE_HEAVY = 141
local INPUT_MELEE_ALTERNATE = 142
local INPUT_ATTACK2 = 257

if cfg.DamageModifiers.Enabled then
    local function applyModifiers()
        for weapon, modifier in pairs(cfg.DamageModifiers.Weapons) do
            SetWeaponDamageModifier(joaat(weapon), modifier)
        end
    end

    applyModifiers()
    Bridge.onLoaded(applyModifiers)
end

if not (cfg.NoPistolWhip or cfg.NoCombatRoll or cfg.NoBlindFire) then return end

CreateThread(function()
    while true do
        local sleep = 250
        local ped = Cache.ped

        if not Cache.vehicle and IsPedArmed(ped, GUNS_AND_THROWABLES) then
            sleep = 0

            if cfg.NoPistolWhip then
                DisableControlAction(0, INPUT_MELEE_LIGHT, true)
                DisableControlAction(0, INPUT_MELEE_HEAVY, true)
                DisableControlAction(0, INPUT_MELEE_ALTERNATE, true)
            end

            if cfg.NoCombatRoll and (IsControlPressed(0, INPUT_AIM) or IsPlayerFreeAiming(Cache.playerId)) then
                DisableControlAction(0, INPUT_JUMP, true)
            end

            if cfg.NoBlindFire and IsPedInCover(ped, false) and not IsPedAimingFromCover(ped) then
                DisableControlAction(0, INPUT_ATTACK, true)
                DisableControlAction(0, INPUT_ATTACK2, true)
            end
        end

        Wait(sleep)
    end
end)

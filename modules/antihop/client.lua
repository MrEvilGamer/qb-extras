local cfg = Config.AntiHop
if not cfg.Enabled then return end

local lastJump = 0
local wasJumping = false

local function isSprintJump(ped)
    return (IsPedSprinting(ped) or IsPedRunning(ped))
        and IsPedOnFoot(ped)
        and not IsPedSwimming(ped)
        and not IsPedRagdoll(ped)
end

local function onJumpStart(ped)
    if not isSprintJump(ped) then return end

    local now = GetGameTimer()
    local repeated = now - lastJump <= cfg.RepeatWindow
    lastJump = now

    if cfg.RepeatedJumpsOnly and not repeated then return end
    if math.random() >= cfg.Chance then return end

    Wait(cfg.RagdollDelay)

    if IsPedClimbing(ped) or not IsPedOnFoot(ped) then return end
    SetPedToRagdoll(ped, cfg.RagdollTime, 1, 2, false, false, false)
end

CreateThread(function()
    while true do
        Wait(100)
        local ped = Cache.ped

        if IsPedClimbing(ped) then
            lastJump = 0
        end

        local jumping = IsPedJumping(ped)
        if jumping and not wasJumping then
            onJumpStart(ped)
            jumping = IsPedJumping(ped)
        end
        wasJumping = jumping
    end
end)

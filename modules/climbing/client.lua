local cfg = Config.Climbing
if not cfg.Enabled then return end

local INPUT_MOVE_LR = 30
local INPUT_MOVE_UD = 31

local isGrabbing = false
local lastGrab = 0
local lastFailedGrab = 0

local function raycast(from, to, ignore)
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, -1, ignore, 4)
    local _, hit, coords, normal, material = GetShapeTestResultIncludingMaterial(handle)
    return hit == 1, coords, normal, material
end

local function normalize2d(vec)
    local length = math.sqrt(vec.x * vec.x + vec.y * vec.y)
    if length <= 0.001 then return nil, 0.0 end
    return vector3(vec.x / length, vec.y / length, 0.0), length
end

local function distance2d(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

local function isAirborne(ped)
    return IsPedJumping(ped) or IsPedFalling(ped)
end

local function inputDirection(ped)
    local forward = GetEntityForwardVector(ped)
    local moveX = GetDisabledControlNormal(0, INPUT_MOVE_LR)
    local moveY = GetDisabledControlNormal(0, INPUT_MOVE_UD)

    if math.abs(moveX) < 0.05 and math.abs(moveY) < 0.05 then
        return normalize2d(forward)
    end

    local heading = math.rad(GetEntityHeading(ped))
    local right = vector3(math.cos(heading), -math.sin(heading), 0.0)
    return normalize2d(vector3(
        forward.x * moveY + right.x * moveX,
        forward.y * moveY + right.y * moveX,
        0.0
    ))
end

local function approachDirection(ped)
    local inputDir = inputDirection(ped)
    local velocityDir, speed = normalize2d(GetEntityVelocity(ped))

    if inputDir and GetDisabledControlNormal(0, INPUT_MOVE_UD) > 0.12 then
        return inputDir, speed
    end
    if velocityDir and speed > 0.2 then
        return velocityDir, speed
    end
    return inputDir or normalize2d(GetEntityForwardVector(ped)), speed
end

local function canEvaluate(ped)
    if isGrabbing or not isAirborne(ped) then return false end

    local now = GetGameTimer()
    if now - lastGrab < cfg.Cooldown or now - lastFailedGrab < cfg.FailedGrabCooldown then return false end

    return not Cache.vehicle
        and not IsEntityDead(ped)
        and not IsEntityInWater(ped)
        and not IsPedRagdoll(ped)
        and not IsPedGettingUp(ped)
        and not IsPedClimbing(ped)
end

local function materialAllowed(material)
    if not cfg.AllowedMaterials then return true end
    for _, allowed in ipairs(cfg.AllowedMaterials) do
        if allowed == material then return true end
    end
    return false
end

local WALL_HEIGHTS = { 1.45, 1.25, 1.05, 0.85, 0.65, 0.45, 0.25 }

local function findWallFace(ped, pos, dir, distance)
    local best

    for i = 1, #WALL_HEIGHTS do
        local from = pos + vector3(0.0, 0.0, WALL_HEIGHTS[i])
        local hit, coords, normal, material = raycast(from, from + dir * distance, ped)

        if hit and materialAllowed(material) then
            local hitDistance = distance2d(pos, coords)
            if not best or hitDistance < best.distance then
                best = { coords = coords, normal = normal, distance = hitDistance }
            end
        end
    end

    return best
end

local COARSE_STEP, FINE_STEP = 0.24, 0.08

local function findLedgeTop(ped, dir, wall)
    local base = wall.coords - vector3(dir.x * 0.14, dir.y * 0.14, 0.0)
    local reach = dir * 0.58

    local function blocked(up)
        local probe = base + vector3(0.0, 0.0, up)
        return raycast(probe, probe + reach, ped)
    end

    for up = 0.05, cfg.MaxScanHeight, COARSE_STEP do
        if not blocked(up) then
            for fine = math.max(0.05, up - COARSE_STEP + FINE_STEP), up - FINE_STEP, FINE_STEP do
                if not blocked(fine) then return base.z + fine end
            end
            return base.z + up
        end
    end
end

local function findLanding(ped, dir, wall, topZ)
    local above = vector3(wall.coords.x + dir.x * 0.62, wall.coords.y + dir.y * 0.62, topZ + 0.85)
    local floorHit, floor = raycast(above, vector3(above.x, above.y, topZ - 1.35), ped)
    if not floorHit then return nil end

    local landing = vector3(
        floor.x + dir.x * cfg.LandingForwardOffset,
        floor.y + dir.y * cfg.LandingForwardOffset,
        floor.z
    )
    if raycast(landing + vector3(0.0, 0.0, 0.35), landing + vector3(0.0, 0.0, 1.85), ped) then
        return nil
    end
    return landing
end

local function findLedge(ped, maxDistance)
    local dir, speed = approachDirection(ped)
    if not dir then return nil, false end

    if speed < cfg.MinHorizontalSpeed and GetDisabledControlNormal(0, INPUT_MOVE_UD) < 0.12 then
        return nil, false
    end

    local pos = GetEntityCoords(ped)
    local wall = findWallFace(ped, pos, dir, maxDistance or cfg.DetectDistance)
    if not wall then return nil, false end

    if wall.distance > cfg.ArmReachDistance then return nil, true end

    local topZ = findLedgeTop(ped, dir, wall)
    if not topZ then return nil, true end

    local topOffset = topZ - pos.z
    if topOffset < cfg.TopMinOffset or topOffset > cfg.TopMaxOffset then return nil, true end

    local landing = findLanding(ped, dir, wall, topZ)
    if not landing then return nil, true end

    return {
        dir = dir,
        heading = GetHeadingFromVector_2d(dir.x, dir.y),
        landing = landing,
    }, true
end

local function easeMovePed(ped, target, duration, heading)
    local start = GetEntityCoords(ped)
    local startedAt = GetGameTimer()

    while GetGameTimer() - startedAt < duration do
        local progress = (GetGameTimer() - startedAt) / duration
        local eased = 1.0 - (1.0 - progress) * (1.0 - progress)
        local pos = start + (target - start) * eased

        SetEntityVelocity(ped, 0.0, 0.0, 0.0)
        SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, false, false, false)
        SetEntityHeading(ped, heading)
        Wait(0)
    end

    SetEntityCoordsNoOffset(ped, target.x, target.y, target.z, false, false, false)
    SetEntityHeading(ped, heading)
end

local function tryNativeClimb(ped, ledge)
    SetEntityHeading(ped, ledge.heading)
    SetEntityVelocity(ped, ledge.dir.x * cfg.VelocityAssist, ledge.dir.y * cfg.VelocityAssist, cfg.UpwardAssist)
    TaskClimb(ped, true)

    local startBy = GetGameTimer() + cfg.NativeStartTimeout
    while not IsPedClimbing(ped) do
        if GetGameTimer() > startBy then return false end
        Wait(0)
    end

    local finishBy = GetGameTimer() + cfg.NativeClimbTimeout
    while GetGameTimer() < finishBy do
        if not IsPedClimbing(ped) and not isAirborne(ped) then return true end
        Wait(0)
    end

    return not isAirborne(ped)
end

local function grab(ped, ledge)
    isGrabbing = true
    lastGrab = GetGameTimer()
    SetPedCanRagdoll(ped, false)

    local ok = tryNativeClimb(ped, ledge)

    if not ok then
        local nearLanding = #(GetEntityCoords(ped) - ledge.landing) <= 1.8
        if cfg.UseFallbackPlacement and (isAirborne(ped) or not nearLanding) then
            ClearPedTasksImmediately(ped)
            easeMovePed(ped, ledge.landing, cfg.FallbackDuration, ledge.heading)
        else
            lastFailedGrab = GetGameTimer()
        end
    end

    SetPedCanRagdoll(ped, true)
    isGrabbing = false
    return ok
end

CreateThread(function()
    while true do
        local sleep = 120
        local ped = Cache.ped

        if canEvaluate(ped) then
            local ledge, nearWall = findLedge(ped)
            if ledge then
                grab(ped, ledge)
            elseif nearWall then
                sleep = 0
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= Cache.resource or not isGrabbing then return end
    ClearPedTasksImmediately(Cache.ped)
    SetPedCanRagdoll(Cache.ped, true)
end)

exports('TriggerLedgeClimb', function()
    local ped = Cache.ped
    if isGrabbing or GetGameTimer() - lastGrab < cfg.Cooldown then return false end

    local ledge = findLedge(ped, cfg.ArmReachDistance)
    if ledge then
        CreateThread(function() grab(ped, ledge) end)
        return true
    end

    lastFailedGrab = GetGameTimer()
    return false
end)

exports('IsMantling', function()
    return isGrabbing
end)

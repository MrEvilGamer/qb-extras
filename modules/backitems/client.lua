local cfg = Config.BackItems
if not cfg.Enabled or not Bridge.hasInventory() then return end

local FEMALE_MODEL = `mp_f_freemode_01`

local definitions, order = {}, {}
for name, def in pairs(cfg.Items) do
    name = name:lower()
    definitions[name] = def
    order[#order + 1] = name
    if name:find('^weapon_') then def.weaponHash = joaat(name) end
end
table.sort(order)

local inventory = {}
local attached = {}
local refreshing = false

local function remove(name)
    local object = attached[name]
    if object and DoesEntityExist(object) then DeleteEntity(object) end
    attached[name] = nil
end

local function removeAll()
    for name in pairs(attached) do remove(name) end
end

local function create(name, ped)
    local def = definitions[name]
    local model = Utils.requestModel(def.model)
    if not model then return end

    local object = CreateObject(model, 1.0, 1.0, 1.0, true, true, false)
    SetModelAsNoLongerNeeded(model)

    local y = def.pos.y + (GetEntityModel(ped) == FEMALE_MODEL and cfg.FemaleOffset or 0.0)
    AttachEntityToEntity(object, ped, GetPedBoneIndex(ped, def.bone),
        def.pos.x, y, def.pos.z, def.rot.x, def.rot.y, def.rot.z,
        false, true, false, true, 0, true)
    attached[name] = object
end

local function wanted(ped)
    local list = {}
    if not Bridge.isLoaded() or Cache.vehicle then return list end

    local inHand = GetSelectedPedWeapon(ped)
    local count = 0

    for _, name in ipairs(order) do
        if (inventory[name] or 0) > 0 and definitions[name].weaponHash ~= inHand then
            list[name] = true
            count = count + 1
            if count >= cfg.MaxItems then break end
        end
    end

    return list
end

local function refresh()
    if refreshing then return end
    refreshing = true

    local ped = Cache.ped
    local want = wanted(ped)

    for name, object in pairs(attached) do
        if not want[name] or not DoesEntityExist(object) or not IsEntityAttachedToEntity(object, ped) then
            remove(name)
        end
    end

    for name in pairs(want) do
        if not attached[name] then create(name, ped) end
    end

    refreshing = false
end

local function updateInventory()
    inventory = Bridge.getItems()
end

Bridge.onItemsChanged(updateInventory)
Bridge.onLoaded(updateInventory)
Bridge.onUnloaded(function()
    inventory = {}
    removeAll()
end)

CreateThread(function()
    while true do
        refresh()
        Wait(500)
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name == Cache.resource then removeAll() end
end)

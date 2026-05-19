--[[
==========================================================
    MTJ Door System - CLIENT MAIN
    Copyright © MTJScripts
==========================================================
]]

ESX = exports['es_extended']:getSharedObject()

DoorCache = {}    -- aktuelle Türen vom Server
SpawnedNpcs = {}  -- [doorId_point] = ped
TargetIds = {}    -- [doorId_point] = { type='zone'|'entity', id=zoneId, ped=ped }

-- ==========================================================
-- HELPER
-- ==========================================================
local function getMarkerPreset(id)
    for _, m in ipairs(Config.MarkerPresets) do if m.id == id then return m end end
    return Config.MarkerPresets[1]
end

local function getColor(id)
    for _, c in ipairs(Config.ColorPresets) do if c.id == id then return c.rgb end end
    return {255,255,255}
end

local function getNpcModel(id)
    for _, n in ipairs(Config.NpcPresets) do if n.id == id then return n.model end end
    return Config.NpcPresets[1].model
end

local function hasCoords(coords)
    if type(coords) ~= 'table' then return false end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    return x ~= nil and y ~= nil and z ~= nil
end

local function isReturnEnabled(door)
    if type(door.interaction) == 'table' and door.interaction.returnEnabled == false then
        return false
    end
    return true
end

-- ==========================================================
-- NPC SPAWN
-- ==========================================================
local function spawnNpc(key, coords, heading, npcId)
    if SpawnedNpcs[key] and DoesEntityExist(SpawnedNpcs[key]) then return SpawnedNpcs[key] end
    local model = getNpcModel(npcId)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 100 do Wait(50); timeout = timeout + 1 end
    if not HasModelLoaded(hash) then return nil end

    local ped = CreatePed(4, hash, coords.x, coords.y, coords.z - 1.0, heading or 0.0, false, true)
    if Config.NpcFreeze then FreezeEntityPosition(ped, true) end
    if Config.NpcInvincible then SetEntityInvincible(ped, true) end
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDiesWhenInjured(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedFleeAttributes(ped, 0, false)
    SetEntityCanBeDamaged(ped, false)
    SetModelAsNoLongerNeeded(hash)
    SpawnedNpcs[key] = ped
    return ped
end

local function despawnNpc(key)
    if SpawnedNpcs[key] and DoesEntityExist(SpawnedNpcs[key]) then
        DeletePed(SpawnedNpcs[key])
    end
    SpawnedNpcs[key] = nil
end

-- ==========================================================
-- TARGET REGISTRATION
-- ==========================================================
local function registerTarget(door, pointKey, point, direction)
    local targetName = ('mtj_door_%s_%s'):format(door.id, pointKey)
    local label = point.label or (direction == 'enter' and Config.DefaultLabels.enter or Config.DefaultLabels.exit)
    local icon  = Config.TargetIcon

    local opts = {{
        name     = targetName,
        label    = label,
        icon     = icon,
        distance = Config.TargetDistance,
        onSelect = function()
            TriggerServerEvent('mtj_doors:server:requestTeleport', door.id, direction)
        end
    }}

    if point.type == 'npc' and SpawnedNpcs[targetName] then
        exports.ox_target:addLocalEntity(SpawnedNpcs[targetName], opts)
        TargetIds[targetName] = { type = 'entity', ped = SpawnedNpcs[targetName] }
    else
        local zoneId = exports.ox_target:addBoxZone({
            coords   = point.coords,
            size     = vec3(1.5, 1.5, 2.0),
            rotation = point.heading or 0.0,
            debug    = false,
            options  = opts
        })
        TargetIds[targetName] = { type = 'zone', id = zoneId }
    end
end

local function removeTarget(door, pointKey)
    local targetName = ('mtj_door_%s_%s'):format(door.id, pointKey)
    local entry = TargetIds[targetName]
    if not entry then return end
    if entry.type == 'zone' and entry.id then
        pcall(function() exports.ox_target:removeZone(entry.id) end)
    elseif entry.type == 'entity' and entry.ped and DoesEntityExist(entry.ped) then
        pcall(function() exports.ox_target:removeLocalEntity(entry.ped, targetName) end)
    end
    TargetIds[targetName] = nil
end

-- ==========================================================
-- BUILD / TEARDOWN DOOR
-- ==========================================================
local function buildDoor(door)
    local points = {
        {'entry', 'enter', door.entry}
    }
    if isReturnEnabled(door) then
        points[#points+1] = {'exitp', 'exit', door.exitp}
    end
    for _, pair in ipairs(points) do
        local pkey, direction, point = pair[1], pair[2], pair[3]
        if point and hasCoords(point.coords) then
            local key = ('mtj_door_%s_%s'):format(door.id, pkey)
            if point.type == 'npc' then
                spawnNpc(key, point.coords, point.heading, point.npc)
            end
            registerTarget(door, pkey, point, direction)
        end
    end
end

local function teardownDoor(door)
    for _, pkey in ipairs({'entry','exitp'}) do
        local key = ('mtj_door_%s_%s'):format(door.id, pkey)
        removeTarget(door, pkey)
        despawnNpc(key)
    end
end

-- ==========================================================
-- SYNC EVENT
-- ==========================================================
RegisterNetEvent('mtj_doors:client:syncDoors', function(list)
    -- Erst alles abbauen
    for _, d in pairs(DoorCache) do teardownDoor(d) end
    DoorCache = {}

    -- Neu aufbauen
    for _, d in ipairs(list) do
        DoorCache[d.id] = d
        buildDoor(d)
    end
end)

-- Initial request
CreateThread(function()
    while not ESX.PlayerLoaded do Wait(500) end
    Wait(500)
    TriggerServerEvent('mtj_doors:server:requestDoors')
end)

RegisterNetEvent('esx:playerLoaded', function()
    Wait(2000)
    TriggerServerEvent('mtj_doors:server:requestDoors')
end)

-- ==========================================================
-- MARKER LOOP
-- ==========================================================
CreateThread(function()
    while true do
        local sleep = 1000
        local pc = GetEntityCoords(PlayerPedId())

        for _, door in pairs(DoorCache) do
            local radius = door.visibility or Config.DefaultVisibilityRadius
            for _, pkey in ipairs({'entry','exitp'}) do
                local point = (pkey == 'entry') and door.entry or door.exitp
                if point and hasCoords(point.coords) and point.type == 'marker' then
                    local dist = #(pc - vec3(point.coords.x, point.coords.y, point.coords.z))
                    if dist <= radius then
                        sleep = 0
                        local preset = getMarkerPreset(point.marker or 'cylinder')
                        if preset.markerType >= 0 then
                            local rgb = getColor(point.color or 'white')
                            DrawMarker(
                                preset.markerType,
                                point.coords.x, point.coords.y, point.coords.z - 0.9,
                                0,0,0, 0,0,0,
                                preset.size.x, preset.size.y, preset.size.z,
                                rgb[1], rgb[2], rgb[3], Config.MarkerAlpha,
                                preset.bobUpAndDown, false, 2,
                                preset.rotate, nil, nil, false
                            )
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- ==========================================================
-- TELEPORT HANDLER
-- ==========================================================
RegisterNetEvent('mtj_doors:client:teleport', function(coords, heading)
    local ped = PlayerPedId()
    local vehicle = nil
    if IsPedInAnyVehicle(ped, false) then
        local v = GetVehiclePedIsIn(ped, false)
        if v and v ~= 0 then vehicle = v end
    end
    if Config.FadeOnTeleport then
        DoScreenFadeOut(Config.FadeDuration)
        local t = 0
        while not IsScreenFadedOut() and t < 20 do Wait(50); t = t + 1 end
    end

    if vehicle then
        SetEntityCoords(vehicle, coords.x, coords.y, coords.z - 0.95, false, false, false, false)
        if heading then SetEntityHeading(vehicle, heading + 0.0) end
        SetVehicleOnGroundProperly(vehicle)
    else
        SetEntityCoords(ped, coords.x, coords.y, coords.z - 0.95, false, false, false, false)
        if heading then SetEntityHeading(ped, heading + 0.0) end
    end

    if Config.FadeOnTeleport then
        Wait(200)
        DoScreenFadeIn(Config.FadeDuration)
    end
end)

-- ==========================================================
-- CLEANUP
-- ==========================================================
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, d in pairs(DoorCache) do teardownDoor(d) end
end)

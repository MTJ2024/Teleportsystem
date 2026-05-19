--[[
==========================================================
    MTJ Door System - SERVER MAIN
    Copyright © MTJScripts
==========================================================
]]

ESX = exports['es_extended']:getSharedObject()

local Doors = {}     -- in-memory cache: [id] = doorData
local JsonPath = GetResourcePath(GetCurrentResourceName()) .. '/server/data/doors.json'

-- ==========================================================
-- STORAGE LAYER
-- ==========================================================
local Storage = {}

function Storage.LoadAll(cb)
    if Config.StorageMode == 'mysql' then
        MySQL.query('SELECT * FROM mtj_doors', {}, function(rows)
            local result = {}
            for _, r in ipairs(rows or {}) do
                result[r.id] = {
                    id          = r.id,
                    label       = r.label,
                    interaction = json.decode(r.interaction or '{}'),
                    entry       = json.decode(r.entry or '{}'),
                    exitp       = json.decode(r.exitp or '{}'),
                    access      = json.decode(r.access or '{"type":"public"}'),
                    visibility  = r.visibility or Config.DefaultVisibilityRadius,
                    enabled     = r.enabled == 1,
                    created_by  = r.created_by
                }
            end
            cb(result)
        end)
    else
        -- JSON
        local f = io.open(JsonPath, 'r')
        if not f then cb({}) return end
        local content = f:read('*a'); f:close()
        local ok, data = pcall(json.decode, content)
        cb(ok and data or {})
    end
end

function Storage.Save(door, cb)
    if Config.StorageMode == 'mysql' then
        if door.id and Doors[door.id] then
            MySQL.update('UPDATE mtj_doors SET label=?, interaction=?, entry=?, exitp=?, access=?, visibility=?, enabled=? WHERE id=?', {
                door.label,
                json.encode(door.interaction),
                json.encode(door.entry),
                json.encode(door.exitp),
                json.encode(door.access),
                door.visibility,
                door.enabled and 1 or 0,
                door.id
            }, function() cb(door.id) end)
        else
            MySQL.insert('INSERT INTO mtj_doors (label, interaction, entry, exitp, access, visibility, enabled, created_by) VALUES (?,?,?,?,?,?,?,?)', {
                door.label,
                json.encode(door.interaction),
                json.encode(door.entry),
                json.encode(door.exitp),
                json.encode(door.access),
                door.visibility,
                door.enabled and 1 or 0,
                door.created_by or 'unknown'
            }, function(insertId)
                door.id = insertId
                cb(insertId)
            end)
        end
    else
        if not door.id then
            local maxId = 0
            for k,_ in pairs(Doors) do if tonumber(k) and tonumber(k) > maxId then maxId = tonumber(k) end end
            door.id = maxId + 1
        end
        Doors[door.id] = door
        Storage.PersistJson()
        cb(door.id)
    end
end

function Storage.Delete(id, cb)
    if Config.StorageMode == 'mysql' then
        MySQL.update('DELETE FROM mtj_doors WHERE id=?', { id }, function() cb(true) end)
    else
        Doors[id] = nil
        Storage.PersistJson()
        cb(true)
    end
end

function Storage.PersistJson()
    -- ensure dir
    os.execute('mkdir -p "' .. GetResourcePath(GetCurrentResourceName()) .. '/server/data"')
    local f = io.open(JsonPath, 'w')
    if not f then return end
    f:write(json.encode(Doors)); f:close()
end

-- ==========================================================
-- BOOTSTRAP
-- ==========================================================
CreateThread(function()
    Wait(1000)
    Storage.LoadAll(function(data)
        Doors = data or {}
        local count = 0
        for _ in pairs(Doors) do count = count + 1 end
        print(('^2[MTJ-Doors]^7 %d Türen geladen (Modus: %s)'):format(count, Config.StorageMode))
    end)
end)

-- ==========================================================
-- HELPER: Filter Doors für Client (mit Zugriffsprüfung)
-- ==========================================================
local function BuildClientDoorList(src, cb)
    local list = {}
    local pending = 0
    local done = false

    local function check()
        if done and pending == 0 then cb(list) end
    end

    for id, door in pairs(Doors) do
        if door.enabled then
            pending = pending + 1
            Permissions.PlayerHasAccess(src, door, function(allowed)
                if allowed then
                    list[#list+1] = door
                end
                pending = pending - 1
                check()
            end)
        end
    end

    done = true
    check()

    -- Falls keine Türen vorhanden, sofort callback
    if next(Doors) == nil then cb({}) end
end

-- ==========================================================
-- CLIENT REQUESTS
-- ==========================================================
RegisterNetEvent('mtj_doors:server:requestDoors', function()
    local src = source
    BuildClientDoorList(src, function(list)
        TriggerClientEvent('mtj_doors:client:syncDoors', src, list)
    end)
end)

-- Teleport-Permission-Check (Server-Side gegen Cheats)
RegisterNetEvent('mtj_doors:server:requestTeleport', function(doorId, direction)
    local src = source
    local door = Doors[doorId]
    if not door then return end
    Permissions.PlayerHasAccess(src, door, function(allowed)
        if not allowed then
            TriggerClientEvent('ox_lib:notify', src, { type='error', description='Keine Berechtigung.' })
            return
        end
        local target = (direction == 'enter') and door.exitp or door.entry
        if not target or not target.coords then return end
        TriggerClientEvent('mtj_doors:client:teleport', src, target.coords, target.heading)
    end)
end)

-- ==========================================================
-- ADMIN / NUI ENDPOINTS
-- ==========================================================
local function assertAdmin(src)
    if not Permissions.IsAdmin(src) then
        TriggerClientEvent('ox_lib:notify', src, { type='error', description='Keine Berechtigung (mtj.doors.admin).' })
        return false
    end
    return true
end

ESX.RegisterServerCallback('mtj_doors:cb:getAll', function(src, cb)
    if not assertAdmin(src) then cb({}); return end
    local list = {}
    for _, d in pairs(Doors) do list[#list+1] = d end
    cb(list)
end)

ESX.RegisterServerCallback('mtj_doors:cb:getJobs', function(src, cb)
    if not assertAdmin(src) then cb({}); return end
    local jobs = {}
    MySQL.query('SELECT name, label FROM jobs', {}, function(rows)
        for _, r in ipairs(rows or {}) do
            jobs[#jobs+1] = { name = r.name, label = r.label }
        end
        cb(jobs)
    end)
end)

ESX.RegisterServerCallback('mtj_doors:cb:getJobGrades', function(src, jobName, cb)
    if not assertAdmin(src) then cb({}); return end
    MySQL.query('SELECT grade, label FROM job_grades WHERE job_name=? ORDER BY grade ASC', { jobName }, function(rows)
        cb(rows or {})
    end)
end)

RegisterNetEvent('mtj_doors:server:save', function(doorData)
    local src = source
    if not assertAdmin(src) then return end
    doorData.created_by = doorData.created_by or (ESX.GetPlayerFromId(src) and ESX.GetPlayerFromId(src).identifier or 'admin')
    Storage.Save(doorData, function(id)
        doorData.id = id
        Doors[id] = doorData
        TriggerClientEvent('ox_lib:notify', src, { type='success', description='Tür gespeichert (#'..id..').' })
        -- Re-sync alle Spieler
        for _, pid in ipairs(GetPlayers()) do
            BuildClientDoorList(tonumber(pid), function(list)
                TriggerClientEvent('mtj_doors:client:syncDoors', tonumber(pid), list)
            end)
        end
    end)
end)

RegisterNetEvent('mtj_doors:server:delete', function(id)
    local src = source
    if not assertAdmin(src) then return end
    Storage.Delete(id, function()
        Doors[id] = nil
        TriggerClientEvent('ox_lib:notify', src, { type='success', description='Tür gelöscht.' })
        for _, pid in ipairs(GetPlayers()) do
            BuildClientDoorList(tonumber(pid), function(list)
                TriggerClientEvent('mtj_doors:client:syncDoors', tonumber(pid), list)
            end)
        end
    end)
end)

RegisterNetEvent('mtj_doors:server:toggle', function(id, enabled)
    local src = source
    if not assertAdmin(src) then return end
    if not Doors[id] then return end
    Doors[id].enabled = enabled
    Storage.Save(Doors[id], function()
        for _, pid in ipairs(GetPlayers()) do
            BuildClientDoorList(tonumber(pid), function(list)
                TriggerClientEvent('mtj_doors:client:syncDoors', tonumber(pid), list)
            end)
        end
    end)
end)

-- Owner-Check Callback für NUI-Open
ESX.RegisterServerCallback('mtj_doors:cb:isAdmin', function(src, cb)
    cb(Permissions.IsAdmin(src))
end)

-- ==========================================================
-- HILFS-COMMAND: eigene Identifier ausgeben (für Config-Setup)
-- ==========================================================
RegisterCommand('mtjmyid', function(source)
    local src = source
    if src == 0 then
        print('^3[MTJ-Doors]^7 Dieser Command muss in-game ausgeführt werden.')
        return
    end
    local ids = GetPlayerIdentifiers(src) or {}
    local lines = { '^2[MTJ-Doors]^7 Deine Identifier (in Config.OwnerIdentifiers eintragen):' }
    for _, id in ipairs(ids) do
        lines[#lines+1] = '  ' .. id
    end
    local msg = table.concat(lines, '\n')
    -- Auf Server-Konsole loggen
    print(msg)
    -- Dem Spieler per Chat senden
    TriggerClientEvent('chat:addMessage', src, {
        color = { 255, 192, 0 },
        multiline = true,
        args = { 'MTJ-Doors', 'Identifier wurden in der Server-Konsole und unten ausgegeben:\n' .. table.concat(ids, '\n') }
    })
end, false)

print('^2[MTJ-Doors]^7 Server gestartet | © MTJScripts')

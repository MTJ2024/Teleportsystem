--[[
==========================================================
    MTJ Door System - IN-GAME CREATOR
    Liefert Coords/Heading an NUI für Entry/Exit-Setzung
    Copyright © MTJScripts
==========================================================
]]

local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vec3(-math.sin(z)*num, math.cos(z)*num, math.sin(x))
end

local function rayPick()
    local cam = GetGameplayCamCoord()
    local dir = rotationToDirection(GetGameplayCamRot(2))
    local dest = vec3(cam.x + dir.x * 25.0, cam.y + dir.y * 25.0, cam.z + dir.z * 25.0)
    local ray = StartShapeTestRay(cam.x, cam.y, cam.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
    local _, hit, endCoords = GetShapeTestResult(ray)
    return hit == 1, endCoords
end

local function round2(n)
    return math.floor((n or 0) * 100) / 100
end

-- Aktuelle Position des Spielers
RegisterNUICallback('mtj:getCurrentCoords', function(_, cb)
    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    cb({
        x = round2(c.x),
        y = round2(c.y),
        z = round2(c.z),
        heading = round2(h)
    })
end)

-- Crosshair-Raycast (Tür anvisieren)
RegisterNUICallback('mtj:pickCoords', function(_, cb)
    local hit, coords = rayPick()
    if hit and coords then
        cb({
            x = round2(coords.x),
            y = round2(coords.y),
            z = round2(coords.z),
            heading = round2(GetEntityHeading(PlayerPedId()))
        })
    else
        cb({ error = 'Kein Treffer' })
    end
end)

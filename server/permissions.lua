--[[
==========================================================
    MTJ Door System - PERMISSION CHECK
    Copyright © MTJScripts
==========================================================
]]

Permissions = {}

---@param src number
---@return boolean
function Permissions.IsAdmin(src)
    -- Identifier-Whitelist prüfen
    local ids = GetPlayerIdentifiers(src) or {}
    local owners = Config.OwnerIdentifiers or {}

    -- Lookup-Set für O(1)-Vergleich
    local set = {}
    for _, owner in ipairs(owners) do
        set[string.lower(owner)] = true
    end

    for _, pid in ipairs(ids) do
        if set[string.lower(pid)] then
            return true
        end
    end

    -- Optionaler ACE-Fallback
    if Config.AllowAceFallback and IsPlayerAceAllowed(src, Config.AdminAcePerm) then
        return true
    end

    return false
end

---@param src number
---@param door table {access = { type, job, grade, license }}
---@param cb function(allowed:boolean)
function Permissions.PlayerHasAccess(src, door, cb)
    local access = door.access or { type = 'public' }

    -- Public
    if access.type == 'public' or access.type == nil then
        cb(true); return
    end

    local player = Bridge.GetPlayer(src)
    if not player then cb(false) return end

    -- Job
    if access.type == 'job' then
        if player.job ~= access.job then cb(false) return end
        if access.grade and tonumber(access.grade) and tonumber(player.grade) < tonumber(access.grade) then
            cb(false); return
        end
        cb(true); return
    end

    -- License
    if access.type == 'license' then
        Bridge.GetLicenses(src, function(licenses)
            for _, lic in ipairs(licenses) do
                if lic.type == access.license then cb(true) return end
            end
            cb(false)
        end)
        return
    end

    -- Job + License kombiniert
    if access.type == 'job_license' then
        if player.job ~= access.job then cb(false) return end
        if access.grade and tonumber(player.grade) < tonumber(access.grade) then cb(false) return end
        Bridge.GetLicenses(src, function(licenses)
            for _, lic in ipairs(licenses) do
                if lic.type == access.license then cb(true) return end
            end
            cb(false)
        end)
        return
    end

    cb(false)
end

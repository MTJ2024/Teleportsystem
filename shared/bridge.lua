--[[
==========================================================
    MTJ Door System - ESX BRIDGE
    Copyright © MTJScripts
==========================================================
]]

Bridge = {}

if Config.Framework == 'esx' then

    if IsDuplicityVersion() then
        -- SERVER
        Bridge.GetPlayer = function(src)
            local xPlayer = ESX.GetPlayerFromId(src)
            if not xPlayer then return nil end
            return {
                identifier = xPlayer.identifier,
                job        = xPlayer.job and xPlayer.job.name or nil,
                grade      = xPlayer.job and xPlayer.job.grade or 0,
                licenses   = nil -- wird async geladen
            }
        end

        Bridge.GetLicenses = function(src, cb)
            local xPlayer = ESX.GetPlayerFromId(src)
            if not xPlayer then cb({}) return end
            TriggerEvent('esx_license:getLicenses', src, function(licenses)
                cb(licenses or {})
            end)
        end
    else
        -- CLIENT
        Bridge.GetPlayerData = function()
            local data = ESX.GetPlayerData() or {}
            return {
                job   = data.job and data.job.name  or nil,
                grade = data.job and data.job.grade or 0
            }
        end
    end
end

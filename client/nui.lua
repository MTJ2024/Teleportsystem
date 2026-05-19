--[[
==========================================================
    MTJ Door System - NUI BRIDGE
    Copyright © MTJScripts
==========================================================
]]

local nuiOpen = false

local function openDashboard()
    if nuiOpen then return end
    ESX.TriggerServerCallback('mtj_doors:cb:isAdmin', function(isAdmin)
        if not isAdmin then
            ESX.ShowNotification('~r~Keine Berechtigung (mtj.doors.admin).')
            return
        end
        ESX.TriggerServerCallback('mtj_doors:cb:getAll', function(doors)
            ESX.TriggerServerCallback('mtj_doors:cb:getJobs', function(jobs)
                nuiOpen = true
                SetNuiFocus(true, true)
                if SetNuiFocusKeepInput then SetNuiFocusKeepInput(true) end
                SendNUIMessage({
                    action = 'open',
                    doors  = doors,
                    jobs   = jobs,
                    config = {
                        markers  = Config.MarkerPresets,
                        colors   = Config.ColorPresets,
                        npcs     = Config.NpcPresets,
                        licenses = Config.LicensePresets,
                        minR     = Config.MinVisibilityRadius,
                        maxR     = Config.MaxVisibilityRadius,
                        defaultR = Config.DefaultVisibilityRadius
                    }
                })
            end)
        end)
    end)
end

local function closeDashboard()
    nuiOpen = false
    if SetNuiFocusKeepInput then SetNuiFocusKeepInput(false) end
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand(Config.CommandDashboard, function() openDashboard() end, false)
RegisterKeyMapping(Config.CommandDashboard, 'MTJ Doors Dashboard öffnen', 'keyboard', '')

RegisterNUICallback('mtj:close', function(_, cb) closeDashboard(); cb('ok') end)

-- Job Grades nachladen
RegisterNUICallback('mtj:getGrades', function(data, cb)
    ESX.TriggerServerCallback('mtj_doors:cb:getJobGrades', function(grades)
        cb(grades or {})
    end, data.job)
end)

-- Speichern
RegisterNUICallback('mtj:saveDoor', function(data, cb)
    TriggerServerEvent('mtj_doors:server:save', data)
    cb('ok')
end)

-- Löschen
RegisterNUICallback('mtj:deleteDoor', function(data, cb)
    TriggerServerEvent('mtj_doors:server:delete', data.id)
    cb('ok')
end)

-- Toggle Enabled
RegisterNUICallback('mtj:toggleDoor', function(data, cb)
    TriggerServerEvent('mtj_doors:server:toggle', data.id, data.enabled)
    cb('ok')
end)

-- Refresh-Liste
RegisterNUICallback('mtj:refresh', function(_, cb)
    ESX.TriggerServerCallback('mtj_doors:cb:getAll', function(doors)
        cb(doors)
    end)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    closeDashboard()
end)

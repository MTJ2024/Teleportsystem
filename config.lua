--[[
==========================================================
    MTJ Door & Teleport System - CONFIG
    Copyright © MTJScripts
==========================================================
]]

Config = {}

-- ========================================================
-- ALLGEMEIN
-- ========================================================
Config.Locale            = 'de'
Config.CommandDashboard  = 'mtjdoors'      -- /mtjdoors öffnet das Dashboard (nur für Owner)
Config.CommandCreate     = 'mtjdoor'       -- /mtjdoor create | edit | delete (in-game)

-- ========================================================
-- OWNER-WHITELIST (per Lizenz / Identifier)
-- ========================================================
-- Trage hier die Identifier ein, die Zugriff auf das Dashboard haben.
-- Unterstützte Präfixe: license, license2, steam, discord, fivem, xbl, live
--
-- So findest du deine eigene Lizenz:
--   1. Im Spiel: Konsole (F8) -> "playerlist" oder Server-Konsole -> "list"
--   2. Oder einfach den Command /mtjmyid eingeben (siehe README)
--   3. Oder in der DB: SELECT identifier FROM users WHERE firstname = '...'
--
-- Beispiele:
--   'license:abcdef1234567890abcdef1234567890abcdef12',
--   'steam:110000112345678',
--   'discord:123456789012345678',
Config.OwnerIdentifiers = {
     'license:366c3d437a682115ababea671897bda09e8f638c',
    -- 'license:weitereLizenzAlsZweiterOwner',
}

-- Fallback: Wenn true, dürfen Spieler mit ACE-Permission 'mtj.doors.admin'
-- zusätzlich das Dashboard nutzen (z.B. für Server-Owner über server.cfg).
Config.AllowAceFallback  = true
Config.AdminAcePerm      = 'mtj.doors.admin'

-- ========================================================
-- DATENBANK
-- ========================================================
-- 'mysql'  = oxmysql (empfohlen, persistent)
-- 'json'   = lokale JSON-Datei in /server/data/doors.json
Config.StorageMode       = 'mysql'

-- ========================================================
-- FRAMEWORK
-- ========================================================
Config.Framework         = 'esx'           -- esx | qb (für später) -- aktuell ESX Legacy
Config.UseFrameworkJobs  = true            -- Jobs/Ränge aus Framework ziehen
Config.UseLicenses       = true            -- Lizenzen aus esx_license / user_licenses

-- Lizenz-Auswahl im Dashboard (verhindert Tippfehler)
-- ID muss dem Datenbankeintrag in user_licenses.type entsprechen.
Config.LicensePresets = {
    { id = 'drive',       label = 'Führerschein (Auto)' },
    { id = 'drive_bike',  label = 'Führerschein (Motorrad)' },
    { id = 'drive_truck', label = 'Führerschein (LKW)' },
    { id = 'weapon',      label = 'Waffenschein' },
    { id = 'pilot',       label = 'Pilotenschein' },
    { id = 'boat',        label = 'Bootsschein' },
    { id = 'fishing',     label = 'Angelschein' },
    { id = 'hunting',     label = 'Jagdschein' }
}

-- ========================================================
-- INTERAKTION (ox_target)
-- ========================================================
Config.TargetIcon        = 'fa-solid fa-door-open'
Config.TargetDistance    = 2.0              -- Default ox_target Distanz
Config.FadeOnTeleport    = true             -- Fade out beim Teleport
Config.FadeDuration      = 800              -- ms

-- ========================================================
-- MARKER-VORAUSWAHL (Type IDs aus GTA V)
-- ========================================================
-- https://docs.fivem.net/docs/game-references/markers/
Config.MarkerPresets = {
    { id = 'arrow_down', label = 'Pfeil nach unten',  markerType = 27, size = vec3(1.0, 1.0, 0.5),  bobUpAndDown = false, rotate = true  },
    { id = 'cylinder',   label = 'Zylinder',           markerType = 1,  size = vec3(1.0, 1.0, 1.0),  bobUpAndDown = false, rotate = false },
    { id = 'ring',       label = 'Ring (boden)',       markerType = 25, size = vec3(1.2, 1.2, 1.2),  bobUpAndDown = false, rotate = true  },
    { id = 'arrow_up',   label = 'Pfeil aufwärts',     markerType = 6,  size = vec3(0.8, 0.8, 0.8),  bobUpAndDown = true,  rotate = false },
    { id = 'house',      label = 'Haus-Icon',          markerType = 36, size = vec3(0.8, 0.8, 0.8),  bobUpAndDown = false, rotate = false },
    { id = 'crown',      label = 'Krone',              markerType = 22, size = vec3(0.6, 0.6, 0.6),  bobUpAndDown = true,  rotate = false },
    { id = 'chevron',    label = 'Doppel-Pfeil',       markerType = 7,  size = vec3(1.0, 1.0, 0.5),  bobUpAndDown = true,  rotate = false },
    { id = 'invisible',  label = 'Unsichtbar (nur ox_target)', markerType = -1, size = vec3(1.0, 1.0, 1.0), bobUpAndDown = false, rotate = false }
}

-- ========================================================
-- FARB-PALETTE (RGB)
-- ========================================================
Config.ColorPresets = {
    { id = 'white',  label = 'Weiß',     rgb = {255, 255, 255} },
    { id = 'red',    label = 'Rot',      rgb = {220, 50, 50}   },
    { id = 'blue',   label = 'Blau',     rgb = {50, 130, 220}  },
    { id = 'green',  label = 'Grün',     rgb = {60, 200, 90}   },
    { id = 'yellow', label = 'Gelb',     rgb = {240, 200, 50}  },
    { id = 'purple', label = 'Lila',     rgb = {160, 70, 200}  },
    { id = 'orange', label = 'Orange',   rgb = {240, 130, 40}  },
    { id = 'cyan',   label = 'Türkis',   rgb = {50, 220, 220}  }
}
Config.MarkerAlpha = 150  -- 0-255

-- ========================================================
-- NPC-VORAUSWAHL
-- ========================================================
Config.NpcPresets = {
    { id = 'security', label = 'Security / Wache', model = 's_m_m_security_01' },
    { id = 'business', label = 'Geschäftsmann',     model = 'a_m_y_business_01' },
    { id = 'doctor',   label = 'Arzt',              model = 's_m_m_doctor_01'   },
    { id = 'mechanic', label = 'Mechaniker',        model = 's_m_y_xmech_02'    }
}
Config.NpcInvincible = true
Config.NpcFreeze     = true

-- ========================================================
-- SICHTBARKEIT
-- ========================================================
Config.DefaultVisibilityRadius = 15.0   -- Default Sichtbarkeitsradius in Metern
Config.MinVisibilityRadius     = 2.0
Config.MaxVisibilityRadius     = 50.0

-- ========================================================
-- DEFAULT-INTERAKTIONSLABELS
-- ========================================================
Config.DefaultLabels = {
    enter = '[E] Betreten',
    exit  = '[E] Verlassen'
}

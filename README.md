# MTJ Door & Teleport System
**© MTJScripts – All rights reserved.**

Ein dynamisches Tür-, Teleport- und NPC-Interaktionssystem für FiveM mit
**In-Game Dashboard**. Alles wird live über ein NUI verwaltet — kein Restart,
kein Code-Edit nötig.

---

## Features

- **Eingang + Ausgang** als Paar verwaltet (Tür-System).
- **Marker / Unsichtbar / NPC** als Interaktionsstart.
- **ox_target** gesteuert für jede Interaktion.
- **Marker-Vorauswahl** (8 Stile) + **Farb-Palette** (8 Farben).
- **NPC-Vorauswahl** (4 Modelle, in `config.lua` erweiterbar).
- **Sichtbarkeitsradius** pro Tür individuell einstellbar.
- **Berechtigungen**: public · Job · Job+Rang · Lizenz · Job+Lizenz.
- **Live-Erstellung** im Spiel: `Hier setzen` (aktuelle Position) oder
  `Anvisieren` (Crosshair-Raycast).
- **GTA V Stil** im Dashboard (Pricedown + Chalet Fonts).
- **Storage**: MySQL (oxmysql) oder lokale JSON-Datei, in Config umschaltbar.
- **Anti-Cheat**: Teleport-Permission wird serverseitig verifiziert.

---

## Abhängigkeiten

- `es_extended` (ESX Legacy)
- `ox_lib`
- `ox_target`
- `oxmysql` (nur wenn `StorageMode = 'mysql'`)

---

## Installation

1. **Resource entpacken** nach `resources/[mtj]/mtj_doorsystem`.
2. **Datenbank** (nur bei MySQL-Modus) — `sql/install.sql` einspielen.
3. **Fonts** in `html/fonts/` ablegen:
   - `pricedown.otf` — GTA-Titelschriftart (z.B. Pricedown von typodermicfonts).
   - `chalet.otf` — Chalet London 1960 (oder ähnliche Replacement-Font).
   - Falls Fonts fehlen, fällt das Dashboard automatisch auf `Impact` und
     `Helvetica Neue` zurück.
4. **Owner festlegen** (per Lizenz/Identifier in `config.lua`):
   ```lua
   Config.OwnerIdentifiers = {
       'license:abcdef1234567890abcdef1234567890abcdef12',
       -- 'steam:110000112345678',
   }
   ```
   So findest du deine Lizenz:
   - Im Spiel `/mtjmyid` eingeben → deine Identifier werden im Chat und in
     der Server-Konsole ausgegeben.
   - Oder Server-Konsole: `list` bzw. F8-Konsole im Spiel.

   Alternativ (oder zusätzlich) ACE-Permission über `server.cfg`:
   ```cfg
   add_ace group.admin mtj.doors.admin allow
   ```
   Das funktioniert nur, wenn `Config.AllowAceFallback = true` (Default).
5. In `server.cfg` starten:
   ```cfg
   ensure ox_lib
   ensure ox_target
   ensure oxmysql
   ensure es_extended
   ensure mtj_doorsystem
   ```

---

## Bedienung

### Dashboard öffnen
```
/mtjdoors
```
> Nur Spieler mit `mtj.doors.admin` Ace-Permission können das Dashboard öffnen.

### Eingang erstellen (Workflow)

1. Stell dich an die gewünschte Position für den **Eingang**.
2. `/mtjdoors` → Tab **Editor** → Karte „Eingang" → **Hier setzen**.
3. Wähle Typ (Marker / Unsichtbar / NPC), Stil, Farbe.
4. Gehe zur Ausgangsposition (z.B. Innenraum).
5. Karte „Ausgang" → **Hier setzen** → Konfigurieren.
6. Optional: Berechtigung setzen (Job + Rang oder Lizenz).
7. **Speichern** — die Tür ist sofort für berechtigte Spieler aktiv.

### „Anvisieren" Modus
Statt drauf zu stehen kannst du auf eine Tür zielen und **Anvisieren** klicken.
Der Raycast übernimmt die getroffene Position automatisch.

---

## Konfiguration

Alle Einstellungen in `config.lua`:

- `Config.StorageMode` — `'mysql'` oder `'json'`
- `Config.OwnerIdentifiers` — Whitelist der Owner-Identifier (Lizenzen)
- `Config.AllowAceFallback` — true/false, ob zusätzlich ACE-Perm erlaubt ist
- `Config.MarkerPresets` — Marker-Stile (Type-IDs aus GTA V)
- `Config.ColorPresets` — RGB-Farbpalette
- `Config.NpcPresets` — NPC-Modelle
- `Config.CommandDashboard` / `Config.CommandCreate`
- `Config.DefaultVisibilityRadius` / `MinVisibilityRadius` / `MaxVisibilityRadius`

---

## Datenmodell (eine Tür)

```json
{
  "id": 1,
  "label": "Polizei HQ Haupteingang",
  "enabled": true,
  "visibility": 15.0,
  "entry": {
    "coords":  { "x": 441.0, "y": -981.0, "z": 30.7 },
    "heading": 90.0,
    "type":    "marker",        // marker | invisible | npc
    "label":   "[E] Betreten",
    "marker":  "arrow_down",
    "color":   "blue",
    "npc":     "security"
  },
  "exitp": { "...gleiche struktur..." },
  "access": {
    "type":   "job",            // public | job | license | job_license
    "job":    "police",
    "grade":  2,
    "license":"weapon"
  }
}
```

---

## Lizenz
Diese Resource ist Eigentum von **MTJScripts**. Weitergabe, Resale oder
Veröffentlichung ohne ausdrückliche Genehmigung ist untersagt.

/*
==========================================================
  MTJ Door System - Dashboard Logic
  Copyright © MTJScripts
==========================================================
*/

const RES = (() => {
    if (typeof GetParentResourceName === 'function') {
        const parent = GetParentResourceName();
        if (parent && parent !== '') return parent;
    }
    const host = window.location.host;
    return host && host !== '' ? host : 'mtj_doorsystem';
})();

const STATE = {
    doors: [],
    jobs: [],
    cfg: { markers: [], colors: [], npcs: [], licenses: [], defaultR: 15, minR: 2, maxR: 50 },
    editing: null,
    activePoint: 'entry',
    booted: false
};

const $  = (sel, ctx=document) => ctx.querySelector(sel);
const $$ = (sel, ctx=document) => Array.from(ctx.querySelectorAll(sel));

async function nui(name, data={}) {
    try {
        const r = await fetch(`https://${RES}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        });
        const txt = await r.text();
        if (!txt) return null;
        try { return JSON.parse(txt); } catch { return txt; }
    } catch (e) {
        console.error('[MTJ] NUI fetch failed', name, e);
        return null;
    }
}

// ==========================================================
//  FALLBACK PRESETS (used when server sends empty config)
// ==========================================================
const FALLBACK_MARKERS = [
    { id: 'arrow_down', label: 'Pfeil nach unten',  markerType: 27 },
    { id: 'cylinder',   label: 'Zylinder',           markerType: 1  },
    { id: 'ring',       label: 'Ring (Boden)',       markerType: 25 },
    { id: 'arrow_up',   label: 'Pfeil aufwärts',     markerType: 6  },
    { id: 'house',      label: 'Haus-Icon',          markerType: 36 },
    { id: 'crown',      label: 'Krone',              markerType: 22 },
    { id: 'chevron',    label: 'Doppel-Pfeil',       markerType: 7  },
    { id: 'invisible',  label: 'Unsichtbar',         markerType: -1 }
];
const FALLBACK_COLORS = [
    { id: 'white',  label: 'Weiß',   rgb: [255,255,255] },
    { id: 'red',    label: 'Rot',    rgb: [220,50,50]   },
    { id: 'blue',   label: 'Blau',   rgb: [50,130,220]  },
    { id: 'green',  label: 'Grün',   rgb: [60,200,90]   },
    { id: 'yellow', label: 'Gelb',   rgb: [240,200,50]  },
    { id: 'purple', label: 'Lila',   rgb: [160,70,200]  },
    { id: 'orange', label: 'Orange', rgb: [240,130,40]  },
    { id: 'cyan',   label: 'Türkis', rgb: [50,220,220]  }
];
const FALLBACK_NPCS = [
    { id: 'security', label: 'Security / Wache' },
    { id: 'business', label: 'Geschäftsmann'    },
    { id: 'valet',    label: 'Valet / Parkservice' },
    { id: 'doctor',   label: 'Arzt'             },
    { id: 'mechanic', label: 'Mechaniker'       },
    { id: 'cop',      label: 'Polizist'         }
];
const FALLBACK_LICENSES = [
    { id: 'drive',       label: 'Führerschein (Auto)'      },
    { id: 'drive_bike',  label: 'Führerschein (Motorrad)'  },
    { id: 'drive_truck', label: 'Führerschein (LKW)'       },
    { id: 'weapon',      label: 'Waffenschein'             },
    { id: 'pilot',       label: 'Pilotenschein'            }
];

function applyConfigFallbacks(cfg) {
    if (!Array.isArray(cfg.markers)  || cfg.markers.length  === 0) cfg.markers  = FALLBACK_MARKERS;
    if (!Array.isArray(cfg.colors)   || cfg.colors.length   === 0) cfg.colors   = FALLBACK_COLORS;
    if (!Array.isArray(cfg.npcs)     || cfg.npcs.length     === 0) cfg.npcs     = FALLBACK_NPCS;
    if (!Array.isArray(cfg.licenses) || cfg.licenses.length === 0) cfg.licenses = FALLBACK_LICENSES;
    return cfg;
}

// ==========================================================
//  OPEN / CLOSE
// ==========================================================
window.addEventListener('message', (e) => {
    const m = e.data || {};
    if (m.action === 'open') {
        STATE.doors = Array.isArray(m.doors) ? m.doors : [];
        STATE.jobs  = Array.isArray(m.jobs)  ? m.jobs  : [];
        STATE.cfg   = applyConfigFallbacks(Object.assign(STATE.cfg, m.config || {}));
        document.body.classList.remove('hidden');
        if (!STATE.booted) { bindStaticListeners(); STATE.booted = true; }
        renderJobsDropdown();
        renderLicensesDropdown();
        renderList();
        switchTab('list');
    } else if (m.action === 'close') {
        document.body.classList.add('hidden');
        STATE.editing = null;
    } else if (m.action === 'mtj:hotkeyEnterSetCoords') {
        if (!STATE.editing || document.body.classList.contains('hidden')) return;
        if ($('.panel[data-panel="editor"]').classList.contains('hidden')) return;
        applyCoords(STATE.activePoint || 'entry', m.coords || null);
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        closeUI();
        return;
    }
    if (e.key === 'Enter') {
        quickSetCoordsFromEnter(e);
    }
});

function closeUI() {
    nui('mtj:close');
    document.body.classList.add('hidden');
    STATE.editing = null;
}

function setActivePoint(point) {
    if (point !== 'entry' && point !== 'exitp') return;
    STATE.activePoint = point;
    $$('.point-card').forEach(c => c.classList.toggle('active-point', c.dataset.point === STATE.activePoint));
}

function getReturnEnabled(interaction) {
    return !(interaction && interaction.returnEnabled === false);
}

async function quickSetCoordsFromEnter(e) {
    if (!STATE.editing) return;
    if ($('.panel[data-panel="editor"]').classList.contains('hidden')) return;
    if (document.body.classList.contains('hidden')) return;
    const activeTag = (document.activeElement && document.activeElement.tagName || '').toLowerCase();
    if (activeTag === 'textarea' || activeTag === 'input' || activeTag === 'select') return;
    if (document.activeElement && document.activeElement.isContentEditable) return;
    e.preventDefault();
    const c = await nui('mtj:getCurrentCoords', {});
    applyCoords(STATE.activePoint || 'entry', c);
}

// ==========================================================
//  STATIC LISTENERS (binden nur einmal)
// ==========================================================
function bindStaticListeners() {
    $('#closeBtn').addEventListener('click', closeUI);
    $$('.tab').forEach(t => t.addEventListener('click', () => switchTab(t.dataset.tab)));
    $('#search').addEventListener('input', renderList);
    $('#newDoor').addEventListener('click', () => openEditor(null));
    $('#cancelBtn').addEventListener('click', () => {
        STATE.editing = null;
        switchTab('list');
    });
    $('#saveBtn').addEventListener('click', saveCurrent);

    // Basis-Felder
    $('#f_label').addEventListener('input', e => { if (STATE.editing) STATE.editing.label = e.target.value; });
    $('#f_enabled').addEventListener('change', e => { if (STATE.editing) STATE.editing.enabled = e.target.checked; });
    $('#f_return').addEventListener('change', e => {
        if (!STATE.editing) return;
        STATE.editing.interaction = STATE.editing.interaction || {};
        STATE.editing.interaction.returnEnabled = e.target.checked;
    });
    $('#f_vis').addEventListener('input', e => {
        $('#f_visLabel').textContent = e.target.value + 'm';
        if (STATE.editing) STATE.editing.visibility = parseFloat(e.target.value);
    });

    // Access
    $('#a_type').addEventListener('change', () => {
        if (!STATE.editing) return;
        const t = $('#a_type').value;
        STATE.editing.access = STATE.editing.access || {};
        STATE.editing.access.type = t;
        renderAccessVisibility();
    });
    $('#a_job').addEventListener('change', async e => {
        if (!STATE.editing) return;
        STATE.editing.access = STATE.editing.access || {};
        STATE.editing.access.job = e.target.value || null;
        STATE.editing.access.grade = null;
        await refreshGrades(e.target.value);
    });
    $('#a_grade').addEventListener('change', e => {
        if (!STATE.editing) return;
        STATE.editing.access = STATE.editing.access || {};
        STATE.editing.access.grade = e.target.value === '' ? null : parseInt(e.target.value);
    });
    $('#a_license').addEventListener('change', e => {
        if (!STATE.editing) return;
        STATE.editing.access = STATE.editing.access || {};
        STATE.editing.access.license = e.target.value || null;
    });

    // Point-Cards (entry/exitp): Inputs + Buttons + Radios
    ['entry','exitp'].forEach(point => bindPointCardListeners(point));
}

function bindPointCardListeners(point) {
    const card = $(`.point-card[data-point="${point}"]`);
    card.addEventListener('mousedown', () => setActivePoint(point));
    card.addEventListener('focusin', () => setActivePoint(point));

    // Koordinaten-Inputs
    card.querySelectorAll('input[data-axis]').forEach(inp => {
        inp.addEventListener('input', () => {
            if (!STATE.editing) return;
            STATE.editing[point] = STATE.editing[point] || pointTemplate(point);
            const a = inp.dataset.axis;
            const v = parseFloat(inp.value);
            if (a === 'heading') {
                STATE.editing[point].heading = isNaN(v) ? 0 : v;
            } else {
                STATE.editing[point].coords = STATE.editing[point].coords || { x:0,y:0,z:0 };
                STATE.editing[point].coords[a] = isNaN(v) ? 0 : v;
            }
        });
    });

    // Interaktionstext
    card.querySelector('input[data-field="label"]').addEventListener('input', e => {
        if (!STATE.editing) return;
        STATE.editing[point] = STATE.editing[point] || pointTemplate(point);
        STATE.editing[point].label = e.target.value;
    });

    // Type-Radios
    card.querySelectorAll('input[type="radio"]').forEach(r => {
        r.addEventListener('change', () => {
            if (!STATE.editing || !r.checked) return;
            STATE.editing[point] = STATE.editing[point] || pointTemplate(point);
            STATE.editing[point].type = r.value;
            updatePointBlocks(point);
        });
    });

    // "Hier setzen" / "Anvisieren"
    card.querySelector('[data-action="here"]').addEventListener('click', async () => {
        if (!STATE.editing) return;
        setActivePoint(point);
        const c = await nui('mtj:getCurrentCoords', {});
        applyCoords(point, c);
    });
    card.querySelector('[data-action="pick"]').addEventListener('click', async () => {
        if (!STATE.editing) return;
        setActivePoint(point);
        const c = await nui('mtj:pickCoords', {});
        if (c && !c.error) applyCoords(point, c);
        else alert('Kein Treffer beim Anvisieren.');
    });
}

// ==========================================================
//  TABS
// ==========================================================
function switchTab(tab) {
    $$('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === tab));
    $$('.panel').forEach(p => p.classList.toggle('hidden', p.dataset.panel !== tab));
}

// ==========================================================
//  LIST RENDER
// ==========================================================
function renderList() {
    const grid = $('#doorGrid');
    grid.innerHTML = '';
    const q = ($('#search').value || '').toLowerCase();
    const filtered = STATE.doors.filter(d => (d.label || '').toLowerCase().includes(q));
    $('#doorCount').textContent = `${STATE.doors.length} TÜREN`;
    $('#emptyHint').classList.toggle('hidden', STATE.doors.length > 0);
    filtered.forEach(d => grid.appendChild(buildDoorCard(d)));
}

function buildDoorCard(d) {
    const el = document.createElement('div');
    el.className = 'door-card' + (d.enabled === false ? ' disabled' : '');
    const tag = accessTag(d.access);
    el.innerHTML = `
        <div class="dc-id">#${d.id ?? '—'}</div>
        <div class="dc-label">${escapeHTML(d.label || 'UNBENANNT')}</div>
        <div class="dc-meta">
            <span class="${tag.cls}">${tag.text}</span>
            <span>RADIUS ${Math.round(d.visibility || 15)}M</span>
            <span>${(d.entry?.type || '—').toUpperCase()} → ${(d.exitp?.type || '—').toUpperCase()}</span>
        </div>
        <div class="dc-coords">
            <b>IN </b>: ${fmtCoords(d.entry?.coords)}<br/>
            <b>OUT</b>: ${fmtCoords(d.exitp?.coords)}
        </div>
        <div class="dc-actions">
            <button class="btn small" data-act="edit">BEARBEITEN</button>
            <button class="btn small ghost" data-act="toggle">${d.enabled === false ? 'AKTIV.' : 'DEAKT.'}</button>
            <button class="btn small danger" data-act="delete">LÖSCHEN</button>
        </div>`;

    el.querySelector('[data-act="edit"]').addEventListener('click', e => { e.stopPropagation(); openEditor(d); });
    el.querySelector('[data-act="toggle"]').addEventListener('click', async e => {
        e.stopPropagation();
        const newEnabled = !(d.enabled !== false);
        await nui('mtj:toggleDoor', { id: d.id, enabled: newEnabled });
        d.enabled = newEnabled;
        renderList();
    });
    el.querySelector('[data-act="delete"]').addEventListener('click', async e => {
        e.stopPropagation();
        if (!confirm(`Tür "${d.label}" wirklich löschen?`)) return;
        await nui('mtj:deleteDoor', { id: d.id });
        STATE.doors = STATE.doors.filter(x => x.id !== d.id);
        renderList();
    });
    return el;
}

function fmtCoords(c) {
    if (!c || c.x == null) return '— — —';
    return `${(+c.x).toFixed(2)} / ${(+c.y).toFixed(2)} / ${(+c.z).toFixed(2)}`;
}
function accessTag(a) {
    a = a || { type: 'public' };
    if (a.type === 'public') return { text: 'PUBLIC', cls: 'tag-pub' };
    if (a.type === 'job') return { text: `JOB: ${a.job||'?'}${a.grade!=null?' G'+a.grade:''}`, cls: 'tag-job' };
    if (a.type === 'license') return { text: `LIZ: ${a.license||'?'}`, cls: 'tag-lic' };
    if (a.type === 'job_license') return { text: `${a.job||'?'} + ${a.license||'?'}`, cls: 'tag-job' };
    return { text: 'PUBLIC', cls: 'tag-pub' };
}
function escapeHTML(s) {
    return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}

// ==========================================================
//  EDITOR
// ==========================================================
function openEditor(door) {
    STATE.editing = door ? deepClone(door) : newDoorTemplate();
    $('#editorTitle').textContent = door ? `BEARBEITEN: ${(door.label || '#'+door.id).toUpperCase()}` : 'NEUER EINGANG';

    // Basis-Felder
    $('#f_label').value   = STATE.editing.label || '';
    $('#f_enabled').checked = STATE.editing.enabled !== false;
    $('#f_return').checked = getReturnEnabled(STATE.editing.interaction);
    $('#f_vis').value     = STATE.editing.visibility || STATE.cfg.defaultR;
    $('#f_visLabel').textContent = $('#f_vis').value + 'm';

    // Chip-Rows neu rendern (jedes Mal frisch, weil presets variabel)
    buildChipRows('entry');
    buildChipRows('exitp');
    fillPointCard('entry');
    fillPointCard('exitp');
    setActivePoint('entry');

    // Always refresh dropdowns in case jobs/licenses changed
    renderJobsDropdown();
    renderLicensesDropdown();

    // Access
    const a = STATE.editing.access || { type: 'public' };
    $('#a_type').value = a.type || 'public';
    renderAccessVisibility();

    if (a.job) {
        $('#a_job').value = a.job;
        refreshGrades(a.job, a.grade);
    } else {
        $('#a_job').value = '';
        $('#a_grade').innerHTML = '<option value="">— BELIEBIG —</option>';
    }

    if (a.license) {
        $('#a_license').value = a.license;
    } else {
        $('#a_license').value = '';
    }

    switchTab('editor');
}

function newDoorTemplate() {
    return {
        label: '',
        enabled: true,
        visibility: STATE.cfg.defaultR || 15,
        interaction: { returnEnabled: true },
        entry: pointTemplate('entry'),
        exitp: pointTemplate('exitp'),
        access: { type: 'public' }
    };
}
function pointTemplate(p) {
    const isEntry = (p === 'entry');
    return {
        coords: null,
        heading: 0,
        type: 'marker',
        label: isEntry ? '[E] Betreten' : '[E] Verlassen',
        marker: (STATE.cfg.markers[0] && STATE.cfg.markers[0].id) || 'cylinder',
        color: (STATE.cfg.colors[0] && STATE.cfg.colors[0].id) || 'white',
        npc: (STATE.cfg.npcs[0] && STATE.cfg.npcs[0].id) || 'security'
    };
}
function deepClone(o) { return JSON.parse(JSON.stringify(o)); }

// ----- Point Card -----
function buildChipRows(point) {
    const card = $(`.point-card[data-point="${point}"]`);

    const mrow = card.querySelector('.marker-row');
    mrow.innerHTML = '';
    STATE.cfg.markers.forEach(m => {
        const c = document.createElement('div');
        c.className = 'chip'; c.dataset.id = m.id; c.textContent = m.label;
        c.addEventListener('click', () => {
            if (!STATE.editing) return;
            STATE.editing[point].marker = m.id;
            mrow.querySelectorAll('.chip').forEach(x => x.classList.toggle('active', x.dataset.id === m.id));
        });
        mrow.appendChild(c);
    });

    const crow = card.querySelector('.color-row');
    crow.innerHTML = '';
    STATE.cfg.colors.forEach(co => {
        const c = document.createElement('div');
        c.className = 'chip'; c.dataset.id = co.id;
        c.innerHTML = `<span class="dot" style="background:rgb(${co.rgb.join(',')})"></span>${co.label}`;
        c.addEventListener('click', () => {
            if (!STATE.editing) return;
            STATE.editing[point].color = co.id;
            crow.querySelectorAll('.chip').forEach(x => x.classList.toggle('active', x.dataset.id === co.id));
        });
        crow.appendChild(c);
    });

    const nrow = card.querySelector('.npc-row');
    nrow.innerHTML = '';
    STATE.cfg.npcs.forEach(n => {
        const c = document.createElement('div');
        c.className = 'chip'; c.dataset.id = n.id; c.textContent = n.label;
        c.addEventListener('click', () => {
            if (!STATE.editing) return;
            STATE.editing[point].npc = n.id;
            nrow.querySelectorAll('.chip').forEach(x => x.classList.toggle('active', x.dataset.id === n.id));
        });
        nrow.appendChild(c);
    });
}

function applyCoords(point, c) {
    if (!c || !STATE.editing) return;
    STATE.editing[point] = STATE.editing[point] || pointTemplate(point);
    STATE.editing[point].coords = { x: +c.x, y: +c.y, z: +c.z };
    STATE.editing[point].heading = +c.heading || 0;
    fillPointCard(point);
}

function fillPointCard(point) {
    if (!STATE.editing) return;
    const card = $(`.point-card[data-point="${point}"]`);
    STATE.editing[point] = STATE.editing[point] || pointTemplate(point);
    const p = STATE.editing[point];
    const coords = p.coords || {};

    card.querySelector('[data-axis="x"]').value = coords.x ?? '';
    card.querySelector('[data-axis="y"]').value = coords.y ?? '';
    card.querySelector('[data-axis="z"]').value = coords.z ?? '';
    card.querySelector('[data-axis="heading"]').value = p.heading ?? 0;
    card.querySelector('input[data-field="label"]').value = p.label || '';

    card.querySelectorAll('input[type="radio"]').forEach(r => r.checked = (r.value === (p.type || 'marker')));

    card.querySelectorAll('.marker-row .chip').forEach(x => x.classList.toggle('active', x.dataset.id === (p.marker || 'cylinder')));
    card.querySelectorAll('.color-row .chip').forEach(x => x.classList.toggle('active', x.dataset.id === (p.color || 'white')));
    card.querySelectorAll('.npc-row .chip').forEach(x => x.classList.toggle('active', x.dataset.id === (p.npc || 'security')));

    updatePointBlocks(point);
}
function updatePointBlocks(point) {
    if (!STATE.editing) return;
    const card = $(`.point-card[data-point="${point}"]`);
    const t = STATE.editing[point].type || 'marker';
    card.querySelector('.marker-block').classList.toggle('hidden', t !== 'marker');
    card.querySelector('.npc-block').classList.toggle('hidden', t !== 'npc');
}

// ----- Access -----
function renderAccessVisibility() {
    const t = $('#a_type').value;
    $$('.ac-job').forEach(el => el.classList.toggle('hidden', !(t === 'job' || t === 'job_license')));
    $$('.ac-license').forEach(el => el.classList.toggle('hidden', !(t === 'license' || t === 'job_license')));
}

function renderJobsDropdown() {
    const sel = $('#a_job');
    sel.innerHTML = '<option value="">— JOB WÄHLEN —</option>';
    (STATE.jobs || []).forEach(j => {
        const o = document.createElement('option');
        o.value = j.name;
        o.textContent = `${j.label} (${j.name})`;
        sel.appendChild(o);
    });
}

function renderLicensesDropdown() {
    const sel = $('#a_license');
    sel.innerHTML = '<option value="">— LIZENZ WÄHLEN —</option>';
    (STATE.cfg.licenses || []).forEach(l => {
        const o = document.createElement('option');
        o.value = l.id;
        o.textContent = `${l.label} (${l.id})`;
        sel.appendChild(o);
    });
}

async function refreshGrades(job, preselect) {
    const sel = $('#a_grade');
    sel.innerHTML = '<option value="">— BELIEBIG —</option>';
    if (!job) return;
    const grades = await nui('mtj:getGrades', { job });
    (Array.isArray(grades) ? grades : []).forEach(g => {
        const o = document.createElement('option');
        o.value = g.grade;
        o.textContent = `${g.grade} — ${g.label}`;
        sel.appendChild(o);
    });
    if (preselect != null) sel.value = String(preselect);
}

// ----- Save -----
async function saveCurrent() {
    const d = STATE.editing;
    if (!d) { return; }
    if (!d.label || d.label.trim().length < 2) { alert('Bitte ein Label eingeben.'); return; }

    // Sanity check Koordinaten
    d.entry = normalizePointForSave(d.entry, 'entry');
    d.exitp = normalizePointForSave(d.exitp, 'exitp');
    const noEntry = !hasRealCoords(d.entry?.coords);
    if (noEntry) { alert('Bitte zuerst den Eingang setzen.'); return; }

    // Access aufräumen
    d.access = d.access || { type: 'public' };
    if (d.access.type === 'public') {
        d.access = { type: 'public' };
    } else if (d.access.type === 'job') {
        if (!d.access.job) { alert('Bitte einen Job auswählen.'); return; }
    } else if (d.access.type === 'license') {
        if (!d.access.license) { alert('Bitte eine Lizenz auswählen.'); return; }
    } else if (d.access.type === 'job_license') {
        if (!d.access.job || !d.access.license) { alert('Bitte Job UND Lizenz auswählen.'); return; }
    }
    d.interaction = d.interaction || {};
    d.interaction.returnEnabled = getReturnEnabled(d.interaction);

    await nui('mtj:saveDoor', d);
    const fresh = await nui('mtj:refresh', {});
    if (Array.isArray(fresh)) STATE.doors = fresh;
    STATE.editing = null;
    renderList();
    switchTab('list');
}

function hasRealCoords(coords) {
    if (!coords) return false;
    const x = Number(coords.x);
    const y = Number(coords.y);
    const z = Number(coords.z);
    if (!Number.isFinite(x) || !Number.isFinite(y) || !Number.isFinite(z)) return false;
    return true;
}

function normalizePointForSave(point, pointKey) {
    const p = Object.assign(pointTemplate(pointKey), point || {});
    if (hasRealCoords(p.coords)) {
        p.coords = {
            x: Number(p.coords.x),
            y: Number(p.coords.y),
            z: Number(p.coords.z)
        };
        p.heading = Number.isFinite(Number(p.heading)) ? Number(p.heading) : 0;
    } else {
        p.coords = null;
        p.heading = 0;
    }
    return p;
}

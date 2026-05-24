"""
Dutch Agency — Migratie van lokale database naar Supabase
Uitvoeren: python3 migrate_to_supabase.py
"""

import sqlite3
import uuid
import json
import urllib.request
import urllib.error
import os

# ── Configuratie ──────────────────────────────────────────
SUPABASE_URL = 'https://agurvyolmndhefsafboi.supabase.co'
SUPABASE_KEY = 'PLAK_HIER_JE_SERVICE_ROLE_KEY'  # Haal op uit Supabase → Settings → API

# Pad naar de SQLite database (relatief aan dit script)
DB_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'dutch_agency.db')
# ──────────────────────────────────────────────────────────

HEADERS = {
    'apikey': SUPABASE_KEY,
    'Authorization': f'Bearer {SUPABASE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal'
}


def post(table, rows):
    """Stuur een batch rijen naar Supabase."""
    url = f'{SUPABASE_URL}/rest/v1/{table}'
    data = json.dumps(rows).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers=HEADERS, method='POST')
    try:
        with urllib.request.urlopen(req) as resp:
            return True
    except urllib.error.HTTPError as e:
        body = e.read().decode('utf-8')[:300]
        print(f'  FOUT {table}: {e.code} — {body}')
        return False


def insert_batches(table, rows, batch_size=200, label=''):
    total = len(rows)
    ok = 0
    for i in range(0, total, batch_size):
        batch = rows[i:i + batch_size]
        if post(table, batch):
            ok += len(batch)
            pct = int(ok / total * 100)
            print(f'  {label} {ok}/{total} ({pct}%)', end='\r')
    print(f'  {label} {ok}/{total} — klaar!         ')
    return ok


def main():
    print(f'\nVerbinden met SQLite: {DB_PATH}')
    if not os.path.exists(DB_PATH):
        print(f'FOUT: database niet gevonden op {DB_PATH}')
        return

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    # ── Labels ───────────────────────────────────────────
    print('\n1/5 Labels...')
    cur.execute('SELECT * FROM labels ORDER BY id')
    label_map = {}
    label_rows = []
    for l in cur.fetchall():
        new_id = str(uuid.uuid4())
        label_map[l['id']] = new_id
        label_rows.append({
            'id': new_id,
            'name': l['name'],
            'description': l['description'],
        })
    insert_batches('labels', label_rows, label='Labels')

    # ── Artiesten ────────────────────────────────────────
    print('\n2/5 Artiesten...')
    cur.execute('SELECT * FROM artists ORDER BY id')
    artist_map = {}
    artist_rows = []
    for a in cur.fetchall():
        new_id = str(uuid.uuid4())
        artist_map[a['id']] = new_id
        artist_rows.append({
            'id': new_id,
            'name': a['name'],
            'email': a['email'] or None,
            'phone': a['phone'] or None,
            'active': True,
        })
    insert_batches('artists', artist_rows, label='Artiesten')

    # ── Tracks ───────────────────────────────────────────
    print('\n3/5 Tracks...')
    cur.execute('SELECT * FROM tracks ORDER BY id')
    track_map = {}
    track_rows = []
    for t in cur.fetchall():
        new_id = str(uuid.uuid4())
        track_map[t['id']] = new_id
        track_rows.append({
            'id': new_id,
            'title': t['title'],
            'isrc': t['catalog_number'] or None,
            'label_id': label_map.get(t['label_id']) if t['label_id'] else None,
        })
    insert_batches('tracks', track_rows, label='Tracks')

    # ── Statement ────────────────────────────────────────
    print('\n4/5 Statement...')
    cur.execute('SELECT * FROM statements ORDER BY id')
    stmt_map = {}
    stmt_rows = []
    for s in cur.fetchall():
        new_id = str(uuid.uuid4())
        stmt_map[s['id']] = new_id
        stmt_rows.append({
            'id': new_id,
            'filename': s['filename'],
            'period': s['period'] or None,
            'total_royalties': 0,
            'line_count': 0,
        })
    insert_batches('statements', stmt_rows, label='Statements')

    # ── Statement lines ──────────────────────────────────
    print('\n5/5 Statement regels...')
    cur.execute('SELECT * FROM statement_lines ORDER BY id')
    sl_rows = []
    for r in cur.fetchall():
        sl_rows.append({
            'id': str(uuid.uuid4()),
            'statement_id': stmt_map.get(r['statement_id']),
            'label_name': r['label_name'] or None,
            'artist_name': r['raw_artist'] or None,
            'track_title': r['raw_track'] or None,
            'isrc': r['raw_catalog'] or None,
            'nett_royalty': float(r['nett_royalty'] or 0),
        })
    insert_batches('statement_lines', sl_rows, batch_size=100, label='Regels')

    conn.close()
    print('\nMigratie voltooid!')
    print('Ga naar de website en check het dashboard.')


if __name__ == '__main__':
    main()

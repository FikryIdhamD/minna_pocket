"""
validate.py — memeriksa assets/<book>/ sebelum masuk APK.

Pemakaian:  python3 tools/validate.py book1 [--no-audio]
Keluar dengan kode 1 jika ada kesalahan.

Pemeriksaan:
 1. Setiap lessons/Lxx.json cocok dengan schema/lesson.schema.json.
 2. Semua path gambar (img/...) dan audio (audio/...) yang dirujuk ada di assets/<book>/.
 3. Nomor bagian berurutan 1..n (bunkei, reibun, renshuu_a/b/c, mondai, bunpou).
 4. ID unik di seluruh buku.
 5. Waktu audio Kaiwa/Mondai naik (monoton) dan berada dalam durasi.
 6. manifest.json merujuk file yang ada.
"""
import json
import os
import sys

import jsonschema

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))


def walk(obj):
    if isinstance(obj, dict):
        yield obj
        for v in obj.values():
            yield from walk(v)
    elif isinstance(obj, list):
        for v in obj:
            yield from walk(v)


def main(book, skip_audio=False):
    base = os.path.join(ROOT, 'assets', book)
    schema = json.load(open(os.path.join(ROOT, 'schema', 'lesson.schema.json'), encoding='utf-8'))
    errors = []
    ids = set()
    manifest = json.load(open(os.path.join(base, 'manifest.json'), encoding='utf-8'))
    for lm in manifest['lessons']:
        path = os.path.join(base, lm['file'])
        if not os.path.exists(path):
            errors.append(f'manifest merujuk file tidak ada: {lm["file"]}')
            continue
        data = json.load(open(path, encoding='utf-8'))
        v = jsonschema.Draft202012Validator(schema)
        for e in v.iter_errors(data):
            errors.append(f'{lm["id"]}: skema: {"/".join(map(str, e.path))}: {e.message[:200]}')
        for d in walk(data):
            for key in (('image',) if skip_audio else ('image', 'audio')):
                p = d.get(key)
                if isinstance(p, str) and not os.path.exists(os.path.join(base, p)):
                    errors.append(f'{lm["id"]}: file tidak ada: {p}')
            if 'id' in d and isinstance(d['id'], str) and d['id'].startswith('L'):
                if d['id'] in ids:
                    errors.append(f'ID ganda: {d["id"]}')
                ids.add(d['id'])
        sec = data['sections']
        for key in ('bunkei', 'reibun', 'renshuu_a', 'renshuu_c', 'mondai', 'bunpou'):
            nums = [x['no'] for x in sec.get(key, [])]
            if nums and nums != list(range(1, len(nums) + 1)):
                errors.append(f'{lm["id"]}.{key}: nomor tidak berurutan {nums}')
        if 'renshuu_b' in sec:
            nums = [x['no'] for x in sec['renshuu_b']['items']]
            if nums != list(range(1, len(nums) + 1)):
                errors.append(f'{lm["id"]}.renshuu_b: nomor tidak berurutan {nums}')
            figs = {f['id'] for f in sec['renshuu_b']['figures']}
            for it in sec['renshuu_b']['items']:
                if it.get('figure') and it['figure'] not in figs:
                    errors.append(f'{it["id"]}: figure tidak dikenal {it["figure"]}')
        def check_times(name, ts, dur):
            prev = -1
            for t in ts:
                if not (0 <= t[0] < t[1] <= dur + 0.01) or t[0] < prev:
                    errors.append(f'{name}: waktu tidak valid {t}')
                prev = t[1]
        if 'kaiwa' in sec:
            check_times(f'{lm["id"]}.kaiwa', [l['t'] for l in sec['kaiwa']['lines']], sec['kaiwa']['duration'])
        for m in sec.get('mondai', []):
            if m.get('segments'):
                check_times(m['id'], [s['t'] for s in m['segments']], m['duration'])
                exp = len(m['examples']) + len(m['questions'])
                if len(m['segments']) != exp:
                    errors.append(f'{m["id"]}: jumlah segmen {len(m["segments"])} != {exp}')
    # ---- Mondaishuu
    from referencing import Registry, Resource
    reg = Registry().with_resource('lesson.schema.json', Resource.from_contents(schema))
    ms_schema = json.load(open(os.path.join(ROOT, 'schema', 'mondaishuu.schema.json'), encoding='utf-8'))
    msv = jsonschema.Draft202012Validator(ms_schema, registry=reg)
    for mm in manifest.get('mondaishuu', []) + manifest.get('fukushuu', []):
        path = os.path.join(base, mm['file'])
        if not os.path.exists(path):
            errors.append(f'manifest merujuk file tidak ada: {mm["file"]}')
            continue
        data = json.load(open(path, encoding='utf-8'))
        for e in msv.iter_errors(data):
            errors.append(f'{mm["id"]}: skema: {"/".join(map(str, e.path))}: {e.message[:200]}')
        for d in walk(data):
            p = d.get('image')
            if isinstance(p, str) and not os.path.exists(os.path.join(base, p)):
                errors.append(f'{mm["id"]}: file tidak ada: {p}')
            for b in d.get('blanks', []) if isinstance(d.get('blanks'), list) else []:
                if b['type'] in ('text', 'sentence', 'choice', 'free') and not b.get('answers_jp'):
                    errors.append(f'{d.get("id")}: blank tanpa answers_jp')
                if b['type'] == 'option' and not b.get('answer'):
                    errors.append(f'{d.get("id")}: blank option tanpa answer')
                if b['type'] == 'choice' and not b.get('choices_jp'):
                    errors.append(f'{d.get("id")}: blank choice tanpa choices_jp')
    for fn in ('kanji_index.json', 'search_index.json'):
        if not os.path.exists(os.path.join(base, fn)):
            errors.append(f'{fn} tidak ada')
    if errors:
        print('GAGAL:')
        for e in errors:
            print(' -', e)
        sys.exit(1)
    print(f'VALID: {len(manifest["lessons"])} bab, {len(ids)} ID')


if __name__ == '__main__':
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    main(args[0] if args else 'book1', skip_audio='--no-audio' in sys.argv)

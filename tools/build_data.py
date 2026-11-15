"""
build_data.py — membangun assets/book1/ dari content-src/book1/.

Pemakaian (dari folder proyek):
  python3 tools/build_data.py book1

Langkah:
 1. Baca content-src/<book>/L??.json (format penulisan, markup {漢字|かな}).
 2. Ubah semua field "jp", "*_jp", "*_rich" menjadi JpText terkompilasi (token + romaji).
 3. Beri ID tetap ke setiap item (mis. L01.renshuu_b.3).
 4. Tempelkan waktu audio (Kaiwa per baris, Mondai per soal) dari audio_raw.json
    (+ audio_overrides.json bila ada).
 5. Tulis assets/<book>/lessons/L??.json, manifest.json, kanji_index.json, search_index.json.
 6. Jalankan validate.py.
"""
import json
import os
import sys
import datetime

sys.path.insert(0, os.path.dirname(__file__))
from jptext import compile_jptext, romaji_line, kata_to_hira, kana_to_romaji  # noqa: E402
from audio_segments import split_largest_gaps, split_mondai, best_mondai_split, align_lines, mora_count  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
SECTION_ORDER = ['kosakata', 'bunkei', 'reibun', 'kaiwa', 'renshuu_a', 'renshuu_b', 'renshuu_c',
                 'mondai', 'bunpou', 'sankou']
SECTION_SOURCE = {'kosakata': 'translation', 'bunpou': 'translation', 'sankou': 'translation'}
LISTEN_KINDS = {'listen_write', 'listen_choice_image', 'listen_truefalse', 'listen_choice'}


def is_jp_key(k):
    return k == 'jp' or k.endswith('_jp') or k.endswith('_rich')


def convert(obj):
    if isinstance(obj, dict):
        out = {}
        for k, v in obj.items():
            if is_jp_key(k):
                if v is None:
                    out[k] = None
                elif isinstance(v, list):
                    out[k] = [[compile_jptext(y) for y in x] if isinstance(x, list) else compile_jptext(x) for x in v]
                else:
                    out[k] = compile_jptext(v)
            else:
                out[k] = convert(v)
        return out
    if isinstance(obj, list):
        return [convert(x) for x in obj]
    return obj


def reading_of(jt):
    return ''.join(t.get('r', t['s']) for t in jt['tokens'])


def assign_ids(lid, sec):
    s = sec
    n = 0
    for g in s.get('kosakata', {}).get('groups', []):
        for it in g['items']:
            n += 1
            it['id'] = f'{lid}.kosakata.{n}'
    for it in s.get('bunkei', []):
        it['id'] = f'{lid}.bunkei.{it["no"]}'
    for it in s.get('reibun', []):
        it['id'] = f'{lid}.reibun.{it["no"]}'
        for i, ln in enumerate(it['lines'], 1):
            ln['id'] = f'{it["id"]}.{i}'
    if 'kaiwa' in s:
        s['kaiwa']['id'] = f'{lid}.kaiwa'
        for i, ln in enumerate(s['kaiwa']['lines'], 1):
            ln['id'] = f'{lid}.kaiwa.{i}'
    for key in ('renshuu_a', 'renshuu_c', 'bunpou'):
        for it in s.get(key, []):
            it['id'] = f'{lid}.{key}.{it["no"]}'
    if 'renshuu_b' in s:
        for it in s['renshuu_b']['items']:
            it['id'] = f'{lid}.renshuu_b.{it["no"]}'
            for q in it['questions']:
                q['id'] = f'{it["id"]}.{q["no"]}'
    for it in s.get('mondai', []):
        it['id'] = f'{lid}.mondai.{it["no"]}'
        for q in it['questions']:
            q['id'] = f'{it["id"]}.{q["no"] if q.get("no") is not None else 0}'
    if 'sankou' in s:
        s['sankou']['id'] = f'{lid}.sankou'


def fill_speakers(lines):
    """Baris tanpa speaker mewarisi speaker sebelumnya; tandai awal giliran bicara."""
    cur_jp, cur_tr = None, None
    for ln in lines:
        if ln.get('speaker_jp') is not None:
            cur_jp, cur_tr = ln['speaker_jp'], ln.get('speaker_tr')
            ln['turn_start'] = True
        else:
            ln['speaker_jp'], ln['speaker_tr'] = cur_jp, cur_tr
            ln['turn_start'] = False


KAIWA_INTRO = 3


def align_kaiwa(speech, moras, breaks, total):
    """Selaras per adegan: baris break_before dipasangkan dengan jeda terpanjang di audio.
    Jika pembagian itu tidak masuk akal (adegan kekurangan interval), selaraskan sekaligus."""
    k = sum(breaks[1:])
    if k:
        gaps = sorted(range(len(speech) - 1), key=lambda i: speech[i + 1][0] - speech[i][1], reverse=True)[:k]
        cuts = sorted(gaps)
        sp_groups, start = [], 0
        for c in cuts:
            sp_groups.append(speech[start:c + 1])
            start = c + 1
        sp_groups.append(speech[start:])
        ln_groups, cur = [], []
        for m, b in zip(moras, breaks):
            if b and cur:
                ln_groups.append(cur)
                cur = []
            cur.append(m)
        ln_groups.append(cur)
        if all(len(sg) >= len(lg) for sg, lg in zip(sp_groups, ln_groups)):
            out = []
            for sg, lg in zip(sp_groups, ln_groups):
                out += align_lines(sg, lg, total)
            return out
    return align_lines(speech, moras, total)
MONDAI1_INTRO = 3
MONDAI_INTRO = 2


def attach_audio(lid, sec, raw, overrides):
    if 'kaiwa' in sec and sec['kaiwa'].get('audio'):
        key = f'{lid}_kaiwa'
        a = raw[key]
        lines = sec['kaiwa']['lines']
        if key in overrides:
            segs = overrides[key]
        else:
            moras = [mora_count(reading_of(l['jp'])) for l in lines]
            # 3 interval pertama = pengumuman CD ("第N課" + "会話" + judul), bukan isi dialog
            # interval tanpa suara manusia (efek suara mobil, pintu, dsb.) dibuang
            sp = a['speech'][KAIWA_INTRO:]
            if a.get('voiced'):
                # buang: vr < 0.2 (bunyi tanpa nada: mobil, pintu) dan vr >= 0.99 selama >= 0.9 dtk
                # (nada murni: bel pintu, dering telepon — ucapan selalu punya konsonan tak bersuara)
                sp = [iv for iv, vr in list(zip(a['speech'], a['voiced']))[KAIWA_INTRO:]
                      if vr >= 0.2 and not (vr >= 0.99 and iv[1] - iv[0] >= 0.9)]
            segs = align_kaiwa(sp, moras, [bool(l.get('break_before')) for l in lines], a['duration'])
        for ln, t in zip(lines, segs):
            ln['t'] = t
        sec['kaiwa']['duration'] = a['duration']
        sec['kaiwa']['timing'] = 'manual' if key in overrides else 'auto'
    for it in sec.get('mondai', []):
        if it.get('kind') in LISTEN_KINDS:
            key = f'{lid}_mondai{it["no"]}'
            if it.get('audio') is None:
                raise ValueError(f'{it["id"]}: soal dengar tanpa audio')
            a = raw[key]
            labels = [ex['label_jp']['jp'] for ex in it['examples']] + [str(q['no']) for q in it['questions']]
            # interval pengumuman CD di awal trek ("第N課 問題 1" / "問題 N")
            intro = MONDAI1_INTRO if it['no'] == 1 else MONDAI_INTRO
            segs = overrides.get(key) or best_mondai_split(a['speech'][intro:], len(it['examples']), len(it['questions']), a['duration'])
            it['duration'] = a['duration']
            it['timing'] = 'manual' if key in overrides else 'auto'
            it['segments'] = [{'label': lb, 't': t} for lb, t in zip(labels, segs)]


def iter_jptexts(obj, path=()):
    if isinstance(obj, dict):
        if 'tokens' in obj and 'jp' in obj and isinstance(obj['tokens'], list):
            yield path, obj
            return
        for k, v in obj.items():
            yield from iter_jptexts(v, path + (k,))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            yield from iter_jptexts(v, path + (i,))


def build(book):
    src_dir = os.path.join(ROOT, 'content-src', book)
    out_dir = os.path.join(ROOT, 'assets', book)
    os.makedirs(os.path.join(out_dir, 'lessons'), exist_ok=True)
    raw = json.load(open(os.path.join(src_dir, 'audio_raw.json'), encoding='utf-8'))
    ov_path = os.path.join(src_dir, 'audio_overrides.json')
    overrides = json.load(open(ov_path, encoding='utf-8')) if os.path.exists(ov_path) else {}

    lessons_meta = []
    kanji = {}
    search = []
    for fn in sorted(os.listdir(src_dir)):
        if not (fn.startswith('L') and fn.endswith('.json')):
            continue
        srcobj = json.load(open(os.path.join(src_dir, fn), encoding='utf-8'))
        lid = f'L{srcobj["lesson"]:02d}'
        data = convert(srcobj)
        sec = data['sections']
        assign_ids(lid, sec)
        if 'kaiwa' in sec:
            fill_speakers(sec['kaiwa']['lines'])
        for it in sec.get('renshuu_c', []):
            fill_speakers(it['dialog'])
        attach_audio(lid, sec, raw, overrides)
        data['id'] = lid
        with open(os.path.join(out_dir, 'lessons', f'{lid}.json'), 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, separators=(',', ':'))

        # ---- manifest
        secs = []
        for key in SECTION_ORDER:
            if key not in sec:
                continue
            v = sec[key]
            m = {'key': key, 'source': SECTION_SOURCE.get(key, 'main')}
            if key == 'kosakata':
                m['count'] = sum(len(g['items']) for g in v['groups'])
            elif key in ('bunkei', 'reibun', 'renshuu_a', 'renshuu_c', 'bunpou'):
                m['count'] = len(v)
                m['numbers'] = [x['no'] for x in v]
            elif key == 'renshuu_b':
                m['count'] = len(v['items'])
                m['numbers'] = [x['no'] for x in v['items']]
            elif key == 'mondai':
                m['count'] = len(v)
                m['numbers'] = [x['no'] for x in v]
                m['audio_numbers'] = [x['no'] for x in v if x.get('kind') in LISTEN_KINDS]
            elif key == 'kaiwa':
                m['audio'] = v.get('audio')
                m['duration'] = v.get('duration')
                m['title_jp'] = v['title_jp']
            elif key == 'sankou':
                m['title_jp'] = v['title_jp']
                m['title_tr'] = v['title_tr']
            secs.append(m)
        lessons_meta.append({'lesson': srcobj['lesson'], 'id': lid, 'file': f'lessons/{lid}.json',
                             'title_jp': data['title_jp'], 'title_tr': data['title_tr'], 'sections': secs})

        # ---- indeks kanji
        kosa_meaning = {}
        for g in sec.get('kosakata', {}).get('groups', []):
            for it in g['items']:
                for jt in (it.get('kanji_jp'), it.get('kana_jp')):
                    if not jt:
                        continue
                    ks = [t for t in jt['tokens'] if t.get('k')]
                    rest = ''.join(t['s'] for t in jt['tokens'] if not t.get('k')).strip('～―〜　 。')
                    # arti hanya dipakai jika entri berisi persis satu kata berkanji (boleh diawali ～/―)
                    if len(ks) == 1 and rest == '':
                        kosa_meaning.setdefault(ks[0]['s'], it['tr'])
        if 'sankou' in sec:
            for blk in sec['sankou']['blocks']:
                for row in blk.get('rows', []):
                    for cell in row:
                        for c in cell:
                            if c.get('tr') and c.get('jp'):
                                ks = [t for t in c['jp']['tokens'] if t.get('k')]
                                rest = ''.join(t['s'] for t in c['jp']['tokens'] if not t.get('k')).strip()
                                if len(ks) == 1 and rest == '':
                                    kosa_meaning.setdefault(ks[0]['s'], c['tr'])
        for path, jt in iter_jptexts(sec):
            for t in jt['tokens']:
                if not t.get('k'):
                    continue
                if not any('\u3400' <= ch <= '\u9fff' or ch == '々' for ch in t['s']):
                    continue  # bacaan untuk angka (mis. {7|なな}つ) bukan kata berkanji
                e = kanji.setdefault(t['s'], {'word': t['s'], 'readings': [], 'readings_ro': [], 'meaning': None,
                                              'first_lesson': srcobj['lesson'], 'occurrences': []})
                if t['r'] not in e['readings']:
                    e['readings'].append(t['r'])
                    e['readings_ro'].append(kana_to_romaji(t['r']))
                if e['meaning'] is None and t['s'] in kosa_meaning:
                    e['meaning'] = kosa_meaning[t['s']]
                ref = f'{lid}.{path[0]}'
                if ref not in [o['ref'] for o in e['occurrences']]:
                    e['occurrences'].append({'lesson': srcobj['lesson'], 'section': path[0], 'ref': ref})

        # ---- indeks pencarian
        for g in sec.get('kosakata', {}).get('groups', []):
            for it in g['items']:
                jt = it.get('kanji_jp') or it['kana_jp']
                search.append({'type': 'kosakata', 'ref': it['id'], 'lesson': srcobj['lesson'],
                               'jp': jt['jp'], 'kana': kata_to_hira(reading_of(it['kana_jp'])),
                               'ro': romaji_line(it['kana_jp']).lower(), 'tr': it['tr']})
        for it in sec.get('bunkei', []):
            search.append({'type': 'kalimat', 'ref': it['id'], 'lesson': srcobj['lesson'], 'jp': it['jp']['jp'],
                           'kana': kata_to_hira(reading_of(it['jp'])), 'ro': romaji_line(it['jp']).lower(), 'tr': it['tr']})
        for it in sec.get('reibun', []):
            for ln in it['lines']:
                search.append({'type': 'kalimat', 'ref': ln['id'], 'lesson': srcobj['lesson'], 'jp': ln['jp']['jp'],
                               'kana': kata_to_hira(reading_of(ln['jp'])), 'ro': romaji_line(ln['jp']).lower(), 'tr': ln['tr']})
        for ln in sec.get('kaiwa', {}).get('lines', []):
            search.append({'type': 'kalimat', 'ref': ln['id'], 'lesson': srcobj['lesson'], 'jp': ln['jp']['jp'],
                           'kana': kata_to_hira(reading_of(ln['jp'])), 'ro': romaji_line(ln['jp']).lower(), 'tr': ln['tr']})
        for it in sec.get('bunpou', []):
            search.append({'type': 'tata_bahasa', 'ref': it['id'], 'lesson': srcobj['lesson'],
                           'jp': it['title_rich']['jp'], 'kana': '', 'ro': '', 'tr': it['title_rich']['jp']})
        if 'sankou' in sec:
            for blk in sec['sankou']['blocks']:
                for row in blk.get('rows', []):
                    # terjemahan dari sel lain di baris yang sama (sel berisi teks Indonesia saja)
                    row_tr = ' / '.join(c['tr'] for cell in row for c in cell if c.get('tr') and not c.get('jp'))
                    for cell in row:
                        for c in cell:
                            if not c.get('jp'):
                                continue
                            search.append({'type': 'referensi', 'ref': sec['sankou']['id'], 'lesson': srcobj['lesson'],
                                           'jp': c['jp']['jp'], 'kana': kata_to_hira(reading_of(c['jp'])),
                                           'ro': romaji_line(c['jp']).lower(), 'tr': c.get('tr') or row_tr})

    # ---- dokumen tambahan (extras): intro, howto, matome ...
    ex_dir = os.path.join(src_dir, 'extras')
    os.makedirs(os.path.join(out_dir, 'extras'), exist_ok=True)
    if os.path.isdir(ex_dir):
        for fn in sorted(os.listdir(ex_dir)):
            if fn.endswith('.json'):
                doc = convert(json.load(open(os.path.join(ex_dir, fn), encoding='utf-8')))
                with open(os.path.join(out_dir, 'extras', fn), 'w', encoding='utf-8') as f:
                    json.dump(doc, f, ensure_ascii=False, separators=(',', ':'))

    # ---- Mondaishuu (mondaishuu/) dan 復習・まとめ buku utama (fukushuu/) — format sama
    def build_sets(folder):
        meta = []
        d_in = os.path.join(src_dir, folder)
        os.makedirs(os.path.join(out_dir, folder), exist_ok=True)
        if not os.path.isdir(d_in):
            return meta
        for fn in sorted(os.listdir(d_in)):
            if not fn.endswith('.json'):
                continue
            ms = convert(json.load(open(os.path.join(d_in, fn), encoding='utf-8')))
            for ex in ms['exercises']:
                ex['id'] = f'{ms["id"]}.{ex["no"]}'
                for it in ex['items']:
                    it['id'] = f'{ex["id"]}.{it["no"]}'
                    n_blank = sum(1 for l in it['lines_jp'] for t in l['tokens'] if t.get('blank'))
                    if n_blank != len(it['blanks']):
                        raise ValueError(f'{it["id"]}: {n_blank} tempat kosong tetapi {len(it["blanks"])} blanks')
            with open(os.path.join(out_dir, folder, f'{ms["id"]}.json'), 'w', encoding='utf-8') as f:
                json.dump(ms, f, ensure_ascii=False, separators=(',', ':'))
            meta.append({'id': ms['id'], 'file': f'{folder}/{ms["id"]}.json', 'lessons': ms['lessons'],
                         'title_jp': ms['title_jp'], 'kind': ms.get('kind', 'lesson'),
                         'exercise_count': len(ms['exercises']),
                         'item_count': sum(len(e['items']) for e in ms['exercises'])})
        return meta
    ms_meta = build_sets('mondaishuu')
    fk_meta = build_sets('fukushuu')

    manifest = {
        'book': int(book[-1]),
        'data_version': datetime.date.today().strftime('%Y.%m.%d'),
        'title': 'Minna no Nihongo Shokyu I' if book == 'book1' else 'Minna no Nihongo Shokyu II',
        'lessons': lessons_meta,
        'mondaishuu': ms_meta,
        'fukushuu': fk_meta,
        'sequence': [{'type': 'lesson', 'lesson': m['lesson']} for m in lessons_meta],
    }
    seq_path = os.path.join(src_dir, 'sequence.json')
    if os.path.exists(seq_path):
        manifest['sequence'] = json.load(open(seq_path, encoding='utf-8'))
        by_id = {m['id']: m for m in fk_meta}
        for it in manifest['sequence']:
            if it['type'] in ('fukushuu', 'matome'):
                m = by_id[it['id']]  # KeyError bila id di sequence.json tidak ada set-nya
                ls = m['lessons']
                it['title_jp'] = m['title_jp']
                it['subtitle'] = (f'Bab {ls[0]}–{ls[-1]} · {m["item_count"]} soal')
    with open(os.path.join(out_dir, 'manifest.json'), 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=1)
    with open(os.path.join(out_dir, 'kanji_index.json'), 'w', encoding='utf-8') as f:
        json.dump(sorted(kanji.values(), key=lambda e: (e['first_lesson'], e['word'])), f, ensure_ascii=False, separators=(',', ':'))
    with open(os.path.join(out_dir, 'search_index.json'), 'w', encoding='utf-8') as f:
        json.dump(search, f, ensure_ascii=False, separators=(',', ':'))
    print(f'OK: {len(lessons_meta)} bab, {len(kanji)} kata berkanji, {len(search)} entri pencarian')


if __name__ == '__main__':
    build(sys.argv[1] if len(sys.argv) > 1 else 'book1')

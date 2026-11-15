"""
jptext.py — mengubah teks bermarkup (format content-src) menjadi JpText terkompilasi.

Markup:
  {漢字|かな}   kata berkanji + furigana persis seperti di buku
  [[teks]]      bagian bergaris bawah (slot pengganti di Renshuu C)
  ＿            tempat kosong (isian)
  　            spasi lebar seperti di buku (dipertahankan)

Output JpText:
  {"jp": "<teks polos>", "tokens": [ {"s":..., "r":..., "ro":..., "k":true, "u":true, "blank":true}, ... ]}
  - s  : teks tampil
  - r  : bacaan (hanya untuk token kanji)
  - ro : romaji token ini (sudah termasuk spasi di depan bila perlu)
  - k  : true jika token kanji (bisa ditekan untuk furigana)
  - u  : true jika bergaris bawah
  - blank : true jika tempat kosong
"""
import re
import unicodedata

try:
    import fugashi
    _TAGGER = fugashi.Tagger()
except Exception:  # pragma: no cover
    _TAGGER = None

MARKUP_RE = re.compile(r"\{([^|{}]+)\|([^{}]+)\}|\[\[|\]\]|＿")

# ---------------------------------------------------------------- kana → romaji (Hepburn)
_BASE = {
 'あ':'a','い':'i','う':'u','え':'e','お':'o','か':'ka','き':'ki','く':'ku','け':'ke','こ':'ko',
 'さ':'sa','し':'shi','す':'su','せ':'se','そ':'so','た':'ta','ち':'chi','つ':'tsu','て':'te','と':'to',
 'な':'na','に':'ni','ぬ':'nu','ね':'ne','の':'no','は':'ha','ひ':'hi','ふ':'fu','へ':'he','ほ':'ho',
 'ま':'ma','み':'mi','む':'mu','め':'me','も':'mo','や':'ya','ゆ':'yu','よ':'yo',
 'ら':'ra','り':'ri','る':'ru','れ':'re','ろ':'ro','わ':'wa','ゐ':'i','ゑ':'e','を':'o','ん':'n',
 'が':'ga','ぎ':'gi','ぐ':'gu','げ':'ge','ご':'go','ざ':'za','じ':'ji','ず':'zu','ぜ':'ze','ぞ':'zo',
 'だ':'da','ぢ':'ji','づ':'zu','で':'de','ど':'do','ば':'ba','び':'bi','ぶ':'bu','べ':'be','ぼ':'bo',
 'ぱ':'pa','ぴ':'pi','ぷ':'pu','ぺ':'pe','ぽ':'po','ゔ':'vu',
 'ぁ':'a','ぃ':'i','ぅ':'u','ぇ':'e','ぉ':'o','ゃ':'ya','ゅ':'yu','ょ':'yo','ゎ':'wa',
}
_DIGRAPH = {
 'きゃ':'kya','きゅ':'kyu','きょ':'kyo','しゃ':'sha','しゅ':'shu','しょ':'sho','ちゃ':'cha','ちゅ':'chu','ちょ':'cho',
 'にゃ':'nya','にゅ':'nyu','にょ':'nyo','ひゃ':'hya','ひゅ':'hyu','ひょ':'hyo','みゃ':'mya','みゅ':'myu','みょ':'myo',
 'りゃ':'rya','りゅ':'ryu','りょ':'ryo','ぎゃ':'gya','ぎゅ':'gyu','ぎょ':'gyo','じゃ':'ja','じゅ':'ju','じょ':'jo',
 'ぢゃ':'ja','ぢゅ':'ju','ぢょ':'jo','びゃ':'bya','びゅ':'byu','びょ':'byo','ぴゃ':'pya','ぴゅ':'pyu','ぴょ':'pyo',
 # perluasan katakana (ditulis dalam hiragana setelah konversi)
 'しぇ':'she','ちぇ':'che','じぇ':'je','てぃ':'ti','でぃ':'di','でゅ':'dyu','とぅ':'tu','どぅ':'du',
 'ふぁ':'fa','ふぃ':'fi','ふぇ':'fe','ふぉ':'fo','ふゅ':'fyu','うぃ':'wi','うぇ':'we','うぉ':'wo',
 'ゔぁ':'va','ゔぃ':'vi','ゔぇ':'ve','ゔぉ':'vo','つぁ':'tsa','つぃ':'tsi','つぇ':'tse','つぉ':'tso',
 'いぇ':'ye','くぁ':'kwa','ぐぁ':'gwa',
}
_PUNCT = {'、':',','。':'.','？':'?','！':'!','・':' ','「':'“','」':'”','（':'(','）':')','［':'[','］':']',
          '〜':'~','～':'~','―':'-','—':'-','…':'…','：':':','／':'/','　':' ','〈':'<','〉':'>'}


def kata_to_hira(s: str) -> str:
    out = []
    for ch in s:
        o = ord(ch)
        if 0x30A1 <= o <= 0x30F6:
            out.append(chr(o - 0x60))
        else:
            out.append(ch)
    return ''.join(out)


def kana_to_romaji(text: str) -> str:
    """Hepburn: っ menggandakan konsonan, ん+vokal/y → n', ー mengulang vokal sebelumnya."""
    s = kata_to_hira(text)
    out = []
    i = 0
    sokuon = False
    while i < len(s):
        ch = s[i]
        if ch in 'っ':
            sokuon = True
            i += 1
            continue
        if ch == 'ー':
            prev = ''.join(out)
            v = next((c for c in reversed(prev) if c in 'aiueo'), '')
            out.append(v)
            i += 1
            continue
        pair = s[i:i+2]
        if pair in _DIGRAPH:
            r = _DIGRAPH[pair]; i += 2
        elif ch in _BASE:
            r = _BASE[ch]; i += 1
            if ch == 'ん' and i < len(s) and (s[i] in 'あいうえおやゆよ' or s[i] in 'アイウエオヤユヨ'):
                r = "n'"
        elif ch in _PUNCT:
            r = _PUNCT[ch]; i += 1
        else:
            r = unicodedata.normalize('NFKC', ch); i += 1
        if sokuon:
            if r.startswith('ch'):
                r = 't' + r
            elif r and r[0].isalpha() and r[0] not in 'aiueon':
                r = r[0] + r
            sokuon = False
        out.append(r)
    return ''.join(out)


def is_kana(ch: str) -> bool:
    o = ord(ch)
    return 0x3041 <= o <= 0x309F or 0x30A0 <= o <= 0x30FF


def has_japanese(s: str) -> bool:
    return any(is_kana(c) or 0x4E00 <= ord(c) <= 0x9FFF for c in s)

# ---------------------------------------------------------------- parsing markup

def parse_markup(src: str):
    """Kembalikan list segmen mentah: (teks, bacaan|None, underline, blank)."""
    segs = []
    pos = 0
    under = False
    for m in MARKUP_RE.finditer(src):
        if m.start() > pos:
            segs.append((src[pos:m.start()], None, under, False))
        tok = m.group(0)
        if tok == '[[':
            under = True
        elif tok == ']]':
            under = False
        elif tok == '＿':
            segs.append(('＿', None, under, True))
        else:
            segs.append((m.group(1), m.group(2), under, False))
        pos = m.end()
    if pos < len(src):
        segs.append((src[pos:], None, under, False))
    if under:
        raise ValueError(f"[[ tidak ditutup: {src}")
    if '{' in ''.join(s[0] for s in segs) or '}' in ''.join(s[0] for s in segs):
        raise ValueError(f"Markup furigana rusak: {src}")
    return segs

# ---------------------------------------------------------------- pemenggalan kata untuk spasi romaji
_HYPHEN_SUFFIX = {'さん', 'ちゃん', 'さま', 'くん', '様', '君'}
_SPACED_AUX = {'です', 'でし', 'でしょう', 'だ', 'だっ', 'だろう', 'じゃ'}


def _morph_boundaries(plain: str):
    """dict posisi_karakter → 'space' | 'hyphen' | 'particle:<romaji>' (awal morfem)."""
    res = {}
    if _TAGGER is None or not plain.strip():
        return res
    pos = 0
    prev = None
    for w in _TAGGER(plain):
        surf = w.surface
        start = plain.find(surf, pos)
        if start < 0:
            continue
        pos = start + len(surf)
        f = w.feature
        p1, p2 = f.pos1, f.pos2
        mark = None
        if prev is not None:
            pp1 = prev.feature.pos1
            if p1 == '補助記号' or p1 == '空白':
                mark = None
            elif pp1 == '補助記号':
                mark = 'space' if prev.surface in ('、', '。', '？', '！', '，') else None
            elif pp1 == '接頭辞':
                mark = None
            elif _is_katakana(surf) and _is_katakana(prev.surface):
                mark = None
            elif p1 == '接尾辞':
                mark = 'hyphen' if surf in _HYPHEN_SUFFIX else None
            elif p1 == '助動詞':
                mark = 'space' if surf in _SPACED_AUX or w.feature.lemma in ('です', 'だ') else None
            elif p1 == '形容詞' and surf.startswith('な') and pp1 == '形容詞':
                mark = None  # さむく|ない → samukunai
            elif p1 == '助詞':
                if (p2 == '接続助詞' and surf in ('て', 'で', 'ば')
                        or surf in ('たり', 'だり')) and pp1 in ('動詞', '助動詞', '形容詞'):
                    mark = None
                else:
                    mark = 'space'
            elif p1 == '動詞' and p2 == '非自立可能' and pp1 in ('動詞',):
                mark = None
            else:
                mark = 'space'
        if p1 == '助詞' and surf in ('は', 'へ', 'を'):
            res.setdefault(start, None)
            res[('particle', start)] = {'は': 'wa', 'へ': 'e', 'を': 'o'}[surf]
        if mark:
            res[start] = mark
        prev = w
    return res


def _is_katakana(s: str) -> bool:
    return bool(s) and all(0x30A0 <= ord(c) <= 0x30FF for c in s)


def compile_jptext(src):
    if src is None:
        return None
    if not isinstance(src, str):
        raise TypeError(f"JpText harus string: {src!r}")
    segs = parse_markup(src)
    plain = ''.join(s[0] for s in segs)
    marks = _morph_boundaries(plain.replace('＿', '　'))

    tokens = []
    offset = 0
    for text, reading, under, blank in segs:
        start = offset
        offset += len(text)
        if blank:
            tokens.append({'s': '＿', 'ro': '___', 'blank': True, **({'u': True} if under else {})})
            continue
        if reading is not None:
            ro = kana_to_romaji(reading)
            m = marks.get(start)
            prefix = ' ' if m == 'space' else ('-' if m == 'hyphen' else '')
            tok = {'s': text, 'r': reading, 'ro': prefix + ro, 'k': True}
            if under:
                tok['u'] = True
            tokens.append(tok)
            continue
        # teks non-kanji: pecah per posisi pemenggalan
        pieces = []
        cur = ''
        cur_start = start
        for i, ch in enumerate(text):
            p = start + i
            m = marks.get(p)
            if i > 0 and m in ('space', 'hyphen'):
                pieces.append((cur, cur_start))
                cur, cur_start = '', p
            cur += ch
        pieces.append((cur, cur_start))
        ro_parts = []
        for piece, pstart in pieces:
            m = marks.get(pstart)
            prefix = ' ' if m == 'space' else ('-' if m == 'hyphen' else '')
            part = marks.get(('particle', pstart))
            if part and piece[:1] in 'はへを':
                r = part + kana_to_romaji(piece[1:])
            else:
                r = kana_to_romaji(piece)
            ro_parts.append(prefix + r)
        tok = {'s': text, 'ro': ''.join(ro_parts)}
        if under:
            tok['u'] = True
        tokens.append(tok)
    # angka diikuti huruf Jepang → beri spasi
    for a, b in zip(tokens, tokens[1:]):
        if a['s'][-1:].isdigit() and b['s'][:1] and not b['s'][:1].isdigit() and not b['ro'].startswith(' '):
            b['ro'] = ' ' + b['ro']
    # ungkapan baku (bacaan per huruf ≠ cara baca lazim)
    # は tepat setelah kata berkanji lalu spasi/tanda baca = partikel topik (MeCab kadang membaca 今晩は sebagai salam)
    for a, b in zip(tokens, tokens[1:]):
        if a.get('k') and re.match(r'(?i)ha(?=[\s,.?!]|$)', b['ro']) and re.match(r'は(?=[\s　、。？！]|$)', b['s']):
            b['ro'] = ('' if a['ro'].endswith(' ') else ' ') + ('Wa' if b['ro'][0] == 'H' else 'wa') + b['ro'][2:]
    for t in tokens:
        # でも、 (konjungsi "tetapi") — di awal token atau setelah akhir kalimat
        t['ro'] = re.sub(r'(?i)(^\s*|(?<=[.?!] ))(d)e mo(?=[,.])', lambda m: m.group(1) + m.group(2) + 'emo', t['ro'])
        for a, b in (('konnichiha', 'konnichiwa'), ('konbanha', 'konbanwa'), ('ano u', 'anou'),
                     ('dou mo', 'doumo'), ('sayou nara', 'sayounara')):
            t['ro'] = re.sub(a, b, t['ro'], flags=re.I) if a in t['ro'].lower() else t['ro']
    # spasi setelah tanda baca (di dalam token maupun antar token)
    for t in tokens:
        t['ro'] = re.sub(r'([,.?!])(?=[^\s,.?!)\]…"\-])', r'\1 ', t['ro'])
        t['ro'] = re.sub(r'(\d), (\d{3})(?!\d)', r'\1,\2', t['ro'])  # 2,500 tetap utuh (2、3 tidak)
        t['ro'] = re.sub(r'(\d)\. (\d)', r'\1.\2', t['ro'])  # 1.5
    # tanda kutip “…”: spasi di luar, rapat di dalam
    for t in tokens:
        t['ro'] = re.sub(r'(?<=[^\s(“])“', ' “', t['ro'])
        t['ro'] = re.sub(r'“\s+', '“', t['ro'])
        t['ro'] = re.sub(r'\s+”', '”', t['ro'])
        t['ro'] = re.sub(r'”(?=[A-Za-z0-9])', '” ', t['ro'])
    for a, b in zip(tokens, tokens[1:]):
        if b['ro'].startswith('“') and a['ro'] and not a['ro'][-1].isspace() and a['ro'][-1] not in '(“':
            b['ro'] = ' ' + b['ro']
        if a['ro'].endswith('”') and b['ro'][:1].isalnum():
            b['ro'] = ' ' + b['ro']
        if a['ro'].rstrip().endswith('“'):
            b['ro'] = b['ro'].lstrip()
    for a, b in zip(tokens, tokens[1:]):
        if re.search(r'[,.?!]$', a['ro']) and b['ro'][:1] not in ('', ' ', ',', '.', '?', '!', ')', ']', '…'):
            b['ro'] = ' ' + b['ro']
    # rapikan spasi & kapital di awal kalimat (per karakter)
    cap = True
    for idx, t in enumerate(tokens):
        ro = re.sub(r'\s+', ' ', t['ro'])
        if idx == 0:
            ro = ro.lstrip()
        chars = list(ro)
        for i, c in enumerate(chars):
            if cap and c.isalnum():
                if c.isalpha():
                    chars[i] = c.upper()
                cap = False
            elif c in '.?!“':
                cap = True
        t['ro'] = ''.join(chars)
    # hapus spasi sebelum tanda baca penutup
    for t in tokens:
        t['ro'] = re.sub(r' ([,.?!)\]])', r'\1', t['ro'])
        t['ro'] = re.sub(r'(\d), ?(\d{3})(?!\d)', r'\1,\2', t['ro'])  # 2,500 tetap utuh
        t['ro'] = re.sub(r'(\d)\. ?(\d)', r'\1.\2', t['ro'])
        t['ro'] = re.sub(r'(\d) ?- ?(?=\d)', r'\1-', t['ro'])  # 349-7895
        t['ro'] = re.sub(r'^ ?- ?(?=\d)', '-', t['ro'])
    for a, b in zip(tokens, tokens[1:]):
        if a['s'][-1:].isdigit() and b['ro'].lstrip().startswith('-'):
            b['ro'] = b['ro'].lstrip()
            b['ro'] = re.sub(r'^- (?=\d)', '-', b['ro'])
        if a['ro'].endswith('-') and b['s'][:1].isdigit():
            b['ro'] = b['ro'].lstrip()
    # partikel は/へ/を tepat setelah tanda kutip tidak selalu dikenali MeCab
    for t in tokens:
        t['ro'] = re.sub(r'” (ha|he|wo)(?= |$)', lambda m: '” ' + {'ha': 'wa', 'he': 'e', 'wo': 'o'}[m.group(1)], t['ro'])
    # tidak ada spasi ganda antar token
    for a, b in zip(tokens, tokens[1:]):
        if a['ro'][-1:].isspace() and b['ro'][:1].isspace():
            b['ro'] = b['ro'].lstrip()
    return {'jp': plain, 'tokens': tokens}


def romaji_line(jt) -> str:
    s = ''.join(t['ro'] for t in jt['tokens'])
    s = re.sub(r'\s+', ' ', s).strip()
    s = re.sub(r' ([,.?!)\]])', r'\1', s)
    s = re.sub(r'(\d), ?(\d{3})(?!\d)', r'\1,\2', s)
    s = re.sub(r'(\d)\. ?(\d)', r'\1.\2', s)
    s = re.sub(r'(\d) ?- ?(?=\d)', r'\1-', s)
    return s


if __name__ == '__main__':
    import sys
    for line in sys.argv[1:] or [
        'わたしは　マイク・ミラーです。',
        'アメリカから　{来|き}ました。',
        '{佐藤|さとう}さん、こちらは　マイク・ミラーさんです。',
        'テレーザちゃんは　{何歳|なんさい}ですか。',
        '……9{歳|さい}です。',
        'ミラーさんは　IMCの　{社員|しゃいん}です。',
        '{初|はじ}めまして。　[[マイク・ミラー]]です。',
        'カリナさん（＿）　{先生|せんせい}です（＿）。',
        'どうぞ　よろしく　お{願|ねが}いします。',
        'サントスさんは　{学生|がくせい}じゃ　ありません。',
        '{失礼|しつれい}ですが、お{名前|なまえ}は？',
    ]:
        jt = compile_jptext(line)
        print(jt['jp'], '→', romaji_line(jt))

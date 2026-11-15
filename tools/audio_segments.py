"""
audio_segments.py — membagi interval bersuara (dari audio_raw.json) menjadi segmen.

- split_largest_gaps(speech, n): untuk Mondai. Memotong pada n-1 jeda terpanjang.
- align_lines(speech, moras): untuk Kaiwa. Dynamic programming yang mencocokkan
  durasi kelompok interval dengan panjang baris (jumlah mora), sambil memilih
  jeda panjang sebagai batas.
Semua hasil bersifat otomatis; koreksi manual bisa ditulis di
content-src/book1/audio_overrides.json dengan kunci yang sama ("L01_kaiwa", ...).
"""
from functools import lru_cache

LEAD = 0.12   # detik sebelum suara dimulai
TAIL = 0.25   # detik setelah suara berakhir


def _pad(groups, total):
    out = []
    for i, (s, e) in enumerate(groups):
        s2 = max(0.0, s - LEAD)
        e2 = min(total, e + TAIL)
        if i + 1 < len(groups):
            e2 = min(e2, groups[i + 1][0] - LEAD)
        out.append([round(s2, 2), round(e2, 2)])
    return out


def split_largest_gaps(speech, n, total):
    if n <= 0:
        return []
    if len(speech) < n:
        raise ValueError(f"Interval bersuara ({len(speech)}) lebih sedikit dari segmen yang diminta ({n})")
    gaps = sorted(range(len(speech) - 1), key=lambda i: speech[i + 1][0] - speech[i][1], reverse=True)[: n - 1]
    cuts = sorted(gaps)
    groups, start = [], 0
    for c in cuts:
        groups.append([speech[start][0], speech[c][1]])
        start = c + 1
    groups.append([speech[start][0], speech[-1][1]])
    return _pad(groups, total)


def mora_count(kana: str) -> int:
    small = set('ゃゅょぁぃぅぇぉャュョァィゥェォ')
    digits = sum(1 for c in kana if c.isdigit())  # angka dibaca ±3 mora per digit
    return max(1, sum(1 for c in kana if ('ぁ' <= c <= 'ヿ') and c not in small and c != '・') + 3 * digits)


def align_lines(speech, moras, total, gap_weight=2.0):
    m, n = len(speech), len(moras)
    if m < n:
        raise ValueError(f"Interval ({m}) < baris ({n})")
    span = sum(e - s for s, e in speech)
    rate = span / sum(moras)

    @lru_cache(None)
    def best(i, j):
        # kelompokkan speech[i:] menjadi baris j..n-1
        if j == n:
            return (0.0, ()) if i == m else (float('inf'), ())
        if m - i < n - j:
            return (float('inf'), ())
        res = (float('inf'), ())
        for k in range(i + 1, m - (n - j - 1) + 1):
            dur = sum(e - s for s, e in speech[i:k])
            exp = moras[j] * rate
            c = (dur - exp) ** 2 / exp
            if k < m:
                c -= gap_weight * (speech[k][0] - speech[k - 1][1])
            sub = best(k, j + 1)
            if c + sub[0] < res[0]:
                res = (c + sub[0], (k,) + sub[1])
        return res

    _, cuts = best(0, 0)
    groups, start = [], 0
    for k in cuts:
        groups.append([speech[start][0], speech[k - 1][1]])
        start = k
    return _pad(groups, total)


def split_mondai(speech, n_examples, n_questions, total, max_marker=0.45, min_gap=1.0):
    """Mondai: tiap soal diawali ucapan nomor yang pendek (<= max_marker dtk) setelah jeda >= min_gap.
    - Ada contoh: kelompok pertama dimulai dari awal trek (pembuka + contoh), batas berikutnya = penanda
      dengan jeda-sebelum terpanjang.
    - Tanpa contoh: pembuka trek dibuang; soal pertama dimulai di penanda pertama yang terpilih.
    Jika penanda tidak cukup → jatuh ke split_largest_gaps.
    """
    n_groups = n_examples + n_questions
    markers = []
    for i in range(1, len(speech)):
        dur = speech[i][1] - speech[i][0]
        gap = speech[i][0] - speech[i - 1][1]
        if dur <= max_marker and gap >= min_gap:
            markers.append((gap, i))
    need = n_groups - 1 if n_examples > 0 else n_groups
    if len(markers) < need or need <= 0:
        return split_largest_gaps(speech, n_groups, total)
    starts = sorted(i for _, i in sorted(markers, reverse=True)[:need])
    if n_examples > 0:
        starts = [0] + starts
    groups = []
    for k, st in enumerate(starts):
        end = (starts[k + 1] - 1) if k + 1 < len(starts) else len(speech) - 1
        groups.append([speech[st][0], speech[end][1]])
    return _pad(groups, total)


def _cv(groups):
    d = [e - s for s, e in groups]
    m = sum(d) / len(d)
    return (sum((x - m) ** 2 for x in d) / len(d)) ** 0.5 / m if m > 0 else 9.0


def best_mondai_split(speech, n_examples, n_questions, total):
    """Coba metode penanda nomor & jeda terpanjang; pilih yang durasi kelompoknya paling seragam.
    Bila selisih keseragaman kecil (< 0.05), metode penanda diutamakan."""
    a = split_mondai(speech, n_examples, n_questions, total)
    b = split_largest_gaps(speech, n_examples + n_questions, total)
    return a if _cv(a) <= _cv(b) + 0.05 else b

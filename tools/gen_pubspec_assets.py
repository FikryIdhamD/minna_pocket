"""
gen_pubspec_assets.py — menulis ulang daftar folder aset buku di pubspec.yaml.
Flutter tidak membaca subfolder secara rekursif, jadi setiap folder yang berisi file didaftarkan,
dengan "flavors" agar APK book1 hanya membawa assets/book1 (dan sebaliknya).

Pemakaian (dari folder proyek):  python3 tools/gen_pubspec_assets.py
Jalankan setiap kali ada folder aset baru (bab baru, gambar baru).
"""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
START, END = '# >>> ASSETS (dibuat otomatis — jangan diubah)', '# <<< ASSETS'


def main():
    lines = []
    for book in ('book1', 'book2'):
        base = os.path.join(ROOT, 'assets', book)
        if not os.path.isdir(base):
            continue
        dirs = []
        for d, _, files in os.walk(base):
            if any(not f.startswith('.') for f in files):
                dirs.append(d)
        # folder audio selalu didaftarkan bila data audio buku ada (file audio besar tidak ikut paket data)
        audio = os.path.join(base, 'audio')
        if os.path.exists(os.path.join(ROOT, 'content-src', book, 'audio_raw.json')) and audio not in dirs:
            dirs.append(audio)
        for d in sorted(dirs):
            if True:
                rel = os.path.relpath(d, ROOT).replace(os.sep, '/') + '/'
                lines.append(f'    - path: {rel}\n      flavors:\n        - {book}')
    p = os.path.join(ROOT, 'pubspec.yaml')
    s = open(p, encoding='utf-8').read()
    a = s.index(START)
    b = s.index(END, a)
    s = s[:a] + START + '\n' + '\n'.join(lines) + '\n' + s[b:]
    open(p, 'w', encoding='utf-8', newline='\n').write(s)
    print(f'{len(lines)} folder aset didaftarkan')


if __name__ == '__main__':
    main()

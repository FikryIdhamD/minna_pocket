"""
crop_images.py — memotong gambar dari PDF scan sesuai content-src/<book>/crops.json.

Format crops.json:
  [ {"out": "img/L01/kaiwa.webp", "pdf": "main", "page": 30, "box": [x0, y0, x1, y1]}, ... ]
  - pdf  : "main" | "translation" | "workbook"  (path PDF diatur di PDF_PATHS / argumen)
  - page : nomor halaman PDF (mulai 1)
  - box  : pecahan lebar/tinggi halaman (0..1)
  - trim : (opsional) true → buang tepi putih di sekeliling isi setelah dipotong
  - white: (opsional) ambang pemutihan latar 0..255 (default 215; turunkan untuk scan berbintik)

Pemakaian:
  python3 tools/crop_images.py book1 <main.pdf> <translation.pdf> <workbook.pdf>
Hasil: assets/<book>/<out>, WebP lossless grayscale (atau berwarna bila "color": true), lebar maks 900 px, latar diputihkan.
"""
import json
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageOps

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
DPI = 200
MAX_W = 900


def render(pdf, page, cache, color=False):
    key = (pdf, page, color)
    if key not in cache:
        tmp = tempfile.mktemp()
        mode = [] if color else ['-gray']
        subprocess.run(['pdftoppm', '-r', str(DPI), '-f', str(page), '-l', str(page), *mode,
                        '-png', '-singlefile', pdf, tmp], check=True, stderr=subprocess.DEVNULL)
        cache[key] = Image.open(tmp + '.png').convert('RGB' if color else 'L')
    return cache[key]


def main(book, main_pdf, tr_pdf, wb_pdf):
    pdfs = {'main': main_pdf, 'translation': tr_pdf, 'workbook': wb_pdf}
    spec = json.load(open(os.path.join(ROOT, 'content-src', book, 'crops.json'), encoding='utf-8'))
    cache = {}
    for c in spec:
        color = bool(c.get('color'))  # True: pertahankan warna (mis. tas merah yang jadi isi soal)
        im = render(pdfs[c['pdf']], c['page'], cache, color)
        w, h = im.size
        x0, y0, x1, y1 = c['box']
        crop = im.crop((int(x0 * w), int(y0 * h), int(x1 * w), int(y1 * h)))
        gray = crop.convert('L')
        if c.get('trim'):
            inv = ImageOps.invert(gray.point(lambda p: 255 if p > 200 else 0))
            bb = inv.getbbox()
            if bb:
                pad = 6
                crop = crop.crop((max(0, bb[0] - pad), max(0, bb[1] - pad),
                                  min(crop.width, bb[2] + pad), min(crop.height, bb[3] + pad)))
        wt = c.get('white', 215)
        if color:
            # latar kertas (abu/krem terang) diputihkan; piksel berwarna dibiarkan
            px = crop.load()
            for yy in range(crop.height):
                for xx in range(crop.width):
                    r, g, b = px[xx, yy]
                    if min(r, g, b) > wt and max(r, g, b) - min(r, g, b) < 40:
                        px[xx, yy] = (255, 255, 255)
        else:
            crop = ImageOps.autocontrast(crop, cutoff=1)
            crop = crop.point(lambda p, wt=wt: 255 if p > wt else p)
        if crop.width > MAX_W:
            crop = crop.resize((MAX_W, round(crop.height * MAX_W / crop.width)), Image.LANCZOS)
        out = os.path.join(ROOT, 'assets', book, c['out'])
        os.makedirs(os.path.dirname(out), exist_ok=True)
        crop.save(out, 'WEBP', lossless=True, method=6)
        print(c['out'], crop.size, os.path.getsize(out))


if __name__ == '__main__':
    main(*sys.argv[1:5])

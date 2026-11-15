"""
make_kana.py — membuat assets/<book>/extras/kana.json dari tabel はじめに (buku utama hlm. PDF 21-22).
Susunan baris & sel kosong mengikuti tabel di buku. Romaji dari tools/jptext.kana_to_romaji (Hepburn).
Pemakaian: python3 tools/make_kana.py book1
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
from jptext import kana_to_romaji

SEION = ["あいうえお","かきくけこ","さしすせそ","たちつてと","なにぬねの","はひふへほ","まみむめも",
         "や_ゆ_よ","らりるれろ","わ___を","ん____"]
DAKUON = ["がぎぐげご","ざじずぜぞ","だぢづでど","ばびぶべぼ","ぱぴぷぺぽ"]
YOUON = ["きゃ きゅ きょ","しゃ しゅ しょ","ちゃ ちゅ ちょ","にゃ にゅ にょ","ひゃ ひゅ ひょ","みゃ みゅ みょ","りゃ りゅ りょ"]
YOUON_D = ["ぎゃ ぎゅ ぎょ","じゃ じゅ じょ","びゃ びゅ びょ","ぴゃ ぴゅ ぴょ"]

def h2k(s): return ''.join(chr(ord(c)+0x60) if 'ぁ'<=c<='ゖ' else c for c in s)

def table(id_, title, rows, kata):
    out=[]
    for r in rows:
        cells = r.split(' ') if ' ' in r else list(r)
        row=[]
        for c in cells:
            if c=='_': row.append(None); continue
            k=h2k(c) if kata else c
            row.append({"kana":k,"ro":kana_to_romaji(c)})
        out.append(row)
    return {"id":id_,"title":title,"rows":out}

def chart(kata):
    return [table("seion","Huruf dasar",SEION,kata),table("dakuon","Huruf bertitik (dakuon/handakuon)",DAKUON,kata),
            table("youon","Bunyi gabungan (youon)",YOUON,kata),table("youon_dakuon","Bunyi gabungan bertitik",YOUON_D,kata)]

book=sys.argv[1] if len(sys.argv)>1 else 'book1'
root=os.path.abspath(os.path.join(os.path.dirname(__file__),'..'))
out=os.path.join(root,'assets',book,'extras','kana.json')
os.makedirs(os.path.dirname(out),exist_ok=True)
json.dump({"source_pdf_page":21,"hiragana":chart(False),"katakana":chart(True)},open(out,'w',encoding='utf-8'),ensure_ascii=False,indent=1)
print('ok', out)

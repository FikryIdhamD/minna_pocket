"""
audio_prepare.py — kompres MP3 CD menjadi AAC mono dan deteksi bagian bersuara.

Pemakaian:
  python3 tools/audio_prepare.py <folder_mp3_cd> <folder_output_audio> <file_output_json>

- Nama file CD: "NN Dai X Ka - Kaiwa.mp3" / "NN Dai X Ka - Mondai Y.mp3"
- Output audio: L01_kaiwa.m4a, L01_mondai1.m4a, ... (AAC mono 64 kbps)
- Output JSON: {"L01_kaiwa": {"duration": 23.95, "speech": [[start, end], ...]}, ...}
  "speech" = interval bersuara (komplemen dari jeda >= 0.35 dtk pada -35 dB).
"""
import json
import os
import re
import subprocess
import sys

NAME_RE = re.compile(r"^(\d+) Dai (\d+) Ka - (Kaiwa|Mondai (\d+))\.mp3$")


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                          "-of", "csv=p=0", path], capture_output=True, text=True).stdout
    return float(out.strip())


def speech_intervals(path, total):
    err = subprocess.run(["ffmpeg", "-hide_banner", "-i", path, "-af",
                          "silencedetect=noise=-35dB:d=0.35", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    starts = [float(x) for x in re.findall(r"silence_start: ([\d.]+)", err)]
    ends = [float(x) for x in re.findall(r"silence_end: ([\d.]+)", err)]
    silences = list(zip(starts, ends + [total] * (len(starts) - len(ends))))
    speech, cur = [], 0.0
    for s, e in silences:
        if s - cur > 0.05:
            speech.append([round(cur, 3), round(s, 3)])
        cur = e
    if total - cur > 0.05:
        speech.append([round(cur, 3), round(total, 3)])
    return speech


def main(src, out_dir, out_json):
    os.makedirs(out_dir, exist_ok=True)
    result = {}
    for name in sorted(os.listdir(src)):
        m = NAME_RE.match(name)
        if not m:
            continue
        lesson = int(m.group(2))
        key = f"L{lesson:02d}_kaiwa" if m.group(3) == "Kaiwa" else f"L{lesson:02d}_mondai{int(m.group(4))}"
        path = os.path.join(src, name)
        target = os.path.join(out_dir, key + ".m4a")
        if not os.path.exists(target):
            subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", path,
                            "-ac", "1", "-c:a", "aac", "-b:a", "64k", target], check=True)
        total = duration(path)
        result[key] = {"cd_file": name, "cd_track": int(m.group(1)), "duration": round(total, 3),
                       "speech": speech_intervals(path, total)}
        print(key, round(total, 1), len(result[key]["speech"]))
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main(*sys.argv[1:4])

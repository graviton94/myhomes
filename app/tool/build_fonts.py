#!/usr/bin/env python3
"""Builds the bundled fonts in app/assets/fonts from Google Fonts sources.

Variable fonts are cut into the static weights the app uses, then subset:
Latin for all faces, plus the 2,350 common Hangul syllables (KS X 1001) and
Hangul jamo for the Korean faces, so user-typed Korean names render in the
bundled font too.

  python3 tool/build_fonts.py          download sources, write assets/fonts
  python3 tool/build_fonts.py --check  every character in the ARB files is
                                       covered (no download; for CI)
"""
import io
import json
import pathlib
import sys
import urllib.request

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

APP = pathlib.Path(__file__).resolve().parent.parent
OUT = APP / "assets" / "fonts"
CACHE = pathlib.Path("/tmp/homefairy-font-src")
RAW = "https://raw.githubusercontent.com/google/fonts/main/ofl/"

# (output file, source path under ofl/, axis values or None, korean?)
FACES = [
    ("Fredoka-Medium.ttf", "fredoka/Fredoka%5Bwdth,wght%5D.ttf", {"wght": 500, "wdth": 100}, False),
    ("Fredoka-SemiBold.ttf", "fredoka/Fredoka%5Bwdth,wght%5D.ttf", {"wght": 600, "wdth": 100}, False),
    ("Nunito-Regular.ttf", "nunito/Nunito%5Bwght%5D.ttf", {"wght": 400}, False),
    ("Nunito-SemiBold.ttf", "nunito/Nunito%5Bwght%5D.ttf", {"wght": 600}, False),
    ("Nunito-Bold.ttf", "nunito/Nunito%5Bwght%5D.ttf", {"wght": 700}, False),
    ("Jua-Regular.ttf", "jua/Jua-Regular.ttf", None, True),
    ("NotoSansKR-Regular.ttf", "notosanskr/NotoSansKR%5Bwght%5D.ttf", {"wght": 400}, True),
    ("NotoSansKR-Bold.ttf", "notosanskr/NotoSansKR%5Bwght%5D.ttf", {"wght": 700}, True),
    ("IBMPlexMono-Medium.ttf", "ibmplexmono/IBMPlexMono-Medium.ttf", None, False),
]

KOREAN_FILES = ["Jua-Regular.ttf", "NotoSansKR-Regular.ttf", "NotoSansKR-Bold.ttf"]


def latin() -> set[int]:
    cps = set(range(0x20, 0x7F)) | set(range(0xA0, 0x180))
    cps |= {0x2013, 0x2014, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2026, 0x203A,
            0x2039, 0x2190, 0x2192, 0x2194, 0x21C4, 0x2212, 0x00D7, 0x2713, 0x2715, 0x20A9}
    return cps


def ksx1001_hangul() -> set[int]:
    cps = set()
    for lead in range(0xB0, 0xC9):
        for trail in range(0xA1, 0xFF):
            try:
                cps.add(ord(bytes([lead, trail]).decode("euc-kr")))
            except UnicodeDecodeError:
                pass
    return cps


def korean() -> set[int]:
    jamo = set(range(0x3131, 0x318F))
    punct = {0x3001, 0x3002, 0x300C, 0x300D, 0x300E, 0x300F, 0x3008, 0x3009, 0xFF5E}
    return ksx1001_hangul() | jamo | punct


def arb_chars() -> set[int]:
    cps = set()
    for f in (APP / "lib" / "l10n").glob("app_*.arb"):
        data = json.loads(f.read_text(encoding="utf-8"))
        for k, v in data.items():
            if not k.startswith("@") and isinstance(v, str):
                cps |= {ord(c) for c in v}
    return cps


def source(path: str) -> bytes:
    CACHE.mkdir(parents=True, exist_ok=True)
    local = CACHE / path.replace("/", "_")
    if not local.exists():
        print("download", path)
        local.write_bytes(urllib.request.urlopen(RAW + path, timeout=120).read())
    return local.read_bytes()


def build() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for out, path, axes, is_korean in FACES:
        font = TTFont(io.BytesIO(source(path)))
        if axes:
            font = instancer.instantiateVariableFont(font, axes)
        cps = latin() | (korean() if is_korean else set())
        options = subset.Options()
        options.layout_features = ["*"]
        options.name_IDs = ["*"]
        options.notdef_outline = True
        sub = subset.Subsetter(options)
        sub.populate(unicodes=sorted(cps))
        sub.subset(font)
        font.save(OUT / out)
        print(f"{out}: {(OUT / out).stat().st_size // 1024} KB")


def check() -> None:
    needed = {c for c in arb_chars() if c > 0x20}
    problems = []
    for name in KOREAN_FILES + ["Nunito-Regular.ttf"]:
        path = OUT / name
        if not path.exists():
            problems.append(f"missing {path}")
            continue
        cmap = TTFont(path).getBestCmap()
        if name in KOREAN_FILES:
            missing = [chr(c) for c in needed if c not in cmap and c >= 0x1100]
        else:
            missing = [chr(c) for c in needed if c not in cmap and c < 0x1100]
        if missing:
            problems.append(f"{name} lacks: {''.join(sorted(missing))}")
    if problems:
        print("\n".join(problems))
        print("Run: python3 tool/build_fonts.py")
        sys.exit(1)
    print("Fonts cover every character in the ARB files.")


if __name__ == "__main__":
    check() if "--check" in sys.argv else build()

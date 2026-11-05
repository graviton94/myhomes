"""Turns the public recipe DB (식품안전나라 COOKRCP01, tool/data/COOKRCP01.csv,
식품의약품안전처) into assets/recipes.json for the app: name, kind, way,
kcal, main photo, ingredients (name as written + a plain name for matching,
and whether it is a pantry staple) and steps.

    python3 tool/build_recipes.py          # build
    python3 tool/build_recipes.py --check  # fail if the output is stale
"""
import csv
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'tool', 'data', 'COOKRCP01.csv')
OUT = os.path.join(ROOT, 'assets', 'recipes.json')

# Words that start a section of the list ("양념 다진 마늘(15g)") rather than name a thing.
HEADERS = ('주재료', '부재료', '재료', '양념장', '양념', '소스', '육수', '고명', '드레싱', '반죽', '토핑', '곁들임채소', '곁들임', '속재료', '튀김옷', '장식')
# Things most kitchens have: they never count as missing.
STAPLES = {
    '소금', '천일염', '꽃소금', '설탕', '흑설탕', '후추', '후춧가루', '백후춧가루', '통후추', '간장', '국간장', '진간장', '저염간장', '양조간장',
    '식용유', '현미유', '포도씨유', '카놀라유', '올리브유', '올리브오일', '튀김기름', '물', '생수', '참기름', '들기름', '깨', '참깨', '통깨', '깨소금',
    '식초', '올리고당', '물엿', '조청', '맛술', '청주', '정종', '미림', '고춧가루', '고추장', '된장', '다진마늘', '다진 마늘', '마늘', '육수', '멸치육수',
    '흰후추', '맛간장', '밀가루', '전분', '감자전분', '녹말가루', '부침가루', '버터', '무염버터', '케첩', '마요네즈', '굴소스', '매실액', '매실청', '얼음', '꿀',
}
# Modifiers dropped for the plain name ("다진 파" → "파", "무염버터" → "버터").
MODIFIERS = ('다진', '저염', '무염', '손질된', '손질한', '데친', '삶은', '냉동', '건', '말린', '깐', '채썬', '채 썬', '슬라이스')
SYNONYMS = {'달걀': '계란', '쪽파': '파', '대파': '파', '실파': '파', '청양고추': '고추', '풋고추': '고추', '홍고추': '고추', '붉은 고추': '고추',
            '닭다릿살': '닭다리', '청고추': '고추', '국멸치': '멸치', '흰후추': '후추', '돼지고기 앞다리살': '돼지고기', '쇠고기': '소고기', '우육': '소고기', '흰쌀밥': '밥', '쌀밥': '밥', '현미밥': '밥'}
QTY = re.compile(r'\s*[\(\[]|\s*\d|\s*(약간|조금|적당량|적당히|한줌|한 줌|소량|약간씩)|\s*[½⅓¼⅔¾]')


def plain(name: str) -> str:
    n = re.sub(r'\s*다진\s*것$', '', name.strip())
    for a, b in SYNONYMS.items():
        if n == a:
            return b
    for m in MODIFIERS:
        if n.startswith(m) and len(n) > len(m) + 1:
            n = n[len(m):].strip()
    return SYNONYMS.get(n, n).replace(' ', '')


def ingredients(text: str, dish: str) -> list[dict]:
    out, seen = [], set()
    dish_key = dish.replace(' ', '')
    for line in text.replace('\r', '').split('\n'):
        line = re.sub(r'\[[^\]]*\]', ' ', line)              # [ 2인분 ]
        line = re.sub(r'[●○■□◆◇▶•·\-]\s*[^:：,]{0,12}[:：]', ',', line)  # ●주재료 : / - 소스 :
        line = re.sub(r'^[^,(:：]{0,12}[:：]', '', line)       # 양념 : ...
        for piece in re.split(r'[,，、/]', line):
            piece = re.sub(r'</?\w+>?', ' ', piece)  # stray HTML ("strong>")
            piece = re.split(r'[>:：]', piece)[-1]     # "초콜릿 > 카카오매스", "초고추장:고추장"
            piece = re.sub(r'[①-⑳]', '', piece).strip().strip('-•·●').strip()
            if not piece:
                continue
            m = QTY.search(piece)
            name = (piece[:m.start()] if m else piece).strip()
            words = name.split()
            if len(words) >= 2 and any(words[0].endswith(h) for h in HEADERS):
                name = ' '.join(words[1:])
            if not name or name in HEADERS or '때' in name or name.endswith('용') or name.replace(' ', '') == dish_key or len(name) > 14 or not re.search('[가-힣A-Za-z]', name):
                continue
            key = plain(name)
            if key in seen:
                continue
            seen.add(key)
            out.append({'n': name, 'k': key, 's': key in {plain(s) for s in STAPLES} or name in STAPLES})
    return out


def steps(row: dict) -> list[str]:
    out = []
    for i in range(1, 21):
        s = (row.get(f'MANUAL{i:02d}') or '').strip()
        if not s:
            continue
        s = re.sub(r'^\d+\.\s*', '', s)
        s = re.sub(r'[a-z]$', '', s).strip()  # the source ends steps with a stray letter
        out.append(s)
    return out


def build() -> str:
    rows = list(csv.DictReader(open(SRC, encoding='utf-8-sig')))
    recipes = []
    for r in rows:
        ing = ingredients(r['RCP_PARTS_DTLS'] or '', r['RCP_NM'] or '')
        st = steps(r)
        if not ing or not st:
            continue
        photo = (r['ATT_FILE_NO_MAIN'] or '').strip().replace('http://', 'https://')
        recipes.append({
            'id': int(r['RCP_SEQ']),
            'name': r['RCP_NM'].strip(),
            'kind': r['RCP_PAT2'].strip(),
            'way': r['RCP_WAY2'].strip(),
            'kcal': int(float(r['INFO_ENG'])) if (r['INFO_ENG'] or '').replace('.', '').isdigit() else None,
            'photo': photo or None,
            'ing': ing,
            'steps': st,
            'tip': (r['RCP_NA_TIP'] or '').strip() or None,
        })
    recipes.sort(key=lambda x: x['id'])
    return json.dumps({'source': '식품의약품안전처 식품안전나라 조리식품의 레시피 DB (COOKRCP01)', 'recipes': recipes},
                      ensure_ascii=False, separators=(',', ':')) + '\n'


if __name__ == '__main__':
    data = build()
    if '--check' in sys.argv:
        if not os.path.exists(OUT) or open(OUT, encoding='utf-8').read() != data:
            sys.exit('assets/recipes.json is out of date. Run: python3 tool/build_recipes.py')
        print('recipes.json is up to date.')
    else:
        open(OUT, 'w', encoding='utf-8').write(data)
        print(f'Wrote {len(json.loads(data)["recipes"])} recipes, {len(data) // 1024} KB')

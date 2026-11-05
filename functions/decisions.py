"""Decisions asked of the TypeSafe System One model (Jev).

Shared by the Cloud Function (main.py) and the evaluation script
(app/tool/jev_eval.py), so the scores measured are the ones users get.
Only typed choices come back; nothing here generates text.
"""
import json
import os

from typesafe_sdk import Choice, Noul

_ICONS = json.load(open(os.path.join(os.path.dirname(__file__), 'icons.json'), encoding='utf-8'))

CATEGORIES = {
    'food': '식품 · 음료 · 조미료',
    'household': '생활용품 · 세제 · 휴지 · 화장품 · 침구 · 전구 · 건전지',
    'tools': '공구 · 테이프 · 접착제 · 열쇠',
    'medicine': '약 · 영양제 · 의료용품',
    'clothes': '옷 · 신발 · 가방 · 모자 · 안경 · 장신구',
    'electronics': '전자기기 · 휴대폰 · 컴퓨터 · 게임기 · 이어폰',
    'papers': '서류 · 책 · 문구 · 카드 · 돈 · 티켓',
    'hobby': '운동 · 캠핑 · 여행 · 악기 · 미술 · 식물 · 명절 장식',
    'kids': '아기 · 아이 용품 · 장난감',
    'pets': '반려동물 용품 · 사료',
    'other': '그 밖의 것',
}

MAX_FIND_OPTIONS = 400


def _answer(a):
    top = sorted(a.probabilities.items(), key=lambda kv: -kv[1])[:3]
    # Maps, not pairs: Firestore (the classify cache) cannot store nested lists.
    return {'choice': a.choice, 'confidence': round(a.confidence, 3), 'top': [{'choice': k, 'p': round(v, 3)} for k, v in top]}


async def classify(client, name: str, model: str | None = None) -> dict:
    """Category and icon in one request. (Choosing the icon only within the
    guessed category's groups was tried and scored lower: a wrong category
    hides the right icon.)"""
    name = name.strip()[:80]
    r = await client.system_one(
        f'물건 이름: {name}',
        {
            'category': Choice(instructions='이 집안 물건은 어떤 종류인가요?', criteria=CATEGORIES),
            'icon': Choice(
                instructions='이 물건을 가장 잘 나타내는 아이콘은? (아이콘 이름은 영어, 괄호는 묶음)',
                criteria={k: f'({g})' for g, ks in _ICONS.items() for k in ks},
            ),
        },
        model=model,
    )
    return {'category': _answer(r.choices['category']), 'icon': _answer(r.choices['icon'])}


async def find(client, query: str, items: list[str], model: str | None = None) -> dict:
    """Which of the home's items a "where is it?" question means, and whether
    it means any of them at all (a Choice always picks one, so the Noul tells
    code when nothing fits)."""
    names = list(dict.fromkeys(n.strip()[:80] for n in items if n and n.strip()))[:MAX_FIND_OPTIONS]
    if not names:
        return {'item': None, 'mentions': None}
    r = await client.system_one(
        # The list is in the state so the Noul can see it too (questions
        # cannot see each other's options).
        {'question': query.strip()[:120], 'home_items': names},
        {
            'item': Choice(
                instructions='`question`이 찾는 물건은 `home_items` 중 어느 것인가요? 같은 쓰임이나 다른 이름으로 불리는 물건도 맞아요.',
                criteria={n: None for n in names},
            ),
            'mentions': Noul(
                instructions='`question`은 `home_items`에 있는 물건 하나를 찾고 있다.',
                criteria={
                    'true': '목록의 물건을 이름이나 쓰임으로 말한다. 예: 목록에 타이레놀이 있을 때 "열 날 때 먹는 약"',
                    'false': '목록에 없는 물건을 찾는다. 예: 목록에 우산이 없을 때 "비 올 때 쓰는 거"',
                },
            ),
        },
        model=model,
    )
    return {'item': _answer(r.choices['item']), 'mentions': round(r.nouls['mentions'].noul, 3)}


MAX_RECEIPT_LINES = 40


async def receipt(client, lines: list[dict], model: str | None = None) -> dict:
    """For each line read off a shop receipt: is it a thing kept at home,
    which of the code's name candidates a person would write, and whether it
    refills one of the home's similar things. The model only picks; names
    come from code (select instead of generate)."""
    rows = []
    for ln in lines[:MAX_RECEIPT_LINES]:
        names = list(dict.fromkeys(str(n).strip()[:60] for n in (ln.get('names') or []) if str(n).strip()))[:6]
        like = list(dict.fromkeys(str(n).strip()[:60] for n in (ln.get('like') or []) if str(n).strip()))[:12]
        if names:
            rows.append((names, like))
    if not rows:
        return {'lines': []}
    state = {'receipt_lines': {f'l{i}': names[0] for i, (names, _) in enumerate(rows)}}
    questions = {}
    for i, (names, like) in enumerate(rows):
        questions[f'keep{i}'] = Noul(
            instructions=f'`receipt_lines.l{i}`은 집에 두고 쓰려고 산 상품이다.',
            criteria={
                'true': '식품, 생활용품, 물건처럼 집에 들여놓는 상품. 예: 햇반, 키친타월',
                'false': '합계, 할인, 봉투값, 카드나 포인트 안내 같은 상품이 아닌 줄',
            },
        )
        if len(names) > 1:
            questions[f'name{i}'] = Choice(
                instructions=f'`receipt_lines.l{i}` 상품에 집에서 붙일 이름은?',
                criteria={n: None for n in names},
            )
        if like:
            questions[f'same{i}'] = Noul(
                instructions=f'`receipt_lines.l{i}`은 우리 집에 이미 있는 이 물건들 중 하나와 같은 종류다: {", ".join(like)}',
                criteria={'true': '같은 물건을 또 산 것. 예: 집에 햇반이 있고 CJ햇반210g을 샀다',
                          'false': '이름 일부만 겹치는 다른 물건. 예: 집에 우유가 있고 우유식빵을 샀다'},
            )
            questions[f'item{i}'] = Choice(
                instructions=f'`receipt_lines.l{i}`과 가장 같은 우리 집 물건은?',
                criteria={n: None for n in like},
            )
    r = await client.system_one(state, questions, model=model)
    out = []
    for i, (names, like) in enumerate(rows):
        out.append({
            'keep': round(r.nouls[f'keep{i}'].noul, 3),
            'name': r.choices[f'name{i}'].choice if f'name{i}' in questions else names[0],
            'same': round(r.nouls[f'same{i}'].noul, 3) if like else 0.0,
            'item': r.choices[f'item{i}'].choice if like else None,
        })
    return {'lines': out}

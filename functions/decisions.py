"""Decisions asked of the TypeSafe System One model (Jev).

Shared by the Cloud Function (main.py) and the evaluation script
(app/tool/jev_eval.py), so the scores measured are the ones users get.
Only typed choices come back; nothing here generates text.
"""
import json
import os

from typesafe_sdk import Choice

_ICONS = json.load(open(os.path.join(os.path.dirname(__file__), 'icons.json'), encoding='utf-8'))

CATEGORIES = {
    'food': '식품 · 음료 · 조미료',
    'household': '생활용품 · 세제 · 휴지 · 전구 · 건전지',
    'tools': '공구 · 문구용 도구 · 열쇠',
    'medicine': '약 · 영양제 · 의료용품',
    'other': '옷 · 서류 · 전자기기 · 취미 · 반려동물 · 그 밖의 것',
}

# Icon groups to choose from once the category is known (keeps requests small).
_GROUPS_FOR = {
    'food': ['food'],
    'household': ['household', 'furniture'],
    'tools': ['tools'],
    'medicine': ['health'],
    'other': ['clothes', 'family', 'pets', 'devices', 'papers', 'hobby', 'furniture'],
}

MAX_FIND_OPTIONS = 400


def _answer(a):
    top = sorted(a.probabilities.items(), key=lambda kv: -kv[1])[:3]
    return {'choice': a.choice, 'confidence': round(a.confidence, 3), 'top': [[k, round(v, 3)] for k, v in top]}


async def classify(client, name: str, model: str | None = None) -> dict:
    """Category, then the icon within that category's groups."""
    name = name.strip()[:80]
    first = await client.system_one(
        f'물건 이름: {name}',
        {'category': Choice(instructions='이 집안 물건은 어떤 종류인가요?', criteria=CATEGORIES)},
        model=model,
    )
    cat = first.choices['category']
    icons = [k for g in _GROUPS_FOR[cat.choice] for k in _ICONS.get(g, [])]
    second = await client.system_one(
        f'물건 이름: {name}',
        {
            'icon': Choice(
                instructions='이 물건을 가장 잘 나타내는 아이콘은? (아이콘 이름은 영어)',
                criteria={k: None for k in icons},
            )
        },
        model=model,
    )
    return {'category': _answer(cat), 'icon': _answer(second.choices['icon'])}


async def find(client, query: str, items: list[str], model: str | None = None) -> dict:
    """Which of the home's items a "where is it?" question means."""
    names = list(dict.fromkeys(n.strip()[:80] for n in items if n and n.strip()))[:MAX_FIND_OPTIONS]
    if not names:
        return {'item': None}
    r = await client.system_one(
        f'"그거 어디 있어?" 질문: {query.strip()[:120]}',
        {
            'item': Choice(
                instructions='이 질문이 찾는 물건은 우리 집 물건 중 어느 것인가요? 같은 쓰임이나 다른 이름으로 불리는 물건도 맞아요.',
                criteria={n: None for n in names},
            )
        },
        model=model,
    )
    return {'item': _answer(r.choices['item'])}

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

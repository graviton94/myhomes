"""Scores the TypeSafe decision model (Jev) against the rules on eval/ sets.

Run in CI (.github/workflows/jev-eval.yml) with TYPESAFE_API_KEY set:
    python3 tool/jev_eval.py rules.json [model ...]
Prints a markdown report. Only item names from the evaluation set are sent.
"""
import asyncio
import json
import os
import sys
import time

from typesafe_sdk import AsyncTypeSafeClient, Choice

CORE = os.path.join(os.path.dirname(__file__), '..', 'packages', 'core')
CLASSIFY = [json.loads(l) for l in open(os.path.join(CORE, 'eval', 'classify.jsonl'), encoding='utf-8') if l.strip()]
FIND = json.load(open(os.path.join(CORE, 'eval', 'find.json'), encoding='utf-8'))
ICONS_DART = open(os.path.join(CORE, 'lib', 'src', 'icons.dart'), encoding='utf-8').read()

CATEGORIES = {
    'food': '식품 · 음료 · 조미료',
    'household': '생활용품 · 세제 · 휴지 · 전구 · 건전지',
    'tools': '공구 · 문구용 도구 · 열쇠',
    'medicine': '약 · 영양제 · 의료용품',
    'other': '옷 · 서류 · 전자기기 · 취미 · 반려동물 · 그 밖의 것',
}


def icon_keys():
    # Group order and keys from core's iconGroups, so the choice list matches the app.
    start = ICONS_DART.index('const Map<String, List<String>> iconGroups')
    body = ICONS_DART[start:ICONS_DART.index('};', start)]
    groups, keys, current = {}, [], None
    for raw in body.splitlines():
        line = raw.strip()
        if line.startswith("'") and ("': [" in line):
            current = line.split("'")[1]
            line = line.split('[', 1)[1]
        if current is None:
            continue
        for part in line.replace(']', '').replace('//', '').split(','):
            k = part.strip().strip("'")
            if k and k.replace('_', '').isalnum():
                groups.setdefault(current, []).append(k)
                keys.append(k)
    return keys, {k: g for g, ks in groups.items() for k in ks}


KEYS, GROUP_OF = icon_keys()


async def ask(client, sem, state, questions, model):
    async with sem:
        t = time.perf_counter()
        try:
            r = await client.system_one(state, questions, model=model)
            return r, time.perf_counter() - t, None
        except Exception as e:  # report and keep going
            return None, time.perf_counter() - t, f'{type(e).__name__}: {str(e)[:200]}'


def pct(a, b):
    return f'{a}/{b} ({100 * a / b:.0f}%)' if b else '-'


async def run(model, rules):
    sem = asyncio.Semaphore(8)
    async with AsyncTypeSafeClient(model=model) as client:
        cls_q = {
            'category': Choice(instructions='이 집안 물건은 어떤 종류인가요?', criteria=CATEGORIES),
            'icon': Choice(
                instructions='이 물건을 가장 잘 나타내는 아이콘은? (아이콘 이름은 영어, 괄호는 묶음)',
                criteria={k: f'({GROUP_OF[k]})' for k in KEYS},
            ),
        }
        cls = await asyncio.gather(*[ask(client, sem, f'물건 이름: {c["name"]}', cls_q, model) for c in CLASSIFY])
        home = FIND['home']
        find_q = {
            'item': Choice(
                instructions='이 질문이 찾는 물건은 우리 집 물건 중 어느 것인가요? 같은 쓰임이나 다른 이름으로 불리는 물건도 맞아요.',
                criteria={n: None for n in home},
            )
        }
        fnd = await asyncio.gather(*[ask(client, sem, f'"그거 어디 있어?" 질문: {q["query"]}', find_q, model) for q in FIND['questions']])

    out = [f'## {model}', '']
    errors = [e for _, _, e in cls + fnd if e]
    if errors:
        out += [f'- errors: {len(errors)} (first: `{errors[0]}`)', '']

    def stats(rows, gold_ok, rule_pred, rule_ok):
        ok = hi = hi_ok = combo = 0
        for (r, _, _), g, rp, ro in zip(rows, gold_ok, rule_pred, rule_ok):
            if r is None:
                combo += ro
                continue
            pick, conf, good = g(r)
            ok += good
            if conf >= 0.7:
                hi += 1
                hi_ok += good
            combo += ro if rp is not None else good
        return ok, hi, hi_ok, combo

    n = len(CLASSIFY)
    rc = rules['classify']
    cat = stats(
        cls,
        [lambda r, c=c: (r.choices['category'].choice, r.choices['category'].confidence, r.choices['category'].choice == c['category']) for c in CLASSIFY],
        [p['category'] for p in rc],
        [p['category'] == c['category'] for p, c in zip(rc, CLASSIFY)],
    )
    ico = stats(
        cls,
        [lambda r, c=c: (r.choices['icon'].choice, r.choices['icon'].confidence, r.choices['icon'].choice in c['icons']) for c in CLASSIFY],
        [p['icon'] for p in rc],
        [p['icon'] in c['icons'] for p, c in zip(rc, CLASSIFY)],
    )
    qs = FIND['questions']
    rf = rules['find']
    fd = stats(
        fnd,
        [lambda r, q=q: (r.choices['item'].choice, r.choices['item'].confidence, r.choices['item'].choice == q['answer']) for q in qs],
        [p['answer'] for p in rf],
        [p['answer'] == q['answer'] for p, q in zip(rf, qs)],
    )
    rules_cat = sum(p['category'] == c['category'] for p, c in zip(rc, CLASSIFY))
    rules_ico = sum(p['icon'] in c['icons'] for p, c in zip(rc, CLASSIFY))
    rules_fd = sum(p['answer'] == q['answer'] for p, q in zip(rf, qs))
    out += [
        '| task | rules | model | model, confidence ≥ 0.7 (accuracy · share) | rules first, then model |',
        '|---|---|---|---|---|',
        f'| category | {pct(rules_cat, n)} | {pct(cat[0], n)} | {pct(cat[2], cat[1])} · {pct(cat[1], n)} | {pct(cat[3], n)} |',
        f'| icon ({len(KEYS)} options) | {pct(rules_ico, n)} | {pct(ico[0], n)} | {pct(ico[2], ico[1])} · {pct(ico[1], n)} | {pct(ico[3], n)} |',
        f'| find ({len(FIND["home"])} items) | {pct(rules_fd, len(qs))} | {pct(fd[0], len(qs))} | {pct(fd[2], fd[1])} · {pct(fd[1], len(qs))} | {pct(fd[3], len(qs))} |',
        '',
    ]
    lat = sorted(t for _, t, e in cls + fnd if not e)
    toks = [r.usage.input_tokens or 0 for r, _, _ in cls + fnd if r is not None and r.usage]
    if lat:
        out.append(f'- latency: median {lat[len(lat) // 2] * 1000:.0f} ms, p90 {lat[int(len(lat) * 0.9)] * 1000:.0f} ms (8 in parallel, from GitHub runner)')
    if toks:
        out.append(f'- input tokens: classify ~{sum(toks[:len(cls)]) // max(1, len(cls))}/request, find ~{sum(toks[len(cls):]) // max(1, len(fnd))}/request, total {sum(toks)}')
    misses = [
        f'{c["name"]} → {r.choices["icon"].choice} ({r.choices["icon"].confidence:.2f})'
        for (r, _, _), c in zip(cls, CLASSIFY)
        if r is not None and r.choices['icon'].choice not in c['icons']
    ][:20]
    if misses:
        out += ['', '<details><summary>icon misses (first 20)</summary>', '', *[f'- {m}' for m in misses], '', '</details>']
    fmiss = [
        f'{q["query"]} → {r.choices["item"].choice} ({r.choices["item"].confidence:.2f}), want {q["answer"]}'
        for (r, _, _), q in zip(fnd, qs)
        if r is not None and r.choices['item'].choice != q['answer']
    ]
    if fmiss:
        out += ['', '<details><summary>find misses</summary>', '', *[f'- {m}' for m in fmiss], '', '</details>']
    return '\n'.join(out)


async def main():
    rules = json.load(open(sys.argv[1], encoding='utf-8'))
    models = sys.argv[2:] or ['jev-latest']
    print(f'# Jev evaluation — {len(CLASSIFY)} names, {len(FIND["questions"])} questions\n')
    for m in models:
        print(await run(m, rules))
        print()


asyncio.run(main())

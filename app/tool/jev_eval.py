"""Scores the TypeSafe decision model (Jev) against the rules on the
evaluation sets in app/packages/core/eval, using the same decision code the
Cloud Function runs (functions/decisions.py).

Run in CI (.github/workflows/jev-eval.yml) with TYPESAFE_API_KEY set:
    python3 tool/jev_eval.py rules.json [model ...]
Prints a markdown report. Only item names from the evaluation set are sent.
"""
import asyncio
import json
import os
import sys
import time

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
sys.path.insert(0, os.path.join(ROOT, 'functions'))

from typesafe_sdk import AsyncTypeSafeClient  # noqa: E402

import decisions  # noqa: E402

EVAL = os.path.join(ROOT, 'app', 'packages', 'core', 'eval')
CLASSIFY = [json.loads(l) for l in open(os.path.join(EVAL, 'classify.jsonl'), encoding='utf-8') if l.strip()]
FIND = json.load(open(os.path.join(EVAL, 'find.json'), encoding='utf-8'))
BIG_HOME = FIND['home'] + [c['name'] for c in CLASSIFY]


async def timed(sem, coro):
    async with sem:
        t = time.perf_counter()
        try:
            return await coro, time.perf_counter() - t, None
        except Exception as e:  # report and keep going
            return None, time.perf_counter() - t, f'{type(e).__name__}: {str(e)[:200]}'


def pct(a, b):
    return f'{a}/{b} ({100 * a / b:.0f}%)' if b else '-'


def row(label, rule_ok, results, ok_of, conf_of):
    n = len(results)
    got = [r for r, _, _ in results]
    ok = sum(ok_of(i, r) for i, r in enumerate(got) if r)
    hi = [(i, r) for i, r in enumerate(got) if r and conf_of(r) >= 0.7]
    hi_ok = sum(ok_of(i, r) for i, r in hi)
    mid = [(i, r) for i, r in enumerate(got) if r and 0.4 <= conf_of(r) < 0.7]
    return f'| {label} | {pct(sum(rule_ok), n)} | {pct(ok, n)} | {pct(hi_ok, len(hi))} · {pct(len(hi), n)} | {pct(len(mid), n)} |'


async def run(model, rules):
    sem = asyncio.Semaphore(8)
    async with AsyncTypeSafeClient(model=model) as client:
        cls = await asyncio.gather(*[timed(sem, decisions.classify(client, c['name'], model)) for c in CLASSIFY])
        fnd = await asyncio.gather(*[timed(sem, decisions.find(client, q['query'], FIND['home'], model)) for q in FIND['questions']])
        big = await asyncio.gather(*[timed(sem, decisions.find(client, q['query'], BIG_HOME, model)) for q in FIND['questions']])

    qs = FIND['questions']
    out = [f'## {model}', '']
    errors = [e for _, _, e in cls + fnd + big if e]
    if errors:
        out += [f'- errors: {len(errors)} (first: `{errors[0]}`)', '']
    out += [
        '| task | rules | model | confidence ≥ 0.7: accuracy · share | 0.4–0.7 (show as chips) |',
        '|---|---|---|---|---|',
        row('category', [p['category'] == c['category'] for p, c in zip(rules['classify'], CLASSIFY)], cls,
            lambda i, r: r['category']['choice'] == CLASSIFY[i]['category'], lambda r: r['category']['confidence']),
        row('icon', [p['icon'] in c['icons'] for p, c in zip(rules['classify'], CLASSIFY)], cls,
            lambda i, r: r['icon']['choice'] in CLASSIFY[i]['icons'], lambda r: r['icon']['confidence']),
        row(f'find ({len(FIND["home"])} items)', [p['answer'] in q['answer'] for p, q in zip(rules['find'], qs)], fnd,
            lambda i, r: r['item']['choice'] in qs[i]['answer'], lambda r: r['item']['confidence']),
        row(f'find ({len(BIG_HOME)} items)', [p['answer'] in q['answer'] for p, q in zip(rules['findBig'], qs)], big,
            lambda i, r: r['item']['choice'] in qs[i]['answer'], lambda r: r['item']['confidence']),
        '',
    ]
    for label, rows in (('classify', cls), ('find', fnd), ('find big', big)):
        lat = sorted(t for _, t, e in rows if not e)
        if lat:
            out.append(f'- {label} latency: median {lat[len(lat) // 2] * 1000:.0f} ms, p90 {lat[int(len(lat) * 0.9)] * 1000:.0f} ms')
    top3 = sum(any(t['choice'] in c['icons'] for t in r['icon']['top']) for (r, _, _), c in zip(cls, CLASSIFY) if r)
    out.append(f'- icon right answer within the top 3 chips: {pct(top3, len(CLASSIFY))}')
    misses = [f'{c["name"]} → {r["category"]["choice"]}/{r["icon"]["choice"]} ({r["icon"]["confidence"]:.2f})'
              for (r, _, _), c in zip(cls, CLASSIFY) if r and r['icon']['choice'] not in c['icons']]
    fmiss = [f'{q["query"]} → {r["item"]["choice"]} ({r["item"]["confidence"]:.2f}), want {", ".join(q["answer"])}'
             for (r, _, _), q in zip(big, qs) if r and r['item']['choice'] not in q['answer']]
    for title, ms in (('icon misses', misses), ('find misses in the big home', fmiss)):
        if ms:
            out += ['', f'<details><summary>{title} ({len(ms)})</summary>', '', *[f'- {m}' for m in ms[:30]], '', '</details>']
    return '\n'.join(out)


async def main():
    rules = json.load(open(sys.argv[1], encoding='utf-8'))
    models = sys.argv[2:] or ['jev-latest']
    print(f'# Jev evaluation — {len(CLASSIFY)} names, {len(FIND["questions"])} questions\n')
    for m in models:
        print(await run(m, rules))
        print()


asyncio.run(main())

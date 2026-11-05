"""A handful of live Jev questions, to see real answers (not a score).

    TYPESAFE_API_KEY=... python3 tool/jev_probe.py photos/  > probe.md

Sends: the sample questions and receipt lines below, a short list of
sample item names, and the photos in the folder given (public Wikimedia
Commons pictures fetched by the workflow). Nothing from any real home.
"""
import asyncio
import json
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'functions'))
import decisions  # noqa: E402
from typesafe_sdk import AsyncTypeSafeClient, Choice, Image, Noul  # noqa: E402

HOME = ['타이레놀', '대일밴드', 'AA 건전지', '극세사 담요', '우산', '가위', '박스 테이프', '햇반', '키친타월', '우유',
        '여권', '캠핑 랜턴', '강아지 사료', '다우니 섬유유연제', '후시딘', '체온계', '노트북 충전기', 'HDMI 케이블']

QUESTIONS = ['열 날 때 먹는 약', '상처에 바르는 거', '리모컨에 넣는 거', '비 올 때 쓰는 거', '해외여행 갈 때 필요한 거',
             '정전 대비', '노트북 선', '빨래할 때 넣는 거', '덮고 자는 거', '자동차 키']

RECEIPT = ['CJ햇반210g*3', '서울우유1L', '비닐봉투', '키친타월(4롤)', '행사할인', '다우니 섬유유연제 1L', '합계', '농심 신라면 5입']


def candidates(name: str) -> list[str]:
    # The same idea as core nameCandidates, kept short here.
    import re
    out = [name]
    for s in (re.sub(r'[\(\[].*?[\)\]]', ' ', name),):
        s2 = re.sub(r'\s*\d+(\.\d+)?\s*(g|kg|ml|l|L|입|롤|개)(\s*[*xX×]\s*\d+)?', ' ', s)
        s3 = re.sub(r'^([A-Za-z]{1,6}|농심|오뚜기|롯데)\s*', '', s2.strip())
        for v in (s, s2, s3):
            v = ' '.join(v.split())
            if v and v not in out:
                out.append(v)
    return out


def like(name: str) -> list[str]:
    a = {name[i:i + 2] for i in range(len(name) - 1)}
    scored = []
    for h in HOME:
        b = {h[i:i + 2] for i in range(len(h) - 1)}
        n = len(a & b)
        if n:
            scored.append((n / len(a | b), h))
    return [h for _, h in sorted(scored, reverse=True)[:6]]


async def main() -> None:
    folder = Path(sys.argv[1]) if len(sys.argv) > 1 else None
    icons = json.load(open(os.path.join(os.path.dirname(__file__), '..', '..', 'functions', 'icons.json'), encoding='utf-8'))
    async with AsyncTypeSafeClient() as client:
        print('## 1. 찾기 (집 물건 %d개 중)\n' % len(HOME))
        print('| 질문 | 고른 물건 | 2·3위 | 우리 집 물건인가 (Noul) | ms |\n|---|---|---|---|---|')
        for q in QUESTIONS:
            t = time.time()
            r = await decisions.find(client, q, HOME)
            ms = int((time.time() - t) * 1000)
            top = ', '.join(f"{x['choice']} {x['p']:.2f}" for x in r['item']['top'][1:3])
            print(f"| {q} | **{r['item']['choice']}** {r['item']['top'][0]['p']:.2f} | {top} | {r['mentions']:.2f} | {ms} |")

        print('\n## 2. 영수증 정리\n')
        lines = [{'names': candidates(x), 'like': like(x)} for x in RECEIPT]
        t = time.time()
        r = await decisions.receipt(client, lines)
        print(f'한 번에 {len(RECEIPT)}줄, {int((time.time() - t) * 1000)} ms\n')
        print('| 읽은 줄 | 상품인가 | 고른 이름 (후보) | 집에 있는 것과 같은가 | 같은 물건 |\n|---|---|---|---|---|')
        for raw, ln, out in zip(RECEIPT, lines, r['lines']):
            print(f"| {raw} | {out['keep']:.2f} | **{out['name']}** ({' / '.join(ln['names'])}) | {out['same']:.2f} | {out['item'] or '-'} |")

        if folder and folder.is_dir():
            print('\n## 3. 사진 한 장 → 안에 있는 물건들 (서버와 같은 decisions.photo)\n')
            print('| 사진 | 보이는 묶음 (0.5 이상) | 체크될 물건 (0.75 이상) | ms |\n|---|---|---|---|')
            for p in sorted(folder.glob('*.jpg')):
                t = time.time()
                r = await decisions.photo(client, p.read_bytes())
                ms = int((time.time() - t) * 1000)
                groups = ', '.join(f'{g} {v:.2f}' for g, v in sorted(r['groups'].items(), key=lambda kv: -kv[1]) if v >= 0.5)
                items = ', '.join(f"{x['name']} {x['p']:.2f}" for x in r['items'] if x['p'] >= 0.75)
                print(f'| {p.stem} | {groups or "-"} | {items or "-"} | {ms} |')


asyncio.run(main())

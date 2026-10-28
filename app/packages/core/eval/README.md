# 평가 세트

규칙과 Jev(TypeSafe) 같은 결정 모델을 같은 문제로 비교하기 위한 정답지예요.

- `classify.jsonl` — 물건 이름 → 종류(`food|household|tools|medicine|other`) · 맞는 아이콘 키(앞쪽이 가장 좋음).
- `find.json` — 한 집의 물건 목록 + "그거 어디 있어?" 질문과 정답 물건.

규칙 점수는 `dart test test/eval_test.dart` 가 출력해요. 모델 점수는 `.github/workflows/jev-eval.yml`(수동 실행)이 같은 파일로 재요.
정답은 사람이 고친다. 모델 출력으로 정답을 바꾸지 않는다.

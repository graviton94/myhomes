# 다음 작업 (세션 인계)

마지막 갱신: 2026-10-25. 새 세션은 이 문서 → `CLAUDE.md` → `docs/plan.md` 순서로 읽는다.

## 지금 상태

- 서비스 기획 v0.6: `docs/woorijip-yojeong-plan.html` (아티팩트 https://claude.ai/artifact/Wrqvth4oM8YnZHqeqtiuKS).
- 개발 계획: `docs/plan.md`. Flutter + JSON 파일(게스트 모드) → 3단계에 Firebase(us-central1).
- 화면 흐름 시안(허락받음, "추천안으로 진행"): https://claude.ai/artifact/Jy5Wd17RfXEJ4iuMSgsbhu — 로딩 → 소개 → 로그인(버튼은 보이되 3단계 전까지 "곧 열려요") → 홈(추가 · 이동 · 빼기) · 보관함에서 바로 추가 · 이동 · 빼기 · 집요정은 오른쪽 아래 동그란 버튼 → 대화 시트.
- 패키지 `io.github.graviton94.homefairy`, 기본 언어 영어 + 한국어.
- 사용자 계정 작업은 아직 없음 (필요해질 때 "선행 필요"로 요청).
- 컨테이너: Flutter SDK 는 `/opt/flutter-sdk/flutter` 에 받아 쓴다 (세션마다 새로 받아야 할 수 있음: `docs/plan.md` 1장의 버전 3.47.7). Android SDK 는 막혀 있어 APK 는 GitHub Actions 에서.

## v0.7 방향 전환 (2026-10-25, 시안 검토 중)

시안: https://claude.ai/artifact/N8aBQ1TqSVo85fBQXP1ijc (`docs/home-map-mockup.html`). 디자인은 대체로 OK, 템플릿을 실제 분양 평면에 가깝게 고치고 글자 겹침을 다듬음(v0.7.1). 코드 패치는 아직 허락 전.

- 제1 목적: "그거 어디 있어?"에 가족 누구나 10초 안에 답하기. 첫 화면 = 우리 집 평면도(블록) + 검색창 하나(= 집요정). 탭은 지도 · 넣기 · 가족.
- 보관함 3종류: 가구(칸 · 서랍) · 상자(번호, 통째로 이동) · 자리. 칸 안 순서(slot)는 기록하지 않음.
- 넣기: 자리 고르기 → 이름 여러 개 한 문장("가위, 테이프랑 AA 건전지 4개") → 저장. 사진은 칸 · 상자에 한 장(선택). ML Kit 은 나중에 이름 후보 칩으로만.
- 집 구조: 평면도 사진 따라 그리기 + 템플릿 6개(59㎡ · 84㎡ 3베이 · 84㎡ 4베이 · 84㎡ 타워형 · 투룸 빌라 · 원룸), 0.5m 칸 블록 조립.
- 소비기한 · 돌려받기 · 소모품 알림은 설정에서 켜는 부가 기능(기본 꺼짐).
- 사진: 기기에서 480px WebP(약 30KB) + 96px 썸네일 → Firestore `photos/{id}` (Storage · Blaze 안 씀).

## Jev (TypeSafe System One) 평가 — 2026-10-28

- 키 `JEV_API_KEY` 작동 확인(`jev-docs.yml`). API `https://api.typesafe.ai`, Python SDK `typesafe-sdk`, 질문 형식 Noul(예·아니오 확률) · Choice(고르기, 확률 · 신뢰도) · Score. 모델 `jev-latest`, `jev-preview`.
- 이 세션은 typesafe.ai 와 Actions 결과물 저장소에 못 닿는다 → CI 로그(GitHub MCP `get_job_logs`)로 읽는다.
- 평가 세트 `app/packages/core/eval/` + `jev-eval.yml`(수동). 서버와 같은 코드 `functions/decisions.py` 로 잰다. 결과(jev-latest, 2026-10-28):

| 일 | 규칙만 | Jev | 신뢰도 ≥ 0.7 (정확도 · 비율) | 0.4–0.7 |
|---|---|---|---|---|
| 종류 5개 | 58% | 90% | 95% · 90% | 8% |
| 아이콘 157개 (한 번에) | 59% | 93% | 100% · 68% | 29% (위 3개 칩 안에 정답 97%) |
| 찾기, 40개 집 | 18% | 90% | 100% · 85% | 12% |
| 찾기, 207개 집 | 25% | 90% | 100% · 72% | 22% |

- 응답 중앙값 약 100ms. "종류 → 그 묶음 안 아이콘" 2단계는 77%로 더 낮아서 버림.
- 정책: 0.7 이상이면 미리 선택, 0.4–0.7이면 위 3개 칩, 그 아래·오프라인은 규칙.
- 서버: `functions/` (Python Cloud Function `decide`, us-central1, 익명 로그인 필수, 하루 300회, 키는 Secret Manager). 배포 `functions.yml`. 첫 배포는 서비스 계정에 "Service Usage Admin" 역할이 없어 API 사용 설정에서 멈춤 → 사용자에게 요청함.

## 사용자가 넣은 값 (GitHub Actions Secrets)

| 이름 | 상태 | 쓰는 곳 |
|---|---|---|
| `SIDELOAD_PASSPHRASE` | 확인됨 | 시험 키 `sideload.jks.gpg` 생성 완료 → `app.yml` 이 풀어 서명하고 서명자를 검사 |
| `ANDROID_UPLOAD_PASSPHRASE` | 확인됨 | 업로드 키 `upload.jks.gpg` 생성 완료 (4단계 AAB) |
| `GOOGLE_SERVICES_JSON` | 확인됨 | 프로젝트 `homefairy-dev`, 패키지 일치. SHA 미등록(Google 로그인 붙일 때 `keystore/README.md` 의 SHA-1 두 개 등록 후 파일 다시 받기) |
| `FIREBASE_SERVICE_ACCOUNT` | 확인됨 | 같은 프로젝트, 인증 성공, Firestore `(default)` @ us-central1 있음 |
| `JEV_API_KEY` | 확인됨 | TypeSafe Jev. 앱에 넣지 않는다(중계 서버에서만) |
| `FOOD_API_KEY` | 확인됨 | C005 호출 INFO-000 (https · http 모두 됨) |

- 확인은 `secrets-check.yml`(수동 실행)로 한다. 값은 찍지 않고 프로젝트 ID · 결과 코드만 남긴다.
- 식약처 바코드: 서비스 `C005`, 입력 `BAR_CD`(바코드 번호), 출력 `PRDLST_NM`(제품명)만 쓴다. `POG_DAYCNT`(소비기한)는 "제조일로부터 12개월" 같은 글이고 제조일자는 필수 표기가 아니라 해석하지 않는다 — 소비기한은 사람이 날짜로 직접(선택) 넣는다. 주소 형식 `openapi.foodsafetykorea.go.kr/api/{키}/C005/json/1/5/BAR_CD={번호}` — https 지원 여부와 하루 호출 한도는 붙일 때 확인. 키는 앱에 들어가므로(`--dart-define`) 공개돼도 되는 무료 키로만 쓴다.

## 0단계에 들어간 것

| 무엇 | 어디 |
|---|---|
| Flutter 프로젝트, Riverpod · go_router, minSdk 26 | `app/` |
| 순수 규칙 + 테스트: 소비기한 단계 · 알림 시각, 초성 검색, 위치 코드 | `app/packages/core` |
| 디자인 토큰 → 생성 코드, 라이트/다크 테마 | `design/tokens.json` → `app/tool/generate.dart` → `lib/design/` |
| 영어 · 한국어, 언어 · 테마 설정(저장됨) | `lib/l10n/*.arb`, `lib/settings/` |
| 글꼴 부분 집합 (한글 KS X 1001 2,350자) | `app/tool/build_fonts.py` → `assets/fonts` |
| 집요정 6표정 (라이트/다크) · 앱 아이콘 | `design/fairy/parts.svg` → `app/tool/bake_fairy.mjs` |
| 화면: 홈(빈 상태) · 탭 4개 빈 화면 · 설정 · 디자인 견본 | `lib/features/` |
| 위젯 테스트 · 골든 스크린샷 (커밋하지 않음) | `app/test/` |
| CI: 푸시마다 시험용 APK → Releases `android-latest` | `.github/workflows/app.yml`, `screens.yml` |


## 1단계 첫 묶음에 들어간 것

| 무엇 | 어디 |
|---|---|
| 모델 · 규칙(공간 · 보관함 · 물건 · 기록, 이동 합치기 · 나누기, 일괄 빼기, 검색, 기한 정렬) + 테스트 | `app/packages/core/lib/src/model.dart`, `ops.dart` |
| JSON 저장소 · 한 단계 되돌리기 | `lib/data/home_store.dart` |
| 로딩 · 소개 · 로그인(게스트로 시작) | `lib/features/onboarding/` |
| 홈 개편 · 집요정 버튼 + 대화 시트(기기 안 검색, 이번 주 챙길 것, 얼마 안 남은 것) | `lib/features/home/`, `lib/features/fairy/` |
| 공간 · 보관함(사진 · 이름 · 코드, 칸은 화면 너비에 맞춰 줄바꿈하고 물건 따라 늘어남) · 물건 추가/수정(사진, 최근 이름, 기한 칩, 연속 등록) | `lib/features/spaces/`, `storage/`, `item/` |
| 보관함 칸 화면: 빈 칸 탭 = 추가, 물건 시트(−/+ · 이동 · 다 씀 · 수정), 길게 눌러 여러 개 + 수량 팝업 → 이동 · 빼기 · 다 씀, 되돌리기 | `lib/features/storage/` |
| 검색 탭 · 소비기한 탭 · 설정(소개 다시 보기, 데이터 모두 삭제) | `lib/features/search/`, `expiry/`, `settings/` |

## 공간 화면 개편 (시안 C 허락받음)

시안: https://claude.ai/artifact/Uj38XuYqYv1QZSCGJsULBP (`docs/hierarchy-options.html`)

- 공간 탭 = 방 탭 + 보관함 "가방"들(칸에 물건 이름이 바로 보임). 물건을 고르면 다른 가방에 "여기로" 버튼이 생겨 바로 이동. `lib/features/spaces/space_board.dart`
- 모든 화면 위 위치 줄 "⌂ 우리 집 › 방 › 보관함" (방 = 초록, 보관함 = 노랑). `lib/widgets/location_bar.dart`
- 아이콘: 공간 · 보관함 · 물건 모두 아이콘을 가짐(160여 개, 10묶음). 이름을 쓰면 맞는 아이콘을 추천하고 고르지 않으면 가장 잘 맞는 것을 자동으로 씀. 규칙은 `packages/core/lib/src/icons.dart`, 그림은 `lib/widgets/app_icons.dart`.

## 반짝이기 · 끌어놓기 · 집 밖

- 검색 · 요정 · 소비기한 · 홈에서 물건을 누르면 공간 탭이 그 방으로 열리고 가방까지 스크롤된 뒤 칸이 반짝임 (`/space/:id?item=`). `lib/widgets/open_item.dart`
- 끌어놓기: 물건을 꾹 눌러 끌면 다른 칸(같은 보관함은 자리 바꾸기) · 다른 칸이나 가방 머리(그 보관함으로 이동, 같은 종류는 합치기). 꾹 눌렀다 그냥 떼면 고르기. 화면 끝으로 끌면 자동 스크롤. `lib/features/storage/inventory_grid.dart`
- 집 밖: 공간에 `outside` 표시, 방 탭 뒤에 따로(감 색). 집 밖 보관함은 돌려받을 날(`returnBy`)을 둘 수 있고, 소비기한 탭 맨 위 "돌려받을 것"에 모임.
- AI 사진 인식(OCR)은 비용 때문에 뒤로 미룸.

## 6가지 사용 피드백 반영

- 다른 방으로 끌기: 끄는 동안 아래에 다른 방 독이 뜸. 방 위에 잠깐 올려두면 그 방이 열리고, 방에 바로 놓으면 보관함이 하나면 거기로, 여럿이면 고르기.
- 집 밖 장소는 홈 · 고르기 · 독에서도 감 색.
- "어디로 옮길까요?": 방별 색 머리 + 보관함 카드(아이콘, 개수, 물건 미리보기) + 각 방의 "새 보관함". 지금 있는 곳은 흐리게 "지금 여기".
- 수정 · 삭제: 가방 ⋮ 메뉴(크게 보기 · 수정 · 삭제), 방 탭이나 홈 타일 길게 누르기 → 수정 시트(아래에 삭제).
- 아래 시트들이 휴대폰 내비게이션 바에 가리지 않게 여백.
- 아이콘: 이모지는 쓰지 않음(통일성). 머티리얼에 없는 옷(상의 · 반팔 · 하의 · 반바지 · 속옷 · 원피스 · 치마 · 양말)과 반려동물(개 · 고양이 · 햄스터 · 새)은 같은 24칸 꽉 찬 모양으로 직접 그려 `design/icons/*.svg` → `app/tool/build_icons.py` → `assets/fonts/HfIcons.ttf` + `lib/widgets/hf_icons.g.dart`. 가족(아빠 · 엄마 · 아들 · 딸 · 할아버지 · 할머니)은 머티리얼.

## 다음 할 일

### 1단계 남은 것
1. 사용자가 이번 APK 로 실제 물건을 넣고 · 옮기고 · 빼 보기 → 고칠 점 반영.
2. 로컬 알림 (`flutter_local_notifications`, D-3 · D-1 · 당일 09:00).
3. 공간 사진 + 핀, 보관함 안에서 끌어서 칸 옮기기(`moveToSlot` 는 core 에 있음), 중첩 보관함 화면, 활동 기록 화면.

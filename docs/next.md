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

시안: https://claude.ai/artifact/N8aBQ1TqSVo85fBQXP1ijc (`docs/home-map-mockup.html`). 디자인은 대체로 OK, 템플릿을 실제 분양 평면에 가깝게 고치고 글자 겹침을 다듬음(v0.7.1).

진행 방식(2026-10-28 사용자 결정): 한 번에 바꾸지 않고 작은 단계로 나눠, 단계마다 APK 로 확인받고 다음으로 넘어간다. 지금 앱 위에 하나씩 얹는다.
1. 넣기: 자리 하나 + 문장 하나("가위, 테이프랑 AA 건전지 4개") → 여러 물건 한 번에 저장 — 구현(2026-10-28): core `sentence.dart`(나누기 · 수량 · 같은 이름 합치기 · 최근 자리), 화면 `/add`(홈 "추가" · 보관함 "추가"에서 열림). 빈 칸 탭은 기존 한 개 넣기 화면 그대로. 서버 추천은 아직 안 붙임(규칙으로 아이콘 · 종류).
2. 홈 위 검색창 하나 = 집요정 (찾기 탭과 대화 시트를 한 입구로) — 구현(2026-10-28, 시안 https://claude.ai/artifact/8EMAUc9pDQPp8HNYNw5h6X `docs/onboarding-search-mockup.html`): 홈 검색창에서 바로 결과 + 요정 한 줄(`features/search/search_results.dart`), 이름으로 못 찾을 때만 0.8초 뒤 서버. 찾기 탭 · 요정 버튼 · 대화 시트 삭제, 탭 4개. 같이 들어간 것: 시작 화면 요정이 선으로 그려지는 애니메이션(`widgets/fairy_sketch.dart`, 좌표는 `design/fairy/parts.svg`), 소개 3장(찾기 · 넣기 · 가족 장면 + 상황별 요정), 소개 다시 보기 → 게스트면 로그인 화면까지, 기존 게스트에게 홈에서 한 번 로그인 시트(`LoginNudge`). ARB 글자는 부분 글꼴에 있는 것만(…, →, › 안 됨: `tool/build_fonts.py --check`).
3. 보관함 종류: 가구(칸 · 서랍) · 상자(번호, 통째로 이동) · 자리 — 구현(2026-10-28): core `kinds.dart`(Storage.kind/number, 기존 데이터는 자리), 보관함 추가 때 종류 먼저, 가구는 칸 이름 목록, 방 화면에 가구 칸별 그리드 + 상자 칩, 상자 ⋮ "상자째 옮기기". 아직: 칸 안 순서 없애기(그리드 유지 중), 가구 앞모습 화면.
4. 첫 화면 우리 집 지도(블록) + 탭 개편(지도 · 넣기 · 가족) — 1차 구현(2026-10-28): 홈 = 검색창 + 지도(`features/home/house_map.dart`, 방은 초록 블록 두 줄로 자동 배치, 안에 가구 · 상자 · 자리 꿀색 블록, 검색하면 찾은 곳이 감색 + 개수, 집 밖은 아래 띠) + 먼저 챙기기. 탭 지도 · 넣기 · 가족, 공간 · 소비기한은 밀어 여는 화면. 모든 탭 위에 확성기 줄(직전 변경, `lastChange`) + 설정, 밀어 여는 화면도 우상단 설정. 방 위치는 5단계 평면도에서.
5. 집 구조 만들기: 템플릿 6개 · 블록 조립 — 1차 구현(2026-10-28): core `plan.dart`(Space.plan 0.5m 칸, 템플릿 6개, `applyTemplate`은 같은 이름 방에 자리 지정), `/house/setup`(템플릿 · 빈 칸 · 지도 없이), `/house/edit`(방 블록 끌어 옮기기 · 모서리 점으로 크기, 칸에 맞춤), 지도는 평면도대로 그리고 평면도 밖 방은 아래에. 아직: 평면도 사진 따라 그리기, 가구 블록 위치.
6. 사진 Firestore · 부가 기능(기한 · 돌려받기 · 소모품 알림) 설정에서 켜기 — 1차 구현(2026-10-28): 설정 "더하기 기능" 스위치 3개(기본 꺼짐, `settings.dart` expiryOn · returnsOn · lowStockOn). 켜면 지도 아래 띠(먼저 챙기기 · 돌려받을 것 · 떨어져 가요), 물건 화면에 기한 · 최소 수량, `/shopping` 장보기 목록(채웠어요 = 최소 수량까지). 최소 수량이 있는 물건은 다 써도 0개로 남음. 알림은 core `features.dart` `remindersFrom`(D-3 · D-1 · 당일 9시) → `data/reminders.dart`(flutter_local_notifications, 정확하지 않은 알람이라 별도 권한 없음, 아이콘 `ic_stat_fairy`). 사진은 480px WebP + 160px 썸네일(`_t.webp`)로 줄여 저장. Firestore 사진 올리기는 클라우드 동기화(다음 단계)와 함께.

- 제1 목적: "그거 어디 있어?"에 가족 누구나 10초 안에 답하기. 첫 화면 = 우리 집 평면도(블록) + 검색창 하나(= 집요정). 탭은 지도 · 넣기 · 가족.
- 보관함 3종류: 가구(칸 · 서랍) · 상자(번호, 통째로 이동) · 자리. 칸 안 순서(slot)는 기록하지 않음.
- 넣기: 자리 고르기 → 이름 여러 개 한 문장("가위, 테이프랑 AA 건전지 4개") → 저장. 사진은 칸 · 상자에 한 장(선택). ML Kit 은 나중에 이름 후보 칩으로만.
- 집 구조: 평면도 사진 따라 그리기 + 템플릿 6개(59㎡ · 84㎡ 3베이 · 84㎡ 4베이 · 84㎡ 타워형 · 투룸 빌라 · 원룸), 0.5m 칸 블록 조립.
- 소비기한 · 돌려받기 · 소모품 알림은 설정에서 켜는 부가 기능(기본 꺼짐).
- 사진: 기기에서 480px WebP(약 30KB) + 96px 썸네일 → Firestore `photos/{id}` (Storage · Blaze 안 씀).

## v0.8 계획 (2026-10-28, 컨펌 대기)

시안: https://claude.ai/artifact/5UW7dqFvM1HdDre5nwVEeh (`docs/v08-plan-mockup.html`). 1 우리 집 만들기 · 초대코드 → 2 동기화 → 3 사진 → 4 규칙 · App Check → 5 가족 알림 → 6 평면도 사진 · 가구 위치 → 7 네이버 → 8 구독 · 비공개 테스트.
사용자 결정(2026-10-28): 무료는 2명까지. Firestore 는 이미 사용 중(Blaze). 네이버 · Play Console 이 필요한 것(App Check, 구독, AAB)만 빼고 진행.
- 1~3 구현(2026-10-28): Cloud Function `household`(create · invite · join · leave, 6자리 코드 24시간, 인원 `limit` 2), `users/{uid}.homeId`, `homes/{id}` + 하위 `spaces · containers · items · log · photos`. 규칙 `firestore.rules`(멤버만, 초대 · 사용량은 함수만), `functions.yml` 이 규칙 배포 + 두 계정 종단 시험. 앱: core `sync.dart`(문서 단위 diff, `_o` 순서), `data/household.dart`(CloudHomeRepository: 실시간 · 오프라인, 사진은 `photos/{파일명}` Blob 로 올리고 다른 폰은 처음 볼 때 받음), 가족 탭(`features/family/`), 확성기 줄에 누가 바꿨는지 + 저장 상태 구름 아이콘. 로그 항목에 `by`(uid).
- 5 구현(2026-10-28): 설정 더하기 기능 "가족이 바꾸면 알림"(우리 집 안에서만). 앱이 바꾼 뒤 3초 모아 `household` notify 호출 → 알림 켠 다른 가족에게 FCM(사람별 tag 로 한 줄씩 교체). 토큰 · 언어는 `users/{uid}`(alerts · fcm · lang). Firestore 트리거 대신 호출이라 지역 설정 문제 없음.
- 6 구현(2026-10-28): 집 모양 고치기에 평면도 사진 깔기(이 폰에만, 크기 슬라이더 · 숨기기), 방 고르고 "가구 놓기" → `/house/room/:id`(Storage.plan, 방 안 0.5m 칸). 지도는 놓은 가구를 위치대로, 안 놓은 것은 이름 아래 목록.

## v0.9 계획 (2026-10-28, 컨펌 대기)

시안: https://claude.ai/artifact/T56u4NN3UWeapy7yxuF781 (`docs/v09-plan-mockup.html`). 개정 2(사용자 피드백): 1 가족 다듬기 → 2 AI 비용 계측 · 월 크레딧(플러스 마진 60% 이상: 원가 상한 약 900원/집/월) → 3 영수증으로 넣기(폰 안 ML Kit OCR + core 규칙, 서버는 글자만 정리) → 4 바코드(식품만, 기존 `FOOD_API_KEY` C005) → 5 홈 위젯 → 6 월간 리포트 PDF → 7 비공개 테스트 · 플러스(★ Play Console, 네이버는 이때 다시) → 8 사진 한 장(평가 세트 · 원가 먼저, 신중히). 무료 AI 하루 50번/사람은 크레딧으로 줄인다.
- 진행(2026-10-28, 혼자 할 수 있는 것부터): 월간 보고서 `/report`(core `report.dart` monthReport, 새 로그 종류 `discard` "버렸어요" — 물건 시트, 화면을 그림으로 떠서 A4 PDF 로 공유, 서버 없음. 공유 집은 그 달 로그를 서버에서 읽음).
v0.8 마무리(2026-10-28): Firestore 규칙 배포에 Firebase Rules Admin 역할 필요(사용자가 추가함), 공유 집 종단 시험 통과. Releases 업로드 403 은 저장소 Actions 권한 Read and write 로 바꿔 해결(다음 푸시부터 확인).

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
- 서버: `functions/` (Python Cloud Function `decide`, us-central1, 익명 로그인 필수, 모델 호출 하루 50회, 이름별 결과 캐시 `classifyCache/{이름 해시}` — 이름 자체는 저장 안 함, 키는 Secret Manager). 배포 · 시험 `functions.yml` (2026-10-28 통과).
- 앱: `lib/data/smart_suggest.dart` (익명 로그인 → `decide`, 6초 제한, 실패하면 null → 규칙). AI 추천은 설정 없이 항상 켜짐(사용자 결정 2026-10-28). 하루 한도(서버 `resource-exhausted`)를 넘으면 그날은 규칙(단어 검색)만 쓰고, 검색에 "AI 검색에서 단어 검색으로 전환돼요" + 구독 안내를 띄운다(`outOfQuota`). 구독 상품은 아직 없음. Firebase 값은 CI 가 `GOOGLE_SERVICES_JSON` 에서 뽑아 `--dart-define` 으로 넣음.

## 로그인 (2026-10-28)

- Google: Firebase Auth + `google_sign_in`(웹 클라이언트 ID 는 CI 가 `GOOGLE_SERVICES_JSON` 의 type 3 클라이언트에서 뽑아 `GOOGLE_WEB_CLIENT_ID`). 게스트(익명)면 같은 uid 로 연결.
- 카카오 · 네이버: SDK 로 받은 액세스 토큰 → Cloud Function `login` 이 제공자 API(`kapi.kakao.com/v2/user/me`, `openapi.naver.com/v1/nid/me`)로 확인 → Firebase 커스텀 토큰(uid `kakao:<id>`, `naver:<id>`). 함수 서비스 계정에 "서비스 계정 토큰 생성자" 필요(`functions.yml` 이 검사).
- 앱 코드 `lib/data/accounts.dart`, 버튼 `lib/widgets/login_buttons.dart`, 설정 화면 "계정". 물건은 아직 휴대폰에만 있다(로그인해도 동기화 없음).
- 남은 일: 클라우드 동기화 전에 카카오 토큰의 앱 ID 확인(`/v1/user/access_token_info`) 추가.

## 시작 화면 · 게스트 (2026-10-28)

- 시작 화면은 탭할 때까지 기다린다(`splashDoneProvider`, 테스트는 `splashDelayProvider` 0 이면 바로 통과). 연필이 선을 따라 요정을 그림(약 3.5초, `sounds/pencil.wav`) → 색 → 별 · 돼지꼬리 "뿅"(`sounds/pop.wav`) → 이름 → "터치해서 시작". 소리는 `tool/make_sounds.py` 로 만든 것(녹음 아님).
- 게스트는 시작할 때마다 로그인 화면을 거친다("계정 없이 시작하기"로 계속). 설정 계정 칸의 "로그인"은 로그인 화면으로 보낸다(`leaveGuest`). 홈의 한 번짜리 로그인 시트는 없앰.

## 사용자가 넣은 값 (GitHub Actions Secrets)

| 이름 | 상태 | 쓰는 곳 |
|---|---|---|
| `SIDELOAD_PASSPHRASE` | 확인됨 | 시험 키 `sideload.jks.gpg` 생성 완료 → `app.yml` 이 풀어 서명하고 서명자를 검사 |
| `ANDROID_UPLOAD_PASSPHRASE` | 확인됨 | 업로드 키 `upload.jks.gpg` 생성 완료 (4단계 AAB) |
| `GOOGLE_SERVICES_JSON` | 확인됨 | 프로젝트 `homefairy-dev`, 패키지 일치. SHA 미등록(Google 로그인 붙일 때 `keystore/README.md` 의 SHA-1 두 개 등록 후 파일 다시 받기) |
| `FIREBASE_SERVICE_ACCOUNT` | 확인됨 | 같은 프로젝트, 인증 성공, Firestore `(default)` @ us-central1 있음 |
| `JEV_API_KEY` | 확인됨 | TypeSafe Jev. 앱에 넣지 않는다(중계 서버에서만) |
| `KAKAO_NATIVE_APP_KEY` | 넣음 | 카카오 로그인(앱 · 매니페스트 스킴) |
| `NAVER_CLIENT_ID` · `NAVER_CLIENT_SECRET` | 넣음 | 네이버 로그인(SDK 설계상 앱 안에 들어감) |
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

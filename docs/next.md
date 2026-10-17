# 다음 작업 (세션 인계)

마지막 갱신: 2026-10-16. 새 세션은 이 문서 → `CLAUDE.md` → `docs/plan.md` 순서로 읽는다.

## 지금 상태

- 서비스 기획 v0.6: `docs/woorijip-yojeong-plan.html` (아티팩트 https://claude.ai/artifact/Wrqvth4oM8YnZHqeqtiuKS).
- 개발 계획: `docs/plan.md`. Flutter + JSON 파일(게스트 모드) → 3단계에 Firebase(us-central1).
- 화면 흐름 시안(허락받음, "추천안으로 진행"): https://claude.ai/artifact/Jy5Wd17RfXEJ4iuMSgsbhu — 로딩 → 소개 → 로그인(버튼은 보이되 3단계 전까지 "곧 열려요") → 홈(추가 · 이동 · 빼기) · 보관함에서 바로 추가 · 이동 · 빼기 · 집요정은 오른쪽 아래 동그란 버튼 → 대화 시트.
- 패키지 `io.github.graviton94.homefairy`, 기본 언어 영어 + 한국어.
- 사용자 계정 작업은 아직 없음 (필요해질 때 "선행 필요"로 요청).
- 컨테이너: Flutter SDK 는 `/opt/flutter-sdk/flutter` 에 받아 쓴다 (세션마다 새로 받아야 할 수 있음: `docs/plan.md` 1장의 버전 3.47.7). Android SDK 는 막혀 있어 APK 는 GitHub Actions 에서.

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

## 다음 할 일

### 1단계 남은 것
1. 사용자가 이번 APK 로 실제 물건을 넣고 · 옮기고 · 빼 보기 → 고칠 점 반영.
2. 로컬 알림 (`flutter_local_notifications`, D-3 · D-1 · 당일 09:00).
3. 공간 사진 + 핀, 보관함 안에서 끌어서 칸 옮기기(`moveToSlot` 는 core 에 있음), 중첩 보관함 화면, 활동 기록 화면.

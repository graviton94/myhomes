# 다음 작업 (세션 인계)

마지막 갱신: 2026-10-15. 새 세션은 이 문서 → `CLAUDE.md` → `docs/plan.md` 순서로 읽는다.

## 지금 상태

- 서비스 기획 v0.6: `docs/woorijip-yojeong-plan.html` (아티팩트 https://claude.ai/artifact/Wrqvth4oM8YnZHqeqtiuKS).
- 개발 계획: `docs/plan.md`. Flutter + drift(게스트 모드) → 3단계에 Firebase(us-central1).
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

## 다음 할 일

### 1단계: 혼자 쓰는 핵심 (0단계 폰 확인 뒤)
1. drift 스키마: Space · Container(중첩, 칸 rows×cols, 코드) · Item(칸, 수량, 분류, 사진, 소비기한) · MoveLog(batchId).
2. 공간 만들기 → 사진 찍기 → 핀 찍기 → 보관함 칸 설정. (화면 흐름 시안 먼저)
3. 찍어서 넣기 (카메라 우선, 최근 이름 칩, 마지막 위치 기본값, 연속 등록).
4. 보관함 칸 보기 · 빼기(−1, 다 썼어요, 되돌리기) · 여러 개 선택 + 수량 팝업 + 일괄 이동.
5. 검색(초성) · 소비기한 탭 · 로컬 알림 (D-3 · D-1 · 당일 09:00).

# 다음 작업 (세션 인계)

마지막 갱신: 2026-10-15. 새 세션은 이 문서 → `CLAUDE.md` → `docs/plan.md` 순서로 읽는다.

## 지금 상태

- 서비스 기획 v0.6 완료: `docs/woorijip-yojeong-plan.html` (아티팩트 https://claude.ai/artifact/Wrqvth4oM8YnZHqeqtiuKS).
- 개발 계획 확정: `docs/plan.md`. 스택은 Flutter + drift(게스트 모드) → 3단계에 Firebase(us-central1).
- 패키지명 `io.github.graviton94.homefairy`, 기본 언어 영어 + 한국어.
- 사용자 계정 작업은 아직 아무것도 하지 않았다 (필요해질 때 "선행 필요"로 요청).
- 이 컨테이너: Flutter SDK · pub 는 받을 수 있고, Android SDK 는 막혀 있다 → 테스트는 여기서, APK 는 GitHub Actions 에서.

## 다음 할 일

### 0단계: 기반 (사용자 허락 뒤 시작)
1. Flutter 프로젝트 `app/` 생성, `packages/core` 분리, Riverpod · go_router · drift 의존성.
2. `design/tokens.json` (기획서 v0.6 따뜻한 팔레트 · 글꼴 · 간격) → `tool/generate.dart` → `tokens.g.dart`, 라이트 · 다크 테마.
3. `gen-l10n`: `app_en.arb`(기본) · `app_ko.arb`, 설정에서 언어 바꾸기.
4. 글꼴 번들 (Fredoka · Nunito · Jua · Noto Sans KR 부분 집합).
5. 집요정: 기획서 SVG 를 `design/fairy/` 로 옮기고 6표정 WebP 굽기 스크립트.
6. CI: `app.yml` (analyze · test · debug APK → Releases `android-latest`), `screens.yml` (골든), 시험 서명 키(`sideload`).
7. 첫 화면: 테마 견본 + 빈 홈 + 언어 전환 → 사용자 폰 확인.

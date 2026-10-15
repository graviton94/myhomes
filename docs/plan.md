# 우리집요정 (Home Fairy) 개발 계획

마지막 갱신: 2026-10-15. 서비스 기획 · 화면 목업은 [docs/woorijip-yojeong-plan.html](woorijip-yojeong-plan.html) (아티팩트와 같은 파일).
이 문서는 **어떻게 · 어떤 순서로 만드는지**만 다룬다.

## 0. 원칙

- **만드는 사람은 Claude, 확인하는 사람은 사용자.** 코드 · 테스트 · 빌드 설정은 Claude 가 클라우드 세션에서 직접 한다.
- **사용자 손이 필요한 일**(계정 · 콘솔 · API 키 · 비밀값)은 두 경우에만 꺼낸다.
  1. 사용자가 물어볼 때
  2. 그것 없이는 다음 단계를 시험할 수 없을 때. 이때는 **"선행 필요: ○○ — 이게 있어야 △△ 를 시험할 수 있어요"** 로 한 번에 정확히 알린다.
- 그 전까지는 계정 없이 돌아가는 것부터 쌓는다: 기기 안 저장소, 로컬 알림, 시험용 서명 키.
- 작업 순서는 [CLAUDE.md](../CLAUDE.md) 그대로: 시안 → 허락 → 패치 → 스크린샷 점검 → (“릴리즈하자” 뒤에만) 출시 빌드.

## 1. 기술 스택 (확정)

| 영역 | 선택 | 이유 |
|---|---|---|
| 앱 | **Flutter** (stable, Dart 3) | Android 먼저, iOS 는 같은 코드로. Firebase 공식 SDK |
| 상태 · 화면 이동 | Riverpod · go_router | 테스트하기 쉬운 구조, 딥링크(초대 링크) 대응 |
| 기기 저장소 | **drift (SQLite)** | 계정 없이 바로 쓰는 “게스트 모드”의 원본. 오프라인 우선 |
| 클라우드 (3단계부터) | Firebase Auth · Firestore · Storage · FCM · Cloud Functions(TypeScript), **us-central1** | 가족 실시간 동기화 · 푸시 · 커스텀 로그인 |
| 로그인 | Google(Firebase) · 카카오(`kakao_flutter_sdk`) · 네이버(`flutter_naver_login`) | 카카오 · 네이버는 Functions 에서 토큰 확인 → Firebase 커스텀 토큰 |
| 사진 | `image_picker` + `flutter_image_compress` | 기기에서 1280px WebP + 256px 썸네일 |
| 알림 | `flutter_local_notifications` → (3단계) FCM | 1단계는 내 폰 소비기한 알림, 3단계에 가족 알림 |
| 다국어 | Flutter `gen-l10n` (ARB) | **기본 영어, 한국어 지원**이 1차 목표 |
| 디자인 원본 | `design/tokens.json` → `tool/generate.dart` → `lib/design/tokens.g.dart` | 기존 앱들과 같은 방식 (생성 파일은 손으로 안 고침) |
| 집요정 | 크레용 SVG(기획서 원본) → 헤드리스 브라우저로 WebP 굽기 | Flutter SVG 는 크레용 필터를 못 그려서 미리 구운 이미지로 |
| 시험 | `core` 순수 Dart 테스트 · 위젯 테스트 · **골든 스크린샷** | 에뮬레이터 없이 화면 사진 확인 (기존 앱의 screens 와 같은 역할) |
| CI | GitHub Actions | 푸시마다 분석 · 테스트 · debug APK → Releases `android-latest` 에서 폰으로 받기 |

이 컨테이너에서는 Flutter SDK · pub 로 **테스트까지** 돌리고, Android SDK 는 받을 수 없어 **APK 는 GitHub Actions 에서** 만든다.

## 2. 구조

```
myhomes/
├─ CLAUDE.md               작업 순서 (세션마다 먼저 읽음)
├─ docs/  plan.md · next.md(인계) · ia.md(화면 트리 · 규칙) · release.md
├─ design/ tokens.json      색 · 글꼴 · 간격 (라이트/다크는 값만 다름)
│          fairy/           집요정 원본 SVG · 구운 WebP
├─ app/                     Flutter 앱 (패키지 io.github.graviton94.homefairy)
│  ├─ packages/core/        순수 Dart: 모델 · 규칙 (수량 나누기 · 합치기 · 기한 · 코드 · 초성 검색)
│  ├─ lib/data/             저장소 인터페이스 ─┬─ LocalRepository (drift, 1단계~)
│  │                                         └─ CloudRepository (Firestore, 3단계~)
│  ├─ lib/features/         home · space · container · item · select · search · expiry · family
│  ├─ lib/l10n/             app_en.arb (기본) · app_ko.arb
│  └─ test/ · test/goldens/
├─ functions/              (3단계) 로그인 · 소비기한 알림 배치
├─ firestore.rules · storage.rules  (3단계) + 규칙 테스트
└─ .github/workflows/      app.yml · screens.yml · signing-key.yml · apk.yml · aab.yml · functions.yml
```

**게스트 → 우리 집:** 1~2단계는 기기 안 저장소로만 동작한다. 3단계에서 로그인하면 기기 데이터를 “우리 집”으로 한 번 올리고, 이후 Firestore 가 원본이 된다. 이 흐름은 출시 후에도 그대로 남는다 (로그인 없이 먼저 써 보기).

## 3. 단계별 계획

★ = 사용자 선행 필요. 그 단계의 해당 작업에 닿았을 때만 요청한다.

| 단계 | 기간 | 만드는 것 | 선행 필요 | 사용자가 폰으로 확인하는 것 |
|---|---|---|---|---|
| **0. 기반** | 1주 | 저장소 뼈대, 디자인 토큰 → 테마(라이트/다크), 영어 · 한국어, 글꼴, 집요정 이미지, CI(debug APK · 골든), 시험 서명 키 | 없음 | 테마 견본 화면 · 빈 홈 · 언어 전환 |
| **1. 혼자 쓰는 핵심** | 3~4주 | 공간(사진 핀) · 보관함(칸 · 코드 · 중첩) · 찍어서 넣기 · 칸 보기 · 빼기(−1 · 다 썼어요 · 되돌리기) · 여러 개 선택 + 수량 팝업 + 일괄 이동 · 검색(초성) · 소비기한 + 로컬 알림 · 활동 기록 | 없음 | 실제 우리 집 물건으로 넣고 · 옮기고 · 빼기 |
| **2. 다듬기** | 1~2주 | 집요정 6표정 적용, 빈 화면, 접근성(48dp · 글자 크기), 영어/한국어 문구 점검, 골든 전 화면 | 없음 | 전체 흐름 사용성 |
| **3. 계정 · 가족 공유** | 3주 | Google 로그인, 집 만들기 · 초대코드, Firestore 동기화, 사진 Storage, 게스트 데이터 올리기, 가족 푸시 → 카카오 · 네이버 로그인 | ★ Firebase dev 프로젝트(us-central1, Blaze, 예산 알림) · `google-services.json` · 배포용 서비스 계정 → ★ 카카오 · 네이버 앱 등록 | 가족 폰 두 대로 실시간 동기화 |
| **4. 비공개 테스트** | 2~3주 | 업로드 키 · AAB, 개인정보처리방침(`graviton94.github.io/homefairy/privacy/`), 스토어 등록정보 | ★ `ANDROID_UPLOAD_PASSPHRASE` · Play Console 앱 만들기 · 테스터 12명 이상 14일 · github.io 저장소 쓰기 권한 | 스토어에서 설치 |
| **5. 기본 완성** | 6주 | 장보기 목록 · 바코드 상품명 · 월간 리포트 · 홈 위젯 · 내보내기 | 없음 (바코드 상품 DB 는 고를 때 알림) | |
| **6. AI 연동 → 정식 출시** | 6주 | 사진으로 이름 · 분류 추천(Haiku 5.5 기본), 영수증 입고, 광고 · 쿠팡 파트너스 | ★ Anthropic API 키 · AdMob · 쿠팡 파트너스 | 사진 한 장으로 넣기 |
| **7. 출시 + 2개월** | | iOS, 요정 플러스 구독 | ★ Apple 개발자 계정 · Play 결제 프로필 | |

참고: 카카오 · 네이버 등록은 Play 업로드가 없어도 된다 (패키지명 + 서명 키 해시만 필요). 다만 위 원칙대로 3단계에서 필요해질 때 요청한다.

## 4. 개발 루프 (매 작업)

1. 큰 화면 · 흐름 변경은 **시안(아티팩트)** 으로 먼저 보여 주고 허락받는다. 작은 수정은 바로 패치.
2. 이 컨테이너에서 `flutter analyze` · `flutter test`(core · 위젯 · 골든) 통과 후 푸시.
3. `app.yml` 이 debug APK 를 만들어 Releases `android-latest` 에 올린다 → 사용자가 폰에서 받아 설치.
4. 사용자 피드백 → 다음 패치. 진행 상황은 `docs/next.md` 에 남긴다.

## 5. 정해진 값

| 항목 | 값 |
|---|---|
| 패키지명 | `io.github.graviton94.homefairy` |
| 앱 이름 | Home Fairy (영어, 기본) · 우리집요정 (한국어) |
| 캐릭터 | 집요정 / House Fairy |
| 최소 Android | 8.0 (API 26) |
| Firebase 리전 | us-central1 |
| 개인정보처리방침 | `https://graviton94.github.io/homefairy/privacy/` |

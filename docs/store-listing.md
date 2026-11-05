# Play 등록정보 · 우리집요정 (Home Fairy)

패키지 `io.github.graviton94.homefairy`. 그림은 `docs/store/` (골든 테스트 `app/test/goldens/store_shots_test.dart` 가 만듦: `flutter test test/goldens/store_shots_test.dart --update-goldens`).

## 주소

| 항목 | 주소 |
|---|---|
| 개인정보처리방침 | https://graviton94.github.io/homefairy/privacy/ |
| 계정 삭제 (데이터 보안 › 계정 삭제 URL) | https://graviton94.github.io/homefairy/privacy/#delete |
| 웹사이트 | https://graviton94.github.io/homefairy/ |
| 이메일 | ruahn49@gmail.com |

## 그림

| 항목 | 파일 |
|---|---|
| 앱 아이콘 512×512 | `docs/store/icon-512.png` |
| 그래픽 이미지 1024×500 | `docs/store/ko-feature.png` · `en-feature.png` |
| 휴대전화 스크린샷 1080×1920 | 한국어 `ko-1-map` ~ `ko-5-moving`, 영어 `en-1-map` ~ `en-4-add` |

## 한국어

- 앱 이름 (30자): 우리집요정: 물건 위치 기억 · 살림 정리
- 간단한 설명 (80자): 물건이 어디 있는지 집 지도에 적고, 검색 한 번으로 찾아요. 기한 · 장보기 · 이사까지.
- 자세한 설명:

```
"가위 어디 뒀더라?" 이제 요정에게 물어보세요.

우리집요정은 집 안 물건이 어디 있는지 우리 집 지도에 적어 두고, 검색 한 번으로 찾아 주는 살림 앱이에요.

■ 집 지도
방 · 가구 · 서랍 · 상자를 우리 집 모양 그대로 적어요. 평면도를 고르면 지도가 실제 집처럼 보여요.

■ 찾기
이름 · 초성 · 위치 코드로 바로 찾아요. "열 날 때 먹는 약"처럼 설명으로 물어도, 말로 물어도 돼요.

■ 넣기 · 옮기기 · 사용
이름을 쓰면 아이콘과 종류가 저절로 붙어요. 사진 · 바코드 · 영수증으로 여러 개를 한 번에 넣어요.

■ 기한 · 장보기 · 돌려받기
기한이 다가오면 먼저 챙길 것을 알려 주고, 떨어진 것은 장보기에 담겨요. 빌려준 물건은 돌려받을 날을 기억해요.

■ 뭐 해 먹지
냉장고 식품으로 만들 수 있는 요리를 공공 레시피에서 골라요. 만든 뒤에는 쓴 만큼만 빼요.

■ 가족과 함께
초대 코드 하나로 가족이 같은 집을 보고 같이 정리해요.

■ 이사 상자
상자마다 번호를 매겨 무엇을 넣었는지 적고, 새 집에서 풀며 제자리를 정해요.

■ 조용한 앱
광고가 없고, 찾지 않은 물건을 먼저 권하지 않아요. 계정 없이 쓰면 모든 기록이 폰 안에만 있어요.

레시피 · 바코드 정보: 식품의약품안전처 식품안전나라
```

## English

- App name (30): Home Fairy: Where Things Are
- Short description (80): Map where things are at home and find them in one search. Dates, shopping, moving.
- Full description:

```
"Where did I put the scissors?" Ask the fairy.

Home Fairy remembers where things are on a map of your home, and finds them with one search.

■ A map of your home
Rooms, furniture, drawers and boxes as they really are. Pick a floor plan and the map looks like your home.

■ Find
By name, by location code, or by description ("medicine for a fever"), typed or spoken.

■ Put away, move, use
Type a name and the icon and kind follow. Add many at once from a photo, a barcode or a receipt.

■ Dates, shopping, things lent
See what to use first, let what runs out go to the shopping list, and remember when lent things come back.

■ What to cook
Dishes from public recipes that use the food you have; take out only what you used. Recipes are in Korean.

■ With family
One invite code, and the family sees and tidies the same home.

■ Moving boxes
Number each box, note what went in, and give things their new place as you unpack.

■ Quiet by design
No ads, and no suggestions you did not ask for. Without an account everything stays on your phone.
```

## 비공개 테스트 출시 노트 (500자)

```
<ko-KR>
첫 비공개 테스트예요. 물건 넣기 · 찾기 · 옮기기, 가족과 함께 쓰는 집, 뭐 해 먹지, 이사 상자를 써 보고 불편한 점을 알려 주세요.
</ko-KR>
<en-US>
First closed test. Try putting away, finding and moving things, sharing a home, What to cook and moving boxes, and tell us what felt awkward.
</en-US>
```

## 앱 콘텐츠 답안

- **광고**: 없음.
- **앱 액세스 권한**: 대부분 기능은 로그인 없이 쓸 수 있음. 가족 공유 · 요정 기능은 카카오 또는 Google 로그인이 필요 — 심사용 안내: "로그인 없이 '시작하기'로 모든 기본 기능을 쓸 수 있고, Google 로그인은 심사자 계정으로 가능".
- **콘텐츠 등급**: 유틸리티 · 생산성, 폭력 · 성적 콘텐츠 · 도박 없음, 사용자 간 소통 = 가족 공유(초대한 사람끼리만, 공개 소통 없음).
- **타겟 연령**: 18세 이상 (13세 미만 대상 아님).
- **뉴스 앱 · 정부 앱 · 건강 앱 · 금융**: 아니오.

## 데이터 보안 답안

- 데이터 수집 · 공유: 예. 전송 중 암호화: 예 (HTTPS · Firebase). 삭제 요청: 예 (앱 안 계정 삭제 + 위 URL).
- 계정 없이도 쓸 수 있음 (계정 만들기는 선택).

| 데이터 유형 | 수집 | 공유 | 필수/선택 | 목적 | 비고 |
|---|---|---|---|---|---|
| 개인 정보 › 이름 (별명) | 예 | 아니오 | 선택 | 계정 관리, 앱 기능 | 카카오 · Google 별명, 가족 공유 집에 표시 |
| 개인 정보 › 사용자 ID | 예 | 아니오 | 선택 | 계정 관리, 앱 기능 | 로그인 서비스 회원 번호 |
| 사진 및 동영상 › 사진 | 예 | 예 (TypeSafe, 사진으로 넣기 때만) | 선택 | 앱 기능 | 가족 공유 집의 물건 사진은 Firebase 에 저장. 사진으로 넣기는 512px 한 장, 저장 안 함 |
| 앱 활동 › 기타 사용자 생성 콘텐츠 | 예 | 예 (TypeSafe, 요정 기능 때만) | 선택 | 앱 기능 | 공유 집의 물건 · 기록 · 장보기, 요정 기능에 보내는 물건 이름 · 영수증 글자 |
| 앱 활동 › 앱 상호작용 | 예 | 아니오 | 선택 | 앱 기능 | 요정 기능 하루 사용 횟수 |
| 앱 정보 및 성능 › 비정상 종료 로그 · 진단 | 예 | 아니오 | 필수 | 분석 (오류 수정) | Firebase Crashlytics |
| 기기 또는 기타 ID | 예 | 아니오 | 선택 | 앱 기능 | 가족 알림용 FCM 토큰 |
| 오디오 › 음성 | 아니오 | — | — | — | 폰의 음성 인식 서비스가 처리, 앱 서버로 안 감 |
| 위치 · 연락처 · 금융 · 건강 | 아니오 | — | — | — | — |

- "공유"의 상대: TypeSafe (판단 모델 서비스, 우리 서버를 거쳐 처리만 하고 저장 안 함). Google Firebase 는 서비스 제공자(처리자)라 공유가 아님. 식품안전나라 API 에는 바코드 숫자만 가고 개인 데이터가 아님.

## 콘솔에서 할 일 (사용자)

1. 앱 만들기 → 위 주소 · 답안 입력.
2. 테스트 › 비공개 테스트 → 트랙 만들기 → 테스터 목록 (12명 이상, 14일 연속).
3. `aab.yml` 로 만든 AAB 업로드 (GitHub › Actions › Store AAB › Run workflow, 버전 1.0.0 → Releases 의 초안에서 AAB 받기).
4. **Play 앱 서명 키 지문 등록**: 설정 › 앱 서명에서 "앱 서명 키 인증서"의 SHA-1 · SHA-256 을 복사해 Firebase 프로젝트 설정 › 내 앱 › 디지털 지문, 카카오 개발자 › 플랫폼 › Android 키 해시(SHA-1 을 base64 로: `echo <SHA-1> | xxd -r -p | base64`)에 더한다. Play 로 받은 앱은 Google 이 이 키로 다시 서명하므로, 이게 없으면 테스터 폰에서 Google · 카카오 로그인이 실패한다.

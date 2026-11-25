"""Icon sheet orders (user request, 2026-11-25): 7×7 pictograms per sheet,
solid one-colour like icon-sheet-01.png. Sheet 1 (rooms and furniture) is
in; these are sheets 2 to 21. Writes icon-orders.json (names per sheet, in
grid order, for cutting) and the order page."""
import json, pathlib

SHEETS = [
 ("주방 도구", "프라이팬 냄비 웍 압력솥 전기밥솥 주전자 전기포트 국자 뒤집개 집게 거품기 주걱 식칼 도마 주방가위 감자칼 강판 채반 체 믹싱볼 계량컵 계량스푼 밀대 깔때기 병따개 캔따개 와인오프너 마늘다지기 절구 찜기 뚝배기 석쇠 에어프라이어 믹서기 토스터 커피머신 핸드블렌더 전기그릴 와플메이커 정수기 행주 수세미 고무장갑 앞치마 냄비받침 오븐장갑 키친타이머 주방저울 키친타월"),
 ("식기 · 보관 용기", "밥공기 국그릇 접시 앞접시 대접 쟁반 머그컵 유리컵 와인잔 맥주잔 텀블러 보온병 물병 젓가락 숟가락 포크 나이프 수저통 이쑤시개 빨대 도시락통 밀폐용기 유리용기 지퍼백 랩 호일 비닐봉지 위생장갑 키친랩 김치통 쌀통 양념통 소금통 후추통 기름병 간장병 시럽병 잼병 유리병 티백통 커피캔 반찬통 아이스박스 얼음틀 컵받침 식탁매트 냅킨 이유식그릇 일회용컵"),
 ("채소 · 과일", "사과 배 귤 오렌지 레몬 바나나 포도 딸기 수박 참외 복숭아 자두 키위 망고 파인애플 체리 블루베리 감 밤 토마토 방울토마토 오이 당근 감자 고구마 양파 대파 쪽파 마늘 생강 배추 양배추 상추 깻잎 시금치 브로콜리 파프리카 고추 가지 호박 버섯 콩나물 무 옥수수 아보카도 연근 우엉 두부 달걀"),
 ("고기 · 해산물 · 냉동", "소고기 돼지고기 닭고기 닭다리 삼겹살 스테이크 햄 소시지 베이컨 스팸 생선 고등어 연어 새우 오징어 문어 조개 굴 게 멸치 김 미역 다시마 어묵 맛살 냉동만두 냉동피자 냉동볶음밥 치킨너겟 돈가스 아이스크림 아이스바 얼음 냉동새우 냉동블루베리 떡 떡국떡 순대 족발 훈제오리 육포 치즈 버터 우유 요구르트 생크림 계란판 두유 플레인요거트"),
 ("가공식품 · 간식", "라면 컵라면 국수 파스타면 쌀 잡곡 밀가루 부침가루 빵가루 시리얼 식빵 베이글 케이크 쿠키 과자 감자칩 초콜릿 사탕 젤리 껌 견과류 아몬드 땅콩 팝콘 떡볶이 즉석밥 즉석카레 통조림 참치캔 옥수수캔 과일통조림 수프 죽 김자반 김치 단무지 피클 잼 꿀 땅콩버터 누텔라 마시멜로 프레첼 크래커 에너지바 단백질바 뻥튀기 약과 양갱"),
 ("양념 · 소스", "간장 고추장 된장 쌈장 식초 설탕 소금 후추 고춧가루 참기름 들기름 식용유 올리브유 맛술 굴소스 케첩 마요네즈 머스터드 핫소스 스테이크소스 바비큐소스 데리야끼소스 칠리소스 와사비 연겨자 다시다 치킨스톡 카레가루 짜장가루 물엿 올리고당 매실청 액젓 새우젓 쯔유 발사믹 드레싱 파마산 시나몬 바닐라 베이킹파우더 이스트 전분 깨 허브 월계수잎 소금통그라인더 후추그라인더 조미료통"),
 ("음료 · 차", "생수 탄산수 콜라 사이다 주스 오렌지주스 커피원두 캡슐커피 인스턴트커피 믹스커피 녹차 홍차 보리차 허브차 유자차 꿀차 코코아 우유팩 두유팩 요구르트병 이온음료 에너지드링크 식혜 맥주캔 맥주병 소주 막걸리 와인 위스키 샴페인 칵테일 얼음컵 빨대컵 텀블러커피 티포트 드립포트 드리퍼 원두그라인더 커피필터 시럽 단백질쉐이크 분유 스무디 레모네이드 콤부차 탄산수제조기 물티슈팩 보틀 캔홀더"),
 ("청소용품", "청소기 무선청소기 로봇청소기 물걸레 빗자루 쓰레받기 대걸레 밀대걸레 걸레 먼지떨이 롤클리너 스펀지 솔 변기솔 청소포 물티슈 키친클리너 락스 세제 유리세정제 곰팡이제거제 배수구클리너 탈취제 방향제 쓰레기통 분리수거함 음식물쓰레기통 종량제봉투 재활용봉투 집게 고무장갑 마스크 양동이 분무기 스팀청소기 창문닦이 먼지봉투 필터 공기청정기 제습기 가습기 선풍기 써큘레이터 모기향 살충제 바퀴약 끈끈이 장갑 청소카트"),
 ("세탁 · 의류 관리", "세탁기 세탁세제 섬유유연제 표백제 세탁망 빨래바구니 빨래건조대 옷걸이 바지걸이 집게 다리미 다리미판 스팀다리미 보풀제거기 옷솔 신발건조기 의류관리기 건조기시트 얼룩제거제 세탁볼 빨래비누 손빨래통 수선실 단추 지퍼 옷핀 이름표 압축팩 옷커버 방충제 제습제 신발주머니 신발깔창 구둣주걱 구두약 우산 우비 장화 실내화 슬리퍼 양말 속옷 수건 목욕가운 잠옷 앞치마 장갑 털모자 귀마개"),
 ("욕실 · 세면", "칫솔 치약 전동칫솔 치실 구강청결제 혀클리너 비누 비누받침 핸드워시 샴푸 린스 트리트먼트 바디워시 바디로션 샤워볼 샤워타올 수건 목욕수건 면도기 면도크림 쉐이빙폼 드라이기 고데기 빗 헤어브러시 헤어밴드 머리끈 샤워캡 욕실매트 욕조마개 변기커버 휴지 휴지걸이 물티슈 손톱깎이 귀이개 면봉 화장솜 거울 체중계 체온계 족욕기 반신욕기 입욕제 때수건 욕실화 방수시계 샤워필터 욕실선반"),
 ("화장품 · 미용", "스킨 로션 에센스 세럼 크림 아이크림 선크림 쿠션 파운데이션 컨실러 파우더 블러셔 하이라이터 립스틱 립밤 립글로스 아이섀도 아이라이너 마스카라 눈썹연필 뷰러 화장솜 화장붓 퍼프 클렌징폼 클렌징오일 클렌징워터 마스크팩 각질제거제 미스트 향수 데오드란트 핸드크림 매니큐어 네일리무버 네일파일 족집게 거울 화장품파우치 헤어오일 헤어스프레이 왁스 염색약 고무줄 실핀 헤어롤 눈썹칼 속눈썹 렌즈케이스"),
 ("약 · 건강", "구급상자 반창고 붕대 거즈 소독약 연고 파스 해열제 진통제 감기약 기침약 소화제 지사제 변비약 알레르기약 안약 인공눈물 콧물약 목캔디 비타민 영양제 오메가3 유산균 홍삼 마스크 손소독제 체온계 혈압계 혈당계 체지방계 찜질팩 핫팩 아이스팩 마사지기 지압봉 보호대 무릎보호대 깁스 약통 약봉투 알약케이스 주사기 처방전 의료보험증 안경 콘택트렌즈 보청기 휠체어 지팡이"),
 ("아기 · 육아", "젖병 분유 분유통 젖꼭지 쪽쪽이 턱받이 기저귀 물티슈 기저귀가방 기저귀교환대 아기욕조 아기샴푸 아기로션 아기파우더 체온계 콧물흡입기 아기손톱깎이 유모차 카시트 아기띠 보행기 바운서 아기침대 범퍼침대 모빌 딸랑이 치발기 이유식기 이유식스푼 빨대컵 아기의자 아기모자 아기양말 배냇저고리 우주복 수유쿠션 유축기 젖병소독기 젖병솔 아기세제 안전문 모서리보호대 콘센트커버 아기모니터 그림책 블록 애착인형 수면조끼 아기수건"),
 ("장난감 · 놀이", "레고 블록 인형 곰인형 로봇 자동차장난감 기차장난감 비행기장난감 공 축구공 농구공 야구공 배드민턴 줄넘기 훌라후프 퍼즐 보드게임 카드게임 체스 바둑 주사위 큐브 비눗방울 물총 연 요요 팽이 클레이 색종이 크레파스 색연필 물감 스케치북 스티커 슬라임 장난감총 소꿉놀이 주방놀이 병원놀이 마트놀이 텐트놀이 볼풀 미끄럼틀 그네 킥보드 세발자전거 게임기 게임패드 장난감상자"),
 ("반려동물", "개밥그릇 물그릇 사료 사료통 간식 개껌 목줄 하네스 리드줄 배변패드 배변봉투 고양이모래 모래삽 화장실 스크래쳐 캣타워 낚싯대장난감 공장난감 삑삑이 방석 켄넬 이동가방 유모차 옷 신발 빗 발톱깎이 샴푸 칫솔 귀세정제 약 영양제 심장사상충약 구충제 넥카라 인식표 어항 수초 물고기밥 새장 새모이 햄스터집 쳇바퀴 톱밥 급식기 급수기 자동급식기 탈취제 펫카메라"),
 ("문구 · 사무", "볼펜 연필 샤프 지우개 형광펜 매직 네임펜 자 가위 커터칼 풀 테이프 양면테이프 스테이플러 심 펀치 클립 집게 고무줄 포스트잇 메모지 노트 다이어리 수첩 파일 클리어파일 바인더 봉투 편지지 엽서 우표 도장 인주 계산기 달력 필통 연필깎이 책갈피 라벨기 화이트 수정테이프 마스킹테이프 압정 자석 칠판 보드마커 명함 서류함 북엔드"),
 ("전자기기", "스마트폰 태블릿 노트북 데스크톱 모니터 키보드 마우스 프린터 스캐너 TV 리모컨 셋톱박스 공유기 스피커 블루투스스피커 이어폰 무선이어폰 헤드폰 마이크 웹캠 카메라 액션캠 드론 게임기 VR기기 스마트워치 전자책 MP3 라디오 전화기 시계 알람시계 디지털액자 빔프로젝터 외장하드 USB메모리 SD카드 메모리리더기 계산기 전자사전 녹음기 번역기 무전기 손전등 랜턴 전자모기채 체중계 스마트플러그 스마트전구"),
 ("케이블 · 충전 · 전기", "충전기 고속충전기 무선충전기 보조배터리 USB케이블 C타입케이블 라이트닝케이블 HDMI케이블 랜선 연장선 멀티탭 어댑터 변환젠더 여행용어댑터 건전지 AA건전지 AAA건전지 충전지 배터리충전기 전구 LED전구 형광등 스탠드 무드등 센서등 손전등 두꺼비집 차단기 콘센트 스위치 전선 케이블타이 케이블정리함 절연테이프 퓨즈 타이머콘센트 전기장판 온수매트 전기히터 전기난로 선풍기 냉풍기 제습기 가습기 전기모기채 충전스테이션 거치대 리모컨배터리 스마트홈허브"),
 ("공구 · 수리", "망치 드라이버 십자드라이버 전동드릴 렌치 스패너 몽키스패너 펜치 니퍼 롱노우즈 줄자 수평계 톱 쇠톱 커터 칼날 사포 줄 끌 클램프 바이스 못 나사 볼트 너트 와셔 앵커 실리콘건 실리콘 글루건 순간접착제 목공풀 페인트 붓 롤러 마스킹테이프 공구함 사다리 작업장갑 보안경 헤드랜턴 전기테스터 납땜기 케이블 경첩 자물쇠 열쇠 도어락배터리 벽걸이후크"),
 ("운동 · 아웃도어", "자전거 헬멧 킥보드 인라인 스케이트보드 요가매트 덤벨 케틀벨 바벨 폼롤러 운동밴드 줄넘기 짐볼 철봉 러닝머신 실내자전거 축구공 농구공 배구공 야구글러브 야구배트 테니스라켓 배드민턴라켓 탁구라켓 골프클럽 골프공 수영복 수경 수모 튜브 구명조끼 스키 스노보드 등산화 등산스틱 배낭 텐트 침낭 캠핑의자 캠핑테이블 버너 코펠 랜턴 아이스박스 해먹 낚싯대 쿨러 물통 선글라스"),
 ("옷 · 신발 · 잡화", "티셔츠 셔츠 블라우스 니트 후드티 맨투맨 청바지 슬랙스 반바지 치마 원피스 정장 코트 패딩 점퍼 가디건 조끼 속옷 브래지어 양말 스타킹 잠옷 운동복 수영복 넥타이 벨트 스카프 목도리 장갑 모자 야구모자 비니 운동화 구두 하이힐 샌들 부츠 슬리퍼 크록스 가방 백팩 크로스백 지갑 시계 안경 선글라스 반지 목걸이 귀걸이"),
]

STYLE = ("첨부 이미지와 똑같은 스타일의 픽토그램 49개를 7×7 격자 한 장에 그려 줘.\n"
         "스타일: 꽉 찬 단색 실루엣 아이콘(머티리얼 아이콘처럼). 둥근 모서리, 굵기 일정, 선이 아니라 면으로. 안쪽 구멍(문 · 손잡이 · 눈금 등)은 배경색으로 뚫기.\n"
         "규칙: 순수 흰 배경에 검정 단색, 배경 사각형 없이 아이콘만, 칸마다 하나씩 가운데, 모두 같은 크기와 시각 무게, 글자 · 그림자 · 그라데이션 없음, 칸끼리 여백 충분히. 같은 것이 두 번 나오지 않게.\n"
         "순서(왼쪽 위부터 가로로 7개씩):\n")

FIX = {7: {'집게': '먼지제거테이프', '고무장갑': '변기뚫어뻥', '물티슈': '정전기청소포', '마스크': '손걸레', '제습기': '제습통', '가습기': '방충망', '선풍기': '환풍기필터', '장갑': '극세사장갑'}, 8: {'집게': '빨래집게', '앞치마': '세탁소옷걸이', '장갑': '다림질장갑', '슬리퍼': '신발정리대', '양말': '양말정리함', '속옷': '속옷정리함', '수건': '수건정리함', '잠옷': '옷개기판'}, 9: {'물티슈': '변기물티슈', '화장솜': '욕실청소솔', '거울': '확대경', '체온계': '욕조온도계'}, 10: {'고무줄': '헤어집게'}, 12: {'분유': '분유포트', '빨대컵': '아기물병', '물티슈': '아기물티슈', '체온계': '귀체온계', '블록': '촉감책'}, 13: {'축구공': '공기놀이', '농구공': '딱지', '줄넘기': '윷놀이', '킥보드': '붕붕카', '게임기': '무선조종차'}, 14: {'탈취제': '펫드라이룸', '칫솔': '펫치약', '샴푸': '펫샴푸', '빗': '펫브러시', '영양제': '펫영양제', '유모차': '펫유모차'}, 15: {'집게': '더블클립', '고무줄': '파일꽂이'}, 16: {'체중계': '스마트도어벨', '게임기': '게임CD', '계산기': '바코드스캐너', '시계': '탁상시계', '랜턴': '블루투스트래커'}, 17: {'손전등': '비상조명'}, 18: {'마스킹테이프': '배관테이프'}, 19: {'아이스박스': '보냉백', '선글라스': '스포츠고글'}, 20: {'시계': '손목시계', '안경': '안경집', '수영복': '래시가드'}}

out = []
for n_sheet, (title, words) in enumerate(SHEETS):
    names = [FIX.get(n_sheet, {}).get(w, w) for w in words.split()]
    assert len(names) == 49, (title, len(names))
    out.append({"title": title, "names": names})
seen = {}
for s in out:
    for n in s["names"]:
        seen.setdefault(n, []).append(s["title"])
dups = {k: v for k, v in seen.items() if len(v) > 1}
print("sheets", len(out), "icons", sum(len(s['names']) for s in out), "repeated across sheets", len(dups))
here = pathlib.Path(__file__).parent
(here / "icon-orders.json").write_text(json.dumps(out, ensure_ascii=False, indent=1))

# The order page: the reference sheet, then one card per sheet with its prompt and a Copy button.
import html as _h
cards = []
for i, s in enumerate(out):
    rows = [" ".join(f"{r * 7 + c + 1} {s['names'][r * 7 + c]}" for c in range(7)) for r in range(7)]
    text = STYLE + "\n".join(rows)
    cards.append(f'''<section class="card" id="s{i + 2}"><div class="head"><h2>{i + 2}장 · {_h.escape(s['title'])}</h2><button data-i="{i}">복사</button></div><pre>{_h.escape(text)}</pre></section>''')
data = json.dumps([STYLE + "\n".join(" ".join(f"{r * 7 + c + 1} {s['names'][r * 7 + c]}" for c in range(7)) for r in range(7)) for s in out], ensure_ascii=False)
page = f'''<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>아이콘 발주 프롬프트</title><link href="https://fonts.googleapis.com/css2?family=Jua&family=Gowun+Dodum&display=swap" rel="stylesheet">
<style>
/* VOICE: 작업 지시서, 차분하고 바로 쓰는 문서
   IDEA: 인쇄소에 넘기는 발주 묶음 — 한 장에 한 장씩
   PICTURE: 받은 1장 시트(기준 이미지)
   COLOUR and TYPE: 크림 바탕, 갈색 글자, 주황 버튼 / Jua + Gowun Dodum
   LAYOUT: 기준 이미지와 쓰는 법, 아래로 21장 카드 */
:root{{color-scheme:light dark;--bg:light-dark(#FBF6EF,#1A1411);--card:light-dark(#FFFCF7,#241C17);--fg:light-dark(#2E241C,#F5ECE2);--mf:light-dark(#6E5F51,#BBA996);--bd:light-dark(#E9DCCB,#3A2F27);--pr:#BF4F24}}
:root[data-theme=light]{{color-scheme:light}}:root[data-theme=dark]{{color-scheme:dark}}
*{{box-sizing:border-box;min-width:0}}body{{margin:0;background:var(--bg);color:var(--fg);font:16px/1.6 'Gowun Dodum',sans-serif;word-break:keep-all;overflow-x:clip}}
h1,h2{{font-family:Jua,sans-serif;font-weight:400}}h1{{font-size:clamp(28px,6vw,40px);line-height:1.1;margin:0 0 10px}}h2{{font-size:20px;margin:0}}
.band{{padding:clamp(20px,4vw,44px) max(5vw,16px);max-width:980px;margin:0 auto}}
.top{{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,360px);gap:28px;align-items:start}}@media(max-width:760px){{.top{{grid-template-columns:minmax(0,1fr)}}}}
.top img{{width:100%;border-radius:16px;border:1px solid var(--bd);background:#fff}}
ol{{padding-left:20px;margin:0}}li{{margin-bottom:6px}}.mf{{color:var(--mf)}}
.toc{{display:flex;gap:8px;overflow-x:auto;padding:4px 0 12px;scrollbar-width:none}}.toc a{{flex:none;padding:8px 12px;border-radius:18px;border:1px solid var(--bd);background:var(--card);color:var(--fg);text-decoration:none;font-size:14px}}
.card{{background:var(--card);border:1px solid var(--bd);border-radius:16px;padding:14px 16px;margin-bottom:14px}}
.head{{display:flex;align-items:center;gap:10px;margin-bottom:8px}}.head h2{{flex:1}}
button{{min-height:44px;padding:0 18px;border-radius:22px;border:0;background:var(--pr);color:#fff;font:16px Jua,sans-serif;cursor:pointer}}button.done{{background:#4F7F47}}
pre{{white-space:pre-wrap;word-break:keep-all;margin:0;font:14px/1.7 'Gowun Dodum',sans-serif;color:var(--fg);max-height:220px;overflow:auto}}
</style></head><body>
<div class="band top"><div><h1>아이콘 발주 프롬프트<br>21장 · 1,029개</h1>
<p class="mf">1장(방 · 가구 49개)은 받았어요.<br>2장부터 22장까지, 장마다 49개가 모두 달라요.</p>
<ol><li>기준 이미지(받은 1장)를 저장해요.</li><li>장마다 <b>복사</b>를 누르고, 기준 이미지와 함께 붙여 넣어요.</li><li>받은 시트는 번호(2장 · 3장…)를 붙여 이 채팅에 주세요.<br>제가 잘라서 앱 아이콘 글꼴로 구워요.</li></ol></div>
<img src="icon-sheet-01.png" alt="받은 1장: 방과 가구 픽토그램 49개"></div>
<div class="band" style="padding-top:0"><nav class="toc">{''.join(f'<a href="#s{i + 2}">{i + 2} {_h.escape(s["title"])}</a>' for i, s in enumerate(out))}</nav>
{''.join(cards)}</div>
<script>{{const T={data};document.addEventListener('click',async e=>{{const b=e.target.closest('button[data-i]');if(!b)return;try{{await navigator.clipboard.writeText(T[+b.dataset.i]);b.textContent='복사됨';b.classList.add('done');setTimeout(()=>{{b.textContent='복사';b.classList.remove('done')}},1600)}}catch(_){{const r=document.createRange();r.selectNodeContents(b.closest('.card').querySelector('pre'));const s=getSelection();s.removeAllRanges();s.addRange(r);b.textContent='선택됨 · 길게 눌러 복사'}}}})}}</script>
</body></html>'''
(here / "icon-orders.html").write_text(page)
print("page written")

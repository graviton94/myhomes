/// Words that point at each icon key, in Korean and English.
///
/// Each value lists terms separated by `|`. A term matches anywhere in a name,
/// except:
/// - a one-letter Korean term matches only a whole word or the end of a word
///   ("약" in "감기약", not in "약속");
/// - a term starting with `=` matches only a whole word ("=자" is a ruler, not
///   the end of "모자");
/// - an English term must start a word ("pen" in "pencil", not in "open").
///
/// When terms overlap, the longest wins ("초코파이" beats "초"). A term listed
/// under several keys points at all of them, in the order of this map.
library;

const Map<String, String> iconTerms = {
  // ── rooms ──
  'home': '=집|우리집|자택|home|house',
  'living': '거실|응접실|living',
  'kitchen': '주방|부엌|키친|kitchen',
  'dining': '식탁|다이닝|dining',
  'bedroom': '침실|안방|큰방|작은방|bedroom',
  'kids': '아이방|애기방|아기방|키즈룸|자녀방|kids room|nursery',
  'bathroom': '욕실|화장실|욕조|bathroom|restroom|toilet',
  'laundry': '세탁실|다용도실|빨래방|laundry room|utility',
  'entrance': '현관|신발장|입구|entrance|hallway|=hall|foyer',
  'balcony': '베란다|발코니|테라스|balcony|terrace|porch',
  'study': '서재|공부방|study',
  'office': '사무실|회사|직장|오피스|office|work',
  'storeroom': '창고|팬트리|=광|드레스룸 창고|storeroom|storage|pantry|attic|basement|지하실|다락',
  'garage': '차고|주차장|garage|parking',
  'garden': '정원|마당|텃밭|옥상|garden|yard',
  'car': '자동차|차량|트렁크|글러브박스|=car|cars|trunk|vehicle',
  'school': '학교|학원|유치원|어린이집|school|academy|kindergarten',
  'store': '가게|매장|상점|마트|store|shop',
  'family_home': '본가|친정|시댁|부모님 댁|부모님댁|할머니댁|할머니 댁|고향집|parents',
  // ── furniture & storage ──
  'drawer': '서랍|서랍장|협탁|drawer|dresser|nightstand',
  'shelf': '선반|책장|진열장|랙|수납 선반|shelf|shelves|bookcase|rack',
  'cabinet': '수납장|찬장|장식장|상부장|하부장|싱크대 위|싱크대 아래|신발장|캐비닛|cabinet|cupboard',
  'wardrobe': '옷장|붙박이장|드레스룸|행거|closet|wardrobe',
  'fridge': '냉장고|냉장실|김치냉장고|냉장|fridge|refrigerator',
  'freezer': '냉동고|냉동실|냉동|freezer|frozen',
  'box': '상자|박스|수납함|수납통|리빙박스|정리함|=통|함|box|bin|container|case|crate',
  'basket': '바구니|바스켓|basket|hamper',
  'bag': '가방|파우치|에코백|장바구니|쇼핑백|bag|pouch|tote',
  'desk': '책상|데스크|desk',
  'table': '테이블|탁자|거실장|티비장|tv장|table|console',
  'bed': '침대|침대 밑|침대밑|매트리스|bed|mattress',
  'tv': '티비|텔레비전|tv|television',
  'safe': '금고|safe',
  'sink': '싱크대|세면대|개수대|sink|basin',
  'first_aid_box': '구급상자|구급함|구급약통|약통|약상자|상비약|first aid|medicine box|medkit',
  // ── food ──
  'drink':
      '우유|두유|주스|쥬스|음료|음료수|탄산|탄산음료|사이다|콜라|환타|스프라이트|이온음료|포카리|게토레이|요구르트|야쿠르트|식혜|수정과|에너지드링크|핫식스|레드불|코코아|핫초코|milk|juice|soda|cola|coke|drink|beverage|lemonade|smoothie|yogurt drink',
  'water': '생수|물병|탄산수|삼다수|아이시스|에비앙|백산수|water|sparkling',
  'coffee': '커피|원두|믹스커피|커피믹스|캡슐커피|드립백|콜드브루|맥심|카누|네스프레소|돌체구스토|에스프레소|캔커피|coffee|espresso|latte|nespresso',
  'tea': '녹차|홍차|보리차|옥수수차|둥굴레차|현미녹차|허브티|캐모마일|페퍼민트|유자차|생강차|대추차|티백|=tea|teabag|matcha|chamomile',
  'wine': '와인|레드와인|화이트와인|샴페인|스파클링 와인|wine|champagne|prosecco',
  'beer': '맥주|캔맥주|생맥주|카스|테라|하이네켄|칭따오|beer|lager|=ale',
  'liquor': '소주|위스키|보드카|진로|참이슬|처음처럼|막걸리|사케|고량주|리큐르|양주|청주|복분자주|매실주|=술|liquor|whisky|whiskey|vodka|=rum|=gin|sake|soju|tequila',
  'egg': '계란|달걀|메추리알|구운란|맥반석|egg|eggs',
  'rice': '쌀|현미|잡곡|찹쌀|흑미|햇반|즉석밥|오뚜기밥|떡|떡국떡|떡볶이떡|누룽지|=밥|rice|grain|mochi',
  'noodles':
      '라면|국수|파스타|스파게티|스파게티면|소면|중면|우동|냉면|쫄면|칼국수|짜파게티|짜장라면|신라면|진라면|안성탕면|너구리|불닭|컵라면|당면|쌀국수|메밀|소바|noodle|noodles|pasta|ramen|spaghetti|udon|soba|macaroni',
  'bread':
      '빵|식빵|베이글|모닝빵|바게트|크루아상|크로와상|모닝롤|토르티야|또띠아|밀가루|부침가루|튀김가루|빵가루|핫케이크가루|피자|냉동피자|bread|bagel|toast|baguette|croissant|flour|pizza|tortilla',
  'cookie': '쿠키|비스킷|크래커|오레오|칙촉|마가렛트|cookie|biscuit|cracker',
  'cake': '케이크|케잌|머핀|카스텔라|컵케이크|마카롱|cake|muffin|cupcake',
  'icecream': '아이스크림|하겐다즈|베스킨|빙과|하드|아이스바|메로나|월드콘|빵빠레|붕어싸만코|투게더|ice cream|icecream|gelato',
  'vegetable':
      '채소|야채|양파|대파|쪽파|=파|마늘|다진마늘|생강|감자|고구마|당근|오이|호박|애호박|가지|배추|양배추|상추|깻잎|시금치|브로콜리|파프리카|피망|고추|청양고추|콩나물|숙주|버섯|팽이버섯|새송이|표고|양송이|=무|열무|부추|미나리|샐러드|양상추|케일|토마토|방울토마토|옥수수|콩|두부|순두부|김치|깍두기|단무지|피클|vegetable|veggie|onion|garlic|potato|carrot|cabbage|lettuce|spinach|tomato|mushroom|tofu|kimchi|salad|corn',
  'fruit':
      '과일|사과|=배|바나나|귤|감귤|한라봉|오렌지|레몬|라임|자몽|딸기|블루베리|포도|샤인머스캣|청포도|수박|참외|멜론|복숭아|자두|체리|키위|망고|파인애플|아보카도|석류|=감|곶감|대추|건포도|fruit|apple|banana|orange|lemon|strawberry|blueberry|grape|melon|peach|cherry|kiwi|mango|pineapple|avocado',
  'fish':
      '생선|고등어|갈치|조기|굴비|삼치|꽁치|연어|참치회|광어|명태|동태|황태|북어|코다리|오징어|문어|낙지|쭈꾸미|주꾸미|새우|대하|꽃게|=게|조개|바지락|홍합|=굴|전복|멸치|어묵|오뎅|맛살|게맛살|미역|다시마|해산물|fish|salmon|tuna steak|mackerel|shrimp|prawn|squid|octopus|crab|clam|seafood|oyster',
  'meat':
      '고기|소고기|쇠고기|한우|돼지고기|삼겹살|목살|앞다리|뒷다리|갈비|불고기|등심|안심|차돌|차돌박이|양지|사태|닭고기|닭가슴살|닭다리|닭날개|닭봉|생닭|오리고기|양고기|베이컨|소시지|햄|비엔나|훈제|육포|만두|떡갈비|돈까스|돈가스|너겟|meat|beef|pork|chicken|bacon|sausage|=ham|steak|dumpling|lamb',
  'soup': '=국|미역국|된장국|곰탕|설렁탕|육개장|사골|사골곰탕|레토르트|즉석국|=탕|찌개|카레|짜장|3분카레|수프|스프|죽|soup|stew|curry|broth|porridge',
  'snack':
      '과자|스낵|감자칩|새우깡|포카칩|꼬북칩|양파링|홈런볼|초코파이|빼빼로|프링글스|시리얼|콘푸레이크|콘프레이크|그래놀라|오트밀|견과|견과류|아몬드|호두|땅콩|캐슈넛|피스타치오|해바라기씨|팝콘|=김|조미김|구운김|김밥김|간식|snack|chips|crisps|cereal|granola|oatmeal|nuts|almond|walnut|peanut|popcorn|pretzel',
  'candy': '사탕|캔디|젤리|구미|하리보|껌|마이쮸|츄파춥스|목캔디|캐러멜|candy|gummy|gummies|jelly|=gum|lollipop|caramel',
  'chocolate': '초콜릿|초콜렛|초코|가나|페레로|킷캣|m&m|chocolate|choco',
  'can': '캔|통조림|참치|참치캔|스팸|리챔|꽁치캔|골뱅이|옥수수캔|황도|=can|canned|=tin|spam|tuna',
  'sauce':
      '소스|양념|간장|진간장|국간장|된장|고추장|쌈장|춘장|케첩|케찹|마요네즈|마요|머스타드|굴소스|액젓|멸치액젓|까나리|식초|올리고당|물엿|꿀|조청|잼|딸기잼|누텔라|땅콩버터|드레싱|소스류|데리야끼|돈까스소스|핫소스|스리라차|sauce|ketchup|mayo|mayonnaise|mustard|vinegar|soy sauce|honey|=jam|dressing|syrup sauce',
  'oil': '식용유|기름|올리브유|올리브오일|참기름|들기름|카놀라유|포도씨유|해바라기유|아보카도오일|마가린|oil|olive oil|canola|butter|margarine',
  'spice':
      '소금|천일염|맛소금|설탕|흑설탕|후추|후춧가루|고춧가루|깨|참깨|통깨|들깨|=깨|다시다|미원|치킨스톡|파슬리|바질|오레가노|시나몬|계피|카레가루|조미료|향신료|허브|salt|sugar|pepper|spice|seasoning|cinnamon|paprika|oregano|basil|msg',
  'cheese': '치즈|버터|유제품|슬라이스치즈|모짜렐라|체다|파마산|크림치즈|요거트|그릭요거트|생크림|휘핑크림|cheese|yogurt|yoghurt|cream cheese|mozzarella|cheddar|parmesan',
  // ── household ──
  'cleaning':
      '청소|청소용품|걸레|물걸레|청소포|막대걸레|밀대|빗자루|쓰레받기|먼지떨이|돌돌이|테이프클리너|락스|유한락스|곰팡이제거제|세정제|욕실세정제|변기세정제|유리세정제|다목적세정제|베이킹소다|구연산|과탄산|수세미|행주|주방세제|퐁퐁|트리오|식기세척기세제|식세기|탈취제|섬유탈취제|페브리즈|스펀지|스폰지|고무장갑|clean|cleaner|cleaning|bleach|mop|broom|sponge|scrubber|dish soap|dishwasher|gloves rubber|febreze',
  'soap': '비누|핸드워시|손세정제|샴푸|린스|컨디셔너|트리트먼트|바디워시|바디샤워|폼클렌징|클렌징폼|클렌징|soap|shampoo|conditioner|body wash|hand wash|cleanser',
  'sanitizer': '소독|손소독제|소독제|알코올솜|소독용 에탄올|에탄올|소독약@medicine|sanitizer|disinfectant|alcohol wipes',
  'tissue':
      '휴지|화장지|두루마리|두루마리휴지|롤휴지|각티슈|티슈|미용티슈|물티슈|키친타월|키친타올|키친 타월|냅킨|생리대|탐폰|팬티라이너|오버나이트|tissue|tissues|toilet paper|paper towel|napkin|wet wipes|wipes|=pad|tampon',
  'laundry_soap':
      '세제|세탁세제|가루세제|액체세제|캡슐세제|섬유유연제|유연제|다우니|피죤|표백제|산소계표백제|옥시크린|드라이시트|빨래집게|빨래망|세탁망|detergent|laundry|fabric softener|softener|downy|clothespin',
  'trash': '쓰레기|쓰레기봉투|쓰레기 봉투|종량제|종량제봉투|종량제 봉투|음식물쓰레기|음식물 쓰레기|휴지통|쓰레기통|분리수거|재활용|비닐봉지|비닐봉투|비닐|trash|garbage|rubbish|bin bag|recycling',
  'lightbulb': '전구|형광등|=led|조명|스탠드|무드등|램프|램프전구|bulb|lightbulb|lamp|light',
  'battery':
      '건전지|배터리|충전지|보조배터리@electronics|보조 배터리@electronics|=aa|=aaa|9v|코인전지|cr2032|에네루프|듀라셀|batter|battery|batteries|power bank@electronics|powerbank@electronics',
  'plug': '충전기|어댑터|아답터|멀티탭|멀티 탭|콘센트|플러그|돼지코|변환플러그|고속충전기|무선충전기|charger|adapter|plug|power strip|socket|outlet',
  'cable': '케이블|=선|충전선|충전 케이블|c타입|라이트닝|8핀|usb선|hdmi|랜선|랜 케이블|연장선|케이블타이@tools|cable|cord|wire|hdmi|=lan|lightning|usb-c',
  'umbrella': '우산|양산|우비|비옷|장우산|접이식 우산|umbrella|raincoat|parasol',
  'shower': '샤워|샤워기|샤워볼|샤워타올|면도기|면도날|면도크림|쉐이빙|때타월|목욕|입욕제|배쓰밤|shower|razor|shaver|shaving|bath bomb',
  'fan': '선풍기|서큘레이터|에어컨|에어컨 리모컨|공기청정기|가습기|히터|온풍기|난로|전기난로|라디에이터|fan|circulator|air conditioner|heater|purifier|humidifier',
  'candle': '초|향초|양초|캔들|디퓨저|방향제|인센스|=향|룸스프레이|candle|diffuser|incense|air freshener',
  'toothbrush': '칫솔|전동칫솔|치실|치간칫솔|혀클리너|칫솔모|toothbrush|floss',
  'toothpaste': '치약|가그린|구강청결제|리스테린|페리오|toothpaste|mouthwash|listerine',
  'mosquito': '모기|모기향|모기약|홈매트|에프킬라|살충제|바퀴벌레약|컴배트|해충|벌레|모기장|mosquito|insect|bug spray|insecticide|repellent',
  'hanger': '옷걸이|바지걸이|행거|hanger|hangers',
  'cosmetics':
      '화장품|손톱깎이|손톱깍이|발톱깎이|손톱|nail clipper|스킨|토너|로션|에센스|세럼|크림|수분크림|선크림|썬크림|자외선차단제|립밤|립스틱|틴트|파운데이션|쿠션|비비크림|마스카라|아이섀도|아이라이너|매니큐어|네일|화장솜|면봉|마스크팩|핸드크림|바디크림|바디로션|향수|헤어에센스|왁스|헤어젤|헤어스프레이|고데기|드라이기|헤어드라이어|=빗|cosmetic|cosmetics|makeup|lotion|cream|sunscreen|lipstick|lip balm|perfume|toner|serum|foundation|mascara|nail polish|cotton pad|cotton swab|hair dryer|comb',
  'vacuum': '청소기|무선청소기|로봇청소기|청소기 필터|청소기 먼지봉투|다이슨|vacuum|roomba|dyson',
  'sewing': '바느질|반짇고리|=실|바늘|재봉틀|단추|옷핀|안전핀|sewing|needle|thread|button|safety pin',
  'linens':
      '수건|타월|타올|이불|이불커버|=요|토퍼|베개|베개커버|쿠션커버|담요|블랭킷|극세사|전기장판|전기요|온수매트|침구|침대커버|매트리스커버|towel|towels|blanket|duvet|comforter|pillow|pillowcase|sheet|bedding|quilt',
  'wrap':
      '지퍼백|위생백|위생팩|랩|비닐랩|호일|쿠킹호일|알루미늄호일|종이호일|쿠킹시트|유산지|위생장갑|비닐장갑|일회용 장갑|밀폐용기|락앤락|반찬통|wrap|cling|foil|ziploc|zip bag|freezer bag|parchment|tupperware',
  'dehumidifier': '제습제|물먹는하마|습기제거제|제습기|실리카겔|방습제|dehumidifier|desiccant|silica',
  // ── tools ──
  'scissors': '가위|커터|커터칼|칼|문구용 칼|과도|scissor|scissors|cutter|box cutter|knife',
  'tape':
      '테이프|박스테이프|박스 테이프|투명테이프|스카치테이프|양면테이프|마스킹테이프|절연테이프|청테이프|덕트테이프|글루건|글루스틱|순간접착제|본드|접착제|딱풀|=풀|실리콘|tape|scotch tape|duct tape|glue|glue gun|super glue|adhesive|silicone',
  'ruler': '줄자|=자|자 30cm|쇠자|각도기|수평계|ruler|tape measure|measuring tape|level',
  'wrench': '렌치|스패너|몽키스패너|육각렌치|펜치|니퍼|플라이어|롱노즈|드라이버|십자드라이버|일자드라이버|wrench|spanner|pliers|allen key|hex key|screwdriver',
  'hammer': '망치|고무망치|해머|hammer|mallet',
  'toolbox': '공구|공구함|공구통|공구세트|공구 세트|연장|드릴|전동드릴|전동 드릴|드릴비트|타카|그라인더|tool|tools|toolbox|toolkit|drill',
  'saw': '톱|실톱|쇠톱|=saw|hacksaw',
  'paint': '페인트|붓|롤러|페인트붓|사포|퍼티|젯소|스프레이 페인트|paint|brush|roller|sandpaper|putty',
  'flashlight': '손전등|후레쉬|플래시|랜턴|헤드랜턴|헤드램프|비상등|flashlight|torch|lantern|headlamp',
  'key': '열쇠|=키|보조키|카드키|도어키|차키|자동차 키|key|keys',
  'lock': '자물쇠|자전거 자물쇠|번호자물쇠|와이어락|lock|padlock',
  'pin': '압정|=못|핀|꾹꾹이|=클립|집게|=pin|pins|pushpin|thumbtack|nail|clip',
  'screw': '나사|피스|볼트|너트|와셔|앵커|칼블럭|screw|screws|bolt|=nut|washer|anchor',
  'ladder': '사다리|접이식 사다리|발판|스텝스툴|ladder|step stool',
  'plumbing': '배관|뚫어뻥|뚫어펑|배수구|트랩|하수구|수전|plumbing|plunger|drain',
  'electric': '전기|두꺼비집|차단기|전선|전기테이프|테스터기|electric|electrical|breaker',
  // ── health ──
  'pill':
      '약|알약|상비약|감기약|두통약|진통제|해열제|소화제|위장약|지사제|변비약|알러지약|알레르기약|항히스타민|수면제|멀미약|타이레놀|게보린|펜잘|애드빌|이지엔|부루펜|판콜|판피린|베아제|훼스탈|까스활명수|활명수|겔포스|스멕타|지르텍|처방약|medicine|pill|pills|tablet medicine|painkiller|tylenol|advil|ibuprofen|aspirin|antacid|allergy',
  'syrup': '시럽|물약|해열제 시럽|기침시럽|부루펜시럽|챔프|syrup|liquid medicine|cough syrup',
  'bandage': '밴드|대일밴드|메디폼|반창고|붕대|거즈|압박붕대|습윤밴드|파스|쿨파스|핫파스|신신파스|=패치|band|bandage|band-aid|gauze|plaster|patch',
  'ointment': '연고|후시딘|마데카솔|바세린|비판텐|리도맥스|라미실|오라메디|크림 연고|상처연고|ointment|vaseline|antibiotic cream',
  'syringe': '주사|주사기|인슐린|펜니들|syringe|insulin|injection',
  'thermometer': '체온계|온도계|귀체온계|thermometer',
  'mask': '마스크|kf94|kf80|덴탈마스크|덴탈 마스크|일회용 마스크|mask|masks|n95',
  'vitamin':
      '비타민|종합비타민|멀티비타민|영양제|오메가3|오메가 3|유산균|프로바이오틱스|루테인|밀크씨슬|마그네슘|칼슘|철분|아연|홍삼|홍삼정|정관장|콜라겐|프로폴리스|vitamin|vitamins|multivitamin|supplement|omega|probiotic|probiotics|lutein|magnesium|calcium',
  'heart': '혈압|혈압계|혈당|혈당계|혈당측정기|체중계|인바디|맥박|blood pressure|glucose|scale',
  'eye_drops': '안약|인공눈물|점안액|렌즈세척액|식염수|eye drops|eyedrops|saline',
  // ── clothes ──
  'top': '상의|긴팔|후드|후드티|맨투맨|니트|스웨터|블라우스|나시|민소매|=탑|크롭|조끼|베스트|잠옷|파자마|=top|tops|hoodie|sweater|sweatshirt|blouse|knit|=vest|pajamas|pyjamas',
  'tshirt': '티셔츠|반팔|반팔티|=티|면티|t-shirt|tshirt|=tee',
  'pants': '바지|하의|청바지|슬랙스|레깅스|조거|트레이닝복|츄리닝|면바지|정장바지|pants|jeans|trousers|leggings|slacks|joggers',
  'shorts': '반바지|숏팬츠|5부바지|shorts',
  'underwear': '속옷|팬티|브라|브래지어|런닝|러닝셔츠|내복|내의|드로즈|underwear|=bra|briefs|boxers|lingerie',
  'dress': '원피스|드레스|수영복|비키니|한복|dress|swimsuit|bikini|gown',
  'skirt': '치마|스커트|skirt',
  'socks': '양말|스타킹|덧신|발목양말|니삭스|sock|socks|stockings|tights',
  'coat': '외투|패딩|코트|자켓|재킷|점퍼|잠바|바람막이|가디건|카디건|야상|롱패딩|경량패딩|목도리|머플러|스카프|장갑|털장갑|coat|jacket|parka|cardigan|scarf|muffler|gloves|mittens',
  'shirt': '셔츠|와이셔츠|남방|정장|양복|수트|넥타이|타이|벨트|허리띠|shirt|suit|=tie|necktie|belt',
  'shoes': '신발|운동화|스니커즈|구두|로퍼|샌들|슬리퍼|쪼리|부츠|장화|레인부츠|등산화|축구화|실내화|하이힐|=힐|크록스|shoe|shoes|sneakers|boots|sandals|slippers|heels|loafers',
  'hat': '모자|캡모자|야구모자|비니|버킷햇|벙거지|썬캡|=hat|hats|=cap|caps|beanie',
  'glasses': '안경|선글라스|썬글라스|안경집|돋보기|콘택트렌즈|렌즈|glasses|sunglasses|eyeglasses|contact lens',
  'handbag': '지갑|핸드백|숄더백|크로스백|클러치|명품가방|카드지갑|동전지갑|wallet|purse|handbag|clutch',
  'backpack': '백팩|책가방|배낭|등산가방|backpack|rucksack|schoolbag',
  'watch': '시계|손목시계|스마트워치@electronics|애플워치@electronics|갤럭시워치@electronics|watch|smartwatch@electronics',
  'jewelry': '반지|목걸이|귀걸이|팔찌|발찌|브로치|액세서리|악세서리|귀금속|금반지|진주|jewel|jewelry|jewellery|ring|necklace|earrings|bracelet',
  'iron': '다리미|스팀다리미|다림판|iron|ironing',
  // ── family ──
  'dad': '아빠|남편|아버지|dad|father|husband',
  'mom': '엄마|아내|어머니|부인|mom|mother|wife',
  'boy': '아들|=형|오빠|남동생|son|brother|boy',
  'girl': '=딸|누나|언니|여동생|daughter|sister|girl',
  'grandpa': '할아버지|grandpa|grandfather',
  'grandma': '할머니|grandma|grandmother',
  'family': '가족|family',
  'person': '친구|빌려줌|빌려|대여|lent|loan|friend|neighbor|이웃',
  // ── pets ──
  'pet':
      '반려|반려동물|애완|애완동물|=펫|배변패드|배변봉투|하네스|목줄|리드줄|켄넬|이동장|펫드라이룸|고양이 모래|고양이모래|두부모래|벤토나이트|거북|거북이|도마뱀|파충류|=물고기|열대어|pet|pets|leash|harness|kennel|litter|turtle|lizard',
  'dog': '강아지|=개|애견|반려견|멍멍이|댕댕이|개껌|dog|puppy',
  'cat': '고양이|냥이|반려묘|캣타워|스크래처|숨숨집|=cat|cats|kitten|scratcher',
  'hamster': '햄스터|토끼|기니피그|톱밥|hamster|rabbit|bunny|guinea pig',
  'bird': '=새|앵무|앵무새|새장|새 모이|새모이|조류|카나리아|bird|parrot|birdseed',
  'pet_food': '사료|강아지 간식|고양이 간식|츄르|캔사료|습식사료|건사료|져키|개밥|금붕어 밥|금붕어밥|물고기 밥|물고기밥|pet food|dog food|cat food|kibble|treats',
  'aquarium': '어항|수조|금붕어|구피|여과기|aquarium|fish tank|goldfish',
  // ── devices ──
  'phone': '휴대폰|핸드폰|스마트폰|=폰|아이폰|갤럭시|공기계|phone|iphone|galaxy|smartphone|mobile',
  'laptop': '노트북|맥북|=그램|랩탑|컴퓨터|데스크탑|본체|laptop|macbook|computer|=pc|desktop',
  'tablet': '태블릿|아이패드|갤럭시탭|갤탭|전자책|이북리더|킨들|tablet|ipad|kindle|e-reader',
  'headphones': '이어폰|헤드폰|헤드셋|에어팟|버즈|갤럭시버즈|무선 이어폰|무선이어폰|블루투스 이어폰|headphone|headphones|earphone|earphones|earbuds|airpods|headset',
  'camera': '카메라|디카|디지털카메라|캠코더|액션캠|고프로|미러리스|dslr|폴라로이드|camera|camcorder|gopro|polaroid',
  'game': '게임|게임기|닌텐도|스위치|플스|플레이스테이션|엑스박스|조이콘|컨트롤러|game|games|nintendo|switch|playstation|ps5|ps4|xbox|controller|joystick',
  'speaker': '스피커|블루투스 스피커|사운드바|라디오|speaker|soundbar|radio',
  'printer': '프린터|복합기|잉크|카트리지|스캐너|printer|ink|cartridge|scanner',
  'router': '공유기|와이파이|모뎀|셋톱박스|router|wifi|modem|set-top',
  'keyboard': '키보드|keyboard',
  'mouse': '마우스|마우스패드|mouse|mousepad',
  'usb': 'usb|usb메모리|usb 메모리|외장하드|외장 하드|ssd|하드디스크|hdd|flash drive|thumb drive|external drive',
  'memory_card': '메모리|메모리카드|sd카드|sd 카드|마이크로sd|memory card|sd card|microsd',
  'remote': '리모컨|리모콘|remote|remote control',
  'monitor': '모니터|monitor|display|screen',
  // ── papers ──
  'document':
      '서류|문서|계약서|임대차|등기|등기부등본|보증서|증명서|가족관계증명서|등본|초본|졸업장|졸업증명서|성적표|자격증|상장|보험|보험증권|보험증서|세금|고지서|청구서|명세서|설명서|사용설명서|매뉴얼|파일철|클리어파일|document|documents|paper|papers|contract|certificate|warranty|manual|insurance|invoice',
  'book': '책|도서|동화책@kids|그림책@kids|소설|만화책|만화|잡지|교과서|문제집|참고서|사전|앨범책|book|books|novel|comic|magazine|textbook',
  'notebook': '노트|공책|수첩|다이어리|메모지|포스트잇|플래너|스프링노트|notebook|notepad|diary|planner|post-it|sticky notes',
  'pen': '펜|볼펜|연필|샤프|샤프심|색연필|형광펜|매직|네임펜|사인펜|지우개|필통|만년필|pen|pens|pencil|marker|highlighter|eraser|pencil case',
  'mail': '편지|우편|택배|엽서|우표|편지봉투|mail|letter|postcard|stamp|envelope',
  'photo': '사진|앨범|사진앨범|액자|인화|photo|photos|album|picture|frame',
  'receipt': '영수증|보관 영수증|receipt|receipts',
  'id_card': '여권|신분증|주민등록증|주민증|운전면허증|면허증|학생증|사원증|외국인등록증|passport|id card|license|licence',
  'card': '카드|신용카드|체크카드|교통카드|티머니|멤버십카드|포인트카드|credit card|debit card|card',
  'money': '현금|=돈|용돈|동전|지폐|외화|달러|엔화|통장|저금통|cash|money|coin|coins|bankbook|piggy bank',
  'gift': '선물|상품권@papers|기프트카드@papers|쿠폰@papers|기프티콘@papers|gift|gift card|voucher|coupon|present',
  'ticket': '티켓|입장권|공연 티켓|공연티켓|영화표|기차표|항공권|=표|ticket|tickets|boarding pass',
  // ── hobby ──
  'ball': '공|축구공|농구공|배구공|야구공|야구|축구|농구|배구|글러브|야구 글러브|ball|soccer|football|basketball|baseball|volleyball',
  'tennis': '테니스|배드민턴|라켓|셔틀콕|탁구|탁구채|스쿼시|tennis|badminton|racket|racquet|shuttlecock|ping pong',
  'fitness': '운동|헬스|덤벨|아령|케틀벨|요가|요가매트|폼롤러|짐볼|줄넘기|필라테스|저항밴드|철봉|gym|fitness|dumbbell|yoga|kettlebell|foam roller|jump rope',
  'bike': '자전거|헬멧|킥보드|퀵보드|인라인|롤러스케이트|스케이트보드|bike|bicycle|scooter|skateboard|rollerblade|helmet',
  'music': '악기|=기타|통기타|일렉기타|우쿨렐레|피아노|바이올린|첼로|플루트|리코더|하모니카|드럼|music|guitar|ukulele|piano|violin|flute|recorder|drum',
  'art': '그림|미술|물감|수채화|크레파스@kids|크레용@kids|파스텔|스케치북|도화지|캔버스|이젤|색종이|점토|클레이|=art|paint set|crayon|crayons|sketchbook|canvas|clay',
  'plant': '화분|식물|다육이|선인장|씨앗|모종|분갈이흙|비료|흙|물조리개|plant|plants|pot plant|seed|seeds|succulent|cactus|soil',
  'suitcase': '캐리어|여행|여행가방|여행용|트렁크 가방|suitcase|travel|luggage',
  'beach': '해변|비치|튜브|물놀이|돗자리|파라솔|beach|float|picnic mat',
  'tent': '캠핑|텐트|타프|침낭|코펠|버너|가스버너|부탄가스|캠핑의자|캠핑 의자|아이스박스|쿨러|camping|tent|sleeping bag|stove|cooler',
  'fishing': '낚시|낚싯대|낚시대|=릴|미끼|fishing|fishing rod',
  'golf': '골프|골프공|골프채|골프백|퍼터|golf|golf ball|golf club|putter',
  'christmas': '크리스마스|트리|크리스마스트리|크리스마스 트리|오너먼트|성탄|산타|christmas|xmas|ornament',
  'party': '파티|풍선|생일|고깔|폭죽|가랜드|party|balloon|balloons|birthday',
  'star': '즐겨찾기|=star',
  'heart_fav': '소중한|추억|favorite|favourite',
  // ── kids ──
  'baby': '아기|아가|유아|신생아|베이비|아기띠|힙시트|카시트|이유식|턱받이|공갈젖꼭지|쪽쪽이|아기 물티슈|baby|infant|toddler|car seat|pacifier|=bib',
  'diaper': '기저귀|팬티기저귀|하기스|팸퍼스|diaper|diapers|nappy',
  'baby_bottle': '젖병|분유|분유통|젖병솔|젖꼭지|formula|baby bottle|bottle nipple',
  'stroller': '유모차|휴대용 유모차|웨건|stroller|pram|buggy',
  'toy': '장난감|인형|곰인형|봉제인형|피규어|미니카|장난감 자동차|로봇|팽이|공룡|슬라임|toy|toys|=doll|dolls|teddy|figure|action figure',
  'puzzle': '퍼즐|레고|블록|블럭|보드게임@hobby|체스@hobby|바둑@hobby|카드게임@hobby|큐브|puzzle|lego|blocks|board game@hobby|chess@hobby|rubik',
  // ── other ──
  'other': '기타 물건|그 밖의|=other|misc',
};

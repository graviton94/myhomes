// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '우리집요정';

  @override
  String get fairyName => '집요정';

  @override
  String get myHome => '우리 집';

  @override
  String get navHome => '홈';

  @override
  String get navSpaces => '공간';

  @override
  String get navSearch => '검색';

  @override
  String get navExpiry => '소비기한';

  @override
  String get navFamily => '가족';

  @override
  String get homeGreeting => '안녕하세요! 물건 위치는 제가 기억할게요.';

  @override
  String get searchHint => '무엇을 찾을까요? (초성도 돼요)';

  @override
  String get homeEmptyTitle => '우리 집 지도를 만들어 볼까요';

  @override
  String get homeEmptyBody => '거실이나 주방처럼 방 하나부터 시작해요. 그다음 그 안의 서랍과 선반을 넣으면 돼요.';

  @override
  String get addSpace => '공간 추가';

  @override
  String get spacesEmptyTitle => '아직 공간이 없어요';

  @override
  String get spacesEmptyBody => '추가한 방과 그 안의 보관함이 여기에 보여요.';

  @override
  String get searchEmptyTitle => '아직 찾을 물건이 없어요';

  @override
  String get searchEmptyBody => '물건을 넣고 이름을 입력하면 어디 있는지 바로 알려 드릴게요.';

  @override
  String get expiryEmptyTitle => '곧 기한이 끝나는 물건이 없어요';

  @override
  String get expiryEmptyBody => '식품이나 약에 소비기한을 넣으면 D-3, D-1, 당일에 알려 드릴게요.';

  @override
  String get familyEmptyTitle => '우리 집을 함께 써요';

  @override
  String get familyEmptyBody => '가족을 초대하면 모두가 물건을 찾고 수량을 함께 맞출 수 있어요.';

  @override
  String get comingSoon => '다음 빌드에서 만나요.';

  @override
  String get settings => '설정';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '휴대폰 설정 따르기';

  @override
  String get theme => '화면 테마';

  @override
  String get themeSystem => '휴대폰 설정 따르기';

  @override
  String get themeLight => '밝게';

  @override
  String get themeDark => '어둡게';

  @override
  String get about => '정보';

  @override
  String version(String version) {
    return '버전 $version';
  }

  @override
  String get sampleColors => '색';

  @override
  String get sampleType => '글꼴';

  @override
  String get sampleParts => '부품';

  @override
  String get sampleFairy => '집요정';

  @override
  String get sampleButtonPrimary => '옮기기';

  @override
  String get sampleButtonSecondary => '수정';

  @override
  String get sampleButtonText => '취소';

  @override
  String get sampleCategoryFood => '식품';

  @override
  String get sampleCategoryHousehold => '생활용품';

  @override
  String get sampleCategoryTools => '공구';

  @override
  String get sampleCategoryMedicine => '의약품';

  @override
  String get sampleSlotEmpty => '빈 칸';

  @override
  String get sampleSlotFilled => '건전지 AA, 8개';

  @override
  String get sampleSlotSelected => '선택됨';

  @override
  String get sampleSlotExpiring => '우유, 기한 임박';

  @override
  String get sampleSlotChosen => '8개 중 4개 고름';

  @override
  String get fairyHello => '안녕!';

  @override
  String get fairyFound => '찾았다!';

  @override
  String get fairyCarry => '영차';

  @override
  String get fairyWorry => '어떡해';

  @override
  String get fairyCheer => '잘했어요';

  @override
  String get fairySleep => '쿨쿨';

  @override
  String expiryOverdue(int days) {
    return '$days일 지남';
  }

  @override
  String get expiryToday => '오늘까지';

  @override
  String get expiryTomorrow => '내일까지';

  @override
  String expiryDaysLeft(int days) {
    return 'D-$days';
  }

  @override
  String get expiryOk => '여유';

  @override
  String get splashLoading => '요정을 깨우는 중...';

  @override
  String get skip => '건너뛰기';

  @override
  String get next => '다음';

  @override
  String get getStarted => '시작하기';

  @override
  String pageOf(int page, int total) {
    return '$total쪽 중 $page쪽';
  }

  @override
  String get intro1Title => '물어보면 바로 찾아요';

  @override
  String get intro1Body => '검색창 하나에 쓰거나 말하세요. 이름이 조금 달라도 요정이 뜻으로 찾아 줘요.';

  @override
  String get intro2Title => '한 문장으로 넣어요';

  @override
  String get intro2Body => '자리를 고르고 넣을 물건을 한 번에 쓰세요. 같은 이름은 알아서 합쳐요.';

  @override
  String get intro3Title => '가족과 같이 채워요';

  @override
  String get intro3Body => '로그인하면 가족을 초대할 수 있어요. 각자 자기 방만 채워도 집 전체가 완성돼요.';

  @override
  String get loginTagline => '우리 집 물건, 요정이 기억해요.';

  @override
  String get loginKakao => '카카오 로그인';

  @override
  String get loginNaver => '네이버 로그인';

  @override
  String get loginGoogle => 'Google로 계속하기';

  @override
  String get loginSoon => '곧 열려요';

  @override
  String get or => '또는';

  @override
  String get startWithoutAccount => '계정 없이 시작하기';

  @override
  String get guestNote => '모든 정보는 이 휴대폰에만 저장돼요. 나중에 로그인하면 가족과 함께 쓸 수 있어요.';

  @override
  String get cancel => '취소';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get edit => '수정';

  @override
  String get more => '더 보기';

  @override
  String get close => '닫기';

  @override
  String get clear => '지우기';

  @override
  String get undo => '되돌리기';

  @override
  String get change => '바꾸기';

  @override
  String get choose => '선택';

  @override
  String get seeAll => '모두 보기';

  @override
  String get send => '보내기';

  @override
  String get increase => '늘리기';

  @override
  String get decrease => '줄이기';

  @override
  String get actionAdd => '추가';

  @override
  String get actionMove => '이동';

  @override
  String get actionTakeOut => '빼기';

  @override
  String get makeStorageFirst => '먼저 공간과 보관함을 만들어 주세요.';

  @override
  String get addWhere => '어디에 넣을까요?';

  @override
  String get moveFromWhere => '어디에서 옮길까요?';

  @override
  String get takeOutFromWhere => '어디에서 뺄까요?';

  @override
  String eatFirst(int count) {
    return '먼저 챙기기 · $count개';
  }

  @override
  String itemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '물건 $count개',
      zero: '비어 있음',
    );
    return '$_temp0';
  }

  @override
  String spaceSummary(int storages, int items) {
    return '보관함 $storages개 · 물건 $items개';
  }

  @override
  String get addStorage => '보관함 추가';

  @override
  String get editStorage => '보관함 수정';

  @override
  String get spaceNameHint => '이름 (예: 주방)';

  @override
  String get storageNameHint => '이름 (예: 서랍 2칸)';

  @override
  String get spaceEmptyTitle => '아직 보관함이 없어요';

  @override
  String get spaceEmptyBody => '이 방의 서랍, 선반, 상자를 추가해 보세요.';

  @override
  String deleteSpaceTitle(String name) {
    return '$name을(를) 삭제할까요?';
  }

  @override
  String get deleteSpaceBody => '이 공간의 보관함과 물건도 모두 삭제돼요.';

  @override
  String deleteStorageTitle(String name) {
    return '$name을(를) 삭제할까요?';
  }

  @override
  String deleteStorageBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '안에 있는 물건 $count개도 삭제돼요.',
      zero: '비어 있는 보관함이에요.',
    );
    return '$_temp0';
  }

  @override
  String get noStorageYet => '아직 보관함이 없어요. 공간에서 추가해 주세요.';

  @override
  String get recentPlaces => '최근 쓴 곳';

  @override
  String get storageHint =>
      '빈 칸을 누르면 추가, 물건을 누르면 빼기·이동이에요. 물건을 꾹 눌러 다른 칸으로 끌면 옮겨지고, 꾹 눌렀다 떼면 여러 개를 고를 수 있어요.';

  @override
  String get selectHint => '물건을 눌러 고르고 수량을 정하세요.';

  @override
  String get pickSeveral => '여러 개 고르기';

  @override
  String get pickItems => '물건 고르기';

  @override
  String pickedSummary(int kinds, int total) {
    return '$kinds종류 $total개';
  }

  @override
  String get moveToWhere => '어디로 옮길까요?';

  @override
  String movedTo(int count, String name) {
    return '$name(으)로 $count개 옮겼어요';
  }

  @override
  String tookOut(int count) {
    return '$count개 뺐어요';
  }

  @override
  String get usedUp => '다 씀';

  @override
  String usedUpKinds(int count) {
    return '$count종류를 다 썼어요';
  }

  @override
  String usedUpName(String name) {
    return '$name 다 썼어요';
  }

  @override
  String get emptySlot => '빈 칸';

  @override
  String slotLabel(String name, int count) {
    return '$name, $count개';
  }

  @override
  String howMany(String name) {
    return '$name 몇 개?';
  }

  @override
  String youHave(int count) {
    return '$count개 있어요.';
  }

  @override
  String get qtyOne => '1개';

  @override
  String qtyHalf(int count) {
    return '절반 ($count)';
  }

  @override
  String qtyAll(int count) {
    return '전부 ($count)';
  }

  @override
  String get deselect => '선택 해제';

  @override
  String qtyShort(int count) {
    return '$count개';
  }

  @override
  String get addItem => '물건 추가';

  @override
  String get editItem => '물건 수정';

  @override
  String get photo => '사진';

  @override
  String get takePhoto => '사진 찍기';

  @override
  String get chooseFromGallery => '앨범에서 고르기';

  @override
  String get removePhoto => '사진 빼기';

  @override
  String get itemName => '이름';

  @override
  String get nameRequired => '이름을 넣어 주세요';

  @override
  String get category => '종류';

  @override
  String get categoryFood => '식품';

  @override
  String get categoryHousehold => '생활용품';

  @override
  String get categoryTools => '공구';

  @override
  String get categoryMedicine => '약';

  @override
  String get categoryOther => '기타';

  @override
  String get quantity => '수량';

  @override
  String get useBy => '기한';

  @override
  String get dueNone => '없음';

  @override
  String dueDays(int count) {
    return '$count일';
  }

  @override
  String get dueWeek => '1주';

  @override
  String get dueMonth => '1달';

  @override
  String get duePick => '날짜 고르기';

  @override
  String useByDate(String date) {
    return '기한 $date';
  }

  @override
  String get place => '위치';

  @override
  String get putWhere => '어디에 둘까요?';

  @override
  String get chooseAPlace => '위치를 골라 주세요';

  @override
  String get note => '메모';

  @override
  String get noteHint => '브랜드, 크기, 누구 것인지...';

  @override
  String get saveAndNext => '저장하고 계속';

  @override
  String addedName(String name) {
    return '$name 추가했어요';
  }

  @override
  String deletedName(String name) {
    return '$name 삭제했어요';
  }

  @override
  String get recentItems => '최근 물건';

  @override
  String get searchTip => '팁: 초성(ㄱㅇ)이나 위치 코드(예: LIV-A1)로도 찾을 수 있어요.';

  @override
  String noResultsTitle(String query) {
    return '\"$query\"은(는) 아직 없어요';
  }

  @override
  String get noResultsBody => '맞춤법을 확인하거나, 두는 곳에 추가해 보세요.';

  @override
  String resultsCount(int count) {
    return '$count개 찾았어요';
  }

  @override
  String get groupOverdue => '기한 지남';

  @override
  String get groupSoon => '3일 안';

  @override
  String get groupLater => '나중에';

  @override
  String get askFairy => '집요정에게 물어보기';

  @override
  String askFairyWithBadge(int count) {
    return '집요정에게 물어보기, 확인할 것 $count개';
  }

  @override
  String get fairySubtitle => '물건 위치를 물어보세요';

  @override
  String get askFairyHint => '예: 건전지 어디 있어?';

  @override
  String get fairyGreeting => '안녕하세요! 뭐든 어디 있는지 물어보세요.';

  @override
  String fairyGreetingUrgent(int count) {
    return '안녕하세요! 곧 챙겨야 할 물건이 $count개 있어요.';
  }

  @override
  String fairyFoundCount(int count) {
    return '$count개 찾았어요!';
  }

  @override
  String fairyNotFound(String query) {
    return '\"$query\"은(는) 못 찾았어요. 다른 이름으로 넣었나요?';
  }

  @override
  String get chipThisWeek => '이번 주 챙길 것';

  @override
  String get chipRunningLow => '얼마 안 남은 것';

  @override
  String get chipHowTo => '어떻게 써요?';

  @override
  String fairyThisWeek(int count) {
    return '이번 주에 챙길 물건 $count개예요.';
  }

  @override
  String get fairyNothingThisWeek => '이번 주에 챙길 건 없어요.';

  @override
  String fairyLow(int count) {
    return '마지막 하나 남은 물건이 $count개예요.';
  }

  @override
  String get fairyNothingLow => '얼마 안 남은 물건은 없어요.';

  @override
  String get fairyHowTo =>
      '공간(방)을 만들고 그 안에 보관함을 추가한 뒤, 빈 칸을 눌러 물건을 넣어요. 물건을 길게 누르면 여러 개를 한 번에 옮길 수 있어요.';

  @override
  String get goSee => '보러 가기';

  @override
  String get dataSection => '데이터';

  @override
  String get showIntroAgain => '소개 화면 다시 보기';

  @override
  String get deleteAllData => '이 휴대폰의 데이터 모두 삭제';

  @override
  String get deleteAllBody => '이 휴대폰의 공간, 보관함, 물건이 모두 삭제돼요. 되돌릴 수 없어요.';

  @override
  String get allDeleted => '모든 데이터를 삭제했어요';

  @override
  String get editSpace => '공간 수정';

  @override
  String get addPhoto => '사진 추가';

  @override
  String get addPhotoOptional => '사진 추가 (선택)';

  @override
  String get changePhoto => '바꾸기';

  @override
  String get icon => '아이콘';

  @override
  String get moreIcons => '더 보기';

  @override
  String get chooseIcon => '아이콘 고르기';

  @override
  String get iconGroupRooms => '방';

  @override
  String get iconGroupFurniture => '가구 · 수납';

  @override
  String get iconGroupFood => '음식 · 음료';

  @override
  String get iconGroupHousehold => '생활용품';

  @override
  String get iconGroupTools => '공구';

  @override
  String get iconGroupHealth => '건강';

  @override
  String get iconGroupClothes => '옷 · 소품';

  @override
  String get iconGroupDevices => '전자기기';

  @override
  String get iconGroupPapers => '서류 · 돈';

  @override
  String get iconGroupHobby => '취미 · 기타';

  @override
  String get addSpaceShort => '방';

  @override
  String editSpaceNamed(String name) {
    return '$name 수정';
  }

  @override
  String deleteSpaceNamed(String name) {
    return '$name 삭제';
  }

  @override
  String get moveHere => '여기로';

  @override
  String get openStorage => '크게 보기';

  @override
  String get boardMoveHint => '옮길 보관함의 “여기로”를 누르거나, 이동으로 다른 곳을 고르세요.';

  @override
  String get boardFirstStorageHint =>
      '이 방의 서랍, 선반, 상자를 추가하세요. 그 칸들이 바로 여기에 보여요.';

  @override
  String get outsideHome => '집 밖';

  @override
  String get addOutside => '집 밖 장소 추가';

  @override
  String get addOutsideShort => '집 밖';

  @override
  String get outsideNameHint => '이름 (예: 자동차, 회사, 빌려줌)';

  @override
  String get outsideStorageHint => '이름 (예: 트렁크, 민수에게 빌려줌)';

  @override
  String get returnByOptional => '돌려받을 날 (선택)';

  @override
  String returnOverdue(int days) {
    return '$days일 지남';
  }

  @override
  String get returnToday => '오늘 돌려받기';

  @override
  String returnDaysLeft(int days) {
    return '$days일 뒤 돌려받기';
  }

  @override
  String get groupReturns => '돌려받을 것';

  @override
  String get iconGroupFamily => '가족';

  @override
  String get iconGroupPets => '반려동물';

  @override
  String get hereNow => '지금 여기';

  @override
  String get newStorageHere => '새 보관함';

  @override
  String deleteStorageNamed(String name) {
    return '$name 삭제';
  }

  @override
  String get dockHint => '방 위에 잠깐 올려두면 열려요 · 바로 놓으면 그 방으로';

  @override
  String get dockNoOtherRooms => '다른 방이나 집 밖 장소를 추가하면 여기로 옮길 수 있어요';

  @override
  String get smartApplied => '요정이 종류와 아이콘을 골랐어요. 틀리면 바꿔 주세요.';

  @override
  String get smartFound => '요정이 찾았어요';

  @override
  String get smartMaybe => '혹시 이건가요?';

  @override
  String get loginFailed => '로그인하지 못했어요. 다시 해 볼까요?';

  @override
  String loginWelcome(String name) {
    return '$name님, 반가워요!';
  }

  @override
  String get accountSection => '계정';

  @override
  String get accountGuest => '게스트';

  @override
  String get accountGuestBody => '모든 정보는 이 휴대폰에만 있어요.';

  @override
  String accountWith(String provider) {
    return '$provider로 로그인함';
  }

  @override
  String get providerKakao => '카카오';

  @override
  String get providerNaver => '네이버';

  @override
  String get providerGoogle => 'Google';

  @override
  String get signIn => '로그인';

  @override
  String get signOut => '로그아웃';

  @override
  String get signOutBody => '휴대폰에 저장된 물건은 그대로 남아요.';

  @override
  String get signedOut => '로그아웃했어요. 휴대폰에 저장된 물건은 그대로예요.';

  @override
  String loginFailedWhy(String reason) {
    return '로그인하지 못했어요 ($reason)';
  }

  @override
  String get sentenceTitle => '넣기';

  @override
  String get sentencePickOther => '다른 곳';

  @override
  String get sentenceWhat => '무엇을 넣나요? 쉼표나 “랑”으로 이어 쓰세요.';

  @override
  String get sentenceHint => '가위, 박스테이프랑 AA 건전지 4개';

  @override
  String get sentenceVoice => '키보드 마이크로 말해도 돼요';

  @override
  String sentenceMerge(String name, int have, int total) {
    return '이미 있는 $name ×$have에 더해 ×$total';
  }

  @override
  String sentenceSave(int count) {
    return '$count개 넣기';
  }

  @override
  String sentenceSaved(int count, String place) {
    return '$place에 $count개 넣었어요';
  }

  @override
  String get sentenceDetails => '사진 · 기한과 함께 하나씩 넣기';

  @override
  String get sentenceNoPlace => '넣을 곳을 먼저 골라 주세요';

  @override
  String get introDemoQuery => '건전지 어딨어?';

  @override
  String get introDemoItem => 'AA 건전지 ×8';

  @override
  String get introDemoSentence => '가위, 박스테이프랑 AA 건전지 4개';

  @override
  String get introDemoFamily1 => '엄마 · 안방';

  @override
  String get introDemoFamily2 => '아빠 · 베란다';

  @override
  String get introDemoFamily3 => '지우 · 아이방';

  @override
  String get introDemoInvite => '+ 초대';

  @override
  String get introDemoRoom => '거실';

  @override
  String get introDemoStorage => 'TV장';

  @override
  String get introDemoSpot => '왼쪽 서랍';

  @override
  String get loginNudgeTitle => '로그인하고 가족과 같이 써요';

  @override
  String get loginNudgeBody => '지금 넣은 물건은 그대로 남아요. 로그인은 설정에서도 할 수 있어요.';

  @override
  String get later => '나중에';

  @override
  String get searchThinking => '무슨 뜻인지 생각해 볼게요';

  @override
  String get kindTitle => '어떤 보관함인가요?';

  @override
  String get kindFurniture => '가구';

  @override
  String get kindFurnitureBody => '냉장고 · 옷장 · TV장처럼 움직이지 않는 것. 칸 · 서랍으로 나뉘어요.';

  @override
  String get kindBox => '상자';

  @override
  String get kindBoxBody => '박스 · 바구니 · 공구함처럼 통째로 옮기는 것. 겉에 적을 번호가 붙어요.';

  @override
  String get kindSpot => '자리';

  @override
  String get kindSpotBody => '소파 밑 · 현관 옆 · 차 트렁크처럼 그냥 놓인 곳.';

  @override
  String get furnitureNameHint => '예: TV장';

  @override
  String get boxNameHint => '안에 든 것 (예: 캠핑 소품)';

  @override
  String get sectionsTitle => '칸 · 서랍';

  @override
  String get sectionsHint => '위에서 아래 순서로, 쉼표로 나눠 쓰세요';

  @override
  String get sectionsDefault => '윗칸, 가운데 칸, 아랫칸';

  @override
  String boxName(int number) {
    return '상자 $number';
  }

  @override
  String boxNamed(int number, String name) {
    return '상자 $number · $name';
  }

  @override
  String get moveBox => '상자째 옮기기';

  @override
  String get moveBoxWhere => '상자를 어디로 옮길까요?';

  @override
  String floorOf(String room) {
    return '$room 바닥';
  }

  @override
  String boxMoved(String box, String place) {
    return '$box 이동: $place';
  }

  @override
  String get addBoxHere => '상자';

  @override
  String boxesInside(int count) {
    return '상자 $count개';
  }

  @override
  String get touchToStart => '터치해서 시작';

  @override
  String get leaveGuest => '로그인하러 가기';

  @override
  String get leaveGuestBody => '로그인 화면으로 가요. 휴대폰에 넣은 물건은 그대로 남아요.';

  @override
  String get navMap => '지도';

  @override
  String get navPut => '넣기';

  @override
  String changeAdd(String what, String place) {
    return '$what 넣음 · $place';
  }

  @override
  String changeMove(String what, String place) {
    return '$what 옮김 · $place';
  }

  @override
  String changeUse(String what, String place) {
    return '$what 꺼냄 · $place';
  }

  @override
  String changeUsedUp(String what) {
    return '$what 다 씀';
  }

  @override
  String changeEdit(String what) {
    return '$what 고침';
  }

  @override
  String changeRemove(String what) {
    return '$what 지움';
  }

  @override
  String changeWhatMore(String first, int count) {
    return '$first 외 $count개';
  }

  @override
  String get agoNow => '방금';

  @override
  String agoMinutes(int n) {
    return '$n분 전';
  }

  @override
  String agoHours(int n) {
    return '$n시간 전';
  }

  @override
  String agoDays(int n) {
    return '$n일 전';
  }

  @override
  String get noChangesYet => '바꾼 내용이 여기에 나와요.';

  @override
  String get mapOutside => '집 밖';

  @override
  String get mapEmptyRoom => '아직 보관함이 없어요';

  @override
  String mapHits(int count) {
    return '$count곳';
  }

  @override
  String get roomBedroom2 => '침실2';

  @override
  String get roomBedroom3 => '침실3';

  @override
  String get roomMaster => '안방';

  @override
  String get roomBath => '욕실';

  @override
  String get roomMasterBath => '안방 욕실';

  @override
  String get roomEntrance => '현관';

  @override
  String get roomKitchen => '주방';

  @override
  String get roomDressroom => '드레스룸';

  @override
  String get roomLiving => '거실';

  @override
  String get roomBalcony => '발코니';

  @override
  String get roomUtility => '다용도실';

  @override
  String get roomRoom => '방';

  @override
  String get tplApt84 => '84형 판상형 3베이';

  @override
  String get tplApt84Body => '침실2 · 거실 · 안방 남향';

  @override
  String get tplApt84bay4 => '84형 판상형 4베이';

  @override
  String get tplApt84bay4Body => '방 3개와 거실 남향';

  @override
  String get tplApt84tower => '84형 타워형';

  @override
  String get tplApt84towerBody => '거실 모서리, 두 면 창';

  @override
  String get tplApt59 => '59형 판상형';

  @override
  String get tplApt59Body => '방 3 · 욕실 2';

  @override
  String get tplVilla2 => '투룸 빌라';

  @override
  String get tplVilla2Body => '방 2 · 거실 겸 주방';

  @override
  String get tplStudio => '원룸 · 오피스텔';

  @override
  String get tplStudioBody => '현관 옆 욕실 · 주방';

  @override
  String get houseSetupTitle => '우리 집 모양 고르기';

  @override
  String get houseSetupBody =>
      '가장 비슷한 모양에서 시작하세요. 아래쪽(발코니)이 남향이에요. 방 이름 · 크기는 다음 화면에서 바꿔요.';

  @override
  String get houseBlank => '빈 칸에서 시작';

  @override
  String get houseNoMap => '지도 없이 목록으로';

  @override
  String get houseUseThis => '이 모양으로 시작';

  @override
  String get houseEditTitle => '우리 집 맞추기';

  @override
  String get houseEditHint => '블록을 끌어서 옮기고, 모서리 점을 끌어 크기를 바꿔요. 칸 하나 = 0.5m.';

  @override
  String get houseDone => '완료';

  @override
  String get houseAddRoom => '방';

  @override
  String get houseRename => '이름 바꾸기';

  @override
  String get houseTakeOff => '지도에서 빼기';

  @override
  String get houseTapBlock => '블록을 눌러 고르세요';

  @override
  String get mapSetup => '우리 집 모양 정하기';

  @override
  String get mapSetupBody => '평면도 모양을 고르면\n지도가 실제 집처럼 보여요';

  @override
  String get mapEdit => '모양 고치기';

  @override
  String get mapUnplaced => '지도에 아직 없는 방';

  @override
  String get aiToWordSearch => 'AI 검색에서 단어 검색으로 전환돼요.';

  @override
  String get aiQuotaSubscribe =>
      '오늘 쓸 수 있는 AI 검색을 다 썼어요. 구독하면 하루 한도 없이 요정이 뜻으로 찾아 줘요.';

  @override
  String get featuresSection => '더하기 기능';

  @override
  String get featureExpiry => '소비기한 챙기기';

  @override
  String get featureExpiryBody => '기한을 적어 두면 알려 줘요\n3일 전 · 하루 전 · 당일 아침 9시';

  @override
  String get featureReturns => '빌려준 물건 돌려받기';

  @override
  String get featureReturnsBody => '집 밖 자리에 돌려받을 날을 적고\n그날이 다가오면 알려 줘요';

  @override
  String get featureLowStock => '소모품 떨어지면 알림';

  @override
  String get featureLowStockBody => '최소 수량을 정해 두면\n모자랄 때 장보기 목록에 올려요';

  @override
  String get notifyOff => '알림이 꺼져 있어요. 휴대폰 설정에서 우리집요정 알림을 켜 주세요.';

  @override
  String get notifyChannel => '기한 알림';

  @override
  String get notifyChannelBody => '소비기한과 돌려받을 날';

  @override
  String notifyExpiry(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '기한이 $days일 남았어요',
      one: '내일까지 써야 해요',
      zero: '오늘까지 써야 해요',
    );
    return '$_temp0';
  }

  @override
  String notifyReturn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일 뒤 돌려받는 날이에요',
      one: '내일 돌려받는 날이에요',
      zero: '오늘 돌려받는 날이에요',
    );
    return '$_temp0';
  }

  @override
  String getBackCount(int count) {
    return '돌려받을 것 · $count개';
  }

  @override
  String runningLow(int count) {
    return '떨어져 가요 · $count개';
  }

  @override
  String get shoppingTitle => '장보기 목록';

  @override
  String get shoppingEmptyTitle => '떨어져 가는 게 없어요';

  @override
  String get shoppingEmptyBody => '휴지 · 쌀처럼 늘 두는 물건에\n최소 수량을 정해 두세요';

  @override
  String shoppingNeed(int qty, int min) {
    return '$qty개 남음\n$min개는 있어야 해요';
  }

  @override
  String get shoppingRefill => '채웠어요';

  @override
  String shoppingRefilled(String name, int qty) {
    return '$name $qty개로 채웠어요';
  }

  @override
  String get minQty => '최소 수량';

  @override
  String get minQtyHint => '이보다 적으면 장보기 목록에 올라가요.';

  @override
  String get minQtyNone => '안 정함';

  @override
  String get minQtySet => '정하기';

  @override
  String get familyGuestTitle => '가족과 같이 써요';

  @override
  String get familyGuestBody =>
      '로그인하고 우리 집을 만들면\n가족이 같은 지도를 보며\n같이 넣고 찾을 수 있어요';

  @override
  String get familyAloneBody => '우리 집을 만들어 가족을 부르거나\n받은 초대코드로 들어가세요';

  @override
  String get familyCreate => '우리 집 만들기';

  @override
  String get familyJoin => '초대코드로 들어가기';

  @override
  String get familyDefaultName => '우리 집';

  @override
  String get familyUploadTitle => '이 폰에 있던 것도 올릴까요?';

  @override
  String familyUploadBody(int spaces, int items) {
    return '공간 $spaces개 · 물건 $items개를 올려요\n가족도 볼 수 있고, 폰에도 그대로 남아요';
  }

  @override
  String get familyUploadYes => '올리고 시작하기';

  @override
  String get familyUploadNo => '빈 집으로 시작하기';

  @override
  String familyHeader(String name, int count, int limit) {
    return '$name · $count/$limit명';
  }

  @override
  String get familyMe => '나';

  @override
  String get familyOwner => '만든 사람';

  @override
  String get familySomeone => '가족';

  @override
  String get familyInviteSection => '가족 부르기';

  @override
  String get familyInviteMake => '초대코드 만들기';

  @override
  String familyInviteValid(String time) {
    return '$time까지 쓸 수 있어요';
  }

  @override
  String get familyInviteSend => '초대코드 보내기';

  @override
  String familyInviteMessage(String code) {
    return '우리집요정에서 우리 집에 들어와요. 가족 탭에서 초대코드로 들어가기를 누르고 $code를 넣어 주세요.';
  }

  @override
  String get familyCopied => '코드를 복사했어요';

  @override
  String get familyFull => '무료는 2명까지 함께 쓸 수 있어요.';

  @override
  String get familyLeave => '우리 집에서 나가기';

  @override
  String get familyLeaveBody =>
      '이 폰은 원래 있던 물건으로 돌아가요\n우리 집은 가족에게 그대로 남고\n아무도 없으면 지워져요';

  @override
  String get familyLeaveAction => '나가기';

  @override
  String get familyJoinHint => '6자리 코드';

  @override
  String get familyJoinGo => '들어가기';

  @override
  String get familyJoinBody => '가족이 보낸 코드를 넣어 주세요\n24시간 동안 쓸 수 있어요';

  @override
  String get familyAlreadyTitle => '지금 집에서 나갈까요?';

  @override
  String get familyAlreadyBody => '한 번에 한 집에만 있을 수 있어요.';

  @override
  String get familyAlreadyAction => '나가고 들어가기';

  @override
  String get familyProblemFull => '그 집은 꽉 찼어요. 무료는 2명까지예요.';

  @override
  String get familyProblemNotFound => '코드가 맞지 않거나 시간이 지났어요.';

  @override
  String get familyProblemOffline => '서버에 닿지 않았어요. 인터넷을 확인하고 다시 해 주세요.';

  @override
  String get familyProblemOther => '잘 안 됐어요. 다시 해 주세요.';

  @override
  String get syncSaved => '모두 저장됨';

  @override
  String get syncSaving => '저장 중';

  @override
  String get syncOffline => '오프라인 · 폰에 저장됨';

  @override
  String changeBy(String name, String change) {
    return '$name · $change';
  }

  @override
  String get featureFamilyAlerts => '가족이 바꾸면 알림';

  @override
  String get featureFamilyAlertsBody => '가족이 넣고 옮기고 쓰면\n바로 알려 줘요';

  @override
  String get featureFamilyAlertsNeedsHome => '가족 탭에서 우리 집에 들어가면\n켤 수 있어요';

  @override
  String get notifyFamilyChannel => '가족 소식';

  @override
  String get notifyFamilyChannelBody => '가족이 우리 집에서 바꾼 것';

  @override
  String roomEditTitle(String room) {
    return '$room 가구 놓기';
  }

  @override
  String get roomEditHint => '끌어서 옮기고, 모서리 점으로 크기를 바꿔요. 한 칸은 0.5m예요.';

  @override
  String get roomTapToPlace => '눌러서 바닥에 놓아요';

  @override
  String get roomAllPlaced => '이 방 것은 다 놓았어요.';

  @override
  String get roomPlaceFurniture => '가구 놓기';

  @override
  String get planPhoto => '평면도 사진';

  @override
  String get planPhotoHide => '사진 숨기기';

  @override
  String get planPhotoShow => '사진 보이기';

  @override
  String get planPhotoChange => '다른 사진 고르기';

  @override
  String get planPhotoRemove => '사진 지우기';

  @override
  String get planPhotoSize => '사진 크기';

  @override
  String get discard => '버렸어요';

  @override
  String discardedName(String name) {
    return '$name 버렸어요';
  }

  @override
  String changeDiscard(String what) {
    return '$what 버림';
  }

  @override
  String get reportOpen => '이번 달 보고서';

  @override
  String reportTitle(String month) {
    return '$month 우리 집';
  }

  @override
  String get reportAdded => '넣음';

  @override
  String get reportUsed => '씀';

  @override
  String get reportDiscarded => '버림';

  @override
  String get reportTopUsed => '많이 쓴 것';

  @override
  String get reportThrownOut => '버린 것';

  @override
  String get reportByMember => '가족별 바꾼 횟수';

  @override
  String reportTimes(int count) {
    return '$count번';
  }

  @override
  String get reportEmpty => '이번 달은 아직 기록이 없어요';

  @override
  String get reportShare => 'PDF로 공유';

  @override
  String reportFooter(String date) {
    return '우리집요정 · $date 만듦';
  }

  @override
  String get reportPrev => '지난달';

  @override
  String get reportNext => '다음 달';
}

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
  String get myHome => '우리 집';

  @override
  String get navSpaces => '공간';

  @override
  String get navExpiry => '소비기한';

  @override
  String get navFamily => '가족';

  @override
  String get searchHintShort => '무엇을 찾을까요?';

  @override
  String get searchHint => '무엇을 찾을까요? (초성도 돼요)';

  @override
  String get homeEmptyTitle => '우리 집 지도를 만들어 볼까요';

  @override
  String get homeEmptyBody => '집 모양부터 고르면\n방이 한 번에 생겨요';

  @override
  String get addSpace => '공간 추가';

  @override
  String get spacesEmptyTitle => '아직 공간이 없어요';

  @override
  String get spacesEmptyBody => '추가한 방과 그 안의 보관함이 여기에 보여요.';

  @override
  String get expiryEmptyTitle => '곧 기한이 끝나는 물건이 없어요';

  @override
  String get expiryEmptyBody => '기한을 넣으면 미리 알려 줘요';

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
  String get loginTagline => '로그인하면 가족과 같은 집을 쓰고\n요정 가루를 매달 받아요';

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
  String get guestNote => '이 폰에만 저장돼요 · 나중에 로그인해도 그대로';

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
  String get actionAdd => '넣기';

  @override
  String get actionMove => '옮기기';

  @override
  String get actionTakeOut => '사용';

  @override
  String get addWhere => '어디에 넣을까요?';

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
  String get storageHint => '물건을 꾹 누르면 여러 개를 골라요\n끌면 옮겨요';

  @override
  String get selectHint => '물건을 눌러 고르고\n수량을 정하세요';

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
    return '$count개 사용했어요';
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
  String get categoryClothes => '옷';

  @override
  String get categoryElectronics => '전자기기';

  @override
  String get categoryPapers => '서류';

  @override
  String get categoryHobby => '취미';

  @override
  String get categoryKids => '아이';

  @override
  String get categoryPets => '반려동물';

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
  String get groupOverdue => '기한 지남';

  @override
  String get groupSoon => '3일 안';

  @override
  String get groupLater => '나중에';

  @override
  String fairyFoundCount(int count) {
    return '$count개 찾았어요!';
  }

  @override
  String fairyNotFound(String query) {
    return '\"$query\"은(는) 없어요';
  }

  @override
  String get dataSection => '데이터';

  @override
  String get showIntroAgain => '소개 화면 다시 보기';

  @override
  String get deleteAllData => '이 휴대폰의 데이터 모두 삭제';

  @override
  String get deleteAllBody => '이 폰의 모든 것이 지워져요. 되돌릴 수 없어요.';

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
  String get moreIcons => '더 찾기';

  @override
  String get chooseIcon => '아이콘 고르기';

  @override
  String get searchIconsHint => '찾기 (예: 우산)';

  @override
  String get noIconsFound => '맞는 아이콘이 없어요';

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
  String get boardMoveHint => '옮길 곳을 고르세요';

  @override
  String get boardFirstStorageHint => '서랍 · 선반 · 상자를 넣어요';

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
  String get iconGroupKids => '아이';

  @override
  String get hereNow => '지금 여기';

  @override
  String get newStorageHere => '새 보관함';

  @override
  String deleteStorageNamed(String name) {
    return '$name 삭제';
  }

  @override
  String get dockHint => '방에 놓으면 그 방으로';

  @override
  String get dockNoOtherRooms => '다른 방을 만들면 옮길 수 있어요';

  @override
  String get smartApplied => '요정이 골랐어요. 바꿀 수 있어요.';

  @override
  String get smartFound => '요정이 찾았어요';

  @override
  String get smartMaybe => '혹시 이건가요?';

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
  String get signedOut => '로그아웃했어요';

  @override
  String loginFailedWhy(String reason) {
    return '로그인하지 못했어요 ($reason)';
  }

  @override
  String get sentenceTitle => '넣기';

  @override
  String get sentencePickOther => '다른 곳';

  @override
  String get sentenceWhat => '무엇을 넣나요?\n쉼표나 “랑”으로 이어 쓰세요';

  @override
  String get sentenceHint => '가위, 테이프랑 건전지 4개';

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
  String get introDemoRoom => '거실';

  @override
  String get introDemoStorage => 'TV장';

  @override
  String get introDemoSpot => '왼쪽 서랍';

  @override
  String get later => '나중에';

  @override
  String get searchThinking => '무슨 뜻인지 생각해 볼게요';

  @override
  String get kindTitle => '어떤 보관함인가요?';

  @override
  String get kindFurniture => '가구';

  @override
  String get kindFurnitureBody => '냉장고 · 옷장처럼 고정된 것';

  @override
  String get kindBox => '상자';

  @override
  String get kindBoxBody => '박스 · 바구니처럼 옮기는 것';

  @override
  String get kindSpot => '자리';

  @override
  String get kindSpotBody => '소파 밑 · 트렁크 같은 자리';

  @override
  String get furnitureNameHint => '예: TV장';

  @override
  String get boxNameHint => '안에 든 것 (예: 캠핑 소품)';

  @override
  String get sectionsTitle => '칸 · 서랍';

  @override
  String get sectionsDefault => '윗칸, 가운데 칸, 아랫칸';

  @override
  String boxName(int number) {
    return '상자 $number';
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
    return '$box 옮김 · $place';
  }

  @override
  String get addBoxHere => '상자';

  @override
  String get touchToStart => '터치해서 시작';

  @override
  String get leaveGuest => '로그인하러 가기';

  @override
  String get leaveGuestBody => '이 폰의 물건은 그대로예요';

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
    return '$what 사용 · $place';
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
  String get tplApt84Body => '침실2 · 거실\n안방 남향';

  @override
  String get tplApt84bay4 => '84형 판상형 4베이';

  @override
  String get tplApt84bay4Body => '방 3개와\n거실 남향';

  @override
  String get tplApt84tower => '84형 타워형';

  @override
  String get tplApt84towerBody => '거실 모서리\n두 면 창';

  @override
  String get tplApt59 => '59형 판상형';

  @override
  String get tplApt59Body => '방 3 · 욕실 2';

  @override
  String get tplVilla2 => '투룸 빌라';

  @override
  String get tplVilla2Body => '방 2\n거실 겸 주방';

  @override
  String get tplStudio => '원룸 · 오피스텔';

  @override
  String get tplStudioBody => '현관 옆\n욕실 · 주방';

  @override
  String get houseSetupTitle => '어떤 집에 사세요?';

  @override
  String get houseSetupBody => '비슷한 모양을 고르세요\n이름 · 크기는 다음에 바꿔요';

  @override
  String get houseBlank => '처음부터 직접 만들기';

  @override
  String get houseNoMap => '지도 없이 목록으로만 쓰기';

  @override
  String get houseUseThis => '이 모양으로 시작';

  @override
  String get houseEditTitle => '우리 집 맞추기';

  @override
  String get houseEditHint =>
      '빈칸 두 번 눌러 방 추가 · 방을 누르면 크기 조절\n꾹 눌러 옮기기 · 두 손가락으로 보기 · 확대';

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
  String get aiQuotaSubscribe => '이번 달 요정 가루를 다 썼어요\n눌러서 더 받기';

  @override
  String get featuresSection => '더하기 기능';

  @override
  String get featureExpiry => '소비기한 챙기기';

  @override
  String get featureExpiryBody => '기한 3일 전, 하루 전,\n당일에 알려요';

  @override
  String get featureReturns => '빌려준 물건 돌려받기';

  @override
  String get featureReturnsBody => '돌려받을 날 알림';

  @override
  String get featureLowStock => '소모품 떨어지면 알림';

  @override
  String get featureLowStockBody => '최소 수량을 정해 두면\n모자랄 때 장보기에 올려요';

  @override
  String get notifyOff => '알림이 꺼져 있어요. 폰 설정에서 켜 주세요.';

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
  String get shoppingTitle => '장보기';

  @override
  String get shoppingEmptyTitle => '살 것이 없어요';

  @override
  String get shoppingEmptyBody => '살 것을 추가하거나\n최소 수량을 정해 두세요';

  @override
  String get minQty => '최소 수량';

  @override
  String get minQtyHint => '이보다 적으면\n장보기 목록에 올라가요';

  @override
  String get minQtyNone => '안 정함';

  @override
  String get minQtySet => '정하기';

  @override
  String get familyGuestTitle => '가족과 같이 써요';

  @override
  String get familyGuestBody => '로그인하면 가족과\n같은 집을 함께 써요';

  @override
  String get familyAloneBody => '집을 만들거나\n초대코드로 들어가요';

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
    return '공간 $spaces개 · 물건 $items개를 올려요';
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
    return '우리집요정 초대코드: $code';
  }

  @override
  String get familyCopied => '코드를 복사했어요';

  @override
  String get familyFull => '무료는 2명까지 함께 쓸 수 있어요.';

  @override
  String get familyLeave => '우리 집에서 나가기';

  @override
  String get familyLeaveBody => '이 폰은 원래 물건으로 돌아가요';

  @override
  String get familyLeaveAction => '나가기';

  @override
  String get familyJoinHint => '6자리 코드';

  @override
  String get familyJoinGo => '들어가기';

  @override
  String get familyJoinBody => '받은 코드를 넣어요 (24시간)';

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
  String get familyProblemOffline => '인터넷을 확인해 주세요';

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
  String get featureFamilyAlertsBody => '가족이 넣기 · 옮기기 · 사용하면\n바로 알려 줘요';

  @override
  String get featureFamilyAlertsNeedsHome => '가족 탭에서 우리 집에\n들어가면 켤 수 있어요';

  @override
  String get notifyFamilyChannel => '가족 소식';

  @override
  String get notifyFamilyChannelBody => '가족이 우리 집에서 바꾼 것';

  @override
  String roomEditTitle(String room) {
    return '$room 가구 놓기';
  }

  @override
  String get roomEditHint => '누르면 크기 조절 · 꾹 눌러 옮기기\n두 손가락으로 보기 · 확대';

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
  String get reportUsed => '사용';

  @override
  String get reportDiscarded => '버림';

  @override
  String get reportTopUsed => '많이 사용한 것';

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

  @override
  String get barcodeAdd => '바코드로 넣기';

  @override
  String get barcodeTitle => '바코드 찍기';

  @override
  String get barcodeHint => '바코드를 틀에 맞춰요';

  @override
  String barcodeKnown(int qty, String place) {
    return '우리 집에 이미 $qty개 있어요\n$place';
  }

  @override
  String get barcodeOneMore => '하나 더';

  @override
  String barcodeAdded(String name, int qty) {
    return '$name $qty개가 됐어요';
  }

  @override
  String get barcodeLooking => '바코드를 찾고 있어요';

  @override
  String get barcodeUnknown => '식품 목록에 없어요. 이름을 적어 주세요.';

  @override
  String widgetUseFirst(int count) {
    return '먼저 챙기기 $count';
  }

  @override
  String widgetToBuy(int count) {
    return '장보기 $count';
  }

  @override
  String widgetGetBack(int count) {
    return '돌려받기 $count';
  }

  @override
  String widgetSummary(int items, int spaces) {
    return '물건 $items개 · 공간 $spaces곳';
  }

  @override
  String get familyMergeTitle => '이 폰 물건을 우리 집에 합치기';

  @override
  String familyMergeBody(int spaces, int items) {
    return '공간 $spaces개 · 물건 $items개\n같은 이름은 하나로 합쳐요';
  }

  @override
  String get familyMergeAction => '합치기';

  @override
  String familyMerged(int count) {
    return '물건 $count개를 우리 집에 합쳤어요';
  }

  @override
  String itemChangedElsewhere(int qty) {
    return '가족이 방금 이 물건을 바꿨어요\n지금 $qty개';
  }

  @override
  String get itemGoneElsewhere => '가족이 방금 이 물건을 뺐어요';

  @override
  String get itemReload => '새로 불러오기';

  @override
  String get familyAlertsNow => '바로';

  @override
  String get familyAlertsDaily => '저녁 8시 반에 한 번';

  @override
  String get creditsTitle => '요정 가루';

  @override
  String creditsBody(int left, int limit) {
    return '$limit 중 $left 남음\n찾기 1 · 영수증 3 · 사진 5';
  }

  @override
  String get receiptAdd => '영수증으로 넣기';

  @override
  String get receiptTitle => '영수증으로 넣기';

  @override
  String get receiptBody => '영수증을 찍어요\n사진은 보내지 않아요';

  @override
  String get receiptTake => '영수증 찍기';

  @override
  String get receiptReading => '영수증을 읽고 있어요';

  @override
  String receiptFound(int count) {
    return '$count개 찾았어요\n안 둘 건 체크를 빼요';
  }

  @override
  String get receiptNothingTitle => '물건을 찾지 못했어요';

  @override
  String get receiptNothingBody => '밝은 곳에서 똑바로 찍어요';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get deleteAccountBody => '계정과 서버 정보를 지워요\n이 폰의 물건은 남아요';

  @override
  String get accountDeleted => '계정을 지웠어요. 이 폰의 물건은 그대로 남아요.';

  @override
  String get backupSave => '백업 파일 만들기';

  @override
  String get backupSaveBody => '물건과 사진을 파일 하나로';

  @override
  String get backupRestore => '백업 불러오기';

  @override
  String get backupNotOne => '우리집요정 백업 파일이 아니에요.';

  @override
  String backupReplaceBody(int spaces, int items) {
    return '공간 $spaces개 · 물건 $items개\n지금 것과 바꿔요';
  }

  @override
  String backupMergeBody(int spaces, int items) {
    return '공간 $spaces개 · 물건 $items개\n같은 이름은 하나로 합쳐요';
  }

  @override
  String get backupReplace => '바꾸기';

  @override
  String backupRestored(int count) {
    return '백업을 불러왔어요 · 물건 $count개';
  }

  @override
  String get actionUse => '사용';

  @override
  String inUseSince(Object time) {
    return '사용 중 · $time부터';
  }

  @override
  String get putBack => '제자리에 뒀어요';

  @override
  String usedOne(Object name) {
    return '$name 1개 썼어요';
  }

  @override
  String nowInUse(Object name) {
    return '$name 사용 중이에요';
  }

  @override
  String askBackTitle(Object name) {
    return '$name은(는) 다 사용했나요?';
  }

  @override
  String askBackDetail(Object place, Object time) {
    return '$time에 $place에서 꺼냈어요';
  }

  @override
  String get askBackYes => '네 · 제자리에 뒀어요';

  @override
  String get askBackStill => '아직 쓰는 중';

  @override
  String get askBackElsewhere => '다른 곳에 보관했어요';

  @override
  String get returnsLabel => '쓰고 제자리에 두는 물건';

  @override
  String get historyTitle => '활동 기록';

  @override
  String get filterAll => '전체';

  @override
  String get filterAdd => '넣음';

  @override
  String get filterMove => '옮김';

  @override
  String get filterUse => '사용';

  @override
  String get historyEmpty => '아직 기록이 없어요';

  @override
  String get dayToday => '오늘';

  @override
  String get dayYesterday => '어제';

  @override
  String get notifyInUse => '제자리에 뒀나요?';

  @override
  String get shopAdd => '살 것 추가';

  @override
  String shopQty(Object count) {
    return '$count개';
  }

  @override
  String get shopLow => '떨어져 가요';

  @override
  String get shopNew => '처음 사요';

  @override
  String shopPutIn(Object count, Object name, Object place) {
    return '$name $count개를 $place에 넣었어요';
  }

  @override
  String shopHowMany(Object name) {
    return '$name 몇 개 샀어요?';
  }

  @override
  String shopLeft(Object count) {
    return '남은 $count개는 장보기에 둬요';
  }

  @override
  String get shopPlace => '넣을 곳';

  @override
  String get shopAddName => '무엇을 살까요?';

  @override
  String get shopAddButton => '추가';

  @override
  String shopRemoved(Object name) {
    return '$name 뺐어요';
  }

  @override
  String get tileUseFirst => '먼저 챙기기';

  @override
  String get tileShopping => '장보기';

  @override
  String get tileReturns => '돌려받기';

  @override
  String tileReport(Object month) {
    return '$month 보고서';
  }

  @override
  String shopTookOff(Object count) {
    return '장보기에서 $count개 뺐어요';
  }

  @override
  String get moreDetails => '더 적기';

  @override
  String get changeIcon => '아이콘 바꾸기';

  @override
  String get formQtyQuestion => '몇 개 넣을까요?';

  @override
  String askExpiredTitle(Object name) {
    return '$name 다 쓰셨나요?';
  }

  @override
  String askExpiredDetail(Object date) {
    return '기한이 $date에 지났어요';
  }

  @override
  String get askExpiredUsed => '네 · 다 썼어요';

  @override
  String get askExpiredThrown => '버렸어요';

  @override
  String get askExpiredStill => '아직 있어요';

  @override
  String fairyHowMany(Object count, Object name) {
    return '$name $count개 있어요';
  }

  @override
  String fairyBuyAsk(Object name) {
    return '$name 장보기에 넣을까요?';
  }

  @override
  String get fairyBuyDo => '넣기';

  @override
  String fairyBuyDone(Object name) {
    return '$name 장보기에 넣었어요';
  }

  @override
  String fairyUsedAsk(Object name) {
    return '$name 다 썼다고 적을까요?';
  }

  @override
  String get fairyUsedDo => '적기';

  @override
  String get receiptTidy => '요정이 정리하기';

  @override
  String get receiptTidying => '정리하는 중';

  @override
  String get receiptTidied => '요정이 정리했어요\n상품이 아닌 줄은 체크를 뺐어요';

  @override
  String get receiptTidyFailed => '지금은 정리할 수 없어요';

  @override
  String get photoAdd => '사진으로 넣기';

  @override
  String get photoBody => '서랍이나 선반 안을 찍어요\n사진은 요정에게 보내요 (요정 가루 5)';

  @override
  String get photoTake => '안을 찍기';

  @override
  String get photoLooking => '요정이 보는 중이에요';

  @override
  String photoFound(Object count) {
    return '$count개 찾았어요\n흐린 건 혹시 몰라 체크를 뺐어요';
  }

  @override
  String get photoNothingTitle => '물건을 알아보지 못했어요';

  @override
  String get photoNothingBody => '밝은 곳에서 가까이 찍어요';

  @override
  String get photoFailed => '지금은 사진을 볼 수 없어요';

  @override
  String get voiceListening => '듣고 있어요';

  @override
  String get voiceSearch => '말로 찾기';

  @override
  String get voiceUnavailable => '이 폰에서는 말로 찾을 수 없어요';

  @override
  String notifyWarranty(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days일 뒤 보증이 끝나요',
      zero: '오늘 보증이 끝나요',
    );
    return '$_temp0';
  }

  @override
  String get valuable => '보증 · 영수증';

  @override
  String get valuableTitle => '보증 · 가격';

  @override
  String get warrantyUntil => '보증 끝나는 날';

  @override
  String get warranty1y => '1년';

  @override
  String get warranty2y => '2년';

  @override
  String get price => '가격';

  @override
  String get priceHint => '원';

  @override
  String get proof => '영수증 · 보증서 사진';

  @override
  String get proofAdd => '사진 넣기';

  @override
  String get valuablesTitle => '보증서 · 고가품';

  @override
  String get valuablesEmpty => '보증이나 가격을 적은 물건이 여기 모여요';

  @override
  String valuablesTotal(Object total) {
    return '모두 $total원';
  }

  @override
  String warrantyLeft(Object date) {
    return '보증 $date까지';
  }

  @override
  String won(Object price) {
    return '$price원';
  }

  @override
  String get done => '완료';

  @override
  String get askFamily => '가족에게 물어보기';

  @override
  String get askedFamily => '가족에게 물었어요';

  @override
  String get stage0 => '새싹 요정';

  @override
  String get stage1 => '꼬마 요정';

  @override
  String get stage2 => '살림 요정';

  @override
  String get stage3 => '든든 요정';

  @override
  String get stage4 => '우리집 수호 요정';

  @override
  String get stageShort0 => '새싹';

  @override
  String get stageShort1 => '꼬마';

  @override
  String get stageShort2 => '살림';

  @override
  String get stageShort3 => '든든';

  @override
  String get stageShort4 => '수호';

  @override
  String get growthTitle => '요정 이야기';

  @override
  String growthToNext(Object count) {
    return '다음 단계까지 별 $count개';
  }

  @override
  String get growthTop => '가장 높은 단계예요';

  @override
  String get growthWeek => '이번 주 할 일';

  @override
  String growthWeeks(Object count) {
    return '$count주째 정리 중';
  }

  @override
  String taskClearExpired(Object name) {
    return '기한 지난 $name 정리하기';
  }

  @override
  String taskFillSpot(Object name) {
    return '$name에 물건 넣기';
  }

  @override
  String get taskBuyTwo => '장보기 2개 체크하기';

  @override
  String get taskAddFive => '물건 5개 넣기';

  @override
  String get taskAddDetail => '물건 하나에 기한 · 보증 적기';

  @override
  String get stampFirstDrawer => '첫 서랍 완성';

  @override
  String get stampFamily => '가족과 함께';

  @override
  String get stampFridgeKeeper => '냉장고 지킴이';

  @override
  String get stampShopper => '장보기 달인';

  @override
  String get stampWarranty => '보증서 챙김';

  @override
  String get stampPhotos => '사진 정리';

  @override
  String levelUpTitle(Object stage) {
    return '$stage이 됐어요!';
  }

  @override
  String levelUpBody(Object count) {
    return '별 $count개를 모았어요';
  }

  @override
  String starsCount(Object count) {
    return '별 $count';
  }

  @override
  String get shareCard => '자랑하기';

  @override
  String shareCardTitle(Object month) {
    return '$month 우리 집';
  }

  @override
  String get shareCardSend => '보내기';

  @override
  String get recipesTitle => '뭐 해 먹지';

  @override
  String get recipeKindAll => '전체';

  @override
  String get recipeKindSide => '반찬';

  @override
  String get recipeKindSoup => '국·찌개';

  @override
  String get recipeKindMeal => '밥·일품';

  @override
  String get recipeKindDessert => '후식';

  @override
  String recipeHaveMissing(int have, int missing) {
    return '있는 것 $have · 없는 것 $missing';
  }

  @override
  String recipeHaveAll(int have) {
    return '있는 것 $have · 다 있어요';
  }

  @override
  String recipeUrgent(String names) {
    return '먼저 쓸 것: $names';
  }

  @override
  String get recipesEmptyTitle => '만들 수 있는 요리가 없어요';

  @override
  String get recipesEmptyBody => '식품을 넣으면\n그걸 쓰는 요리를 찾아 줘요';

  @override
  String get recipeIngredients => '재료';

  @override
  String recipeHave(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 있음',
      one: '있음',
    );
    return '$_temp0';
  }

  @override
  String get recipeMissing => '없음';

  @override
  String recipeStaples(int count, String names) {
    return '기본양념 $count가지 · $names';
  }

  @override
  String recipeStaplesShort(int count) {
    return '기본양념 $count가지';
  }

  @override
  String recipeBuyMissing(int count) {
    return '없는 것 $count개 장보기에';
  }

  @override
  String recipeBuyDone(int count) {
    return '장보기에 $count개 넣었어요';
  }

  @override
  String recipeSteps(int count) {
    return '만드는 법 · $count단계';
  }

  @override
  String get recipeTip => '요리 팁';

  @override
  String get recipeSource => '출처 · 식품의약품안전처 식품안전나라';

  @override
  String get recipeCooked => '만들었어요';

  @override
  String get cookAsk => '얼마나 썼어요?';

  @override
  String get cookAskDetail => '레시피 양으로 미리 골라 뒀어요';

  @override
  String get cookNone => '안 씀';

  @override
  String get cookSome => '조금';

  @override
  String get cookAll => '다 씀';

  @override
  String cookHave(int count) {
    return '$count개 있음';
  }

  @override
  String get cookTake => '쓴 만큼';

  @override
  String get cookTakeOut => '이대로 빼기';

  @override
  String get cookDone => '쓴 재료를 뺐어요';

  @override
  String get cookToBuy => '장보기에';

  @override
  String cookWith(String names) {
    return '$names 쓰는 요리';
  }

  @override
  String get cookIdeas => '뭐 해 먹지 보기';

  @override
  String get fairyCookFound => '이런 요리를 만들 수 있어요';

  @override
  String get fairyCookNone => '지금 재료에 맞는 요리가 없어요';

  @override
  String get recipesMore => '요리 더 보기';

  @override
  String get addPlaceTitle => '무엇을 더할까요?';

  @override
  String get addPlaceRoom => '방';

  @override
  String get addPlaceRoomBody => '거실 · 안방 · 주방';

  @override
  String get addPlaceOutsideBody => '차 · 창고 · 빌려준 곳';

  @override
  String get addPlaceMoving => '이사 상자';

  @override
  String get addPlaceMovingBody => '상자마다 번호를 매겨요';

  @override
  String get movingName => '이사 상자';

  @override
  String movingSummary(int boxes, int items) {
    return '상자 $boxes개 · 물건 $items개';
  }

  @override
  String movingProgress(int done, int total) {
    return '상자 $total개 중 $done개 풀었어요';
  }

  @override
  String get movingAddBox => '새 상자';

  @override
  String movingGoesTo(String room) {
    return '$room에 갈 상자';
  }

  @override
  String get movingNoRoom => '갈 방 미정';

  @override
  String get movingUnpacked => '풀었어요';

  @override
  String get movingWriteHint => '상자 옆면에 이 숫자를 크게 적어 주세요';

  @override
  String get movingGoesToLabel => '새 집에서 갈 방';

  @override
  String movingInside(int count) {
    return '넣은 것 · $count';
  }

  @override
  String get movingPackFromHome => '집에서 담기';

  @override
  String get movingPackNew => '새로 적기';

  @override
  String get movingPlaceWhole => '상자째 두기';

  @override
  String movingUnpackPicked(int count) {
    return '고른 $count개 · 자리 정하기';
  }

  @override
  String get movingUnpackWhere => '어디에 둘까요?';

  @override
  String movingPackTitle(String name) {
    return '$name에 담기';
  }

  @override
  String movingPackDo(int count, String name) {
    return '$name에 넣기 · $count개';
  }

  @override
  String get movingPackSearch => '이름으로 찾기';

  @override
  String get movingPackEmpty => '더 담을 물건이 없어요';

  @override
  String get movingDoneTitle => '상자를 다 풀었어요';

  @override
  String get movingDoneBody => '이사 상자 칸을 지도에서 지울까요?\n예전 집의 빈 칸도 같이 정리해요.';

  @override
  String get movingDoneClear => '지우고 마치기';

  @override
  String get movingDoneKeep => '그대로 두기';

  @override
  String get movingFinish => '이사 마치기';

  @override
  String movingFinishBlocked(int count) {
    return '아직 물건이 든 상자가 $count개 있어요';
  }

  @override
  String get movingFinished => '이사를 마쳤어요';

  @override
  String get privacyPolicy => '개인정보처리방침';

  @override
  String get appPage => '앱 소개 · 출처';

  @override
  String get homeEmptyPlan => '우리 집 모양 고르기';

  @override
  String get homeEmptyOneRoom => '방 하나만 만들기';

  @override
  String get introWelcomeTitle => '우리 집 물건,\n요정이 기억해요';

  @override
  String get introWelcomeBody => '어디 뒀는지 잊어도 괜찮아요\n물어보면 바로 찾아 줘요';

  @override
  String get introPromise1 => '계정 없이도 바로';

  @override
  String get introPromise2 => '기록은 이 폰 안에';

  @override
  String get introPromise3 => '가족과 함께도';

  @override
  String get introMapTitle => '우리 집 모양 그대로\n지도를 그려요';

  @override
  String get introMapBody => '평면도를 고르면\n방이 한 번에 생겨요';

  @override
  String get introFindTitle => '물어보면\n바로 찾아 줘요';

  @override
  String get introFindBody => '이름 · 초성 · 설명으로,\n말로 물어봐도 돼요';

  @override
  String get introCareTitle => '기한 · 장보기 · 돌려받기\n잊지 않게 챙겨요';

  @override
  String get introCareBody => '적어 둔 날짜에 맞춰\n알림이 와요';

  @override
  String get introDemoFridge => '냉장고';

  @override
  String get introDemoScissors => '가위';

  @override
  String get introDemoAsk => '가위 어디 뒀지?';

  @override
  String get introCareBadge1 => '내일까지';

  @override
  String get introCareLine1 => '우유 · 냉장고';

  @override
  String get introCareBadge2 => '1개 남음';

  @override
  String get introCareLine2 => 'AA 건전지 · 장보기에';

  @override
  String get introCareBadge3 => '2일 뒤';

  @override
  String get introCareLine3 => '캠핑 랜턴 돌려받기';

  @override
  String get houseBlankBody => '빈 칸에 방을 그려요';

  @override
  String get dustMonth => '이번 달 요정 가루';

  @override
  String dustOf(int left, int limit) {
    return '$left / $limit';
  }

  @override
  String dustRefill(int limit, String date) {
    return '$date에 다시 $limit으로 채워져요';
  }

  @override
  String get dustCostFind => '설명으로 찾기';

  @override
  String get dustCostReceipt => '영수증 정리';

  @override
  String get dustCostPhoto => '사진으로 넣기';

  @override
  String get dustFree => '이름 · 초성 · 코드로 찾기와 아이콘 고르기는\n가루 없이 돼요';

  @override
  String get dustGuest => '로그인하면 매달\n요정 가루 150을 받아요';

  @override
  String dustSpent(int spent, int left) {
    return '요정 가루 $spent 썼어요 · $left 남음';
  }

  @override
  String dustLow(int left) {
    return '요정 가루가 $left 남았어요';
  }

  @override
  String get achHome => '첫 집';

  @override
  String get achHomeHow => '집 모양 정하기';

  @override
  String get achDrawers => '서랍 정리왕';

  @override
  String get achDrawersHow => '물건이 든 칸';

  @override
  String get achThings => '척척 넣기';

  @override
  String get achThingsHow => '넣어 둔 물건 수';

  @override
  String get achFinder => '척척 찾기';

  @override
  String get achFinderHow => '검색으로 찾은 횟수';

  @override
  String get achFridge => '냉장고 지킴이';

  @override
  String get achFridgeHow => '식품 5개 이상 · 기한 지난 것 없음\n한 달 동안 버린 것 없음';

  @override
  String get achThrifty => '알뜰 살림';

  @override
  String get achThriftyHow => '물건을 쓴 횟수';

  @override
  String get achBought => '장보기 달인';

  @override
  String get achBoughtHow => '장보기 체크';

  @override
  String get achFamily => '함께 사는 집';

  @override
  String get achFamilyHow => '가족이 우리 집에 들어오기';

  @override
  String get achMoves => '척척 옮기기';

  @override
  String get achMovesHow => '물건을 옮긴 횟수';

  @override
  String get achCook => '오늘의 요리사';

  @override
  String get achCookHow => '레시피로 요리한 횟수';

  @override
  String get achMoving => '이사 완료';

  @override
  String get achMovingHow => '이사 상자 모두 풀기';

  @override
  String get achWarranty => '보증서 챙김';

  @override
  String get achWarrantyHow => '보증 기간을 적은 물건';

  @override
  String get achStreak => '꾸준한 요정';

  @override
  String get achStreakHow => '이번 주 할 일을 다 한 주';

  @override
  String get achPhotos => '사진 기록가';

  @override
  String get achPhotosHow => '사진을 넣은 물건';

  @override
  String get achDated => '기한 챙김';

  @override
  String get achDatedHow => '기한을 적은 물건';

  @override
  String get achTitle => '업적';

  @override
  String achCount(int got, int total) {
    return '업적 $got / $total';
  }

  @override
  String get achSeeAll => '모두 보기';

  @override
  String achSummary(int gold, int silver, int bronze) {
    return '금 $gold · 은 $silver · 동 $bronze';
  }

  @override
  String get achKindAll => '전체';

  @override
  String get achKindHome => '정리';

  @override
  String get achKindFind => '넣기 · 찾기';

  @override
  String get achKindCare => '챙기기';

  @override
  String get achKindTogether => '함께';

  @override
  String get medalBronze => '동';

  @override
  String get medalSilver => '은';

  @override
  String get medalGold => '금';

  @override
  String achProgress(int value, int next) {
    return '$value / $next';
  }

  @override
  String achNext(String name, int left) {
    return '다음 업적까지: $name $left 남음';
  }

  @override
  String get achNone => '첫 업적을 모아 보세요';

  @override
  String achStars(int n) {
    return '별 +$n';
  }

  @override
  String achMedal(String medal) {
    return '$medal 업적';
  }

  @override
  String get achGot => '새 업적을 받았어요';

  @override
  String get updateAvailable => '새 버전이 나왔어요';

  @override
  String get updateLater => '나중에';

  @override
  String get updateGet => '받기';

  @override
  String updateDownloading(int percent) {
    return '새 버전 받는 중 · $percent%';
  }

  @override
  String updateDownloadingShort(int percent) {
    return '받는 중 · $percent%';
  }

  @override
  String get updateDownloaded => '업데이트 준비됐어요';

  @override
  String get updateRestart => '다시 시작';

  @override
  String get updateRestartInstall => '다시 시작해서 설치';

  @override
  String get updateFailed => '업데이트를 받지 못했어요';

  @override
  String get updateRetry => '다시 받기';

  @override
  String get updateLatest => '최신이에요';

  @override
  String get updateNew => '새 버전';

  @override
  String get updateNotStore => '스토어에서 설치한 앱만\n업데이트를 확인해요';

  @override
  String get updateFailedShort => '받지 못했어요';

  @override
  String get updateDownloadedShort => '준비됐어요';

  @override
  String houseNewRoom(int n) {
    return '방 $n';
  }

  @override
  String get fairyNeedsAccount => '로그인하면 요정에게 물어볼 수 있어요';

  @override
  String get familyProblemTries => '틀린 코드가 너무 많았어요.\n한 시간 뒤에 다시 해 주세요.';

  @override
  String get familyRemove => '우리 집에서 내보내기';

  @override
  String familyRemoveTitle(String name) {
    return '$name 님을 내보낼까요?';
  }

  @override
  String get familyRemoveBody => '그 폰은 원래 물건으로 돌아가요.\n새 코드를 받으면 다시 들어올 수 있어요.';

  @override
  String get familyRemoveAction => '내보내기';

  @override
  String dustBought(int n) {
    return '산 요정 가루 $n (없어지지 않아요)';
  }

  @override
  String get plusOpen => '요정 가루 더 받기';

  @override
  String get plusOpenHave => '플러스 · 요정 가루';

  @override
  String get plusTitle => '요정 가루 더 받기';

  @override
  String get plusLead => '설명으로 찾기 · 영수증 정리 · 사진으로 넣기에\n요정 가루를 써요.';

  @override
  String get plusName => '플러스';

  @override
  String get plusBody => '매달 요정 가루 1,500\n(무료 150의 10배)';

  @override
  String plusPrice(String price) {
    return '한 달 $price';
  }

  @override
  String get plusTerms =>
      '해지할 때까지 매달 자동으로 결제돼요.\nGoogle Play 에서 언제든 해지할 수 있어요.';

  @override
  String get plusBuy => '플러스 시작하기';

  @override
  String get plusActive => '플러스를 쓰고 있어요';

  @override
  String get plusManage => 'Google Play 에서 관리';

  @override
  String get packName => '요정 가루 한 주머니';

  @override
  String get packBody => '요정 가루 500, 한 번만\n다 쓸 때까지 없어지지 않아요.';

  @override
  String packBuy(String price) {
    return '$price에 사기';
  }

  @override
  String get plusRestore => '구매 다시 불러오기';

  @override
  String get plusGuest => '먼저 로그인해 주세요.\n산 것은 계정에 보관돼요.';

  @override
  String get plusSoon =>
      '이 폰에서는 아직 상점이 열리지 않았어요.\nGoogle Play 에서 설치한 앱에서 살 수 있어요.';

  @override
  String get plusDone => '고마워요! 요정 가루가 들어왔어요.';

  @override
  String get plusFailed => '구매를 마치지 못했어요.\n두 번 결제되지는 않아요. 다시 해 주세요.';

  @override
  String get settingsFeedback => '의견 보내기';

  @override
  String get settingsPlus => '플러스 · 요정 가루';

  @override
  String sectionNumbered(int n) {
    return '$n번째 칸';
  }

  @override
  String sectionsOrder(String name) {
    return '$name · 위에서 아래 순서';
  }

  @override
  String get sectionsOrderShort => '위에서 아래 순서';

  @override
  String get sectionAdd => '칸 추가';

  @override
  String get sectionsRemoveNote => '지운 칸에 있던 물건은\n맨 위 칸으로 옮겨져요.';

  @override
  String get sectionsEdit => '칸 · 서랍 고치기';
}

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
  String get searchHint => '물건 이름으로 찾기 (예: 가위)';

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
  String get designSample => '디자인 견본';

  @override
  String get designSampleBody => '앱 전체에 쓰는 색 · 글꼴 · 부품이에요.';

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
  String get intro1Title => '어디 뒀는지 바로 찾아요';

  @override
  String get intro1Body => '\"건전지 어디 있어?\" 하고 물으면 서랍과 칸까지 바로 알려 줘요.';

  @override
  String get intro2Title => '게임 인벤토리처럼 옮겨요';

  @override
  String get intro2Body => '여러 물건을 골라 수량을 정하고 한 번에 옮겨요.';

  @override
  String get intro3Title => '기한 지나기 전에 챙겨요';

  @override
  String get intro3Body => '기한을 넣으면 D-3, D-1, 당일에 요정이 알려 줘요.';

  @override
  String get loginTagline => '우리 집 물건, 요정이 기억해요.';

  @override
  String get loginKakao => '카카오로 계속하기';

  @override
  String get loginNaver => '네이버로 계속하기';

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
      '빈 칸을 누르면 추가, 물건을 누르면 빼기·이동이에요. 길게 누르면 여러 개를 고를 수 있어요.';

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
}

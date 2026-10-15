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
  String get quickAdd => '찍어서 넣기';

  @override
  String get quickMove => '골라서 옮기기';

  @override
  String get quickUse => '꺼내 쓰기';

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
}

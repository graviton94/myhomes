import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

void main() {
  test('a mart receipt keeps the things bought with their quantity', () {
    final rows = [
      '홈플러스 강서점',
      '사업자 123-45-67890 대표 홍길동',
      '2026-10-28 18:42 POS 03',
      '상품명 단가 수량 금액',
      '------------------------------',
      '001 CJ햇반210g*3 3,980 1 3,980',
      '002 키친타월 4,900 2 9,800',
      '8801115114154 서울우유 900ml 2,650 1 2,650',
      '달걀 15구',
      '6,980 1 6,980',
      '[할인] 키친타월 -500',
      '봉투(20L) 490 1 490',
      '------------------------------',
      '합계 23,400',
      '부가세 2,127',
      '신용카드 23,400',
    ];
    expect(parseReceipt(rows).map((i) => (i.name, i.qty)), [
      ('CJ햇반 210g', 3),
      ('키친타월', 2),
      ('서울우유 900ml', 1),
      ('달걀 15구', 1),
    ]);
  });

  test('OCR pieces in columns come back together as printed rows', () {
    final rows = receiptRows(const [
      OcrPiece('키친타월', 10, 100, 20),
      OcrPiece('9,800', 300, 102, 20),
      OcrPiece('2', 220, 99, 20),
      OcrPiece('햇반', 10, 130, 20),
      OcrPiece('3,980', 300, 131, 20),
    ]);
    expect(rows, ['키친타월 2 9,800', '햇반 3,980']);
    expect(parseReceipt(rows).map((i) => (i.name, i.qty)), [('키친타월', 2), ('햇반', 1)]);
  });
}

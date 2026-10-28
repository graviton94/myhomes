/// Receipts (v0.9): the phone reads the text (on-device OCR); these rules
/// put the pieces back into rows and keep the rows that are things bought,
/// with their quantity. Prices, totals, payment, bags and discounts drop out.
library;

import 'hangul.dart';

/// A piece of text the OCR found and where (any unit, top-left origin).
class OcrPiece {
  const OcrPiece(this.text, this.left, this.top, this.height);

  final String text;
  final double left;
  final double top;
  final double height;

  double get middle => top + height / 2;
}

/// Pieces on the same printed line, left to right. Receipts print names and
/// prices in columns, which OCR often returns as separate blocks.
List<String> receiptRows(List<OcrPiece> pieces) {
  final sorted = [...pieces]..sort((a, b) => a.middle.compareTo(b.middle));
  final rows = <List<OcrPiece>>[];
  for (final p in sorted) {
    final row = rows.isEmpty ? null : rows.last;
    final avg = row == null ? 0.0 : row.map((r) => r.height).reduce((a, b) => a + b) / row.length;
    final mid = row == null ? 0.0 : row.map((r) => r.middle).reduce((a, b) => a + b) / row.length;
    if (row != null && (p.middle - mid).abs() < avg * 0.55) {
      row.add(p);
    } else {
      rows.add([p]);
    }
  }
  return [
    for (final r in rows) (r..sort((a, b) => a.left.compareTo(b.left))).map((p) => p.text.trim()).where((t) => t.isNotEmpty).join(' '),
  ];
}

class ReceiptItem {
  const ReceiptItem(this.name, this.qty);

  final String name;
  final int qty;

  @override
  String toString() => 'ReceiptItem($name, $qty)';
}

const _skipWords = [
  '합계',
  '총액',
  '소계',
  '총계',
  '부가세',
  '부가가치세',
  '과세',
  '면세',
  '공급가',
  '카드',
  '현금',
  '승인',
  '거스름',
  '받은',
  '할인',
  '쿠폰',
  '포인트',
  '적립',
  '봉투',
  '쇼핑백',
  '종량제',
  '사업자',
  '대표',
  '전화',
  '주소',
  '영수증',
  '매장',
  '일시',
  '날짜',
  '회원',
  '결제',
  '단가',
  '수량',
  '금액',
  '상품명',
  '품명',
  '교환',
  '환불',
  '반품',
  '고객',
  '감사',
  '판매',
  '계산',
  '신용',
  '체크',
  '할부',
  '잔액',
  '면세물품',
  '과세물품',
  '배달',
  '주차',
  '번호',
  '가맹',
  'pos',
  'tel',
  'www',
  'http',
  'total',
  'tax',
  'vat',
  'card',
  'cash',
  'change',
  'subtotal',
  'discount',
  'plasticbag',
  'shoppingbag',
  'carrierbag',
];

final _price = RegExp(r'^-?\d{1,3}(,\d{3})+$|^-?\d+$');
final _leadingIndex = RegExp(r'^(\d{1,3}[\).]?\s+|[*#]\s*)');
final _barcode = RegExp(r'\b\d{8,14}\b');
final _timesQty = RegExp(r'\s*[*xX×]\s*(\d{1,2})$');
final _hangulDigit = RegExp(r'([가-힣])(\d)');
final _letters = RegExp(r'[가-힣A-Za-z]');

/// Things bought, from the receipt's rows (top to bottom).
List<ReceiptItem> parseReceipt(List<String> rows) {
  final out = <ReceiptItem>[];
  String? pendingName;
  for (final raw in rows) {
    final row = cleanText(raw).replaceAll(RegExp(r'\s+'), ' ');
    if (row.isEmpty) continue;
    final lower = row.toLowerCase().replaceAll(' ', '');
    if (_skipWords.any(lower.contains) || RegExp(r'^[-=_*~.\s]+$').hasMatch(row)) {
      pendingName = null;
      continue;
    }
    // Split off the numbers at the end: unit price, quantity, amount.
    final tokens = row.split(' ');
    final numbers = <String>[];
    while (tokens.isNotEmpty && _price.hasMatch(tokens.last)) {
      numbers.insert(0, tokens.removeLast());
    }
    var name = tokens.join(' ').replaceFirst(_leadingIndex, '').replaceAll(_barcode, '').trim();
    if (numbers.isEmpty) {
      // A name alone: its numbers may be on the next row.
      pendingName = _letters.allMatches(name).length >= 2 ? name : null;
      continue;
    }
    if (name.isEmpty || _letters.allMatches(name).length < 2) {
      if (pendingName == null) continue;
      name = pendingName;
    }
    pendingName = null;
    if (numbers.any((n) => n.startsWith('-'))) continue; // a discount line
    var qty = _qtyOf(numbers);
    final times = _timesQty.firstMatch(name);
    if (times != null) {
      name = name.substring(0, times.start).trim();
      if (qty == 1) qty = int.parse(times.group(1)!);
    }
    name = name.replaceAllMapped(_hangulDigit, (m) => '${m[1]} ${m[2]}').trim();
    if (_letters.allMatches(name).length < 2) continue;
    out.add(ReceiptItem(name, qty < 1 ? 1 : qty));
  }
  return out;
}

/// Unit price, quantity, amount: the quantity is the small number between
/// two prices (or before the amount); a lone amount means one.
int _qtyOf(List<String> numbers) {
  final values = numbers.map((n) => int.parse(n.replaceAll(',', ''))).toList();
  if (values.length >= 3) {
    final q = values[values.length - 2];
    if (q > 0 && q < 100) return q;
  }
  if (values.length == 2 && values.first > 0 && values.first < 100 && values.last >= 100) return values.first;
  return 1;
}

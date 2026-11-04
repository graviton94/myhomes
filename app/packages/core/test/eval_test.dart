// Scores the rule-based guesses against the answer sheets in eval/ and keeps
// them from sliding back. Prints the scores so a change can be compared.
import 'dart:convert';
import 'dart:io';

import 'package:homefairy_core/homefairy_core.dart';
import 'package:test/test.dart';

({double category, double icon, double unknown, List<String> misses}) score(String file) {
  final rows = [
    for (final l in File(file).readAsLinesSync().where((l) => l.trim().isNotEmpty)) jsonDecode(l) as Map<String, dynamic>,
  ];
  var cat = 0, icon = 0, none = 0;
  final misses = <String>[];
  for (final r in rows) {
    final name = r['name'] as String;
    final guess = guessCategory(name);
    final icons = iconsFromName(name);
    if (guess == null) none++;
    if (guess?.name == r['category']) {
      cat++;
    } else {
      misses.add('$name: ${guess?.name} (${r['category']})');
    }
    if (icons.isNotEmpty && (r['icons'] as List).contains(icons.first)) icon++;
  }
  return (category: cat / rows.length, icon: icon / rows.length, unknown: none / rows.length, misses: misses);
}

void main() {
  for (final (file, floor) in [('eval/classify.jsonl', 0.9), ('eval/classify_holdout.jsonl', 0.85)]) {
    test('rules score on $file', () {
      final s = score(file);
      String pct(double v) => '${(v * 100).toStringAsFixed(1)}%';
      print('$file  category ${pct(s.category)} · icon ${pct(s.icon)} · unknown ${pct(s.unknown)}');
      for (final m in s.misses) {
        print('  miss  $m');
      }
      expect(s.category, greaterThanOrEqualTo(floor));
    });
  }
}

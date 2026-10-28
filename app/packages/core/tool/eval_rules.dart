// Prints the rule-based answers for the evaluation sets in eval/ as JSON, so
// tool/jev_eval.py can score rules and the decision model side by side.
//   dart run tool/eval_rules.dart > rules.json
import 'dart:convert';
import 'dart:io';

import 'package:homefairy_core/homefairy_core.dart';

void main() {
  final classify = [
    for (final line in File('eval/classify.jsonl').readAsLinesSync().where((l) => l.trim().isNotEmpty))
      jsonDecode(line) as Map<String, dynamic>,
  ];
  final find = jsonDecode(File('eval/find.json').readAsStringSync()) as Map<String, dynamic>;

  var n = 0;
  final ctx = Ctx(newId: () => 'id${n++}', now: () => DateTime(2026, 1, 1));
  final space = addSpace(const HomeData(), ctx, 'Home');
  final box = addContainer(space.data, ctx, spaceId: space.value.id, name: 'Box');
  var home = box.data;
  for (final name in (find['home'] as List).cast<String>()) {
    home = addItem(home, ctx, containerId: box.value.id, name: name).data;
  }

  // The same home with every classify name added (about 200 items).
  var big = home;
  for (final c in classify) {
    big = addItem(big, ctx, containerId: box.value.id, name: c['name'] as String).data;
  }

  stdout.writeln(
    jsonEncode({
      'classify': [
        for (final c in classify)
          {'name': c['name'], 'category': guessCategory(c['name'] as String)?.name, 'icon': iconsFromName(c['name'] as String).firstOrNull},
      ],
      'find': [
        for (final q in (find['questions'] as List).cast<Map<String, dynamic>>())
          {'query': q['query'], 'answer': searchItems(home, q['query'] as String).firstOrNull?.item.name},
      ],
      'findBig': [
        for (final q in (find['questions'] as List).cast<Map<String, dynamic>>())
          {'query': q['query'], 'answer': searchItems(big, q['query'] as String).firstOrNull?.item.name},
      ],
    }),
  );
}

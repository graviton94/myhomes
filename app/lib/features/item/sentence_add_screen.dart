import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_icons.dart';
import '../../widgets/sheets.dart';

/// "One place, one sentence": pick where, write the names in one line
/// ("가위, 박스테이프랑 AA 건전지 4개"), save them all as one change.
class SentenceAddScreen extends ConsumerStatefulWidget {
  const SentenceAddScreen({super.key, this.storageId});

  final String? storageId;

  @override
  ConsumerState<SentenceAddScreen> createState() => _SentenceAddScreenState();
}

class _SentenceAddScreenState extends ConsumerState<SentenceAddScreen> {
  final _text = TextEditingController();
  String? _place;
  List<ParsedItem> _items = const [];

  @override
  void initState() {
    super.initState();
    final d = ref.read(homeProvider).requireValue;
    _place = widget.storageId ?? recentPlaces(d, limit: 1).firstOrNull;
    _text.addListener(() => setState(() => _items = parseItemSentence(_text.text)));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String _placeName(HomeData d, String id) {
    final s = d.container(id)!;
    return pathText([d.space(s.spaceId)?.name ?? '', s.name]);
  }

  Future<void> _pickOther() async {
    final id = await pickStorage(context, title: AppLocalizations.of(context).addWhere);
    if (id != null) setState(() => _place = id);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final place = _place;
    if (place == null) {
      showMessage(context, l.sentenceNoPlace);
      return;
    }
    final d = ref.read(homeProvider).requireValue;
    final name = d.container(place)!.name;
    final count = _items.length;
    await ref.read(homeProvider.notifier).apply((d, ctx) => addItemsFromSentence(d, ctx, place, _items));
    if (!mounted) return;
    showUndo(context, ref, l.sentenceSaved(count, name));
    context.canPop() ? context.pop() : context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final text = Theme.of(context).textTheme;
    final d = ref.watch(homeProvider).requireValue;
    final place = _place != null && d.container(_place!) != null ? _place : null;
    final recent = {?place, ...recentPlaces(d)}.toList();

    return Scaffold(
      appBar: AppBar(title: Text(l.sentenceTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xl),
              children: [
                Text(l.addWhere, style: text.titleSmall),
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final id in recent)
                      ChoiceChip(
                        avatar: storageGlyph(d.container(id)!, size: 18, color: id == place ? c.primaryInk : c.mutedFg),
                        label: Text(_placeName(d, id)),
                        selected: id == place,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _place = id),
                      ),
                    ActionChip(
                      avatar: Icon(Icons.travel_explore_rounded, size: 18, color: c.mutedFg),
                      label: Text(l.sentencePickOther),
                      onPressed: _pickOther,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
                Text(l.sentenceWhat, style: text.titleSmall),
                const SizedBox(height: AppSpace.sm),
                TextField(
                  controller: _text,
                  autofocus: place != null,
                  minLines: 2,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(hintText: l.sentenceHint, helperText: l.sentenceVoice),
                ),
                if (_items.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: [
                      for (final i in _items)
                        Chip(
                          avatar: glyph(iconsFromName(i.name).firstOrNull, Icons.category_rounded, size: 18, color: c.primaryInk),
                          label: Text(i.qty > 1 ? '${i.name}  ×${i.qty}' : i.name),
                        ),
                    ],
                  ),
                  if (place != null)
                    for (final i in _items)
                      if (sameNameIn(d, place, i.name) case final have?)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpace.sm),
                          child: Row(
                            children: [
                              Icon(Icons.merge_rounded, size: 18, color: c.mutedFg),
                              const SizedBox(width: AppSpace.xs),
                              Expanded(
                                child: Text(
                                  l.sentenceMerge(have.name, have.qty, have.qty + i.qty),
                                  style: text.bodySmall?.copyWith(color: c.mutedFg),
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
                const SizedBox(height: AppSpace.lg),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => context.push(place == null ? '/item/new' : '/item/new?storage=$place'),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(l.sentenceDetails),
                  ),
                ),
              ],
            ),
          ),
          // In the body, not bottomNavigationBar, so it rides above the keyboard.
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _items.isEmpty ? null : _save,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(_items.isEmpty ? l.sentenceTitle : l.sentenceSave(_items.length)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

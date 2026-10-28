import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/header_line.dart';
import 'house_words.dart';
import 'plan_preview.dart';

/// HOU-01: pick the closest floor plan, start from empty squares, or keep
/// the list without a map.
class HouseSetupScreen extends ConsumerStatefulWidget {
  const HouseSetupScreen({super.key});

  @override
  ConsumerState<HouseSetupScreen> createState() => _HouseSetupScreenState();
}

class _HouseSetupScreenState extends ConsumerState<HouseSetupScreen> {
  int _picked = 0;

  Future<void> _start() async {
    final l = AppLocalizations.of(context);
    final t = houseTemplates[_picked];
    await ref.read(homeProvider.notifier).apply((d, ctx) => applyTemplate(d, ctx, t, (k) => roomName(l, k)));
    if (mounted) context.pushReplacement('/house/edit');
  }

  /// Rooms already made go on empty squares, side by side, to be arranged.
  Future<void> _blank() async {
    await ref.read(homeProvider.notifier).apply((d, ctx) {
      var data = d;
      for (final s in d.spaces.where((s) => !s.outside && s.plan == null)) {
        data = setRoomPlan(data, s.id, freePlanSpot(data));
      }
      return data;
    });
    if (mounted) context.pushReplacement('/house/edit');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.houseSetupTitle), actions: const [SettingsButton()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xl),
        children: [
          Text(l.houseSetupBody, style: t.bodyMedium?.copyWith(color: c.mutedFg)),
          const SizedBox(height: AppSpace.md),
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - AppSpace.sm) / 2;
              return Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final (i, tpl) in houseTemplates.indexed)
                    SizedBox(
                      width: w,
                      child: _TemplateCard(template: tpl, selected: i == _picked, onTap: () => setState(() => _picked = i)),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpace.lg),
          FilledButton(key: const ValueKey('use-template'), onPressed: _start, child: Text(l.houseUseThis)),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(onPressed: _blank, child: Text(l.houseBlank)),
          TextButton(onPressed: () => context.pop(), child: Text(l.houseNoMap)),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.selected, required this.onTap});

  final HouseTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final (name, body) = templateWords(l, template.id);
    return Material(
      color: selected ? c.primarySoft : c.card,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        key: ValueKey('tpl-${template.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpace.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: selected ? c.primary : c.border, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 92,
                child: Center(child: PlanPreview(template: template)),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(name, style: AppType.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                body,
                style: AppType.caption.copyWith(color: c.mutedFg),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

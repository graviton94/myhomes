import 'package:flutter/material.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/dday_badge.dart';
import '../../widgets/fairy.dart';
import '../../widgets/inventory_slot.dart';

/// Living style guide: colours, type and parts as the app renders them.
class DesignSampleScreen extends StatelessWidget {
  const DesignSampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final today = DateTime.now();
    ExpiryStatus inDays(int d) => expiryStatus(today: today, expiresOn: today.add(Duration(days: d)));

    final fairies = {
      FairyPose.hello: l.fairyHello,
      FairyPose.found: l.fairyFound,
      FairyPose.carry: l.fairyCarry,
      FairyPose.worry: l.fairyWorry,
      FairyPose.cheer: l.fairyCheer,
      FairyPose.sleep: l.fairySleep,
    };
    final swatches = {
      'primary': c.primary,
      'secondary': c.secondary,
      'accent': c.accent,
      'danger': c.danger,
      'bg': c.bg,
      'card': c.card,
      'fg': c.fg,
      'mutedFg': c.mutedFg,
      'border': c.border,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l.designSample)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.xxl),
        children: [
          _Heading(l.sampleFairy),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final e in fairies.entries)
                SizedBox(
                  width: 96,
                  child: Column(children: [Fairy(e.key, height: 96), Text(e.value, style: t.labelMedium)]),
                ),
            ],
          ),
          _Heading(l.sampleColors),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final e in swatches.entries)
                Container(
                  width: 96,
                  decoration: BoxDecoration(
                    color: c.card,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 40, color: e.value),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Text(e.key, style: AppType.code.copyWith(color: c.mutedFg)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          _Heading(l.sampleType),
          Text(l.appTitle, style: t.displaySmall),
          Text(l.homeEmptyTitle, style: t.titleLarge),
          Text(l.homeGreeting, style: t.titleMedium),
          Text(l.homeEmptyBody, style: t.bodyLarge),
          Text(l.searchEmptyBody, style: t.bodySmall),
          Text('LIV-A1-L', style: AppType.code.copyWith(color: c.mutedFg)),
          _Heading(l.sampleParts),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              FilledButton(onPressed: () {}, child: Text(l.sampleButtonPrimary)),
              OutlinedButton(onPressed: () {}, child: Text(l.sampleButtonSecondary)),
              TextButton(onPressed: () {}, child: Text(l.sampleButtonText)),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              FilterChip(label: Text(l.sampleCategoryFood), selected: true, onSelected: (_) {}),
              FilterChip(label: Text(l.sampleCategoryHousehold), selected: false, onSelected: (_) {}),
              FilterChip(label: Text(l.sampleCategoryTools), selected: false, onSelected: (_) {}),
              FilterChip(label: Text(l.sampleCategoryMedicine), selected: false, onSelected: (_) {}),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [for (final d in [-2, 0, 1, 3, 10]) DdayBadge(inDays(d))],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              InventorySlot(semanticLabel: l.sampleSlotEmpty),
              InventorySlot(icon: Icons.battery_full_rounded, category: ItemCategory.household, quantity: 8, semanticLabel: l.sampleSlotFilled),
              InventorySlot(icon: Icons.battery_full_rounded, category: ItemCategory.household, quantity: 8, selected: true, semanticLabel: l.sampleSlotSelected),
              InventorySlot(icon: Icons.local_drink_outlined, category: ItemCategory.food, quantity: 2, expiring: true, semanticLabel: l.sampleSlotExpiring),
              InventorySlot(icon: Icons.battery_full_rounded, category: ItemCategory.household, quantity: 8, chosen: 4, semanticLabel: l.sampleSlotChosen),
            ],
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.md),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

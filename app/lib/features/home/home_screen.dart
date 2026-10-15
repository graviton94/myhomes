import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/fairy.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).comingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.myHome),
        actions: [
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.xl),
        children: [
          _FairySays(text: l.homeGreeting),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              _QuickAction(icon: Icons.photo_camera_outlined, label: l.quickAdd, color: c.primaryInk, onTap: () => _soon(context)),
              const SizedBox(width: AppSpace.sm),
              _QuickAction(icon: Icons.swap_horiz_rounded, label: l.quickMove, color: c.accentInk, onTap: () => _soon(context)),
              const SizedBox(width: AppSpace.sm),
              _QuickAction(icon: Icons.back_hand_outlined, label: l.quickUse, color: c.secondaryInk, onTap: () => _soon(context)),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          TextField(
            readOnly: true,
            onTap: () => context.go('/search'),
            decoration: InputDecoration(hintText: l.searchHint, prefixIcon: const Icon(Icons.search_rounded)),
          ),
          const SizedBox(height: AppSpace.lg),
          Card(
            child: EmptyState(
              pose: FairyPose.carry,
              title: l.homeEmptyTitle,
              body: l.homeEmptyBody,
              action: FilledButton.icon(
                onPressed: () => _soon(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(l.addSpace),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FairySays extends StatelessWidget {
  const _FairySays({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = HfColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Fairy(FairyPose.hello, height: 64),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 10),
            decoration: BoxDecoration(
              color: c.card,
              border: Border.all(color: c.border),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
                bottomRight: Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: AppSpace.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 26),
                  const SizedBox(height: 6),
                  Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

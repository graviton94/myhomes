import 'package:flutter/material.dart';

import '../design/tokens.g.dart';
import 'fairy.dart';

/// Fairy + title + one helpful sentence + optional action. Used wherever a
/// list has nothing in it yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.pose,
    required this.title,
    required this.body,
    this.action,
  });

  final FairyPose pose;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Fairy(pose, height: 132),
          const SizedBox(height: AppSpace.md),
          Text(title, style: t.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpace.sm),
          Text(body, style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: AppSpace.lg), action!],
        ],
      ),
    );
  }
}

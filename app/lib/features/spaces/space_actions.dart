import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/photo_picker.dart';

/// Asks for a room name (and an optional photo), creates the space and opens it.
Future<void> addSpaceFlow(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final r = await askNameAndPhoto(context, title: l.addSpace, label: l.spaceNameHint);
  if (r == null || !context.mounted) return;
  final space = await ref.read(homeProvider.notifier).apply<Space>((d, ctx) => addSpace(d, ctx, r.name, photoPath: r.photoPath));
  if (space != null && context.mounted) context.push('/space/${space.id}');
}

/// Asks for a storage name (and an optional photo), creates it and opens it.
Future<void> addStorageFlow(BuildContext context, WidgetRef ref, String spaceId) async {
  final l = AppLocalizations.of(context);
  final r = await askNameAndPhoto(context, title: l.addStorage, label: l.storageNameHint);
  if (r == null || !context.mounted) return;
  final s = await ref
      .read(homeProvider.notifier)
      .apply<Storage>((d, ctx) => addContainer(d, ctx, spaceId: spaceId, name: r.name, photoPath: r.photoPath));
  if (s != null && context.mounted) context.push('/storage/${s.id}');
}

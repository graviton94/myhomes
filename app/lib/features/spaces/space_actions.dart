import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/photo_picker.dart';
import '../../widgets/sheets.dart';

/// Asks for a room (name, icon, optional photo) and creates it. Opens it
/// unless [open] is false. Returns the new space.
Future<Space?> addSpaceFlow(BuildContext context, WidgetRef ref, {bool open = true}) async {
  final l = AppLocalizations.of(context);
  final r = await askNameAndPhoto(context, title: l.addSpace, label: l.spaceNameHint, kind: IconKind.space);
  if (r == null || !context.mounted) return null;
  final space = await ref
      .read(homeProvider.notifier)
      .apply<Space>((d, ctx) => addSpace(d, ctx, r.name, photoPath: r.photoPath, icon: r.icon));
  if (open && space != null && context.mounted) context.push('/space/${space.id}');
  return space;
}

Future<void> editSpaceFlow(BuildContext context, WidgetRef ref, Space space) async {
  final l = AppLocalizations.of(context);
  final r = await askNameAndPhoto(
    context,
    title: l.editSpace,
    label: l.spaceNameHint,
    kind: IconKind.space,
    name: space.name,
    photoPath: space.photoPath,
    icon: space.icon,
  );
  if (r == null) return;
  await ref
      .read(homeProvider.notifier)
      .apply((d, _) => updateSpace(d, space.id, name: r.name, photoPath: r.photoPath, clearPhoto: r.photoPath == null, icon: r.icon));
}

/// Deletes a room after asking. Returns true when deleted.
Future<bool> deleteSpaceFlow(BuildContext context, WidgetRef ref, Space space) async {
  final l = AppLocalizations.of(context);
  final ok = await confirm(context, title: l.deleteSpaceTitle(space.name), body: l.deleteSpaceBody, action: l.delete);
  if (!ok) return false;
  await ref.read(homeProvider.notifier).apply((d, _) => deleteSpace(d, space.id));
  return true;
}

/// Asks for a storage spot (name, icon, optional photo) and adds it to the room.
Future<Storage?> addStorageFlow(BuildContext context, WidgetRef ref, String spaceId) async {
  final l = AppLocalizations.of(context);
  final r = await askNameAndPhoto(context, title: l.addStorage, label: l.storageNameHint, kind: IconKind.storage);
  if (r == null || !context.mounted) return null;
  return ref
      .read(homeProvider.notifier)
      .apply<Storage>((d, ctx) => addContainer(d, ctx, spaceId: spaceId, name: r.name, photoPath: r.photoPath, icon: r.icon));
}

Future<void> editStorageFlow(BuildContext context, WidgetRef ref, Storage s) async {
  final l = AppLocalizations.of(context);
  final r = await askNameAndPhoto(
    context,
    title: l.editStorage,
    label: l.storageNameHint,
    kind: IconKind.storage,
    name: s.name,
    photoPath: s.photoPath,
    icon: s.icon,
  );
  if (r == null) return;
  await ref
      .read(homeProvider.notifier)
      .apply((d, _) => updateContainer(d, s.id, name: r.name, photoPath: r.photoPath, clearPhoto: r.photoPath == null, icon: r.icon));
}

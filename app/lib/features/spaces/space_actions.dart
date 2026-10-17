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
Future<Space?> addSpaceFlow(BuildContext context, WidgetRef ref, {bool open = true, bool outside = false}) async {
  final l = AppLocalizations.of(context);
  final r = await askNameAndPhoto(
    context,
    title: outside ? l.addOutside : l.addSpace,
    label: outside ? l.outsideNameHint : l.spaceNameHint,
    kind: outside ? IconKind.outside : IconKind.space,
  );
  if (r == null || !context.mounted) return null;
  final space = await ref
      .read(homeProvider.notifier)
      .apply<Space>((d, ctx) => addSpace(d, ctx, r.name, photoPath: r.photoPath, icon: r.icon, outside: outside));
  if (open && space != null && context.mounted) context.push('/space/${space.id}');
  return space;
}

/// Edit sheet for a room; its delete button asks first. [onDeleted] runs
/// after a delete (e.g. to leave a screen that showed the room).
Future<void> editSpaceFlow(BuildContext context, WidgetRef ref, Space space, {VoidCallback? onDeleted}) async {
  final l = AppLocalizations.of(context);
  final r = await askNameAndPhoto(
    context,
    title: l.editSpace,
    label: space.outside ? l.outsideNameHint : l.spaceNameHint,
    kind: space.outside ? IconKind.outside : IconKind.space,
    name: space.name,
    photoPath: space.photoPath,
    icon: space.icon,
    deleteLabel: l.deleteSpaceNamed(space.name),
    onDelete: () async {
      if (await deleteSpaceFlow(context, ref, space)) onDeleted?.call();
    },
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
  final outside = ref.read(homeProvider).requireValue.space(spaceId)?.outside ?? false;
  final r = await askNameAndPhoto(
    context,
    title: l.addStorage,
    label: outside ? l.outsideStorageHint : l.storageNameHint,
    kind: IconKind.storage,
    askReturnBy: outside,
  );
  if (r == null || !context.mounted) return null;
  return ref
      .read(homeProvider.notifier)
      .apply<Storage>(
        (d, ctx) => addContainer(d, ctx, spaceId: spaceId, name: r.name, photoPath: r.photoPath, icon: r.icon, returnBy: r.returnBy),
      );
}

/// Deletes a storage spot and what is in it, after asking. Returns true when deleted.
Future<bool> deleteStorageFlow(BuildContext context, WidgetRef ref, Storage s) async {
  final l = AppLocalizations.of(context);
  final count = ref.read(homeProvider).requireValue.itemsIn(s.id).length;
  final ok = await confirm(context, title: l.deleteStorageTitle(s.name), body: l.deleteStorageBody(count), action: l.delete);
  if (!ok) return false;
  await ref.read(homeProvider.notifier).apply((d, _) => deleteContainer(d, s.id));
  return true;
}

/// Edit sheet for a storage spot; its delete button asks first.
Future<void> editStorageFlow(BuildContext context, WidgetRef ref, Storage s, {VoidCallback? onDeleted}) async {
  final l = AppLocalizations.of(context);
  final outside = ref.read(homeProvider).requireValue.space(s.spaceId)?.outside ?? false;
  final r = await askNameAndPhoto(
    context,
    title: l.editStorage,
    label: outside ? l.outsideStorageHint : l.storageNameHint,
    kind: IconKind.storage,
    name: s.name,
    photoPath: s.photoPath,
    icon: s.icon,
    askReturnBy: outside || s.returnBy != null,
    returnBy: s.returnBy,
    deleteLabel: l.deleteStorageNamed(s.name),
    onDelete: () async {
      if (await deleteStorageFlow(context, ref, s)) onDeleted?.call();
    },
  );
  if (r == null) return;
  await ref
      .read(homeProvider.notifier)
      .apply(
        (d, _) => updateContainer(
          d,
          s.id,
          name: r.name,
          photoPath: r.photoPath,
          clearPhoto: r.photoPath == null,
          icon: r.icon,
          returnBy: r.returnBy,
          clearReturnBy: r.returnBy == null,
        ),
      );
}

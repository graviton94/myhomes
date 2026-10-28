import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';

import '../../data/home_store.dart';
import '../../design/theme.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_icons.dart';
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

/// Adds a storage spot to the room: first what kind (furniture, box or spot),
/// then its name, icon and optional photo; furniture also gets its shelves
/// and drawers. Places outside the home only have spots.
Future<Storage?> addStorageFlow(BuildContext context, WidgetRef ref, String spaceId, {String? parentId}) async {
  final l = AppLocalizations.of(context);
  final d = ref.read(homeProvider).requireValue;
  final outside = d.space(spaceId)?.outside ?? false;
  final kind = outside ? StorageKind.spot : (parentId != null ? StorageKind.box : await pickStorageKind(context));
  if (kind == null || !context.mounted) return null;
  final r = await askNameAndPhoto(
    context,
    title: switch (kind) {
      StorageKind.furniture => l.kindFurniture,
      StorageKind.box => l.kindBox,
      _ => l.addStorage,
    },
    label: switch (kind) {
      StorageKind.furniture => l.furnitureNameHint,
      StorageKind.box => l.boxNameHint,
      _ => outside ? l.outsideStorageHint : l.storageNameHint,
    },
    name: kind == StorageKind.box ? l.boxName(nextBoxNumber(d)) : '',
    kind: IconKind.storage,
    askReturnBy: outside,
  );
  if (r == null || !context.mounted) return null;
  final home = ref.read(homeProvider.notifier);
  switch (kind) {
    case StorageKind.furniture:
      final sections = await askSections(context);
      if (sections == null) return null;
      return home.apply<Storage>(
        (d, ctx) => addFurniture(d, ctx, spaceId: spaceId, name: r.name, sections: sections, photoPath: r.photoPath, icon: r.icon),
      );
    case StorageKind.box:
      return home.apply<Storage>(
        (d, ctx) => addBox(d, ctx, spaceId: spaceId, name: r.name, parentId: parentId, photoPath: r.photoPath, icon: r.icon ?? 'box'),
      );
    case StorageKind.spot:
    case StorageKind.section:
      return home.apply<Storage>(
        (d, ctx) => addContainer(d, ctx, spaceId: spaceId, name: r.name, photoPath: r.photoPath, icon: r.icon, returnBy: r.returnBy),
      );
  }
}

/// Furniture, box or spot, each with what it is for.
Future<StorageKind?> pickStorageKind(BuildContext context) {
  final l = AppLocalizations.of(context);
  return showModalBottomSheet<StorageKind>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      final c = HfColors.of(context);
      Widget option(StorageKind k, IconData icon, String title, String body) => ListTile(
        key: ValueKey('kind-${k.name}'),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: c.accentInk),
        ),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        subtitle: Text(body),
        onTap: () => Navigator.pop(context, k),
      );
      return SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: AppSpace.md + MediaQuery.viewPaddingOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(l.kindTitle),
              option(StorageKind.furniture, Icons.shelves, l.kindFurniture, l.kindFurnitureBody),
              option(StorageKind.box, Icons.inventory_2_rounded, l.kindBox, l.kindBoxBody),
              option(StorageKind.spot, Icons.place_rounded, l.kindSpot, l.kindSpotBody),
            ],
          ),
        ),
      );
    },
  );
}

/// Shelf and drawer names for new furniture, top to bottom.
Future<List<String>?> askSections(BuildContext context) async {
  final l = AppLocalizations.of(context);
  final text = TextEditingController(text: l.sectionsDefault);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l.sectionsTitle),
      content: TextField(
        key: const ValueKey('sections'),
        controller: text,
        autofocus: true,
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(helperText: l.sectionsHint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.save)),
      ],
    ),
  );
  // Not disposed here: the dialog's closing animation still shows the field.
  final value = text.text;
  if (ok != true) return null;
  return [
    for (final p in value.split(RegExp(r'[,，、\n]')))
      if (p.trim().isNotEmpty) p.trim(),
  ];
}

/// Moves a box with everything in it: to a section, another box or a room's floor.
Future<void> moveBoxFlow(BuildContext context, WidgetRef ref, Storage box) async {
  final l = AppLocalizations.of(context);
  final target = await pickBoxPlace(context, box);
  if (target == null || !context.mounted) return;
  final (spaceId, parentId) = target;
  await ref.read(homeProvider.notifier).apply((d, _) => moveContainer(d, box.id, spaceId: spaceId, parentId: parentId));
  if (!context.mounted) return;
  final d = ref.read(homeProvider).requireValue;
  final place = parentId == null ? l.floorOf(d.space(spaceId)!.name) : pathText(d.pathOf(parentId));
  showUndo(context, ref, l.boxMoved(box.name, place));
}

/// Where a box can go: each room's floor, and every section, box or spot
/// that is not the box itself or inside it. Returns (room id, parent id).
Future<(String, String?)?> pickBoxPlace(BuildContext context, Storage box) {
  final l = AppLocalizations.of(context);
  return showModalBottomSheet<(String, String?)>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final d = ref.watch(homeProvider).requireValue;
        final c = HfColors.of(context);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.94,
          builder: (context, scroll) => Column(
            children: [
              SheetHeader(l.moveBoxWhere),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: EdgeInsets.only(bottom: AppSpace.xl + MediaQuery.viewPaddingOf(context).bottom),
                  children: [
                    for (final space in spacesInOrder(d).where((s) => !s.outside)) ...[
                      ListTile(
                        leading: spaceGlyph(space, size: 22, color: c.secondaryInk),
                        title: Text(l.floorOf(space.name)),
                        enabled: canMoveContainer(d, box.id, null),
                        onTap: () => Navigator.pop(context, (space.id, null)),
                      ),
                      for (final s in placesIn(d, space.id))
                        if (s.id != box.id && canMoveContainer(d, box.id, s.id))
                          ListTile(
                            contentPadding: const EdgeInsets.only(left: AppSpace.xl * 2, right: AppSpace.lg),
                            leading: storageGlyph(s, size: 20, color: c.accentInk),
                            title: Text(pathText(d.pathOf(s.id).skip(1).toList())),
                            onTap: () => Navigator.pop(context, (space.id, s.id)),
                          ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
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

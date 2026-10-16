import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/home_store.dart';
import '../design/theme.dart';
import '../design/tokens.g.dart';
import '../l10n/app_localizations.dart';
import 'sheets.dart';

/// Camera / gallery / remove. Returns null when dismissed, `(path: null)`
/// when the photo was removed, or the new photo's path in the app folder.
Future<({String? path})?> choosePhoto(BuildContext context, WidgetRef ref, {required bool hasPhoto}) async {
  final l = AppLocalizations.of(context);
  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(l.photo),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(l.takePhoto),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.chooseFromGallery),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.hide_image_outlined),
              title: Text(l.removePhoto),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
        ],
      ),
    ),
  );
  if (choice == null) return null;
  if (choice == 'remove') return (path: null);
  final picked = await ImagePicker().pickImage(
    source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
    maxWidth: 1280,
    imageQuality: 82,
  );
  if (picked == null) return null;
  final dir = ref.read(photoDirProvider);
  await dir.create(recursive: true);
  final path = '${dir.path}/${ref.read(ctxProvider).newId()}.jpg';
  await picked.saveTo(path);
  return (path: path);
}

/// Wide photo area: the photo, or a centred camera icon with a label.
class PhotoBox extends StatelessWidget {
  const PhotoBox({super.key, required this.photoPath, required this.onTap, this.height = 160, this.label});

  final String? photoPath;
  final VoidCallback onTap;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = HfColors.of(context);
    final t = Theme.of(context).textTheme;
    final has = photoPath != null && File(photoPath!).existsSync();
    final radius = BorderRadius.circular(AppRadius.lg);
    return Semantics(
      button: true,
      label: has ? l.changePhoto : (label ?? l.addPhoto),
      child: Material(
        color: c.muted,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: has
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(photoPath!), fit: BoxFit.cover, cacheWidth: 900),
                      Positioned(
                        right: AppSpace.sm,
                        bottom: AppSpace.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.card.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_camera_outlined, size: 16, color: c.fg),
                              const SizedBox(width: 6),
                              Text(l.changePhoto, style: t.labelMedium?.copyWith(color: c.fg)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 32, color: c.mutedFg),
                      const SizedBox(height: AppSpace.sm),
                      Text(label ?? l.addPhoto, style: t.labelLarge?.copyWith(color: c.mutedFg)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with a photo and a name, for spaces and storage spots.
/// Returns null when cancelled.
Future<({String name, String? photoPath})?> askNameAndPhoto(
  BuildContext context, {
  required String title,
  required String label,
  String name = '',
  String? photoPath,
}) {
  return showModalBottomSheet<({String name, String? photoPath})>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _NamePhotoSheet(title: title, label: label, name: name, photoPath: photoPath),
  );
}

class _NamePhotoSheet extends ConsumerStatefulWidget {
  const _NamePhotoSheet({required this.title, required this.label, required this.name, this.photoPath});

  final String title;
  final String label;
  final String name;
  final String? photoPath;

  @override
  ConsumerState<_NamePhotoSheet> createState() => _NamePhotoSheetState();
}

class _NamePhotoSheetState extends ConsumerState<_NamePhotoSheet> {
  late final _name = TextEditingController(text: widget.name);
  late String? _photo = widget.photoPath;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _name.text.trim();
    if (v.isEmpty) return;
    Navigator.pop(context, (name: v, photoPath: _photo));
  }

  Future<void> _pick() async {
    final r = await choosePhoto(context, ref, hasPhoto: _photo != null);
    if (r != null && mounted) setState(() => _photo = r.path);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SheetHeader(widget.title),
              const SizedBox(height: AppSpace.sm),
              PhotoBox(photoPath: _photo, onTap: _pick, height: 140, label: l.addPhotoOptional),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: _name,
                autofocus: widget.name.isEmpty,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: widget.label),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpace.lg),
              FilledButton(onPressed: _submit, child: Text(l.save)),
            ],
          ),
        ),
      ),
    );
  }
}

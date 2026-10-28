import 'dart:io';

import 'package:flutter/material.dart';

import '../data/household.dart';
import 'photo_picker.dart';

/// Whether [path] can be shown: taken on this phone, or in the shared home.
bool photoAvailable(String? path) => path != null && (File(path).existsSync() || PhotoCloud.current != null);

/// A photo from the photo folder. In a shared home, one taken on another
/// phone is fetched the first time it is shown.
class LocalPhoto extends StatefulWidget {
  const LocalPhoto(this.path, {super.key, this.width, this.height, this.cacheWidth, this.thumb = false, this.fit = BoxFit.cover});

  final String path;
  final double? width;
  final double? height;
  final int? cacheWidth;
  final BoxFit fit;

  /// Use the small copy when there is one (list thumbnails).
  final bool thumb;

  @override
  State<LocalPhoto> createState() => _LocalPhotoState();
}

class _LocalPhotoState extends State<LocalPhoto> {
  File? _file;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(LocalPhoto old) {
    super.didUpdateWidget(old);
    if (old.path != widget.path) _resolve();
  }

  void _resolve() {
    final cloud = PhotoCloud.current;
    final f = cloud?.localFile(widget.path) ?? File(widget.path);
    _file = f.existsSync() ? f : null;
    if (_file == null && cloud != null) {
      final path = widget.path;
      cloud.fetch(path).then((got) {
        if (mounted && got != null && widget.path == path) setState(() => _file = got);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = _file;
    if (f == null) return SizedBox(width: widget.width, height: widget.height);
    return Image.file(
      File(widget.thumb ? thumbOf(f.path) : f.path),
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.cacheWidth,
      errorBuilder: (_, _, _) => SizedBox(width: widget.width, height: widget.height),
    );
  }
}

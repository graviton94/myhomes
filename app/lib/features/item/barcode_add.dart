import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homefairy_core/homefairy_core.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/barcode.dart';
import '../../data/home_store.dart';
import '../../design/tokens.g.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/doodle.dart';
import '../../widgets/fit_text.dart';
import '../../widgets/sheets.dart';

/// Scan a barcode. Already in the home: one more of it. New: the food
/// product's name is filled in on the item form ([storageId] preselected).
Future<void> addByBarcode(BuildContext context, WidgetRef ref, {String? storageId}) async {
  final code = await Navigator.of(
    context,
    rootNavigator: true,
  ).push<String>(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const BarcodeScanScreen()));
  if (code == null || !context.mounted) return;
  await handleBarcode(context, ref, code, storageId: storageId);
}

/// What a scanned [code] does: one more of a known item, or a new item with its name.
Future<void> handleBarcode(BuildContext context, WidgetRef ref, String code, {String? storageId}) async {
  final l = AppLocalizations.of(context);
  final d = ref.read(homeProvider).requireValue;
  final known = itemWithBarcode(d, code);
  if (known != null) {
    final more = await confirm(
      context,
      title: known.name,
      body: l.barcodeKnown(known.qty, pathText(d.pathOf(known.containerId))),
      action: l.barcodeOneMore,
    );
    if (!more || !context.mounted) return;
    await ref.read(homeProvider.notifier).apply((d, ctx) => adjustQty(d, ctx, known.id, 1));
    if (context.mounted) showMessage(context, l.barcodeAdded(known.name, known.qty + 1));
    return;
  }
  showMessage(context, l.barcodeLooking);
  final name = await ref.read(barcodeLookupProvider).nameOf(code);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  if (name == null) showMessage(context, l.barcodeUnknown);
  final q = {'storage': ?storageId, 'name': ?name, 'barcode': code};
  context.push(Uri(path: '/item/new', queryParameters: q).toString());
}

/// The camera, with a crayon frame to aim at the barcode.
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final _camera = MobileScannerController(formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE]);
  bool _done = false;

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(l.barcodeTitle)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _camera,
            onDetect: (capture) {
              final code = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
              if (code == null || _done) return;
              _done = true;
              Navigator.pop(context, code);
            },
          ),
          IgnorePointer(child: CustomPaint(painter: _AimPainter())),
          Positioned(
            left: AppSpace.lg,
            right: AppSpace.lg,
            bottom: AppSpace.xl,
            child: FitText(
              l.barcodeHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AimPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width * 0.72, h = w * 0.5;
    final r = Rect.fromCenter(center: size.center(Offset.zero), width: w, height: h);
    final frame = Path()..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(16)));
    Doodle.crayon(canvas, frame, Doodle.line(Doodle.honey, 4), wobble: 1.2, step: 4, seed: 9);
  }

  @override
  bool shouldRepaint(_AimPainter old) => false;
}

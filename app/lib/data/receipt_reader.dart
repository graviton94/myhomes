import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:homefairy_core/homefairy_core.dart';

/// Reads a receipt photo into printed rows, on the phone (no photo leaves it).
abstract interface class ReceiptReader {
  /// The receipt's rows top to bottom, or null when nothing could be read.
  Future<List<String>?> read(String imagePath);
}

class NoReceiptReader implements ReceiptReader {
  const NoReceiptReader();

  @override
  Future<List<String>?> read(String imagePath) async => null;
}

/// Google ML Kit's Korean text recognition (also reads Latin letters and numbers).
class MlKitReceiptReader implements ReceiptReader {
  @override
  Future<List<String>?> read(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    try {
      final text = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      final pieces = [
        for (final block in text.blocks)
          for (final line in block.lines) OcrPiece(line.text, line.boundingBox.left, line.boundingBox.top, line.boundingBox.height),
      ];
      return pieces.isEmpty ? null : receiptRows(pieces);
    } catch (e) {
      debugPrint('receipt: ${e.runtimeType}');
      return null;
    } finally {
      await recognizer.close();
    }
  }
}

/// Overridden in main() on Android.
final receiptReaderProvider = Provider<ReceiptReader>((ref) => const NoReceiptReader());

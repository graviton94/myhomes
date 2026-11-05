import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speech to text for the search box ("가위 어디 있어?" said, not typed).
/// The phone's own recogniser does the listening; nothing goes to our server.
abstract interface class Voice {
  /// Listens once in [localeId] ("ko_KR"). [onWords] gets the words so far
  /// and whether they are final. False when the phone cannot listen (no
  /// permission, no recogniser).
  Future<bool> listen(String localeId, void Function(String words, bool done) onWords);

  Future<void> stop();
}

/// Tests and phones without a recogniser.
class NoVoice implements Voice {
  const NoVoice();

  @override
  Future<bool> listen(String localeId, void Function(String words, bool done) onWords) async => false;

  @override
  Future<void> stop() async {}
}

class PhoneVoice implements Voice {
  final _stt = SpeechToText();
  bool? _ready;

  @override
  Future<bool> listen(String localeId, void Function(String words, bool done) onWords) async {
    try {
      _ready ??= await _stt.initialize(onError: (e) => debugPrint('voice: ${e.errorMsg}'));
      if (_ready != true) return false;
      await _stt.listen(
        onResult: (r) => onWords(r.recognizedWords, r.finalResult),
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: const Duration(seconds: 12),
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
          listenMode: ListenMode.search,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('voice: ${e.runtimeType}');
      return false;
    }
  }

  @override
  Future<void> stop() => _stt.stop();
}

/// Overridden in main() with [PhoneVoice] on Android.
final voiceProvider = Provider<Voice>((ref) => const NoVoice());

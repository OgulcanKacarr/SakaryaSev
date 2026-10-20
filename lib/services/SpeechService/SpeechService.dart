
import 'package:flutter/foundation.dart';
import 'EdgeSpeechEngine/EdgeSpeechEngine.dart';
import 'PiperSpeechEngine/PiperSpeechEngine.dart';
import 'SpeechEngine.dart';
import 'TtsSpeechEngine/TtsSpeechEngine.dart';
import 'WindowsSpeechEngine/WindowsSpeechEngine.dart';


class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();

  final List<SpeechEngine> _engines = [
    EdgeSpeechEngine(),   // İnternet üzerinden doğal ses
    PiperSpeechEngine(),  // Önce yerel sinir ağı sesi
    WindowsTtsEngine(),   // Yerel Windows TTS yedeği
    WindowsSpeechEngine(), // Son çare
  ];

  // Aynı anda iki motorun konuşmasını engeller.
  Future<void> _queue = Future<void>.value();

  /// Yeni bir motoru tercih sırasına ekler.
  /// Windows motoru her zaman son sırada tutulur.
  void registerEngine(SpeechEngine engine) {
    _engines.removeWhere((item) => item.name == engine.name);

    final int windowsIndex = _engines.indexWhere(
          (item) => item is WindowsSpeechEngine,
    );

    if (engine is WindowsSpeechEngine || windowsIndex == -1) {
      _engines.add(engine);
    } else {
      _engines.insert(windowsIndex, engine);
    }
  }

  Future<void> speak(
      String text, {
        required String voiceGender,
      }) {
    final Future<void> task = _queue.then(
          (_) => _speakWithFallback(
        text,
        voiceGender: voiceGender,
      ),
    );

    // Bir başarısız çağrı sonraki konuşmaları durdurmasın.
    _queue = task.catchError((Object error, StackTrace stackTrace) {
      debugPrint('Konuşma kuyruğu hatası: $error');
    });

    return task;
  }


  Future<void> _speakWithFallback(
      String text, {
        required String voiceGender,
      }) async {
    Object? lastError;

    debugPrint('=== TTS motor listesi ===');
    for (final engine in _engines) {
      debugPrint('Motor: ${engine.name}');
    }

    for (final SpeechEngine engine in _engines) {
      try {
        final available = await engine.isAvailable();
        if (!available) {
          continue;
        }
        await engine.speak(
          text,
          voiceGender: voiceGender,
        );
        return;
      } catch (error, stackTrace) {
        lastError = error;
        debugPrint('[TTS] ${engine.name} HATA: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    throw Exception(
      'Hiçbir konuşma motoru çalışmadı. Son hata: $lastError',
    );
  }

}

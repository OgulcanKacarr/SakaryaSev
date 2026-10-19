
import 'package:flutter/foundation.dart';
import 'EdgeSpeechEngine/EdgeSpeechEngine.dart';
import 'PiperSpeechEngine/PiperSpeechEngine.dart';
import 'SpeechEngine.dart';
import 'WindowsSpeechEngine/WindowsSpeechEngine.dart';


class SpeechService {
  SpeechService._();

  static final SpeechService instance = SpeechService._();

  // Yeni motorlar buraya, Windows motorundan ÖNCE eklenir.
  final List<SpeechEngine> _engines = [
    PiperSpeechEngine(),
    EdgeSpeechEngine(),
    WindowsSpeechEngine(),
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

    for (final SpeechEngine engine in _engines) {
      try {
        if (!await engine.isAvailable()) {
          continue;
        }

        debugPrint('Konuşma motoru deneniyor: ${engine.name}');

        await engine.speak(
          text,
          voiceGender: voiceGender,
        );

        // Başarılı motor konuştu; başka motoru çalıştırma.
        return;
      } catch (error) {
        lastError = error;
        debugPrint(
          '${engine.name} başarısız oldu; sonraki motor denenecek: $error',
        );
      }
    }

    throw Exception(
      'Hiçbir konuşma motoru metni seslendiremedi. Son hata: $lastError',
    );
  }
}

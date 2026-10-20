import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../SpeechEngine.dart';

class WindowsTtsEngine implements SpeechEngine {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  @override
  String get name => 'Windows TTS (flutter_tts)';

  @override
  Future<bool> isAvailable() async {
    return !kIsWeb && Platform.isWindows;
  }

  Future<void> _init() async {
    if (_isInitialized) return;

    try {
      await _flutterTts.setLanguage("tr-TR");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // flutter_tts 4.2.5: Seslendirme bitene kadar await edilmesini sağlar
      await _flutterTts.awaitSpeakCompletion(true);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Windows TTS başlatılamadı: $e');
    }
  }

  @override
  Future<void> speak(
      String text, {
        required String voiceGender,
      }) async {
    if (!await isAvailable()) {
      throw UnsupportedError('Windows TTS yalnızca Windows üzerinde desteklenir.');
    }

    if (text.trim().isEmpty) return;

    await _init();

    try {
      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        for (var voice in voices) {
          final name = voice['name']?.toString().toLowerCase() ?? '';
          final locale = voice['locale']?.toString().toLowerCase() ?? '';

          if (locale.contains('tr')) {
            if (voiceGender.toLowerCase() == 'female' &&
                (name.contains('zira') || name.contains('gul') || name.contains('female'))) {
              await _flutterTts.setVoice({"name": voice['name'], "locale": voice['locale']});
              break;
            } else if (voiceGender.toLowerCase() == 'male' &&
                (name.contains('ahmet') || name.contains('berk') || name.contains('male'))) {
              await _flutterTts.setVoice({"name": voice['name'], "locale": voice['locale']});
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Ses seçimi hatası: $e');
    }

    try {
      final result = await _flutterTts.speak(text);
      if (result == 0) {
        throw Exception('FlutterTts seslendirme başlatamadı.');
      }
      debugPrint('Konuşma tamamlandı: $name');
    } catch (error, stackTrace) {
      debugPrint('Windows TTS hatası: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> dispose() async {
    await _flutterTts.stop();
  }
}
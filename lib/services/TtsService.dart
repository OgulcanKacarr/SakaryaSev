import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  TtsService() {
    _tts.setLanguage('tr-TR');
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  Future<void> speak({required String text, required String voiceType}) async {
    await _tts.stop();
    await _tts.setLanguage('tr-TR');

    // Şimdilik Windows'ta test ettiğimiz Türkçe erkek sesi.
    await _tts.setVoice({'name': 'Microsoft Tolga', 'locale': 'tr-TR'});

    await _tts.speak(text);
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}


import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_edge_tts/flutter_edge_tts.dart';

import '../SpeechEngine.dart';

class EdgeSpeechEngine implements SpeechEngine {
  final AudioPlayer _player = AudioPlayer();

  @override
  String get name => 'Microsoft Edge Turkish Neural';

  @override
  Future<bool> isAvailable() async {
    return !kIsWeb && Platform.isWindows;
  }

  @override
  Future<void> speak(
      String text, {
        required String voiceGender,
      }) async {
    if (!await isAvailable()) {
      throw UnsupportedError('Edge TTS Windows dışında desteklenmiyor.');
    }

    if (text.trim().isEmpty) return;

    final bool male = voiceGender.toLowerCase() == 'male';

    final FlutterEdgeTts tts = FlutterEdgeTts(
      voice: male ? 'tr-TR-AhmetNeural' : 'tr-TR-EmelNeural',
      voiceLocale: 'tr-TR',
      outputFormat: EdgeTtsOutputFormat.audio24Khz96KbitrateMonoMp3,
    );

    try {
      // Ağ yanıtı gelmezse sonsuza kadar bekleme.
      final result = await tts
          .synthesize(text)
          .timeout(const Duration(seconds: 45));

      if (result.audioBytes.isEmpty) {
        throw Exception('Edge TTS boş ses verisi döndürdü.');
      }

      // Dinleyiciyi oynatma başlamadan önce oluştur.
      final Future<void> completed = _player.onPlayerComplete.first
          .timeout(const Duration(minutes: 5));

      await _player.play(BytesSource(result.audioBytes));
      await completed;

      debugPrint('Konuşma tamamlandı: $name');
    } catch (error, stackTrace) {
      debugPrint('Edge TTS hatası: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      await tts.close();
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

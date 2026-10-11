import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_edge_tts/flutter_edge_tts.dart';

class TtsService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> speak({
    required String text,
    required String voiceType,
  }) async {
    final tts = FlutterEdgeTts(
      voice: voiceType == "Erkek"
          ? "tr-TR-AhmetNeural"
          : "tr-TR-EmelNeural",
    );

    // Önce mevcut sesi durdur
    await _player.stop();

    // Her anons için farklı dosya
    final file =
        "${Directory.systemTemp.path}\\announcement_${DateTime.now().microsecondsSinceEpoch}.mp3";

    try {
      await tts.synthesizeToFile(
        text,
        audioFilePath: file,
      );

      await _player.play(
        DeviceFileSource(file),
      );
    } finally {
      await tts.close();
    }
  }

  Future<void> dispose() async {
    await _player.stop();
    await _player.dispose();
  }
}
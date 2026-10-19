
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../SpeechEngine.dart';

class PiperSpeechEngine implements SpeechEngine {
  final AudioPlayer _player = AudioPlayer();

  static const String _exe = r'C:\piper\piper\piper.exe';
  static const String _model =
      r'C:\piper\models\tr_TR-dfki-medium.onnx';
  static const String _config =
      r'C:\piper\models\tr_TR-dfki-medium.onnx.json';

  @override
  String get name => 'Piper Türkçe (Çevrimdışı)';

  @override
  Future<bool> isAvailable() async {
    return !kIsWeb &&
        Platform.isWindows &&
        await File(_exe).exists() &&
        await File(_model).exists() &&
        await File(_config).exists();
  }

  @override
  Future<void> speak(
      String text, {
        required String voiceGender,
      }) async {
    if (text.trim().isEmpty) return;

    if (!await isAvailable()) {
      throw Exception('Piper veya Türkçe model dosyaları bulunamadı.');
    }

    final wavPath =
        '${Directory.systemTemp.path}\\piper_${DateTime.now().microsecondsSinceEpoch}.wav';
    final wavFile = File(wavPath);

    try {
      final process = await Process.start(
        _exe,
        [
          '--model', _model,
          '--config', _config,
          '--output_file', wavPath,
        ],
      );

      process.stdin.write('$text\n');
      await process.stdin.close();

      final exitCode = await process.exitCode.timeout(
        const Duration(minutes: 2),
      );

      if (exitCode != 0 ||
          !await wavFile.exists() ||
          await wavFile.length() == 0) {
        throw Exception('Piper ses oluşturamadı. Çıkış kodu: $exitCode');
      }

      await _player.stop();

      final completed = _player.onPlayerComplete.first.timeout(
        const Duration(minutes: 5),
      );

      await _player.play(DeviceFileSource(wavPath));
      await completed;
    } finally {
      if (await wavFile.exists()) {
        await wavFile.delete();
      }
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

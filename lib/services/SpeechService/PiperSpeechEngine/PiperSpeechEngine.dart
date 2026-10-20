import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../SpeechEngine.dart';

class PiperSpeechEngine implements SpeechEngine {
  static const String _exe = r'C:\piper\piper\piper.exe';

  static const String _model = r'C:\piper\models\tr_TR-dfki-medium.onnx';

  static const String _config = r'C:\piper\models\tr_TR-dfki-medium.onnx.json';

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
  Future<void> speak(String text, {required String voiceGender}) async {
    if (text.trim().isEmpty) return;

    if (!await isAvailable()) {
      throw Exception('Piper veya Türkçe model dosyaları bulunamadı.');
    }

    final wavPath =
        '${Directory.systemTemp.path}\\piper_${DateTime.now().microsecondsSinceEpoch}.wav';
    final wavFile = File(wavPath);

    try {
      // 1. Piper ile WAV dosyasını üret.
      final piper = await Process.start(_exe, [
        '--model',
        _model,
        '--config',
        _config,
        '--output_file',
        wavPath,
      ]);

      final stdoutFuture = piper.stdout.transform(utf8.decoder).join();
      final stderrFuture = piper.stderr.transform(utf8.decoder).join();

      piper.stdin.write('${text.trim()}\n');
      await piper.stdin.close();

      final exitCode = await piper.exitCode.timeout(
        const Duration(minutes: 2),
        onTimeout: () {
          piper.kill();
          throw TimeoutException('Piper ses üretimi zaman aşımına uğradı.');
        },
      );

      final stderr = await stderrFuture;
      await stdoutFuture;

      if (exitCode != 0 ||
          !await wavFile.exists() ||
          await wavFile.length() == 0) {
        throw Exception(
          'Piper ses oluşturamadı. Çıkış kodu: $exitCode. $stderr',
        );
      }

      // 2. WAV dosyasını Windows'un kendi oynatıcısıyla çal.
      // Tek tırnaklar dosya yolunda bulunsa bile PowerShell'de kaçırılır.
      final safePath = wavPath.replaceAll("'", "''");

      final script =
          '''
\$ErrorActionPreference = 'Stop'
\$player = New-Object System.Media.SoundPlayer('$safePath')
try {
  \$player.Load()
  \$player.PlaySync()
} finally {
  \$player.Dispose()
}
''';

      final playback = await Process.start('powershell.exe', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        script,
      ]);

      final playbackStdout = playback.stdout.transform(utf8.decoder).join();
      final playbackStderr = playback.stderr.transform(utf8.decoder).join();

      final playbackExitCode = await playback.exitCode.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          playback.kill();
          throw TimeoutException('Ses oynatma zaman aşımına uğradı.');
        },
      );

      await playbackStdout;
      final playbackError = await playbackStderr;

      if (playbackExitCode != 0) {
        throw Exception('Windows ses oynatma hatası: $playbackError');
      }
    } finally {
      // Ses oynatma işlemi tamamlandıktan sonra geçici dosyayı sil.
      if (await wavFile.exists()) {
        try {
          await wavFile.delete();
        } catch (e) {
          debugPrint('Geçici ses dosyası silinemedi: $e');
        }
      }
    }
  }
}

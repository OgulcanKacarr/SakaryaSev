
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../SpeechEngine.dart';

class WindowsSpeechEngine implements SpeechEngine {
  @override
  String get name => 'Windows Turkish Speech';

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
      throw UnsupportedError('Windows konuşma motoru kullanılamıyor.');
    }

    if (text.trim().isEmpty) return;

    final String textBase64 = base64Encode(utf8.encode(text));
    final String gender =
    voiceGender.toLowerCase() == 'male' ? 'Male' : 'Female';

    final String script = r'''
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

try {
    $text = [System.Text.Encoding]::UTF8.GetString(
        [System.Convert]::FromBase64String('TEXT_BASE64')
    )

    $requestedGender = 'VOICE_GENDER'

    $voices = @(
        $synth.GetInstalledVoices() |
        Where-Object {
            $_.Enabled -and
            $_.VoiceInfo.Culture.Name -like 'tr-*'
        }
    )

    if ($voices.Count -eq 0) {
        throw 'Windows üzerinde Türkçe ses bulunamadı.'
    }

    $selected = $voices |
        Where-Object {
            $_.VoiceInfo.Gender.ToString() -eq $requestedGender
        } |
        Select-Object -First 1

    if ($null -eq $selected) {
        $selected = $voices | Select-Object -First 1
    }

    $synth.SelectVoice($selected.VoiceInfo.Name)
    $synth.Speak($text)
}
catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
finally {
    $synth.Dispose()
}
'''
        .replaceFirst('TEXT_BASE64', textBase64)
        .replaceFirst('VOICE_GENDER', gender);

    // PowerShell -EncodedCommand UTF-16LE bekler.
    final List<int> utf16Bytes = <int>[];

    for (final int unit in script.codeUnits) {
      utf16Bytes
        ..add(unit & 0xFF)
        ..add((unit >> 8) & 0xFF);
    }

    final String encodedScript = base64Encode(utf16Bytes);

    final ProcessResult result = await Process.run(
      'powershell.exe',
      <String>[
        '-NoProfile',
        '-NonInteractive',
        '-EncodedCommand',
        encodedScript,
      ],
    );

    if (result.exitCode != 0) {
      throw Exception(
        'Windows konuşma hatası: ${result.stderr}',
      );
    }

    debugPrint('Konuşma tamamlandı: $name');
  }
}

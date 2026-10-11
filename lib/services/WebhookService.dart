import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WebhookService {
  String webhookUrl;
  String? authKey; // Auth-Key alanı eklendi

  Timer? _timer;
  final Set<String> _processedIds = {};
  bool _firstCheck = true;

  WebhookService({
    required this.webhookUrl,
    this.authKey,
  });

  void updateUrl(String url) {
    webhookUrl = url.trim();
  }

  // Auth-Key'i sonradan güncellemek için
  void updateAuthKey(String key) {
    authKey = key.trim();
  }

  void start({
    required Future<void> Function(
        Map<String, dynamic>,
        ) onReceive,
  }) {
    stop();

    _firstCheck = true;
    _processedIds.clear();

    _check(
      onReceive: onReceive,
    );

    _timer = Timer.periodic(
      const Duration(seconds: 2),
          (_) => _check(
        onReceive: onReceive,
      ),
    );
  }

  Future<void> _check({
    required Future<void> Function(
        Map<String, dynamic>,
        ) onReceive,
  }) async {
    try {
      if (webhookUrl.trim().isEmpty) {
        return;
      }

      // Headers hazırlandı
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (authKey != null && authKey!.isNotEmpty) {
        headers['Auth-Key'] = authKey!;
      }

      // İstek header ile birlikte atılıyor
      final response = await http.get(
        Uri.parse(webhookUrl),
        headers: headers,
      );

      if (response.statusCode != 200) {
        debugPrint(
          "Webhook HTTP Hatası: ${response.statusCode} - ${response.body}",
        );
        return;
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        debugPrint(
          "Webhook verisi liste değil.",
        );
        return;
      }

      /*
       * Uygulama ilk açıldığında mevcut kayıtların
       * tamamını eski kabul ediyoruz.
       */
      if (_firstCheck) {
        for (final record in decoded) {
          if (record is Map<String, dynamic>) {
            final id = record['id']?.toString();

            if (id != null && id.isNotEmpty) {
              _processedIds.add(id);
            }
          }
        }

        _firstCheck = false;

        debugPrint(
          "Webhook başlangıç kayıtları işlendi: "
              "${_processedIds.length}",
        );

        return;
      }

      /*
       * İlk kontrolden sonra sadece yeni kayıtları işle.
       */
      for (final record in decoded) {
        if (record is! Map<String, dynamic>) {
          continue;
        }

        final id = record['id']?.toString();

        if (id == null || id.isEmpty) {
          continue;
        }

        if (_processedIds.contains(id)) {
          continue;
        }

        final data = record['data'];

        if (data is Map<String, dynamic>) {
          _processedIds.add(id);

          await onReceive(data);
        }
      }
    } catch (e) {
      debugPrint(
        "Webhook bağlantı hatası: $e",
      );
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../VehicleService/VehicleService.dart';


class TrioListenerService {
  TrioListenerService._();

  static final TrioListenerService instance = TrioListenerService._();

  HttpServer? _server;

  bool get isRunning => _server != null;

  Future<void> start({int port = 5000}) async {
    if (_server != null) {
      debugPrint('TRIO dinleyicisi zaten çalışıyor.');
      return;
    }

    try {
      _server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        port,
      );

      debugPrint(
        'TRIO dinleyicisi başladı: http://127.0.0.1:$port',
      );

      _server!.listen(
        _handleRequest,
        onError: (Object error) {
          debugPrint('TRIO HTTP dinleyici hatası: $error');
        },
      );
    } catch (e, stackTrace) {
      debugPrint('TRIO dinleyicisi başlatılamadı: $e');
      debugPrintStack(stackTrace: stackTrace);
      _server = null;
      rethrow;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    debugPrint(
      'HTTP istek alındı: ${request.method} ${request.uri.path}',
    );

    request.response.headers.contentType = ContentType.json;

    try {
      if (request.method == 'GET' &&
          request.uri.path == '/health') {
        request.response.statusCode = HttpStatus.ok;
        request.response.write(
          jsonEncode({
            'status': 'ok',
            'service': 'TrioListenerService',
          }),
        );
      } else if (request.method == 'POST' &&
          request.uri.path == '/webhook') {
        final body = await utf8.decoder.bind(request).join();

        final dynamic decoded = jsonDecode(body);

        if (decoded is! Map) {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(
            jsonEncode({
              'success': false,
              'message': 'Webhook içeriği JSON nesnesi olmalıdır.',
            }),
          );
          return;
        }

        final event = Map<String, dynamic>.from(decoded);

        debugPrint('TRIO webhook olayı alındı:');
        debugPrint(
          const JsonEncoder.withIndent('  ').convert(event),
        );

        // Gelen olaydan plaka ve TRIO araç ID'sini eşleştir.
        VehicleService.instance.autoMatchTrioEvent(event);

        request.response.statusCode = HttpStatus.ok;
        request.response.write(
          jsonEncode({
            'success': true,
            'message': 'TRIO olayı alındı.',
          }),
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(
          jsonEncode({
            'success': false,
            'message': 'Adres bulunamadı.',
          }),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('TRIO HTTP istek işleme hatası: $e');
      debugPrintStack(stackTrace: stackTrace);

      request.response.statusCode = HttpStatus.badRequest;
      request.response.write(
        jsonEncode({
          'success': false,
          'message': 'İstek işlenemedi.',
        }),
      );
    } finally {
      await request.response.close();
    }
  }

  Future<void> stop() async {
    final server = _server;
    if (server == null) return;

    await server.close(force: true);
    _server = null;

    debugPrint('TRIO dinleyicisi durduruldu.');
  }
}

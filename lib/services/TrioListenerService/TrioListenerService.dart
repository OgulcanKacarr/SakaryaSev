import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http; // http paketini kullandığınızı varsayıyoruz

import '../TrioNotificationService/TrioNotificationService.dart';
import '../VehicleService/VehicleService.dart';

class TrioListenerService {
  TrioListenerService._();

  static final TrioListenerService instance = TrioListenerService._();

  Timer? _pollingTimer;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  final String _phpEndpoint = 'https://www.sakaryasevturizm.com/acswhook';
  final String _authKey = '362a98b7604b2ebf1c2aaf5c7f621e507f55b576a398eb6c';

  final Set<String> _processedIds = {};

  /// Belirli aralıklarla (örn: her 10 saniyede bir) PHP sunucusunu kontrol eder
  void start({Duration interval = const Duration(seconds: 10)}) {
    if (_isRunning) {
      debugPrint('TRIO sunucu dinleyicisi zaten çalışıyor.');
      return;
    }

    _isRunning = true;
    debugPrint('TRIO web dinleyicisi başlatıldı.');

    // İlk açılışta hemen kontrol et
    _fetchAndProcessEvents();

    // Periyodik kontrolü başlat
    _pollingTimer = Timer.periodic(interval, (timer) async {
      await _fetchAndProcessEvents();
    });
  }

  Future<void> _fetchAndProcessEvents() async {
    try {
      final response = await http.get(
        Uri.parse(_phpEndpoint),
        headers: {
          'Authorization': 'Bearer $_authKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map && item.containsKey('id') && item.containsKey('data')) {
              final String id = item['id'].toString();

              // Eğer bu olayı daha önce işlemediysek işleme al
              if (!_processedIds.contains(id)) {
                _processedIds.add(id);

                final event = Map<String, dynamic>.from(item['data']);

                // Mevcut araç–TRIO eşleştirmesi
                VehicleService.instance.autoMatchTrioEvent(event);

                // TRIO olayını seslendir ve/veya bildir
                await TrioNotificationService.instance.handleEvent(event);

                debugPrint('Yeni TRIO olayı işlendi: $id');
              }
            }
          }
        }
      } else {
        debugPrint('TRIO verileri alınamadı. HTTP Kod: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('TRIO veri çekme hatası: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isRunning = false;
    debugPrint('TRIO web dinleyicisi durduruldu.');
  }
}
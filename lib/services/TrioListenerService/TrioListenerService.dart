
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../TrioNotificationService/TrioNotificationService.dart';
import '../VehicleService/VehicleService.dart';

class TrioListenerService {
TrioListenerService._();

static final TrioListenerService instance = TrioListenerService._();

Timer? _pollingTimer;
bool _isRunning = false;
bool _isFetching = false;
bool _initialSyncCompleted = false;

bool get isRunning => _isRunning;

final String _phpEndpoint =
'https://www.sakaryasevturizm.com/acswhook';

final String _authKey = '362a98b7604b2ebf1c2aaf5c7f621e507f55b576a398eb6c';

final Set<String> _processedIds = {};

void start({Duration interval = const Duration(seconds: 10)}) {
if (_isRunning) {
debugPrint('TRIO dinleyicisi zaten çalışıyor.');
return;
}

_isRunning = true;
debugPrint('TRIO dinleyicisi başlatıldı.');

_fetchAndProcessEvents();

_pollingTimer = Timer.periodic(interval, (_) {
_fetchAndProcessEvents();
});
}

Future<void> _fetchAndProcessEvents() async {
if (_isFetching) return;
_isFetching = true;

try {
debugPrint('TRIO: Sunucu kontrol ediliyor...');

final response = await http
    .get(
Uri.parse(_phpEndpoint),
headers: {
'Authorization': 'Bearer $_authKey',
'Accept': 'application/json',
},
)
    .timeout(const Duration(seconds: 15));

debugPrint('TRIO HTTP durum kodu: ${response.statusCode}');


if (response.statusCode != 200) {
debugPrint('TRIO: Sunucu isteği başarısız.');
return;
}

final dynamic decoded = jsonDecode(response.body);

if (decoded is! List) {
debugPrint(
'TRIO HATASI: Beklenen JSON liste biçimi değil. '
'Gelen tip: ${decoded.runtimeType}',
);
return;
}

debugPrint('TRIO: Sunucuda ${decoded.length} kayıt bulundu.');

// İlk sorgudaki kayıtları geçmiş kayıt olarak işaretle.
if (!_initialSyncCompleted) {
for (final item in decoded) {
if (item is Map && item['id'] != null) {
_processedIds.add(item['id'].toString());
}
}

_initialSyncCompleted = true;

debugPrint(
'TRIO ilk senkronizasyon tamamlandı. '
'${_processedIds.length} mevcut kayıt atlandı.',
);
return;
}

for (final item in decoded) {
if (item is! Map ||
item['id'] == null ||
item['data'] is! Map) {
debugPrint('TRIO: Geçersiz kayıt biçimi atlandı: $item');
continue;
}

final id = item['id'].toString();

if (_processedIds.contains(id)) continue;

final event = Map<String, dynamic>.from(item['data'] as Map);

debugPrint('TRIO: Yeni olay bulundu: $id');

try {
VehicleService.instance.autoMatchTrioEvent(event);
await TrioNotificationService.instance.handleEvent(event);

_processedIds.add(id);
debugPrint('TRIO: Olay işlendi: $id');
} catch (e, stackTrace) {
debugPrint('TRIO olay işleme hatası ($id): $e');
debugPrintStack(stackTrace: stackTrace);
}
}
} on TimeoutException {
debugPrint('TRIO: Sunucu isteği zaman aşımına uğradı.');
} catch (e, stackTrace) {
debugPrint('TRIO veri çekme hatası: $e');
debugPrintStack(stackTrace: stackTrace);
} finally {
_isFetching = false;
}
}

void stop() {
_pollingTimer?.cancel();
_pollingTimer = null;
_isRunning = false;
debugPrint('TRIO dinleyicisi durduruldu.');
}
}

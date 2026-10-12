import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';

import '../../models/BusModel.dart';
import '../../models/TripModel.dart';
import '../../services/NotificationService.dart';
import '../../services/TtsService.dart';
import '../../services/WebhookService.dart';
import '../../viewModel/HomePageViewModel.dart';
import '../../viewModel/settings/SettingsViewModel.dart';
import '../../widgets/DepartureCard.dart';
import '../../widgets/LastAnnouncementsCard.dart';
import '../CashRegisterPage/CashRegisterPage.dart';
import '../settings/SettingsPage.dart';

final homeProvider = ChangeNotifierProvider(
      (ref) => HomePageViewModel(),
);

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final NotificationService _notificationService = NotificationService();
  final TtsService _ttsService = TtsService();

  WebhookService? _webhookService;

  int selectedIndex = 0;
  Timer? _manualArrivalTimer;

  final Set<String> _announcedManualArrivals = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = ref.read(settingsProvider);

    await _notificationService.init();

    await settings.loadWebhookUrl();
    await settings.loadBuses();
    await settings.loadTrips();
    await settings.loadSpeedViolationSetting();

    _webhookService = WebhookService(
      webhookUrl: "https://www.sakaryasevturizm.com/acswhook",
      authKey: "362a98b7604b2ebf1c2aaf5c7f621e507f55b576a398eb6c",
    );

    _webhookService!.start(
      onReceive: _handleWebhookData,
    );

    _startManualArrivalChecker();
  }

  Future<void> _handleWebhookData(
      Map<String, dynamic> data,
      ) async {
    final settings = ref.read(settingsProvider);
    final home = ref.read(homeProvider);

    final violation = data["violation"];

    if (violation is! Map) return;

    // ------------------------------------------------------------
    // 1. HIZ İHLALİ WEBHOOK'U
    // ------------------------------------------------------------

    final alarmRule = data["alarmRule"];
    final isSpeedViolation =
        alarmRule is Map &&
            violation["measurement"] is Map &&
            (violation["measurement"] as Map)["speed"] != null;

    if (isSpeedViolation) {
      final vehicle = violation["vehicle"];
      final measurement = violation["measurement"] as Map;
      final rule = (alarmRule)["rule"];
      final threshold = rule is Map ? rule["threshold"] : null;
      final speedThreshold =
      threshold is Map ? threshold["speed"] : null;
      final latest =
      speedThreshold is Map ? speedThreshold["latest"] : null;
      final limitData = latest is Map ? latest["limit"] : null;

      final vehicleId =
      vehicle is Map ? vehicle["_id"]?.toString() ?? "" : "";

      final speedRaw = measurement["speed"];
      final limitRaw =
      limitData is Map ? limitData["moreThan"] : null;

      final speed = speedRaw is num
          ? speedRaw.toDouble()
          : double.tryParse(speedRaw?.toString() ?? "");

      final limit = limitRaw is num
          ? limitRaw.toDouble()
          : double.tryParse(limitRaw?.toString() ?? "");

      if (speed == null || limit == null) {
        debugPrint("Hız ihlali: hız veya limit bilgisi eksik.");
        return;
      }

      final summary = data["summary"]?.toString() ?? "";
      var plate = home.extractPlate(summary);

      // Önce kayıtlı araçların Trio ID eşleşmesini kullan.
      BusModel? bus;

      try {
        bus = settings.buses.firstWhere(
              (e) => e.vehicleId == vehicleId && vehicleId.isNotEmpty,
        );
      } catch (_) {
        bus = null;
      }

      // ID eşleşmesi bulunamadıysa özetteki plakayı kullan.
      if (bus == null && plate.isNotEmpty) {
        try {
          bus = settings.buses.firstWhere(
                (e) => e.plate.toUpperCase() == plate.toUpperCase(),
          );
        } catch (_) {
          bus = null;
        }
      }

      if (bus != null) {
        plate = bus.plate;

        // Araç ID'si henüz kayıtlı değilse eşleştirmeyi kaydet.
        if (vehicleId.isNotEmpty && bus.vehicleId != vehicleId) {
          await settings.updateVehicleId(
            plate: bus.plate,
            vehicleId: vehicleId,
          );
        }
      }

      if (plate.isEmpty) {
        debugPrint(
          "Hız ihlali geldi ancak araç plakası eşleştirilemedi. "
              "Trio Vehicle ID: $vehicleId",
        );
        return;
      }

      final speedText =
      speed.toStringAsFixed(speed % 1 == 0 ? 0 : 1);
      final limitText =
      limit.toStringAsFixed(limit % 1 == 0 ? 0 : 1);

      final alertText =
          "Dikkat! $plate plakalı araç, "
          "$limitText kilometre/saat hız sınırını aşarak "
          "saatte $speedText kilometre hızla seyrediyor.";

      debugPrint("Hız ihlali: $alertText");

      if (settings.notification) {
        await _notificationService.show(
          title: "Hız İhlali - $plate",
          body: alertText,
        );
      }

      // Hız ihlali, normal bölge anonsundan bağımsız kontrol edilir.
      if (settings.speakSpeedViolations) {
        await _ttsService.speak(
          text: alertText,
          voiceType: settings.voiceType,
        );
      }

      return;
    }

    // ------------------------------------------------------------
    // 2. MEVCUT BÖLGE WEBHOOK'U
    // ------------------------------------------------------------

    final vehicle = violation["vehicle"];
    final vehicleId =
    vehicle is Map ? vehicle["_id"]?.toString() ?? "" : "";
    final summary = data["summary"]?.toString() ?? "";

    final plate = home.extractPlate(summary);

    if (plate.isNotEmpty && vehicleId.isNotEmpty) {
      await settings.updateVehicleId(
        plate: plate,
        vehicleId: vehicleId,
      );
    }

    final announcement = home.createAnnouncement(
      webhook: data,
      buses: settings.buses,
      trips: settings.trips,
    );

    if (announcement == null) return;

    home.addAnnouncement(announcement);

    String text = settings.buildAnnouncementText(announcement);

    BusModel? bus;

    try {
      bus = settings.buses.firstWhere(
            (e) =>
        e.plate.toUpperCase() ==
            announcement.plate.toUpperCase(),
      );
    } catch (_) {
      bus = null;
    }

    if (bus != null &&
        bus.speakNote &&
        bus.note.trim().isNotEmpty) {
      text += " Not. ${bus.note}";
    }

    if (settings.notification) {
      await _notificationService.show(
        title: announcement.plate,
        body: text,
      );
    }

    if (settings.voice) {
      await _ttsService.speak(
        text: text,
        voiceType: settings.voiceType,
      );
    }
  }


  @override
  void dispose() {
    _webhookService?.dispose();
    _ttsService.dispose();
    _manualArrivalTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      settingsProvider,
          (previous, next) {
        if (previous?.webhookUrl != next.webhookUrl) {
          _webhookService?.updateUrl(next.webhookUrl);
        }
      },
    );

    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(),
          const VerticalDivider(width: 1),
          Expanded(
            child: selectedIndex == 0
                ? _buildDashboard()
                : selectedIndex == 1
                ? const CashRegisterPage()
                : const SettingsPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
      labelType: NavigationRailLabelType.all,
      leading: const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Icon(
          Icons.directions_bus,
          size: 40,
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text("Ana Sayfa"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet),
          label: Text("Kasa"),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text("Ayarlar"),
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ÜST BAŞLIK VE LOGO ALANI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol Köşe: Tarih
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Tarih: $currentDate",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),

              // Orta Kısım: Logo ve Başlık
              Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 60,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.directions_bus, size: 50, color: Colors.blueAccent),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    "Araç Takip ve Operasyon Merkezi",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                    ),
                  ),


                ],
              ),

              // Sağ Kısım Simetri Boşluğu
              const SizedBox(width: 80),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(thickness: 1.2),
          const SizedBox(height: 24),

          _buildSectionTitle(
            "Araç Notları",
            Icons.sticky_note_2_outlined,
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 180,
            child: _buildBusNotes(),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle(
            "Son Duyurular",
            Icons.notifications_active_outlined,
          ),

          const SizedBox(height: 12),

          const SizedBox(
            height: 250,
            child: LastAnnouncementsCard(),
          ),

          const SizedBox(height: 24),

          _buildSectionTitle(
            "Sefer Durumları",
            Icons.route,
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 250,
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: const [
                DepartureCard(
                  departure: "Karasu",
                ),
                DepartureCard(
                  departure: "Harem",
                ),
                DepartureCard(
                  departure: "Esenler",
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBusNotes() {
    final settings = ref.watch(settingsProvider);

    final busesWithNotes = settings.buses
        .where(
          (bus) => bus.note.trim().isNotEmpty,
    )
        .toList();

    if (busesWithNotes.isEmpty) {
      return Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 12),
                Text(
                  "Kayıtlı araç notu bulunmuyor.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: busesWithNotes.length,
        separatorBuilder: (_, __) => const Divider(
          height: 1,
        ),
        itemBuilder: (context, index) {
          final bus = busesWithNotes[index];

          return ListTile(
            leading: CircleAvatar(
              child: Icon(
                bus.speakNote
                    ? Icons.volume_up
                    : Icons.sticky_note_2_outlined,
              ),
            ),
            title: Text(
              bus.plate,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                bus.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  icon: Icon(
                    bus.speakNote
                        ? Icons.volume_up
                        : Icons.volume_off_outlined,
                  ),
                  label: Text(
                    bus.speakNote
                        ? "Seslendiriliyor"
                        : "Notu Seslendir",
                  ),
                  onPressed: () async {
                    await settings.setBusNoteSpeech(
                      plate: bus.plate,
                      value: !bus.speakNote,
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: "Notu Sil",
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    await settings.deleteBusNote(
                      plate: bus.plate,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(
      String title,
      IconData icon,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _startManualArrivalChecker() {
    _manualArrivalTimer?.cancel();
    _checkManualArrivals();
    _manualArrivalTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _checkManualArrivals(),
    );
  }

  Future<void> _checkManualArrivals() async {
    final settings = ref.read(settingsProvider);
    final now = DateTime.now();

    for (final bus in settings.buses) {
      if (!bus.manualTracking) continue;
      if (bus.estimatedArrivalMinutes <= 0) continue;

      final trips = settings.getTripsByPlate(bus.plate);
      if (trips.isEmpty) continue;

      TripModel? selectedTrip;
      int smallestDifference = 999999;
      final currentMinutes = now.hour * 60 + now.minute;

      for (final trip in trips) {
        final parts = trip.time.split(":");
        if (parts.length != 2) continue;

        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        final tripMinutes = hour * 60 + minute;
        final difference = (tripMinutes - currentMinutes).abs();

        if (difference < smallestDifference) {
          smallestDifference = difference;
          selectedTrip = trip;
        }
      }

      if (selectedTrip == null) continue;

      final parts = selectedTrip.time.split(":");
      final departureHour = int.parse(parts[0]);
      final departureMinute = int.parse(parts[1]);

      final departureTime = DateTime(
        now.year,
        now.month,
        now.day,
        departureHour,
        departureMinute,
      );

      final estimatedArrival = departureTime.add(
        Duration(minutes: bus.estimatedArrivalMinutes),
      );

      final difference = now.difference(estimatedArrival).inSeconds;
      if (difference < 0) continue;
      if (difference > 600) continue;

      final announcementId =
          "${bus.plate}_${selectedTrip.time}_${now.year}-${now.month}-${now.day}";

      if (_announcedManualArrivals.contains(announcementId)) continue;

      _announcedManualArrivals.add(announcementId);

      await _speakManualArrival(
        bus: bus,
        trip: selectedTrip,
      );
    }
  }

  Future<void> _speakManualArrival({
    required BusModel bus,
    required TripModel trip,
  }) async {
    final settings = ref.read(settingsProvider);

    final List<String> parts = [];
    parts.add("${bus.plate} plakalı araç");
    parts.add("${trip.departure} kalkışlı");
    parts.add("yaklaşık olarak Sakarya'ya ulaştı.");

    if (bus.note.trim().isNotEmpty) {
      parts.add("Araç notu: ${bus.note}");
    }

    final text = parts.join(" ");

    if (settings.notification) {
      await _notificationService.show(
        title: "${bus.plate} Tahmini Varış",
        body: text,
      );
    }

    if (settings.voice) {
      await _ttsService.speak(
        text: text,
        voiceType: settings.voiceType,
      );
    }
  }
}
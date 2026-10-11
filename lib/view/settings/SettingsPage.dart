import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../models/AssistantModel.dart';
import '../../models/BusAssignmentModel.dart';
import '../../models/BusModel.dart';
import '../../models/DriverModel.dart';
import '../../viewModel/settings/SettingsViewModel.dart';

final settingsProvider = ChangeNotifierProvider(
  (ref) => SettingsPageViewModel(),
);

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _initialized = false;

  bool _vehiclesExpanded = false;
  bool _driversExpanded = false;
  bool _assistantsExpanded = false;

  String _vehicleSearchQuery = "";
  String _driverSearchQuery = "";
  String _assistantSearchQuery = "";

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      final vm = ref.read(settingsProvider);

      vm.loadBuses();
      vm.loadDrivers();
      vm.loadAssistants();
      vm.loadWebhookUrl();

      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildMainPanel(vm)),

              const SizedBox(width: 24),

              SizedBox(width: 380, child: _buildRightPanel(vm)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ANA PANEL
  // ============================================================

  Widget _buildMainPanel(SettingsPageViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCollapsibleSectionHeader(
          title: "Araçlar",
          icon: Icons.directions_bus_rounded,
          expanded: _vehiclesExpanded,
          itemCount: vm.buses.length,
          onToggle: () {
            setState(() {
              _vehiclesExpanded = !_vehiclesExpanded;
            });
          },
          onAdd: () {
            vm.showAddBusDialog(context, vm);
          },
        ),

        if (_vehiclesExpanded) ...[
          const SizedBox(height: 12),
          _buildVehicleContent(vm),
        ],

        const SizedBox(height: 24),

        _buildCollapsibleSectionHeader(
          title: "Şoförler",
          icon: Icons.drive_eta_rounded,
          expanded: _driversExpanded,
          itemCount: vm.drivers.length,
          onToggle: () {
            setState(() {
              _driversExpanded = !_driversExpanded;
            });
          },
          onAdd: () {
            _showDriverDialog(context, vm);
          },
        ),

        if (_driversExpanded) ...[
          const SizedBox(height: 12),
          _buildDriversContent(vm),
        ],

        const SizedBox(height: 24),

        _buildAssistantsSection(vm),
      ],
    );
  }

  // ============================================================
  // ARAÇLAR
  // ============================================================

  Widget _buildVehicleContent(SettingsPageViewModel vm) {
    final query = _vehicleSearchQuery.trim().toUpperCase();

    final filteredBuses = vm.buses.where((bus) {
      if (query.isEmpty) {
        return true;
      }

      return bus.plate.toUpperCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: (value) {
            setState(() {
              _vehicleSearchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: "Plaka ara...",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _vehicleSearchQuery.isNotEmpty
                ? IconButton(
                    tooltip: "Aramayı temizle",
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _vehicleSearchQuery = "";
                      });
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        if (vm.buses.isEmpty)
          _buildEmptyState(
            "Henüz araç eklenmedi.",
            Icons.directions_bus_outlined,
          )
        else if (filteredBuses.isEmpty)
          _buildEmptyState(
            "Aramanızla eşleşen araç bulunamadı.",
            Icons.search_off,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredBuses.length,
            itemBuilder: (context, index) {
              final bus = filteredBuses[index];

              return _buildBusCard(vm, bus);
            },
          ),
      ],
    );
  }

  Widget _buildBusCard(SettingsPageViewModel vm, BusModel bus) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            bus.manualTracking ? Icons.schedule : Icons.directions_bus,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          bus.plate,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Text(_buildBusSubtitle(bus)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCountBadge(bus.assignments.length, small: true),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: "Araç işlemleri",
              onSelected: (value) {
                if (value == "settings") {
                  _showBusSettingsDialog(context, vm, bus);
                }

                if (value == "delete") {
                  _confirmDeleteBus(context, vm, bus);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: "settings",
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined),
                      SizedBox(width: 10),
                      Text("Araç Ayarları"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: "delete",
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Text("Aracı Sil"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [_buildBusDetails(vm, bus)],
      ),
    );
  }

  String _buildBusSubtitle(BusModel bus) {
    final parts = <String>[];

    if (bus.vehicleId.isNotEmpty) {
      parts.add("Trio ID: ${bus.vehicleId}");
    } else {
      parts.add("Trio eşleşmesi yok");
    }

    if (bus.assignments.isNotEmpty) {
      parts.add("${bus.assignments.length} atama");
    } else {
      parts.add("Atama yok");
    }

    return parts.join(" • ");
  }

  // ============================================================
  // ARAÇ DETAYLARI
  // ============================================================

  Widget _buildBusDetails(SettingsPageViewModel vm, BusModel bus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.alt_route_rounded),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Şoför / Kalkış Atamaları",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                _showAssignmentDialog(context, vm, bus);
              },
              icon: const Icon(Icons.add),
              label: const Text("Atama Ekle"),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (bus.assignments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.alt_route_outlined,
                  size: 40,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 8),
                Text(
                  "Bu araca henüz atama yapılmadı.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Bölge, kalkış yeri ve şoför "
                  "eşleştirmesi ekleyebilirsiniz.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bus.assignments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final assignment = bus.assignments[index];

              return _buildAssignmentCard(vm, bus, assignment);
            },
          ),

        if (bus.note.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_outlined, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(bus.note)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAssignmentCard(
    SettingsPageViewModel vm,
    BusModel bus,
    BusAssignmentModel assignment,
  ) {
    final driver = vm.getDriverById(assignment.driverId);

    final driverName = driver?.fullName ?? "Şoför bulunamadı";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            child: Icon(
              Icons.route_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.region.isEmpty
                      ? "Bölge belirtilmemiş"
                      : assignment.region,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 5),

                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  children: [
                    _buildInfoChip(Icons.trip_origin, assignment.departure),
                    _buildInfoChip(Icons.person_outline, driverName),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: "Atamayı düzenle",
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              _showAssignmentDialog(context, vm, bus, assignment: assignment);
            },
          ),

          IconButton(
            tooltip: "Atamayı sil",
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              _confirmDeleteAssignment(context, vm, bus, assignment);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 15), const SizedBox(width: 5), Text(text)],
      ),
    );
  }

  // ============================================================
  // ATAMA EKLE / DÜZENLE
  // ============================================================

  void _showAssignmentDialog(
    BuildContext context,
    SettingsPageViewModel vm,
    BusModel bus, {
    BusAssignmentModel? assignment,
  }) {
    final isEdit = assignment != null;

    String? selectedDriverId = isEdit ? assignment!.driverId : null;

    String selectedDeparture = isEdit ? assignment!.departure : "Karasu";

    final regionController = TextEditingController(
      text: isEdit ? assignment!.region : "",
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                isEdit
                    ? "${bus.plate} Atamasını Düzenle"
                    : "${bus.plate} İçin Atama",
              ),

              content: SizedBox(
                width: 480,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: regionController,
                          decoration: const InputDecoration(
                            labelText: "Trio Bölgesi",
                            hintText: "Örn: ADA AVM",
                            prefixIcon: Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Bölge giriniz.";
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value: selectedDeparture,
                          decoration: const InputDecoration(
                            labelText: "Kalkış Yeri",
                            prefixIcon: Icon(Icons.trip_origin),
                            border: OutlineInputBorder(),
                          ),
                          items: const ["Karasu", "Harem", "Esenler"]
                              .map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedDeparture = value;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 16),

                        DropdownButtonFormField<String>(
                          value:
                              vm.drivers.any(
                                (driver) => driver.id == selectedDriverId,
                              )
                              ? selectedDriverId
                              : null,
                          decoration: const InputDecoration(
                            labelText: "Şoför",
                            prefixIcon: Icon(Icons.drive_eta_outlined),
                            border: OutlineInputBorder(),
                          ),
                          hint: const Text("Şoför seçin"),
                          items: vm.drivers
                              .map(
                                (driver) => DropdownMenuItem<String>(
                                  value: driver.id,
                                  child: Text(driver.fullName),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedDriverId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Şoför seçiniz.";
                            }

                            return null;
                          },
                        ),

                        if (vm.drivers.isEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Henüz kayıtlı şoför yok. "
                              "Önce Şoförler bölümünden "
                              "şoför ekleyin.",
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Bu kayıt, araç için kalıcı "
                                  "bir Trio bölge → kalkış → "
                                  "şoför eşleşmesi oluşturur.",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("İptal"),
                ),

                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: Text(isEdit ? "Güncelle" : "Kaydet"),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    if (selectedDriverId == null) {
                      return;
                    }

                    final region = regionController.text.trim();

                    if (isEdit) {
                      await vm.updateBusAssignment(
                        plate: bus.plate,
                        assignmentId: assignment!.id,
                        region: region,
                        departure: selectedDeparture,
                        driverId: selectedDriverId!,
                      );
                    } else {
                      await vm.addBusAssignment(
                        plate: bus.plate,
                        region: region,
                        departure: selectedDeparture,
                        driverId: selectedDriverId!,
                      );
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ATAMA SİL
  // ============================================================

  void _confirmDeleteAssignment(
    BuildContext context,
    SettingsPageViewModel vm,
    BusModel bus,
    BusAssignmentModel assignment,
  ) {
    final driver = vm.getDriverById(assignment.driverId);

    final driverName = driver?.fullName ?? "Bilinmeyen şoför";

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Atamayı Sil"),
          content: Text(
            "${assignment.region} bölgesi için "
            "$assignment.departure kalkışlı "
            "$driverName şoför atamasını silmek "
            "istiyor musunuz?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("İptal"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await vm.removeBusAssignment(
                  plate: bus.plate,
                  assignmentId: assignment.id,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Sil"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ARAÇ AYARLARI
  // ============================================================

  void _showBusSettingsDialog(
    BuildContext context,
    SettingsPageViewModel vm,
    BusModel bus,
  ) {
    final noteController = TextEditingController(text: bus.note);

    bool manualTracking = bus.manualTracking;

    int hours = bus.estimatedArrivalMinutes ~/ 60;

    int minutes = bus.estimatedArrivalMinutes % 60;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("${bus.plate} Araç Ayarları"),

              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Araç Notu",
                        hintText: "Örn: Evrak teslim alınacak",
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 18),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Manuel tahmini varış"),
                      subtitle: const Text("GPS olmayan araçlar için"),
                      value: manualTracking,
                      onChanged: (value) {
                        setState(() {
                          manualTracking = value;
                        });
                      },
                    ),

                    if (manualTracking) ...[
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: hours,
                              decoration: const InputDecoration(
                                labelText: "Saat",
                                border: OutlineInputBorder(),
                              ),
                              items: List.generate(
                                13,
                                (index) => DropdownMenuItem(
                                  value: index,
                                  child: Text("$index saat"),
                                ),
                              ),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    hours = value;
                                  });
                                }
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: minutes,
                              decoration: const InputDecoration(
                                labelText: "Dakika",
                                border: OutlineInputBorder(),
                              ),
                              items: const [0, 10, 20, 30, 40, 50]
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text("$value dk"),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    minutes = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Toplam tahmini süre: "
                        "$hours saat "
                        "$minutes dakika",
                      ),
                    ],
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text("İptal"),
                ),

                FilledButton(
                  onPressed: () async {
                    final totalMinutes = (hours * 60) + minutes;

                    await vm.updateBusNote(
                      plate: bus.plate,
                      note: noteController.text.trim(),
                    );

                    await vm.updateManualTracking(
                      plate: bus.plate,
                      enabled: manualTracking,
                      minutes: totalMinutes,
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text("Kaydet"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ARAÇ SİL
  // ============================================================

  void _confirmDeleteBus(
    BuildContext context,
    SettingsPageViewModel vm,
    BusModel bus,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Aracı Sil"),
          content: Text(
            "${bus.plate} plakalı aracı "
            "silmek istediğinize emin misiniz?\n\n"
            "Bu araca bağlı "
            "${bus.assignments.length} atama da silinecektir.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("İptal"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await vm.removeBus(bus);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Sil"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ŞOFÖRLER
  // ============================================================

  Widget _buildDriversContent(SettingsPageViewModel vm) {
    final query = _driverSearchQuery.trim().toLowerCase();

    final filteredDrivers = vm.drivers.where((driver) {
      final name = driver.fullName.toLowerCase();

      final phone = driver.phone.toLowerCase();

      return query.isEmpty || name.contains(query) || phone.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          onChanged: (value) {
            setState(() {
              _driverSearchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: "Şoför adına veya telefona göre ara...",
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _driverSearchQuery.isNotEmpty
                ? IconButton(
                    tooltip: "Aramayı temizle",
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _driverSearchQuery = "";
                      });
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 12),

        if (vm.drivers.isEmpty)
          _buildEmptyState("Henüz şoför eklenmedi.", Icons.drive_eta_outlined)
        else if (filteredDrivers.isEmpty)
          _buildEmptyState(
            "Aramanızla eşleşen şoför bulunamadı.",
            Icons.search_off,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredDrivers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final driver = filteredDrivers[index];

              return _buildDriverCard(vm, driver);
            },
          ),
      ],
    );
  }

  Widget _buildDriverCard(SettingsPageViewModel vm, DriverModel driver) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(_getInitials(driver.firstName, driver.lastName)),
        ),
        title: Text(
          driver.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (driver.phone.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text("Telefon: ${driver.phone}"),
              ),
            if (driver.note.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Not: ${driver.note}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: "Şoförü düzenle",
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                _showDriverDialog(context, vm, driver: driver);
              },
            ),
            IconButton(
              tooltip: "Şoförü sil",
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                _confirmDeleteDriver(context, vm, driver);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ŞOFÖR EKLE / DÜZENLE
  // ============================================================

  void _showDriverDialog(
    BuildContext context,
    SettingsPageViewModel vm, {
    DriverModel? driver,
  }) {
    final isEdit = driver != null;

    final firstNameController = TextEditingController(
      text: isEdit ? driver!.firstName : "",
    );

    final lastNameController = TextEditingController(
      text: isEdit ? driver!.lastName : "",
    );

    final phoneController = TextEditingController(
      text: isEdit ? driver!.phone : "",
    );

    final noteController = TextEditingController(
      text: isEdit ? driver!.note : "",
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEdit ? "Şoförü Düzenle" : "Yeni Şoför"),

          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: "Ad",
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Ad giriniz.";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: lastNameController,
                      decoration: const InputDecoration(
                        labelText: "Soyad",
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Soyad giriniz.";
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: const InputDecoration(
                        labelText: "Telefon",
                        hintText: "05XXXXXXXXX",
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Not",
                        hintText: "Şoför hakkında not...",
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("İptal"),
            ),

            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: Text(isEdit ? "Güncelle" : "Kaydet"),
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final firstName = firstNameController.text.trim();

                final lastName = lastNameController.text.trim();

                final phone = phoneController.text.trim();

                final note = noteController.text.trim();

                if (isEdit) {
                  await vm.updateDriver(
                    DriverModel(
                      id: driver!.id,
                      firstName: firstName,
                      lastName: lastName,
                      phone: phone,
                      note: note,
                    ),
                  );
                } else {
                  await vm.addDriver(
                    DriverModel(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      firstName: firstName,
                      lastName: lastName,
                      phone: phone,
                      note: note,
                    ),
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ŞOFÖR SİL
  // ============================================================

  void _confirmDeleteDriver(
    BuildContext context,
    SettingsPageViewModel vm,
    DriverModel driver,
  ) {
    final assignmentCount = vm.buses
        .expand((bus) => bus.assignments)
        .where((assignment) => assignment.driverId == driver.id)
        .length;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Şoförü Sil"),
          content: Text(
            "${driver.fullName} isimli şoförü "
            "silmek istediğinize emin misiniz?"
            "${assignmentCount > 0 ? "\n\nBu şoför ${assignmentCount} araç atamasında kullanılıyor." : ""}",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("İptal"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await vm.removeDriver(driver);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Sil"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MUAVİNLER
  // ============================================================

  Widget _buildAssistantsSection(SettingsPageViewModel vm) {
    final query = _assistantSearchQuery.trim().toLowerCase();

    final filteredAssistants = vm.assistants.where((assistant) {
      final fullName =
          "${assistant.firstName} "
                  "${assistant.lastName}"
              .toLowerCase();

      final phone = assistant.phone.toLowerCase();

      return query.isEmpty || fullName.contains(query) || phone.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCollapsibleSectionHeader(
          title: "Muavinler",
          icon: Icons.support_agent_rounded,
          expanded: _assistantsExpanded,
          itemCount: vm.assistants.length,
          onToggle: () {
            setState(() {
              _assistantsExpanded = !_assistantsExpanded;
            });
          },
          onAdd: () {
            _showAssistantDialog(context, vm);
          },
        ),

        if (_assistantsExpanded) ...[
          const SizedBox(height: 12),

          TextField(
            onChanged: (value) {
              setState(() {
                _assistantSearchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Muavin adına göre ara...",
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _assistantSearchQuery.isNotEmpty
                  ? IconButton(
                      tooltip: "Temizle",
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _assistantSearchQuery = "";
                        });
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          if (vm.assistants.isEmpty)
            _buildEmptyState(
              "Henüz muavin eklenmedi.",
              Icons.support_agent_outlined,
            )
          else if (filteredAssistants.isEmpty)
            _buildEmptyState(
              "Aramanızla eşleşen muavin bulunamadı.",
              Icons.search_off,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAssistants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final assistant = filteredAssistants[index];

                return _buildAssistantTile(vm, assistant);
              },
            ),
        ],
      ],
    );
  }

  Widget _buildAssistantTile(
    SettingsPageViewModel vm,
    AssistantModel assistant,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: CircleAvatar(
        child: Text(_getInitials(assistant.firstName, assistant.lastName)),
      ),
      title: Text(
        "${assistant.firstName} ${assistant.lastName}",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (assistant.phone.trim().isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 17),
                  const SizedBox(width: 6),
                  Expanded(child: SelectableText(assistant.phone)),
                  IconButton(
                    tooltip: "Telefonu kopyala",
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_outlined, size: 17),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: assistant.phone));

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Telefon numarası kopyalandı."),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),

            if (assistant.tc.trim().isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 17),
                  const SizedBox(width: 6),
                  Expanded(child: SelectableText(assistant.tc)),
                  IconButton(
                    tooltip: "T.C. kimlik numarasını kopyala",
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_outlined, size: 17),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: assistant.tc));

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("T.C. kimlik numarası kopyalandı."),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: "Muavini düzenle",
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              _showAssistantDialog(context, vm, assistant: assistant);
            },
          ),
          IconButton(
            tooltip: "Muavini sil",
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              _confirmDeleteAssistant(context, vm, assistant);
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MUAVİN EKLE / DÜZENLE
  // ============================================================

  void _showAssistantDialog(
    BuildContext context,
    SettingsPageViewModel vm, {
    AssistantModel? assistant,
  }) {
    final isEdit = assistant != null;

    final nameController = TextEditingController(
      text: isEdit ? assistant!.firstName : "",
    );

    final surnameController = TextEditingController(
      text: isEdit ? assistant!.lastName : "",
    );

    final phoneController = TextEditingController(
      text: isEdit ? assistant!.phone : "",
    );

    final tcController = TextEditingController(
      text: isEdit ? assistant!.tc : "",
    );

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEdit ? "Muavin Bilgilerini Güncelle" : "Yeni Muavin"),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Ad",
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Ad giriniz.";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: surnameController,
                      decoration: const InputDecoration(
                        labelText: "Soyad",
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Soyad giriniz.";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: const InputDecoration(
                        labelText: "Telefon",
                        hintText: "05XXXXXXXXX",
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: tcController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      decoration: const InputDecoration(
                        labelText: "T.C. Kimlik No",
                        hintText: "11111111111",
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "T.C. kimlik numarası giriniz.";
                        }

                        if (value.length != 11) {
                          return "T.C. kimlik numarası 11 haneli olmalıdır.";
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("İptal"),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: Text(isEdit ? "Güncelle" : "Kaydet"),
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final firstName = nameController.text.trim();

                final lastName = surnameController.text.trim();

                final phone = phoneController.text.trim();

                final tc = tcController.text.trim();

                if (isEdit) {
                  await vm.updateAssistant(
                    AssistantModel(
                      id: assistant!.id,
                      firstName: firstName,
                      lastName: lastName,
                      phone: phone,
                      tc: tc,
                    ),
                  );
                } else {
                  await vm.addAssistant(
                    AssistantModel(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      firstName: firstName,
                      lastName: lastName,
                      phone: phone,
                      tc: tc,
                    ),
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MUAVİN SİL
  // ============================================================

  void _confirmDeleteAssistant(
    BuildContext context,
    SettingsPageViewModel vm,
    AssistantModel assistant,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Muavini Sil"),
          content: Text(
            "${assistant.firstName} "
            "${assistant.lastName} isimli muavini "
            "silmek istediğinize emin misiniz?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("İptal"),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await vm.removeAssistant(assistant);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text("Sil"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SAĞ PANEL
  // ============================================================

  Widget _buildRightPanel(SettingsPageViewModel vm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(Icons.settings),
              title: Text(
                "Sistem Ayarları",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),

            const Divider(),

            SwitchListTile(
              title: const Text("Bildirimler"),
              value: vm.notification,
              onChanged: vm.setNotification,
            ),

            SwitchListTile(
              title: const Text("Sesli Anons"),
              value: vm.voice,
              onChanged: vm.setVoice,
            ),

            SwitchListTile(
              title: const Text("Şoförü Seslendir"),
              value: vm.speakDriver,
              onChanged: vm.setSpeakDriver,
            ),

            SwitchListTile(
              title: const Text("Kalkış Yerini Seslendir"),
              value: vm.speakDeparture,
              onChanged: vm.setSpeakDeparture,
            ),

            SwitchListTile(
              title: const Text("Plakayı Seslendir"),
              value: vm.speakPlate,
              onChanged: vm.setSpeakPlate,
            ),

            SwitchListTile(
              title: const Text("Bölgeyi Seslendir"),
              value: vm.speakRegion,
              onChanged: vm.setSpeakRegion,
            ),

            const SizedBox(height: 10),



            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: vm.voiceType,
              decoration: const InputDecoration(
                labelText: "Ses Tipi",
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: "Kadın", child: Text("Kadın")),
                DropdownMenuItem(value: "Erkek", child: Text("Erkek")),
              ],
              onChanged: (value) {
                if (value != null) {
                  vm.setVoiceType(value);
                }
              },
            ),

            const SizedBox(height: 30),

            const Opacity(
              opacity: 0.5,
              child: Text(
                "Created by Oğulcan KAÇAR",
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildCollapsibleSectionHeader({
    required String title,
    required IconData icon,
    required bool expanded,
    required int itemCount,
    required VoidCallback onToggle,
    required VoidCallback onAdd,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),

            const SizedBox(width: 12),

            Expanded(
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 10),

                      _buildCountBadge(itemCount),

                      const SizedBox(width: 8),

                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            FilledButton.tonalIcon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text("Ekle"),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SAYI ROZETİ
  // ============================================================

  Widget _buildCountBadge(int count, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$count kayıt",
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: small ? 11 : 13,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(String text, IconData icon) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          children: [
            Icon(icon, size: 45, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // YARDIMCI
  // ============================================================

  String _getInitials(String name, String surname) {
    final nameInitial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : "";

    final surnameInitial = surname.trim().isNotEmpty
        ? surname.trim()[0].toUpperCase()
        : "";

    return "$nameInitial$surnameInitial";
  }
}

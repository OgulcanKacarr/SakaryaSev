
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../models/Vehicle/Vehicle.dart';
import '../../viewModel/settings/SettingsViewModel.dart';

final settingsProvider =
ChangeNotifierProvider((ref) => SettingsPageViewModel());

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final vm = ref.read(settingsProvider);
      vm.loadVehicles();
      vm.loadAppSettings();
    });
  }
  Future<void> _openVehicleDialog({Vehicle? vehicle}) async {
    final result = await showDialog<Vehicle>(
      context: context,
      builder: (_) => VehicleFormDialog(vehicle: vehicle),
    );

    if (!mounted || result == null) return;

    final vm = ref.read(settingsProvider);
    final success = result.id == null
        ? vm.addVehicle(result)
        : vm.updateVehicle(result);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (result.id == null
              ? 'Araç başarıyla eklendi.'
              : 'Araç bilgileri güncellendi.')
              : (vm.errorMessage ?? 'İşlem başarısız oldu.'),
        ),
      ),
    );
  }

  Future<void> _deleteVehicle(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Aracı sil'),
        content: Text(
          '${vehicle.plate} plakalı aracı silmek istiyor musun?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || vehicle.id == null) return;

    final vm = ref.read(settingsProvider);
    final success = vm.deleteVehicle(vehicle.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Araç silindi.'
              : (vm.errorMessage ?? 'Araç silinemedi.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Colors.teal,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Araç Yönetimi',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Araçları ve TRIO eşleşmelerini yönet.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_bus, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${vm.vehicleCount} araç',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  FilledButton.icon(
                    onPressed: () => _openVehicleDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Araç Ekle'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : vm.errorMessage != null && vm.vehicles.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 42,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(vm.errorMessage!),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: vm.loadVehicles,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
                    : vm.vehicles.isEmpty
                    ? _buildEmptyState(theme)
                    : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns =
                    constraints.maxWidth < 650 ? 1 : 3;

                    return GridView.builder(
                      itemCount: vm.vehicles.length,
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        mainAxisExtent: 310,
                      ),
                      itemBuilder: (context, index) {
                        final vehicle = vm.vehicles[index];

                        return _VehicleCard(
                          vehicle: vehicle,
                          onEdit: () =>
                              _openVehicleDialog(
                                vehicle: vehicle,
                              ),
                          onDelete: () =>
                              _deleteVehicle(vehicle),
                        );

                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 76,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 18),
          Text(
            'Henüz araç eklenmedi',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Başlamak için ilk aracını ekleyebilirsin.'),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _openVehicleDialog(),
            icon: const Icon(Icons.add),
            label: const Text('İlk Aracı Ekle'),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.brightness == Brightness.dark
        ? const Color(0xFF292D32)
        : const Color(0xFFE9ECEF);

    return Card(
      color: cardColor,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: vehicle.isActive
                        ? Colors.green.withOpacity(0.13)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: vehicle.isActive
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vehicle.isActive ? 'Aktif' : 'Pasif',
                        style: TextStyle(
                          fontSize: 12,
                          color: vehicle.isActive
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: 'Araç işlemleri',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined),
                          SizedBox(width: 10),
                          Text('Düzenle'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 10),
                          Text('Sil'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/bus.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.directions_bus_rounded,
                    size: 100,
                    color: theme.colorScheme.onSurface.withOpacity(0.35),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              vehicle.plate,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.6,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              [
                if (vehicle.brand?.isNotEmpty == true) vehicle.brand!,
                if (vehicle.model?.isNotEmpty == true) vehicle.model!,
                if (vehicle.year != null) vehicle.year.toString(),
              ].join(' • ').isEmpty
                  ? 'Marka ve model bilgisi girilmedi'
                  : [
                if (vehicle.brand?.isNotEmpty == true) vehicle.brand!,
                if (vehicle.model?.isNotEmpty == true) vehicle.model!,
                if (vehicle.year != null) vehicle.year.toString(),
              ].join(' • '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),

            if (vehicle.description?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                vehicle.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 10),

            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  size: 17,
                  color: Colors.teal,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'TRIO ID',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                vehicle.trioVehicleId?.isNotEmpty == true
                    ? vehicle.trioVehicleId!
                    : 'Henüz eşleştirilmedi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VehicleFormDialog extends StatefulWidget {
  final Vehicle? vehicle;

  const VehicleFormDialog({super.key, this.vehicle});

  @override
  State<VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _plateController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _yearController;
  late final TextEditingController _descriptionController;

  late bool _isActive;

  @override
  void initState() {
    super.initState();

    final vehicle = widget.vehicle;

    _plateController = TextEditingController(text: vehicle?.plate ?? '');
    _brandController = TextEditingController(text: vehicle?.brand ?? '');
    _modelController = TextEditingController(text: vehicle?.model ?? '');
    _yearController =
        TextEditingController(text: vehicle?.year?.toString() ?? '');
    _descriptionController =
        TextEditingController(text: vehicle?.description ?? '');
    _isActive = vehicle?.isActive ?? true;


  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.vehicle != null;

    return AlertDialog(
      title: Text(isEditing ? 'Aracı Düzenle' : 'Yeni Araç Ekle'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(
                  controller: _plateController,
                  label: 'Araç plakası',
                  hint: 'Örn. 54 BB 205',
                  requiredField: true,
                ),
                _field(
                  controller: _brandController,
                  label: 'Marka',
                  hint: 'Örn. Mercedes-Benz',
                ),
                _field(
                  controller: _modelController,
                  label: 'Model',
                  hint: 'Örn. Tourismo',
                ),
                _field(
                  controller: _yearController,
                  label: 'Model yılı',
                  hint: 'Örn. 2024',
                  numeric: true,
                ),
                _field(
                  controller: _descriptionController,
                  label: 'Açıklama',
                  hint: 'İsteğe bağlı araç bilgileri',
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Araç aktif'),
                  value: _isActive,
                  activeThumbColor: Colors.teal,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(isEditing ? 'Kaydet' : 'Aracı Ekle'),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool requiredField = false,
    bool numeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType:
        numeric ? TextInputType.number : TextInputType.text,
        textCapitalization:
        numeric ? TextCapitalization.none : TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (requiredField && (value == null || value.trim().isEmpty)) {
            return '$label zorunludur.';
          }

          if (numeric &&
              value != null &&
              value.trim().isNotEmpty &&
              int.tryParse(value.trim()) == null) {
            return 'Geçerli bir yıl gir.';
          }

          return null;
        },
      ),
    );
  }


  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final yearText = _yearController.text.trim();

    final vehicle = Vehicle(
      id: widget.vehicle?.id,
      plate: _plateController.text.trim().toUpperCase(),
      trioVehicleId: widget.vehicle?.trioVehicleId,
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      year: yearText.isEmpty ? null : int.parse(yearText),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      isActive: _isActive,
    );

    Navigator.of(context).pop<Vehicle>(vehicle);
  }

}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../SettingsPage.dart';


class GeneralSettingsPage extends ConsumerStatefulWidget {
  const GeneralSettingsPage({super.key});

  @override
  ConsumerState<GeneralSettingsPage> createState() =>
      _GeneralSettingsPageState();
}

class _GeneralSettingsPageState
    extends ConsumerState<GeneralSettingsPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(settingsProvider).loadAppSettings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(settingsProvider);
    final settings = vm.appSettings;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            Text(
              'Genel Ayarlar',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Seslendirme ve bildirim tercihlerini yönet.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Seslendirme'),
                    subtitle: const Text(
                      'Olaylar sesli olarak duyurulsun.',
                    ),
                    secondary: const Icon(Icons.record_voice_over),
                    value: settings.voiceEnabled,
                    onChanged: (value) {
                      vm.updateAppSettings(
                        settings.copyWith(voiceEnabled: value),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.record_voice_over),
                    title: const Text('Ses türü'),
                    trailing: DropdownButton<String>(
                      value: settings.voiceGender,
                      items: const [
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Kadın'),
                        ),
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('Erkek'),
                        ),
                      ],
                      onChanged: settings.voiceEnabled
                          ? (value) {
                        if (value != null) {
                          vm.updateAppSettings(
                            settings.copyWith(
                              voiceGender: value,
                            ),
                          );
                        }
                      }
                          : null,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Windows bildirimleri'),
                    secondary: const Icon(Icons.notifications_active),
                    value: settings.windowsNotificationsEnabled,
                    onChanged: (value) {
                      vm.updateAppSettings(
                        settings.copyWith(
                          windowsNotificationsEnabled: value,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Hız ihlalleri'),
                    secondary: const Icon(Icons.speed),
                    value: settings.speedNotificationsEnabled,
                    onChanged: (value) {
                      vm.updateAppSettings(
                        settings.copyWith(
                          speedNotificationsEnabled: value,
                        ),
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Kontak olayları'),
                    secondary: const Icon(Icons.key),
                    value: settings.ignitionNotificationsEnabled,
                    onChanged: (value) {
                      vm.updateAppSettings(
                        settings.copyWith(
                          ignitionNotificationsEnabled: value,
                        ),
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Rölanti olayları'),
                    secondary: const Icon(Icons.hourglass_bottom),
                    value: settings.idleNotificationsEnabled,
                    onChanged: (value) {
                      vm.updateAppSettings(
                        settings.copyWith(
                          idleNotificationsEnabled: value,
                        ),
                      );
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Bölge giriş / çıkışları'),
                    secondary: const Icon(Icons.location_on_outlined),
                    value: settings.regionNotificationsEnabled,
                    onChanged: (value) {
                      vm.updateAppSettings(
                        settings.copyWith(
                          regionNotificationsEnabled: value,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            if (vm.settingsErrorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                vm.settingsErrorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../viewModel/home/HomePageViewModel.dart';
import '../settings/GeneralSettingsPage/GeneralSettingsPage.dart';
import '../settings/SettingsPage.dart';

final homeProvider =
ChangeNotifierProvider((ref) => HomePageViewModel());

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(homeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            color: const Color(0xFF171C20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_bus_filled_rounded,
                        color: Colors.tealAccent,
                        size: 34,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Sakarya SEV',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 34),
                _MenuItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Ana Sayfa',
                  selected: vm.selectedPage == 'home',
                  onTap: () => ref
                      .read(homeProvider)
                      .selectPage('home'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: InkWell(
                    onTap: () =>
                        ref.read(homeProvider).toggleSettings(),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.settings_rounded,
                            color: Colors.white70,
                            size: 21,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Ayarlar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            vm.settingsExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (vm.settingsExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 25),
                    child: _MenuItem(
                      icon: Icons.tune_rounded,
                      title: 'Genel Ayarlar',
                      selected: vm.selectedPage == 'generalSettings',
                      onTap: () => ref
                          .read(homeProvider)
                          .selectPage('generalSettings'),
                      compact: true,
                    ),
                  ),
                if (vm.settingsExpanded)
                  Padding(
                    padding: const EdgeInsets.only(left: 25),
                    child: _MenuItem(
                      icon: Icons.directions_bus_outlined,
                      title: 'Araçlar',
                      selected: vm.selectedPage == 'vehicles',
                      onTap: () => ref
                          .read(homeProvider)
                          .selectPage('vehicles'),
                      compact: true,
                    ),
                  ),
                const Spacer(),
                const Divider(color: Colors.white12),
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Sakarya SEV • Yönetim',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(vm.selectedPage, theme),
          ),

        ],
      ),
    );
  }

    Widget _buildContent(String page, ThemeData theme) {
      switch (page) {
        case 'vehicles':
          return const SettingsPage();

        case 'generalSettings':
          return const GeneralSettingsPage();

        case 'home':
        default:
          return Container(
            color: theme.scaffoldBackgroundColor,
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ana Sayfa',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sakarya SEV araç takip ve yönetim paneline hoş geldin.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_bus_rounded,
                          size: 38,
                          color: Colors.teal,
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Text(
                            'Araç takip özeti ve TRIO olayları bu alana eklenecek.',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
      }
    }
  }


class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 12,
        3,
        12,
        3,
      ),
      child: Material(
        color: selected
            ? const Color(0xFF126E65)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 11 : 13,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? Colors.white
                      : Colors.white70,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.circle,
                    size: 7,
                    color: Colors.tealAccent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

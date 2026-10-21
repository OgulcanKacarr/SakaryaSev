
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../services/NoteService/NoteService.dart';
import '../../services/TrioNotificationService/TrioNotificationService.dart';
import '../../viewModel/home/HomePageViewModel.dart';
import '../settings/GeneralSettingsPage/GeneralSettingsPage.dart';
import '../settings/KasaPage/KasaPage.dart';
import '../settings/MuavinPage/MuavinPage.dart';
import '../settings/NotesPage/NotesPage.dart';
import '../settings/SoforPage/SoforPage.dart';
import '../settings/SettingsPage.dart';

final homeProvider = ChangeNotifierProvider(
      (ref) => HomePageViewModel(),
);

const _navBackground = Color(0xFF151D2B);
const _accent = Color(0xFF0D9488);
const _pageBackground = Color(0xFFDCE5EF);
const _textPrimary = Color(0xFF172033);
const _textSecondary = Color(0xFF697586);
const _cardBackground = Color(0xFFF1F5F9);
const _cardBorder = Color(0xFFD5DEE9);

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: _pageBackground,
      body: Row(
        children: [
          _Sidebar(
            selectedPage: vm.selectedPage,
            settingsExpanded: vm.settingsExpanded,
            onSelect: (page) =>
                ref.read(homeProvider).selectPage(page),
            onToggleSettings: () =>
                ref.read(homeProvider).toggleSettings(),
          ),
          Expanded(
            child: _buildContent(vm.selectedPage, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String page, WidgetRef ref) {
    switch (page) {
      case 'vehicles':
        return const SettingsPage();
      case 'generalSettings':
        return const GeneralSettingsPage();
      case 'muavinler':
        return const MuavinPage();
      case 'soforler':
        return const SoforPage();
      case 'notes':
        return const NotesPage();
      case 'kasa':
        return KasaPage();
      case 'home':
      default:
        return _Dashboard(
          onOpenNotes: () =>
              ref.read(homeProvider).selectPage('notes'),
          onOpenVehicles: () =>
              ref.read(homeProvider).selectPage('vehicles'),
          onOpenCash: () =>
              ref.read(homeProvider).selectPage('kasa'),
          onOpenDrivers: () =>
              ref.read(homeProvider).selectPage('soforler'),
          onOpenAssistants: () =>
              ref.read(homeProvider).selectPage('muavinler'),
        );
    }
  }
}

// -----------------------------------------------------------------------------
// SIDEBAR
// -----------------------------------------------------------------------------

class _Sidebar extends StatelessWidget {
  final String selectedPage;
  final bool settingsExpanded;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggleSettings;

  const _Sidebar({
    required this.selectedPage,
    required this.settingsExpanded,
    required this.onSelect,
    required this.onToggleSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: _navBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 18, 28),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.directions_bus_filled_rounded,
                      color: Color(0xFF5EEAD4),
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sakarya SEV',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'YÖNETİM PANELİ',
                          style: TextStyle(
                            color: Color(0xFF9BA8BA),
                            fontSize: 9,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 18, 10),
              child: Text(
                'MENÜ',
                style: TextStyle(
                  color: Color(0xFF77869A),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            _NavItem(
              icon: Icons.grid_view_rounded,
              title: 'Ana Sayfa',
              selected: selectedPage == 'home',
              onTap: () => onSelect('home'),
            ),
            _NavItem(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Gün Sonu Kasa',
              selected: selectedPage == 'kasa',
              onTap: () => onSelect('kasa'),
            ),
            _NavItem(
              icon: Icons.sticky_note_2_rounded,
              title: 'Notlar',
              selected: selectedPage == 'notes',
              onTap: () => onSelect('notes'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 4),
              child: Material(
                color: settingsExpanded
                    ? Colors.white.withOpacity(0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: onToggleSettings,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.settings_rounded,
                          color: Color(0xFFB7C2D0),
                          size: 19,
                        ),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Text(
                            'Yönetim',
                            style: TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          settingsExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF9BA8BA),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (settingsExpanded) ...[
              _NavItem(
                icon: Icons.tune_rounded,
                title: 'Genel Ayarlar',
                selected: selectedPage == 'generalSettings',
                compact: true,
                onTap: () => onSelect('generalSettings'),
              ),
              _NavItem(
                icon: Icons.directions_bus_outlined,
                title: 'Araçlar',
                selected: selectedPage == 'vehicles',
                compact: true,
                onTap: () => onSelect('vehicles'),
              ),
              _NavItem(
                icon: Icons.badge_outlined,
                title: 'Muavinler',
                selected: selectedPage == 'muavinler',
                compact: true,
                onTap: () => onSelect('muavinler'),
              ),
              _NavItem(
                icon: Icons.airline_seat_recline_normal_rounded,
                title: 'Şoförler',
                selected: selectedPage == 'soforler',
                compact: true,
                onTap: () => onSelect('soforler'),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.045),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.07),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Color(0xFF5EEAD4),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Created by Oğulcan KAÇAR\n\nwww.github.com/OgulcanKacarr',
                        style: TextStyle(
                          color: Color(0xFFB7C2D0),
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 24 : 14, 3, 14, 3),
      child: Material(
        color: selected ? _accent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 10 : 12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: compact ? 17 : 19,
                  color: selected
                      ? Colors.white
                      : const Color(0xFFB7C2D0),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : const Color(0xFFD4DCE6),
                      fontSize: compact ? 12 : 13,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFCCFBF1),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DASHBOARD
// -----------------------------------------------------------------------------

class _Dashboard extends StatelessWidget {
  final VoidCallback onOpenNotes;
  final VoidCallback onOpenVehicles;
  final VoidCallback onOpenCash;
  final VoidCallback onOpenDrivers;
  final VoidCallback onOpenAssistants;

  const _Dashboard({
    required this.onOpenNotes,
    required this.onOpenVehicles,
    required this.onOpenCash,
    required this.onOpenDrivers,
    required this.onOpenAssistants,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${now.day.toString().padLeft(2, '0')}.'
        '${now.month.toString().padLeft(2, '0')}.'
        '${now.year}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
        constraints.maxWidth < 900 ? 22.0 : 36.0;

        return Container(
          color: _pageBackground,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              30,
              horizontalPadding,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kontrol Merkezi',
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.7,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Sakarya SEV yönetim paneline hoş geldiniz.',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: _cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: _accent,
                          ),
                          const SizedBox(width: 9),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // TRIO BİLDİRİMLERİ: SAYFANIN EN ÜSTÜNDE
                const SizedBox(height: 24),
                const _TrioEventsCard(prominent: true),

                const SizedBox(height: 28),
                const _SectionHeading(
                  title: 'Hızlı Erişim',
                  subtitle:
                  'Sık kullanılan işlemlere tek tıkla ulaşın.',
                ),
                const SizedBox(height: 14),

                LayoutBuilder(
                  builder: (context, cardConstraints) {
                    final compact =
                        cardConstraints.maxWidth < 760;

                    final cards = [
                      _ShortcutData(
                        title: 'Araçlar',
                        description: 'Araç kayıtları ve yönetimi',
                        icon: Icons.directions_bus_rounded,
                        color: const Color(0xFF2563EB),
                        onTap: onOpenVehicles,
                      ),
                      _ShortcutData(
                        title: 'Notlar',
                        description:
                        'Notları ve hatırlatmaları görüntüle',
                        icon: Icons.sticky_note_2_rounded,
                        color: const Color(0xFF7C3AED),
                        onTap: onOpenNotes,
                      ),
                      _ShortcutData(
                        title: 'Gün Sonu Kasa',
                        description: 'Kasa işlemlerine geçiş yap',
                        icon:
                        Icons.account_balance_wallet_rounded,
                        color: _accent,
                        onTap: onOpenCash,
                      ),
                    ];

                    if (compact) {
                      return Column(
                        children: cards
                            .map(
                              (item) => Padding(
                            padding:
                            const EdgeInsets.only(bottom: 12),
                            child: _ShortcutCard(data: item),
                          ),
                        )
                            .toList(),
                      );
                    }

                    return Row(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 14),
                          Expanded(
                            child: _ShortcutCard(data: cards[i]),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 26),
                const _SectionHeading(
                  title: 'Son Notlar',
                  subtitle: 'Eklenen son notlar ve hatırlatmalar.',
                ),
                const SizedBox(height: 14),
                _RecentNotesCard(onOpenNotes: onOpenNotes),

                const SizedBox(height: 26),
                const _SectionHeading(
                  title: 'Personel Yönetimi',
                  subtitle:
                  'Şoför ve muavin kayıtlarına hızlıca erişin.',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 520) {
                      return Column(
                        children: [
                          _SmallActionCard(
                            icon: Icons
                                .airline_seat_recline_normal_rounded,
                            title: 'Şoförler',
                            onTap: onOpenDrivers,
                          ),
                          const SizedBox(height: 12),
                          _SmallActionCard(
                            icon: Icons.badge_outlined,
                            title: 'Muavinler',
                            onTap: onOpenAssistants,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _SmallActionCard(
                            icon: Icons
                                .airline_seat_recline_normal_rounded,
                            title: 'Şoförler',
                            onTap: onOpenDrivers,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SmallActionCard(
                            icon: Icons.badge_outlined,
                            title: 'Muavinler',
                            onTap: onOpenAssistants,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TRIO OLAYLARI — SABİT YÜKSEKLİK, KENDİ İÇİNDE KAYDIRMA
// -----------------------------------------------------------------------------

class _TrioEventsCard extends StatelessWidget {
  final bool prominent;

  const _TrioEventsCard({
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TrioDashboardEvent>>(
      valueListenable:
      TrioNotificationService.instance.dashboardEvents,
      builder: (context, events, _) {
        return Container(
          height: prominent ? 440 : 340,
          padding: EdgeInsets.all(prominent ? 22 : 18),
          decoration: BoxDecoration(
            color: _cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: prominent
                  ? const Color(0xFFF5C98B)
                  : _cardBorder,
            ),
            boxShadow: prominent
                ? [
              BoxShadow(
                color: const Color(0xFFD97706)
                    .withOpacity(0.07),
                blurRadius: 22,
                offset: const Offset(0, 7),
              ),
            ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: prominent ? 48 : 38,
                    height: prominent ? 48 : 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: const Color(0xFFD97706),
                      size: prominent ? 25 : 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TRIO Olayları & Bildirimler',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: prominent ? 19 : 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Araçlardan gelen güncel olay kayıtları',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: prominent ? 12 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: events.isEmpty
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${events.length}',
                          style: TextStyle(
                            color: events.isEmpty
                                ? _textSecondary
                                : const Color(0xFF9A3412),
                            fontSize: prominent ? 20 : 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'OLAY',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: _cardBorder, height: 1),
              const SizedBox(height: 12),

              // Bu alanın dışındaki başlık ve sayaç sabit kalır.
              // Olaylar çoğaldığında sadece liste kayar.
              Expanded(
                child: events.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        color: Color(0xFFB7C2D0),
                        size: 38,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Aktif olay bulunmuyor.',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
                    : Scrollbar(
                  child: ListView.separated(
                    primary: false,
                    padding: const EdgeInsets.only(
                      right: 8,
                      bottom: 4,
                    ),
                    itemCount: events.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final time = event.receivedAt;

                      final timeLabel =
                          '${time.hour.toString().padLeft(2, '0')}:'
                          '${time.minute.toString().padLeft(2, '0')}:'
                          '${time.second.toString().padLeft(2, '0')}';

                      final IconData icon =
                      switch (event.type) {
                        TrioEventType.speed =>
                        Icons.speed_rounded,
                        TrioEventType.ignition =>
                        Icons.key_rounded,
                        TrioEventType.idle =>
                        Icons.local_shipping_rounded,
                        TrioEventType.region =>
                        Icons.location_on_rounded,
                      };

                      return Container(
                        padding: EdgeInsets.all(
                          prominent ? 14 : 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(14),
                          border: Border.all(
                            color: _cardBorder,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: prominent ? 44 : 38,
                              height: prominent ? 44 : 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEDD5),
                                borderRadius:
                                BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                color: const Color(0xFFD97706),
                                size: prominent ? 23 : 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 5,
                                    crossAxisAlignment:
                                    WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        event.plate,
                                        style: TextStyle(
                                          color: _textPrimary,
                                          fontSize:
                                          prominent ? 14 : 12,
                                          fontWeight:
                                          FontWeight.w800,
                                        ),
                                      ),
                                      Container(
                                        padding:
                                        const EdgeInsets
                                            .symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFFFEDD5,
                                          ),
                                          borderRadius:
                                          BorderRadius
                                              .circular(7),
                                        ),
                                        child: Text(
                                          event.typeLabel,
                                          style: const TextStyle(
                                            color: Color(
                                              0xFFB45309,
                                            ),
                                            fontSize: 10,
                                            fontWeight:
                                            FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    event.message,
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize:
                                      prominent ? 12 : 11,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 2),
                              child: Text(
                                timeLabel,
                                style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SON NOTLAR
// -----------------------------------------------------------------------------

class _RecentNotesCard extends StatelessWidget {
  final VoidCallback onOpenNotes;

  const _RecentNotesCard({
    required this.onOpenNotes,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: NoteService.instance.changes,
      builder: (context, snapshot) {
        final notes =
        NoteService.instance.getRecentNotes(limit: 5);

        return _PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _IconBadge(
                    icon: Icons.sticky_note_2_rounded,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'Son Notlar',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onOpenNotes,
                    child: const Text('Tümünü gör'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: _cardBorder),
              if (notes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.note_add_outlined,
                          color: Color(0xFFB7C2D0),
                          size: 34,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Henüz not eklenmemiş.',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...notes.map(
                      (note) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: note.isImportant
                                ? const Color(0xFFFFF4D6)
                                : const Color(0xFFE3EAF2),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            note.isImportant
                                ? Icons.star_rounded
                                : note.vehicleId != null
                                ? Icons.directions_bus_rounded
                                : Icons.notes_rounded,
                            color: note.isImportant
                                ? const Color(0xFFD97706)
                                : const Color(0xFF64748B),
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  note.content,
                                  if (note.vehiclePlate != null)
                                    'Araç: ${note.vehiclePlate}',
                                  if (note.reminderAt != null)
                                    'Hatırlatma: ${note.reminderAt!.toLocal()}',
                                ].join(' • '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _textSecondary,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// SECTION HEADING
// -----------------------------------------------------------------------------

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// QUICK ACCESS CARDS
// -----------------------------------------------------------------------------

class _ShortcutData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ShortcutCard extends StatelessWidget {
  final _ShortcutData data;

  const _ShortcutCard({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data.description,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_outward_rounded,
                color: Color(0xFF9AA6B2),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PERSONNEL ACTION CARDS
// -----------------------------------------------------------------------------

class _SmallActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SmallActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _accent,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF9AA6B2),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SHARED PANEL AND ICON
// -----------------------------------------------------------------------------

class _PanelCard extends StatelessWidget {
  final Widget child;

  const _PanelCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/Muavin/Muavin.dart';
import '../../../viewModel/MuavinViewModel/MuavinViewModel.dart';

class MuavinPage extends ConsumerWidget {
  const MuavinPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(muavinProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık Alanı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Muavinler',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Araçlarda görev yapan muavinleri yönetin ve takip edin.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: vm.yukleniyor
                    ? null
                    : () => _muavinFormuAc(context, ref),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Muavin Ekle'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Üst İstatistik Kartı ve Arama Çubuğu
          Row(
            children: [
              SizedBox(
                width: 260,
                child: Card(
                  elevation: 0,
                  color: isDarkMode
                      ? theme.cardColor.withOpacity(0.6)
                      : const Color(0xFFF8F9FA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00796B).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: Color(0xFF00796B),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toplam Muavin',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${vm.toplamMuavin}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  onChanged: vm.ara,
                  decoration: InputDecoration(
                    hintText: 'Ad, soyad, telefon veya T.C. ile ara...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00796B)),
                    filled: true,
                    fillColor: isDarkMode ? theme.cardColor : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: theme.dividerColor.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF00796B),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Liste / Tablo Kartı
          Expanded(
            child: Card(
              elevation: 0,
              color: isDarkMode ? theme.cardColor : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: theme.dividerColor.withOpacity(0.15),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _listeIcerigi(context, ref, vm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listeIcerigi(
      BuildContext context,
      WidgetRef ref,
      MuavinViewModel vm,
      ) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (vm.yukleniyor) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00796B),
        ),
      );
    }

    if (vm.hata != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                vm.hata!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: vm.yukle,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final muavinler = vm.muavinler;

    if (muavinler.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.badge_outlined,
              size: 56,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz muavin kaydı bulunmuyor.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            isDarkMode ? Colors.grey[900] : const Color(0xFFF1F5F4),
          ),
          dataRowMinHeight: 60,
          dataRowMaxHeight: 65,
          columnSpacing: 24,
          horizontalMargin: 24,
          columns: const [
            DataColumn(label: Text('Ad Soyad', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Telefon', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('T.C. Kimlik No', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('İşlemler', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: muavinler.map((muavin) {
            return DataRow(
              cells: [
                // Ad Soyad Kopyalama
                DataCell(
                  InkWell(
                    onTap: () => _panoyaKopyala(context, muavin.tamAd, 'Ad Soyad'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF00796B).withOpacity(0.15),
                            child: const Icon(
                              Icons.person_outline,
                              size: 18,
                              color: Color(0xFF00796B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            muavin.tamAd,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.copy_rounded, size: 13, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                ),

                // Telefon Kopyalama
                DataCell(
                  InkWell(
                    onTap: () => _panoyaKopyala(context, muavin.telefon, 'Telefon'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(muavin.telefon),
                          const SizedBox(width: 8),
                          Icon(Icons.copy_rounded, size: 13, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                ),

                // T.C. Maskeli Gösterim & Tam Halini Kopyalama
                DataCell(
                  InkWell(
                    onTap: () => _panoyaKopyala(context, muavin.tc, 'T.C. Kimlik No'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _tcMaskele(muavin.tc),
                            style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1.1),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.copy_rounded, size: 13, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                ),

                // İşlemler
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Düzenle',
                        onPressed: () => _muavinFormuAc(
                          context,
                          ref,
                          muavin: muavin,
                        ),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Sil',
                        onPressed: () => _silmeOnayi(
                          context,
                          ref,
                          muavin,
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _panoyaKopyala(BuildContext context, String veri, String alanAdi) {
    Clipboard.setData(ClipboardData(text: veri));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$alanAdi panoya kopyalandı: $veri'), duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), ), ); }    String _tcMaskele(String tc) { if (tc.length != 11) return '***********'; return '${tc.substring(0, 3)}*****${tc.substring(8)}';
  }

  void _muavinFormuAc(
      BuildContext context,
      WidgetRef ref, {
        Muavin? muavin,
      }) {
    final formKey = GlobalKey<FormState>();

    final adController = TextEditingController(text: muavin?.ad);
    final soyadController = TextEditingController(text: muavin?.soyad);
    final telefonController = TextEditingController(text: muavin?.telefon);
    final tcController = TextEditingController(text: muavin?.tc);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        title: Text(
          muavin == null ? 'Yeni Muavin Ekle' : 'Muavini Düzenle',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SizedBox(
          width: 420,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _alan(adController, 'Ad'),
                  _alan(soyadController, 'Soyad'),
                  _alan(
                    telefonController,
                    'Telefon',
                    keyboardType: TextInputType.phone,
                  ),
                  _alan(
                    tcController,
                    'T.C. Kimlik No',
                    maxLength: 11,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              final vm = ref.read(muavinProvider);
              final ad = adController.text.trim();
              final soyad = soyadController.text.trim();
              final telefon = telefonController.text.trim();
              final tc = tcController.text.trim();

              try {
                if (vm.tcKullaniliyor(
                  tc,
                  mevcutId: muavin?.id,
                )) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bu T.C. kimlik numarası zaten kayıtlı.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                if (muavin == null) {
                  vm.ekle(
                    ad: ad,
                    soyad: soyad,
                    telefon: telefon,
                    tc: tc,
                  );
                } else {
                  vm.guncelle(
                    muavin: muavin,
                    ad: ad,
                    soyad: soyad,
                    telefon: telefon,
                    tc: tc,
                  );
                }

                Navigator.pop(dialogContext);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      muavin == null
                          ? 'Muavin başarıyla eklendi.'
                          : 'Muavin bilgileri güncellendi.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kayıt işlemi başarısız: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    ); // <-- `.then(...)` bloğu ve içindeki controller dispose işlemleri tamamen kaldırıldı.
  }

  Widget _alan(
      TextEditingController controller,
      String label, {
        int? maxLength,
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLength: maxLength,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.withOpacity(0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF00796B), width: 1.5),
          ),
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (text.isEmpty) {
            return '$label alanı zorunludur.';
          }

          if (label == 'T.C. Kimlik No' &&
              !RegExp(r'^\d{11}$').hasMatch(text)) {
            return 'T.C. kimlik numarası 11 rakam olmalıdır.';
          }

          return null;
        },
      ),
    );
  }

  Future<void> _silmeOnayi(
      BuildContext context,
      WidgetRef ref,
      Muavin muavin,
      ) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Muavini Sil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          '${muavin.tamAd} isimli muavini silmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay != true || !context.mounted) return;

    try {
      ref.read(muavinProvider).sil(muavin.id);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Muavin kaydı silindi.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme işlemi başarısız: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
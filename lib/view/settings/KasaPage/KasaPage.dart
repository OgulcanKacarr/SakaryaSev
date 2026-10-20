import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../models/KasaViewModel/KasaViewModel.dart';

class KasaPage extends ConsumerWidget {
  KasaPage({super.key});

  // Ekran görüntüsü almak için kullanılan global anahtar
  final GlobalKey _printKey = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(kasaProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    String para(double val) {
      return '${val.toStringAsFixed(2).replaceAll('.', ',')} ₺';
    }

    return RepaintBoundary(
      key: _printKey,
      child: Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ÜST BAŞLIK, TARİH VE DIŞA AKTARMA BUTONLARI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gün Sonu Kasa',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sakarya SEV günlük gelir, gider ve POS hesap kapatma paneli.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  children: [
                    // Tarih Seçici
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: vm.seciliTarih,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          ref.read(kasaProvider).tarihDegistir(picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      label: Text(
                        vm.tarihOkunabilir,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Excel (CSV) İndir Butonu
                    OutlinedButton.icon(
                      onPressed: () => _excelAktar(context, vm),
                      icon: const Icon(
                        Icons.table_chart_rounded,
                        size: 18,
                        color: Colors.green,
                      ),
                      label: const Text('Excel\'e Aktar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    // Fotoğraf (PNG) Kaydet Butonu
                    OutlinedButton.icon(
                      onPressed: () => _fotografKaydet(context, vm),
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: Colors.tealAccent,
                      ),
                      label: const Text('Görsel Kaydet'),
                      // ...
                    ),

                    // Kaydet Butonu
                    FilledButton.icon(
                      onPressed: vm.yukleniyor
                          ? null
                          : () async {
                              final success = await ref
                                  .read(kasaProvider)
                                  .kaydet();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Gün sonu kasa kaydı başarıyla kaydedildi.'
                                          : 'Kasa kaydedilirken bir hata oluştu.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: success
                                        ? Colors.teal
                                        : Colors.redAccent,
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.save_rounded, size: 20),
                      label: const Text('Kasayı Kaydet'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF00796B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ÖZET KARTLARI
            Row(
              children: [
                Expanded(
                  child: _OzetKarti(
                    baslik: 'Toplam Gelir',
                    tutar: para(vm.toplamGelir),
                    icon: Icons.arrow_downward_rounded,
                    color: Colors.green,
                    bgColor: Colors.green.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _OzetKarti(
                    baslik: 'Toplam Gider',
                    tutar: para(vm.toplamGider),
                    icon: Icons.arrow_upward_rounded,
                    color: Colors.redAccent,
                    bgColor: Colors.redAccent.withOpacity(0.1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _OzetKarti(
                    baslik: 'Kasada Kalan Nakit',
                    tutar: para(vm.kalanNakit),
                    icon: Icons.account_balance_wallet_rounded,
                    color: vm.kalanNakit >= 0
                        ? const Color(0xFF00796B)
                        : Colors.orange,
                    bgColor: const Color(0xFF00796B).withOpacity(0.12),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // TABLOLAR
            Expanded(
              child: vm.yukleniyor
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00796B),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // GİDERLER
                        Expanded(
                          flex: 5,
                          child: Card(
                            elevation: 0,
                            color: isDarkMode ? theme.cardColor : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: theme.dividerColor.withOpacity(0.15),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.remove_circle_outline,
                                            color: Colors.redAccent,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'GİDERLER',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _ekstraGiderEkleDialog(
                                          context,
                                          ref,
                                        ),
                                        icon: const Icon(
                                          Icons.add_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Ekstra Gider Ekle'),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 20),
                                  Expanded(
                                    child: ListView.separated(
                                      itemCount: vm.giderler.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final item = vm.giderler[index];
                                        return _KasaInputRow(
                                          baslik: item.baslik,
                                          deger: item.tutar,
                                          sabit: item.sabit,
                                          onChanged: (val) {
                                            ref
                                                .read(kasaProvider)
                                                .giderTutarGuncelle(index, val);
                                          },
                                          onDelete: () {
                                            ref
                                                .read(kasaProvider)
                                                .giderSil(index);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        // GELİRLER & AÇIKLAMA
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              Card(
                                elevation: 0,
                                color: isDarkMode
                                    ? theme.cardColor
                                    : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(
                                    color: theme.dividerColor.withOpacity(0.15),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'GELİRLER',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 20),
                                      ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: vm.gelirler.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 8),
                                        itemBuilder: (context, index) {
                                          final item = vm.gelirler[index];
                                          return _KasaInputRow(
                                            baslik: item.baslik,
                                            deger: item.tutar,
                                            sabit: true,
                                            onChanged: (val) {
                                              ref
                                                  .read(kasaProvider)
                                                  .gelirTutarGuncelle(
                                                    index,
                                                    val,
                                                  );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              Expanded(
                                child: Card(
                                  elevation: 0,
                                  color: isDarkMode
                                      ? theme.cardColor
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                    side: BorderSide(
                                      color: theme.dividerColor.withOpacity(
                                        0.15,
                                      ),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(
                                              Icons.notes_rounded,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'GÜN SONU NOTLARI / AÇIKLAMA',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // KasaPage içinde Card'ın altındaki bölüm:
                                        Expanded(
                                          child: _KasaAciklamaInput(
                                            aciklama: vm.aciklama,
                                            onChanged: (val) => ref
                                                .read(kasaProvider)
                                                .aciklamaGuncelle(val),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // EXCEL / CSV OLARAK MASAÜSTÜNE KAYDETME
  Future<void> _excelAktar(BuildContext context, KasaViewModel vm) async {
    try {
      final desktopPath = p.join(
        Platform.environment['USERPROFILE'] ?? '',
        'Desktop',
      );
      final dir = Directory(desktopPath);
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final fileName = 'SakaryaSEV_Kasa_${vm.tarihFormatli}.csv';
      final filePath = p.join(desktopPath, fileName);

      final buffer = StringBuffer();
      buffer.writeln('SAKARYA SEV - GÜN SONU KASA RAPORU');
      buffer.writeln('Tarih:;${vm.tarihOkunabilir}');
      buffer.writeln('');
      buffer.writeln('GELİRLER');
      buffer.writeln('Kalem;Tutar');
      for (var g in vm.gelirler) {
        buffer.writeln('${g.baslik};${g.tutar.toStringAsFixed(2)}');
      }
      buffer.writeln('');
      buffer.writeln('GİDERLER');
      buffer.writeln('Kalem;Tutar');
      for (var g in vm.giderler) {
        buffer.writeln('${g.baslik};${g.tutar.toStringAsFixed(2)}');
      }
      buffer.writeln('');
      buffer.writeln('TOPLAM GELİR;${vm.toplamGelir.toStringAsFixed(2)}');
      buffer.writeln('TOPLAM GİDER;${vm.toplamGider.toStringAsFixed(2)}');
      buffer.writeln('NAKİT KALAN;${vm.kalanNakit.toStringAsFixed(2)}');
      if (vm.aciklama.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln(
          'AÇIKLAMA / NOTLAR:;${vm.aciklama.replaceAll('\n', ' ')}',
        );
      }

      // Türkçe karakterlerin Excel'de bozulmaması için UTF-8 BOM ekliyoruz
      final file = File(filePath);
      await file.writeAsBytes([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(buffer.toString()),
      ]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel dosyası Masaüstüne kaydedildi: $fileName'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel dışa aktarma hatası: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

// GÖRSELİ EKRANDAN BAĞIMSIZ TAM BOY CANVAS ILE CIZIP MASAÜSTÜNE KAYDETME
  Future<void> _fotografKaydet(BuildContext context, KasaViewModel vm) async {
    try {
      // 1. Dinamik Yükseklik Hesabı (Kalem sayılarına göre resim yüksekliğini esnetiyoruz)
      final int satirSayisi = vm.giderler.length > vm.gelirler.length
          ? vm.giderler.length
          : vm.gelirler.length;

      final double genislik = 900;
      final double yukseklik = 350 + (satirSayisi * 38) + (vm.aciklama.isNotEmpty ? 120 : 0);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, genislik, yukseklik));

      // Arka Plan
      final bgPaint = Paint()..color = const Color(0xFFF8F9FA);
      canvas.drawRect(Rect.fromLTWH(0, 0, genislik, yukseklik), bgPaint);

      // Üst Bilgi Kartı (Yeşil Başlık)
      final headerPaint = Paint()..color = const Color(0xFF00796B);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(20, 20, genislik - 40, 70), const Radius.circular(12)),
        headerPaint,
      );

      // Yazı Biçimlendiricileri
      TextPainter createText(String text, double fontSize, FontWeight weight, Color color) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color, fontFamily: 'sans-serif'),
          ),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        return tp;
      }

      // Başlık ve Tarih Yazıları
      createText('SAKARYA SEV - GÜN SONU KASA RAPORU', 18, FontWeight.bold, Colors.white)
          .paint(canvas, const Offset(40, 32));
      createText(vm.tarihOkunabilir, 13, FontWeight.w500, Colors.white70)
          .paint(canvas, const Offset(40, 56));

      double currentY = 110;

      // Tablo Başlıkları
      createText('GİDERLER', 15, FontWeight.bold, Colors.redAccent)
          .paint(canvas, Offset(30, currentY));
      createText('GELİRLER', 15, FontWeight.bold, Colors.green)
          .paint(canvas, Offset(genislik / 2 + 10, currentY));

      currentY += 28;

      // Satır Çizim Kalemi
      final rowBgPaint = Paint()..color = Colors.white;
      final borderPaint = Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke;

      // 2. TÜM GİDER VE GELİR KALEMLERİNİ TEKER TEKER ÇİZ
      for (int i = 0; i < satirSayisi; i++) {
        // Gider Kalemi
        if (i < vm.giderler.length) {
          final g = vm.giderler[i];
          final rect = Rect.fromLTWH(30, currentY, (genislik / 2) - 40, 32);
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), rowBgPaint);
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), borderPaint);

          createText(g.baslik, 12, FontWeight.w600, Colors.black87)
              .paint(canvas, Offset(40, currentY + 8));
          final t = createText('${g.tutar.toStringAsFixed(2).replaceAll('.', ',')} ₺', 12, FontWeight.bold, Colors.redAccent);
          t.paint(canvas, Offset((genislik / 2) - 15 - t.width, currentY + 8));
        }

        // Gelir Kalemi
        if (i < vm.gelirler.length) {
          final g = vm.gelirler[i];
          final rect = Rect.fromLTWH(genislik / 2 + 10, currentY, (genislik / 2) - 40, 32);
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), rowBgPaint);
          canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), borderPaint);

          createText(g.baslik, 12, FontWeight.w600, Colors.black87)
              .paint(canvas, Offset(genislik / 2 + 20, currentY + 8));
          final t = createText('${g.tutar.toStringAsFixed(2).replaceAll('.', ',')} ₺', 12, FontWeight.bold, Colors.green);
          t.paint(canvas, Offset(genislik - 35 - t.width, currentY + 8));
        }

        currentY += 36;
      }

      currentY += 15;

      // 3. ALTA BOYDAN BOYA ÖZET KARTLARI ÇİZ
      final ozetCardRect = Rect.fromLTWH(30, currentY, genislik - 60, 65);
      final ozetBgPaint = Paint()..color = const Color(0xFFE0F2F1);
      canvas.drawRRect(RRect.fromRectAndRadius(ozetCardRect, const Radius.circular(10)), ozetBgPaint);

      createText('TOPLAM GELİR: ${vm.toplamGelir.toStringAsFixed(2).replaceAll('.', ',')} ₺', 13, FontWeight.bold, Colors.green)
          .paint(canvas, Offset(50, currentY + 24));

      createText('TOPLAM GİDER: ${vm.toplamGider.toStringAsFixed(2).replaceAll('.', ',')} ₺', 13, FontWeight.bold, Colors.redAccent)
          .paint(canvas, Offset(320, currentY + 24));

      createText('NAKİT KALAN: ${vm.kalanNakit.toStringAsFixed(2).replaceAll('.', ',')} ₺', 14, FontWeight.bold, const Color(0xFF00796B))
          .paint(canvas, Offset(600, currentY + 24));

      currentY += 80;

      // 4. VARSA GÜN SONU NOTU / AÇIKLAMA ÇİZ
      if (vm.aciklama.isNotEmpty) {
        createText('NOTLAR / AÇIKLAMA:', 12, FontWeight.bold, Colors.black54)
            .paint(canvas, Offset(30, currentY));
        currentY += 18;

        final noteRect = Rect.fromLTWH(30, currentY, genislik - 60, 60);
        canvas.drawRRect(RRect.fromRectAndRadius(noteRect, const Radius.circular(8)), rowBgPaint);
        canvas.drawRRect(RRect.fromRectAndRadius(noteRect, const Radius.circular(8)), borderPaint);

        createText(vm.aciklama, 12, FontWeight.normal, Colors.black87)
            .paint(canvas, Offset(40, currentY + 12));
      }

      // 5. RESME DÖNÜŞTÜRÜP KAYDET
      final picture = recorder.endRecording();
      final img = await picture.toImage(genislik.toInt(), yukseklik.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) return;

      final desktopPath = p.join(Platform.environment['USERPROFILE'] ?? '', 'Desktop');
      final dir = Directory(desktopPath);
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final fileName = 'SakaryaSEV_Kasa_${vm.tarihFormatli}_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = p.join(desktopPath, fileName);

      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tüm kasa raporu eksiksiz fotoğraf olarak Masaüstüne kaydedildi: $fileName'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.teal,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel oluşturma hatası: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _ekstraGiderEkleDialog(BuildContext context, WidgetRef ref) {
    final baslikController = TextEditingController();
    final tutarController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Yeni Gider Kalemi Ekle'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: baslikController,
              decoration: const InputDecoration(
                labelText: 'Gider Adı / Başlığı',
                hintText: 'Örn: YANGIN TÜPÜ DOLUM',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tutarController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Tutar (₺)',
                hintText: '0.00',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00796B),
            ),
            onPressed: () {
              final baslik = baslikController.text.trim();
              final tutar =
                  double.tryParse(tutarController.text.replaceAll(',', '.')) ??
                  0.0;
              if (baslik.isNotEmpty) {
                ref.read(kasaProvider).ekstraGiderEkle(baslik, tutar);
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}

// (Diğer _KasaInputRow ve _OzetKarti bileşenleri aynı kalacak)
// ==========================================
// ALT BİLEŞENLER (WIDGET'LAR)
// ==========================================

// SATIR INPUT BİLEŞENİ (GELİR/GİDER GİRİŞ SATIRI)
class _KasaInputRow extends StatefulWidget {
  final String baslik;
  final double deger;
  final bool sabit;
  final ValueChanged<double> onChanged;
  final VoidCallback? onDelete;

  const _KasaInputRow({
    required this.baslik,
    required this.deger,
    required this.sabit,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<_KasaInputRow> createState() => _KasaInputRowState();
}

class _KasaInputRowState extends State<_KasaInputRow> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.deger == 0.0 ? '' : widget.deger.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant _KasaInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Dışarıdan değer değişirse controller'ı güncelle (örn: başka günden veri gelirse)
    final yeniText = widget.deger == 0.0 ? '' : widget.deger.toStringAsFixed(0);
    if (_controller.text != yeniText && _controller.text.isEmpty) {
      _controller.text = yeniText;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              widget.baslik,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.end,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
              ],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00796B),
              ),
              decoration: const InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: InputBorder.none,
                suffixText: ' ₺',
              ),
              onChanged: (val) {
                // Kullanıcı yazarken anlık olarak hesaplamalara yansısın ama odak kaybolmasın
                final parseVal =
                    double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                widget.onChanged(parseVal);
              },
            ),
          ),
          if (!widget.sabit && widget.onDelete != null)
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.redAccent,
              ),
              onPressed: widget.onDelete,
            ),
        ],
      ),
    );
  }
}

// ÖZET KARTI BİLEŞENİ (TOPLAM GELİR, GİDER, KASADA KALAN)
class _OzetKarti extends StatelessWidget {
  final String baslik;
  final String tutar;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _OzetKarti({
    required this.baslik,
    required this.tutar,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).cardColor
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tutar,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// GÜN SONU NOTLARI İÇİN ODAK KAYBETMEYEN METİN KUTUSU
class _KasaAciklamaInput extends StatefulWidget {
  final String aciklama;
  final ValueChanged<String> onChanged;

  const _KasaAciklamaInput({required this.aciklama, required this.onChanged});

  @override
  State<_KasaAciklamaInput> createState() => _KasaAciklamaInputState();
}

class _KasaAciklamaInputState extends State<_KasaAciklamaInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.aciklama);
  }

  @override
  void didUpdateWidget(covariant _KasaAciklamaInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Yalnızca tarih değiştirilip veritabanından tamamen yeni bir veri yüklendiğinde controller'ı güncelle
    if (oldWidget.aciklama != widget.aciklama &&
        _controller.text != widget.aciklama) {
      _controller.text = widget.aciklama;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: _controller,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText: 'Örn: ÇARŞI SERVİS DÜN BUGÜN KALAN MAZOT 2000 DÜŞÜLDÜ...',
        filled: true,
        fillColor: isDarkMode ? Colors.black26 : Colors.grey[50],
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}


import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../models/KasaViewModel/KasaViewModel.dart';

class KasaPage extends ConsumerWidget {
  KasaPage({super.key});

  final GlobalKey _printKey = GlobalKey();

  static const Color _anaRenk = Color(0xFF00796B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(kasaProvider);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    String para(double val) =>
        '${val.toStringAsFixed(2).replaceAll('.', ',')} ₺';

    return RepaintBoundary(
      key: _printKey,
      child: Container(
        color: theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, pageConstraints) {
            final darEkran = pageConstraints.maxWidth < 1000;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ustBaslik(context, ref, vm, darEkran),

                const SizedBox(height: 20),

                // ÖZET KARTLARI
                LayoutBuilder(
                  builder: (context, constraints) {
                    final darOzet = constraints.maxWidth < 750;

                    if (darOzet) {
                      return Column(
                        children: [
                          _OzetKarti(
                            baslik: 'Toplam Gelir',
                            tutar: para(vm.toplamGelir),
                            icon: Icons.arrow_downward_rounded,
                            color: Colors.green,
                            bgColor: Colors.green.withOpacity(0.1),
                          ),
                          const SizedBox(height: 10),
                          _OzetKarti(
                            baslik: 'Toplam Gider',
                            tutar: para(vm.toplamGider),
                            icon: Icons.arrow_upward_rounded,
                            color: Colors.redAccent,
                            bgColor: Colors.redAccent.withOpacity(0.1),
                          ),
                          const SizedBox(height: 10),
                          _OzetKarti(
                            baslik: 'Kasada Kalan Nakit',
                            tutar: para(vm.kalanNakit),
                            icon: Icons.account_balance_wallet_rounded,
                            color: vm.kalanNakit >= 0
                                ? _anaRenk
                                : Colors.orange,
                            bgColor: _anaRenk.withOpacity(0.12),
                          ),
                        ],
                      );
                    }

                    return Row(
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OzetKarti(
                            baslik: 'Toplam Gider',
                            tutar: para(vm.toplamGider),
                            icon: Icons.arrow_upward_rounded,
                            color: Colors.redAccent,
                            bgColor: Colors.redAccent.withOpacity(0.1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OzetKarti(
                            baslik: 'Kasada Kalan Nakit',
                            tutar: para(vm.kalanNakit),
                            icon: Icons.account_balance_wallet_rounded,
                            color: vm.kalanNakit >= 0
                                ? _anaRenk
                                : Colors.orange,
                            bgColor: _anaRenk.withOpacity(0.12),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 20),

                // ANA İÇERİK
                Expanded(
                  child: vm.yukleniyor
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: _anaRenk,
                    ),
                  )
                      : darEkran
                      ? SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 390,
                          child: _giderlerPanel(
                            context,
                            ref,
                            vm,
                            isDarkMode,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _gelirlerPanel(
                          context,
                          ref,
                          vm,
                          isDarkMode,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 240,
                          child: _notlarPanel(
                            context,
                            ref,
                            vm,
                            isDarkMode,
                          ),
                        ),
                      ],
                    ),
                  )
                      : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _giderlerPanel(
                          context,
                          ref,
                          vm,
                          isDarkMode,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            _gelirlerPanel(
                              context,
                              ref,
                              vm,
                              isDarkMode,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _notlarPanel(
                                context,
                                ref,
                                vm,
                                isDarkMode,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // BAŞLIK VE İŞLEM BUTONLARI
  Widget _ustBaslik(
      BuildContext context,
      WidgetRef ref,
      KasaViewModel vm,
      bool darEkran,
      ) {
    final theme = Theme.of(context);

    final baslik = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );

    final butonlar = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
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
              horizontal: 12,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
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
              horizontal: 12,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _fotografKaydet(context, vm),
          icon: const Icon(
            Icons.camera_alt_rounded,
            size: 18,
            color: Colors.teal,
          ),
          label: const Text('Görsel Kaydet'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: vm.yukleniyor
              ? null
              : () async {
            final success =
            await ref.read(kasaProvider).kaydet();

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Gün sonu kasa kaydı başarıyla kaydedildi.'
                      : 'Kasa kaydedilirken bir hata oluştu.',
                ),
                behavior: SnackBarBehavior.floating,
                backgroundColor:
                success ? Colors.teal : Colors.redAccent,
              ),
            );
          },
          icon: const Icon(Icons.save_rounded, size: 20),
          label: const Text('Kasayı Kaydet'),
          style: FilledButton.styleFrom(
            backgroundColor: _anaRenk,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );

    if (darEkran) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          baslik,
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: butonlar,
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1200) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              baslik,
              const SizedBox(height: 14),
              butonlar,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: baslik),
            const SizedBox(width: 16),
            Flexible(child: butonlar),
          ],
        );
      },
    );
  }

  // ORTAK KART TASARIMI
  Widget _panelCard({
    required BuildContext context,
    required bool isDarkMode,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDarkMode ? theme.cardColor : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.15),
        ),
      ),
      child: child,
    );
  }

  // GİDERLER PANELİ
  Widget _giderlerPanel(
      BuildContext context,
      WidgetRef ref,
      KasaViewModel vm,
      bool isDarkMode,
      ) {
    return _panelCard(
      context: context,
      isDarkMode: isDarkMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'GİDERLER',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Flexible(
                  child: TextButton.icon(
                    onPressed: () =>
                        _ekstraGiderEkleDialog(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Ekstra Gider Ekle'),
                  ),
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
                      ref.read(kasaProvider).giderSil(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // GELİRLER PANELİ
  Widget _gelirlerPanel(
      BuildContext context,
      WidgetRef ref,
      KasaViewModel vm,
      bool isDarkMode,
      ) {
    return _panelCard(
      context: context,
      isDarkMode: isDarkMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
              physics: const NeverScrollableScrollPhysics(),
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
                        .gelirTutarGuncelle(index, val);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // GÜN SONU NOTLARI PANELİ
  Widget _notlarPanel(
      BuildContext context,
      WidgetRef ref,
      KasaViewModel vm,
      bool isDarkMode,
      ) {
    return _panelCard(
      context: context,
      isDarkMode: isDarkMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notes_rounded, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GÜN SONU NOTLARI / AÇIKLAMA',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _KasaAciklamaInput(
                aciklama: vm.aciklama,
                onChanged: (val) {
                  ref.read(kasaProvider).aciklamaGuncelle(val);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CSV OLARAK MASAÜSTÜNE KAYDETME
  Future<void> _excelAktar(
      BuildContext context,
      KasaViewModel vm,
      ) async {
    try {
      final kullaniciDizini = Platform.environment['USERPROFILE'];

      if (kullaniciDizini == null || kullaniciDizini.isEmpty) {
        throw Exception('Kullanıcı dizini bulunamadı.');
      }

      final desktopPath = p.join(kullaniciDizini, 'Desktop');
      final dir = Directory(desktopPath);

      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final fileName = 'SakaryaSEV_Kasa_${vm.tarihFormatli}.csv';
      final filePath = p.join(desktopPath, fileName);

      final buffer = StringBuffer();
      buffer.writeln('SAKARYA SEV - GÜN SONU KASA RAPORU');
      buffer.writeln('Tarih:;${vm.tarihOkunabilir}');
      buffer.writeln();
      buffer.writeln('GELİRLER');
      buffer.writeln('Kalem;Tutar');

      for (final g in vm.gelirler) {
        buffer.writeln('${g.baslik};${g.tutar.toStringAsFixed(2)}');
      }

      buffer.writeln();
      buffer.writeln('GİDERLER');
      buffer.writeln('Kalem;Tutar');

      for (final g in vm.giderler) {
        buffer.writeln('${g.baslik};${g.tutar.toStringAsFixed(2)}');
      }

      buffer.writeln();
      buffer.writeln(
        'TOPLAM GELİR;${vm.toplamGelir.toStringAsFixed(2)}',
      );
      buffer.writeln(
        'TOPLAM GİDER;${vm.toplamGider.toStringAsFixed(2)}',
      );
      buffer.writeln(
        'NAKİT KALAN;${vm.kalanNakit.toStringAsFixed(2)}',
      );

      if (vm.aciklama.isNotEmpty) {
        buffer.writeln();
        buffer.writeln(
          'AÇIKLAMA / NOTLAR:;${vm.aciklama.replaceAll('\n', ' ')}',
        );
      }

      final file = File(filePath);

      await file.writeAsBytes([
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(buffer.toString()),
      ]);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CSV dosyası Masaüstüne kaydedildi: $fileName',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel dışa aktarma hatası: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // TAM BOY PNG RAPORU OLUŞTURMA
  Future<void> _fotografKaydet(
      BuildContext context,
      KasaViewModel vm,
      ) async {
    ui.Picture? picture;
    ui.Image? image;

    try {
      final satirSayisi = vm.giderler.length > vm.gelirler.length
          ? vm.giderler.length
          : vm.gelirler.length;

      const double genislik = 900;
      final double yukseklik =
          350 +
              (satirSayisi * 38) +
              (vm.aciklama.isNotEmpty ? 120 : 0);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, genislik, yukseklik),
      );

      canvas.drawRect(
        Rect.fromLTWH(0, 0, genislik, yukseklik),
        Paint()..color = const Color(0xFFF8F9FA),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(20, 20, genislik - 40, 70),
          const Radius.circular(12),
        ),
        Paint()..color = _anaRenk,
      );

      TextPainter createText(
          String text,
          double fontSize,
          FontWeight weight,
          Color color, {
            double? maxWidth,
            int? maxLines,
          }) {
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: weight,
              color: color,
              fontFamily: 'sans-serif',
            ),
          ),
          textDirection: TextDirection.ltr,
          maxLines: maxLines,
          ellipsis: maxLines == null ? null : '…',
        );

        tp.layout(maxWidth: maxWidth ?? genislik);
        return tp;
      }

      createText(
        'SAKARYA SEV - GÜN SONU KASA RAPORU',
        18,
        FontWeight.bold,
        Colors.white,
        maxWidth: genislik - 80,
        maxLines: 1,
      ).paint(canvas, const Offset(40, 32));

      createText(
        vm.tarihOkunabilir,
        13,
        FontWeight.w500,
        Colors.white70,
        maxLines: 1,
      ).paint(canvas, const Offset(40, 56));

      double currentY = 110;

      createText(
        'GİDERLER',
        15,
        FontWeight.bold,
        Colors.redAccent,
      ).paint(canvas, Offset(30, currentY));

      createText(
        'GELİRLER',
        15,
        FontWeight.bold,
        Colors.green,
      ).paint(canvas, Offset(genislik / 2 + 10, currentY));

      currentY += 28;

      final rowBgPaint = Paint()..color = Colors.white;

      final borderPaint = Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < satirSayisi; i++) {
        if (i < vm.giderler.length) {
          final g = vm.giderler[i];
          final rect = Rect.fromLTWH(
            30,
            currentY,
            (genislik / 2) - 40,
            32,
          );

          final rrect = RRect.fromRectAndRadius(
            rect,
            const Radius.circular(6),
          );

          canvas.drawRRect(rrect, rowBgPaint);
          canvas.drawRRect(rrect, borderPaint);

          createText(
            g.baslik,
            12,
            FontWeight.w600,
            Colors.black87,
            maxWidth: 250,
            maxLines: 1,
          ).paint(canvas, Offset(40, currentY + 8));

          final tutar = createText(
            '${g.tutar.toStringAsFixed(2).replaceAll('.', ',')} ₺',
            12,
            FontWeight.bold,
            Colors.redAccent,
            maxLines: 1,
          );

          tutar.paint(
            canvas,
            Offset((genislik / 2) - 15 - tutar.width, currentY + 8),
          );
        }

        if (i < vm.gelirler.length) {
          final g = vm.gelirler[i];
          final rect = Rect.fromLTWH(
            genislik / 2 + 10,
            currentY,
            (genislik / 2) - 40,
            32,
          );

          final rrect = RRect.fromRectAndRadius(
            rect,
            const Radius.circular(6),
          );

          canvas.drawRRect(rrect, rowBgPaint);
          canvas.drawRRect(rrect, borderPaint);

          createText(
            g.baslik,
            12,
            FontWeight.w600,
            Colors.black87,
            maxWidth: 250,
            maxLines: 1,
          ).paint(canvas, Offset(genislik / 2 + 20, currentY + 8));

          final tutar = createText(
            '${g.tutar.toStringAsFixed(2).replaceAll('.', ',')} ₺',
            12,
            FontWeight.bold,
            Colors.green,
            maxLines: 1,
          );

          tutar.paint(
            canvas,
            Offset(genislik - 35 - tutar.width, currentY + 8),
          );
        }

        currentY += 36;
      }

      currentY += 15;

      final ozetRect = Rect.fromLTWH(
        30,
        currentY,
        genislik - 60,
        65,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          ozetRect,
          const Radius.circular(10),
        ),
        Paint()..color = const Color(0xFFE0F2F1),
      );

      createText(
        'TOPLAM GELİR: ${vm.toplamGelir.toStringAsFixed(2).replaceAll('.', ',')} ₺',
        13,
        FontWeight.bold,
        Colors.green,
        maxWidth: 250,
        maxLines: 1,
      ).paint(canvas, Offset(50, currentY + 24));

      createText(
        'TOPLAM GİDER: ${vm.toplamGider.toStringAsFixed(2).replaceAll('.', ',')} ₺',
        13,
        FontWeight.bold,
        Colors.redAccent,
        maxWidth: 250,
        maxLines: 1,
      ).paint(canvas, Offset(320, currentY + 24));

      createText(
        'NAKİT KALAN: ${vm.kalanNakit.toStringAsFixed(2).replaceAll('.', ',')} ₺',
        14,
        FontWeight.bold,
        _anaRenk,
        maxWidth: 250,
        maxLines: 1,
      ).paint(canvas, Offset(600, currentY + 24));

      currentY += 80;

      if (vm.aciklama.isNotEmpty) {
        createText(
          'NOTLAR / AÇIKLAMA:',
          12,
          FontWeight.bold,
          Colors.black54,
        ).paint(canvas, Offset(30, currentY));

        currentY += 18;

        final noteRect = Rect.fromLTWH(
          30,
          currentY,
          genislik - 60,
          60,
        );

        final noteRRect = RRect.fromRectAndRadius(
          noteRect,
          const Radius.circular(8),
        );

        canvas.drawRRect(noteRRect, rowBgPaint);
        canvas.drawRRect(noteRRect, borderPaint);

        createText(
          vm.aciklama,
          12,
          FontWeight.normal,
          Colors.black87,
          maxWidth: genislik - 100,
          maxLines: 3,
        ).paint(canvas, Offset(40, currentY + 12));
      }

      picture = recorder.endRecording();

      image = await picture.toImage(
        genislik.toInt(),
        yukseklik.toInt(),
      );

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      final pngBytes = byteData?.buffer.asUint8List();

      if (pngBytes == null) {
        throw Exception('PNG verisi oluşturulamadı.');
      }

      final kullaniciDizini = Platform.environment['USERPROFILE'];

      if (kullaniciDizini == null || kullaniciDizini.isEmpty) {
        throw Exception('Kullanıcı dizini bulunamadı.');
      }

      final desktopPath = p.join(kullaniciDizini, 'Desktop');
      final dir = Directory(desktopPath);

      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final fileName =
          'SakaryaSEV_Kasa_${vm.tarihFormatli}_${DateTime.now().millisecondsSinceEpoch}.png';

      final filePath = p.join(desktopPath, fileName);

      await File(filePath).writeAsBytes(pngBytes);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kasa raporu Masaüstüne kaydedildi: $fileName',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.teal,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Görsel oluşturma hatası: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      image?.dispose();
      picture?.dispose();
    }
  }

  // EKSTRA GİDER EKLEME PENCERESİ
  void _ekstraGiderEkleDialog(
      BuildContext context,
      WidgetRef ref,
      ) {
    final baslikController = TextEditingController();
    final tutarController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Yeni Gider Kalemi Ekle'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: SingleChildScrollView(
          child: Column(
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
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[\.,]?\d*'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Tutar (₺)',
                  hintText: '0,00',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _anaRenk,
            ),
            onPressed: () {
              final baslik = baslikController.text.trim();
              final tutar = double.tryParse(
                tutarController.text.replaceAll(',', '.'),
              ) ??
                  0.0;

              if (baslik.isNotEmpty) {
                ref.read(kasaProvider).ekstraGiderEkle(
                  baslik,
                  tutar,
                );
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    ).whenComplete(() {
      baslikController.dispose();
      tutarController.dispose();
    });
  }
}

// GELİR / GİDER SATIRI
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
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.deger == 0.0
          ? ''
          : widget.deger.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(covariant _KasaInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    final yeniText = widget.deger == 0.0
        ? ''
        : widget.deger.toStringAsFixed(0);

    if (oldWidget.deger != widget.deger &&
        _controller.text != yeniText &&
        !_controller.selection.isValid) {
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: dark ? Colors.grey[900] : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              widget.baslik,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.end,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*[\.,]?\d*'),
                ),
              ],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _KasaPageColor.anaRenk,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 8,
                ),
                border: InputBorder.none,
                suffixText: ' ₺',
              ),
              onChanged: (val) {
                final parsed =
                    double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                widget.onChanged(parsed);
              },
            ),
          ),
          if (!widget.sabit && widget.onDelete != null)
            SizedBox(
              width: 34,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Gideri sil',
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.redAccent,
                ),
                onPressed: widget.onDelete,
              ),
            ),
        ],
      ),
    );
  }
}

// ÖZET KARTI
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
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.brightness == Brightness.dark
          ? theme.cardColor
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    baslik,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      tutar,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
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
}

// AÇIKLAMA KUTUSU
class _KasaAciklamaInput extends StatefulWidget {
  final String aciklama;
  final ValueChanged<String> onChanged;

  const _KasaAciklamaInput({
    required this.aciklama,
    required this.onChanged,
  });

  @override
  State<_KasaAciklamaInput> createState() =>
      _KasaAciklamaInputState();
}

class _KasaAciklamaInputState extends State<_KasaAciklamaInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.aciklama);
  }

  @override
  void didUpdateWidget(covariant _KasaAciklamaInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.aciklama != widget.aciklama &&
        _controller.text != widget.aciklama) {
      _controller.value = TextEditingValue(
        text: widget.aciklama,
        selection: TextSelection.collapsed(
          offset: widget.aciklama.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: _controller,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        hintText:
        'Örn: ÇARŞI SERVİS DÜN BUGÜN KALAN MAZOT 2000 DÜŞÜLDÜ...',
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

// Yardımcı renk sabiti
class _KasaPageColor {
  static const Color anaRenk = Color(0xFF00796B);
}

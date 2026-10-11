import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../viewModel/CashRegisterViewModel/CashRegisterViewModel.dart';

class CashRegisterPage extends ConsumerStatefulWidget {
  const CashRegisterPage({super.key});

  @override
  ConsumerState<CashRegisterPage> createState() => _CashRegisterPageState();
}

class _CashRegisterPageState extends ConsumerState<CashRegisterPage> {
  final GlobalKey _repaintKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(cashRegisterViewModelProvider);
    final fmt = viewModel.currencyFormat;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sol köşe için güncel tarih (Örn: 11.10.2026)
    final String currentDate = DateFormat('dd.MM.yyyy').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PNG Olarak Yakalanacak Rapor Alanı
          RepaintBoundary(
            key: _repaintKey,
            child: Container(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ÜST KISIM: Sol Köşe Tarih, Orta Logo ve Başlık
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

                      // Orta Kısım: Logo ve Firma Adı
                      Column(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 60,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_bus, size: 50, color: Colors.blue),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "SAKARYASEV TURİZM",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: isDark ? Colors.cyanAccent : Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "GÜN SONU KASA RAPORU",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      // Simetri için boş alan (Sağ taraf)
                      const SizedBox(width: 80),
                    ],
                  ),
                  const Divider(height: 36, thickness: 1.5),

                  // ÖZET KARTLARI
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard("TOPLAM GELİR", fmt.format(viewModel.totalIncome), Colors.green, isDark)),
                      const SizedBox(width: 14),
                      Expanded(child: _buildSummaryCard("TOPLAM GİDER", fmt.format(viewModel.totalExpense), Colors.orange, isDark)),
                      const SizedBox(width: 14),
                      Expanded(child: _buildSummaryCard("NET KALAN KASA", fmt.format(viewModel.netCash), Colors.cyan, isDark)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ŞUBE KASALARI
                  Text(
                    "ŞUBE KASALARI",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.purpleAccent : Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        children: [
                          _buildInputRow("Terminal Kasa", viewModel.terminalKasa, (v) => ref.read(cashRegisterViewModelProvider).updateKasa('terminal', v), isDark),
                          const Divider(height: 20),
                          _buildInputRow("Çarşı Kasa", viewModel.carsiKasa, (v) => ref.read(cashRegisterViewModelProvider).updateKasa('carsi', v), isDark),
                          const Divider(height: 20),
                          _buildInputRow("Karasu Kasa", viewModel.karasuKasa, (v) => ref.read(cashRegisterViewModelProvider).updateKasa('karasu', v), isDark),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // GİDERLER
                  Text(
                    "GİDERLER",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.purpleAccent : Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: viewModel.expenses.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, index) {
                          final item = viewModel.expenses[index];
                          return Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: item.isFixed
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : (isDark ? Colors.amberAccent : Colors.blue.shade800),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  initialValue: item.amount.toString(),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                    suffixText: "₺",
                                    suffixStyle: TextStyle(color: isDark ? Colors.cyanAccent : Colors.blueAccent),
                                  ),
                                  onChanged: (val) {
                                    ref.read(cashRegisterViewModelProvider).updateExpenseAmount(index, double.tryParse(val) ?? 0.0);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (!item.isFixed)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => ref.read(cashRegisterViewModelProvider).removeExpense(index),
                                )
                              else
                                const SizedBox(width: 48),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // EKSTRA KALEM EKLEME
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.deepPurpleAccent : Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Ekstra Gider Kalemi Ekle", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: () => _showAddDialog(context, ref),
            ),
          ),
          const SizedBox(height: 32),

          // PNG KAYDET BUTONU
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 24),
              label: const Text("Kaydet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final filePath = await ref.read(cashRegisterViewModelProvider).saveReportAsPng(_repaintKey);
                if (context.mounted) {
                  _showResultDialog(context, filePath);
                }
              },
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String val, Color accentCol, bool isDark) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF2A2A3D) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: accentCol, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            Text(val, textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(String label, double val, Function(double) onChanged, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        SizedBox(
          width: 170,
          child: TextFormField(
            initialValue: val.toString(),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              suffixText: "₺",
              suffixStyle: TextStyle(color: isDark ? Colors.cyanAccent : Colors.blueAccent),
            ),
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0.0),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ekstra Gider Kalemi Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Kalem Adı")),
            const SizedBox(height: 12),
            TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Tutar (₺)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                ref.read(cashRegisterViewModelProvider).addExtraExpense(nameCtrl.text, double.tryParse(amountCtrl.text) ?? 0.0);
                Navigator.pop(context);
              }
            },
            child: const Text("Ekle"),
          ),
        ],
      ),
    );
  }

  void _showResultDialog(BuildContext context, String? path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(path != null ? "İşlem Başarılı" : "Hata"),
        content: Text(
          path != null
              ? "Gün sonu kasa raporu başarıyla kaydedildi:\n\n$path"
              : "Rapor görseli kaydedilirken bir sorun oluştu.",
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Tamam")),
        ],
      ),
    );
  }
}
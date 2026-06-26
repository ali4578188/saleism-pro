import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/purchase_provider.dart';
import 'purchase_form.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseProvider>().loadPurchases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(
        title: const Text('Purchases'),
        backgroundColor: AppColors.bgBlack,
      ),
      body: Consumer<PurchaseProvider>(
        builder: (context, prov, _) {
          if (prov.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
          if (prov.purchases.isEmpty) return const Center(child: Text('No purchases yet', style: TextStyle(color: AppColors.textSecondary)));
          return RefreshIndicator(
            color: AppColors.primaryOrange,
            backgroundColor: AppColors.bgCard,
            onRefresh: () => prov.loadPurchases(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prov.purchases.length,
              itemBuilder: (context, i) => _PurchaseTile(
                purchase: prov.purchases[i],
                onTap: () => _viewDetail(context, prov.purchases[i]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchaseForm()))
            .then((_) => context.read<PurchaseProvider>().loadPurchases()),
        icon: const Icon(Icons.add),
        label: const Text('New Purchase'),
        backgroundColor: AppColors.primaryOrange,
      ),
    );
  }

  void _viewDetail(BuildContext context, Map<String, dynamic> purchase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _PurchaseDetailSheet(purchase: purchase),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  final Map<String, dynamic> purchase;
  final VoidCallback onTap;

  const _PurchaseTile({required this.purchase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = purchase['payment_status'] as String? ?? 'unpaid';
    final statusColor = status == 'paid' ? AppColors.profitGreen : status == 'partial' ? AppColors.warning : AppColors.lossRed;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(purchase['invoice_number'] ?? '', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.business, color: AppColors.textMuted, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(purchase['company_name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
                Text(DateUtils2.toDisplay(purchase['date']), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Total:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(width: 6),
                Text(CurrencyUtils.format((purchase['total_amount'] as num).toDouble()),
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                const Text('Paid:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(width: 6),
                Text(CurrencyUtils.format((purchase['paid_amount'] as num).toDouble()),
                  style: const TextStyle(color: AppColors.profitGreen, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseDetailSheet extends StatefulWidget {
  final Map<String, dynamic> purchase;
  const _PurchaseDetailSheet({required this.purchase});

  @override
  State<_PurchaseDetailSheet> createState() => _PurchaseDetailSheetState();
}

class _PurchaseDetailSheetState extends State<_PurchaseDetailSheet> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await context.read<PurchaseProvider>().getPurchaseItems(widget.purchase['id']);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.purchase;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(p['invoice_number'] ?? '', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w800, fontSize: 18)),
                  const Spacer(),
                  Text(DateUtils2.toDisplay(p['date']), style: const TextStyle(color: AppColors.textSecondary)),
                ]),
                Text(p['company_name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const Divider(color: AppColors.divider, height: 24),
              ],
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primaryOrange)))
          else
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ..._items.map((item) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['product_name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text('${item['cartons']}C × ${item['boxes']}B × ${item['pieces']}P', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const Spacer(),
                          Text(CurrencyUtils.format((item['total_amount'] as num).toDouble()),
                            style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700)),
                        ]),
                      ],
                    ),
                  )),
                  const Divider(color: AppColors.divider),
                  Row(children: [
                    const Text('Total Amount:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const Spacer(),
                    Text(CurrencyUtils.format((p['total_amount'] as num).toDouble()),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Text('Paid:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const Spacer(),
                    Text(CurrencyUtils.format((p['paid_amount'] as num).toDouble()),
                      style: const TextStyle(color: AppColors.profitGreen, fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Text('Balance:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const Spacer(),
                    Text(CurrencyUtils.format(((p['total_amount'] as num) - (p['paid_amount'] as num)).toDouble()),
                      style: const TextStyle(color: AppColors.lossRed, fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
                  const SizedBox(height: 32),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

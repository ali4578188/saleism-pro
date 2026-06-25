import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/sale_provider.dart';
import 'sale_form.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(title: const Text('Sales'), backgroundColor: AppColors.bgBlack),
      body: Consumer<SaleProvider>(
        builder: (context, prov, _) {
          if (prov.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
          if (prov.sales.isEmpty) return const Center(child: Text('No sales yet', style: TextStyle(color: AppColors.textSecondary)));
          return RefreshIndicator(
            color: AppColors.primaryOrange,
            backgroundColor: AppColors.bgCard,
            onRefresh: () => prov.loadSales(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prov.sales.length,
              itemBuilder: (context, i) => _SaleTile(
                sale: prov.sales[i],
                onTap: () => _viewDetail(context, prov.sales[i]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SaleForm()))
            .then((_) => context.read<SaleProvider>().loadSales()),
        icon: const Icon(Icons.add),
        label: const Text('New Sale'),
        backgroundColor: AppColors.primaryOrange,
      ),
    );
  }

  void _viewDetail(BuildContext context, Map<String, dynamic> sale) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SaleDetailSheet(sale: sale),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Map<String, dynamic> sale;
  final VoidCallback onTap;
  const _SaleTile({required this.sale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final method = sale['payment_method'] as String? ?? 'cash';
    final methodColor = method == 'cash' ? AppColors.profitGreen : method == 'credit' ? AppColors.creditYellow : AppColors.info;

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
                  decoration: BoxDecoration(color: AppColors.primaryOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(sale['invoice_number'] ?? '', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: methodColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(method.toUpperCase(), style: TextStyle(color: methodColor, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, color: AppColors.textMuted, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(sale['customer_name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
                Text(DateUtils2.toDisplay(sale['date']), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Amount:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(width: 6),
                Text(CurrencyUtils.format((sale['final_amount'] as num).toDouble()),
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                const Spacer(),
                if ((sale['discount'] as num).toDouble() > 0)
                  Text('Disc: ${CurrencyUtils.format((sale['discount'] as num).toDouble())}',
                    style: const TextStyle(color: AppColors.warning, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleDetailSheet extends StatefulWidget {
  final Map<String, dynamic> sale;
  const _SaleDetailSheet({required this.sale});

  @override
  State<_SaleDetailSheet> createState() => _SaleDetailSheetState();
}

class _SaleDetailSheetState extends State<_SaleDetailSheet> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await context.read<SaleProvider>().getSaleItems(widget.sale['id']);
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sale;
    final profit = _items.fold<double>(0, (sum, i) => sum + (i['profit'] as num).toDouble());
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scroll) => Column(
        children: [
          Container(margin: const EdgeInsets.symmetric(vertical: 10), width: 40, height: 4, decoration: BoxDecoration(color: AppColors.textMuted, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(s['invoice_number'] ?? '', style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w800, fontSize: 18)),
                  const Spacer(),
                  Text(DateUtils2.toDisplay(s['date']), style: const TextStyle(color: AppColors.textSecondary)),
                ]),
                Text(s['customer_name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                if (s['company_name'] != null) Text(s['company_name'], style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
                    decoration: BoxDecoration(color: AppColors.bgInput, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['product_name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text('${item['cartons']}C × ${item['boxes']}B × ${item['pieces']}P @ ${CurrencyUtils.format((item['sale_rate'] as num).toDouble())}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const Spacer(),
                          Text(CurrencyUtils.format((item['total_amount'] as num).toDouble()),
                            style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700)),
                        ]),
                        Text('Profit: ${CurrencyUtils.format((item['profit'] as num).toDouble())}',
                          style: const TextStyle(color: AppColors.profitGreen, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
                  const Divider(color: AppColors.divider),
                  Row(children: [const Text('Total:', style: TextStyle(color: AppColors.textSecondary)), const Spacer(),
                    Text(CurrencyUtils.format((s['total_amount'] as num).toDouble()), style: const TextStyle(color: AppColors.textSecondary))]),
                  if ((s['discount'] as num).toDouble() > 0)
                    Row(children: [const Text('Discount:', style: TextStyle(color: AppColors.warning)), const Spacer(),
                      Text('- ${CurrencyUtils.format((s['discount'] as num).toDouble())}', style: const TextStyle(color: AppColors.warning))]),
                  const SizedBox(height: 4),
                  Row(children: [const Text('Final Amount:', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)), const Spacer(),
                    Text(CurrencyUtils.format((s['final_amount'] as num).toDouble()),
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16))]),
                  if (!_loading && _items.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [const Text('Profit:', style: TextStyle(color: AppColors.profitGreen)), const Spacer(),
                      Text(CurrencyUtils.format(profit), style: const TextStyle(color: AppColors.profitGreen, fontWeight: FontWeight.w700))]),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/auth_provider.dart';
import '../../core/database/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _period = 'daily';
  List<Map<String, dynamic>> _profitData = [];
  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _stockData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final db = DatabaseHelper.instance;
    final now = DateTime.now();
    final dateFrom = _period == 'daily'
        ? DateUtils2.weekStart()
        : _period == 'monthly'
            ? DateUtils2.monthStart()
            : DateUtils2.yearStart();

    _profitData = await db.getProfitReport(dateFrom: dateFrom, period: _period);
    _salesData = await db.getSales(dateFrom: dateFrom);
    _stockData = await db.getLowStockProducts();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppColors.bgBlack,
        actions: [
          PopupMenuButton<String>(
            color: AppColors.bgCard,
            onSelected: (v) => setState(() { _period = v; _load(); }),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'daily', child: Text('Daily', style: TextStyle(color: AppColors.textPrimary))),
              const PopupMenuItem(value: 'monthly', child: Text('Monthly', style: TextStyle(color: AppColors.textPrimary))),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Text(_period == 'daily' ? 'Daily' : 'Monthly', style: const TextStyle(color: AppColors.textPrimary)),
                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 18),
              ]),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryOrange,
          tabs: [
            const Tab(text: 'Sales'),
            Tab(text: isAdmin ? 'Profit' : 'Profit', icon: isAdmin ? null : const Icon(Icons.lock, size: 12)),
            const Tab(text: 'Stock'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : TabBarView(
              controller: _tabs,
              children: [
                _SalesReport(sales: _salesData),
                isAdmin ? _ProfitReport(data: _profitData, period: _period) : _LockedReport(),
                _StockReport(products: _stockData),
              ],
            ),
    );
  }
}

class _SalesReport extends StatelessWidget {
  final List<Map<String, dynamic>> sales;
  const _SalesReport({required this.sales});

  @override
  Widget build(BuildContext context) {
    final totalAmount = sales.fold<double>(0, (s, e) => s + (e['final_amount'] as num).toDouble());
    final cashSales = sales.where((s) => s['payment_method'] == 'cash').fold<double>(0, (s, e) => s + (e['final_amount'] as num).toDouble());
    final creditSales = sales.where((s) => s['payment_method'] == 'credit').fold<double>(0, (s, e) => s + (e['final_amount'] as num).toDouble());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: _ReportCard(label: 'Total Sales', value: CurrencyUtils.format(totalAmount), color: AppColors.primaryOrange, icon: Icons.point_of_sale)),
          const SizedBox(width: 12),
          Expanded(child: _ReportCard(label: 'Invoices', value: '${sales.length}', color: AppColors.info, icon: Icons.receipt)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _ReportCard(label: 'Cash Sales', value: CurrencyUtils.format(cashSales), color: AppColors.profitGreen, icon: Icons.payments)),
          const SizedBox(width: 12),
          Expanded(child: _ReportCard(label: 'Credit Sales', value: CurrencyUtils.format(creditSales), color: AppColors.creditYellow, icon: Icons.credit_card)),
        ]),
        const SizedBox(height: 20),
        if (sales.isNotEmpty) ...[
          const Text('Recent Sales', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          ...sales.take(20).map((s) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['customer_name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                    Text(s['invoice_number'] ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                )),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(CurrencyUtils.format((s['final_amount'] as num).toDouble()),
                      style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700)),
                    Text(DateUtils2.toDisplay(s['date']), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          )),
        ] else
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No sales data for this period', style: TextStyle(color: AppColors.textSecondary)))),
      ],
    );
  }
}

class _ProfitReport extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String period;
  const _ProfitReport({required this.data, required this.period});

  @override
  Widget build(BuildContext context) {
    final totalProfit = data.fold<double>(0, (s, e) => s + (e['total_profit'] as num? ?? 0).toDouble());
    final totalSales = data.fold<double>(0, (s, e) => s + (e['total_sales'] as num? ?? 0).toDouble());
    final avgMargin = totalSales > 0 ? (totalProfit / totalSales) * 100 : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: _ReportCard(label: 'Total Profit', value: CurrencyUtils.format(totalProfit), color: AppColors.profitGreen, icon: Icons.trending_up)),
          const SizedBox(width: 12),
          Expanded(child: _ReportCard(label: 'Avg Margin', value: '${avgMargin.toStringAsFixed(1)}%', color: AppColors.primaryOrange, icon: Icons.percent)),
        ]),
        const SizedBox(height: 16),
        if (data.isNotEmpty) ...[
          const Text('Profit Trend', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: data.map((e) => (e['total_profit'] as num? ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                barGroups: data.take(7).toList().asMap().entries.map((entry) {
                  final profit = (entry.value['total_profit'] as num? ?? 0).toDouble();
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: profit,
                        color: AppColors.primaryOrange,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryOrange, AppColors.orangeDark],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ],
                  );
                }).toList(),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= data.take(7).length) return const SizedBox.shrink();
                        final entry = data.take(7).toList()[idx];
                        final period2 = entry['period'] as String? ?? '';
                        final label = period2.length > 5 ? period2.substring(period2.length - 5) : period2;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Period Breakdown', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          ...data.take(14).map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
            child: Row(
              children: [
                Expanded(child: Text(entry['period'] as String? ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600))),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(CurrencyUtils.format((entry['total_profit'] as num? ?? 0).toDouble()),
                      style: const TextStyle(color: AppColors.profitGreen, fontWeight: FontWeight.w700)),
                    Text('${(entry['margin_pct'] as num? ?? 0).toStringAsFixed(1)}% margin',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ],
    );
  }
}

class _StockReport extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _StockReport({required this.products});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (products.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(48),
            child: Column(children: [
              Icon(Icons.check_circle, color: AppColors.profitGreen, size: 64),
              SizedBox(height: 16),
              Text('All products are well stocked!', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
            ]),
          ))
        else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.lossRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lossRed.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber, color: AppColors.lossRed, size: 24),
              const SizedBox(width: 12),
              Text('${products.length} items need restocking', style: const TextStyle(color: AppColors.lossRed, fontWeight: FontWeight.w700, fontSize: 16)),
            ]),
          ),
          const SizedBox(height: 16),
          ...products.map((p) {
            final totalPieces = (p['total_pieces'] as num? ?? 0).toInt();
            final minLevel = p['min_stock_level'] as int? ?? 10;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    if (p['company_name'] != null) Text(p['company_name'], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                )),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('$totalPieces pcs', style: const TextStyle(color: AppColors.lossRed, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('Min: $minLevel pcs', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ]),
              ]),
            );
          }),
        ],
      ],
    );
  }
}

class _LockedReport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, color: AppColors.textMuted, size: 64),
          SizedBox(height: 16),
          Text('Profit Report', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Admin access required', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _ReportCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}

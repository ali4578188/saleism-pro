import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/product_provider.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<ProductProvider>().loadLowStockProducts();
    });
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(
        title: const Text('Stock Management'),
        backgroundColor: AppColors.bgBlack,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primaryOrange,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryOrange,
          tabs: const [
            Tab(text: 'All Stock'),
            Tab(text: 'Low Stock'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Search products...',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, prov, _) {
                if (prov.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
                return TabBarView(
                  controller: _tabs,
                  children: [
                    _StockList(
                      products: prov.products.where((p) => _search.isEmpty || (p['name'] as String).toLowerCase().contains(_search)).toList(),
                      showAll: true,
                    ),
                    _StockList(
                      products: prov.lowStockProducts.where((p) => _search.isEmpty || (p['name'] as String).toLowerCase().contains(_search)).toList(),
                      showAll: false,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockList extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool showAll;

  const _StockList({required this.products, required this.showAll});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(showAll ? Icons.inventory : Icons.check_circle, color: showAll ? AppColors.textMuted : AppColors.profitGreen, size: 64),
            const SizedBox(height: 16),
            Text(showAll ? 'No products found' : 'All items are well stocked!',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    // Summary stats
    double totalValue = 0;
    int totalCartons = 0;
    for (final p in products) {
      final stockCartons = p['stock_cartons'] as int? ?? 0;
      final stockBoxes = p['stock_boxes'] as int? ?? 0;
      final stockPieces = p['stock_pieces'] as int? ?? 0;
      final cartonQty = p['carton_qty'] as int? ?? 0;
      final piecesPerBox = p['pieces_per_box'] as int? ?? 1;
      final purchaseRate = (p['purchase_rate'] as num).toDouble();
      final totalPieces = stockCartons * cartonQty + stockBoxes * piecesPerBox + stockPieces;
      totalValue += totalPieces * purchaseRate;
      totalCartons += stockCartons;
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StockStat(label: 'Products', value: '${products.length}', icon: Icons.category, color: AppColors.info),
              Container(width: 1, height: 32, color: AppColors.divider),
              _StockStat(label: 'Cartons', value: '$totalCartons', icon: Icons.widgets, color: AppColors.primaryOrange),
              Container(width: 1, height: 32, color: AppColors.divider),
              _StockStat(label: 'Value', value: CurrencyUtils.formatCompact(totalValue), icon: Icons.currency_rupee, color: AppColors.profitGreen),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, i) => _StockTile(product: products[i]),
          ),
        ),
      ],
    );
  }
}

class _StockTile extends StatelessWidget {
  final Map<String, dynamic> product;
  const _StockTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final stockCartons = product['stock_cartons'] as int? ?? 0;
    final stockBoxes = product['stock_boxes'] as int? ?? 0;
    final stockPieces = product['stock_pieces'] as int? ?? 0;
    final cartonQty = product['carton_qty'] as int? ?? 0;
    final piecesPerBox = product['pieces_per_box'] as int? ?? 1;
    final minLevel = product['min_stock_level'] as int? ?? 10;
    final purchaseRate = (product['purchase_rate'] as num).toDouble();
    final totalPieces = stockCartons * cartonQty + stockBoxes * piecesPerBox + stockPieces;
    final stockValue = totalPieces * purchaseRate;
    final isLow = totalPieces <= minLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isLow ? AppColors.lossRed.withOpacity(0.4) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(product['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              if (isLow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.lossRed.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('LOW STOCK', style: TextStyle(color: AppColors.lossRed, fontSize: 10, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          if (product['company_name'] != null)
            Text(product['company_name'], style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              _StockBlock(label: 'Cartons', value: '$stockCartons', color: AppColors.info),
              const SizedBox(width: 8),
              _StockBlock(label: 'Boxes', value: '$stockBoxes', color: AppColors.warning),
              const SizedBox(width: 8),
              _StockBlock(label: 'Pieces', value: '$stockPieces', color: AppColors.primaryOrange),
              const SizedBox(width: 8),
              _StockBlock(label: 'Total Pcs', value: '$totalPieces', color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Value: ${CurrencyUtils.format(stockValue)}', style: const TextStyle(color: AppColors.profitGreen, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('Min: $minLevel pcs', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: minLevel > 0 ? (totalPieces / (minLevel * 3)).clamp(0, 1) : 1,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(isLow ? AppColors.lossRed : AppColors.profitGreen),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StockBlock({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _StockStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StockStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
            Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/product_provider.dart';
import '../../providers/company_provider.dart';
import 'product_form.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CompanyProvider>().loadCompanies();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: AppColors.bgBlack,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                setState(() => _search = v);
                context.read<ProductProvider>().setSearch(v);
              },
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                          context.read<ProductProvider>().setSearch('');
                        })
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, prov, _) {
                if (prov.loading) return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
                if (prov.products.isEmpty) return const Center(child: Text('No products found', style: TextStyle(color: AppColors.textSecondary)));
                return RefreshIndicator(
                  color: AppColors.primaryOrange,
                  backgroundColor: AppColors.bgCard,
                  onRefresh: () => prov.loadProducts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: prov.products.length,
                    itemBuilder: (context, i) {
                      final p = prov.products[i];
                      return _ProductTile(
                        product: p,
                        onEdit: () => _openForm(context, product: p),
                        onDelete: () => _delete(context, p),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, {Map<String, dynamic>? product}) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ProductForm(product: product),
    )).then((_) => context.read<ProductProvider>().loadProducts());
  }

  void _delete(BuildContext context, Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete Product', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "${product['name']}"?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(80, 40)),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ProductProvider>().deleteProduct(product['id']);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductTile({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final stockCartons = product['stock_cartons'] as int? ?? 0;
    final stockBoxes = product['stock_boxes'] as int? ?? 0;
    final stockPieces = product['stock_pieces'] as int? ?? 0;
    final minLevel = product['min_stock_level'] as int? ?? 10;
    final cartonQty = product['carton_qty'] as int? ?? 0;
    final piecesPerBox = product['pieces_per_box'] as int? ?? 1;
    final totalPieces = stockCartons * cartonQty + stockBoxes * piecesPerBox + stockPieces;
    final isLowStock = totalPieces <= minLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isLowStock ? AppColors.lossRed.withOpacity(0.3) : AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isLowStock ? AppColors.lossRed.withOpacity(0.15) : AppColors.primaryOrange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.inventory, color: isLowStock ? AppColors.lossRed : AppColors.primaryOrange, size: 22),
        ),
        title: Text(product['name'] ?? '', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product['company_name'] != null)
              Text(product['company_name'], style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            Row(
              children: [
                _StockChip(label: '${stockCartons}C', icon: Icons.widgets),
                const SizedBox(width: 4),
                _StockChip(label: '${stockBoxes}B', icon: Icons.inventory_2),
                const SizedBox(width: 4),
                _StockChip(label: '${stockPieces}P', icon: Icons.circle),
                if (isLowStock) ...[
                  const SizedBox(width: 4),
                  const _LowTag(),
                ],
              ],
            ),
            Row(
              children: [
                Text('Buy: ${CurrencyUtils.format((product['purchase_rate'] as num).toDouble())}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(width: 8),
                Text('Sell: ${CurrencyUtils.format((product['sale_rate'] as num).toDouble())}',
                  style: const TextStyle(color: AppColors.primaryOrange, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: AppColors.bgCard,
          onSelected: (v) { if (v == 'edit') onEdit(); else if (v == 'delete') onDelete(); },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: AppColors.info, size: 18), SizedBox(width: 8), Text('Edit', style: TextStyle(color: AppColors.textPrimary))])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: AppColors.error, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.textPrimary))])),
          ],
        ),
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StockChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.bgInput,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

class _LowTag extends StatelessWidget {
  const _LowTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.lossRed.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text('LOW', style: TextStyle(color: AppColors.lossRed, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }
}

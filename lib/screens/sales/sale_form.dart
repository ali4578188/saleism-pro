import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/sale_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/product_provider.dart';

class SaleForm extends StatefulWidget {
  const SaleForm({super.key});

  @override
  State<SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends State<SaleForm> {
  String _invoiceNumber = '';
  final _customerCtrl = TextEditingController();
  int? _companyId;
  DateTime _date = DateTime.now();
  final List<_CartItem> _items = [];
  double _discount = 0;
  String _paymentMethod = 'cash';
  double _paidAmount = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _generateInvoice();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CompanyProvider>().loadCompanies();
    });
  }

  @override
  void dispose() { _customerCtrl.dispose(); super.dispose(); }

  Future<void> _generateInvoice() async {
    final num = await context.read<SaleProvider>().generateInvoiceNumber();
    if (mounted) setState(() => _invoiceNumber = num);
  }

  double get _totalAmount => _items.fold(0, (s, i) => s + i.totalAmount);
  double get _finalAmount => _totalAmount - _discount;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.dark(primary: AppColors.primaryOrange)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_customerCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter customer name'), backgroundColor: AppColors.error));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _saving = true);

    final saleData = {
      'invoice_number': _invoiceNumber,
      'customer_name': _customerCtrl.text.trim(),
      'company_id': _companyId,
      'date': DateUtils2.toDb(_date),
      'total_amount': _totalAmount,
      'discount': _discount,
      'final_amount': _finalAmount,
      'paid_amount': _paymentMethod == 'cash' ? _finalAmount : _paidAmount,
      'payment_method': _paymentMethod,
    };

    final items = _items.map((item) => {
      'product_id': item.productId,
      'sale_rate': item.saleRate,
      'purchase_rate': item.purchaseRate,
      'cartons': item.cartons,
      'boxes': item.boxes,
      'pieces': item.pieces,
      'total_pieces': item.totalPieces,
      'total_amount': item.totalAmount,
      'profit': item.profit,
    }).toList();

    final ok = await context.read<SaleProvider>().addSale(saleData, items);
    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale saved!'), backgroundColor: AppColors.success));
        Navigator.pop(context);
      }
    }
  }

  void _addItem() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SaleItemSheet(onAdd: (item) => setState(() => _items.add(item))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companies = context.read<CompanyProvider>().companies;
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(
        title: const Text('New Sale'),
        backgroundColor: AppColors.bgBlack,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryOrange))
                : const Text('SAVE', style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                Row(children: [
                  Text(_invoiceNumber, style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Row(children: [
                      const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 16),
                      const SizedBox(width: 4),
                      Text(DateUtils2.toDisplay(DateUtils2.toDb(_date)), style: const TextStyle(color: AppColors.textPrimary)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customerCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Customer Name *', prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: _companyId,
                  decoration: const InputDecoration(labelText: 'Company (optional)'),
                  dropdownColor: AppColors.bgCard,
                  style: const TextStyle(color: AppColors.textPrimary),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Walk-in Customer', style: TextStyle(color: AppColors.textMuted))),
                    ...companies.map((c) => DropdownMenuItem<int?>(value: c['id'] as int, child: Text(c['name'] as String))),
                  ],
                  onChanged: (v) => setState(() => _companyId = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment method
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Payment Method', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: ['cash', 'credit', 'bank'].map((m) {
                    final selected = m == _paymentMethod;
                    final colors = {'cash': AppColors.profitGreen, 'credit': AppColors.creditYellow, 'bank': AppColors.info};
                    final icons = {'cash': Icons.payments, 'credit': Icons.credit_card, 'bank': Icons.account_balance};
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _paymentMethod = m),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? colors[m]!.withOpacity(0.15) : AppColors.bgInput,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? colors[m]! : AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Icon(icons[m]!, color: selected ? colors[m] : AppColors.textMuted, size: 20),
                              const SizedBox(height: 4),
                              Text(m.toUpperCase(), style: TextStyle(color: selected ? colors[m] : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_paymentMethod == 'credit') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '0',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Advance Payment'),
                    onChanged: (v) => setState(() => _paidAmount = double.tryParse(v) ?? 0),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items
          Row(children: [
            const Text('Items', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Item'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryOrange, minimumSize: const Size(120, 38), padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
          ]),
          const SizedBox(height: 10),

          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
              child: const Center(child: Text('No items added yet', style: TextStyle(color: AppColors.textMuted))),
            ),

          ..._items.asMap().entries.map((e) {
            final item = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(
                children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      Text('${item.cartons}C × ${item.boxes}B × ${item.pieces}P @ ${CurrencyUtils.format(item.saleRate)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      Row(children: [
                        Text(CurrencyUtils.format(item.totalAmount), style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Text('Profit: ${CurrencyUtils.format(item.profit)}', style: const TextStyle(color: AppColors.profitGreen, fontSize: 11)),
                      ]),
                    ],
                  )),
                  IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.lossRed), onPressed: () => setState(() => _items.removeAt(e.key))),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Total section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(
              children: [
                Row(children: [const Text('Subtotal:', style: TextStyle(color: AppColors.textSecondary)), const Spacer(),
                  Text(CurrencyUtils.format(_totalAmount), style: const TextStyle(color: AppColors.textSecondary))]),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: '0',
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(labelText: 'Discount', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                ),
                const Divider(color: AppColors.divider, height: 20),
                Row(children: [
                  const Text('FINAL AMOUNT:', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  Text(CurrencyUtils.format(_finalAmount), style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w800, fontSize: 18)),
                ]),
                if (_items.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Text('Total Profit:', style: TextStyle(color: AppColors.profitGreen, fontSize: 13)),
                    const Spacer(),
                    Text(CurrencyUtils.format(_items.fold(0, (s, i) => s + i.profit)),
                      style: const TextStyle(color: AppColors.profitGreen, fontWeight: FontWeight.w700)),
                  ]),
                ],
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _CartItem {
  final int productId;
  final String productName;
  final double saleRate;
  final double purchaseRate;
  final int cartons, boxes, pieces, cartonQty, piecesPerBox;

  _CartItem({required this.productId, required this.productName, required this.saleRate, required this.purchaseRate,
    required this.cartons, required this.boxes, required this.pieces, required this.cartonQty, required this.piecesPerBox});

  int get totalPieces => cartons * cartonQty + boxes * piecesPerBox + pieces;
  double get totalAmount => saleRate * totalPieces;
  double get profit => (saleRate - purchaseRate) * totalPieces;
}

class _SaleItemSheet extends StatefulWidget {
  final ValueChanged<_CartItem> onAdd;
  const _SaleItemSheet({required this.onAdd});

  @override
  State<_SaleItemSheet> createState() => _SaleItemSheetState();
}

class _SaleItemSheetState extends State<_SaleItemSheet> {
  Map<String, dynamic>? _selected;
  final _cartons = TextEditingController(text: '0');
  final _boxes = TextEditingController(text: '0');
  final _pieces = TextEditingController(text: '0');
  late TextEditingController _rate;

  @override
  void initState() { super.initState(); _rate = TextEditingController(); }
  @override
  void dispose() { _cartons.dispose(); _boxes.dispose(); _pieces.dispose(); _rate.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final products = context.read<ProductProvider>().products;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Sale Item', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selected,
            decoration: const InputDecoration(labelText: 'Select Product'),
            dropdownColor: AppColors.bgCard,
            style: const TextStyle(color: AppColors.textPrimary),
            items: products.map((p) => DropdownMenuItem(value: p, child: Text('${p['name']} (${p['stock_cartons']}C)'))).toList(),
            onChanged: (p) => setState(() { _selected = p; _rate.text = '${p?['sale_rate'] ?? 0}'; }),
          ),
          const SizedBox(height: 12),
          TextFormField(controller: _rate, keyboardType: TextInputType.number, style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Sale Rate')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _qty('Cartons', _cartons)),
            const SizedBox(width: 8),
            Expanded(child: _qty('Boxes', _boxes)),
            const SizedBox(width: 8),
            Expanded(child: _qty('Pieces', _pieces)),
          ]),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_selected == null) return;
              widget.onAdd(_CartItem(
                productId: _selected!['id'] as int,
                productName: _selected!['name'] as String,
                saleRate: double.tryParse(_rate.text) ?? 0,
                purchaseRate: (_selected!['purchase_rate'] as num).toDouble(),
                cartons: int.tryParse(_cartons.text) ?? 0,
                boxes: int.tryParse(_boxes.text) ?? 0,
                pieces: int.tryParse(_pieces.text) ?? 0,
                cartonQty: _selected!['carton_qty'] as int? ?? 0,
                piecesPerBox: _selected!['pieces_per_box'] as int? ?? 1,
              ));
              Navigator.pop(context);
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  Widget _qty(String label, TextEditingController ctrl) => TextFormField(
    controller: ctrl, keyboardType: TextInputType.number,
    style: const TextStyle(color: AppColors.textPrimary), decoration: InputDecoration(labelText: label));
}

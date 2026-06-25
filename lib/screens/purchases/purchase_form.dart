import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/company_provider.dart';
import '../../providers/product_provider.dart';

class PurchaseForm extends StatefulWidget {
  const PurchaseForm({super.key});

  @override
  State<PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends State<PurchaseForm> {
  final _formKey = GlobalKey<FormState>();
  String _invoiceNumber = '';
  int? _companyId;
  DateTime _date = DateTime.now();
  final List<_SaleItem> _items = [];
  double _paidAmount = 0;
  String _paymentStatus = 'unpaid';
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

  Future<void> _generateInvoice() async {
    final num = await context.read<PurchaseProvider>().generateInvoiceNumber();
    if (mounted) setState(() => _invoiceNumber = num);
  }

  double get _totalAmount => _items.fold(0, (s, i) => s + i.totalAmount);

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
    if (_companyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a company'), backgroundColor: AppColors.error));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _saving = true);

    final purchaseData = {
      'invoice_number': _invoiceNumber,
      'company_id': _companyId,
      'date': DateUtils2.toDb(_date),
      'total_amount': _totalAmount,
      'paid_amount': _paidAmount,
      'payment_status': _paymentStatus,
    };

    final items = _items.map((item) => {
      'product_id': item.productId,
      'purchase_rate': item.purchaseRate,
      'cartons': item.cartons,
      'boxes': item.boxes,
      'pieces': item.pieces,
      'total_pieces': item.totalPieces,
      'total_amount': item.totalAmount,
    }).toList();

    final ok = await context.read<PurchaseProvider>().addPurchase(purchaseData, items);
    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase saved!'), backgroundColor: AppColors.success));
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
      builder: (ctx) => _AddItemSheet(
        onAdd: (item) => setState(() => _items.add(item)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companies = context.read<CompanyProvider>().companies;
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(
        title: const Text('New Purchase'),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  Row(children: [
                    const Icon(Icons.receipt, color: AppColors.primaryOrange, size: 18),
                    const SizedBox(width: 8),
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
                  DropdownButtonFormField<int?>(
                    value: _companyId,
                    decoration: const InputDecoration(labelText: 'Supplier Company *'),
                    dropdownColor: AppColors.bgCard,
                    style: const TextStyle(color: AppColors.textPrimary),
                    items: companies.map((c) => DropdownMenuItem<int?>(value: c['id'] as int, child: Text(c['name'] as String))).toList(),
                    onChanged: (v) => setState(() => _companyId = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items section
            Row(children: [
              const Text('Items', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  minimumSize: const Size(120, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ]),
            const SizedBox(height: 10),

            if (_items.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border, style: BorderStyle.solid)),
                child: const Center(child: Text('No items added yet', style: TextStyle(color: AppColors.textMuted))),
              ),

            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.productName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                          Text('${item.cartons}C × ${item.boxes}B × ${item.pieces}P @ ${CurrencyUtils.format(item.purchaseRate)}',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          Text(CurrencyUtils.format(item.totalAmount), style: const TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.lossRed),
                      onPressed: () => setState(() => _items.removeAt(i)),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Payment section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      Text(CurrencyUtils.format(_totalAmount), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: '0',
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Paid Amount'),
                    onChanged: (v) => setState(() {
                      _paidAmount = double.tryParse(v) ?? 0;
                      if (_paidAmount >= _totalAmount) _paymentStatus = 'paid';
                      else if (_paidAmount > 0) _paymentStatus = 'partial';
                      else _paymentStatus = 'unpaid';
                    }),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance:', style: TextStyle(color: AppColors.textSecondary)),
                      Text(
                        CurrencyUtils.format(_totalAmount - _paidAmount),
                        style: TextStyle(
                          color: (_totalAmount - _paidAmount) > 0 ? AppColors.lossRed : AppColors.profitGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SaleItem {
  final int productId;
  final String productName;
  final double purchaseRate;
  final int cartons;
  final int boxes;
  final int pieces;
  final int cartonQty;
  final int piecesPerBox;

  _SaleItem({
    required this.productId,
    required this.productName,
    required this.purchaseRate,
    required this.cartons,
    required this.boxes,
    required this.pieces,
    required this.cartonQty,
    required this.piecesPerBox,
  });

  int get totalPieces => cartons * cartonQty + boxes * piecesPerBox + pieces;
  double get totalAmount => purchaseRate * totalPieces;
}

class _AddItemSheet extends StatefulWidget {
  final ValueChanged<_SaleItem> onAdd;
  const _AddItemSheet({required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  Map<String, dynamic>? _selected;
  final _cartons = TextEditingController(text: '0');
  final _boxes = TextEditingController(text: '0');
  final _pieces = TextEditingController(text: '0');
  late TextEditingController _rate;

  @override
  void initState() {
    super.initState();
    _rate = TextEditingController();
  }

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
          const Text('Add Item', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selected,
            decoration: const InputDecoration(labelText: 'Select Product'),
            dropdownColor: AppColors.bgCard,
            style: const TextStyle(color: AppColors.textPrimary),
            items: products.map((p) => DropdownMenuItem(
              value: p,
              child: Text(p['name'] as String),
            )).toList(),
            onChanged: (p) => setState(() {
              _selected = p;
              _rate.text = '${p?['purchase_rate'] ?? 0}';
            }),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rate,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(labelText: 'Purchase Rate'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _qtyField('Cartons', _cartons)),
            const SizedBox(width: 8),
            Expanded(child: _qtyField('Boxes', _boxes)),
            const SizedBox(width: 8),
            Expanded(child: _qtyField('Pieces', _pieces)),
          ]),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_selected == null) return;
              final item = _SaleItem(
                productId: _selected!['id'] as int,
                productName: _selected!['name'] as String,
                purchaseRate: double.tryParse(_rate.text) ?? 0,
                cartons: int.tryParse(_cartons.text) ?? 0,
                boxes: int.tryParse(_boxes.text) ?? 0,
                pieces: int.tryParse(_pieces.text) ?? 0,
                cartonQty: _selected!['carton_qty'] as int? ?? 0,
                piecesPerBox: _selected!['pieces_per_box'] as int? ?? 1,
              );
              widget.onAdd(item);
              Navigator.pop(context);
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  Widget _qtyField(String label, TextEditingController ctrl) => TextFormField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(labelText: label),
  );
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/product_provider.dart';
import '../../providers/company_provider.dart';

class ProductForm extends StatefulWidget {
  final Map<String, dynamic>? product;
  const ProductForm({super.key, this.product});

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _barcode, _mrp, _purchaseRate, _saleRate;
  late TextEditingController _cartonQty, _boxQty, _piecesPerBox, _minStock;
  late TextEditingController _stockCartons, _stockBoxes, _stockPieces;
  String _category = '';
  int? _companyId;
  bool _saving = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = TextEditingController(text: p?['name'] ?? '');
    _barcode = TextEditingController(text: p?['barcode'] ?? '');
    _mrp = TextEditingController(text: '${p?['mrp'] ?? 0}');
    _purchaseRate = TextEditingController(text: '${p?['purchase_rate'] ?? 0}');
    _saleRate = TextEditingController(text: '${p?['sale_rate'] ?? 0}');
    _cartonQty = TextEditingController(text: '${p?['carton_qty'] ?? 0}');
    _boxQty = TextEditingController(text: '${p?['box_qty'] ?? 0}');
    _piecesPerBox = TextEditingController(text: '${p?['pieces_per_box'] ?? 1}');
    _minStock = TextEditingController(text: '${p?['min_stock_level'] ?? 10}');
    _stockCartons = TextEditingController(text: '${p?['stock_cartons'] ?? 0}');
    _stockBoxes = TextEditingController(text: '${p?['stock_boxes'] ?? 0}');
    _stockPieces = TextEditingController(text: '${p?['stock_pieces'] ?? 0}');
    _category = p?['category'] ?? '';
    _companyId = p?['company_id'];
  }

  @override
  void dispose() {
    for (final c in [_name, _barcode, _mrp, _purchaseRate, _saleRate,
      _cartonQty, _boxQty, _piecesPerBox, _minStock, _stockCartons, _stockBoxes, _stockPieces]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bgCard,
      builder: (ctx) => SizedBox(
        height: 300,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Text('Scan Barcode', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(ctx)),
              ]),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final code = capture.barcodes.first.rawValue;
                  if (code != null) Navigator.pop(ctx, code);
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) setState(() => _barcode.text = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final data = {
      'name': _name.text.trim(),
      'barcode': _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      'company_id': _companyId,
      'category': _category.isEmpty ? null : _category,
      'mrp': double.tryParse(_mrp.text) ?? 0,
      'purchase_rate': double.tryParse(_purchaseRate.text) ?? 0,
      'sale_rate': double.tryParse(_saleRate.text) ?? 0,
      'carton_qty': int.tryParse(_cartonQty.text) ?? 0,
      'box_qty': int.tryParse(_boxQty.text) ?? 0,
      'pieces_per_box': int.tryParse(_piecesPerBox.text) ?? 1,
      'min_stock_level': int.tryParse(_minStock.text) ?? 10,
      'stock_cartons': int.tryParse(_stockCartons.text) ?? 0,
      'stock_boxes': int.tryParse(_stockBoxes.text) ?? 0,
      'stock_pieces': int.tryParse(_stockPieces.text) ?? 0,
    };
    final prov = context.read<ProductProvider>();
    final ok = isEdit
        ? await prov.updateProduct(widget.product!['id'], data)
        : await prov.addProduct(data);
    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Product updated!' : 'Product added!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companies = context.read<CompanyProvider>().companies;
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      appBar: AppBar(title: Text(isEdit ? 'Edit Product' : 'Add Product'), backgroundColor: AppColors.bgBlack),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader('Basic Info'),
            _field('Product Name *', _name, required: true),
            Row(
              children: [
                Expanded(child: _field('Barcode', _barcode)),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: _scanBarcode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bgCard,
                      foregroundColor: AppColors.primaryOrange,
                      minimumSize: const Size(52, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
                    ),
                    child: const Icon(Icons.qr_code_scanner, size: 24),
                  ),
                ),
              ],
            ),

            // Company dropdown
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<int?>(
                value: _companyId,
                decoration: const InputDecoration(labelText: 'Company'),
                dropdownColor: AppColors.bgCard,
                style: const TextStyle(color: AppColors.textPrimary),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('None', style: TextStyle(color: AppColors.textMuted))),
                  ...companies.map((c) => DropdownMenuItem<int?>(
                    value: c['id'] as int,
                    child: Text(c['name'] as String, style: const TextStyle(color: AppColors.textPrimary)),
                  )),
                ],
                onChanged: (v) => setState(() => _companyId = v),
              ),
            ),

            _field('Category', TextEditingController(text: _category),
              onChanged: (v) => _category = v),

            _sectionHeader('Pricing'),
            Row(children: [
              Expanded(child: _field('MRP', _mrp, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field('Purchase Rate', _purchaseRate, keyboardType: TextInputType.number)),
            ]),
            _field('Sale Rate', _saleRate, keyboardType: TextInputType.number),

            _sectionHeader('Pack Sizes'),
            Row(children: [
              Expanded(child: _field('Carton Qty', _cartonQty, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field('Box Qty', _boxQty, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field('Pcs/Box', _piecesPerBox, keyboardType: TextInputType.number)),
            ]),
            _field('Min Stock Level', _minStock, keyboardType: TextInputType.number),

            _sectionHeader('Opening Stock'),
            Row(children: [
              Expanded(child: _field('Cartons', _stockCartons, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field('Boxes', _stockBoxes, keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _field('Pieces', _stockPieces, keyboardType: TextInputType.number)),
            ]),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Update Product' : 'Add Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    child: Text(title, style: const TextStyle(color: AppColors.primaryOrange, fontSize: 14, fontWeight: FontWeight.w700)),
  );

  Widget _field(String label, TextEditingController ctrl, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    ),
  );
}

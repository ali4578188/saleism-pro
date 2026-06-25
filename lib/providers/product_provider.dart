import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';

class ProductProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  bool _loading = false;
  String _searchQuery = '';
  int? _filterCompanyId;
  String? _filterCategory;

  List<Map<String, dynamic>> get products => _products;
  List<Map<String, dynamic>> get lowStockProducts => _lowStockProducts;
  bool get loading => _loading;

  Future<void> loadProducts({String? search, int? companyId, String? category}) async {
    _loading = true;
    notifyListeners();
    _products = await DatabaseHelper.instance.getProducts(
      search: search ?? _searchQuery,
      companyId: companyId ?? _filterCompanyId,
      category: category ?? _filterCategory,
    );
    _loading = false;
    notifyListeners();
  }

  Future<void> loadLowStockProducts() async {
    _lowStockProducts = await DatabaseHelper.instance.getLowStockProducts();
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    loadProducts();
  }

  void setFilters({int? companyId, String? category}) {
    _filterCompanyId = companyId;
    _filterCategory = category;
    loadProducts();
  }

  Future<bool> addProduct(Map<String, dynamic> data) async {
    try {
      await DatabaseHelper.instance.insertProduct(data);
      await loadProducts();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      await DatabaseHelper.instance.updateProduct(id, data);
      await loadProducts();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      await DatabaseHelper.instance.deleteProduct(id);
      await loadProducts();
      return true;
    } catch (_) { return false; }
  }

  Future<Map<String, dynamic>?> findByBarcode(String barcode) async {
    return await DatabaseHelper.instance.getProductByBarcode(barcode);
  }

  Map<String, dynamic>? getById(int id) {
    try { return _products.firstWhere((p) => p['id'] == id); }
    catch (_) { return null; }
  }
}

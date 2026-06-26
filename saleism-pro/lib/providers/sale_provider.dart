import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';

class SaleProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _sales = [];
  bool _loading = false;

  List<Map<String, dynamic>> get sales => _sales;
  bool get loading => _loading;

  Future<void> loadSales({String? dateFrom, String? dateTo, int? companyId, String? customerName}) async {
    _loading = true;
    notifyListeners();
    _sales = await DatabaseHelper.instance.getSales(
      dateFrom: dateFrom,
      dateTo: dateTo,
      companyId: companyId,
      customerName: customerName,
    );
    _loading = false;
    notifyListeners();
  }

  Future<bool> addSale(Map<String, dynamic> data, List<Map<String, dynamic>> items) async {
    try {
      await DatabaseHelper.instance.insertSale(data, items);
      await loadSales();
      return true;
    } catch (_) { return false; }
  }

  Future<List<Map<String, dynamic>>> getSaleItems(int saleId) async {
    return await DatabaseHelper.instance.getSaleItems(saleId);
  }

  Future<String> generateInvoiceNumber() async {
    return await DatabaseHelper.instance.generateInvoiceNumber('INV');
  }

  double get totalSalesAmount => _sales.fold(0, (sum, s) => sum + (s['final_amount'] as num).toDouble());
}

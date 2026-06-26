import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';

class PurchaseProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _purchases = [];
  bool _loading = false;

  List<Map<String, dynamic>> get purchases => _purchases;
  bool get loading => _loading;

  Future<void> loadPurchases({String? dateFrom, String? dateTo, int? companyId}) async {
    _loading = true;
    notifyListeners();
    _purchases = await DatabaseHelper.instance.getPurchases(
      dateFrom: dateFrom,
      dateTo: dateTo,
      companyId: companyId,
    );
    _loading = false;
    notifyListeners();
  }

  Future<bool> addPurchase(Map<String, dynamic> data, List<Map<String, dynamic>> items) async {
    try {
      await DatabaseHelper.instance.insertPurchase(data, items);
      await loadPurchases();
      return true;
    } catch (_) { return false; }
  }

  Future<List<Map<String, dynamic>>> getPurchaseItems(int purchaseId) async {
    return await DatabaseHelper.instance.getPurchaseItems(purchaseId);
  }

  Future<String> generateInvoiceNumber() async {
    return await DatabaseHelper.instance.generateInvoiceNumber('PUR');
  }
}

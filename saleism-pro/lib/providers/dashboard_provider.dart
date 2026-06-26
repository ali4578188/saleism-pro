import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';

class DashboardProvider extends ChangeNotifier {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _profitData = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  bool _loading = false;

  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get profitData => _profitData;
  List<Map<String, dynamic>> get lowStockProducts => _lowStockProducts;
  bool get loading => _loading;

  Future<void> loadDashboard() async {
    _loading = true;
    notifyListeners();
    _stats = await DatabaseHelper.instance.getDashboardStats();
    _profitData = await DatabaseHelper.instance.getProfitReport(period: 'daily');
    _lowStockProducts = await DatabaseHelper.instance.getLowStockProducts();
    _loading = false;
    notifyListeners();
  }

  double get stockValue => (_stats['stock_value'] ?? 0).toDouble();
  double get totalPurchase => (_stats['total_purchase'] ?? 0).toDouble();
  double get totalSales => (_stats['total_sales'] ?? 0).toDouble();
  double get todaySales => (_stats['today_sales'] ?? 0).toDouble();
  double get totalProfit => (_stats['total_profit'] ?? 0).toDouble();
  int get lowStockCount => (_stats['low_stock'] ?? 0).toInt();
  double get outstandingCredit => (_stats['outstanding_credit'] ?? 0).toDouble();
  int get totalCompanies => (_stats['total_companies'] ?? 0).toInt();

  double get profitMargin {
    if (totalSales == 0) return 0;
    return (totalProfit / totalSales) * 100;
  }
}

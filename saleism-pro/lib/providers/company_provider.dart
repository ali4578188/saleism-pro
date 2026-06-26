import 'package:flutter/foundation.dart';
import '../core/database/database_helper.dart';

class CompanyProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _companies = [];
  bool _loading = false;

  List<Map<String, dynamic>> get companies => _companies;
  bool get loading => _loading;

  Future<void> loadCompanies() async {
    _loading = true;
    notifyListeners();
    _companies = await DatabaseHelper.instance.getCompanies();
    _loading = false;
    notifyListeners();
  }

  Future<bool> addCompany(Map<String, dynamic> data) async {
    try {
      await DatabaseHelper.instance.insertCompany(data);
      await loadCompanies();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> updateCompany(int id, Map<String, dynamic> data) async {
    try {
      await DatabaseHelper.instance.updateCompany(id, data);
      await loadCompanies();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> deleteCompany(int id) async {
    try {
      await DatabaseHelper.instance.deleteCompany(id);
      await loadCompanies();
      return true;
    } catch (_) { return false; }
  }

  Future<List<Map<String, dynamic>>> getLedger(int companyId) async {
    return await DatabaseHelper.instance.getLedger(companyId);
  }

  Map<String, dynamic>? getById(int id) {
    try { return _companies.firstWhere((c) => c['id'] == id); }
    catch (_) { return null; }
  }
}

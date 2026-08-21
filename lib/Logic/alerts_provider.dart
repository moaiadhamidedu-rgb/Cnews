import 'package:flutter/material.dart';
import '../data/local/database_helper.dart';

class AlertsProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get alerts => _alerts;
  bool get isLoading => _isLoading;

  Future<void> loadAlerts() async {
    _isLoading = true;
    notifyListeners();
    _alerts = await _dbHelper.queryAllAlerts();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAlert(String currency, double rate, String type) async {
    await _dbHelper.insertAlert(currency, rate, type);
    await loadAlerts();
  }

  Future<void> deleteAlert(int id) async {
    await _dbHelper.deleteAlert(id);
    await loadAlerts();
  }
}

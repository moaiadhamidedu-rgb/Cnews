import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/local/database_helper.dart';

class CalculateProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  double _result = 0.0;
  String _fromCurrency = 'USD';
  String _toCurrency = 'SYP';
  double _currentRate = 14850.0; 

  List<Map<String, dynamic>> _walletItems = [];
  double _totalBalance = 0.0;
  double _income = 0.0;
  double _expense = 0.0;

  double get result => _result;
  String get fromCurrency => _fromCurrency;
  String get toCurrency => _toCurrency;
  List<Map<String, dynamic>> get walletItems => _walletItems;
  double get totalBalance => _totalBalance;
  double get income => _income;
  double get expense => _expense;

  Future<void> loadWallet() async {
    final items = await _dbHelper.queryAllWallet();
    double inc = 0;
    double exp = 0;
    for (var item in items) {
      if (item['type'] == 'income') {
        inc += item['amount'];
      } else {
        exp += item['amount'];
      }
    }
    _walletItems = items;
    _income = inc;
    _expense = exp;
    _totalBalance = inc - exp;
    notifyListeners();
  }

  void convert(String inputStr) {
    double input = double.tryParse(inputStr) ?? 0;
    if (_fromCurrency == 'USD' && _toCurrency == 'SYP') {
      _result = input * _currentRate;
    } else if (_fromCurrency == 'SYP' && _toCurrency == 'USD') {
      _result = input / _currentRate;
    }
    notifyListeners();
  }

  void swapCurrencies(String currentInput) {
    String temp = _fromCurrency;
    _fromCurrency = _toCurrency;
    _toCurrency = temp;
    convert(currentInput);
  }

  Future<void> addTransaction(String title, double amount, String type) async {
    await _dbHelper.insertWalletItem({
      'title': title,
      'amount': amount,
      'type': type,
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'is_paid': 1
    });
    await loadWallet();
  }

  Future<void> deleteTransaction(int id) async {
    await _dbHelper.deleteWalletItem(id);
    await loadWallet();
  }
}

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

  double _totalBalanceSyp = 0.0;
  double _incomeSyp = 0.0;
  double _expenseSyp = 0.0;

  double _totalBalanceUsd = 0.0;
  double _incomeUsd = 0.0;
  double _expenseUsd = 0.0;

  Map<String, double> _categoryTotalsSyp = {};
  Map<String, double> _categoryTotalsUsd = {};

  List<Map<String, dynamic>> _goals = [];
  bool _isAuthProtected = false;

  double get result => _result;
  String get fromCurrency => _fromCurrency;
  String get toCurrency => _toCurrency;
  List<Map<String, dynamic>> get walletItems => _walletItems;
  List<Map<String, dynamic>> get goals => _goals;
  bool get isAuthProtected => _isAuthProtected;

  double get totalBalanceSyp => _totalBalanceSyp;
  double get incomeSyp => _incomeSyp;
  double get expenseSyp => _expenseSyp;

  double get totalBalanceUsd => _totalBalanceUsd;
  double get incomeUsd => _incomeUsd;
  double get expenseUsd => _expenseUsd;

  Map<String, double> get categoryTotalsSyp => _categoryTotalsSyp;
  Map<String, double> get categoryTotalsUsd => _categoryTotalsUsd;

  double get totalBalanceCombinedSyp =>
      _totalBalanceSyp + (_totalBalanceUsd * _currentRate);

  Future<void> loadWallet() async {
    final items = await _dbHelper.queryAllWallet();

    double incSyp = 0;
    double expSyp = 0;
    double incUsd = 0;
    double expUsd = 0;

    Map<String, double> catSyp = {};
    Map<String, double> catUsd = {};

    for (var item in items) {
      final amount = (item['amount'] as num).toDouble();
      final type = item['type'];
      final currency = item['currency'] ?? 'SYP';
      final category = item['category'] ?? 'General';

      if (currency == 'USD') {
        if (type == 'income') {
          incUsd += amount;
        } else {
          expUsd += amount;
          catUsd[category] = (catUsd[category] ?? 0) + amount;
        }
      } else {
        if (type == 'income') {
          incSyp += amount;
        } else {
          expSyp += amount;
          catSyp[category] = (catSyp[category] ?? 0) + amount;
        }
      }
    }

    _walletItems = items;
    _incomeSyp = incSyp;
    _expenseSyp = expSyp;
    _totalBalanceSyp = incSyp - expSyp;
    _categoryTotalsSyp = catSyp;

    _incomeUsd = incUsd;
    _expenseUsd = expUsd;
    _totalBalanceUsd = incUsd - expUsd;
    _categoryTotalsUsd = catUsd;

    _goals = await _dbHelper.queryAllGoals();
    notifyListeners();
  }

  // --- إدارة الأهداف والربط مع المحفظة ---

  Future<void> addGoal(String title, double target, String currency) async {
    await _dbHelper.insertGoal({
      'title': title,
      'target_amount': target,
      'saved_amount': 0,
      'currency': currency,
    });
    await loadWallet();
  }

  Future<bool> updateGoalProgress(int id, double newSaved) async {
    final goal = _goals.firstWhere((g) => g['id'] == id);
    final oldSaved = (goal['saved_amount'] as num).toDouble();
    final diff = newSaved - oldSaved;
    final currency = goal['currency'] ?? 'USD';

    if (diff == 0) return true;

    if (diff > 0) {
      // حالة إضافة مدخرات: نسحب من المحفظة
      if (!canSpend(diff, currency)) return false;

      await addTransaction(
        'ادخار لـ: ${goal['title']}',
        diff,
        'expense',
        currency,
        'Savings',
      );
    } else {
      // حالة سحب من المدخرات: نعيد للمحفظة
      await addTransaction(
        'استرداد من: ${goal['title']}',
        -diff,
        'income',
        currency,
        'Savings',
      );
    }

    await _dbHelper.updateGoal({'id': id, 'saved_amount': newSaved});

    await loadWallet();
    return true;
  }

  Future<void> deleteGoal(int id) async {
    final goal = _goals.firstWhere((g) => g['id'] == id);
    final saved = (goal['saved_amount'] as num).toDouble();
    final currency = goal['currency'] ?? 'USD';

    // إرجاع أي مبلغ مدخر للمحفظة قبل الحذف
    if (saved > 0) {
      await addTransaction(
        'استرداد (حذف هدف): ${goal['title']}',
        saved,
        'income',
        currency,
        'Savings',
      );
    }

    await _dbHelper.deleteGoal(id);
    await loadWallet();
  }

  // --- العمليات المالية ---

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

  bool canSpend(double amount, String currency) {
    if (currency == 'USD') {
      return _totalBalanceUsd >= amount;
    } else {
      return _totalBalanceSyp >= amount;
    }
  }

  Future<bool> addTransaction(
    String title,
    double amount,
    String type,
    String currency,
    String category,
  ) async {
    if (type == 'expense' && !canSpend(amount, currency)) {
      return false;
    }

    await _dbHelper.insertWalletItem({
      'title': title,
      'amount': amount,
      'type': type,
      'currency': currency,
      'category': category,
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'is_paid': 1,
    });
    await loadWallet();
    return true;
  }

  Future<bool> updateTransaction(
    int id,
    String title,
    double amount,
    String type,
    String currency,
    String category, {
    double? oldAmount,
    String? oldType,
    String? oldCurrency,
  }) async {
    double currentBalance = (currency == 'USD')
        ? _totalBalanceUsd
        : _totalBalanceSyp;

    if (oldAmount != null && oldType != null && oldCurrency == currency) {
      if (oldType == 'income')
        currentBalance -= oldAmount;
      else
        currentBalance += oldAmount;
    }

    if (type == 'expense' && currentBalance < amount) {
      return false;
    }

    await _dbHelper.updateWalletItem({
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'currency': currency,
      'category': category,
    });
    await loadWallet();
    return true;
  }

  Future<void> deleteTransaction(int id) async {
    await _dbHelper.deleteWalletItem(id);
    await loadWallet();
  }

  Future<void> resetWallet() async {
    await _dbHelper.clearWallet();
    await loadWallet();
  }

  void setExchangeRate(double rate) {
    _currentRate = rate;
    notifyListeners();
  }
}

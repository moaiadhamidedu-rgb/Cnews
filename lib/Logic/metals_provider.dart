import 'package:flutter/material.dart';
import '../data/remote/currency_service.dart';

class MetalsProvider extends ChangeNotifier {
  final CurrencyService _service = CurrencyService();
  bool _isLoading = true;
  Map<String, dynamic> _prices = {};
  String? _errorMessage;

  bool get isLoading => _isLoading;
  Map<String, dynamic> get prices => _prices;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPrices() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final goldRes = await _service.fetchMetalPrice('XAU');
    final silverRes = await _service.fetchMetalPrice('XAG');
    final platinumRes = await _service.fetchMetalPrice('XPT');
    
    goldRes.fold(
      (f) => _errorMessage = f.message,
      (gold) {
        _prices['Gold'] = gold;
      },
    );

    silverRes.fold(
      (f) => _errorMessage = f.message,
      (silver) {
        _prices['Silver'] = silver;
      },
    );

    platinumRes.fold(
      (f) => _errorMessage = f.message,
      (platinum) {
        _prices['Platinum'] = platinum;
      },
    );

    _isLoading = false;
    notifyListeners();
  }
}

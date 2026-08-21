import 'package:flutter/material.dart';
import '../data/remote/currency_service.dart';

class CryptoProvider extends ChangeNotifier {
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

    final result = await _service.fetchCryptoPrices();
    
    result.fold(
      (failure) => _errorMessage = failure.message,
      (data) {
        _prices = data;
      },
    );

    _isLoading = false;
    notifyListeners();
  }
}

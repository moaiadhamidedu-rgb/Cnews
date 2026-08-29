import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/local/notification_service.dart';
import '../data/models/currency_rate.dart';
import '../data/remote/currency_service.dart';
import '../data/local/database_helper.dart';

class HomeProvider extends ChangeNotifier {
  final CurrencyService _currencyService = CurrencyService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();
  final Connectivity _connectivity = Connectivity();

  List<CurrencyRate> _topRates = [];
  List<CurrencyRate> _allRates = [];
  bool _showAll = false;
  bool _isLoadingTop = false;
  bool _isLoadingAll = false;
  bool _isOffline = false;
  String? _errorMessage;
  static const int _refreshIntervalSeconds = 6 * 60 * 60;
  int _secondsRemaining = _refreshIntervalSeconds;
  Timer? _refreshTimer;

  List<CurrencyRate> get topRates => _topRates;
  List<CurrencyRate> get allRates => _allRates;
  List<CurrencyRate> get otherRates {
    final priorityCodes = _topRates.map((rate) => rate.code).toSet();
    return _allRates
        .where((rate) => !priorityCodes.contains(rate.code))
        .toList();
  }

  bool get showAll => _showAll;
  bool get isLoadingTop => _isLoadingTop;
  bool get isLoadingAll => _isLoadingAll;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;
  int get secondsRemaining => _secondsRemaining;

  void init() {
    _notificationService.init();
    _checkInitialConnectivity();
    fetchAllCurrencies();
    _startTimer();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateOfflineStatus(result);
  }

  void _updateOfflineStatus(List<ConnectivityResult> result) {
    _isOffline = result.contains(ConnectivityResult.none) || result.isEmpty;
    notifyListeners();
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _secondsRemaining = _refreshIntervalSeconds;
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        refreshRates();
      }
    });
  }

  Future<void> fetchTopRates() async {
    _isLoadingTop = true;
    _errorMessage = null;
    notifyListeners();

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none) ||
        connectivityResult.isEmpty) {
      _isOffline = true;
      await _loadSavedRates();
      _isLoadingTop = false;
      notifyListeners();
      return;
    }

    final result = await _currencyService.fetchLatestRates(all: false);

    await result.fold(
      (failure) async {
        _errorMessage = failure.message;
        await _loadSavedRates();
      },
      (rates) async {
        if (rates.isNotEmpty) {
          await _dbHelper.saveRates(rates.map((e) => e.toMap()).toList());
          _isOffline = false;
          _topRates = rates;
          _errorMessage = null;
          _checkAlerts(rates);
        } else {
          await _loadSavedRates();
        }
      },
    );

    _isLoadingTop = false;
    notifyListeners();
  }

  Future<void> _loadSavedRates() async {
    final savedData = await _dbHelper.getLatestSavedRates();
    if (savedData.isNotEmpty) {
      _allRates = savedData.map((e) => CurrencyRate.fromMap(e)).toList();
      _topRates = _priorityRates(_allRates);
      _checkAlerts(_topRates);
    }
  }

  Future<void> fetchAllCurrencies() async {
    _isLoadingAll = true;
    _isLoadingTop = true;
    _errorMessage = null;
    notifyListeners();

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none) ||
        connectivityResult.isEmpty) {
      _isOffline = true;
      await _loadSavedRates();
      _isLoadingAll = false;
      _isLoadingTop = false;
      notifyListeners();
      return;
    }

    final result = await _currencyService.fetchLatestRates(all: true);

    await result.fold(
      (failure) async {
        _errorMessage = failure.message;
        _isOffline = true;
        await _loadSavedRates();
      },
      (all) async {
        _allRates = all;
        _topRates = _priorityRates(all);
        _showAll = true;
        _isOffline = false;
        _errorMessage = null;
        await _dbHelper.saveRates(all.map((rate) => rate.toMap()).toList());
        _checkAlerts(all);
      },
    );

    _isLoadingAll = false;
    _isLoadingTop = false;
    notifyListeners();
  }

  void toggleShowAll() {
    _showAll = !_showAll;
    notifyListeners();
  }

  Future<void> refreshRates() async {
    await fetchAllCurrencies();
    _startTimer();
  }

  List<CurrencyRate> _priorityRates(List<CurrencyRate> rates) {
    const priorityCodes = {'USD', 'EUR', 'TRY', 'SAR', 'AED', 'JOD', 'EGP'};
    return rates.where((rate) => priorityCodes.contains(rate.code)).toList();
  }

  Future<int> _checkAlerts(List<CurrencyRate> rates) async {
    var triggeredAlerts = 0;
    final alerts = await _dbHelper.queryAllAlerts();
    for (var alert in alerts) {
      if (alert['is_active'] == 1) {
        final rateIndex = rates.indexWhere(
          (r) => r.code == alert['currency_pair'],
        );

        if (rateIndex != -1) {
          final currentRate = rates[rateIndex];
          bool shouldNotify = false;
          double targetRate = (alert['target_rate'] as num).toDouble();

          if (alert['alert_type'] == 'above' &&
              currentRate.rate >= targetRate) {
            shouldNotify = true;
          } else if (alert['alert_type'] == 'below' &&
              currentRate.rate <= targetRate) {
            shouldNotify = true;
          }

          if (shouldNotify) {
            await _notificationService.showNotification(
              'تنبيه السعر!',
              'وصل ${getCurrencyName(currentRate.code, true)} إلى ${currentRate.rate.toStringAsFixed(0)} ل.س',
            );
            await _dbHelper.updateAlertStatus(alert['id'], false);
            triggeredAlerts++;
            notifyListeners();
          }
        }
      }
    }
    return triggeredAlerts;
  }

  Future<int> updateManualRate(String code, double newRate) async {
    if (!newRate.isFinite || newRate <= 0) {
      throw const FormatException('The manual rate must be positive');
    }
    // Update in topRates
    int topIndex = _topRates.indexWhere((r) => r.code == code);
    if (topIndex != -1) {
      _topRates[topIndex] = CurrencyRate(
        code: code,
        rate: newRate,
        buy: newRate * 0.99,
        sell: newRate * 1.01,
        timestamp: DateTime.now(),
      );
    }

    // Update in allRates
    int allIndex = _allRates.indexWhere((r) => r.code == code);
    if (allIndex != -1) {
      _allRates[allIndex] = CurrencyRate(
        code: code,
        rate: newRate,
        buy: newRate * 0.99,
        sell: newRate * 1.01,
        timestamp: DateTime.now(),
      );
    }

    notifyListeners();
    // Trigger active alerts immediately for the committee demonstration.
    return _checkAlerts([..._topRates, ..._allRates]);
  }

  String getCurrencyName(String code, bool isArabic) {
    if (!isArabic) return code;
    final Map<String, String> names = {
      'USD': 'الدولار الأمريكي',
      'EUR': 'اليورو الأوروبي',
      'TRY': 'الليرة التركية',
      'GBP': 'الجنيه الإسترليني',
      'SAR': 'الريال السعودي',
      'AED': 'الدرهم الإماراتي',
      'JOD': 'الدينار الأردني',
      'KWD': 'الدينار الكويتي',
      'EGP': 'الجنيه المصري',
    };
    return names[code] ?? code;
  }

  String getCurrencyEmoji(String code) {
    final Map<String, String> specialFlags = {
      'USD': '🇺🇸',
      'EUR': '🇪🇺',
      'GBP': '🇬🇧',
      'TRY': '🇹🇷',
      'SAR': '🇸🇦',
      'AED': '🇦🇪',
      'JPY': '🇯🇵',
      'CNY': '🇨🇳',
      'SYP': '🇸🇾',
      'GOLD': '🟡',
      'SILVER': '⚪',
      'EGP': '🇪🇬',
    };
    if (specialFlags.containsKey(code)) return specialFlags[code]!;
    try {
      if (code.length >= 2) {
        String countryCode = code.substring(0, 2);
        return countryCode.toUpperCase().replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) =>
              String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397),
        );
      }
    } catch (e) {
      return '🏳️';
    }
    return '🏳️';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

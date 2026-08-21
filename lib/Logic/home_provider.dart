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
  int _secondsRemaining = 3600;
  Timer? _refreshTimer;

  List<CurrencyRate> get topRates => _topRates;
  List<CurrencyRate> get allRates => _allRates;
  bool get showAll => _showAll;
  bool get isLoadingTop => _isLoadingTop;
  bool get isLoadingAll => _isLoadingAll;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;
  int get secondsRemaining => _secondsRemaining;

  void init() {
    _notificationService.init();
    _checkInitialConnectivity();
    fetchTopRates();
    fetchAllCurrencies(); // Fetch all by default
    _startTimer();
  }

  Future<void> _checkInitialConnectivity() async {
    var result = await _connectivity.checkConnectivity();
    _updateOfflineStatus(result);
  }

  void _updateOfflineStatus(ConnectivityResult result) {
    _isOffline = (result == ConnectivityResult.none);
    notifyListeners();
  }

  void _startTimer() {
    _refreshTimer?.cancel();
    _secondsRemaining = 3600;
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
    if (connectivityResult == ConnectivityResult.none) {
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
      _topRates = savedData.map((e) => CurrencyRate.fromMap(e)).toList();
      _checkAlerts(_topRates);
    }
  }

  Future<void> fetchAllCurrencies() async {
    _isLoadingAll = true;
    notifyListeners();

    final result = await _currencyService.fetchLatestRates(all: true);

    result.fold(
      (failure) => _errorMessage = failure.message,
      (all) {
        _allRates = all;
        _showAll = true;
        _isOffline = false;
      },
    );

    _isLoadingAll = false;
    notifyListeners();
  }

  void toggleShowAll() {
    _showAll = !_showAll;
    notifyListeners();
  }

  Future<void> refreshRates() async {
    await fetchTopRates();
    if (_showAll) await fetchAllCurrencies();
    _startTimer();
  }

  void _checkAlerts(List<CurrencyRate> rates) async {
    final alerts = await _dbHelper.queryAllAlerts();
    for (var alert in alerts) {
      if (alert['is_active'] == 1) {
        final currentRate = rates.firstWhere(
          (r) => r.code == alert['currency_pair'],
          orElse: () => CurrencyRate(code: '', rate: 0, timestamp: DateTime.now()),
        );

        if (currentRate.code.isNotEmpty) {
          bool shouldNotify = false;
          if (alert['alert_type'] == 'above' && currentRate.rate >= alert['target_rate']) {
            shouldNotify = true;
          } else if (alert['alert_type'] == 'below' && currentRate.rate <= alert['target_rate']) {
            shouldNotify = true;
          }

          if (shouldNotify) {
            _notificationService.showNotification(
              'تنبيه السعر!',
              'وصل ${currentRate.code} إلى ${currentRate.rate.toStringAsFixed(0)} ل.س',
            );
            await _dbHelper.updateAlertStatus(alert['id'], false);
          }
        }
      }
    }
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
      'USD': '🇺🇸', 'EUR': '🇪🇺', 'GBP': '🇬🇧', 'TRY': '🇹🇷',
      'SAR': '🇸🇦', 'AED': '🇦🇪', 'JPY': '🇯🇵', 'CNY': '🇨🇳',
      'SYP': '🇸🇾', 'GOLD': '🟡', 'SILVER': '⚪', 'EGP': '🇪🇬',
    };
    if (specialFlags.containsKey(code)) return specialFlags[code]!;
    try {
      if (code.length >= 2) {
        String countryCode = code.substring(0, 2);
        return countryCode.toUpperCase().replaceAllMapped(RegExp(r'[A-Z]'),
            (match) => String.fromCharCode(match.group(0)!.codeUnitAt(0) + 127397));
      }
    } catch (e) { return '🏳️'; }
    return '🏳️';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

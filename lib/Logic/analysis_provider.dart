import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/remote/currency_service.dart';
import '../data/remote/prediction_service.dart';
import '../data/models/usd_syp_prediction.dart';
import '../data/local/database_helper.dart';

class AnalysisProvider extends ChangeNotifier {
  final CurrencyService _service = CurrencyService();
  final PredictionService _predictionService = PredictionService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String _selectedPeriod = 'Month';
  String _selectedCurrency = 'USD';
  List<FlSpot> _chartData = [];
  List<DateTime> _chartTimestamps = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  double _currentPrice = 0.0;
  double _min = 0.0;
  double _max = 0.0;
  double _average = 0.0;
  double? _predictedPrice;
  String? _dataMessage;

  String get selectedPeriod => _selectedPeriod;
  String get selectedCurrency => _selectedCurrency;
  List<FlSpot> get chartData => _chartData;
  List<DateTime> get chartTimestamps => _chartTimestamps;
  bool get isLoading => _isLoading;
  bool get hasChart => _chartData.length >= 2;
  bool get hasPrediction => _predictedPrice != null;
  double get currentPrice => _currentPrice;
  double get min => _min;
  double get max => _max;
  double get average => _average;
  double? get predictedPrice => _predictedPrice;
  String? get dataMessage => _dataMessage;

  Future<void> ensureLoaded() async {
    if (_hasLoaded) return;
    _hasLoaded = true;
    await loadData();
  }

  void setCurrency(String currency) {
    if (_selectedCurrency == currency) return;
    _selectedCurrency = currency;
    loadData();
  }

  void setPeriod(String period) {
    if (_selectedPeriod == period) return;
    _selectedPeriod = period;
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    _dataMessage = null;
    notifyListeners();

    try {
      if (_selectedCurrency == 'USD' && _selectedPeriod == 'Year') {
        final datasetHistory = await _predictionService.fetchYearHistory();
        _buildChartFromDataset(datasetHistory);
        _calculatePrediction();
        _isLoading = false;
        notifyListeners();
        return;
      }

      final apiResult = await _service.fetchLatestRates(all: true);
      await apiResult.fold(
        (failure) async {
          _dataMessage = failure.message;
          debugPrint('Analysis API Error: ${failure.message}');
        },
        (rates) async {
          final matches = rates.where((rate) => rate.code == _selectedCurrency);
          if (matches.isNotEmpty) {
            final current = matches.first;
            _currentPrice = current.rate;
            await _dbHelper.saveRates([current.toMap()]);
          }
        },
      );

      final history = await _dbHelper.getHistory(
        _selectedCurrency,
        _selectedPeriod,
      );
      _buildChartFromHistory(history);
      _calculatePrediction();
    } catch (e) {
      _dataMessage = e.toString();
      debugPrint('General Analysis Error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _buildChartFromDataset(List<UsdSypHistoryPoint> history) {
    _chartTimestamps = history.map((item) => item.date).toList();
    _chartData = List.generate(
      history.length,
      (index) => FlSpot(index.toDouble(), history[index].rate),
    );
    _currentPrice = history.last.rate;
    _calculateStats(_chartData);
  }

  void _calculatePrediction() {
    // Predictions are provided only by the Backend. A generic local forecast
    // would mix regular rate analysis with the dedicated USD/SYP model.
    _predictedPrice = null;
  }

  void _buildChartFromHistory(List<Map<String, dynamic>> history) {
    final observations = <DateTime, double>{};
    for (final row in history) {
      final timestamp = DateTime.tryParse(row['timestamp']?.toString() ?? '');
      final rawRate = row['rate'];
      final rate = rawRate is num
          ? rawRate.toDouble()
          : double.tryParse(rawRate?.toString() ?? '');
      if (timestamp != null && rate != null && rate.isFinite && rate > 0) {
        observations[timestamp] = rate;
      }
    }

    final entries = observations.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    _chartTimestamps = entries.map((entry) => entry.key).toList();
    _chartData = List.generate(
      entries.length,
      (index) => FlSpot(index.toDouble(), entries[index].value),
    );

    if (_chartData.isNotEmpty) {
      _currentPrice = _chartData.last.y;
    }
    _calculateStats(_chartData);
  }

  void _calculateStats(List<FlSpot> spots) {
    if (spots.isEmpty) {
      _min = 0;
      _max = 0;
      _average = 0;
      return;
    }

    double sum = 0;
    _min = spots[0].y;
    _max = spots[0].y;

    for (var spot in spots) {
      sum += spot.y;
      if (spot.y < _min) _min = spot.y;
      if (spot.y > _max) _max = spot.y;
    }
    _average = sum / spots.length;
  }
}

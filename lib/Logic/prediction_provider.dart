import 'package:flutter/foundation.dart';
import '../data/models/usd_syp_prediction.dart';
import '../data/remote/prediction_service.dart';

enum PredictionStatus { initial, loading, success, error }

class PredictionProvider extends ChangeNotifier {
  PredictionProvider({UsdSypPredictionApi? api})
    : _api = api ?? PredictionService();

  final UsdSypPredictionApi _api;
  PredictionStatus _status = PredictionStatus.initial;
  UsdSypPrediction? _prediction;
  String? _errorMessage;

  PredictionStatus get status => _status;
  UsdSypPrediction? get prediction => _prediction;
  String? get errorMessage => _errorMessage;

  Future<void> loadPrediction() async {
    _status = PredictionStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _prediction = await _api.fetchNextDayPrediction();
      _status = PredictionStatus.success;
    } catch (error) {
      _prediction = null;
      _errorMessage = error is PredictionRequestException
          ? error.message
          : 'Unable to load USD/SYP prediction.';
      _status = PredictionStatus.error;
    }
    notifyListeners();
  }
}

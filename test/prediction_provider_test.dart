import 'package:flutter_test/flutter_test.dart';
import 'package:mpcurrencytracker/Logic/prediction_provider.dart';
import 'package:mpcurrencytracker/data/models/usd_syp_prediction.dart';
import 'package:mpcurrencytracker/data/remote/prediction_service.dart';

void main() {
  test('moves from loading to success with Backend data', () async {
    final provider = PredictionProvider(api: _SuccessfulApi());
    final states = <PredictionStatus>[];
    provider.addListener(() => states.add(provider.status));

    await provider.loadPrediction();

    expect(states, [PredictionStatus.loading, PredictionStatus.success]);
    expect(provider.prediction?.pair, 'USD/SYP');
    expect(provider.errorMessage, isNull);
  });

  test('moves from loading to error without fake prediction data', () async {
    final provider = PredictionProvider(api: _FailingApi());
    final states = <PredictionStatus>[];
    provider.addListener(() => states.add(provider.status));

    await provider.loadPrediction();

    expect(states, [PredictionStatus.loading, PredictionStatus.error]);
    expect(provider.prediction, isNull);
    expect(provider.errorMessage, contains('Backend unavailable'));
  });
}

class _SuccessfulApi implements UsdSypPredictionApi {
  @override
  Future<UsdSypPrediction> fetchNextDayPrediction() async => _prediction;
}

class _FailingApi implements UsdSypPredictionApi {
  @override
  Future<UsdSypPrediction> fetchNextDayPrediction() {
    throw const PredictionRequestException('Backend unavailable');
  }
}

final _prediction = UsdSypPrediction(
  pair: 'USD/SYP',
  currentRate: 130.0,
  predictedNextRate: 130.25,
  change: 0.25,
  changePercent: 0.1923,
  direction: 'up',
  asOfDate: DateTime(2026, 8, 26),
  predictionFor: 'next_business_day',
  modelType: 'linear_regression',
  source: 'Synthetic committee demo dataset',
);

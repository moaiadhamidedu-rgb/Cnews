import 'package:flutter_test/flutter_test.dart';
import 'package:mpcurrencytracker/data/models/usd_syp_prediction.dart';

void main() {
  test('parses every prediction response field', () {
    final prediction = UsdSypPrediction.fromJson(const {
      'pair': 'USD/SYP',
      'currentRate': 130.0,
      'predictedNextRate': 130.25,
      'change': 0.25,
      'changePercent': 0.1923,
      'direction': 'up',
      'asOfDate': '2026-08-26',
      'predictionFor': 'next_business_day',
      'modelType': 'linear_regression',
      'source': 'Synthetic committee demo dataset',
    });

    expect(prediction.pair, 'USD/SYP');
    expect(prediction.currentRate, 130.0);
    expect(prediction.predictedNextRate, 130.25);
    expect(prediction.change, 0.25);
    expect(prediction.changePercent, 0.1923);
    expect(prediction.direction, 'up');
    expect(prediction.asOfDate, DateTime(2026, 8, 26));
    expect(prediction.predictionFor, 'next_business_day');
    expect(prediction.modelType, 'linear_regression');
    expect(prediction.source, 'Synthetic committee demo dataset');
  });

  test('rejects non-positive and non-finite rates', () {
    expect(
      () => UsdSypPrediction.fromJson(const {
        'pair': 'USD/SYP',
        'currentRate': 0,
        'predictedNextRate': 'NaN',
        'change': 0,
        'changePercent': 0,
        'direction': 'unchanged',
        'asOfDate': '2026-08-26',
      }),
      throwsFormatException,
    );
  });
}

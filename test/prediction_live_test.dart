import 'package:flutter_test/flutter_test.dart';
import 'package:mpcurrencytracker/data/remote/prediction_service.dart';

const _runLiveTest = bool.fromEnvironment('RUN_LIVE_BACKEND_TEST');

void main() {
  test(
    'receives a real USD/SYP prediction from the configured Backend',
    () async {
      final prediction = await PredictionService().fetchNextDayPrediction();
      final history = await PredictionService().fetchYearHistory();

      expect(prediction.pair, 'USD/SYP');
      expect(prediction.currentRate, greaterThan(0));
      expect(prediction.predictedNextRate, greaterThan(0));
      expect(history.length, greaterThan(200));
      expect(history.last.date, prediction.asOfDate);
      // ignore: avoid_print
      print(
        'LIVE_RESPONSE pair=${prediction.pair} '
        'currentRate=${prediction.currentRate} '
        'predictedNextRate=${prediction.predictedNextRate} '
        'change=${prediction.change} '
        'changePercent=${prediction.changePercent} '
        'direction=${prediction.direction} '
        'asOfDate=${prediction.asOfDate.toIso8601String().split("T").first} '
        'predictionFor=${prediction.predictionFor} '
        'modelType=${prediction.modelType} source=${prediction.source}',
      );
    },
    skip: !_runLiveTest,
  );
}

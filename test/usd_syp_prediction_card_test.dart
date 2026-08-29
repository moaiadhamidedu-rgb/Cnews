import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpcurrencytracker/Logic/prediction_provider.dart';
import 'package:mpcurrencytracker/data/models/usd_syp_prediction.dart';
import 'package:mpcurrencytracker/data/remote/prediction_service.dart';
import 'package:mpcurrencytracker/ui/widgets/usd_syp_prediction_card.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('shows Backend prediction values in the success state', (
    tester,
  ) async {
    final provider = PredictionProvider(api: _SuccessfulApi());
    await provider.loadPrediction();

    await tester.pumpWidget(_app(provider));

    expect(find.text('Next USD outlook'), findsOneWidget);
    expect(
      find.text('Next-business-day estimate using demo data'),
      findsNothing,
    );
    expect(find.text('130.00'), findsOneWidget);
    expect(find.text('130.25'), findsOneWidget);
    expect(find.text('Expected increase'), findsOneWidget);
    final increaseLabel = tester.widget<Text>(find.text('Expected increase'));
    expect(increaseLabel.style?.color, Colors.red.shade700);
    expect(find.textContaining('2026-08-26'), findsOneWidget);
    expect(find.textContaining('Source:'), findsNothing);
    expect(find.textContaining('synthetic'), findsNothing);
  });

  testWidgets('shows retry and no fake values in the error state', (
    tester,
  ) async {
    final provider = PredictionProvider(api: _FailingApi());
    await provider.loadPrediction();

    await tester.pumpWidget(_app(provider));

    expect(
      find.text('We could not load the USD/SYP prediction from the server.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('0.0'), findsNothing);
  });

  testWidgets('uses green for an expected USD decrease', (tester) async {
    final provider = PredictionProvider(api: _DecreasingApi());
    await provider.loadPrediction();

    await tester.pumpWidget(_app(provider));

    final decreaseLabel = tester.widget<Text>(find.text('Expected decrease'));
    expect(decreaseLabel.style?.color, Colors.green.shade700);
  });
}

Widget _app(PredictionProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: const MaterialApp(
      locale: Locale('en'),
      home: Scaffold(body: UsdSypPredictionCard()),
    ),
  );
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

class _DecreasingApi implements UsdSypPredictionApi {
  @override
  Future<UsdSypPrediction> fetchNextDayPrediction() async => _downPrediction;
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

final _downPrediction = UsdSypPrediction(
  pair: 'USD/SYP',
  currentRate: 131.0,
  predictedNextRate: 130.5,
  change: -0.5,
  changePercent: -0.3817,
  direction: 'down',
  asOfDate: DateTime(2026, 8, 29),
  predictionFor: 'next_business_day',
  modelType: 'linear_regression',
  source: '',
);

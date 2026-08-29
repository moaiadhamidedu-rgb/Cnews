import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpcurrencytracker/Logic/prediction_provider.dart';
import 'package:mpcurrencytracker/data/models/usd_syp_prediction.dart';
import 'package:mpcurrencytracker/data/remote/prediction_service.dart';
import 'package:mpcurrencytracker/ui/widgets/usd_syp_prediction_card.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('USD/SYP card shows loading without placeholder rates', (
    tester,
  ) async {
    final provider = PredictionProvider(api: _PendingApi());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(
          locale: Locale('en'),
          home: Scaffold(body: UsdSypPredictionCard()),
        ),
      ),
    );
    unawaited(provider.loadPrediction());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.text('Loading USD/SYP prediction from the server...'),
      findsOneWidget,
    );
    expect(find.text('0.0'), findsNothing);
  });
}

class _PendingApi implements UsdSypPredictionApi {
  @override
  Future<UsdSypPrediction> fetchNextDayPrediction() =>
      Completer<UsdSypPrediction>().future;
}

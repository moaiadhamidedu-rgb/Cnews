import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpcurrencytracker/data/remote/prediction_service.dart';

void main() {
  const responseJson = {
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
  };

  test('parses a successful Backend prediction', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://backend.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/api/predictions/usd-syp/next-day');
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: responseJson,
            ),
          );
        },
      ),
    );

    final prediction = await PredictionService(
      dio: dio,
    ).fetchNextDayPrediction();

    expect(prediction.pair, 'USD/SYP');
    expect(prediction.currentRate, 130.0);
    expect(prediction.predictedNextRate, 130.25);
    expect(prediction.direction, 'up');
    expect(prediction.asOfDate, DateTime(2026, 8, 26));
  });

  test('throws a clear exception when the Backend request fails', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://backend.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 502,
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      ),
    );

    expect(
      PredictionService(dio: dio).fetchNextDayPrediction(),
      throwsA(
        isA<PredictionRequestException>().having(
          (error) => error.message,
          'message',
          contains('HTTP 502'),
        ),
      ),
    );
  });

  test('parses ordered USD/SYP year history from the Backend', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://backend.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/api/predictions/usd-syp/history');
          expect(options.queryParameters['period'], 'year');
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: const {
                'pair': 'USD/SYP',
                'period': 'year',
                'observations': [
                  {'date': '2026-08-28', 'rate': 130.0},
                  {'date': '2025-08-28', 'rate': 121.0},
                ],
              },
            ),
          );
        },
      ),
    );

    final history = await PredictionService(dio: dio).fetchYearHistory();

    expect(history.map((item) => item.date), [
      DateTime(2025, 8, 28),
      DateTime(2026, 8, 28),
    ]);
    expect(history.map((item) => item.rate), [121.0, 130.0]);
  });
}

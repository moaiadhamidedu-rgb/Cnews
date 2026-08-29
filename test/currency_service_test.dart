import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpcurrencytracker/data/remote/currency_service.dart';

void main() {
  test('maps Backend rates and keeps the priority order', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://backend.test/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/rates');
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'base': 'SYP',
                'denomination': 'new',
                'updatedAt': '2026-08-26T13:01:41.482Z',
                'rates': [
                  {
                    'currency': 'AUD',
                    'buy': 93.79,
                    'sell': 95.09,
                    'status': 'fresh',
                    'confidence': 'medium',
                  },
                  {
                    'currency': 'EUR',
                    'buy': 152.6,
                    'sell': 154.4,
                    'status': 'fresh',
                    'confidence': 'medium',
                  },
                  {
                    'currency': 'USD',
                    'buy': 132.0,
                    'sell': 132.5,
                    'status': 'fresh',
                    'confidence': 'medium',
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final result = await CurrencyService(dio: dio).fetchLatestRates(all: true);

    result.fold((failure) => fail(failure.message), (rates) {
      expect(rates, hasLength(3));
      expect(rates.map((rate) => rate.code), ['USD', 'EUR', 'AUD']);
      expect(rates.first.rate, 132.25);
      expect(rates.first.buy, 132.0);
      expect(rates.first.sell, 132.5);
      expect(rates.first.timestamp, DateTime.parse('2026-08-26T13:01:41.482Z'));
    });
  });

  test('returns only priority currencies when all is false', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'base': 'SYP',
                'updatedAt': '2026-08-26T13:01:41.482Z',
                'rates': [
                  {'currency': 'AUD', 'buy': 93.0, 'sell': 95.0},
                  {'currency': 'USD', 'buy': 132.0, 'sell': 132.5},
                ],
              },
            ),
          );
        },
      ),
    );

    final result = await CurrencyService(dio: dio).fetchLatestRates();

    result.fold((failure) => fail(failure.message), (rates) {
      expect(rates.single.code, 'USD');
      expect(rates.single.rate, 132.25);
    });
  });
}

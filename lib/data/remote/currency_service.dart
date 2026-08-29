import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/errors/failures.dart';
import '../models/currency_rate.dart';

class CurrencyService {
  CurrencyService({Dio? dio}) : _dio = dio ?? _createDio();

  final ApiClient _apiClient = ApiClient(http.Client());
  final Dio _dio;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Read the current value for every request so a URL changed from the
          // settings screen takes effect without restarting the application.
          options.baseUrl = ApiConfig.baseUrl;
          handler.next(options);
        },
      ),
    );
    return dio;
  }

  Future<Either<Failure, List<CurrencyRate>>> fetchLatestRates({
    bool all = false,
  }) async {
    const priorityOrder = ['USD', 'EUR', 'TRY', 'SAR', 'AED', 'JOD', 'EGP'];

    try {
      final response = await _dio.get<dynamic>('/rates');

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return const Left(ParsingFailure('استجابة أسعار العملات غير صالحة'));
      }

      if (data['success'] != true || data['base'] != 'SYP') {
        return const Left(ParsingFailure('استجابة الـBackend غير صالحة'));
      }

      final rawRates = data['rates'];

      if (rawRates is! List || rawRates.isEmpty) {
        return const Left(
          ParsingFailure('لم يعرض الـBackend أسعار عملات حالية'),
        );
      }

      final responseTimestamp = _parseTimestamp(data['updatedAt']);
      final ratesByCode = <String, CurrencyRate>{};

      for (final rawRate in rawRates) {
        if (rawRate is! Map) continue;
        final item = Map<String, dynamic>.from(rawRate);
        final code = item['currency']?.toString().trim().toUpperCase();
        if (code == null || code.isEmpty || code == 'SYP') continue;
        if (!all && !priorityOrder.contains(code)) continue;

        final buy = _toDouble(item['buy']);
        final sell = _toDouble(item['sell']);
        final mid =
            _toDouble(item['mid']) ??
            (buy != null && sell != null ? (buy + sell) / 2 : buy ?? sell);
        if (mid == null) continue;

        final rate = CurrencyRate(
          code: code,
          rate: mid,
          buy: buy,
          sell: sell,
          timestamp: responseTimestamp ?? DateTime.now().toUtc(),
        );

        final existing = ratesByCode[code];
        if (existing == null || rate.timestamp.isAfter(existing.timestamp)) {
          ratesByCode[code] = rate;
        }
      }

      final rates = ratesByCode.values.toList();
      if (rates.isEmpty) {
        return const Left(
          ParsingFailure('تعذر قراءة أسعار العملات من الـBackend'),
        );
      }

      rates.sort((a, b) {
        final aPriority = priorityOrder.indexOf(a.code);
        final bPriority = priorityOrder.indexOf(b.code);
        if (aPriority >= 0 && bPriority >= 0) {
          return aPriority.compareTo(bPriority);
        }
        if (aPriority >= 0) return -1;
        if (bPriority >= 0) return 1;
        return a.code.compareTo(b.code);
      });

      return Right(rates);
    } on DioException catch (error) {
      if (error.response?.statusCode == 429) {
        return const Left(
          ServerFailure(
            'تم بلوغ حد طلبات الـBackend، سيتم عرض آخر أسعار محفوظة',
          ),
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return const Left(NetworkFailure());
      }
      final statusCode = error.response?.statusCode;
      return Left(
        ServerFailure(
          statusCode == null
              ? 'تعذر الاتصال بالـBackend'
              : 'خطأ من الـBackend: $statusCode',
        ),
      );
    } catch (error) {
      return Left(ParsingFailure(error.toString()));
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  Future<Either<Failure, Map<String, dynamic>>> fetchMetalPrice(
    String symbol,
  ) async {
    const String goldApiKey = 'goldapi-1c66afa62f83cec19626422be95a9a4f-io';
    final String url = 'https://www.goldapi.io/api/$symbol/USD';

    final result = await _apiClient.get(
      url,
      headers: {'x-access-token': goldApiKey},
    );

    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data as Map<String, dynamic>),
    );
  }

  Future<Either<Failure, Map<String, dynamic>>> fetchCryptoPrices() async {
    const String url =
        'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,binancecoin,cardano,solana&vs_currencies=usd,eur';
    final result = await _apiClient.get(url);
    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data as Map<String, dynamic>),
    );
  }
}

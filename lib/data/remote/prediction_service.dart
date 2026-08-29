import 'package:dio/dio.dart';
import '../../core/network/api_config.dart';
import '../models/usd_syp_prediction.dart';

abstract interface class UsdSypPredictionApi {
  Future<UsdSypPrediction> fetchNextDayPrediction();
}

class PredictionService implements UsdSypPredictionApi {
  PredictionService({Dio? dio}) : _dio = dio ?? _createDio();

  final Dio _dio;

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.serverOrigin,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'Accept': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.baseUrl = ApiConfig.serverOrigin;
          handler.next(options);
        },
      ),
    );
    return dio;
  }

  @override
  Future<UsdSypPrediction> fetchNextDayPrediction() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/predictions/usd-syp/next-day',
      );
      final data = response.data;
      if (data is! Map) {
        throw const FormatException('Prediction response is not an object');
      }
      return UsdSypPrediction.fromJson(Map<String, dynamic>.from(data));
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      throw PredictionRequestException(
        statusCode == null
            ? 'Unable to connect to the prediction server.'
            : 'Prediction server returned HTTP $statusCode.',
      );
    } on FormatException catch (error) {
      throw PredictionRequestException(error.message);
    }
  }

  Future<List<UsdSypHistoryPoint>> fetchYearHistory() async {
    try {
      final response = await _dio.get<dynamic>(
        '/api/predictions/usd-syp/history',
        queryParameters: const {'period': 'year'},
      );
      final data = response.data;
      if (data is! Map || data['pair'] != 'USD/SYP') {
        throw const FormatException('History response is not valid');
      }
      final rawObservations = data['observations'];
      if (rawObservations is! List || rawObservations.length < 2) {
        throw const FormatException('History response has insufficient data');
      }
      final observations =
          rawObservations
              .whereType<Map>()
              .map(
                (item) => UsdSypHistoryPoint.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
            ..sort((left, right) => left.date.compareTo(right.date));
      if (observations.length < 2) {
        throw const FormatException('History response has insufficient data');
      }
      return observations;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      throw PredictionRequestException(
        statusCode == null
            ? 'Unable to connect to the history server.'
            : 'History server returned HTTP $statusCode.',
      );
    } on FormatException catch (error) {
      throw PredictionRequestException(error.message);
    }
  }
}

class PredictionRequestException implements Exception {
  const PredictionRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

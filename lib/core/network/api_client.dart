import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

class ApiClient {
  final http.Client client;

  ApiClient(this.client);

  final Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'application/json',
  };

  Future<Either<Failure, dynamic>> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await client
          .get(Uri.parse(url), headers: headers ?? _defaultHeaders)
          .timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } on SocketException {
      return const Left(NetworkFailure());
    } on http.ClientException {
      return const Left(ServerFailure('فشل الاتصال بالخادم'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Either<Failure, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return Right(json.decode(response.body));
      } catch (e) {
        return const Left(ParsingFailure());
      }
    } else {
      return Left(ServerFailure('خطأ في الخادم: ${response.statusCode}'));
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dartz/dartz.dart';
import '../../core/network/api_client.dart';
import '../../core/errors/failures.dart';
import '../models/currency_rate.dart';

class CurrencyService {
  final ApiClient _apiClient = ApiClient(http.Client());
  
  final String _apiKey = 'd1d10d23936cabd93fa25507';
  final String _baseUrl = 'https://v6.exchangerate-api.com/v6';

  Future<Either<Failure, List<CurrencyRate>>> fetchLatestRates({bool all = false}) async {
    // We use USD as base to get the rate of SYP easily
    final String url = '$_baseUrl/$_apiKey/latest/USD';

    final result = await _apiClient.get(url);

    return result.fold(
      (failure) => Left(failure),
      (data) {
        try {
          if (data['result'] == 'success') {
            final Map<String, dynamic> rates = data['conversion_rates'];
            final double sypRate = (rates['SYP'] as num).toDouble();
            
            // Get timestamp from API
            final int updateUnix = data['time_last_update_unix'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
            final DateTime apiTimestamp = DateTime.fromMillisecondsSinceEpoch(updateUnix * 1000);

            List<CurrencyRate> currencyList = [];
            List<String> priorityOrder = ['USD', 'EUR', 'TRY', 'SAR', 'AED', 'JOD', 'EGP'];
            
            rates.forEach((code, value) {
              if (all || priorityOrder.contains(code)) {
                if (code != 'SYP') {
                  double rateInSyp = sypRate / (value as num).toDouble();
                  
                  currencyList.add(CurrencyRate(
                    code: code,
                    rate: rateInSyp,
                    buy: rateInSyp * 0.99,
                    sell: rateInSyp * 1.01,
                    timestamp: apiTimestamp,
                  ));
                }
              }
            });

            if (all) {
              // Separate priority currencies from the rest for the full list as well
              List<CurrencyRate> priorityList = [];
              List<CurrencyRate> othersList = [];
              
              for (var rate in currencyList) {
                if (priorityOrder.contains(rate.code)) {
                  priorityList.add(rate);
                } else {
                  othersList.add(rate);
                }
              }
              
              // Sort priority by our specific order
              priorityList.sort((a, b) => priorityOrder.indexOf(a.code).compareTo(priorityOrder.indexOf(b.code)));
              // Sort others alphabetically
              othersList.sort((a, b) => a.code.compareTo(b.code));
              
              return Right([...priorityList, ...othersList]);
            } else {
              // Sort main cards by our specific order
              currencyList.sort((a, b) => priorityOrder.indexOf(a.code).compareTo(priorityOrder.indexOf(b.code)));
              return Right(currencyList);
            }
          } else {
            return const Left(ParsingFailure('API Error: Request was not successful'));
          }
        } catch (e) {
          return Left(ParsingFailure(e.toString()));
        }
      },
    );
  }

  Future<Either<Failure, Map<String, dynamic>>> fetchMetalPrice(String symbol) async {
    const String goldApiKey = 'goldapi-1c66afa62f83cec19626422be95a9a4f-io';
    final String url = 'https://www.goldapi.io/api/$symbol/USD';
    
    final result = await _apiClient.get(url, headers: {'x-access-token': goldApiKey});
    
    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data as Map<String, dynamic>),
    );
  }

  Future<Either<Failure, Map<String, dynamic>>> fetchCryptoPrices() async {
    const String url = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,binancecoin,cardano,solana&vs_currencies=usd,eur';
    final result = await _apiClient.get(url);
    return result.fold(
      (failure) => Left(failure),
      (data) => Right(data as Map<String, dynamic>),
    );
  }
}

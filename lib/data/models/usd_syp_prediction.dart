class UsdSypPrediction {
  const UsdSypPrediction({
    required this.pair,
    required this.currentRate,
    required this.predictedNextRate,
    required this.change,
    required this.changePercent,
    required this.direction,
    required this.asOfDate,
    required this.predictionFor,
    required this.modelType,
    required this.source,
  });

  final String pair;
  final double currentRate;
  final double predictedNextRate;
  final double change;
  final double changePercent;
  final String direction;
  final DateTime asOfDate;
  final String predictionFor;
  final String modelType;
  final String source;

  factory UsdSypPrediction.fromJson(Map<String, dynamic> json) {
    final pair = json['pair']?.toString();
    final direction = json['direction']?.toString();
    final asOfDate = DateTime.tryParse(json['asOfDate']?.toString() ?? '');
    final currentRate = _toDouble(json['currentRate']);
    final predictedNextRate = _toDouble(json['predictedNextRate']);
    final change = _toDouble(json['change']);
    final changePercent = _toDouble(json['changePercent']);

    if (pair != 'USD/SYP' ||
        !const {'up', 'down', 'unchanged'}.contains(direction) ||
        asOfDate == null ||
        currentRate == null ||
        currentRate <= 0 ||
        predictedNextRate == null ||
        predictedNextRate <= 0 ||
        change == null ||
        changePercent == null) {
      throw const FormatException('Invalid USD/SYP prediction response');
    }

    return UsdSypPrediction(
      pair: pair!,
      currentRate: currentRate,
      predictedNextRate: predictedNextRate,
      change: change,
      changePercent: changePercent,
      direction: direction!,
      asOfDate: asOfDate,
      predictionFor: json['predictionFor']?.toString() ?? '',
      modelType: json['modelType']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
    );
  }

  static double? _toDouble(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    return parsed != null && parsed.isFinite ? parsed : null;
  }
}

class UsdSypHistoryPoint {
  const UsdSypHistoryPoint({required this.date, required this.rate});

  final DateTime date;
  final double rate;

  factory UsdSypHistoryPoint.fromJson(Map<String, dynamic> json) {
    final date = DateTime.tryParse(json['date']?.toString() ?? '');
    final rate = UsdSypPrediction._toDouble(json['rate']);
    if (date == null || rate == null || rate <= 0) {
      throw const FormatException('Invalid USD/SYP history observation');
    }
    return UsdSypHistoryPoint(date: date, rate: rate);
  }
}

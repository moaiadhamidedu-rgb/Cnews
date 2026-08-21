class CurrencyRate {
  final String code;
  final double rate; // Default rate (usually sell or average)
  final double? buy;
  final double? sell;
  final DateTime timestamp;

  CurrencyRate({
    required this.code,
    required this.rate,
    this.buy,
    this.sell,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'currency_pair': code,
      'rate': rate,
      'buy': buy,
      'sell': sell,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CurrencyRate.fromMap(Map<String, dynamic> map) {
    return CurrencyRate(
      code: map['currency_pair'],
      rate: map['rate'] ?? 0.0,
      buy: map['buy'],
      sell: map['sell'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

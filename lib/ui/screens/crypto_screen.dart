import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../Logic/crypto_provider.dart';

class CryptoScreen extends StatefulWidget {
  const CryptoScreen({super.key});

  @override
  State<CryptoScreen> createState() => _CryptoScreenState();
}

class _CryptoScreenState extends State<CryptoScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cryptoLogic = Provider.of<CryptoProvider>(context);
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'سوق الكريبتو' : 'Crypto Market'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: cryptoLogic.fetchPrices,
        child: cryptoLogic.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildCryptoCard(
                    'Bitcoin',
                    'البيتكوين',
                    'BTC',
                    Icons.currency_bitcoin_rounded,
                    Colors.orange.shade700,
                    cryptoLogic.prices['bitcoin'],
                    theme,
                    isArabic,
                  ),
                  _buildCryptoCard(
                    'Ethereum',
                    'الإيثيريوم',
                    'ETH',
                    Icons.token_rounded,
                    Colors.indigo.shade400,
                    cryptoLogic.prices['ethereum'],
                    theme,
                    isArabic,
                  ),
                  _buildCryptoCard(
                    'Binance Coin',
                    'بينانس كوين',
                    'BNB',
                    Icons.grid_view_rounded,
                    Colors.yellow.shade700,
                    cryptoLogic.prices['binancecoin'],
                    theme,
                    isArabic,
                  ),
                  _buildCryptoCard(
                    'Solana',
                    'سولانا',
                    'SOL',
                    Icons.wb_sunny_rounded,
                    Colors.tealAccent.shade700,
                    cryptoLogic.prices['solana'],
                    theme,
                    isArabic,
                  ),
                  _buildCryptoCard(
                    'Cardano',
                    'كاردانو',
                    'ADA',
                    Icons.hub_rounded,
                    Colors.blue.shade800,
                    cryptoLogic.prices['cardano'],
                    theme,
                    isArabic,
                  ),
                  const SizedBox(height: 50),
                  Center(
                    child: Text(
                      isArabic ? 'اسحب للأسفل للتحديث' : 'Pull down to refresh',
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCryptoCard(
    String nameEn,
    String nameAr,
    String symbol,
    IconData icon,
    Color accentColor,
    Map<String, dynamic>? data,
    ThemeData theme,
    bool isArabic,
  ) {
    if (data == null || data.isEmpty) return const SizedBox();

    double usd = (data['usd'] as num).toDouble();
    double eur = (data['eur'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? nameAr : nameEn,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          symbol,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _priceRow(
                    'USD',
                    '\$${NumberFormat('#,###.##').format(usd)}',
                    accentColor,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _priceRow(
                    'EUR',
                    '€${NumberFormat('#,###.##').format(eur)}',
                    accentColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
      ],
    );
  }
}

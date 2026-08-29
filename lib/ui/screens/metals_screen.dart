import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../Logic/metals_provider.dart';
import '../../Logic/home_provider.dart';
import '../../data/models/currency_rate.dart';

class MetalsScreen extends StatefulWidget {
  const MetalsScreen({super.key});

  @override
  State<MetalsScreen> createState() => _MetalsScreenState();
}

class _MetalsScreenState extends State<MetalsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final metalsLogic = Provider.of<MetalsProvider>(context);
    final homeLogic = Provider.of<HomeProvider>(context);
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Get USD to SYP rate
    final usdRate = homeLogic.topRates.isNotEmpty
        ? homeLogic.topRates
              .firstWhere(
                (r) => r.code == 'USD',
                orElse: () => CurrencyRate(
                  code: 'USD',
                  rate: 0,
                  timestamp: DateTime.now(),
                ),
              )
              .rate
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'بورصة المعادن' : 'Metal Exchange'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: metalsLogic.fetchPrices,
        child: metalsLogic.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildMetalCard(
                    'Gold',
                    isArabic ? 'الذهب العالمي' : 'Global Gold',
                    Icons.layers_rounded,
                    const Color(0xFFB49A67),
                    metalsLogic.prices['Gold'],
                    theme,
                    isArabic,
                  ),
                  _buildMetalCard(
                    'Silver',
                    isArabic ? 'الفضة النقية' : 'Pure Silver',
                    Icons.blur_on_rounded,
                    Colors.blueGrey.shade300,
                    metalsLogic.prices['Silver'],
                    theme,
                    isArabic,
                  ),
                  _buildMetalCard(
                    'Platinum',
                    isArabic ? 'البلاتين الملكي' : 'Royal Platinum',
                    Icons.diamond_rounded,
                    const Color(0xFFE5E4E2),
                    metalsLogic.prices['Platinum'],
                    theme,
                    isArabic,
                  ),
                  _buildLiraCard(
                    metalsLogic.prices['GoldLira'],
                    usdRate,
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

  Widget _buildMetalCard(
    String nameEn,
    String nameAr,
    IconData icon,
    Color accentColor,
    Map<String, dynamic>? data,
    ThemeData theme,
    bool isArabic,
  ) {
    if (data == null || data.isEmpty) return const SizedBox();

    double priceGram = data['price_gram_24k'] ?? 0.0;
    double priceOunce = data['price'] ?? 0.0;

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
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          isArabic ? 'المعادن النفيسة' : 'Precious Metals',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
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
                    isArabic ? 'سعر الأونصة العالمي' : 'Ounce Price',
                    '\$${NumberFormat('#,###.##').format(priceOunce)}',
                    accentColor,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _priceRow(
                    isArabic ? 'سعر الغرام (ع 24)' : 'Gram Price (24k)',
                    '\$${NumberFormat('#,###.##').format(priceGram)}',
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

  Widget _buildLiraCard(
    Map<String, dynamic>? data,
    double usdToSyp,
    ThemeData theme,
    bool isArabic,
  ) {
    if (data == null || data.isEmpty) return const SizedBox();

    final Color accentColor = const Color(0xFFD4AF37); // Gold color
    final double priceUsd = data['price'];
    final double priceSyp = priceUsd * usdToSyp;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.1),
            theme.cardTheme.color ?? Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'الليرة الذهب (8 غرام)' : 'Gold Lira (8g)',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: accentColor.darken(0.3),
                        ),
                      ),
                      Text(
                        isArabic ? 'عيار 22 - وزن 8 غرام' : '22k - weight 8g',
                        style: TextStyle(
                          color: Colors.grey.shade600,
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isArabic ? 'السعر بالدولار' : 'Price in USD',
                        style: TextStyle(
                          color: accentColor.darken(0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${NumberFormat('#,###.##').format(priceUsd)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          color: accentColor.darken(0.3),
                        ),
                      ),
                    ],
                  ),
                ),
                if (priceSyp > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isArabic ? 'السعر بالليرة' : 'Price in SYP',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${NumberFormat('#,###').format(priceSyp)} ل.س',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: color.darken(0.2),
          ),
        ),
      ],
    );
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

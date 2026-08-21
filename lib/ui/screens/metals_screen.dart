import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../Logic/metals_provider.dart';

class MetalsScreen extends StatefulWidget {
  const MetalsScreen({super.key});

  @override
  State<MetalsScreen> createState() => _MetalsScreenState();
}

class _MetalsScreenState extends State<MetalsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final metalsLogic = Provider.of<MetalsProvider>(context);
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
                  isArabic
                ),
                _buildMetalCard(
                  'Silver', 
                  isArabic ? 'الفضة النقية' : 'Pure Silver', 
                  Icons.blur_on_rounded, 
                  Colors.blueGrey.shade300, 
                  metalsLogic.prices['Silver'], 
                  theme, 
                  isArabic
                ),
                _buildMetalCard(
                  'Platinum', 
                  isArabic ? 'البلاتين الملكي' : 'Royal Platinum', 
                  Icons.diamond_rounded, 
                  const Color(0xFFE5E4E2), 
                  metalsLogic.prices['Platinum'], 
                  theme, 
                  isArabic
                ),
                const SizedBox(height: 50),
                Center(
                  child: Text(
                    isArabic ? 'اسحب للأسفل للتحديث' : 'Pull down to refresh',
                    style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12),
                  ),
                )
              ],
            ),
      ),
    );
  }

  Widget _buildMetalCard(String nameEn, String nameAr, IconData icon, Color accentColor, Map<String, dynamic>? data, ThemeData theme, bool isArabic) {
    if (data == null || data.isEmpty) return const SizedBox();

    double priceGram = data['price_gram_24k'] ?? 0.0;
    double priceOunce = data['price'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
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
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          isArabic ? 'المعادن النفيسة' : 'Precious Metals',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
                    accentColor
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _priceRow(
                    isArabic ? 'سعر الغرام (ع 24)' : 'Gram Price (24k)', 
                    '\$${NumberFormat('#,###.##').format(priceGram)}',
                    accentColor
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
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 20,
            color: color.darken(0.2),
          )
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

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/currency_rate.dart';
import '../../data/local/settings_provider.dart';
import '../../Logic/home_provider.dart';
import '../../core/utils/export_service.dart';
import 'alerts_screen.dart';
import 'analysis_screen.dart';
import 'calculate_screen.dart';
import 'settings_screen.dart';
import 'news_screen.dart';
import 'metals_screen.dart';
import 'crypto_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalysisScreen(),
    const CalculateScreen(),
    const NewsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isArabic = settings.locale.languageCode == 'ar';

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.currency_exchange_rounded),
            label: isArabic ? 'العملات' : 'Currencies',
          ),
          NavigationDestination(
            icon: const Icon(Icons.analytics_rounded),
            label: isArabic ? 'تحليل' : 'Analysis',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calculate_rounded),
            label: isArabic ? 'حسابات' : 'Calculate',
          ),
          NavigationDestination(
            icon: const Icon(Icons.article_rounded),
            selectedIcon: const Icon(Icons.newspaper_rounded),
            label: isArabic ? 'أخبار' : 'News',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_rounded),
            label: isArabic ? 'الإعدادات' : 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  Timer? _carouselTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final homeLogic = Provider.of<HomeProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () => homeLogic.refreshRates(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: isTablet ? screenSize.height * 0.35 : 330,
              floating: false,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, const Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 20),
                      Text(
                        isArabic ? 'أخبار العملات' : 'Currency News',
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: isTablet ? 26 : 20, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic 
                          ? 'تحديث تلقائي خلال: ${_formatDuration(homeLogic.secondsRemaining)}' 
                          : 'Auto update in: ${_formatDuration(homeLogic.secondsRemaining)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    if (homeLogic.topRates.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${isArabic ? "آخر تحديث للأسعار:" : "Prices last update:"} ${DateFormat('HH:mm').format(homeLogic.topRates.first.timestamp)}',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: homeLogic.isLoadingTop 
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : homeLogic.topRates.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.white54),
                                    const SizedBox(height: 8),
                                    Text(isArabic ? 'لا توجد بيانات' : 'No data', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Expanded(
                                    child: PageView.builder(
                                      controller: _pageController,
                                      onPageChanged: (index) => setState(() => _currentPage = index),
                                      itemBuilder: (context, index) {
                                        final rate = homeLogic.topRates[index % homeLogic.topRates.length];
                                        return _buildGlassCard(rate, isArabic, homeLogic);
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(homeLogic.topRates.length, (index) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: (_currentPage % homeLogic.topRates.length) == index 
                                              ? theme.colorScheme.secondary 
                                              : Colors.white24,
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),
            if (homeLogic.isOffline)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.orange.shade100,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 16, color: Colors.orange.shade900),
                      const SizedBox(width: 8),
                      Text(
                        homeLogic.errorMessage != null 
                          ? (isArabic ? 'خطأ: ${homeLogic.errorMessage}' : 'Error: ${homeLogic.errorMessage}')
                          : (isArabic ? 'أنت تعمل في وضع الأوفلاين' : 'You are working offline'), 
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MetalsScreen())),
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        isArabic ? 'أسعار المعادن' : 'Metal Prices',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CryptoScreen())),
                      icon: const Icon(Icons.currency_bitcoin_rounded),
                      label: Text(
                        isArabic ? 'أسعار الكريبتو' : 'Crypto Prices',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final rates = homeLogic.allRates.isNotEmpty ? homeLogic.allRates : homeLogic.topRates;
                    if (index >= rates.length) return null;
                    final rate = rates[index];
                    return _buildCurrencyItem(rate, isArabic, homeLogic);
                  },
                  childCount: homeLogic.allRates.isNotEmpty ? homeLogic.allRates.length : homeLogic.topRates.length,
                ),
              ),
            ),
            
            if (homeLogic.allRates.isEmpty && homeLogic.topRates.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      Icon(Icons.currency_exchange, size: 60, color: Colors.grey.shade300),
                      const SizedBox(height: 10),
                      Text(
                        isArabic ? 'جاري تحميل أسعار العملات...' : 'Loading currency rates...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'alerts',
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsScreen())),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.notifications_active_rounded),
        label: Text(isArabic ? 'التنبيهات' : 'Alerts'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildGlassCard(CurrencyRate rate, bool isArabic, HomeProvider logic) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            logic.getCurrencyName(rate.code, isArabic),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${rate.code} / ${isArabic ? "ليرة سورية" : "SYP"}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        logic.getCurrencyEmoji(rate.code),
                        style: const TextStyle(fontSize: 42),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(
                    color: Colors.white.withOpacity(0.1),
                    height: 1,
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isArabic ? 'مبيع' : 'Sell',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat('#,###').format(rate.sell ?? rate.rate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isArabic ? 'شراء' : 'Buy',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              NumberFormat('#,###').format(rate.buy ?? rate.rate),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyItem(CurrencyRate rate, bool isArabic, HomeProvider logic) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onLongPress: () => ExportService.shareRate(rate.code, rate.rate, isArabic),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(logic.getCurrencyEmoji(rate.code), style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rate.code,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      Text(
                        isArabic ? 'الليرة السورية' : 'Syrian Lira',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat('#,###').format(rate.rate)}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${isArabic ? "شراء" : "B"}: ${NumberFormat('#,###').format(rate.buy ?? 0)}',
                          style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isArabic ? "مبيع" : "S"}: ${NumberFormat('#,###').format(rate.sell ?? 0)}',
                          style: TextStyle(fontSize: 10, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

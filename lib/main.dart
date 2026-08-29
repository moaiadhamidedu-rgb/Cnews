import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:async';

import 'data/remote/currency_service.dart';
import 'data/local/database_helper.dart';
import 'data/local/notification_service.dart';
import 'data/local/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_config.dart';
import 'Logic/home_provider.dart';
import 'Logic/analysis_provider.dart';
import 'Logic/calculate_provider.dart';
import 'Logic/alerts_provider.dart';
import 'Logic/metals_provider.dart';
import 'Logic/news_provider.dart';
import 'Logic/crypto_provider.dart';
import 'Logic/prediction_provider.dart';
import 'data/models/currency_rate.dart';
import 'ui/screens/splash_screen.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await ApiConfig.initialize();
    final currencyService = CurrencyService();
    final dbHelper = DatabaseHelper();
    final notificationService = NotificationService();
    await notificationService.init(requestPermission: false);

    try {
      final result = await currencyService.fetchLatestRates();

      await result.fold(
        (failure) async {
          debugPrint('Background task failure: ${failure.message}');
        },
        (rates) async {
          final alerts = await dbHelper.queryAllAlerts();

          for (var alert in alerts) {
            if (alert['is_active'] == 1) {
              final currentRate = rates.firstWhere(
                (r) => r.code == alert['currency_pair'],
                orElse: () =>
                    CurrencyRate(code: '', rate: 0, timestamp: DateTime.now()),
              );

              if (currentRate.code.isNotEmpty) {
                bool shouldNotify = false;
                if (alert['alert_type'] == 'above' &&
                    currentRate.rate >= alert['target_rate']) {
                  shouldNotify = true;
                } else if (alert['alert_type'] == 'below' &&
                    currentRate.rate <= alert['target_rate']) {
                  shouldNotify = true;
                }

                if (shouldNotify) {
                  await notificationService.showNotification(
                    'تنبيه تلقائي: سعر العملة',
                    'تحديث في الخلفية: وصل ${currentRate.code} إلى ${currentRate.rate.toStringAsFixed(0)} ل.س',
                  );
                  await dbHelper.updateAlertStatus(alert['id'], false);
                }
              }
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Background task error: $e');
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  await Workmanager().registerPeriodicTask(
    "1",
    "fetch_currency_task",
    frequency: const Duration(hours: 6),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()..init()),
        ChangeNotifierProvider(create: (_) => AnalysisProvider()),
        ChangeNotifierProvider(
          create: (_) => CalculateProvider()..loadWallet(),
        ),
        ChangeNotifierProvider(create: (_) => AlertsProvider()..loadAlerts()),
        ChangeNotifierProvider(create: (_) => MetalsProvider()..fetchPrices()),
        ChangeNotifierProvider(create: (_) => NewsProvider()..loadNews()),
        ChangeNotifierProvider(create: (_) => CryptoProvider()..fetchPrices()),
        ChangeNotifierProvider(
          create: (_) => PredictionProvider()..loadPrediction(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'CNews',
      debugShowCheckedModeBanner: false,
      locale: settings.locale,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      themeMode: settings.themeMode,
      theme: AppThemes.build(settings.colorTheme, Brightness.light),
      darkTheme: AppThemes.build(settings.colorTheme, Brightness.dark),
      home: const SplashScreen(),
    );
  }
}

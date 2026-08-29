import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/local/settings_provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  static const _appShareChannel = MethodChannel(
    'com.example.mpcurrencytracker/app_share',
  );
  bool _isPreparingShare = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> _shareApp(bool isArabic) async {
    if (_isPreparingShare) return;
    final message = isArabic
        ? 'تطبيق أخبار العملات السوري CNews\nأسعار مباشرة، تنبيهات ذكية، تحليل وتوقع لسعر الدولار.\nإعداد: مؤيد حميد'
        : 'CNews — Syrian currency rates, smart alerts, analysis, and USD outlook.\nBy Moayad Hameed';

    setState(() => _isPreparingShare = true);
    try {
      if (Platform.isAndroid) {
        final apkPath = await _appShareChannel.invokeMethod<String>(
          'prepareInstalledApk',
        );
        if (apkPath == null || apkPath.isEmpty) {
          throw const FileSystemException('The installed APK was not prepared');
        }
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile(
                apkPath,
                mimeType: 'application/vnd.android.package-archive',
              ),
            ],
            fileNameOverrides: const ['CNews.apk'],
            text: message,
            subject: isArabic ? 'تطبيق CNews' : 'CNews App',
          ),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            text: message,
            subject: isArabic ? 'تطبيق CNews' : 'CNews App',
          ),
        );
      }
    } catch (_) {
      try {
        await SharePlus.instance.share(ShareParams(text: message));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? 'تعذرت المشاركة حالياً. حاول مرة أخرى.'
                  : 'Sharing is unavailable right now. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPreparingShare = false);
    }
  }

  Future<void> _showPrivacyDialog(bool isArabic) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.shield_outlined),
        title: Text(isArabic ? 'الخصوصية والبيانات' : 'Privacy & data'),
        content: Text(
          isArabic
              ? '• لا يتطلب التطبيق إنشاء حساب شخصي.\n\n'
                    '• تُحفظ المحفظة والتنبيهات والتفضيلات محلياً على جهازك.\n\n'
                    '• يُستخدم الإنترنت فقط لجلب الأسعار والأخبار والتوقعات.'
              : '• The app does not require a personal account.\n\n'
                    '• Your wallet, alerts, and preferences stay on your device.\n\n'
                    '• Internet access is used only for rates, news, and predictions.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'حسناً' : 'Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isArabic = settings.locale.languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'الإعدادات' : 'Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader(
            isArabic ? 'المظهر واللغة' : 'Appearance & Language',
            theme,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              isArabic ? 'الثيم اللوني' : 'Color theme',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 126,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: AppColorTheme.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final colorTheme = AppColorTheme.values[index];
                return _ThemeChoiceCard(
                  colorTheme: colorTheme,
                  selected: settings.colorTheme == colorTheme,
                  isArabic: isArabic,
                  onTap: () => settings.setColorTheme(colorTheme),
                );
              },
            ),
          ),
          ListTile(
            leading: Icon(
              settings.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: Text(isArabic ? 'الوضع الليلي' : 'Dark Mode'),
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (value) => settings.toggleTheme(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(isArabic ? 'اللغة' : 'Language'),
            trailing: DropdownButton<String>(
              value: settings.locale.languageCode,
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('العربية')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (val) => val != null ? settings.setLocale(val) : null,
            ),
          ),
          const Divider(),
          _buildSectionHeader(
            isArabic ? 'الخصوصية والأمان' : 'Privacy & Security',
            theme,
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(isArabic ? 'الخصوصية والبيانات' : 'Privacy & data'),
            subtitle: Text(
              isArabic
                  ? 'تعرف على كيفية حماية بياناتك داخل التطبيق'
                  : 'See how your data is protected in the app',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showPrivacyDialog(isArabic),
          ),
          const Divider(),
          _buildSectionHeader(
            isArabic ? 'تواصل وتوثيق' : 'Connect & Credits',
            theme,
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: Text(isArabic ? 'مشاركة التطبيق' : 'Share App'),
            subtitle: Text(
              isArabic
                  ? 'أرسل ملف التطبيق مباشرةً'
                  : 'Send the app file directly',
            ),
            trailing: _isPreparingShare
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.ios_share_rounded),
            onTap: _isPreparingShare ? null : () => _shareApp(isArabic),
          ),
          ListTile(
            leading: const Icon(Icons.person_pin_rounded),
            title: Text(isArabic ? 'معلومات المشروع' : 'Project Info'),
            subtitle: Text(
              isArabic
                  ? 'إعداد: مؤيد حميد\nبإشراف: د. مازن المصطفى'
                  : 'By: Moayad Hameed\nSupervised by: Dr. Mazen Al-Mostafa',
            ),
          ),
          const Divider(),
          _buildSectionHeader(isArabic ? 'عن النسخة' : 'About', theme),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text(
              'CNews',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(isArabic ? 'الإصدار 1.0.0' : 'Version 1.0.0'),
            trailing: Text(
              isArabic ? 'مستقر' : 'Stable',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ThemeChoiceCard extends StatelessWidget {
  const _ThemeChoiceCard({
    required this.colorTheme,
    required this.selected,
    required this.isArabic,
    required this.onTap,
  });

  final AppColorTheme colorTheme;
  final bool selected;
  final bool isArabic;
  final VoidCallback onTap;

  String get _name => switch (colorTheme) {
    AppColorTheme.original => isArabic ? 'الأصلي' : 'Original',
    AppColorTheme.sapphire => isArabic ? 'الياقوتي' : 'Sapphire',
    AppColorTheme.royalPlum => isArabic ? 'الملكي' : 'Royal Plum',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppThemes.paletteOf(colorTheme);

    return Semantics(
      button: true,
      selected: selected,
      label: _name,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 116,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.10)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ColorDot(color: palette.primary, size: 30),
                  Transform.translate(
                    offset: const Offset(-7, 0),
                    child: _ColorDot(color: palette.secondary, size: 30),
                  ),
                  const Spacer(),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                _name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isArabic ? 'اضغط للاختيار' : 'Tap to apply',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
    );
  }
}

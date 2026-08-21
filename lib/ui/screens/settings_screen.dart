import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/local/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _shareApp(bool isArabic) {
    final message = isArabic 
      ? 'حمل تطبيق أخبار العملات السوري - أسعار لحظية وتحليل احترافي!\nإعداد الطالب مؤيد حميد'
      : 'Download CNews App - Live rates & professional analysis!\nBy Moayad Hameed';
    Share.share(message);
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
          _buildSectionHeader(isArabic ? 'المظهر واللغة' : 'Appearance & Language', theme),
          ListTile(
            leading: Icon(settings.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
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
          _buildSectionHeader(isArabic ? 'تواصل وتوثيق' : 'Connect & Credits', theme),
          ListTile(
            leading: const Icon(Icons.share_rounded),
            title: Text(isArabic ? 'مشاركة التطبيق' : 'Share App'),
            onTap: () => _shareApp(isArabic),
          ),
          ListTile(
            leading: const Icon(Icons.person_pin_rounded),
            title: Text(isArabic ? 'معلومات المشروع' : 'Project Info'),
            subtitle: Text(isArabic ? 'إعداد: مؤيد حميد\nبإشراف: د. مازن المصطفى' : 'By: Moayad Hameed\nSupervised by: Dr. Mazen Al-Mostafa'),
          ),
          const Divider(),
          _buildSectionHeader(isArabic ? 'عن النسخة' : 'About', theme),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('V 1.0.2 - Beta'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}

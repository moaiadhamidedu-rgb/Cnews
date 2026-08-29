import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:local_auth/local_auth.dart';
import '../../data/local/settings_provider.dart';
import '../../Logic/calculate_provider.dart';
import '../../core/utils/export_service.dart';

class CalculateScreen extends StatefulWidget {
  final bool isActive;
  const CalculateScreen({super.key, this.isActive = false});

  @override
  State<CalculateScreen> createState() => _CalculateScreenState();
}

class _CalculateScreenState extends State<CalculateScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _calcController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(CalculateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إذا تغيرت حالة التبويب إلى "نشط" والمستخدم لم يوثق بعد، نطلب البصمة
    if (widget.isActive && !oldWidget.isActive && !_isAuthenticated) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        if (mounted) setState(() => _isAuthenticated = true);
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'يرجى تأكيد هويتك للوصول إلى بيانات المحفظة',
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );

      if (mounted) setState(() => _isAuthenticated = didAuthenticate);
    } catch (e) {
      if (mounted) setState(() => _isAuthenticated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = Provider.of<SettingsProvider>(context);
    final calcLogic = Provider.of<CalculateProvider>(context);
    final isArabic = settings.locale.languageCode == 'ar';
    final theme = Theme.of(context);

    if (!_isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              Text(isArabic ? 'المحفظة محمية' : 'Wallet Protected'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _authenticate,
                child: Text(isArabic ? 'فتح المحفظة' : 'Unlock Wallet'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'المحفظة والحسابات' : 'Wallet & Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => _showExportOptions(context, isArabic, calcLogic),
            tooltip: isArabic ? 'تصدير تقرير' : 'Export Report',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: calcLogic.loadWallet,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildDualWalletSummary(theme, isArabic, calcLogic),
              const SizedBox(height: 20),
              _buildGoalsSection(theme, isArabic, calcLogic),
              const SizedBox(height: 20),
              if (calcLogic.walletItems.isNotEmpty) ...[
                _buildSpendingInsights(theme, isArabic, calcLogic),
                const SizedBox(height: 20),
              ],
              _buildActionButtons(theme, isArabic, calcLogic),
              const SizedBox(height: 20),
              _buildCalculatorCard(theme, isArabic, calcLogic),
              const SizedBox(height: 20),
              _buildRecentTransactions(theme, isArabic, calcLogic),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    ThemeData theme,
    bool isArabic,
    CalculateProvider logic,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showTransactionDialog(context, isArabic, logic),
            icon: const Icon(Icons.add_circle_outline, size: 22),
            label: Text(isArabic ? 'إضافة عملية' : 'Add Transaction'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showResetConfirmation(context, isArabic, logic),
            icon: const Icon(Icons.refresh_rounded, size: 22),
            label: Text(isArabic ? 'تصفير المحفظة' : 'Reset Wallet'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDualWalletSummary(
    ThemeData theme,
    bool isArabic,
    CalculateProvider logic,
  ) {
    return Column(
      children: [
        _walletCard(
          theme: theme,
          isArabic: isArabic,
          title: isArabic ? 'محفظة الليرة السورية' : 'SYP Wallet',
          balance: logic.totalBalanceSyp,
          income: logic.incomeSyp,
          expense: logic.expenseSyp,
          currency: 'ل.س',
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 16),
        _walletCard(
          theme: theme,
          isArabic: isArabic,
          title: isArabic ? 'محفظة الدولار الأمريكي' : 'USD Wallet',
          balance: logic.totalBalanceUsd,
          income: logic.incomeUsd,
          expense: logic.expenseUsd,
          currency: '\$',
          color: theme.colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _walletCard({
    required ThemeData theme,
    required bool isArabic,
    required String title,
    required double balance,
    required double income,
    required double expense,
    required String currency,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${NumberFormat('#,###.##').format(balance)} $currency',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem(
                isArabic ? 'الواردات' : 'Income',
                income,
                currency,
                Colors.greenAccent,
              ),
              Container(width: 1, height: 30, color: Colors.white24),
              _statItem(
                isArabic ? 'المصاريف' : 'Expenses',
                expense,
                currency,
                Colors.orangeAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, double value, String currency, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        Text(
          '${NumberFormat('#,###.##').format(value)} $currency',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorCard(
    ThemeData theme,
    bool isArabic,
    CalculateProvider logic,
  ) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'محول العملات السريع' : 'Quick Converter',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _calcController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => logic.convert(v),
                    decoration: InputDecoration(
                      labelText: logic.fromCurrency,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    icon: const Icon(Icons.swap_horiz_rounded, size: 28),
                    onPressed: () => logic.swapCurrencies(_calcController.text),
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          logic.toCurrency,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          NumberFormat('#,###.##').format(logic.result),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
    ThemeData theme,
    bool isArabic,
    CalculateProvider logic,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            isArabic ? 'العمليات الأخيرة' : 'Recent Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (logic.walletItems.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Center(
              child: Text(
                isArabic ? 'لا توجد عمليات حالياً' : 'No transactions yet',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ...logic.walletItems.map((item) {
          final currency = item['currency'] ?? 'SYP';
          final symbol = currency == 'USD' ? '\$' : 'ل.س';
          final isIncome = item['type'] == 'income';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: ListTile(
              onTap: () =>
                  _showTransactionDialog(context, isArabic, logic, item: item),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isIncome ? Colors.green : theme.colorScheme.secondary)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isIncome ? Colors.green : theme.colorScheme.secondary,
                  size: 20,
                ),
              ),
              title: Text(
                item['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                item['date'],
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${NumberFormat('#,###.##').format(item['amount'])} $symbol',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: isIncome
                          ? Colors.green
                          : theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () =>
                        _confirmDelete(context, isArabic, logic, item['id']),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildGoalsSection(
    ThemeData theme,
    bool isArabic,
    CalculateProvider logic,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isArabic ? 'أهدافي المالية' : 'Financial Goals',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
              onPressed: () => _showAddGoalDialog(context, isArabic, logic),
            ),
          ],
        ),
        if (logic.goals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              isArabic ? 'لا توجد أهداف حالياً' : 'No goals yet',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ...logic.goals.map((goal) {
          double progress = (goal['target_amount'] > 0)
              ? (goal['saved_amount'] / goal['target_amount']).clamp(0.0, 1.0)
              : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      goal['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${NumberFormat('#,###.##').format(goal['saved_amount'])} / ${NumberFormat('#,###.##').format(goal['target_amount'])} ${goal['currency'] == 'USD' ? '\$' : 'ل.س'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 8,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _showUpdateGoalDialog(
                            context,
                            isArabic,
                            logic,
                            goal,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () => logic.deleteGoal(goal['id']),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  void _showAddGoalDialog(
    BuildContext context,
    bool isArabic,
    CalculateProvider logic,
  ) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    String currency = 'USD';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'إضافة هدف جديد' : 'Add New Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: isArabic
                    ? 'اسم الهدف (مثلاً: ادخار سيارة)'
                    : 'Goal Name',
              ),
            ),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isArabic
                    ? 'المبلغ المستهدف (\$)'
                    : 'Target Amount (\$)',
                suffixText: '\$',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  targetController.text.isNotEmpty) {
                logic.addGoal(
                  titleController.text,
                  double.tryParse(targetController.text) ?? 0,
                  currency,
                );
                Navigator.pop(context);
              }
            },
            child: Text(isArabic ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _showUpdateGoalDialog(
    BuildContext context,
    bool isArabic,
    CalculateProvider logic,
    Map<String, dynamic> goal,
  ) {
    final savedController = TextEditingController(
      text: goal['saved_amount'].toString(),
    );
    final String currencySymbol = goal['currency'] == 'USD' ? '\$' : 'ل.س';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تحديث التقدم' : 'Update Progress'),
        content: TextField(
          controller: savedController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: isArabic
                ? 'المبلغ المدخر حالياً ($currencySymbol)'
                : 'Current Saved Amount ($currencySymbol)',
            suffixText: currencySymbol,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newVal = double.tryParse(savedController.text) ?? 0;
              final success = await logic.updateGoalProgress(
                goal['id'],
                newVal,
              );

              if (mounted) {
                if (success) {
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'عذراً، رصيد المحفظة لا يكفي لهذا الادخار!'
                            : 'Sorry, wallet balance is insufficient for this saving!',
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(isArabic ? 'تحديث' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    bool isArabic,
    CalculateProvider logic,
    int id,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'حذف العملية' : 'Delete Transaction'),
        content: Text(
          isArabic
              ? 'هل تريد حذف هذه العملية من السجل؟'
              : 'Do you want to delete this transaction?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              logic.deleteTransaction(id);
              Navigator.pop(context);
            },
            child: Text(
              isArabic ? 'حذف' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scanReceipt(
    BuildContext context,
    TextEditingController amountController,
    Function setDialogState,
  ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      double maxAmount = 0;
      final RegExp regExp = RegExp(r'\d+\.\d{2}');

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final matches = regExp.allMatches(line.text);
          for (final match in matches) {
            double val = double.tryParse(match.group(0) ?? '0') ?? 0;
            if (val > maxAmount) maxAmount = val;
          }
        }
      }

      if (maxAmount > 0) {
        setDialogState(
          () => amountController.text = maxAmount.toStringAsFixed(0),
        );
      }
    } finally {
      textRecognizer.close();
    }
  }

  void _showTransactionDialog(
    BuildContext context,
    bool isArabic,
    CalculateProvider logic, {
    Map<String, dynamic>? item,
  }) {
    final titleController = TextEditingController(text: item?['title']);
    final amountController = TextEditingController(
      text: item?['amount']?.toString(),
    );
    String type = item?['type'] ?? 'income';
    String currency = item?['currency'] ?? 'SYP';
    String category = item?['category'] ?? (isArabic ? 'عام' : 'General');

    final categories = isArabic
        ? [
            'عام',
            'طعام',
            'مواصلات',
            'تسوق',
            'فواتير',
            'صحة',
            'ترفيه',
            'Savings',
          ]
        : [
            'General',
            'Food',
            'Transport',
            'Shopping',
            'Bills',
            'Health',
            'Entertainment',
            'Savings',
          ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item == null
                      ? (isArabic ? 'إضافة عملية جديدة' : 'Add Transaction')
                      : (isArabic ? 'تعديل العملية' : 'Edit Transaction'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'العنوان' : 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isArabic ? 'المبلغ' : 'Amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: () => _scanReceipt(
                        context,
                        amountController,
                        setDialogState,
                      ),
                      icon: const Icon(Icons.document_scanner_rounded),
                      tooltip: isArabic ? 'مسح الفاتورة' : 'Scan Receipt',
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: categories.contains(category)
                      ? category
                      : categories.first,
                  decoration: InputDecoration(
                    labelText: isArabic ? 'التصنيف' : 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'العملة:' : 'Currency:',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'SYP', label: Text('SYP')),
                              ButtonSegment(value: 'USD', label: Text('USD')),
                            ],
                            selected: {currency},
                            onSelectionChanged: (val) =>
                                setDialogState(() => currency = val.first),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'النوع:' : 'Type:',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'income',
                          label: Text(isArabic ? 'دخل' : 'Income'),
                          icon: const Icon(Icons.download_rounded),
                        ),
                        ButtonSegment(
                          value: 'expense',
                          label: Text(isArabic ? 'صرف' : 'Expense'),
                          icon: const Icon(Icons.upload_rounded),
                        ),
                      ],
                      selected: {type},
                      onSelectionChanged: (val) =>
                          setDialogState(() => type = val.first),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () async {
                      if (titleController.text.isNotEmpty &&
                          amountController.text.isNotEmpty) {
                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        bool success;

                        if (item == null) {
                          success = await logic.addTransaction(
                            titleController.text,
                            amount,
                            type,
                            currency,
                            category,
                          );
                        } else {
                          success = await logic.updateTransaction(
                            item['id'],
                            titleController.text,
                            amount,
                            type,
                            currency,
                            category,
                            oldAmount: (item['amount'] as num).toDouble(),
                            oldType: item['type'],
                            oldCurrency: item['currency'],
                          );
                        }

                        if (success) {
                          if (mounted) Navigator.pop(context);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isArabic
                                      ? 'عذراً، الرصيد غير كافٍ لإتمام هذه العملية!'
                                      : 'Sorry, insufficient balance to complete this transaction!',
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      }
                    },
                    child: Text(
                      isArabic ? 'حفظ' : 'Save',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpendingInsights(
    ThemeData theme,
    bool isArabic,
    CalculateProvider logic,
  ) {
    final sypData = logic.categoryTotalsSyp;
    if (sypData.isEmpty && logic.categoryTotalsUsd.isEmpty)
      return const SizedBox();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart_outline_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  isArabic ? 'تحليل المصاريف' : 'Spending Insights',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: _buildPieSections(logic, theme),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildLegend(logic, theme, isArabic),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(
    CalculateProvider logic,
    ThemeData theme,
  ) {
    final Map<String, double> data = logic.categoryTotalsSyp.isNotEmpty
        ? logic.categoryTotalsSyp
        : logic.categoryTotalsUsd;

    final List<Color> colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      Colors.orangeAccent,
      Colors.teal,
      Colors.purpleAccent,
    ];

    int i = 0;
    return data.entries.map((entry) {
      final color = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '',
        radius: 15,
      );
    }).toList();
  }

  List<Widget> _buildLegend(
    CalculateProvider logic,
    ThemeData theme,
    bool isArabic,
  ) {
    final Map<String, double> data = logic.categoryTotalsSyp.isNotEmpty
        ? logic.categoryTotalsSyp
        : logic.categoryTotalsUsd;

    final List<Color> colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      Colors.orangeAccent,
      Colors.teal,
      Colors.purpleAccent,
    ];

    int i = 0;
    return data.entries.map((entry) {
      final color = colors[i % colors.length];
      i++;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showResetConfirmation(
    BuildContext context,
    bool isArabic,
    CalculateProvider logic,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArabic ? 'تصفير المحفظة' : 'Reset Wallet'),
        content: Text(
          isArabic
              ? 'سيتم حذف جميع العمليات في كلتا المحفظتين. هل أنت متأكد؟'
              : 'All transactions in both wallets will be deleted. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isArabic ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              logic.resetWallet();
              Navigator.pop(context);
            },
            child: Text(
              isArabic ? 'تأكيد' : 'Confirm',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(
    BuildContext context,
    bool isArabic,
    CalculateProvider logic,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isArabic ? 'تصدير تقرير العمليات' : 'Export Transactions Report',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _exportButton(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  color: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(context);
                    ExportService.exportWalletReport(
                      items: logic.walletItems,
                      format: 'pdf',
                      isArabic: isArabic,
                      totalSyp: logic.totalBalanceSyp,
                      totalUsd: logic.totalBalanceUsd,
                    );
                  },
                ),
                _exportButton(
                  icon: Icons.table_chart_rounded,
                  label: 'Excel (CSV)',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    ExportService.exportWalletReport(
                      items: logic.walletItems,
                      format: 'excel',
                      isArabic: isArabic,
                      totalSyp: logic.totalBalanceSyp,
                      totalUsd: logic.totalBalanceUsd,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _exportButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

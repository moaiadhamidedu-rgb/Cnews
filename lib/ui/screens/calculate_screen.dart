import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/local/settings_provider.dart';
import '../../Logic/calculate_provider.dart';

class CalculateScreen extends StatefulWidget {
  const CalculateScreen({super.key});

  @override
  State<CalculateScreen> createState() => _CalculateScreenState();
}

class _CalculateScreenState extends State<CalculateScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _calcController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = Provider.of<SettingsProvider>(context);
    final calcLogic = Provider.of<CalculateProvider>(context);
    final isArabic = settings.locale.languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'المحفظة والحسابات' : 'Wallet & Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {}, 
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: calcLogic.loadWallet,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildWalletSummaryCard(theme, isArabic, calcLogic),
              const SizedBox(height: 20),
              _buildCalculatorCard(theme, isArabic, calcLogic),
              const SizedBox(height: 20),
              _buildRecentTransactions(theme, isArabic, calcLogic),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(context, isArabic, calcLogic),
        label: Text(isArabic ? 'إضافة عملية' : 'Add Transaction'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalculatorCard(ThemeData theme, bool isArabic, CalculateProvider logic) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.1))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isArabic ? 'محول العملات' : 'Currency Converter', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Text(logic.toCurrency, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          NumberFormat('#,###.##').format(logic.result),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
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

  Widget _buildWalletSummaryCard(ThemeData theme, bool isArabic, CalculateProvider logic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withBlue(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text(isArabic ? 'إجمالي الرصيد بالمحفظة' : 'Personal Wallet Balance', style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${NumberFormat('#,###').format(logic.totalBalance)} ل.س',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _walletStatItem(isArabic ? 'الواردات' : 'Income', logic.income, Colors.greenAccent),
              Container(width: 1, height: 40, color: Colors.white24),
              _walletStatItem(isArabic ? 'المصاريف' : 'Expenses', logic.expense, Colors.orangeAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _walletStatItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '${NumberFormat('#,###').format(value)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(ThemeData theme, bool isArabic, CalculateProvider logic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(isArabic ? 'العمليات المالية' : 'Financial Transactions', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        if (logic.walletItems.isEmpty)
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Center(child: Text(isArabic ? 'لا توجد عمليات حالياً' : 'No transactions yet', style: const TextStyle(color: Colors.grey))),
          ),
        ...logic.walletItems.map((item) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1))),
          child: ListTile(
            leading: Icon(
              item['type'] == 'income' ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: item['type'] == 'income' ? Colors.green : const Color(0xFFB49A67),
            ),
            title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['date'], style: const TextStyle(fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${NumberFormat('#,###').format(item['amount'])} ل.س',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: item['type'] == 'income' ? Colors.green : const Color(0xFFB49A67)
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => logic.deleteTransaction(item['id']),
                ),
              ],
            ),
          ),
        )).toList(),
      ],
    );
  }

  void _showAddTransactionDialog(BuildContext context, bool isArabic, CalculateProvider logic) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'income';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isArabic ? 'إضافة عملية جديدة' : 'Add New Transaction', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: titleController, decoration: InputDecoration(labelText: isArabic ? 'العنوان (مثلاً: راتب)' : 'Title (e.g. Salary)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 15),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: isArabic ? 'المبلغ' : 'Amount', border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)))),
            const SizedBox(height: 15),
            StatefulBuilder(builder: (context, setDialogState) => SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'income', label: Text(isArabic ? 'دخل' : 'Income'), icon: const Icon(Icons.download)),
                ButtonSegment(value: 'expense', label: Text(isArabic ? 'خرج' : 'Expense'), icon: const Icon(Icons.upload)),
              ],
              selected: {type},
              onSelectionChanged: (val) => setDialogState(() => type = val.first),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                    await logic.addTransaction(titleController.text, double.tryParse(amountController.text) ?? 0, type);
                    Navigator.pop(context);
                  }
                },
                child: Text(isArabic ? 'حفظ العملية' : 'Save Transaction'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

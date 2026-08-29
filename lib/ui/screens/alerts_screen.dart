import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Logic/alerts_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _rateController = TextEditingController();
  String _selectedCurrency = 'USD';
  String _alertType = 'above';

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final alertsLogic = Provider.of<AlertsProvider>(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'إدارة التنبيهات' : 'Alert Management'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      isArabic ? 'إضافة تنبيه جديد' : 'Add New Alert',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            isExpanded: true,
                            items: ['USD', 'EUR', 'GBP', 'TRY'].map((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCurrency = val!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _alertType,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(
                                value: 'above',
                                child: Text(
                                  isArabic ? 'إذا زاد عن' : 'If above',
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'below',
                                child: Text(
                                  isArabic ? 'إذا قل عن' : 'If below',
                                ),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _alertType = val!),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: _rateController,
                      decoration: InputDecoration(
                        labelText: isArabic
                            ? 'السعر المستهدف (ل.س)'
                            : 'Target Rate (SYP)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_rateController.text.isNotEmpty) {
                          alertsLogic.addAlert(
                            _selectedCurrency,
                            double.tryParse(_rateController.text) ?? 0,
                            _alertType,
                          );
                          _rateController.clear();
                        }
                      },
                      icon: const Icon(Icons.add_alert),
                      label: Text(isArabic ? 'حفظ التنبيه' : 'Save Alert'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: alertsLogic.isLoading
                ? const Center(child: CircularProgressIndicator())
                : alertsLogic.alerts.isEmpty
                ? Center(
                    child: Text(
                      isArabic ? 'لا توجد تنبيهات حالياً' : 'No alerts yet',
                    ),
                  )
                : ListView.builder(
                    itemCount: alertsLogic.alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alertsLogic.alerts[index];
                      return ListTile(
                        leading: Icon(
                          alert['alert_type'] == 'above'
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: alert['alert_type'] == 'above'
                              ? Colors.red
                              : Colors.green,
                        ),
                        title: Text(
                          '${isArabic ? "تنبيه" : "Alert"} ${alert['currency_pair']}',
                        ),
                        subtitle: Text(
                          '${alert['alert_type'] == 'above' ? (isArabic ? "أعلى من" : "Above") : (isArabic ? "أقل من" : "Below")}: ${alert['target_rate']} ل.س',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () => alertsLogic.deleteAlert(alert['id']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

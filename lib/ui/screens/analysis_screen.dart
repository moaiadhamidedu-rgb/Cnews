import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/local/settings_provider.dart';
import '../../Logic/analysis_provider.dart';
import '../../core/utils/export_service.dart';
import '../../data/local/database_helper.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final settings = Provider.of<SettingsProvider>(context);
    final analysisLogic = Provider.of<AnalysisProvider>(context);
    final isArabic = settings.locale.languageCode == 'ar';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تحليل الأسعار المباشر' : 'Live Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _showExportOptions(context, isArabic),
          )
        ],
      ),
      body: analysisLogic.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: analysisLogic.loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  _buildFilters(isArabic, theme, analysisLogic),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isArabic ? 'السعر الحالي' : 'Current Price', style: const TextStyle(color: Colors.grey)),
                        Text('${NumberFormat('#,###').format(analysisLogic.currentPrice)} ل.س', 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLegend(theme, isArabic, analysisLogic.selectedCurrency),
                  _buildChartCard(theme, isArabic, analysisLogic),
                  const SizedBox(height: 24),
                  _buildSummaryCard(theme, isArabic, analysisLogic),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildFilters(bool isArabic, ThemeData theme, AnalysisProvider logic) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: logic.selectedCurrency,
              decoration: InputDecoration(
                labelText: isArabic ? 'العملة' : 'Currency',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              items: ['USD', 'EUR', 'TRY', 'SAR', 'AED', 'JOD', 'EGP'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => logic.setCurrency(val!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: logic.selectedPeriod,
              decoration: InputDecoration(
                labelText: isArabic ? 'الفترة' : 'Period',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              items: [
                DropdownMenuItem(value: 'Day', child: Text(isArabic ? 'يوم' : 'Day')),
                DropdownMenuItem(value: 'Month', child: Text(isArabic ? 'شهر' : 'Month')),
                DropdownMenuItem(value: 'Year', child: Text(isArabic ? 'سنة' : 'Year')),
              ].toList(),
              onChanged: (val) => logic.setPeriod(val!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, bool isArabic, String currency) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '${isArabic ? "سعر" : "Price"} $currency',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(ThemeData theme, bool isArabic, AnalysisProvider logic) {
    double intervalX = 4; // Default for Day
    if (logic.selectedPeriod == 'Month') intervalX = 5;
    if (logic.selectedPeriod == 'Year') intervalX = 1;

    return Container(
      height: 320,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.only(top: 24, bottom: 12, right: 24, left: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20)],
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: logic.chartData.isEmpty 
          ? const Center(child: Text('No Data'))
          : LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: theme.colorScheme.outline.withOpacity(0.05), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(
                      logic.selectedPeriod == 'Day' ? (isArabic ? 'الساعة' : 'Hour') : 
                      logic.selectedPeriod == 'Month' ? (isArabic ? 'اليوم' : 'Day') : 
                      (isArabic ? 'الشهر' : 'Month'),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: intervalX,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) return const SizedBox();
                        return Text(
                          NumberFormat.compact().format(value),
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 9),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: logic.chartData,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary.withOpacity(0.2), theme.colorScheme.primary.withOpacity(0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, bool isArabic, AnalysisProvider logic) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1))),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.summarize_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(isArabic ? 'تقرير التحليل الذكي' : 'Smart Analysis Report', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              _rowSummary(isArabic ? 'أعلى سعر مسجل' : 'Highest Recorded', '${NumberFormat('#,###').format(logic.max)}', Colors.redAccent),
              const Divider(height: 24),
              _rowSummary(isArabic ? 'أدنى سعر مسجل' : 'Lowest Recorded', '${NumberFormat('#,###').format(logic.min)}', Colors.green),
              const Divider(height: 24),
              _rowSummary(isArabic ? 'متوسط السعر' : 'Average Price', '${NumberFormat('#,###').format(logic.average)}', theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rowSummary(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text('$value ل.س', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
      ],
    );
  }

  void _showExportOptions(BuildContext context, bool isArabic) {
    final logic = Provider.of<AnalysisProvider>(context, listen: false);
    final db = DatabaseHelper();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Text(isArabic ? 'تصدير التقرير الفني' : 'Export Technical Report', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final history = await db.getHistory(logic.selectedCurrency, logic.selectedPeriod);
                      ExportService.exportToPDF(logic.selectedCurrency, history, isArabic);
                    },
                    child: _exportItem(Icons.picture_as_pdf, 'PDF', Colors.red),
                  ),
                  _exportItem(Icons.table_view_rounded, 'Excel', Colors.green),
                  _exportItem(Icons.text_snippet_rounded, 'Text', Colors.blue),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _exportItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}

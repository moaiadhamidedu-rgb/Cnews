import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class ExportService {
  static Future<void> shareRate(String code, double rate, bool isArabic) async {
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final message = isArabic 
      ? 'سعر صرف $code الحالي هو ${NumberFormat('#,###').format(rate)} ل.س\nتحديث: $date\nعبر تطبيق أخبار العملات'
      : 'Current $code rate is ${NumberFormat('#,###').format(rate)} SYP\nUpdated: $date\nvia CNews App';
    
    await Share.share(message);
  }

  static Future<void> exportToPDF(String currency, List<Map<String, dynamic>> history, bool isArabic) async {
    final pdf = pw.Document();

    // إضافة صفحة للتقرير
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(isArabic ? 'تقرير أسعار الصرف التاريخي' : 'Exchange Rate History Report', 
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Text('${isArabic ? "العملة" : "Currency"}: $currency'),
              pw.Text('${isArabic ? "تاريخ التصدير" : "Export Date"}: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}'),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(width: .5, color: PdfColors.grey300),
                  verticalInside: pw.BorderSide(width: .5, color: PdfColors.grey300),
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: [isArabic ? 'التاريخ' : 'Date', isArabic ? 'السعر (ل.س)' : 'Rate (SYP)'],
                data: history.map((row) => [
                  DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(row['timestamp'])),
                  NumberFormat('#,###').format(row['rate'])
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    // حفظ الملف ومشاركته
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/report_$currency.pdf");
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles([XFile(file.path)], text: isArabic ? 'تقرير الأسعار' : 'Rates Report');
  }
}

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

  static Future<void> exportToPDF(
    String currency,
    List<Map<String, dynamic>> history,
    bool isArabic,
  ) async {
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
                child: pw.Text(
                  isArabic
                      ? 'تقرير أسعار الصرف التاريخي'
                      : 'Exchange Rate History Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('${isArabic ? "العملة" : "Currency"}: $currency'),
              pw.Text(
                '${isArabic ? "تاريخ التصدير" : "Export Date"}: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                context: context,
                border: const pw.TableBorder(
                  horizontalInside: pw.BorderSide(
                    width: .5,
                    color: PdfColors.grey300,
                  ),
                  verticalInside: pw.BorderSide(
                    width: .5,
                    color: PdfColors.grey300,
                  ),
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headers: [
                  isArabic ? 'التاريخ' : 'Date',
                  isArabic ? 'السعر (ل.س)' : 'Rate (SYP)',
                ],
                data: history
                    .map(
                      (row) => [
                        DateFormat(
                          'yyyy-MM-dd HH:mm',
                        ).format(DateTime.parse(row['timestamp'])),
                        NumberFormat('#,###').format(row['rate']),
                      ],
                    )
                    .toList(),
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

    await Share.shareXFiles([
      XFile(file.path),
    ], text: isArabic ? 'تقرير الأسعار' : 'Rates Report');
  }

  static Future<void> exportWalletReport({
    required List<Map<String, dynamic>> items,
    required String format,
    required bool isArabic,
    required double totalSyp,
    required double totalUsd,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
    final directory = await getTemporaryDirectory();

    if (format == 'pdf') {
      final pdf = pw.Document();
      // ملاحظة: لتحسين دعم العربي في PDF يفضل تحميل خط يدعم العربية، سنستخدم الأساسي هنا للتبسيط
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                isArabic ? 'تقرير المحفظة المالية' : 'Financial Wallet Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              '${isArabic ? "تاريخ التقرير" : "Report Date"}: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  '${isArabic ? "رصيد السوري" : "SYP Balance"}: ${NumberFormat('#,###').format(totalSyp)} SYP',
                ),
                pw.Text(
                  '${isArabic ? "رصيد الدولار" : "USD Balance"}: \$${NumberFormat('#,###.##').format(totalUsd)}',
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: [
                isArabic ? 'التاريخ' : 'Date',
                isArabic ? 'العنوان' : 'Title',
                isArabic ? 'النوع' : 'Type',
                isArabic ? 'العملة' : 'Currency',
                isArabic ? 'المبلغ' : 'Amount',
              ],
              data: items
                  .map(
                    (item) => [
                      item['date'],
                      item['title'],
                      item['type'] == 'income'
                          ? (isArabic ? 'دخل' : 'Income')
                          : (isArabic ? 'صرف' : 'Expense'),
                      item['currency'],
                      NumberFormat('#,###.##').format(item['amount']),
                    ],
                  )
                  .toList(),
            ),
          ],
        ),
      );

      final file = File("${directory.path}/Wallet_Report_$dateStr.pdf");
      await file.writeAsBytes(await pdf.save());
      await Share.shareXFiles([
        XFile(file.path),
      ], text: isArabic ? 'تقرير المحفظة' : 'Wallet Report');
    } else if (format == 'excel') {
      // تصدير بصيغة CSV المتوافقة مع Excel
      final StringBuffer csvContent = StringBuffer();
      // إضافة BOM لدعم اللغة العربية في Excel
      csvContent.write('\uFEFF');

      // العناوين
      csvContent.writeln(
        '${isArabic ? "التاريخ" : "Date"},${isArabic ? "العنوان" : "Title"},${isArabic ? "النوع" : "Type"},${isArabic ? "العملة" : "Currency"},${isArabic ? "المبلغ" : "Amount"}',
      );

      for (var item in items) {
        final type = item['type'] == 'income'
            ? (isArabic ? 'دخل' : 'Income')
            : (isArabic ? 'صرف' : 'Expense');
        csvContent.writeln(
          '${item['date']},${item['title']},$type,${item['currency']},${item['amount']}',
        );
      }

      final file = File("${directory.path}/Wallet_Report_$dateStr.csv");
      await file.writeAsString(csvContent.toString());
      await Share.shareXFiles([
        XFile(file.path),
      ], text: isArabic ? 'تقرير المحفظة Excel' : 'Wallet Excel Report');
    }
  }
}

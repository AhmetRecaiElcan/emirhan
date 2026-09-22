import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/product_model.dart';

class PdfService {
  static Future<void> generateAndPrintProductList({
    required List<ProductModel> products,
    String? currentUserName,
  }) async {
    final doc = pw.Document();

    // Türkçe karakter desteği için Roboto fontları
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final now = DateTime.now();

    final primaryColor = PdfColor.fromHex('6C5CE7');
    final textColor = PdfColor.fromHex('2D3748');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 36,
                      height: 36,
                      decoration: pw.BoxDecoration(
                        color: primaryColor,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          'A',
                          style: pw.TextStyle(
                            font: fontBold,
                            color: PdfColors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AMBAR STOK - TÜM ÜRÜNLER RAPORU',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),
                        pw.Text(
                          'Depo Envanter ve Ürün Listesi',
                          style: pw.TextStyle(
                            font: fontRegular,
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Rapor Tarihi: ${dateFormat.format(now)}',
                      style: pw.TextStyle(
                        font: fontRegular,
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                    if (currentUserName != null && currentUserName.isNotEmpty)
                      pw.Text(
                        'Raporu Alan: $currentUserName',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    pw.Text(
                      'Toplam Ürün: ${products.length} adet',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: primaryColor, thickness: 1.5),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: PdfColors.grey300, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Ambar Stok Yönetim Sistemi',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Sayfa ${context.pageNumber} / ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 0.5,
            ),
            headerStyle: pw.TextStyle(
              font: fontBold,
              fontSize: 10,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(
              color: primaryColor,
            ),
            headerHeight: 28,
            cellHeight: 24,
            columnWidths: const {
              0: pw.FixedColumnWidth(28),
              1: pw.FlexColumnWidth(2.5),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.5),
              4: pw.FlexColumnWidth(2.2),
              5: pw.FlexColumnWidth(1.8),
              6: pw.FlexColumnWidth(1.5),
              7: pw.FlexColumnWidth(1.1),
            },
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.centerLeft,
              5: pw.Alignment.centerLeft,
              6: pw.Alignment.center,
              7: pw.Alignment.center,
            },
            cellStyle: pw.TextStyle(
              font: fontRegular,
              fontSize: 8.5,
              color: textColor,
            ),
            rowDecoration: pw.BoxDecoration(
              color: PdfColors.white,
            ),
            headers: [
              '#',
              'Ürün Adı',
              'Miktar',
              'Lokasyon / Depo',
              'Nasıl Alındı',
              'Ekleyen Kişi',
              'Eklenme Tarihi',
              'Durum',
            ],
            data: List.generate(products.length, (index) {
              final p = products[index];
              final isLow = p.isLowStock;
              final qtyText = '${p.quantity == p.quantity.toInt() ? p.quantity.toInt() : p.quantity} ${p.unit}';
              final dateText = DateFormat('dd.MM.yyyy HH:mm').format(p.createdAt);

              return [
                (index + 1).toString(),
                p.name,
                qtyText,
                p.depot.isNotEmpty ? p.depot : '-',
                p.purchaseType.isNotEmpty ? p.purchaseType : '-',
                p.createdByName.isNotEmpty ? p.createdByName : 'Bilinmeyen',
                dateText,
                isLow ? 'Kritik Stok' : 'Normal',
              ];
            }),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Ambar_Stok_Urun_Listesi_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf',
    );
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'curriculum_seed.dart';
import 'report_service.dart';

enum ExportFormat { excel, pdf }

extension ExportFormatX on ExportFormat {
  String get ext => this == ExportFormat.excel ? 'xlsx' : 'pdf';
  String get label => this == ExportFormat.excel ? 'Excel' : 'PDF';
}

/// Tạo file báo cáo danh sách sinh viên (Excel / PDF) từ [ReportData].
class ReportExporter {
  static const _school = 'TRƯỜNG ĐẠI HỌC GIÁO DỤC';
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm');

  static String _generatedLine(ReportData r) =>
      'Ngày lập: ${_dateTime.format(r.generatedAt)} · Người lập: ${r.generatedBy}'
      ' · Tổng số: ${r.rows.length} sinh viên';

  static String _criteriaLine(ReportData r) => r.criteria.isEmpty
      ? 'Tiêu chí: tất cả sinh viên'
      : 'Tiêu chí: ${r.criteria.join(' · ')}';

  /// Thống kê nhanh đi kèm báo cáo.
  static Map<String, Map<String, int>> _summaries(ReportData r) => {
        'Theo năm học': r.countBy((d) => 'Năm ${d.progress.yearOfStudy}'),
        'Theo khóa': r.countBy((d) => d.student.cohort),
        'Theo mức cảnh báo học tập': r.countBy(
            (d) => ReportFilter.levelText(d.progress.academicLevel)),
        'Theo tiến độ': r.countBy(
            (d) => d.progress.behindSchedule ? 'Chậm tiến độ' : 'Đúng tiến độ'),
      };

  // ------------------------------------------------------------------ Excel
  static Uint8List buildExcel(ReportData r) {
    final book = xl.Excel.createExcel();
    const listSheet = 'Danh sách';
    book.rename(book.getDefaultSheet()!, listSheet);
    final sheet = book[listSheet];
    final cols = r.columns;
    final lastCol = cols.length - 1;

    xl.CellIndex at(int col, int row) =>
        xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);

    void mergedLine(int row, String text, xl.CellStyle style) {
      sheet.updateCell(at(0, row), xl.TextCellValue(text), cellStyle: style);
      if (lastCol > 0) sheet.merge(at(0, row), at(lastCol, row));
    }

    mergedLine(
        0,
        '$_school – ${CurriculumSeed.faculty.toUpperCase()}',
        xl.CellStyle(bold: true, fontSize: 11));
    mergedLine(
        1,
        r.title.toUpperCase(),
        xl.CellStyle(
            bold: true,
            fontSize: 14,
            horizontalAlign: xl.HorizontalAlign.Center));
    mergedLine(2, _criteriaLine(r), xl.CellStyle(italic: true));
    mergedLine(3, _generatedLine(r), xl.CellStyle(italic: true));

    final thin = xl.Border(borderStyle: xl.BorderStyle.Thin);
    xl.CellStyle cellStyle({
      bool header = false,
      bool numeric = false,
      xl.NumFormat format = xl.NumFormat.standard_0,
    }) =>
        xl.CellStyle(
          bold: header,
          backgroundColorHex: header
              ? xl.ExcelColor.fromHexString('#DCE6F5')
              : xl.ExcelColor.none,
          horizontalAlign: header
              ? xl.HorizontalAlign.Center
              : numeric
                  ? xl.HorizontalAlign.Right
                  : xl.HorizontalAlign.Left,
          verticalAlign: xl.VerticalAlign.Center,
          textWrapping: header ? xl.TextWrapping.WrapText : null,
          leftBorder: thin,
          rightBorder: thin,
          topBorder: thin,
          bottomBorder: thin,
          numberFormat: format,
        );

    const headerRow = 5;
    final headerStyle = cellStyle(header: true);
    for (var c = 0; c < cols.length; c++) {
      sheet.updateCell(at(c, headerRow), xl.TextCellValue(cols[c].label),
          cellStyle: headerStyle);
      sheet.setColumnWidth(c, (cols[c].weight * 5.5).clamp(6, 60));
    }

    final textStyle = cellStyle();
    final intStyle = cellStyle(numeric: true);
    final decStyle = cellStyle(numeric: true, format: xl.NumFormat.standard_2);
    for (var i = 0; i < r.rows.length; i++) {
      final row = headerRow + 1 + i;
      for (var c = 0; c < cols.length; c++) {
        final v = cols[c].valueOf(r.rows[i], i);
        final (xl.CellValue? value, xl.CellStyle style) = switch (v) {
          int n => (xl.IntCellValue(n), intStyle),
          double n => (xl.DoubleCellValue(n), decStyle),
          null => (null, textStyle),
          _ => (xl.TextCellValue('$v'), textStyle),
        };
        sheet.updateCell(at(c, row), value, cellStyle: style);
      }
    }

    // Trang thống kê.
    final stats = book['Thống kê'];
    var row = 0;
    stats.updateCell(at(0, row++), xl.TextCellValue(r.title),
        cellStyle: xl.CellStyle(bold: true, fontSize: 13));
    stats.updateCell(at(0, row++), xl.TextCellValue(_criteriaLine(r)));
    stats.updateCell(at(0, row++),
        xl.TextCellValue('Tổng số sinh viên: ${r.rows.length}'),
        cellStyle: xl.CellStyle(bold: true));
    for (final group in _summaries(r).entries) {
      row++;
      stats.updateCell(at(0, row), xl.TextCellValue(group.key),
          cellStyle: headerStyle);
      stats.updateCell(at(1, row++), xl.TextCellValue('Số SV'),
          cellStyle: headerStyle);
      for (final e in group.value.entries) {
        stats.updateCell(at(0, row), xl.TextCellValue(e.key),
            cellStyle: textStyle);
        stats.updateCell(at(1, row++), xl.IntCellValue(e.value),
            cellStyle: intStyle);
      }
    }
    stats.setColumnWidth(0, 32);
    stats.setColumnWidth(1, 10);

    book.setDefaultSheet(listSheet);
    return Uint8List.fromList(book.encode()!);
  }

  // -------------------------------------------------------------------- PDF
  static pw.Font? _regular;
  static pw.Font? _bold;

  /// Font nhúng có đủ dấu tiếng Việt (font mặc định của PDF thì không).
  static Future<(pw.Font, pw.Font)> loadFonts() async {
    _regular ??= pw.Font.ttf(
        await rootBundle.load('assets/fonts/BeVietnamPro-Regular.ttf'));
    _bold ??=
        pw.Font.ttf(await rootBundle.load('assets/fonts/BeVietnamPro-Bold.ttf'));
    return (_regular!, _bold!);
  }

  static Future<Uint8List> buildPdf(ReportData r,
      {required pw.Font regular, required pw.Font bold}) {
    final doc = pw.Document(
      title: r.title,
      author: r.generatedBy,
      // Không có bản nghiêng riêng: dùng chung font để chữ nghiêng vẫn đủ dấu.
      theme: pw.ThemeData.withFont(
          base: regular, bold: bold, italic: regular, boldItalic: bold),
    );
    final cols = r.columns;
    const muted = PdfColor.fromInt(0xFF6B7280);
    final small = pw.TextStyle(fontSize: 8.5, color: muted);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(r.title, style: small),
            ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 6),
        child: pw.Text('Trang ${ctx.pageNumber}/${ctx.pagesCount}',
            style: small),
      ),
      build: (ctx) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(children: [
              pw.Text(_school, style: const pw.TextStyle(fontSize: 10)),
              pw.Text(CurriculumSeed.faculty.toUpperCase(),
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ]),
            pw.Column(children: [
              pw.Text('CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('Độc lập – Tự do – Hạnh phúc',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ]),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.Text(r.title.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style:
                  pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
            child: pw.Text(_criteriaLine(r),
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9.5))),
        pw.Center(child: pw.Text(_generatedLine(r), style: small)),
        pw.SizedBox(height: 10),
        if (r.rows.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Center(
                child: pw.Text('Không có sinh viên nào thỏa tiêu chí.')),
          )
        else
          pw.TableHelper.fromTextArray(
            context: ctx,
            headers: [for (final c in cols) c.label],
            data: [
              for (var i = 0; i < r.rows.length; i++)
                [for (final c in cols) c.textOf(r.rows[i], i)],
            ],
            border: pw.TableBorder.all(
                color: const PdfColor.fromInt(0xFF9CA3AF), width: 0.5),
            headerStyle:
                pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFFDCE6F5)),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            oddRowDecoration:
                const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF7F8FA)),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            columnWidths: {
              for (var i = 0; i < cols.length; i++)
                i: pw.FlexColumnWidth(cols[i].weight),
            },
            cellAlignments: {
              for (var i = 0; i < cols.length; i++)
                i: cols[i].numeric
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
            },
          ),
        pw.SizedBox(height: 12),
        // Thống kê và chữ ký chung một hàng để không bị tách sang trang trống.
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(child: _pdfSummary(r)),
            pw.SizedBox(width: 24),
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 40),
              child: pw.Column(children: [
                pw.Text('NGƯỜI LẬP BIỂU',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('(Ký, ghi rõ họ tên)',
                    style: pw.TextStyle(
                        fontSize: 9, fontStyle: pw.FontStyle.italic)),
                pw.SizedBox(height: 48),
                pw.Text(r.generatedBy,
                    style: const pw.TextStyle(fontSize: 10)),
              ]),
            ),
          ],
        ),
      ],
    ));
    return doc.save();
  }

  static pw.Widget _pdfSummary(ReportData r) {
    if (r.rows.isEmpty) return pw.SizedBox();
    final groups = _summaries(r);
    return pw.Wrap(
      spacing: 24,
      runSpacing: 6,
      children: [
        for (final g in groups.entries)
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(g.key,
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)),
              for (final e in g.value.entries)
                pw.Text('${e.key}: ${e.value}',
                    style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
      ],
    );
  }

  // ------------------------------------------------------------------- Lưu
  /// Tên file gợi ý: tiêu đề bỏ ký tự không hợp lệ + ngày lập.
  static String suggestedName(ReportData r, ExportFormat f) {
    final base = r.title
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(r.generatedAt);
    return '${base.isEmpty ? 'BaoCao' : base}_$stamp.${f.ext}';
  }

  /// Tạo file và hỏi nơi lưu. Trả về đường dẫn đã lưu, hoặc `null` nếu người
  /// dùng hủy hộp thoại.
  static Future<String?> export(ReportData r, ExportFormat f) async {
    final loc = await getSaveLocation(
      suggestedName: suggestedName(r, f),
      acceptedTypeGroups: [
        XTypeGroup(label: f.label, extensions: [f.ext]),
      ],
    );
    if (loc == null) return null;
    final Uint8List bytes;
    if (f == ExportFormat.excel) {
      bytes = buildExcel(r);
    } else {
      final (regular, bold) = await loadFonts();
      bytes = await buildPdf(r, regular: regular, bold: bold);
    }
    var path = loc.path;
    if (!path.toLowerCase().endsWith('.${f.ext}')) path = '$path.${f.ext}';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }
}


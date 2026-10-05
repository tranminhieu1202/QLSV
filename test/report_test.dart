import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qlgd_edu/data/academic_service.dart';
import 'package:qlgd_edu/data/report_export.dart';
import 'package:qlgd_edu/data/report_service.dart';
import 'package:qlgd_edu/data/repository.dart';
import 'package:qlgd_edu/models/academic.dart';
import 'package:qlgd_edu/models/course.dart';
import 'package:qlgd_edu/models/enrollment.dart';
import 'package:qlgd_edu/models/student.dart';

Course _course(int id, String block, int sem, {int credits = 3}) => Course(
      id: id,
      code: 'C$id',
      name: 'Học phần $id',
      credits: credits,
      mandatory: true,
      plannedSemester: sem,
      semesterText: '$sem',
      block: block,
      blockName: block,
    );

Student _student(int id, String name, int enrollYear, {String cls = 'QT1'}) =>
    Student(
      id: id,
      studentCode: '${enrollYear % 100}01000$id',
      fullName: name,
      cohort: 'K$enrollYear',
      className: cls,
      major: 'QTTH',
      enrollYear: enrollYear,
      status: 'active',
    );

Enrollment _enr(int id, Student s, Course c, String term, double g10) =>
    Enrollment(
      id: id,
      studentId: s.id,
      courseId: c.id,
      term: term,
      grade10: g10,
      grade4: GradeScale.toFour(g10),
      status: GradeScale.isPass(g10) ? EnrollStatus.passed : EnrollStatus.failed,
      course: c,
    );

void main() {
  // 10 học phần bắt buộc kỳ 1 (30 TC) – đủ để tạo trượt > 8 TC.
  final courses = [for (var i = 1; i <= 10; i++) _course(i, 'I', 1)];
  final ref = DateTime(2026, 9, 1);

  StudentWithProgress make(Student s, double grade) {
    var id = s.id * 100;
    final enr = [for (final c in courses) _enr(id++, s, c, '20251', grade)];
    return StudentWithProgress(
        s, AcademicService.compute(s, enr, courses, now: ref));
  }

  // Năm 2 (nhập học 2025), học tốt.
  final good = make(_student(1, 'Nguyễn Văn An', 2025), 8.0);
  // Năm 2, trượt toàn bộ 30 TC → cảnh báo học tập + chậm tiến độ.
  final bad = make(_student(2, 'Trần Thị Bình', 2025), 2.0);
  // Năm 3 (nhập học 2024), học tốt.
  final third = make(_student(3, 'Lê Văn Cường', 2024, cls: 'QT2'), 7.0);
  final all = [good, bad, third];

  test('năm thứ theo mã SV và kỳ hiện tại', () {
    int year(String code, String term) {
      final s = _student(9, 'X', Student.enrollYearFromCode(code)!);
      return (AcademicService.currentSemester(s, term: term) + 1) ~/ 2;
    }
    // Năm học 2026: 26 → năm 1, 25 → năm 2, 24 → năm 3, 23 → năm 4.
    expect([for (final c in ['26', '25', '24', '23']) year('${c}011102', '20261')],
        [1, 2, 3, 4]);
    // Sang năm học 2027: mã 27 là năm 1, mã 26 lên năm 2.
    expect(year('27010001', '20271'), 1);
    expect(year('26011102', '20271'), 2);
    expect(year('26011102', '20262'), 1); // kỳ 2 vẫn là năm 1
    expect(Student.enrollYearFromCode('25010609'), 2025);
    expect(Student.enrollYearFromCode('abc'), isNull);
  });

  test('tiến độ: năm học, mức cảnh báo, chậm tiến độ', () {
    expect(good.progress.yearOfStudy, 2);
    expect(third.progress.yearOfStudy, 3);
    expect(good.progress.academicLevel, WarnLevel.none);
    expect(good.progress.behindSchedule, isFalse);
    // Nợ đọng 30 TC (> 24) → Mức 3.
    expect(bad.progress.academicLevel, WarnLevel.high);
    expect(bad.progress.behindSchedule, isTrue);
  });

  test('lọc theo mẫu báo cáo', () {
    List<String> names(ReportFilter f) => [
          for (final d in applyReport(all, f, ReportOrder.byCode))
            d.student.fullName
        ];
    expect(names(const ReportFilter(years: {2})),
        ['Nguyễn Văn An', 'Trần Thị Bình']);
    expect(names(const ReportFilter(years: {2, 3})).length, 3);
    expect(names(const ReportFilter(academicLevels: {WarnLevel.high})),
        ['Trần Thị Bình']);
    expect(names(const ReportFilter(academicLevels: {WarnLevel.low})), isEmpty);
    expect(names(const ReportFilter(progress: ProgressFilter.onTrack)),
        isNot(contains('Trần Thị Bình')));
    expect(names(const ReportFilter(debt: DebtFilter.hasDebt)),
        ['Trần Thị Bình']);
    expect(names(const ReportFilter(cpaBelow: 2.0)), ['Trần Thị Bình']);
    expect(names(const ReportFilter(classes: {'QT2'})), ['Lê Văn Cường']);
  });

  test('sắp xếp theo tên kiểu Việt Nam (theo tên, không theo họ)', () {
    final sorted = applyReport(
        all, const ReportFilter(), const ReportOrder(ReportColumn.name));
    expect(sorted.map((d) => d.student.fullName.split(' ').last),
        ['An', 'Bình', 'Cường']);
    final desc = applyReport(all, const ReportFilter(),
        const ReportOrder(ReportColumn.name, ascending: false));
    expect(desc.first.student.fullName, 'Lê Văn Cường');
  });

  test('so sánh theo bảng chữ cái tiếng Việt', () {
    final names = ['Đào', 'Dung', 'Ánh', 'Anh', 'Ân', 'Bảo', 'Ẩn', 'Yến', 'Ý'];
    expect(names..sort(vnCompare),
        ['Anh', 'Ánh', 'Ân', 'Ẩn', 'Bảo', 'Dung', 'Đào', 'Ý', 'Yến']);
    expect(['QH-2025-S QL.02', 'QH-2023-S N1', 'QH-2025-S QL.01']..sort(vnCompare),
        ['QH-2023-S N1', 'QH-2025-S QL.01', 'QH-2025-S QL.02']);
  });

  test('sắp xếp theo cột như Excel (lớp, khóa, CPA; giảm dần)', () {
    List<String> codes(ReportOrder o) => [
          for (final d in applyReport(all, const ReportFilter(), o))
            d.student.studentCode
        ];
    // Lớp QT1 trước QT2; cùng lớp thì theo MSSV.
    expect(codes(const ReportOrder(ReportColumn.className)),
        [good.student.studentCode, bad.student.studentCode, third.student.studentCode]);
    // Khóa giảm dần: K2025 trước K2024.
    expect(codes(const ReportOrder(ReportColumn.cohort, ascending: false)).last,
        third.student.studentCode);
    expect(codes(const ReportOrder(ReportColumn.cpa)).first,
        bad.student.studentCode);
  });

  test('mô tả tiêu chí', () {
    const f = ReportFilter(
        academicLevels: {WarnLevel.low}, years: {3, 2}, cpaBelow: 2);
    expect(f.describe(),
        ['Cảnh báo học tập: Mức 1', 'Năm thứ 2, 3', 'CPA < 2.00']);
  });

  ReportData report() => ReportData(
        title: 'Danh sách sinh viên năm 2',
        criteria: const ['Năm thứ 2'],
        columns: ReportColumn.defaultList,
        rows: applyReport(all, const ReportFilter(years: {2}), ReportOrder.byCode),
        generatedBy: 'Quản trị',
        generatedAt: DateTime(2026, 10, 5, 9, 30),
      );

  test('xuất Excel đọc lại được, có tiêu đề + dữ liệu + trang thống kê', () {
    final bytes = ReportExporter.buildExcel(report());
    final book = xl.Excel.decodeBytes(bytes);
    expect(book.tables.keys, containsAll(['Danh sách', 'Thống kê']));
    final sheet = book.tables['Danh sách']!;
    String text(int col, int row) =>
        '${sheet.cell(xl.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value}';
    expect(text(0, 1), 'DANH SÁCH SINH VIÊN NĂM 2');
    expect(text(1, 5), 'MSSV'); // dòng tiêu đề cột
    expect(text(2, 6), 'Nguyễn Văn An');
    expect(text(2, 7), 'Trần Thị Bình');
    expect(sheet.maxRows, 8);
  });

  test('xuất PDF với font tiếng Việt', () async {
    pw.Font font(String f) =>
        pw.Font.ttf(File('assets/fonts/$f').readAsBytesSync().buffer.asByteData());
    final bytes = await ReportExporter.buildPdf(report(),
        regular: font('BeVietnamPro-Regular.ttf'),
        bold: font('BeVietnamPro-Bold.ttf'));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(5000));
  });

  test('tên file gợi ý bỏ ký tự không hợp lệ', () {
    final r = ReportData(
      title: 'DS: SV/năm 2?',
      criteria: const [],
      columns: const [ReportColumn.code],
      rows: const [],
      generatedBy: 'x',
      generatedAt: DateTime(2026, 10, 5, 9, 30),
    );
    expect(ReportExporter.suggestedName(r, ExportFormat.pdf),
        'DS_SVnăm_2_20261005_0930.pdf');
  });
}

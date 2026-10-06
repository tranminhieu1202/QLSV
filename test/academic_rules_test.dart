import 'package:flutter_test/flutter_test.dart';
import 'package:qlgd_edu/data/academic_service.dart';
import 'package:qlgd_edu/models/academic.dart';
import 'package:qlgd_edu/models/course.dart';
import 'package:qlgd_edu/models/enrollment.dart';
import 'package:qlgd_edu/models/student.dart';

// Quy chế đào tạo đại học tại ĐHQGHN – QĐ 3626/QĐ-ĐHQGHN ngày 21/10/2022.

Course _course(int id, {int credits = 3}) => Course(
      id: id,
      code: 'C$id',
      name: 'Học phần $id',
      credits: credits,
      mandatory: true,
      plannedSemester: 1,
      semesterText: '1',
      block: 'I',
      blockName: 'I',
    );

final _student = Student(
  id: 1,
  studentCode: '24010001',
  fullName: 'Nguyễn Văn An',
  cohort: 'QH-2024',
  className: 'QT1',
  major: 'QTTH',
  enrollYear: 2024,
  status: 'active',
);

var _nextId = 1;
Enrollment _enr(Course c, String term, double? g10) => Enrollment(
      id: _nextId++,
      studentId: 1,
      courseId: c.id,
      term: term,
      grade10: g10,
      gradeLetter: g10 == null ? null : GradeScale.letter(g10),
      grade4: g10 == null ? null : GradeScale.toFour(g10),
      status: g10 == null
          ? EnrollStatus.studying
          : GradeScale.isPass(g10)
              ? EnrollStatus.passed
              : EnrollStatus.failed,
      course: c,
    );

void main() {
  final courses = [for (var i = 1; i <= 12; i++) _course(i)];
  StudentProgress run(List<Enrollment> e) =>
      AcademicService.compute(_student, e, courses, term: '20261');

  test('thang điểm chữ & hệ 4 (Điều 41, 43)', () {
    expect([for (final g in [10.0, 9.0, 8.9, 8.5, 8.4, 8.0, 7.0, 6.5, 5.5, 5.0, 4.0, 3.9])
        GradeScale.letter(g)],
        ['A+', 'A+', 'A', 'A', 'B+', 'B+', 'B', 'C+', 'C', 'D+', 'D', 'F']);
    expect([for (final g in [9.0, 8.7, 8.2, 7.5, 6.7, 6.0, 5.2, 4.5, 3.0])
        GradeScale.toFour(g)],
        [4.0, 3.7, 3.5, 3.0, 2.5, 2.0, 1.5, 1.0, 0.0]);
    expect(GradeScale.standing(3.6), 'Xuất sắc');
    expect(GradeScale.standing(3.2), 'Giỏi');
    expect(GradeScale.standing(2.5), 'Khá');
    expect(GradeScale.standing(2.0), 'Trung bình');
    expect(GradeScale.standing(1.99), 'Yếu');
  });

  test('năm đào tạo theo TC tích lũy & ngưỡng CPA (Điều 17, 44)', () {
    expect([for (final c in [0, 34, 35, 70, 71, 105, 106, 140, 141])
        AcademicService.trainingYearFor(c)],
        [1, 1, 2, 2, 3, 3, 4, 4, 5]);
    expect([for (final y in [1, 2, 3, 4, 5]) AcademicService.cpaWarnThreshold(y)],
        [1.2, 1.4, 1.6, 1.8, 1.8]);
  });

  test('cảnh báo liên tiếp: lần 1 → lần 2 → buộc thôi học, hết khi học tốt', () {
    List<Enrollment> failTerm(String t) =>
        [for (final c in courses.take(4)) _enr(c, t, 2.0)];
    var e = [...failTerm('20241')];
    expect(run(e).academicLevel, WarnLevel.low);
    e = [...e, ...failTerm('20242')];
    expect(run(e).academicLevel, WarnLevel.medium);
    e = [...e, ...failTerm('20251')];
    final p3 = run(e);
    expect(p3.academicLevel, WarnLevel.high);
    expect(p3.warnings.first.title, 'Thuộc diện buộc thôi học');
    expect(p3.warnings.first.official, isTrue);
    // Học kỳ sau đạt hết → không còn bị cảnh báo.
    e = [...e, for (final c in courses) _enr(c, '20252', 8.0)];
    expect(run(e).academicLevel, WarnLevel.none);
  });

  test('GPA học kỳ đầu dưới 0,80 bị cảnh báo', () {
    // Kỳ đầu: 1 HP D (1.0) + 1 HP F → GPA 0.5 < 0.8; trượt 50% (không > 50%).
    final first = [_enr(courses[0], '20241', 4.0), _enr(courses[1], '20241', 1.0)];
    final p = run(first);
    expect(p.terms.single.gpa, 0.5);
    expect(p.terms.single.warnReasons, contains(startsWith('GPA học kỳ 0.50')));
  });

  test('kỳ hè gộp vào học kỳ chính ngay trước (Điều 44)', () {
    final e = [
      for (final c in courses.take(4)) _enr(c, '20242', 2.0), // trượt 12 TC
      for (final c in courses.skip(4).take(4)) _enr(c, '20243', 8.0), // hè đạt 12 TC
    ];
    final p = run(e);
    expect(p.terms.map((t) => t.term), ['20242']);
    expect(p.terms.single.registeredCredits, 24);
    expect(p.terms.single.gpa, 1.75); // (12×0 + 12×3.5) / 24
    // Trượt đúng 50% (không vượt), CPA 3.5, nợ 12 TC → không bị cảnh báo.
    expect(p.academicLevel, WarnLevel.none);
    // Không có kỳ hè thì trượt 100% → cảnh báo.
    expect(run(e.where((x) => x.term == '20242').toList()).academicLevel,
        WarnLevel.low);
  });

  test('CPA chỉ tính HP đã đạt, học cải thiện lấy lần đạt gần nhất', () {
    final e = [
      _enr(courses[0], '20241', 4.5), // D – 1.0
      _enr(courses[1], '20241', 3.0), // F – không tính vào CPA
      _enr(courses[0], '20242', 9.2), // cải thiện A+ – 4.0
    ];
    final p = run(e);
    expect(p.cpa, 4.0);
    expect(p.terms.last.cumulativeCredits, 3); // HP 1 chỉ tích lũy một lần
    expect(p.debtCredits, 3);
    expect(p.terms.first.gpa, 0.5); // GPA kỳ tính cả HP không đạt
  });

  test('tên học kỳ & danh sách kỳ để khai báo', () {
    expect(AcademicService.termLabel('20251'), 'HK1 2025–2026');
    expect(AcademicService.termLabel('20252'), 'HK2 2025–2026');
    expect(AcademicService.termLabel('20253'), 'Hè 2025–2026');
    expect(AcademicService.mainTermOf('20253'), '20252');
    final opts = AcademicService.termOptions(_student, '20261');
    expect(opts.first, '20263');
    expect(opts.last, '20241');
    expect(opts.length, 9);
  });

  test('học phần chưa có điểm không làm thay đổi cảnh báo', () {
    final e = [for (final c in courses.take(4)) _enr(c, '20261', null)];
    final p = run(e);
    expect(p.academicLevel, WarnLevel.none);
    expect(p.terms.single.standing, isEmpty);
  });
}

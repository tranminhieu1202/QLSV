import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qlgd_edu/data/academic_service.dart';
import 'package:qlgd_edu/models/course.dart';
import 'package:qlgd_edu/models/enrollment.dart';
import 'package:qlgd_edu/models/student.dart';
import 'package:qlgd_edu/widgets/graduation_view.dart';

void main() {
  testWidgets('tab điều kiện tốt nghiệp hiển thị khối và kết luận',
      (tester) async {
    Course mk(int id, String block, int tc,
            {bool mandatory = false, bool conditional = false}) =>
        Course(
          id: id,
          code: 'C$id',
          name: 'Học phần $id',
          credits: tc,
          mandatory: mandatory,
          conditional: conditional,
          plannedSemester: 1,
          semesterText: '1',
          block: block,
          blockName: block,
        );
    final cs = [
      mk(1, 'I', 3, mandatory: true),
      mk(2, 'II.2', 3),
      mk(3, 'II.2', 3),
      mk(4, 'V.3.1', 3),
      mk(5, 'I', 4, mandatory: true, conditional: true),
    ];
    final s = Student(
      id: 1,
      studentCode: '25010001',
      fullName: 'Nguyễn Văn An',
      cohort: 'QH-2025',
      className: 'QT1',
      major: 'QTTH',
      enrollYear: 2025,
      status: 'active',
    );
    final e = [
      Enrollment(
        id: 1,
        studentId: 1,
        courseId: 1,
        term: '20251',
        grade10: 8,
        gradeLetter: 'B+',
        grade4: 3.5,
        status: EnrollStatus.passed,
        course: cs[0],
      ),
    ];
    final p = AcademicService.compute(s, e, cs, term: '20261');
    await tester.binding.setSurfaceSize(const Size(1000, 1600));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: GraduationView(progress: p, enrollments: e, courses: cs)),
    ));
    expect(find.text('Chưa đủ điều kiện tốt nghiệp'), findsOneWidget);
    expect(find.text('I. Khối kiến thức chung'), findsOneWidget);
    expect(find.textContaining('Tự chọn 3/6 TC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

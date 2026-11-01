import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qlgd_edu/data/academic_service.dart';
import 'package:qlgd_edu/data/repository.dart';
import 'package:qlgd_edu/models/course.dart';
import 'package:qlgd_edu/models/enrollment.dart';
import 'package:qlgd_edu/models/student.dart';
import 'package:qlgd_edu/models/user.dart';
import 'package:qlgd_edu/providers/app_state.dart';
import 'package:qlgd_edu/screens/faculty/graduation_screen.dart';
import 'package:qlgd_edu/screens/student/student_courses_screen.dart';
import 'package:qlgd_edu/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _student = Student(
  id: 1,
  studentCode: '25010001',
  fullName: 'Nguyễn Văn An',
  cohort: 'QH-2025',
  className: 'QTTH1',
  major: 'QTTH',
  enrollYear: 2025,
  status: 'active',
);

final _courses = [
  for (var sem = 1; sem <= 8; sem++)
    for (var k = 0; k < 4; k++)
      Course(
        id: sem * 10 + k,
        code: 'HP$sem$k',
        name: 'Học phần kỳ $sem số $k có tên khá dài để thử xuống dòng',
        credits: 3,
        mandatory: k < 3,
        plannedSemester: sem,
        semesterText: '$sem',
        block: k < 3 ? 'I' : 'II.2',
        blockName: 'I',
      ),
  const Course(
    id: 900,
    code: 'PES1001',
    name: 'Giáo dục thể chất',
    credits: 4,
    mandatory: true,
    conditional: true,
    plannedSemester: 2,
    semesterText: '2-7',
    block: 'I',
    blockName: 'I',
  ),
];

final _enrollments = [
  for (final c in _courses.where((c) => c.plannedSemester == 1))
    Enrollment(
      id: c.id,
      studentId: 1,
      courseId: c.id,
      term: '20251',
      grade10: 7.5,
      gradeLetter: 'B',
      grade4: 3.0,
      status: EnrollStatus.passed,
      course: c,
    ),
];

class _FakeRepo extends Repository {
  _FakeRepo(super.sb);

  @override
  Future<Student?> studentByCode(String code) async => _student;
  @override
  Future<List<Course>> courses() async => _courses;
  @override
  Future<List<Enrollment>> enrollmentsForStudent(int studentId) async =>
      _enrollments;
  @override
  Future<List<StudentWithProgress>> studentsWithProgress({
    String? advisorId,
    String? search,
    String? cohort,
  }) async => [
    StudentWithProgress(
      _student,
      AcademicService.compute(_student, _enrollments, _courses, term: '20261'),
      enrollments: _enrollments,
      courses: _courses,
    ),
  ];
}

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root == null) return;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> f(String n) async =>
      ByteData.sublistView(await File('$dir/$n').readAsBytes());
  await (FontLoader('Roboto')
        ..addFont(f('roboto-regular.ttf'))
        ..addFont(f('roboto-medium.ttf'))
        ..addFont(f('roboto-bold.ttf')))
      .load();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(f('materialicons-regular.otf'))).load();
}

Future<void> _pump(WidgetTester tester, Widget page, UserRole role) async {
  await tester.runAsync(_loadFonts);
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final sb = SupabaseClient(
    'http://localhost:54321',
    'test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final state = AppState(sb, repo: _FakeRepo(sb))
    ..debugSetUser(
      AppUser(id: 'u1', username: 'u', role: role, fullName: 'Người dùng'),
    );
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(20), child: page),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('màn Khai báo học tập: tiêu đề không bị ép dọc, nhập cả kỳ', (
    tester,
  ) async {
    await _pump(
      tester,
      const StudentCoursesScreen(studentCode: '25010001'),
      UserRole.student,
    );
    expect(tester.takeException(), isNull);
    final title = find.text('Khai báo học phần & điểm');
    expect(title, findsOneWidget);
    // Tiêu đề nằm trên một dòng (lỗi cũ: bề rộng 0, mỗi chữ một dòng).
    expect(tester.getSize(title).width, greaterThan(200));
    expect(tester.getSize(title).height, lessThan(40));

    await tester.tap(find.text('Nhập điểm cả kỳ'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Nhập điểm cả học kỳ'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '8.5');
    await tester.pumpAndSettle();
    expect(find.textContaining('(hệ 4): 3.70'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // GDTC: không có ô điểm, chỉ chọn Đạt / Không đạt.
    expect(find.text('PES1001 · Giáo dục thể chất'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Đạt'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Không đạt'), findsOneWidget);
    final fields = find.byType(TextField).evaluate().length;
    await tester.tap(find.widgetWithText(ChoiceChip, 'Đạt'));
    await tester.pumpAndSettle();
    expect(find.text('Không tính điểm TB'), findsOneWidget);
    expect(find.text('Lưu 2 học phần'), findsOneWidget);
    // Không thêm ô điểm nào cho GDTC; điểm TB kỳ không đổi.
    expect(find.byType(TextField).evaluate().length, fields);
    expect(find.textContaining('(hệ 4): 3.70'), findsOneWidget);
  });

  testWidgets('màn Xét tốt nghiệp hiển thị danh sách', (tester) async {
    await _pump(tester, const GraduationScreen(), UserRole.admin);
    expect(tester.takeException(), isNull);
    expect(find.text('Xét điều kiện tốt nghiệp'), findsOneWidget);
    expect(find.text('Chưa đủ'), findsWidgets);
  });
}

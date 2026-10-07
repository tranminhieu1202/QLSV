import 'dart:io';
import 'dart:math';

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
import 'package:qlgd_edu/screens/faculty/dashboard_screen.dart';
import 'package:qlgd_edu/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeRepo extends Repository {
  _FakeRepo(super.sb, this.data);
  final List<StudentWithProgress> data;

  @override
  Future<List<StudentWithProgress>> studentsWithProgress({
    String? advisorId,
    String? search,
    String? cohort,
  }) async => data;
}

/// 60 sinh viên giả lập ở 4 khóa với năng lực khác nhau.
List<StudentWithProgress> _fakeData() {
  final rnd = Random(7);
  var id = 0;
  final courses = [
    for (var sem = 1; sem <= 8; sem++)
      for (var k = 0; k < 5; k++)
        Course(
          id: ++id,
          code: 'HP$sem$k',
          name: 'Học phần $sem.$k',
          credits: 3,
          mandatory: true,
          plannedSemester: sem,
          semesterText: '$sem',
          block: 'I',
          blockName: 'I',
        ),
  ];
  final out = <StudentWithProgress>[];
  var eid = 0;
  for (var i = 0; i < 60; i++) {
    final year = 2023 + i % 4;
    final s = Student(
      id: i + 1,
      studentCode: '${year % 100}01${(1000 + i).toString()}',
      fullName: 'Sinh viên ${String.fromCharCode(65 + i % 26)} số $i',
      cohort: 'QH-$year',
      className: 'QTTH${i % 3 + 1}',
      major: 'QTTH',
      enrollYear: year,
      status: 'active',
    );
    final ability = 3.0 + rnd.nextDouble() * 6.5; // điểm trung bình hệ 10
    final curSem = AcademicService.currentSemester(s, term: '20261');
    final enr = <Enrollment>[];
    for (var sem = 1; sem < curSem; sem++) {
      final term = '${year + (sem - 1) ~/ 2}${sem.isOdd ? 1 : 2}';
      for (final c in courses.where((c) => c.plannedSemester == sem)) {
        if (rnd.nextDouble() < 0.1) continue; // chưa học
        final g = (ability + rnd.nextDouble() * 3 - 1.5).clamp(0.0, 10.0);
        final g10 = double.parse(g.toStringAsFixed(1));
        enr.add(
          Enrollment(
            id: ++eid,
            studentId: s.id,
            courseId: c.id,
            term: term,
            grade10: g10,
            grade4: GradeScale.toFour(g10),
            status: GradeScale.isPass(g10)
                ? EnrollStatus.passed
                : EnrollStatus.failed,
            course: c,
          ),
        );
      }
    }
    out.add(
      StudentWithProgress(
        s,
        AcademicService.compute(s, enr, courses, term: '20261'),
      ),
    );
  }
  return out;
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

Future<void> _pumpDashboard(WidgetTester tester, Size size) async {
  await tester.runAsync(_loadFonts);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final sb = SupabaseClient(
    'http://localhost:54321',
    'test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  final state = AppState(sb, repo: _FakeRepo(sb, _fakeData()))
    ..debugSetUser(
      const AppUser(
        id: 'u1',
        username: 'admin',
        role: UserRole.admin,
        fullName: 'Quản trị',
      ),
    );

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Padding(padding: EdgeInsets.all(20), child: DashboardScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('màn hẹp: các thẻ xếp một cột, không tràn bố cục', (
    tester,
  ) async {
    await _pumpDashboard(tester, const Size(900, 3000));
    expect(find.text('Sinh viên cần chú ý'), findsOneWidget);
  });

  testWidgets('màn Tổng quan hiển thị đủ chỉ số, biểu đồ, không tràn bố cục', (
    tester,
  ) async {
    await _pumpDashboard(tester, const Size(1440, 1300));

    expect(find.text('Tổng quan đào tạo'), findsOneWidget);
    expect(find.text('Cảnh báo học vụ theo năm học'), findsOneWidget);
    expect(find.text('Phân bố CPA theo xếp loại'), findsOneWidget);
    expect(find.text('Sinh viên cần chú ý'), findsOneWidget);

    // Chuyển một biểu đồ sang dạng bảng.
    await tester.tap(find.byTooltip('Xem dạng bảng').first);
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    await tester.tap(find.byTooltip('Xem biểu đồ').first);
    await tester.pumpAndSettle();

    // Lọc theo khóa.
    await tester.tap(find.text('Tất cả khóa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('QH-2024').last);
    await tester.pumpAndSettle();
    expect(find.text('QH-2024'), findsWidgets);

    if (Platform.environment['DASHBOARD_SHOT'] case final path?) {
      await tester.tap(find.text('QH-2024'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tất cả khóa').last);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(Uri.file(path)),
      );
    }
  });
}

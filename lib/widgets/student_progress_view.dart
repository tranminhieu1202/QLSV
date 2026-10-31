import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/academic_service.dart';
import '../models/academic.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'course_declaration_dialog.dart';
import 'graduation_view.dart';

/// Full academic profile of one student. Shared by faculty (student detail)
/// and by the student's own portal.
class StudentProgressView extends StatefulWidget {
  const StudentProgressView({
    super.key,
    required this.student,
    this.canEditGrades = false,
  });

  final Student student;
  final bool canEditGrades;

  @override
  State<StudentProgressView> createState() => _StudentProgressViewState();
}

class _StudentProgressViewState extends State<StudentProgressView>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 5, vsync: this);
  List<Enrollment> _enrollments = [];
  List<Course> _courses = [];
  StudentProgress? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final repo = state.repo;
    final term = state.currentTerm;
    final courses = await repo.courses();
    final enrollments = await repo.enrollmentsForStudent(widget.student.id);
    final progress =
        AcademicService.compute(widget.student, enrollments, courses,
            term: term);
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _enrollments = enrollments;
      _progress = progress;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _progress == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final p = _progress!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _summaryCards(p),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Điểm tổng hợp'),
              Tab(text: 'Điểm chi tiết'),
              Tab(text: 'Tiến trình đào tạo'),
              Tab(text: 'Điều kiện tốt nghiệp'),
              Tab(text: 'Cảnh báo'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _termSummaryTab(p),
              _gradesTab(),
              _curriculumTab(),
              GraduationView(
                  progress: p,
                  enrollments: _enrollments,
                  courses: _courses),
              _warningsTab(p),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------- summary row
  Widget _summaryCards(StudentProgress p) {
    return LayoutBuilder(builder: (context, c) {
      final cards = [
        StatCard(
          title: 'CPA tích lũy',
          value: p.cpa.toStringAsFixed(2),
          icon: Icons.grade,
          color: p.cpa >= 2.0 ? AppColors.ok : AppColors.danger,
          subtitle: 'GPA kỳ gần nhất: ${p.latestGpa.toStringAsFixed(2)}',
        ),
        StatCard(
          title: 'Tín chỉ tích lũy',
          value: '${p.passedCredits}/${p.totalProgramCredits}',
          icon: Icons.stacked_bar_chart,
          color: AppColors.info,
          subtitle: 'Còn thiếu ${p.remainingCredits} TC',
        ),
        StatCard(
          title: 'Tín chỉ nợ',
          value: '${p.debtCredits}',
          icon: Icons.report_gmailerrorred,
          color: p.debtCredits == 0 ? AppColors.ok : AppColors.danger,
          subtitle: 'Học phần chưa đạt',
        ),
        StatCard(
          title: 'Kỳ hiện tại',
          value: 'Kỳ ${p.currentSemesterNo}/8',
          icon: Icons.timelapse,
          color: AppColors.primary,
          subtitle: 'Tiến độ ${(p.completionRate * 100).toStringAsFixed(0)}%',
        ),
      ];
      final width = (c.maxWidth - 3 * 12) / 4;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: cards
            .map((w) => SizedBox(
                width: c.maxWidth < 720 ? c.maxWidth : width, child: w))
            .toList(),
      );
    });
  }

  // ------------------------------------------------- tab 1: term summaries
  Widget _termSummaryTab(StudentProgress p) {
    if (p.terms.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu học tập.'));
    }
    return SingleChildScrollView(
      child: Card(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(AppColors.tableHeader),
            columns: const [
              DataColumn(label: Text('Học kỳ')),
              DataColumn(label: Text('Điểm TB học kỳ (hệ 4)')),
              DataColumn(label: Text('Học lực')),
              DataColumn(label: Text('CPA (hệ 4)')),
              DataColumn(label: Text('TC đăng ký')),
              DataColumn(label: Text('TC đạt')),
              DataColumn(label: Text('TC nợ')),
              DataColumn(label: Text('TC tích lũy')),
              DataColumn(label: Text('Cảnh báo')),
            ],
            rows: [
              for (final t in p.terms)
                DataRow(cells: [
                  DataCell(Text(AcademicService.termLabel(t.term),
                      style:
                          const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(t.standing.isEmpty
                      ? '-'
                      : t.gpa.toStringAsFixed(2))),
                  DataCell(Text(t.standing.isEmpty ? '-' : t.standing)),
                  DataCell(Text(t.cpa.toStringAsFixed(2))),
                  DataCell(_creditCell(t.registeredCredits)),
                  DataCell(Text('${t.passedCredits}')),
                  DataCell(Text('${t.debtCredits}',
                      style: TextStyle(
                          color: t.debtCredits > 0
                              ? AppColors.danger
                              : AppColors.textDark))),
                  DataCell(Text('${t.cumulativeCredits}')),
                  DataCell(t.warnReasons.isEmpty
                      ? LevelBadge(level: t.level)
                      : Tooltip(
                          message: t.warnReasons.join('\n'),
                          child: LevelBadge(level: t.level),
                        )),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _creditCell(int credits) {
    final limits = AcademicService.creditLimits(_courses);
    Color? c;
    if (credits > 0 && credits < limits.min) c = AppColors.danger;
    if (credits > limits.max) c = const Color(0xFFEF6C00);
    return Text('$credits',
        style: TextStyle(
            color: c, fontWeight: c != null ? FontWeight.bold : null));
  }

  // ---------------------------------------------------- tab 2: detailed grades
  Widget _gradesTab() {
    final graded = _enrollments.toList();
    if (graded.isEmpty) {
      return const Center(child: Text('Chưa có học phần nào.'));
    }
    return SingleChildScrollView(
      child: Card(
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(AppColors.tableHeader),
            columns: const [
              DataColumn(label: Text('Mã HP')),
              DataColumn(label: Text('Tên học phần')),
              DataColumn(label: Text('TC')),
              DataColumn(label: Text('Loại')),
              DataColumn(label: Text('Kỳ')),
              DataColumn(label: Text('Điểm 10')),
              DataColumn(label: Text('Điểm chữ')),
              DataColumn(label: Text('Điểm 4')),
              DataColumn(label: Text('Trạng thái')),
            ],
            rows: [
              for (final e in graded)
                DataRow(cells: [
                  DataCell(Text(e.course?.code ?? '')),
                  DataCell(SizedBox(
                      width: 260, child: Text(e.course?.name ?? ''))),
                  DataCell(Text('${e.course?.credits ?? 0}')),
                  DataCell(Text(e.course?.typeLabel ?? '')),
                  DataCell(Text(e.term)),
                  DataCell(_gradeCell(e)),
                  DataCell(Text(e.letterText)),
                  DataCell(Text(e.fourText)),
                  DataCell(EnrollStatusChip(e.status)),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  /// Điểm học phần hệ 10; sinh viên bấm vào để sửa.
  Widget _gradeCell(Enrollment e) {
    final grade = Text(e.grade10?.toStringAsFixed(1) ?? '-',
        style: const TextStyle(fontWeight: FontWeight.w600));
    if (!widget.canEditGrades) return grade;
    return InkWell(
      onTap: () => _editGradesDialog(e),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          grade,
          const SizedBox(width: 4),
          const Icon(Icons.edit, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Future<void> _editGradesDialog(Enrollment e) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CourseDeclarationDialog(
        student: widget.student,
        courses: _courses,
        enrollments: _enrollments,
        editing: e,
      ),
    );
    if (saved == true && mounted) await _load();
  }

  // ------------------------------------------------ tab 3: curriculum/progress
  Widget _curriculumTab() {
    final passedIds = <int>{};
    final statusByCourse = <int, EnrollStatus>{};
    for (final e in _enrollments) {
      if (e.status == EnrollStatus.passed) {
        passedIds.add(e.courseId);
      }
      // latest status wins (enrollments already sorted by term)
      statusByCourse[e.courseId] = e.status;
      if (passedIds.contains(e.courseId)) {
        statusByCourse[e.courseId] = EnrollStatus.passed;
      }
    }

    final bySemester = <int, List<Course>>{};
    for (final c in _courses) {
      bySemester.putIfAbsent(c.plannedSemester, () => []).add(c);
    }
    final semesters = bySemester.keys.toList()..sort();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final sem in semesters) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('Học kỳ $sem',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${bySemester[sem]!.fold(0, (s, c) => s + c.credits)} TC dự kiến',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Card(
              child: Column(
                children: [
                  for (final c in bySemester[sem]!)
                    _curriculumRow(c, statusByCourse[c.id]),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _curriculumRow(Course c, EnrollStatus? status) {
    IconData icon;
    Color color;
    String label;
    switch (status) {
      case EnrollStatus.passed:
        icon = Icons.check_circle;
        color = AppColors.ok;
        label = 'Đã đạt';
        break;
      case EnrollStatus.failed:
        icon = Icons.cancel;
        color = AppColors.danger;
        label = 'Chưa đạt';
        break;
      case EnrollStatus.studying:
        icon = Icons.autorenew;
        color = AppColors.info;
        label = 'Đang học';
        break;
      default:
        icon = Icons.radio_button_unchecked;
        color = AppColors.textMuted;
        label = 'Chưa học';
    }
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text('${c.code} · ${c.name}'),
      subtitle: Text('${c.credits} TC · ${c.typeLabel} · ${c.block}'),
      trailing: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  // ------------------------------------------------------- tab 4: warnings
  Widget _warningsTab(StudentProgress p) {
    if (p.warnings.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.verified, color: AppColors.ok, size: 48),
            SizedBox(height: 12),
            Text('Không có cảnh báo. Sinh viên đang học tập bình thường.'),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: p.warnings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final w = p.warnings[i];
        final c = warnColor(w.level);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: c.withValues(alpha: 0.15),
                      child: Icon(Icons.warning_amber, color: c),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(w.detail,
                              style:
                                  const TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    LevelBadge(level: w.level),
                  ],
                ),
                if (w.courses.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  for (final wc in w.courses) _warningCourseRow(wc),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _warningCourseRow(WarningCourse wc) {
    final Color color;
    switch (wc.status) {
      case 'failed':
        color = AppColors.danger;
        break;
      case 'retaking':
        color = AppColors.info;
        break;
      default:
        color = const Color(0xFFEF6C00);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text('${wc.code} · ${wc.name} (${wc.credits} TC)',
                style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(wc.statusLabel,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/academic_service.dart';
import '../../models/academic.dart';
import '../../models/course.dart';
import '../../models/enrollment.dart';
import '../../models/student.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/course_declaration_dialog.dart';
import '../../widgets/term_grade_entry_dialog.dart';
import '../../widgets/revision_reload.dart';

/// Sinh viên tự khai báo kỳ nào học học phần nào và được bao nhiêu điểm.
/// Không có kỳ đăng ký hay bước duyệt: lưu là có hiệu lực, cố vấn học tập,
/// ban đào tạo khoa và quản trị theo dõi ngay.
class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key, required this.studentCode});
  final String studentCode;

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen>
    with RevisionReload {
  Student? _student;
  List<Course> _courses = [];
  List<Enrollment> _enrollments = [];
  List<CourseSuggestion> _suggestions = [];
  StudentProgress? _progress;
  bool _loading = true;

  Future<void> _load() async {
    final state = context.read<AppState>();
    final repo = state.repo;
    final s = await repo.studentByCode(widget.studentCode);
    if (s == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final courses = await repo.courses();
    final enrollments = await repo.enrollmentsForStudent(s.id);
    if (!mounted) return;
    setState(() {
      _student = s;
      _courses = courses;
      _enrollments = enrollments;
      _progress = AcademicService.compute(
        s,
        enrollments,
        courses,
        term: state.currentTerm,
      );
      _suggestions = AcademicService.suggest(
        s,
        enrollments,
        courses,
        term: state.currentTerm,
        chosenDirection: s.direction,
      );
      _loading = false;
    });
  }

  Future<void> _declare({Enrollment? editing, Course? course}) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => CourseDeclarationDialog(
        student: _student!,
        courses: _courses,
        enrollments: _enrollments,
        editing: editing,
        initialCourse: course,
      ),
    );
  }

  Future<void> _enterTerm([String? term]) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TermGradeEntryDialog(
        student: _student!,
        courses: _courses,
        enrollments: _enrollments,
        initialTerm: term,
      ),
    );
  }

  Future<void> _delete(Enrollment e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa khai báo?'),
        content: Text(
          'Xóa ${e.course?.code} · ${e.course?.name} '
          'ở kỳ ${e.term} cùng điểm đã nhập?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final state = context.read<AppState>();
    await state.repo.deleteDeclaration(
      e,
      state.user!,
      studentCode: widget.studentCode,
    );
    await state.bumpData();
  }

  @override
  Widget build(BuildContext context) {
    watchRevision(_load);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_student == null) {
      return const Center(child: Text('Không tìm thấy hồ sơ sinh viên.'));
    }

    final byTerm = <String, List<Enrollment>>{};
    for (final e in _enrollments) {
      byTerm.putIfAbsent(e.term, () => []).add(e);
    }
    final terms = byTerm.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      children: [
        _headerCard(),
        const SizedBox(height: 16),
        _suggestionsCard(),
        const SizedBox(height: 16),
        if (terms.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Bạn chưa khai báo học phần nào. Bấm "Nhập điểm '
                  'cả kỳ" để nhập điểm các học phần của từng học kỳ.',
                ),
              ),
            ),
          ),
        for (final t in terms) ...[
          _termCard(t, byTerm[t]!),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _headerCard() {
    final p = _progress!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.edit_note, color: AppColors.primary, size: 36),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Khai báo học phần & điểm',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tự khai báo kỳ nào học học phần nào và điểm đạt được. '
                    'Lưu là có hiệu lực, không cần duyệt; cố vấn học tập và '
                    'ban đào tạo khoa theo dõi kết quả của bạn.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 20,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _metric('Đã khai báo', '${_enrollments.length} HP'),
                      _metric('TC tích lũy', '${p.passedCredits}'),
                      _metric('CPA', p.cpa.toStringAsFixed(2)),
                      _metric('Năm đào tạo', '${p.trainingYear}'),
                      LevelBadge(
                        level: p.academicLevel,
                        text: p.academicLevel == WarnLevel.none
                            ? 'Không bị cảnh báo'
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // IntrinsicWidth: hai nút cùng rộng mà không đòi bề rộng vô hạn
            // trong Row (stretch trần làm phần chữ bên trái bị ép về 0).
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _enterTerm(),
                    icon: const Icon(Icons.table_rows_outlined),
                    label: const Text('Nhập điểm cả kỳ'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _declare(),
                    icon: const Icon(Icons.add),
                    label: const Text('Khai báo từng học phần'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$label: ',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        TextSpan(
          text: value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );

  Widget _termCard(String term, List<Enrollment> list) {
    // Điểm TB học kỳ hệ 4 = Σ(hệ 4 × TC) / Σ TC của các học phần đã có điểm,
    // tính cả học phần không đạt (Điều 42 khoản 3). Học phần điều kiện (GDTC,
    // GDQP-AN...) chỉ xét Đạt/Không đạt nên không tính vào TC và điểm TB.
    var credits = 0, graded = 0;
    double quality = 0;
    for (final e in list) {
      if (e.passFailOnly) continue;
      final c = e.course?.credits ?? 0;
      credits += c;
      if (e.grade4 != null) {
        quality += e.grade4! * c;
        graded += c;
      }
    }
    final gpa = graded == 0 ? null : quality / graded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${AcademicService.termLabel(term)} ($term)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${list.length} học phần · $credits TC tính điểm'
                  '${gpa == null ? '' : ' · Điểm TB học kỳ (hệ 4): ${gpa.toStringAsFixed(2)} (${GradeScale.standing(gpa)})'}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _enterTerm(term),
                  icon: const Icon(Icons.table_rows_outlined, size: 18),
                  label: const Text('Nhập / sửa điểm kỳ này'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Mã HP')),
                  DataColumn(label: Text('Tên học phần')),
                  DataColumn(label: Text('TC'), numeric: true),
                  DataColumn(label: Text('Điểm 10'), numeric: true),
                  DataColumn(label: Text('Điểm chữ')),
                  DataColumn(label: Text('Điểm 4'), numeric: true),
                  DataColumn(label: Text('Trạng thái')),
                  DataColumn(label: Text('')),
                ],
                rows: [
                  for (final e in list)
                    DataRow(
                      cells: [
                        DataCell(Text(e.course?.code ?? '')),
                        DataCell(
                          SizedBox(
                            width: 260,
                            child: Text(e.course?.name ?? ''),
                          ),
                        ),
                        DataCell(Text('${e.course?.credits ?? 0}')),
                        DataCell(
                          Text(
                            e.grade10Text,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(Text(e.letterText)),
                        DataCell(Text(e.fourText)),
                        DataCell(EnrollStatusChip(e.status)),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Sửa kỳ / điểm',
                                icon: const Icon(Icons.edit, size: 18),
                                onPressed: () => _declare(editing: e),
                              ),
                              IconButton(
                                tooltip: 'Xóa',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                                onPressed: () => _delete(e),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionsCard() {
    final suggestions = _suggestions.take(6).toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();
    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: const Icon(Icons.tips_and_updates, color: AppColors.accent),
        title: const Text(
          'Gợi ý học phần nên học tiếp',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Dựa trên tiến trình đào tạo, học phần chưa đạt và điều kiện tiên quyết.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [for (final s in suggestions) _suggestionRow(s)],
      ),
    );
  }

  Widget _suggestionRow(CourseSuggestion s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 40,
            decoration: BoxDecoration(
              color: s.priority <= 1 ? AppColors.danger : AppColors.info,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${s.course.code} · ${s.course.name} (${s.course.credits} TC)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  s.prerequisiteMet
                      ? s.reason
                      : '${s.reason} · Thiếu tiên quyết ${s.course.prerequisite}',
                  style: TextStyle(
                    color: s.prerequisiteMet
                        ? AppColors.textMuted
                        : AppColors.danger,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _declare(course: s.course),
            child: const Text('Khai báo'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/academic_service.dart';
import '../../data/curriculum_seed.dart';
import '../../models/academic.dart';
import '../../models/course.dart';
import '../../models/enrollment.dart';
import '../../models/student.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/revision_reload.dart';

class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key, required this.studentCode});
  final String studentCode;

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen>
    with RevisionReload {
  Student? _student;
  List<Course> _courses = [];
  List<Enrollment> _enrollments = [];
  List<CourseSuggestion> _suggestions = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  bool _showAll = false;

  Future<void> _load() async {
    final state = context.read<AppState>();
    final repo = state.repo;
    final s = await repo.studentByCode(widget.studentCode);
    if (s == null) {
      setState(() => _loading = false);
      return;
    }
    final courses = await repo.courses();
    final enrollments = await repo.enrollmentsForStudent(s.id);
    final suggestions = AcademicService.suggest(s, enrollments, courses,
        term: state.currentTerm,
        chosenDirection: s.direction);
    if (!mounted) return;
    setState(() {
      _student = s;
      _courses = courses;
      _enrollments = enrollments;
      _suggestions = suggestions;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Set<int> get _passedIds => {
        for (final e in _enrollments)
          if (e.approval == Approval.approved && e.status == EnrollStatus.passed)
            e.courseId
      };

  List<Enrollment> get _thisTermRegs {
    final term = context.read<AppState>().currentTerm;
    return _enrollments
        .where((e) =>
            e.term == term &&
            e.approval != Approval.rejected &&
            (e.status == EnrollStatus.registered ||
                e.status == EnrollStatus.studying))
        .toList();
  }

  int get _currentCredits =>
      _thisTermRegs.fold(0, (s, e) => s + (e.course?.credits ?? 0));

  Future<void> _register(Course c) async {
    final state = context.read<AppState>();
    final err = await state.repo
        .registerCourse(student: _student!, course: c, actor: state.user!);
    await state.bumpData();
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.danger));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã đăng ký học phần ${c.code}.'),
          backgroundColor: AppColors.ok));
    }
  }

  Future<void> _cancel(Enrollment e) async {
    final state = context.read<AppState>();
    await state.repo.cancelRegistration(e, state.user!,
        studentCode: widget.studentCode);
    await state.bumpData();
  }

  @override
  Widget build(BuildContext context) {
    watchRevision(_load);
    final state = context.watch<AppState>();
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_student == null) {
      return const Center(child: Text('Không tìm thấy hồ sơ sinh viên.'));
    }

    return ListView(
      children: [
        _statusCard(state),
        const SizedBox(height: 16),
        if (!state.regOpen)
          Card(
            color: const Color(0xFFFFF3CD),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [
                Icon(Icons.info, color: Color(0xFF856404)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                      'Kỳ đăng ký hiện đang đóng. Bạn có thể xem gợi ý nhưng '
                      'chưa thể đăng ký. Vui lòng chờ quản trị mở kỳ đăng ký.',
                      style: TextStyle(color: Color(0xFF856404))),
                ),
              ]),
            ),
          ),
        if (!state.regOpen) const SizedBox(height: 16),
        _thisTermCard(state),
        const SizedBox(height: 16),
        _suggestionsCard(state),
        const SizedBox(height: 16),
        _allCoursesCard(state),
      ],
    );
  }

  Widget _statusCard(AppState state) {
    final credits = _currentCredits;
    final over = credits > CurriculumSeed.maxCreditsPerTerm;
    final under = credits < CurriculumSeed.minCreditsPerTerm;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.app_registration, color: AppColors.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Đăng ký học phần · Kỳ ${state.currentTerm}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    'Hướng ngành: ${_directionName(_student!.direction)} · '
                    '${state.regOpen ? "Đang mở đăng ký" : "Đã đóng đăng ký"}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$credits TC',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: (over || under)
                            ? AppColors.danger
                            : AppColors.ok)),
                Text(
                    'Giới hạn ${CurriculumSeed.minCreditsPerTerm}–${CurriculumSeed.maxCreditsPerTerm} TC/kỳ',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                if (over)
                  const Text('Vượt tối đa!',
                      style: TextStyle(color: AppColors.danger, fontSize: 12)),
                if (under)
                  const Text('Chưa đủ tối thiểu',
                      style: TextStyle(color: AppColors.warn, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _thisTermCard(AppState state) {
    final regs = _thisTermRegs;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Học phần đã đăng ký kỳ này (${regs.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (regs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Chưa đăng ký học phần nào cho kỳ này.',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            for (final e in regs)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  e.approval == Approval.pending
                      ? Icons.hourglass_top
                      : Icons.check_circle,
                  color: e.approval == Approval.pending
                      ? AppColors.warn
                      : AppColors.ok,
                ),
                title: Text('${e.course?.code} · ${e.course?.name}'),
                subtitle: Text('${e.course?.credits} TC · ${e.approval.label}'),
                trailing: e.status != EnrollStatus.passed &&
                        e.status != EnrollStatus.failed
                    ? TextButton.icon(
                        onPressed: () => _cancel(e),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Hủy'),
                        style:
                            TextButton.styleFrom(foregroundColor: AppColors.danger),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionsCard(AppState state) {
    final activeIds = {for (final e in _thisTermRegs) e.courseId};
    final suggestions =
        _suggestions.where((s) => !activeIds.contains(s.course.id)).take(8).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.tips_and_updates, color: AppColors.accent),
              SizedBox(width: 8),
              Text('Gợi ý đăng ký cho bạn',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 4),
            const Text(
                'Dựa trên tiến trình đào tạo, học phần chưa đạt và điều kiện tiên quyết.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            if (suggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Bạn đã đăng ký đủ các học phần được gợi ý.'),
              ),
            for (final s in suggestions) _suggestionRow(state, s),
          ],
        ),
      ),
    );
  }

  Widget _suggestionRow(AppState state, CourseSuggestion s) {
    final canReg = state.regOpen && s.prerequisiteMet;
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
                Text('${s.course.code} · ${s.course.name} (${s.course.credits} TC)',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  s.prerequisiteMet
                      ? s.reason
                      : '${s.reason} · Thiếu tiên quyết ${s.course.prerequisite}',
                  style: TextStyle(
                      color: s.prerequisiteMet
                          ? AppColors.textMuted
                          : AppColors.danger,
                      fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: canReg ? () => _register(s.course) : null,
            child: const Text('Đăng ký'),
          ),
        ],
      ),
    );
  }

  Widget _allCoursesCard(AppState state) {
    final passed = _passedIds;
    final activeIds = {for (final e in _thisTermRegs) e.courseId};
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = _courses
        .where((c) =>
            !c.conditional &&
            !passed.contains(c.id) &&
            !activeIds.contains(c.id))
        .toList();
    if (q.isNotEmpty) {
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.code.toLowerCase().contains(q))
          .toList();
    }
    final shown = _showAll ? list : list.take(12).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Tất cả học phần có thể đăng ký',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Tìm mã / tên học phần...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final c in shown)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${c.code} · ${c.name}'),
                subtitle: Text(
                    '${c.credits} TC · ${c.typeLabel} · ${c.block} · kỳ dự kiến ${c.plannedSemester}'),
                trailing: ElevatedButton(
                  onPressed: state.regOpen ? () => _register(c) : null,
                  child: const Text('Đăng ký'),
                ),
              ),
            if (list.length > shown.length || _showAll)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(_showAll
                      ? 'Thu gọn'
                      : 'Xem tất cả (${list.length} học phần)'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _directionName(int? d) {
    switch (d) {
      case 1:
        return 'QT hành chính nhà trường';
      case 2:
        return 'QT nhân lực và đào tạo';
      case 3:
        return 'Phát triển & QL chương trình GD';
      default:
        return 'Chưa chọn';
    }
  }
}

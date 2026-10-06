import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/academic_service.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

enum _GradeMode { overall, components, none }

/// Sinh viên tự khai báo (hoặc sửa) một học phần: học ở kỳ nào và được bao
/// nhiêu điểm. Không cần duyệt – lưu là có hiệu lực, cán bộ theo dõi ngay.
/// Trả về `true` khi đã lưu.
class CourseDeclarationDialog extends StatefulWidget {
  const CourseDeclarationDialog({
    super.key,
    required this.student,
    required this.courses,
    required this.enrollments,
    this.editing,
    this.initialCourse,
    this.initialTerm,
  });

  final Student student;
  final List<Course> courses;

  /// Các học phần sinh viên đã khai báo (để báo trùng / học cải thiện).
  final List<Enrollment> enrollments;

  /// Bản ghi đang sửa; null khi khai báo mới.
  final Enrollment? editing;
  final Course? initialCourse;
  final String? initialTerm;

  @override
  State<CourseDeclarationDialog> createState() =>
      _CourseDeclarationDialogState();
}

class _CourseDeclarationDialogState extends State<CourseDeclarationDialog> {
  final _courseCtrl = TextEditingController();
  final _overallCtrl = TextEditingController();
  final _midCtrl = TextEditingController();
  final _finalCtrl = TextEditingController();
  Course? _course;
  late String _term;
  late List<String> _terms;
  _GradeMode _mode = _GradeMode.overall;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    final state = context.read<AppState>();
    _course = e?.course ?? widget.initialCourse;
    _term = e?.term ?? widget.initialTerm ?? state.currentTerm;
    _terms = AcademicService.termOptions(widget.student, state.currentTerm,
        existing: [_term, for (final x in widget.enrollments) x.term]);
    if (e != null) {
      if (e.midterm != null) {
        _mode = _GradeMode.components;
        _midCtrl.text = e.midterm!.toStringAsFixed(1);
        _finalCtrl.text = e.finalExam?.toStringAsFixed(1) ?? '';
      } else if (e.finalExam != null) {
        _overallCtrl.text = e.finalExam!.toStringAsFixed(1);
      } else {
        _mode = _GradeMode.none;
      }
    }
  }

  @override
  void dispose() {
    _courseCtrl.dispose();
    _overallCtrl.dispose();
    _midCtrl.dispose();
    _finalCtrl.dispose();
    super.dispose();
  }

  static double? _parse(String s) {
    final v = double.tryParse(s.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > 10) return null;
    return v;
  }

  bool _invalid(TextEditingController c) =>
      c.text.trim().isNotEmpty && _parse(c.text) == null;

  /// (giữa kì, cuối kì) gửi lên máy chủ theo cách nhập đang chọn.
  (double?, double?) get _grades => switch (_mode) {
        _GradeMode.overall => (null, _parse(_overallCtrl.text)),
        _GradeMode.components => (
            _parse(_midCtrl.text),
            _parse(_finalCtrl.text)
          ),
        _GradeMode.none => (null, null),
      };

  String? get _note {
    final c = _course;
    if (c == null) return null;
    final others =
        widget.enrollments.where((x) => x.courseId == c.id && x.id != widget.editing?.id);
    if (others.any((x) => x.term == _term)) {
      return 'Học phần này đã được khai báo ở kỳ $_term.';
    }
    final passed = others.where((x) => x.status == EnrollStatus.passed);
    if (passed.isNotEmpty) {
      return 'Bạn đã đạt học phần này ở kỳ ${passed.last.term}. Khai báo thêm '
          'được tính là học cải thiện: lần đạt gần nhất thay điểm cũ khi tính CPA.';
    }
    if (others.any((x) => x.status == EnrollStatus.failed)) {
      return 'Học lại học phần đã không đạt.';
    }
    return null;
  }

  Future<void> _save() async {
    if (_course == null) {
      setState(() => _error = 'Chọn học phần.');
      return;
    }
    if (_invalid(_overallCtrl) || _invalid(_midCtrl) || _invalid(_finalCtrl)) {
      setState(() => _error = 'Điểm phải nằm trong khoảng 0 - 10.');
      return;
    }
    final (mid, fin) = _grades;
    setState(() {
      _saving = true;
      _error = null;
    });
    final state = context.read<AppState>();
    final e = widget.editing;
    final err = e == null
        ? await state.repo.declareCourse(
            student: widget.student,
            course: _course!,
            term: _term,
            midterm: mid,
            finalExam: fin,
            actor: state.user!)
        : await state.repo.updateDeclaration(
            e: e,
            term: _term,
            midterm: mid,
            finalExam: fin,
            actor: state.user!,
            studentCode: widget.student.studentCode);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    await state.bumpData();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.editing != null;
    return AlertDialog(
      title: Text(editing ? 'Sửa khai báo học phần' : 'Khai báo học phần'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (editing)
                Text('${_course?.code} · ${_course?.name} (${_course?.credits} TC)',
                    style: const TextStyle(fontWeight: FontWeight.w600))
              else
                _coursePicker(),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _term,
                decoration: const InputDecoration(labelText: 'Học kỳ'),
                items: [
                  for (final t in _terms)
                    DropdownMenuItem(
                        value: t,
                        child: Text('${AcademicService.termLabel(t)} ($t)')),
                ],
                onChanged: (v) => setState(() => _term = v ?? _term),
              ),
              const SizedBox(height: 16),
              SegmentedButton<_GradeMode>(
                segments: const [
                  ButtonSegment(
                      value: _GradeMode.overall, label: Text('Điểm học phần')),
                  ButtonSegment(
                      value: _GradeMode.components,
                      label: Text('Điểm thành phần')),
                  ButtonSegment(
                      value: _GradeMode.none, label: Text('Chưa có điểm')),
                ],
                selected: {_mode},
                onSelectionChanged: (v) => setState(() => _mode = v.first),
              ),
              const SizedBox(height: 12),
              ..._gradeFields(),
              const SizedBox(height: 12),
              _preview(),
              if (_note != null) ...[
                const SizedBox(height: 8),
                Text(_note!,
                    style: const TextStyle(
                        color: AppColors.info, fontSize: 12)),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context, false),
            child: const Text('Hủy')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Đang lưu...' : 'Lưu'),
        ),
      ],
    );
  }

  Widget _coursePicker() {
    final options = widget.courses.toList()
      ..sort((a, b) {
        final s = a.plannedSemester.compareTo(b.plannedSemester);
        return s != 0 ? s : a.code.compareTo(b.code);
      });
    return DropdownMenu<Course>(
      controller: _courseCtrl,
      initialSelection: _course,
      enableFilter: true,
      requestFocusOnTap: true,
      expandedInsets: EdgeInsets.zero,
      menuHeight: 320,
      label: const Text('Học phần (gõ mã hoặc tên để tìm)'),
      leadingIcon: const Icon(Icons.search),
      dropdownMenuEntries: [
        for (final c in options)
          DropdownMenuEntry(
            value: c,
            label: '${c.code} · ${c.name}',
            labelWidget: Text('${c.code} · ${c.name} (${c.credits} TC)'),
          ),
      ],
      onSelected: (c) => setState(() => _course = c),
    );
  }

  List<Widget> _gradeFields() {
    Widget field(TextEditingController c, String label, {bool focus = false}) =>
        TextField(
          controller: c,
          autofocus: focus,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: label, errorText: _invalid(c) ? '0 - 10' : null),
          onChanged: (_) => setState(() {}),
        );
    switch (_mode) {
      case _GradeMode.overall:
        return [field(_overallCtrl, 'Điểm học phần (hệ 10)', focus: true)];
      case _GradeMode.components:
        return [
          Row(children: [
            Expanded(child: field(_midCtrl, 'Điểm giữa kì / bộ phận')),
            const SizedBox(width: 12),
            Expanded(child: field(_finalCtrl, 'Điểm cuối kì')),
          ]),
        ];
      case _GradeMode.none:
        return const [
          Text('Học phần được ghi là "Đang học"; nhập điểm sau khi có kết quả.',
              style: TextStyle(color: AppColors.textMuted)),
        ];
    }
  }

  Widget _preview() {
    final (mid, fin) = _grades;
    final String text;
    if (_mode == _GradeMode.none) {
      text = 'Trạng thái: Đang học';
    } else if (fin == null) {
      text = _mode == _GradeMode.components
          ? 'Chưa có điểm học phần (cần điểm cuối kì). Trọng số: bộ phận '
              '${(GradeScale.midtermWeight * 100).round()}% · cuối kì '
              '${((1 - GradeScale.midtermWeight) * 100).round()}%'
          : 'Nhập điểm học phần hệ 10 như trên bảng điểm.';
    } else {
      final g = GradeScale.overall(mid, fin);
      text = 'Điểm học phần ${g.toStringAsFixed(1)} → '
          '${GradeScale.letter(g)} · hệ 4: ${GradeScale.toFour(g).toStringAsFixed(1)} · '
          '${GradeScale.isPass(g) ? 'Đạt' : 'Không đạt'}';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tableHeader,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

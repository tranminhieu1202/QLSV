import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/academic_service.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

/// Một dòng trong bảng nhập điểm cả kỳ.
class _Row {
  _Row(this.course, {this.existing, bool checked = false})
    : checked = checked || existing != null,
      passed = _passedOf(existing),
      ctrl = TextEditingController(
        text: course.conditional
            ? ''
            : existing?.grade10?.toStringAsFixed(1) ?? '',
      );

  final Course course;
  final Enrollment? existing; // đã khai báo ở kỳ này
  final TextEditingController ctrl;
  bool checked;
  String? error;

  /// Học phần điều kiện: true = Đạt, false = Không đạt, null = chưa có kết quả.
  bool? passed;

  static bool? _passedOf(Enrollment? e) => switch (e?.status) {
    EnrollStatus.passed => true,
    EnrollStatus.failed => false,
    _ => null,
  };

  bool get passFail => course.conditional;

  double? get grade {
    if (passFail) {
      return passed == null
          ? null
          : (passed! ? GradeScale.passMark : GradeScale.failMark);
    }
    final v = double.tryParse(ctrl.text.trim().replaceAll(',', '.'));
    if (v == null || v < 0 || v > 10) return null;
    return double.parse(v.toStringAsFixed(1));
  }

  bool get invalid => !passFail && ctrl.text.trim().isNotEmpty && grade == null;

  /// Đã tích nhưng chưa có điểm / kết quả → "Đang học".
  bool get pending => passFail ? passed == null : ctrl.text.trim().isEmpty;

  bool get changed {
    if (existing == null) return checked;
    if (passFail) return passed != _passedOf(existing);
    final old = existing!.grade10 == null
        ? null
        : double.parse(existing!.grade10!.toStringAsFixed(1));
    return grade != old;
  }
}

/// Nhập điểm cho cả một học kỳ trên một bảng: hệ thống liệt kê sẵn các học
/// phần theo kế hoạch của kỳ đó (và các học phần đã khai báo), sinh viên chỉ
/// cần gõ điểm hệ 10 rồi lưu một lần. Trả về `true` khi có lưu.
class TermGradeEntryDialog extends StatefulWidget {
  const TermGradeEntryDialog({
    super.key,
    required this.student,
    required this.courses,
    required this.enrollments,
    this.initialTerm,
  });

  final Student student;
  final List<Course> courses;
  final List<Enrollment> enrollments;
  final String? initialTerm;

  @override
  State<TermGradeEntryDialog> createState() => _TermGradeEntryDialogState();
}

class _TermGradeEntryDialogState extends State<TermGradeEntryDialog> {
  static final Map<int, String> _lastTerm = {};

  late String _term;
  late List<String> _terms;
  List<_Row> _rows = [];
  final _pickerCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _term =
        widget.initialTerm ?? _lastTerm[widget.student.id] ?? state.currentTerm;
    _terms = AcademicService.termOptions(
      widget.student,
      state.currentTerm,
      existing: [_term, for (final e in widget.enrollments) e.term],
    );
    _buildRows();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.ctrl.dispose();
    }
    _pickerCtrl.dispose();
    super.dispose();
  }

  /// Học phần có tổ chức ở học kỳ thứ [n] theo kế hoạch ("2-7" gồm 2..7).
  static bool _plannedIn(Course c, int n) {
    final m = RegExp(r'^\s*(\d+)\s*-\s*(\d+)\s*$').firstMatch(c.semesterText);
    if (m != null) {
      return n >= int.parse(m[1]!) && n <= int.parse(m[2]!);
    }
    return c.plannedSemester == n;
  }

  void _buildRows() {
    for (final r in _rows) {
      r.ctrl.dispose();
    }
    final passed = {
      for (final e in widget.enrollments)
        if (e.status == EnrollStatus.passed && e.term != _term) e.courseId,
    };
    final here = {
      for (final e in widget.enrollments)
        if (e.term == _term && e.course != null) e.courseId: e,
    };
    final rows = [for (final e in here.values) _Row(e.course!, existing: e)];
    // Kỳ hè không có kế hoạch sẵn: sinh viên tự thêm học phần.
    if (!AcademicService.isSummerTerm(_term)) {
      final n = AcademicService.currentSemester(widget.student, term: _term);
      for (final c in widget.courses) {
        if (here.containsKey(c.id) || passed.contains(c.id)) continue;
        if (_plannedIn(c, n)) rows.add(_Row(c));
      }
    }
    rows.sort((a, b) {
      final m = (b.course.mandatory ? 1 : 0) - (a.course.mandatory ? 1 : 0);
      return m != 0 ? m : a.course.code.compareTo(b.course.code);
    });
    _rows = rows;
  }

  void _changeTerm(String t) {
    if (_rows.any((r) => r.changed)) {
      setState(
        () => _error = 'Lưu hoặc xóa điểm đang nhập trước khi đổi học kỳ.',
      );
      return;
    }
    setState(() {
      _term = t;
      _error = null;
      _buildRows();
    });
  }

  void _addCourse(Course? c) {
    if (c == null) return;
    setState(() {
      if (!_rows.any((r) => r.course.id == c.id)) {
        _rows.add(_Row(c, checked: true));
      }
      _pickerCtrl.clear();
    });
  }

  Future<void> _save() async {
    for (final r in _rows) {
      r.error = null;
    }
    if (_rows.any((r) => r.checked && r.invalid)) {
      setState(() => _error = 'Điểm phải nằm trong khoảng 0 - 10.');
      return;
    }
    final todo = _rows.where((r) => r.checked && r.changed).toList();
    if (todo.isEmpty) {
      setState(() => _error = 'Chưa có điểm nào mới để lưu.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final state = context.read<AppState>();
    var failed = 0;
    for (final r in todo) {
      final err = r.existing == null
          ? await state.repo.declareCourse(
              student: widget.student,
              course: r.course,
              term: _term,
              grade10: r.grade,
              actor: state.user!,
            )
          : await state.repo.updateDeclaration(
              e: r.existing!,
              term: _term,
              grade10: r.grade,
              actor: state.user!,
              studentCode: widget.student.studentCode,
            );
      if (err != null) {
        r.error = err;
        failed++;
      }
    }
    await state.bumpData();
    if (!mounted) return;
    _lastTerm[widget.student.id] = _term;
    if (failed == 0) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.pop(context, true);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            'Đã lưu ${todo.length} học phần '
            '(${AcademicService.termLabel(_term)}).',
          ),
        ),
      );
      return;
    }
    setState(() {
      _saving = false;
      _error =
          '$failed học phần chưa lưu được, xem lỗi ở từng dòng. '
          'Các học phần khác đã lưu.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhập điểm cả học kỳ'),
      content: SizedBox(
        width: 760,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<String>(
                    initialValue: _term,
                    decoration: const InputDecoration(labelText: 'Học kỳ'),
                    items: [
                      for (final t in _terms)
                        DropdownMenuItem(
                          value: t,
                          child: Text('${AcademicService.termLabel(t)} ($t)'),
                        ),
                    ],
                    onChanged: _saving ? null : (v) => _changeTerm(v ?? _term),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _gpaPreview()),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Gõ điểm học phần hệ 10 (như trên bảng điểm) vào các môn đã học, '
              'nhấn Tab để sang môn tiếp theo. Môn không học kỳ này thì để '
              'trống. Tích ô mà để trống điểm nghĩa là "Đang học". Giáo dục '
              'thể chất, GDQP-AN chỉ chọn Đạt / Không đạt.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _rows.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có học phần nào cho kỳ này. Thêm học '
                        'phần ở ô bên dưới.',
                      ),
                    )
                  : ListView.separated(
                      itemCount: _rows.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) => _rowWidget(_rows[i]),
                    ),
            ),
            const SizedBox(height: 8),
            _picker(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Đóng'),
        ),
        ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save),
          label: Text(
            _saving
                ? 'Đang lưu...'
                : 'Lưu ${_rows.where((r) => r.checked && r.changed).length} học phần',
          ),
        ),
      ],
    );
  }

  Widget _rowWidget(_Row r) {
    final c = r.course;
    final g = r.grade;
    String result = '';
    Color color = AppColors.textMuted;
    if (r.checked && r.pending) {
      result = 'Đang học';
      color = AppColors.info;
    } else if (r.passFail && r.passed != null) {
      result = 'Không tính điểm TB';
    } else if (g != null) {
      final pass = GradeScale.isPass(g);
      color = pass ? AppColors.ok : AppColors.danger;
      result = c.conditional
          ? (pass ? 'Đạt' : 'Không đạt')
          : '${GradeScale.letter(g)} · ${GradeScale.toFour(g).toStringAsFixed(1)}'
                '${pass ? '' : ' · Không đạt'}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: r.checked,
            onChanged: _saving || r.existing != null
                ? null
                : (v) => setState(() => r.checked = v ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${c.code} · ${c.name}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${c.credits} TC · ${c.typeLabel}'
                  '${r.existing != null ? ' · đã khai báo' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                if (r.error != null)
                  Text(
                    r.error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.danger,
                    ),
                  ),
              ],
            ),
          ),
          if (r.passFail)
            _passFailPicker(r)
          else
            SizedBox(
              width: 90,
              child: TextField(
                controller: r.ctrl,
                enabled: !_saving,
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.next,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Điểm',
                  errorText: r.invalid ? '0 - 10' : null,
                ),
                // Gõ điểm là tự tích chọn học phần.
                onChanged: (v) => setState(() {
                  if (v.trim().isNotEmpty) r.checked = true;
                }),
              ),
            ),
          SizedBox(
            width: 120,
            child: Text(
              result,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Học phần điều kiện chỉ chọn Đạt / Không đạt, không nhập điểm.
  Widget _passFailPicker(_Row r) {
    Widget chip(bool value, String label, Color color) => ChoiceChip(
      label: Text(label),
      selected: r.passed == value,
      selectedColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: r.passed == value ? color : AppColors.textDark,
      ),
      visualDensity: VisualDensity.compact,
      onSelected: _saving
          ? null
          : (on) => setState(() {
              // Bấm lại lựa chọn đang chọn để bỏ chọn (về "Đang học").
              r.passed = on ? value : null;
              if (on) r.checked = true;
            }),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip(true, 'Đạt', AppColors.ok),
        const SizedBox(width: 6),
        chip(false, 'Không đạt', AppColors.danger),
      ],
    );
  }

  /// Điểm TB học kỳ dự kiến (hệ 4) từ các điểm đang nhập.
  Widget _gpaPreview() {
    var credits = 0;
    double quality = 0;
    for (final r in _rows) {
      final g = r.grade;
      if (!r.checked || g == null || r.course.conditional) continue;
      credits += r.course.credits;
      quality += GradeScale.toFour(g) * r.course.credits;
    }
    final text = credits == 0
        ? 'Điểm TB học kỳ (hệ 4) hiện ngay khi bạn nhập điểm.'
        : 'Điểm TB học kỳ (hệ 4): ${(quality / credits).toStringAsFixed(2)}'
              ' (${GradeScale.standing(quality / credits)}) · $credits TC';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.tableHeader,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _picker() {
    final shown = {for (final r in _rows) r.course.id};
    final options = widget.courses.where((c) => !shown.contains(c.id)).toList()
      ..sort((a, b) {
        final s = a.plannedSemester.compareTo(b.plannedSemester);
        return s != 0 ? s : a.code.compareTo(b.code);
      });
    return DropdownMenu<Course>(
      key: ValueKey(_rows.length),
      controller: _pickerCtrl,
      enableFilter: true,
      requestFocusOnTap: true,
      expandedInsets: EdgeInsets.zero,
      menuHeight: 280,
      enabled: !_saving,
      label: const Text('Thêm học phần khác (gõ mã hoặc tên)'),
      leadingIcon: const Icon(Icons.add),
      dropdownMenuEntries: [
        for (final c in options)
          DropdownMenuEntry(
            value: c,
            label: '${c.code} · ${c.name}',
            labelWidget: Text('${c.code} · ${c.name} (${c.credits} TC)'),
          ),
      ],
      onSelected: _addCourse,
    );
  }
}

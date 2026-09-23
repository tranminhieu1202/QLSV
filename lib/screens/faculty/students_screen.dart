import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models/academic.dart';
import '../../models/user.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'student_detail_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _searchCtrl = TextEditingController();
  List<StudentWithProgress> _all = [];
  List<StudentWithProgress> _view = [];
  List<String> _cohorts = [];
  String? _cohort;
  String _levelFilter = 'all';
  bool _loading = true;
  int _rev = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _advisorScope {
    final u = context.read<AppState>().user!;
    return u.role == UserRole.advisor ? u.id : null;
  }

  Future<void> _load() async {
    final repo = context.read<AppState>().repo;
    final data = await repo.studentsWithProgress(advisorId: _advisorScope);
    final cohorts = await repo.cohorts();
    if (!mounted) return;
    setState(() {
      _all = data;
      _cohorts = cohorts;
      _loading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _view = _all.where((d) {
        if (_cohort != null && d.student.cohort != _cohort) return false;
        if (_levelFilter == 'atrisk' &&
            d.progress.worstLevel.index < WarnLevel.medium.index) {
          return false;
        }
        if (_levelFilter == 'debt' && d.progress.debtCredits == 0) return false;
        if (q.isNotEmpty &&
            !d.student.fullName.toLowerCase().contains(q) &&
            !d.student.studentCode.toLowerCase().contains(q)) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rev = context.watch<AppState>().dataRevision;
    if (rev != _rev) {
      _rev = rev;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    final canAdd = context.read<AppState>().user!.role.canManageStudents;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Danh sách sinh viên',
          subtitle: 'Hiển thị ${_view.length}/${_all.length} sinh viên',
          trailing: canAdd
              ? ElevatedButton.icon(
                  onPressed: _addStudent,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Thêm sinh viên'),
                )
              : null,
        ),
        _filters(),
        const SizedBox(height: 12),
        Expanded(child: _table()),
      ],
    );
  }

  Future<void> _addStudent() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _StudentDialog(),
    );
    if (saved == true && mounted) {
      await context.read<AppState>().bumpData();
    }
  }

  Widget _filters() {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Tìm theo MSSV hoặc họ tên...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (_) => _applyFilters(),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String?>(
          value: _cohort,
          hint: const Text('Tất cả khóa'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Tất cả khóa')),
            for (final c in _cohorts)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (v) {
            _cohort = v;
            _applyFilters();
          },
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _levelFilter,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
            DropdownMenuItem(value: 'atrisk', child: Text('Cần chú ý (≥ Mức 2)')),
            DropdownMenuItem(value: 'debt', child: Text('Đang nợ tín chỉ')),
          ],
          onChanged: (v) {
            _levelFilter = v ?? 'all';
            _applyFilters();
          },
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Làm mới'),
        ),
      ],
    );
  }

  Widget _table() {
    if (_view.isEmpty) {
      return const Center(child: Text('Không có sinh viên phù hợp.'));
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _headerRow(),
          const Divider(height: 1),
          Expanded(
            child: Scrollbar(
              child: ListView.builder(
                // Fixed row height lets the list virtualize efficiently so
                // scrolling stays smooth even with thousands of students.
                itemExtent: 52,
                itemCount: _view.length,
                itemBuilder: (context, i) => _dataRow(i + 1, _view[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(int idx, Widget child) {
    final spec = _columns[idx];
    final aligned = Align(
      alignment: Alignment.centerLeft,
      child: child,
    );
    return spec.width != null
        ? SizedBox(width: spec.width, child: aligned)
        : Expanded(flex: spec.flex, child: aligned);
  }

  Widget _headerRow() {
    return Container(
      color: AppColors.tableHeader,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < _columns.length; i++)
            _cell(
              i,
              Text(_columns[i].title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _dataRow(int stt, StudentWithProgress d) {
    final p = d.progress;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF2))),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _cell(0, Text('$stt')),
            _cell(
                1,
                Text(d.student.studentCode,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            _cell(
                2,
                Text(d.student.fullName, overflow: TextOverflow.ellipsis)),
            _cell(3, Text(d.student.className)),
            _cell(4, Text(d.student.cohort)),
            _cell(
                5,
                Text(d.student.advisorName ?? '-',
                    overflow: TextOverflow.ellipsis)),
            _cell(
                6,
                Text(p.cpa.toStringAsFixed(2),
                    style: TextStyle(
                        color: p.cpa >= 2.0 ? AppColors.ok : AppColors.danger,
                        fontWeight: FontWeight.w600))),
            _cell(7, Text('${p.passedCredits}/${p.totalProgramCredits}')),
            _cell(
                8,
                Text('${p.debtCredits}',
                    style: TextStyle(
                        color: p.debtCredits > 0 ? AppColors.danger : null))),
            _cell(9, LevelBadge(level: p.worstLevel)),
            _cell(
                10,
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentDetailScreen(student: d.student),
                    ),
                  ),
                  child: const Text('Chi tiết'),
                )),
          ],
        ),
      ),
    );
  }
}

/// Column layout shared by the header and every virtualized data row.
class _Col {
  final String title;
  final double? width;
  final int flex;
  const _Col(this.title, {this.width, this.flex = 1});
}

const _columns = <_Col>[
  _Col('STT', width: 48),
  _Col('MSSV', width: 96),
  _Col('Họ và tên', flex: 3),
  _Col('Lớp', width: 96),
  _Col('Khóa', width: 72),
  _Col('CVHT', flex: 2),
  _Col('CPA', width: 64),
  _Col('TC tích lũy', width: 96),
  _Col('TC nợ', width: 72),
  _Col('Cảnh báo', width: 104),
  _Col('', width: 92),
];

/// Dialog for creating a new student and their login account.
class _StudentDialog extends StatefulWidget {
  const _StudentDialog();

  @override
  State<_StudentDialog> createState() => _StudentDialogState();
}

class _StudentDialogState extends State<_StudentDialog> {
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _className = TextEditingController();
  int _enrollYear = DateTime.now().year;
  String? _advisorId;
  int? _direction;
  bool _createAccount = true;
  bool _saving = false;
  String? _error;

  List<AppUser> _advisors = [];
  List<String> _classes = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final repo = context.read<AppState>().repo;
    final advisors = await repo.advisors();
    final classes = await repo.classNames();
    final code = await repo.suggestStudentCode(_enrollYear);
    if (!mounted) return;
    setState(() {
      _advisors = advisors;
      _classes = classes;
      _code.text = code;
    });
  }

  Future<void> _refreshCode() async {
    final code = await context.read<AppState>().repo.suggestStudentCode(_enrollYear);
    if (mounted) _code.text = code;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _className.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final code = _code.text.trim();
    final className = _className.text.trim();
    if (name.isEmpty || code.isEmpty || className.isEmpty) {
      setState(() => _error = 'Vui lòng nhập họ tên, mã số và lớp.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final state = context.read<AppState>();
    final err = await state.repo.addStudent(
      studentCode: code,
      fullName: name,
      cohort: 'K$_enrollYear',
      className: className,
      enrollYear: _enrollYear,
      advisorId: _advisorId,
      direction: _direction,
      actor: state.user!,
      createAccount: _createAccount,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final years = [
      for (var y = DateTime.now().year + 1; y >= DateTime.now().year - 8; y--) y
    ];
    return AlertDialog(
      title: const Text('Thêm sinh viên'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<int>(
                    initialValue: _enrollYear,
                    decoration: const InputDecoration(labelText: 'Khóa (năm)'),
                    items: [
                      for (final y in years)
                        DropdownMenuItem(value: y, child: Text('K$y')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _enrollYear = v);
                      _refreshCode();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _code,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(labelText: 'Mã số SV'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              _classField(),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _advisorId,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Cố vấn học tập'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Chưa phân công')),
                  for (final a in _advisors)
                    DropdownMenuItem(
                        value: a.id,
                        child: Text(a.fullName, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _advisorId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _direction,
                decoration: const InputDecoration(
                    labelText: 'Hướng ngành (nếu có)'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Chưa chọn')),
                  DropdownMenuItem(value: 1, child: Text('Hướng 1')),
                  DropdownMenuItem(value: 2, child: Text('Hướng 2')),
                  DropdownMenuItem(value: 3, child: Text('Hướng 3')),
                ],
                onChanged: (v) => setState(() => _direction = v),
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Tạo tài khoản đăng nhập'),
                subtitle: const Text('Đăng nhập bằng MSSV · mật khẩu 123456'),
                value: _createAccount,
                onChanged: (v) => setState(() => _createAccount = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Lưu'),
        ),
      ],
    );
  }

  Widget _classField() {
    return Autocomplete<String>(
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.isEmpty) return _classes;
        return _classes.where((c) => c.toLowerCase().contains(q));
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        controller.text = _className.text;
        controller.selection =
            TextSelection.collapsed(offset: controller.text.length);
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Lớp (vd QTTH 01)',
            hintText: 'Chọn lớp có sẵn hoặc nhập lớp mới',
          ),
          onChanged: (v) => _className.text = v,
        );
      },
      onSelected: (v) => _className.text = v,
    );
  }
}

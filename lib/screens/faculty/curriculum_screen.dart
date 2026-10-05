import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/academic_service.dart';
import '../../data/curriculum_seed.dart';
import '../../models/course.dart';
import '../../models/user.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/revision_reload.dart';

class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen>
    with RevisionReload {
  List<Course> _courses = [];
  bool _loading = true;

  Future<void> _load() async {
    final courses = await context.read<AppState>().repo.courses();
    if (!mounted) return;
    setState(() {
      _courses = courses;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    watchRevision(_load);
    if (_loading) return const Center(child: CircularProgressIndicator());

    final canManage = context.read<AppState>().user!.role.canManageCurriculum;
    final total = AcademicService.totalProgramCredits(_courses);
    final mandatory = _courses
        .where((c) => c.mandatory && !c.conditional)
        .fold(0, (s, c) => s + c.credits);

    // group by block, following the official order
    final order = CurriculumSeed.blocks.map((b) => b['key'] as String).toList();
    final byBlock = <String, List<Course>>{};
    for (final c in _courses) {
      byBlock.putIfAbsent(c.block, () => []).add(c);
    }
    final orderedKeys = [
      ...order.where(byBlock.containsKey),
      ...byBlock.keys.where((k) => !order.contains(k)),
    ];

    return ListView(
      children: [
        PageHeader(
          title: 'Chương trình đào tạo · ${CurriculumSeed.major}',
          subtitle:
              '${CurriculumSeed.faculty} · ${CurriculumSeed.decision} · Áp dụng từ khóa 2025',
          trailing: canManage
              ? ElevatedButton.icon(
                  onPressed: () => _editDialog(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm học phần'),
                )
              : null,
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
                width: 240,
                child: StatCard(
                    title: 'Tổng tín chỉ tích lũy',
                    value: '$total TC',
                    icon: Icons.school,
                    color: AppColors.primary)),
            SizedBox(
                width: 240,
                child: StatCard(
                    title: 'Học phần bắt buộc',
                    value: '$mandatory TC',
                    icon: Icons.lock,
                    color: AppColors.info)),
            SizedBox(
                width: 240,
                child: StatCard(
                    title: 'Số học phần',
                    value: '${_courses.length}',
                    icon: Icons.menu_book,
                    color: AppColors.accent)),
            SizedBox(
                width: 240,
                child: StatCard(
                    title: 'Tín chỉ / học kỳ',
                    value:
                        '${CurriculumSeed.minCreditsPerTerm} - ${CurriculumSeed.maxCreditsPerTerm}',
                    icon: Icons.rule,
                    color: const Color(0xFF7B1FA2))),
          ],
        ),
        const SizedBox(height: 20),
        for (final key in orderedKeys)
          _blockBlock(key, byBlock[key]!, canManage),
      ],
    );
  }

  Widget _blockBlock(String key, List<Course> courses, bool canManage) {
    courses.sort((a, b) => a.plannedSemester.compareTo(b.plannedSemester));
    final credits = courses.fold(0, (s, c) => s + c.credits);
    final name = CurriculumSeed.blockNames[key] ?? key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: AppColors.primaryDark),
              child: Text('$name  ·  $credits TC',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
                columns: [
                  const DataColumn(label: Text('Mã HP')),
                  const DataColumn(label: Text('Tên học phần')),
                  const DataColumn(label: Text('TC')),
                  const DataColumn(label: Text('Loại')),
                  const DataColumn(label: Text('Kỳ')),
                  const DataColumn(label: Text('Tiên quyết')),
                  if (canManage) const DataColumn(label: Text('')),
                ],
                rows: [
                  for (final c in courses)
                    DataRow(cells: [
                      DataCell(Text(c.code,
                          style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(SizedBox(
                          width: 340,
                          child: Text(c.oriented ? '${c.name} *' : c.name))),
                      DataCell(Text('${c.credits}')),
                      DataCell(_typeChip(c)),
                      DataCell(Text(c.semesterText.isEmpty
                          ? '${c.plannedSemester}'
                          : c.semesterText)),
                      DataCell(Text(c.prerequisite ?? '-')),
                      if (canManage)
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              tooltip: 'Sửa',
                              onPressed: () => _editDialog(c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: AppColors.danger),
                              tooltip: 'Xóa',
                              onPressed: () => _delete(c),
                            ),
                          ],
                        )),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(Course c) {
    final color =
        c.conditional ? AppColors.textMuted : (c.mandatory ? AppColors.primary : AppColors.info);
    final label = c.conditional ? 'Điều kiện' : c.typeLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _delete(Course c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa học phần?'),
        content: Text('Bạn chắc chắn muốn xóa "${c.code} · ${c.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
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
    final err = await state.repo.deleteCourse(c, state.user!);
    await state.bumpData();
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err), backgroundColor: AppColors.danger));
    }
  }

  Future<void> _editDialog(Course? existing) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _CourseDialog(existing: existing),
    );
    if (saved == true && mounted) {
      await context.read<AppState>().bumpData();
    }
  }
}

/// Dialog for creating / editing a course (admin only).
class _CourseDialog extends StatefulWidget {
  const _CourseDialog({this.existing});
  final Course? existing;

  @override
  State<_CourseDialog> createState() => _CourseDialogState();
}

class _CourseDialogState extends State<_CourseDialog> {
  late final TextEditingController _code =
      TextEditingController(text: widget.existing?.code ?? '');
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _credits =
      TextEditingController(text: widget.existing?.credits.toString() ?? '3');
  late final TextEditingController _semText =
      TextEditingController(text: widget.existing?.semesterText ?? '');
  late final TextEditingController _prereq =
      TextEditingController(text: widget.existing?.prerequisite ?? '');
  late String _block = widget.existing?.block ?? 'I';
  late int _planned = widget.existing?.plannedSemester ?? 1;
  late bool _mandatory = widget.existing?.mandatory ?? true;
  late bool _oriented = widget.existing?.oriented ?? false;
  late bool _conditional = widget.existing?.conditional ?? false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_code, _name, _credits, _semText, _prereq]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final code = _code.text.trim().toUpperCase();
    final name = _name.text.trim();
    final credits = int.tryParse(_credits.text.trim());
    if (code.isEmpty || name.isEmpty || credits == null || credits <= 0) {
      setState(() => _error = 'Vui lòng nhập đầy đủ mã, tên và số tín chỉ hợp lệ.');
      return;
    }
    final direction = _block.startsWith('V.3.')
        ? int.tryParse(_block.substring(4))
        : null;
    final course = Course(
      id: widget.existing?.id ?? 0,
      code: code,
      name: name,
      credits: credits,
      mandatory: _mandatory,
      plannedSemester: _planned,
      semesterText: _semText.text.trim(),
      block: _block,
      blockName: CurriculumSeed.blockNames[_block] ?? _block,
      direction: direction,
      conditional: _conditional,
      oriented: _oriented,
      prerequisite: _prereq.text.trim().isEmpty ? null : _prereq.text.trim(),
    );
    final state = context.read<AppState>();
    try {
      if (widget.existing == null) {
        await state.repo.addCourse(course, state.user!);
      } else {
        await state.repo.updateCourse(widget.existing!.id, course, state.user!);
      }
    } catch (e) {
      setState(() => _error = 'Lỗi lưu (mã học phần có thể đã tồn tại).');
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Thêm học phần' : 'Sửa học phần'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    decoration: const InputDecoration(labelText: 'Mã học phần'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _credits,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Số TC'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên học phần'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _block,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Khối kiến thức'),
                    items: [
                      for (final b in CurriculumSeed.blocks)
                        DropdownMenuItem(
                          value: b['key'] as String,
                          child: Text(b['key'] as String,
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _block = v ?? _block),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<int>(
                    initialValue: _planned,
                    decoration: const InputDecoration(labelText: 'Kỳ'),
                    items: [
                      for (var i = 1; i <= 8; i++)
                        DropdownMenuItem(value: i, child: Text('Kỳ $i')),
                    ],
                    onChanged: (v) => setState(() => _planned = v ?? _planned),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _semText,
                    decoration: const InputDecoration(
                        labelText: 'Kỳ tổ chức (vd 2-4)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _prereq,
                    decoration:
                        const InputDecoration(labelText: 'Tiên quyết (mã)'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Học phần bắt buộc'),
                value: _mandatory,
                onChanged: (v) => setState(() => _mandatory = v),
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Tự chọn định hướng (*)'),
                value: _oriented,
                onChanged: (v) => setState(() => _oriented = v),
              ),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Điều kiện (GDTC/GDQP – không tính GPA)'),
                value: _conditional,
                onChanged: (v) => setState(() => _conditional = v),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.danger)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy')),
        ElevatedButton(onPressed: _save, child: const Text('Lưu')),
      ],
    );
  }
}

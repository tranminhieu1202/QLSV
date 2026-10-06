import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/report_export.dart';
import '../../data/report_service.dart';
import '../../data/repository.dart';
import '../../models/academic.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/export_button.dart';
import '../../widgets/revision_reload.dart';
import '../../widgets/sort_filter_header.dart';

/// Tổng hợp danh sách sinh viên theo tiêu chí (mẫu có sẵn hoặc tùy chỉnh) và
/// xuất ra Excel / PDF.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with RevisionReload {
  List<StudentWithProgress> _data = [];
  bool _loading = true;

  // Tiêu chí đang chọn.
  ReportPreset? _preset = ReportPreset.all;
  final Set<WarnLevel> _levels = {};
  final Set<int> _years = {};
  final Set<String> _cohorts = {};
  final Set<String> _classes = {};
  String? _advisorId;
  ProgressFilter _progress = ProgressFilter.all;
  DebtFilter _debt = DebtFilter.all;
  double? _cpaBelow;
  bool _enoughCredits = false;
  ReportOrder _order = ReportOrder.byCode;
  final Set<ReportColumn> _columns = ReportColumn.defaults;

  final _titleCtrl = TextEditingController();
  bool _titleEdited = false;

  // Lựa chọn lấy từ dữ liệu đã tải.
  List<String> _allCohorts = [];
  List<String> _allClasses = [];
  Map<String, String> _advisors = {};

  Future<void> _load() async {
    final state = context.read<AppState>();
    final data =
        await state.repo.studentsWithProgress(advisorId: state.advisorScope);
    if (!mounted) return;
    setState(() {
      _data = data;
      _allCohorts = {for (final d in data) d.student.cohort}.toList()
        ..sort((a, b) => b.compareTo(a));
      _allClasses = {for (final d in data) d.student.className}.toList()
        ..sort(vnCompare);
      _advisors = {
        for (final d in data)
          if (d.student.advisorId != null)
            d.student.advisorId!: d.student.advisorName ?? d.student.advisorId!,
      };
      _loading = false;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  ReportFilter get _filter => ReportFilter(
        cohorts: {..._cohorts},
        years: {..._years},
        classes: {..._classes},
        advisorId: _advisorId,
        academicLevels: {..._levels},
        progress: _progress,
        debt: _debt,
        cpaBelow: _cpaBelow,
        enoughCredits: _enoughCredits,
      );

  List<String> _criteria(ReportFilter f) =>
      f.describe(advisorName: (id) => _advisors[id]);

  String _autoTitle(List<String> criteria) => criteria.isEmpty
      ? 'Danh sách sinh viên'
      : 'Danh sách sinh viên – ${criteria.join(', ')}';

  /// Thay đổi tiêu chí thủ công: bỏ chọn mẫu báo cáo.
  void _edit(VoidCallback change) => setState(() {
        change();
        _preset = null;
      });

  void _applyPreset(ReportPreset p) {
    final f = p.filter;
    setState(() {
      _preset = p;
      _levels
        ..clear()
        ..addAll(f.academicLevels);
      _years
        ..clear()
        ..addAll(f.years);
      _cohorts
        ..clear()
        ..addAll(f.cohorts);
      _classes
        ..clear()
        ..addAll(f.classes);
      _advisorId = f.advisorId;
      _progress = f.progress;
      _debt = f.debt;
      _cpaBelow = f.cpaBelow;
      _enoughCredits = f.enoughCredits;
      _titleEdited = false;
    });
  }

  ReportData _report(List<StudentWithProgress> rows, List<String> criteria) =>
      ReportData(
        title: _titleCtrl.text.trim().isEmpty
            ? _autoTitle(criteria)
            : _titleCtrl.text.trim(),
        criteria: criteria,
        columns: [
          for (final c in ReportColumn.values)
            if (_columns.contains(c)) c,
        ],
        rows: rows,
        generatedBy: context.read<AppState>().user!.fullName,
      );

  @override
  Widget build(BuildContext context) {
    watchRevision(_load);
    if (_loading) return const Center(child: CircularProgressIndicator());

    final filter = _filter;
    final criteria = _criteria(filter);
    final rows = applyReport(_data, filter, _order);
    final autoTitle = _autoTitle(criteria);
    if (!_titleEdited && _titleCtrl.text != autoTitle) {
      _titleCtrl.text = autoTitle;
    }
    final canExport = _columns.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Báo cáo & xuất danh sách',
          subtitle: 'Tổng hợp sinh viên theo tiêu chí, xuất ra Excel hoặc PDF',
          trailing: Row(children: [
            OutlinedButton.icon(
              onPressed: canExport
                  ? () => runExport(context, _report(rows, criteria),
                      ExportFormat.pdf)
                  : null,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Xuất PDF'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: canExport
                  ? () => runExport(context, _report(rows, criteria),
                      ExportFormat.excel)
                  : null,
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Xuất Excel'),
            ),
          ]),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 340, child: _criteriaPanel()),
              const SizedBox(width: 16),
              Expanded(child: _preview(rows, criteria)),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ tiêu chí
  Widget _criteriaPanel() {
    final isAdvisor = context.read<AppState>().advisorScope != null;
    return Card(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Mẫu báo cáo nhanh'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final p in ReportPreset.list)
                ChoiceChip(
                  label: Text(p.title),
                  selected: identical(_preset, p),
                  onSelected: (_) => _applyPreset(p),
                ),
            ],
          ),
          const Divider(height: 28),
          Row(children: [
            Expanded(child: _section('Tiêu chí tùy chỉnh')),
            TextButton(
              onPressed: () => _applyPreset(ReportPreset.all),
              child: const Text('Xóa tiêu chí'),
            ),
          ]),
          _label('Cảnh báo học vụ (ĐHQGHN)'),
          _chips<WarnLevel>(
            const [
              WarnLevel.none,
              WarnLevel.low,
              WarnLevel.medium,
              WarnLevel.high
            ],
            _levels,
            (l) => l == WarnLevel.none ? 'Không bị CB' : l.label,
          ),
          _label('Sinh viên năm thứ'),
          _chips<int>(const [1, 2, 3, 4], _years, (y) => 'Năm $y'),
          if (_allCohorts.length > 1) ...[
            _label('Khóa'),
            _chips<String>(_allCohorts, _cohorts, (c) => c),
          ],
          if (_allClasses.length > 1) ...[
            _label('Lớp'),
            _chips<String>(_allClasses, _classes, (c) => c),
          ],
          if (!isAdvisor && _advisors.isNotEmpty) ...[
            _label('Cố vấn học tập'),
            DropdownButton<String?>(
              value: _advisorId,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('Tất cả')),
                for (final e in _advisors.entries)
                  DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => _edit(() => _advisorId = v),
            ),
          ],
          _label('Tiến độ đào tạo'),
          SegmentedButton<ProgressFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ProgressFilter.all, label: Text('Tất cả')),
              ButtonSegment(
                  value: ProgressFilter.onTrack, label: Text('Đúng')),
              ButtonSegment(value: ProgressFilter.behind, label: Text('Chậm')),
            ],
            selected: {_progress},
            onSelectionChanged: (v) => _edit(() => _progress = v.first),
          ),
          _label('Nợ tín chỉ'),
          SegmentedButton<DebtFilter>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: DebtFilter.all, label: Text('Tất cả')),
              ButtonSegment(value: DebtFilter.hasDebt, label: Text('Có nợ')),
              ButtonSegment(value: DebtFilter.noDebt, label: Text('Không nợ')),
            ],
            selected: {_debt},
            onSelectionChanged: (v) => _edit(() => _debt = v.first),
          ),
          _label('CPA'),
          DropdownButton<double?>(
            value: _cpaBelow,
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: null, child: Text('Không lọc')),
              DropdownMenuItem(value: 1.0, child: Text('CPA < 1.00')),
              DropdownMenuItem(value: 1.5, child: Text('CPA < 1.50')),
              DropdownMenuItem(value: 2.0, child: Text('CPA < 2.00')),
              DropdownMenuItem(value: 2.5, child: Text('CPA < 2.50')),
              DropdownMenuItem(value: 3.2, child: Text('CPA < 3.20')),
            ],
            onChanged: (v) => _edit(() => _cpaBelow = v),
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Đã tích lũy đủ tín chỉ chương trình'),
            value: _enoughCredits,
            onChanged: (v) => _edit(() => _enoughCredits = v ?? false),
          ),
          const Divider(height: 28),
          _section('Sắp xếp & cột xuất'),
          Text(
            'Sắp xếp: ${_order.label} – bấm tiêu đề cột ở bảng xem trước để '
            'đổi (như Excel).',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in ReportColumn.values)
                FilterChip(
                  label: Text(c.label),
                  selected: _columns.contains(c),
                  onSelected: (on) => setState(
                      () => on ? _columns.add(c) : _columns.remove(c)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 6),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.textMuted, fontWeight: FontWeight.w600)),
      );

  Widget _chips<T>(List<T> options, Set<T> selected, String Function(T) label) =>
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final o in options)
            FilterChip(
              label: Text(label(o)),
              selected: selected.contains(o),
              onSelected: (on) =>
                  _edit(() => on ? selected.add(o) : selected.remove(o)),
            ),
        ],
      );

  // ------------------------------------------------------------- xem trước
  Widget _preview(List<StudentWithProgress> rows, List<String> criteria) {
    final cols = [
      for (final c in ReportColumn.values)
        if (_columns.contains(c)) c,
    ];
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'Tiêu đề báo cáo',
                isDense: true,
                suffixIcon: _titleEdited
                    ? IconButton(
                        tooltip: 'Dùng tiêu đề tự động',
                        icon: const Icon(Icons.auto_fix_high),
                        onPressed: () => setState(() => _titleEdited = false),
                      )
                    : null,
              ),
              onChanged: (_) {
                if (!_titleEdited) setState(() => _titleEdited = true);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('${rows.length}/${_data.length} sinh viên',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  criteria.isEmpty
                      ? 'Không lọc – tất cả sinh viên'
                      : criteria.join(' · '),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          if (cols.isEmpty)
            const Expanded(
                child: Center(child: Text('Hãy chọn ít nhất một cột để xuất.')))
          else if (rows.isEmpty)
            const Expanded(
                child: Center(
                    child: Text('Không có sinh viên nào thỏa tiêu chí.')))
          else ...[
            Container(
              color: AppColors.tableHeader,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                for (final c in cols)
                  _previewCell(c, _header(c)),
              ]),
            ),
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  itemExtent: 40,
                  itemCount: rows.length,
                  itemBuilder: (_, i) => DecoratedBox(
                    decoration: const BoxDecoration(
                      border:
                          Border(bottom: BorderSide(color: Color(0xFFEDEFF2))),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(children: [
                        for (final c in cols)
                          _previewCell(
                            c,
                            c == ReportColumn.academicLevel
                                ? FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: LevelBadge(
                                        level: rows[i].progress.academicLevel,
                                        text: c.textOf(rows[i], i)),
                                  )
                                : Text(c.textOf(rows[i], i),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1),
                          ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tiêu đề cột kiểu Excel; Khóa/Lớp lọc được và đồng bộ với bảng tiêu chí.
  Widget _header(ReportColumn c) {
    final (List<String>? values, Set<String>? selected) = switch (c) {
      ReportColumn.cohort when _allCohorts.length > 1 => (_allCohorts, _cohorts),
      ReportColumn.className when _allClasses.length > 1 =>
        (_allClasses, _classes),
      _ => (null, null),
    };
    return SortFilterHeader(
      label: c.label,
      column: c,
      order: _order,
      onSort: (o) => setState(() => _order = o),
      filterValues: values,
      filterSelected: selected ?? const {},
      onFilter: selected == null
          ? null
          : (sel) => _edit(() => selected
            ..clear()
            ..addAll(sel)),
    );
  }

  Widget _previewCell(ReportColumn c, Widget child) => Expanded(
        flex: (c.weight * 10).round(),
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Align(
            alignment:
                c.numeric ? Alignment.centerRight : Alignment.centerLeft,
            child: child,
          ),
        ),
      );
}

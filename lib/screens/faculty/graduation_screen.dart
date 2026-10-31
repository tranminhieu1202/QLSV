import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/report_service.dart';
import '../../data/repository.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/export_button.dart';
import '../../widgets/revision_reload.dart';
import 'student_detail_screen.dart';

enum _Status { all, eligible, notEligible }

/// Xét điều kiện tốt nghiệp theo lớp / khóa: ai đã đủ, ai còn thiếu gì
/// (tín chỉ từng khối kiến thức, CPA, học phần điều kiện).
class GraduationScreen extends StatefulWidget {
  const GraduationScreen({super.key});

  @override
  State<GraduationScreen> createState() => _GraduationScreenState();
}

class _GraduationScreenState extends State<GraduationScreen>
    with RevisionReload {
  List<StudentWithProgress> _data = [];
  bool _loading = true;
  String? _cohort;
  String? _className;
  _Status _status = _Status.all;
  String _search = '';

  Future<void> _load() async {
    final state = context.read<AppState>();
    final data =
        await state.repo.studentsWithProgress(advisorId: state.advisorScope);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      // Mặc định chọn khóa cũ nhất (gần tốt nghiệp nhất).
      _cohort ??= _cohorts.isEmpty ? null : _cohorts.first;
    });
  }

  List<String> get _cohorts =>
      (_data.map((d) => d.student.cohort).toSet().toList()..sort());

  List<String> get _classes => (_data
      .where((d) => _cohort == null || d.student.cohort == _cohort)
      .map((d) => d.student.className)
      .toSet()
      .toList()
    ..sort());

  List<StudentWithProgress> get _inScope => _data
      .where((d) =>
          (_cohort == null || d.student.cohort == _cohort) &&
          (_className == null || d.student.className == _className))
      .toList();

  @override
  Widget build(BuildContext context) {
    watchRevision(_load);
    if (_loading) return const Center(child: CircularProgressIndicator());

    final scope = _inScope;
    final eligible = scope.where((d) => d.graduation.eligible).length;
    final q = _search.trim().toLowerCase();
    final rows = scope.where((d) {
      final ok = d.graduation.eligible;
      if (_status == _Status.eligible && !ok) return false;
      if (_status == _Status.notEligible && ok) return false;
      if (q.isEmpty) return true;
      return d.student.studentCode.toLowerCase().contains(q) ||
          d.student.fullName.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        // Gần đủ điều kiện đứng trước: đủ → nhiều TC tích lũy hơn.
        final e = (b.graduation.eligible ? 1 : 0) -
            (a.graduation.eligible ? 1 : 0);
        if (e != 0) return e;
        final c = b.progress.passedCredits.compareTo(a.progress.passedCredits);
        return c != 0
            ? c
            : a.student.studentCode.compareTo(b.student.studentCode);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Xét điều kiện tốt nghiệp',
          subtitle: '$eligible/${scope.length} sinh viên đủ điều kiện'
              '${_cohort == null ? '' : ' · khóa $_cohort'}'
              '${_className == null ? '' : ' · lớp $_className'}',
          trailing: ExportMenuButton(
            enabled: rows.isNotEmpty,
            report: () => ReportData(
              title: 'Danh sách xét điều kiện tốt nghiệp',
              criteria: [
                if (_cohort != null) 'Khóa: $_cohort',
                if (_className != null) 'Lớp: $_className',
                if (_status != _Status.all)
                  _status == _Status.eligible
                      ? 'Đủ điều kiện tốt nghiệp'
                      : 'Chưa đủ điều kiện tốt nghiệp',
              ],
              columns: const [
                ReportColumn.stt,
                ReportColumn.code,
                ReportColumn.name,
                ReportColumn.className,
                ReportColumn.cohort,
                ReportColumn.passed,
                ReportColumn.cpa,
                ReportColumn.graduation,
                ReportColumn.graduationMissing,
              ],
              rows: rows,
              generatedBy: context.read<AppState>().user!.fullName,
            ),
          ),
        ),
        _filters(scope.length, eligible),
        const SizedBox(height: 12),
        Expanded(
          child: rows.isEmpty
              ? const Center(child: Text('Không có sinh viên phù hợp.'))
              : Card(
                  child: ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _row(i, rows[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _filters(int total, int eligible) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _dropdown(
          label: 'Khóa',
          value: _cohort,
          items: {null: 'Tất cả', for (final c in _cohorts) c: c},
          onChanged: (v) => setState(() {
            _cohort = v;
            _className = null;
          }),
        ),
        _dropdown(
          label: 'Lớp',
          value: _className,
          items: {null: 'Tất cả', for (final c in _classes) c: c},
          onChanged: (v) => setState(() => _className = v),
        ),
        SegmentedButton<_Status>(
          segments: [
            ButtonSegment(value: _Status.all, label: Text('Tất cả ($total)')),
            ButtonSegment(
                value: _Status.eligible,
                label: Text('Đủ điều kiện ($eligible)')),
            ButtonSegment(
                value: _Status.notEligible,
                label: Text('Chưa đủ (${total - eligible})')),
          ],
          selected: {_status},
          onSelectionChanged: (v) => setState(() => _status = v.first),
        ),
        SizedBox(
          width: 240,
          child: TextField(
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search),
              hintText: 'Tìm MSSV hoặc họ tên',
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required Map<String?, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label: '),
      DropdownButton<String?>(
        value: items.containsKey(value) ? value : null,
        items: [
          for (final e in items.entries)
            DropdownMenuItem<String?>(value: e.key, child: Text(e.value)),
        ],
        onChanged: onChanged,
      ),
    ]);
  }

  Widget _row(int i, StudentWithProgress d) {
    final g = d.graduation;
    final p = d.progress;
    final color = g.eligible ? AppColors.ok : AppColors.danger;
    return ListTile(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => StudentDetailScreen(student: d.student)),
      ),
      leading: SizedBox(
        width: 32,
        child: Text('${i + 1}',
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppColors.textMuted)),
      ),
      title: Text('${d.student.fullName} · ${d.student.studentCode}',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${d.student.className} · ${d.student.cohort} · '
        'TC tích lũy ${p.passedCredits}/${p.totalProgramCredits} · '
        'CPA ${p.cpa.toStringAsFixed(2)}'
        '${g.eligible ? '' : '\nCòn thiếu: ${g.missingSummary}'}',
        style: const TextStyle(fontSize: 12),
      ),
      isThreeLine: !g.eligible,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(g.eligible ? 'Đủ điều kiện' : 'Chưa đủ',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

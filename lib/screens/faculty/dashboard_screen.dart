import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/academic_service.dart';
import '../../data/report_service.dart';
import '../../data/repository.dart';
import '../../models/academic.dart';
import '../../models/enrollment.dart';
import '../../models/user.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/revision_reload.dart';
import 'student_detail_screen.dart';

/// Tổng quan đào tạo: chỉ số chính, cảnh báo học vụ, tiến độ, phân bố CPA và
/// danh sách sinh viên cần chú ý. Bộ lọc khóa áp dụng cho toàn màn hình.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RevisionReload {
  List<StudentWithProgress> _data = [];
  bool _loading = true;
  String? _cohort; // null = tất cả khóa
  DateTime? _loadedAt;

  static const _years = [1, 2, 3, 4];
  static const _levels = [WarnLevel.low, WarnLevel.medium, WarnLevel.high];
  static const _standings = ['Yếu', 'Trung bình', 'Khá', 'Giỏi', 'Xuất sắc'];

  Future<void> _load() async {
    final state = context.read<AppState>();
    final data = await state.repo.studentsWithProgress(
      advisorId: state.advisorScope,
    );
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
      _loadedAt = DateTime.now();
      if (_cohort != null && !data.any((d) => d.student.cohort == _cohort)) {
        _cohort = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    watchRevision(_load);
    if (_loading) return const Center(child: CircularProgressIndicator());
    final state = context.read<AppState>();
    final user = state.user!;

    final rows = _cohort == null
        ? _data
        : _data.where((d) => d.student.cohort == _cohort).toList();
    final cohorts = {for (final d in _data) d.student.cohort}.toList()
      ..sort(vnCompare);

    return ListView(
      children: [
        PageHeader(
          title: 'Tổng quan đào tạo',
          subtitle:
              '${user.role == UserRole.advisor ? 'Sinh viên do bạn cố vấn' : 'Ngành Quản trị trường học'}'
              ' · Kỳ ${AcademicService.termLabel(state.currentTerm)}'
              '${_loadedAt == null ? '' : ' · Cập nhật ${_hm(_loadedAt!)}'}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Khóa: ',
                style: TextStyle(color: AppColors.textMuted),
              ),
              DropdownButton<String?>(
                value: _cohort,
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tất cả khóa'),
                  ),
                  for (final c in cohorts)
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _cohort = v),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => state.bumpData(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Làm mới'),
              ),
            ],
          ),
        ),
        if (rows.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('Chưa có sinh viên nào.')),
            ),
          )
        else ...[
          _kpiRow(rows),
          const SizedBox(height: 16),
          _grid([
            _warningCard(rows),
            _progressCard(rows),
            _cpaCard(rows),
            _attentionCard(rows),
          ]),
        ],
      ],
    );
  }

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// Phần trăm; dưới 10% giữ một chữ số thập phân.
  static String _pct(int n, int total) {
    if (total == 0) return '0%';
    final v = n / total * 100;
    return '${v.toStringAsFixed(v < 10 ? 1 : 0)}%';
  }

  /// Hai cột trên màn rộng, một cột trên màn hẹp.
  Widget _grid(List<Widget> cards) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 1000) {
          return Column(
            children: [
              for (final w in cards) ...[w, const SizedBox(height: 16)],
            ],
          );
        }
        return Column(
          children: [
            for (var i = 0; i < cards.length; i += 2) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cards[i]),
                    const SizedBox(width: 16),
                    Expanded(
                      child: i + 1 < cards.length
                          ? cards[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------ KPI row
  Widget _kpiRow(List<StudentWithProgress> rows) {
    final total = rows.length;
    final active = rows.where((d) => d.student.status == 'active').length;
    final warned = rows
        .where((d) => d.progress.academicLevel != WarnLevel.none)
        .length;
    final dismissal = rows
        .where((d) => d.progress.academicLevel == WarnLevel.high)
        .length;
    final behind = rows.where((d) => d.progress.behindSchedule).length;
    final debtors = rows.where((d) => d.progress.debtCredits > 0).toList();
    final debtTotal = debtors.fold(0, (s, d) => s + d.progress.debtCredits);
    // CPA trung bình chỉ tính sinh viên đã có điểm tích lũy.
    final graded = rows.where((d) => d.progress.cpa > 0).toList();
    final avgCpa = graded.isEmpty
        ? null
        : graded.fold(0.0, (s, d) => s + d.progress.cpa) / graded.length;
    final lowCpa = graded.where((d) => d.progress.cpa < 2.0).length;

    final tiles = [
      _Kpi(
        label: 'Sinh viên',
        value: '$total',
        detail: '$active đang học',
        icon: Icons.groups_outlined,
        accent: AppColors.info,
      ),
      _Kpi(
        label: 'Bị cảnh báo học vụ',
        value: '$warned',
        detail: '${_pct(warned, total)} · $dismissal diện buộc thôi học',
        icon: Icons.warning_amber_rounded,
        accent: AppColors.danger,
      ),
      _Kpi(
        label: 'Chậm tiến độ',
        value: '$behind',
        detail: '${_pct(behind, total)} số sinh viên',
        icon: Icons.schedule,
        accent: AppColors.warn,
      ),
      _Kpi(
        label: 'Đang nợ tín chỉ',
        value: '${debtors.length}',
        detail: 'Tổng $debtTotal TC chưa đạt',
        icon: Icons.report_gmailerrorred_outlined,
        accent: const Color(0xFFEF6C00),
      ),
      _Kpi(
        label: 'CPA trung bình',
        value: avgCpa == null ? '–' : avgCpa.toStringAsFixed(2),
        detail: graded.isEmpty
            ? 'Chưa có điểm'
            : '$lowCpa SV dưới 2,00 · ${graded.length} SV có điểm',
        icon: Icons.school_outlined,
        accent: AppColors.ok,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final perRow = c.maxWidth >= 1200
            ? 5
            : c.maxWidth >= 760
            ? 3
            : 1;
        final w = (c.maxWidth - (perRow - 1) * 12) / perRow;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }

  // ------------------------------------------------------- chart cards
  Widget _warningCard(List<StudentWithProgress> rows) {
    final values = [
      for (final y in _years)
        [
          for (final l in _levels)
            rows
                .where(
                  (d) =>
                      d.progress.yearOfStudy == y &&
                      d.progress.academicLevel == l,
                )
                .length,
        ],
    ];
    final warned = values.expand((v) => v).fold(0, (a, b) => a + b);
    return _ChartCard(
      title: 'Cảnh báo học vụ theo năm học',
      subtitle: warned == 0
          ? 'Không có sinh viên bị cảnh báo học vụ.'
          : '$warned sinh viên bị cảnh báo · Quy chế ĐHQGHN, Điều 44',
      labels: [for (final y in _years) 'Năm $y'],
      series: [for (final l in _levels) l.label],
      colors: VizColors.severity,
      values: values,
      unit: 'SV bị cảnh báo',
    );
  }

  Widget _progressCard(List<StudentWithProgress> rows) {
    final values = [
      for (final y in _years)
        [
          rows
              .where(
                (d) =>
                    d.progress.yearOfStudy == y && !d.progress.behindSchedule,
              )
              .length,
          rows
              .where(
                (d) => d.progress.yearOfStudy == y && d.progress.behindSchedule,
              )
              .length,
        ],
    ];
    return _ChartCard(
      title: 'Tiến độ đào tạo theo năm học',
      subtitle: 'Chậm tiến độ: đạt dưới 80% số TC bắt buộc lẽ ra đã hoàn thành',
      labels: [for (final y in _years) 'Năm $y'],
      series: const ['Đúng tiến độ', 'Chậm tiến độ'],
      colors: const [VizColors.series1, VizColors.series2],
      values: values,
      unit: 'SV',
    );
  }

  Widget _cpaCard(List<StudentWithProgress> rows) {
    final graded = rows.where((d) => d.progress.cpa > 0).toList();
    final counts = {for (final s in _standings) s: 0};
    for (final d in graded) {
      final s = GradeScale.standing(d.progress.cpa);
      counts[s] = counts[s]! + 1;
    }
    final noGrade = rows.length - graded.length;
    return _ChartCard(
      title: 'Phân bố CPA theo xếp loại',
      subtitle:
          'Yếu < 2,00 · TB < 2,50 · Khá < 3,20 · Giỏi < 3,60 · Xuất sắc'
          '${noGrade > 0 ? ' · $noGrade SV chưa có điểm (không tính)' : ''}',
      labels: _standings,
      series: const ['Số sinh viên'],
      colors: VizColors.ordinalBlue,
      colorPerBar: true,
      values: [
        for (final s in _standings) [counts[s]!],
      ],
      unit: 'SV',
    );
  }

  Widget _attentionCard(List<StudentWithProgress> rows) {
    int score(StudentWithProgress d) =>
        d.progress.academicLevel.index * 1000 +
        (d.progress.behindSchedule ? 100 : 0) +
        d.progress.debtCredits;
    final list =
        rows
            .where(
              (d) =>
                  d.progress.academicLevel != WarnLevel.none ||
                  d.progress.debtCredits > 0 ||
                  d.progress.behindSchedule,
            )
            .toList()
          ..sort((a, b) {
            final s = score(b).compareTo(score(a));
            return s != 0 ? s : a.progress.cpa.compareTo(b.progress.cpa);
          });
    const shown = 5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardTitle(
              title: 'Sinh viên cần chú ý',
              subtitle: 'Ưu tiên cảnh báo học vụ, chậm tiến độ, nợ tín chỉ',
            ),
            const SizedBox(height: 8),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Không có sinh viên nào cần chú ý.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
            for (final d in list.take(shown)) _attentionRow(d),
            if (list.length > shown)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'và ${list.length - shown} sinh viên khác – xem đầy đủ ở '
                  'màn Cảnh báo.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _attentionRow(StudentWithProgress d) {
    final p = d.progress;
    final String tag;
    final WarnLevel level;
    if (p.academicLevel != WarnLevel.none) {
      tag = p.academicLevel.label;
      level = p.academicLevel;
    } else if (p.behindSchedule) {
      tag = 'Chậm tiến độ';
      level = WarnLevel.info;
    } else {
      tag = 'Nợ ${p.debtCredits} TC';
      level = WarnLevel.info;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentDetailScreen(student: d.student),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.student.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${d.student.studentCode} · ${d.student.className}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                'CPA ${p.cpa.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            SizedBox(
              width: 70,
              child: Text(
                p.debtCredits == 0 ? '' : 'Nợ ${p.debtCredits} TC',
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 128,
              child: Align(
                alignment: Alignment.centerRight,
                child: LevelBadge(level: level, text: tag),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
/// Thẻ chỉ số: nhãn, con số lớn và một dòng ngữ cảnh.
class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Thẻ biểu đồ cột (xếp chồng khi có nhiều nhóm) kèm chú giải, chú thích khi
/// rê chuột và nút chuyển sang dạng bảng.
class _ChartCard extends StatefulWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.labels,
    required this.series,
    required this.colors,
    required this.values,
    required this.unit,
    this.colorPerBar = false,
  });

  final String title;
  final String subtitle;

  /// Nhãn trục X (một phần tử mỗi cột).
  final List<String> labels;

  /// Tên các nhóm xếp chồng trong mỗi cột.
  final List<String> series;
  final List<Color> colors;

  /// values[cột][nhóm].
  final List<List<int>> values;
  final String unit;

  /// Một nhóm duy nhất, mỗi cột một màu theo thang thứ tự.
  final bool colorPerBar;

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  bool _table = false;

  List<int> get _totals => [
    for (final v in widget.values) v.fold(0, (a, b) => a + b),
  ];

  Color _color(int bar, int series) =>
      widget.colorPerBar ? widget.colors[bar] : widget.colors[series];

  @override
  Widget build(BuildContext context) {
    final multi = widget.series.length > 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardTitle(
              title: widget.title,
              subtitle: widget.subtitle,
              trailing: IconButton(
                tooltip: _table ? 'Xem biểu đồ' : 'Xem dạng bảng',
                icon: Icon(
                  _table ? Icons.bar_chart : Icons.table_chart_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _table = !_table),
              ),
            ),
            if (multi) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  for (var s = 0; s < widget.series.length; s++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: widget.colors[s],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.series[s],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _table ? _tableView() : _chart(),
          ],
        ),
      ),
    );
  }

  /// Bước chia trục Y "đẹp" (số nguyên 1, 2, 5, 10…) cho khoảng 4 vạch.
  static int _niceStep(int max) {
    if (max <= 5) return 1;
    final raw = max / 4;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toInt();
    for (final m in [1, 2, 5, 10]) {
      if (m * mag >= raw) return m * mag;
    }
    return 10 * mag;
  }

  Widget _chart() {
    final totals = _totals;
    final grand = totals.fold(0, (a, b) => a + b);
    final maxV = totals.fold(0, math.max);
    final step = _niceStep(maxV);
    final maxY = (math.max(1, (maxV / step).ceil()) * step).toDouble();
    const tick = TextStyle(fontSize: 11, color: VizColors.axisText);

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(
            show: true,
            border: const Border(
              bottom: BorderSide(color: VizColors.baseline, width: 1),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: step.toDouble(),
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: VizColors.grid, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: step.toDouble(),
                getTitlesWidget: (v, meta) {
                  if (v % step != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      '${v.toInt()}',
                      textAlign: TextAlign.right,
                      style: tick,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= widget.labels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.labels[i],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text('${totals[i]}', style: tick),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => VizColors.tooltipBg,
              tooltipRoundedRadius: 6,
              maxContentWidth: 220,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, _, _, _) {
                final i = group.x;
                final multi = widget.series.length > 1;
                return BarTooltipItem(
                  '${widget.labels[i]}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.left,
                  children: [
                    if (multi)
                      for (var s = 0; s < widget.series.length; s++)
                        TextSpan(
                          text: '${widget.series[s]}: ${widget.values[i][s]}\n',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                    TextSpan(
                      text:
                          '${multi ? 'Tổng: ' : ''}${totals[i]} '
                          '${widget.unit} (${grand == 0 ? 0 : (totals[i] / grand * 100).round()}%)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < widget.labels.length; i++)
              BarChartGroupData(x: i, barRods: [_rod(i, totals[i])]),
          ],
        ),
      ),
    );
  }

  BarChartRodData _rod(int i, int total) {
    const radius = BorderRadius.vertical(top: Radius.circular(4));
    if (widget.series.length == 1) {
      return BarChartRodData(
        toY: total.toDouble(),
        width: 28,
        color: _color(i, 0),
        borderRadius: radius,
      );
    }
    // Xếp chồng; viền màu nền 1px tách các đoạn.
    var from = 0.0;
    final items = <BarChartRodStackItem>[];
    for (var s = 0; s < widget.series.length; s++) {
      final v = widget.values[i][s].toDouble();
      if (v == 0) continue;
      items.add(
        BarChartRodStackItem(
          from,
          from + v,
          _color(i, s),
          const BorderSide(color: Colors.white, width: 1),
        ),
      );
      from += v;
    }
    return BarChartRodData(
      toY: total.toDouble(),
      width: 28,
      color: Colors.transparent,
      borderRadius: radius,
      rodStackItems: items,
    );
  }

  Widget _tableView() {
    final totals = _totals;
    final multi = widget.series.length > 1;
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 40,
        headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
        columns: [
          const DataColumn(label: Text('')),
          if (multi)
            for (final s in widget.series)
              DataColumn(label: Text(s), numeric: true),
          DataColumn(
            label: Text(multi ? 'Tổng' : widget.series.first),
            numeric: true,
          ),
        ],
        rows: [
          for (var i = 0; i < widget.labels.length; i++)
            DataRow(
              cells: [
                DataCell(
                  Text(
                    widget.labels[i],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                if (multi)
                  for (final v in widget.values[i]) DataCell(Text('$v')),
                DataCell(
                  Text(
                    '${totals[i]}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

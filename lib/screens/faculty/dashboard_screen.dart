import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models/academic.dart';
import '../../models/user.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/revision_reload.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with RevisionReload {
  List<StudentWithProgress> _data = [];
  bool _loading = true;

  Future<void> _load() async {
    final state = context.read<AppState>();
    final data =
        await state.repo.studentsWithProgress(advisorId: state.advisorScope);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    watchRevision(_load);
    if (_loading) return const Center(child: CircularProgressIndicator());
    final user = context.read<AppState>().user!;

    final total = _data.length;
    final atRisk = _data
        .where((d) => d.progress.worstLevel.index >= WarnLevel.medium.index)
        .length;
    final debtors = _data.where((d) => d.progress.debtCredits > 0).length;
    final avgCpa = total == 0
        ? 0.0
        : _data.map((d) => d.progress.cpa).reduce((a, b) => a + b) / total;

    // warning level distribution
    final levelCounts = <WarnLevel, int>{
      for (final l in WarnLevel.values) l: 0,
    };
    for (final d in _data) {
      levelCounts[d.progress.worstLevel] =
          (levelCounts[d.progress.worstLevel] ?? 0) + 1;
    }

    // cohort distribution
    final byCohort = <String, int>{};
    for (final d in _data) {
      byCohort[d.student.cohort] = (byCohort[d.student.cohort] ?? 0) + 1;
    }

    return ListView(
      children: [
        PageHeader(
          title: 'Xin chào, ${user.fullName}',
          subtitle:
              'Tổng quan tiến trình đào tạo ngành Quản trị trường học · ${user.role.label}',
          trailing: OutlinedButton.icon(
            onPressed: () => context.read<AppState>().bumpData(),
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới'),
          ),
        ),
        LayoutBuilder(builder: (context, c) {
          final w = (c.maxWidth - 3 * 12) / 4;
          final cardW = c.maxWidth < 720 ? c.maxWidth : w;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: cardW,
                child: StatCard(
                  title: 'Tổng số sinh viên',
                  value: '$total',
                  icon: Icons.groups,
                  color: AppColors.info,
                ),
              ),
              SizedBox(
                width: cardW,
                child: StatCard(
                  title: 'SV cần chú ý (Mức ≥ 2)',
                  value: '$atRisk',
                  icon: Icons.warning_amber,
                  color: AppColors.danger,
                  subtitle: total == 0
                      ? null
                      : '${(atRisk / total * 100).toStringAsFixed(1)}% toàn khoa',
                ),
              ),
              SizedBox(
                width: cardW,
                child: StatCard(
                  title: 'SV đang nợ tín chỉ',
                  value: '$debtors',
                  icon: Icons.report_gmailerrorred,
                  color: const Color(0xFFEF6C00),
                ),
              ),
              SizedBox(
                width: cardW,
                child: StatCard(
                  title: 'CPA trung bình',
                  value: avgCpa.toStringAsFixed(2),
                  icon: Icons.grade,
                  color: avgCpa >= 2.0 ? AppColors.ok : AppColors.danger,
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 20),
        LayoutBuilder(builder: (context, c) {
          final narrow = c.maxWidth < 900;
          final chart1 = _warningChartCard(levelCounts);
          final chart2 = _cohortChartCard(byCohort);
          if (narrow) {
            return Column(children: [chart1, const SizedBox(height: 16), chart2]);
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: chart1),
              const SizedBox(width: 16),
              Expanded(child: chart2),
            ],
          );
        }),
      ],
    );
  }

  Widget _warningChartCard(Map<WarnLevel, int> counts) {
    final entries = WarnLevel.values;
    final maxVal =
        (counts.values.isEmpty ? 1 : counts.values.reduce((a, b) => a > b ? a : b))
            .toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Phân bố mức cảnh báo',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxVal == 0 ? 1 : maxVal * 1.2,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= entries.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(entries[i].label,
                                style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < entries.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: (counts[entries[i]] ?? 0).toDouble(),
                          color: warnColor(entries[i]),
                          width: 26,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cohortChartCard(Map<String, int> byCohort) {
    final keys = byCohort.keys.toList()..sort();
    final colors = [
      AppColors.primary,
      AppColors.info,
      AppColors.accent,
      AppColors.ok,
      const Color(0xFF7B1FA2),
    ];
    final total = byCohort.values.fold(0, (a, b) => a + b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sinh viên theo khóa',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 44,
                        sections: [
                          for (var i = 0; i < keys.length; i++)
                            PieChartSectionData(
                              value: byCohort[keys[i]]!.toDouble(),
                              title: '${byCohort[keys[i]]}',
                              color: colors[i % colors.length],
                              radius: 60,
                              titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < keys.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                  width: 12,
                                  height: 12,
                                  color: colors[i % colors.length]),
                              const SizedBox(width: 8),
                              Text(
                                  '${keys[i]} · ${byCohort[keys[i]]} SV '
                                  '(${total == 0 ? 0 : (byCohort[keys[i]]! / total * 100).round()}%)'),
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
}

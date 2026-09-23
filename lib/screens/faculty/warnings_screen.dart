import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repository.dart';
import '../../models/academic.dart';
import '../../models/user.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'student_detail_screen.dart';

class WarningsScreen extends StatefulWidget {
  const WarningsScreen({super.key});

  @override
  State<WarningsScreen> createState() => _WarningsScreenState();
}

class _WarningsScreenState extends State<WarningsScreen> {
  List<StudentWithProgress> _data = [];
  bool _loading = true;
  int _rev = 0;
  WarnLevel _minLevel = WarnLevel.low;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final state = context.read<AppState>();
    final advisorId =
        state.user!.role == UserRole.advisor ? state.user!.id : null;
    final data = await state.repo.studentsWithProgress(advisorId: advisorId);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rev = context.watch<AppState>().dataRevision;
    if (rev != _rev) {
      _rev = rev;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    if (_loading) return const Center(child: CircularProgressIndicator());

    final flagged = _data
        .where((d) =>
            d.progress.warnings.isNotEmpty &&
            d.progress.worstLevel.index >= _minLevel.index)
        .toList()
      ..sort((a, b) =>
          b.progress.worstLevel.index.compareTo(a.progress.worstLevel.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Bảng cảnh báo sinh viên',
          subtitle: '${flagged.length} sinh viên có cảnh báo cần theo dõi',
          trailing: Row(
            children: [
              const Text('Mức tối thiểu: '),
              const SizedBox(width: 8),
              DropdownButton<WarnLevel>(
                value: _minLevel,
                items: const [
                  DropdownMenuItem(value: WarnLevel.info, child: Text('Lưu ý')),
                  DropdownMenuItem(value: WarnLevel.low, child: Text('Mức 1')),
                  DropdownMenuItem(
                      value: WarnLevel.medium, child: Text('Mức 2')),
                  DropdownMenuItem(value: WarnLevel.high, child: Text('Mức 3')),
                ],
                onChanged: (v) =>
                    setState(() => _minLevel = v ?? WarnLevel.low),
              ),
            ],
          ),
        ),
        Expanded(
          child: flagged.isEmpty
              ? const Center(child: Text('Không có sinh viên nào cần cảnh báo.'))
              : ListView.separated(
                  itemCount: flagged.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _card(flagged[i]),
                ),
        ),
      ],
    );
  }

  Widget _card(StudentWithProgress d) {
    final p = d.progress;
    final c = warnColor(p.worstLevel);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: c.withValues(alpha: 0.15),
                  child: Text(d.student.fullName.characters.last,
                      style: TextStyle(color: c, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${d.student.fullName} · ${d.student.studentCode}',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          '${d.student.className} · ${d.student.cohort} · '
                          'CVHT: ${d.student.advisorName ?? "-"}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                LevelBadge(level: p.worstLevel),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          StudentDetailScreen(student: d.student),
                    ),
                  ),
                  child: const Text('Xem hồ sơ'),
                ),
              ],
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final w in p.warnings)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: warnColor(w.level).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: warnColor(w.level).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber,
                            size: 16, color: warnColor(w.level)),
                        const SizedBox(width: 6),
                        Text(w.title,
                            style: TextStyle(
                                color: warnColor(w.level),
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

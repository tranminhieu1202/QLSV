import 'package:flutter/material.dart';

import '../data/graduation.dart';
import '../models/academic.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../theme/app_theme.dart';

/// Tab "Điều kiện tốt nghiệp": đối chiếu số TC đã tích lũy với yêu cầu của
/// từng khối kiến thức trong chương trình đào tạo (vd khối chung 21 TC, tự
/// chọn lĩnh vực 3/9 TC...) và các điều kiện xét tốt nghiệp khác.
class GraduationView extends StatelessWidget {
  const GraduationView({
    super.key,
    required this.progress,
    required this.enrollments,
    required this.courses,
  });

  final StudentProgress progress;
  final List<Enrollment> enrollments;
  final List<Course> courses;

  static const _groups = {
    'I': 'I. Khối kiến thức chung',
    'II': 'II. Khối kiến thức theo lĩnh vực',
    'III': 'III. Khối kiến thức theo khối ngành',
    'IV': 'IV. Khối kiến thức theo nhóm ngành',
    'V': 'V. Khối kiến thức ngành',
  };

  @override
  Widget build(BuildContext context) {
    final g = GraduationCheck.compute(progress, enrollments, courses);
    final status = <int, EnrollStatus>{};
    for (final e in enrollments) {
      if (status[e.courseId] == EnrollStatus.passed) continue;
      status[e.courseId] = e.status;
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _summary(g),
          const SizedBox(height: 12),
          for (final entry in _groups.entries)
            _group(g, entry.key, entry.value, status),
          _conditionalCard(g),
          const SizedBox(height: 8),
          const Text(
            'Ngoài các điều kiện trên, sinh viên còn phải đạt chuẩn đầu ra '
            'ngoại ngữ và không trong thời gian bị truy cứu trách nhiệm hình sự '
            'hoặc kỷ luật; phòng Đào tạo xét khi làm hồ sơ tốt nghiệp.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _summary(GraduationCheck g) {
    final color = g.eligible ? AppColors.ok : AppColors.warn;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(g.eligible ? Icons.verified : Icons.pending_actions,
                  color: color),
              const SizedBox(width: 8),
              Text(
                  g.eligible
                      ? 'Đủ điều kiện xét tốt nghiệp'
                      : 'Chưa đủ điều kiện tốt nghiệp',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ]),
            const SizedBox(height: 8),
            for (final c in g.conditions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(c.met ? Icons.check_circle : Icons.cancel_outlined,
                        size: 18,
                        color: c.met ? AppColors.ok : AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: '${c.title}: ',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: c.detail),
                      ])),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _group(GraduationCheck g, String key, String title,
      Map<int, EnrollStatus> status) {
    final blocks = g.blocks
        .where((b) => b.key == key || b.key.startsWith('$key.'))
        .toList();
    if (blocks.isEmpty) return const SizedBox.shrink();
    var required = 0, passed = 0;
    var directionAdded = false;
    for (final b in blocks) {
      if (b.kind == 'direction') {
        // Chỉ tính một hướng ngành: hướng đang theo, hoặc yêu cầu 12 TC.
        if (directionAdded) continue;
        directionAdded = true;
        required += b.required;
        final chosen = blocks.where((x) => x.key == g.directionKey);
        if (chosen.isNotEmpty) {
          passed += chosen.first.passed.clamp(0, chosen.first.required);
        }
        continue;
      }
      required += b.required;
      passed += b.passed.clamp(0, b.required);
    }
    final done = passed >= required;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold))),
                Text('$passed/$required TC',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: done ? AppColors.ok : AppColors.textDark)),
              ]),
              const SizedBox(height: 6),
              _bar(required == 0 ? 1 : passed / required, done),
              const SizedBox(height: 4),
              for (final b in blocks)
                _blockTile(g, b, status, sameAsGroup: b.key == key),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(double rate, bool done) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: rate.clamp(0, 1),
          minHeight: 6,
          backgroundColor: AppColors.tableHeader,
          color: done ? AppColors.ok : AppColors.info,
        ),
      );

  Widget _blockTile(
      GraduationCheck g, GradBlock b, Map<int, EnrollStatus> status,
      {bool sameAsGroup = false}) {
    final ignored = b.kind == 'direction' &&
        g.directionKey != null &&
        b.key != g.directionKey;
    final Color color;
    final String badge;
    if (ignored) {
      color = AppColors.textMuted;
      badge = 'Không theo hướng này';
    } else if (b.done) {
      color = AppColors.ok;
      badge = 'Đủ';
    } else {
      color = AppColors.danger;
      badge = 'Thiếu ${b.missing} TC';
    }
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
        title: Text(sameAsGroup ? 'Các học phần của khối' : b.name,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ignored ? AppColors.textMuted : AppColors.textDark)),
        subtitle: Text(
          '${b.requirementLabel} · đã đạt ${b.passed} TC'
          '${b.studying > 0 ? ' · đang học ${b.studying} TC' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(badge,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        children: [for (final c in b.courses) _courseRow(c, status[c.id])],
      ),
    );
  }

  Widget _courseRow(Course c, EnrollStatus? s) {
    final (icon, color, label) = switch (s) {
      EnrollStatus.passed => (Icons.check_circle, AppColors.ok, 'Đã đạt'),
      EnrollStatus.failed => (Icons.cancel, AppColors.danger, 'Chưa đạt'),
      EnrollStatus.studying => (Icons.autorenew, AppColors.info, 'Đang học'),
      _ => (Icons.radio_button_unchecked, AppColors.textMuted, 'Chưa học'),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
            child: Text('${c.code} · ${c.name}',
                style: const TextStyle(fontSize: 13))),
        Text('${c.credits} TC',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(label,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _conditionalCard(GraduationCheck g) {
    if (g.conditionalCourses.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Học phần điều kiện (chỉ xét Đạt / Không đạt)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const Text(
                'Không tính vào tín chỉ tích lũy và CPA, nhưng bắt buộc phải '
                'đạt để được xét tốt nghiệp.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            for (final e in g.conditionalCourses.entries)
              _courseRow(
                  e.key,
                  e.value
                      ? EnrollStatus.passed
                      : _latest(e.key.id)),
          ],
        ),
      ),
    );
  }

  EnrollStatus? _latest(int courseId) {
    EnrollStatus? s;
    for (final e in enrollments) {
      if (e.courseId == courseId) s = e.status;
    }
    return s;
  }
}

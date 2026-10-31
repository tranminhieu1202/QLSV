import '../models/academic.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import 'academic_service.dart';
import 'curriculum_seed.dart';

/// Một khối kiến thức khi xét tốt nghiệp.
class GradBlock {
  final String key;
  final String name;
  final String kind; // mandatory | elective | direction | grad

  /// Số TC phải tích lũy trong khối (khối bắt buộc = tổng TC các học phần).
  final int required;

  /// Tổng TC các học phần được mở trong khối (vd tự chọn 3/9 → 9).
  final int offered;

  /// TC đã đạt (không giới hạn bởi [required]).
  final int passed;

  /// TC đang học, chưa có điểm.
  final int studying;
  final List<Course> courses;

  const GradBlock({
    required this.key,
    required this.name,
    required this.kind,
    required this.required,
    required this.offered,
    required this.passed,
    required this.studying,
    required this.courses,
  });

  bool get done => passed >= required;
  int get missing => (required - passed).clamp(0, required);
  double get rate => required == 0 ? 1 : (passed / required).clamp(0, 1);

  /// Nhãn yêu cầu, vd "Bắt buộc 21 TC" hoặc "Tự chọn 3/9 TC".
  String get requirementLabel => switch (kind) {
        'mandatory' => 'Bắt buộc $required TC',
        'direction' => 'Chọn 1 hướng: $required/$offered TC',
        'grad' => 'Khóa luận hoặc HP thay thế: $required TC',
        _ => 'Tự chọn $required/$offered TC',
      };
}

/// Một điều kiện tốt nghiệp (QĐ 3626/QĐ-ĐHQGHN, Điều 50).
class GradCondition {
  final String title;
  final String detail;
  final bool met;
  const GradCondition(this.title, this.detail, this.met);
}

class GraduationCheck {
  final List<GradBlock> blocks;

  /// Khối hướng ngành được tính (đã đạt đủ, hoặc có nhiều TC đạt nhất).
  final String? directionKey;

  /// Học phần điều kiện (GDTC, GDQP-AN, kĩ năng bổ trợ) và đã đạt hay chưa.
  final Map<Course, bool> conditionalCourses;
  final List<GradCondition> conditions;

  const GraduationCheck({
    required this.blocks,
    required this.directionKey,
    required this.conditionalCourses,
    required this.conditions,
  });

  bool get eligible => conditions.every((c) => c.met);

  /// Tóm tắt những gì còn thiếu, vd "Thiếu 12 TC; II.2 (3 TC); CPA 1.85".
  String get missingSummary {
    if (eligible) return '';
    final parts = <String>[];
    for (final b in blocks) {
      if (b.kind == 'direction' || b.done) continue;
      parts.add('${b.key} (${b.missing} TC)');
    }
    final dirs = blocks.where((b) => b.kind == 'direction');
    if (dirs.isNotEmpty && !dirs.any((b) => b.done)) {
      final best = dirs.reduce((a, b) => a.passed >= b.passed ? a : b);
      parts.add('V.3 hướng ngành (${best.missing} TC)');
    }
    final cpa = conditions[2];
    if (!cpa.met) {
      parts.add(cpa.detail.substring(0, cpa.detail.length - 1)); // bỏ dấu '.'
    }
    final cond = [
      for (final e in conditionalCourses.entries)
        if (!e.value) e.key.code
    ];
    if (cond.isNotEmpty) parts.add('HP điều kiện: ${cond.join(', ')}');
    return parts.join('; ');
  }

  static GraduationCheck compute(
    StudentProgress progress,
    List<Enrollment> enrollments,
    List<Course> courses,
  ) {
    final valid = enrollments
        .where((e) => e.approval != Approval.rejected && e.course != null)
        .toList();
    final passedIds = {
      for (final e in valid)
        if (e.status == EnrollStatus.passed) e.courseId
    };
    final studyingIds = {
      for (final e in valid)
        if (e.status == EnrollStatus.studying && !passedIds.contains(e.courseId))
          e.courseId
    };

    final req = AcademicService.blockRequired(courses);
    final blocks = <GradBlock>[];
    for (final b in CurriculumSeed.blocks) {
      final key = b['key'] as String;
      final list = courses.where((c) => c.block == key && !c.conditional).toList()
        ..sort((a, b) {
          final s = a.plannedSemester.compareTo(b.plannedSemester);
          return s != 0 ? s : a.code.compareTo(b.code);
        });
      int sum(bool Function(Course) f) =>
          list.where(f).fold(0, (s, c) => s + c.credits);
      blocks.add(GradBlock(
        key: key,
        name: CurriculumSeed.blockNames[key] ?? key,
        kind: b['kind'] as String,
        required: req[key] ?? 0,
        offered: sum((_) => true),
        passed: sum((c) => passedIds.contains(c.id)),
        studying: sum((c) => studyingIds.contains(c.id)),
        courses: list,
      ));
    }

    // Hướng ngành: ưu tiên hướng đã đủ TC, sau đó hướng có nhiều TC đạt nhất.
    final dirs = blocks.where((b) => b.kind == 'direction').toList()
      ..sort((a, b) {
        if (a.done != b.done) return a.done ? -1 : 1;
        return b.passed.compareTo(a.passed);
      });
    final directionKey =
        dirs.isEmpty || dirs.first.passed == 0 ? null : dirs.first.key;

    final conditional = {
      for (final c in courses.where((c) => c.conditional).toList()
        ..sort((a, b) => a.code.compareTo(b.code)))
        c: passedIds.contains(c.id)
    };

    final counted = blocks
        .where((b) => b.kind != 'direction' || b.key == directionKey)
        .toList();
    final missingBlocks = counted.where((b) => !b.done).toList();
    final directionDone = dirs.any((b) => b.done);
    final total = progress.totalProgramCredits;
    final missingConditional =
        conditional.entries.where((e) => !e.value).map((e) => e.key).toList();

    final conditions = [
      GradCondition(
        'Tích lũy đủ tín chỉ chương trình',
        'Đã tích lũy ${progress.passedCredits}/$total TC'
            '${progress.passedCredits >= total ? '' : ' – còn thiếu ${progress.remainingCredits} TC'}.',
        progress.passedCredits >= total,
      ),
      GradCondition(
        'Đủ tín chỉ từng khối kiến thức',
        missingBlocks.isEmpty && directionDone
            ? 'Tất cả khối kiến thức đã đủ.'
            : 'Còn thiếu: ${[
                for (final b in missingBlocks)
                  if (b.kind != 'direction') '${b.key} (${b.missing} TC)',
                if (!directionDone)
                  'V.3 hướng ngành (${dirs.isEmpty ? 0 : dirs.first.missing} TC)',
              ].join(', ')}.',
        missingBlocks.isEmpty && directionDone,
      ),
      GradCondition(
        'Điểm trung bình chung tích lũy (CPA) từ 2,00',
        'CPA hiện tại: ${progress.cpa.toStringAsFixed(2)}.',
        progress.cpa >= 2.0,
      ),
      GradCondition(
        'Đạt các học phần điều kiện',
        missingConditional.isEmpty
            ? 'Đã đạt ${conditional.keys.map((c) => c.name).join(', ')}.'
            : 'Chưa đạt: ${missingConditional.map((c) => '${c.code} ${c.name}').join(', ')}.',
        missingConditional.isEmpty,
      ),
    ];

    return GraduationCheck(
      blocks: blocks,
      directionKey: directionKey,
      conditionalCourses: conditional,
      conditions: conditions,
    );
  }
}

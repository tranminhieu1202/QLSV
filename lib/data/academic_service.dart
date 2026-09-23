import '../models/academic.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/student.dart';
import 'curriculum_seed.dart';

class AcademicService {
  /// Required credits for every block (mandatory = sum of its courses).
  static Map<String, int> blockRequired(List<Course> courses) {
    final req = <String, int>{};
    for (final b in CurriculumSeed.blocks) {
      final key = b['key'] as String;
      final kind = b['kind'] as String;
      if (kind == 'mandatory') {
        req[key] = courses
            .where((c) => c.block == key && !c.conditional)
            .fold(0, (s, c) => s + c.credits);
      } else {
        req[key] = b['quota'] as int;
      }
    }
    return req;
  }

  static String blockKind(String key) => (CurriculumSeed.blocks
      .firstWhere((b) => b['key'] == key, orElse: () => const {'kind': 'elective'})['kind']) as String;

  /// Total program credits (đếm hướng ngành 1 lần).
  static int totalProgramCredits(List<Course> courses) {
    final req = blockRequired(courses);
    var total = 0;
    var directionCounted = false;
    for (final entry in req.entries) {
      if (blockKind(entry.key) == 'direction') {
        if (!directionCounted) {
          total += entry.value;
          directionCounted = true;
        }
      } else {
        total += entry.value;
      }
    }
    return total;
  }

  static int currentSemester(Student s, {DateTime? now}) {
    final ref = now ?? DateTime(2026, 9, 1);
    final years = ref.year - s.enrollYear;
    var sem = years * 2 + 1;
    if (sem > 8) sem = 8;
    if (sem < 1) sem = 1;
    return sem;
  }

  static StudentProgress compute(
    Student student,
    List<Enrollment> enrollments,
    List<Course> courses, {
    DateTime? now,
  }) {
    // Chỉ tính các đăng ký đã được duyệt và học phần không phải điều kiện.
    final effective = enrollments
        .where((e) =>
            e.approval == Approval.approved &&
            e.course != null &&
            !e.course!.conditional)
        .toList();

    final termsMap = <String, List<Enrollment>>{};
    for (final e in effective) {
      termsMap.putIfAbsent(e.term, () => []).add(e);
    }
    final termKeys = termsMap.keys.toList()..sort();

    double cumQuality = 0;
    int cumGraded = 0;
    int cumPassed = 0;
    final terms = <TermSummary>[];

    for (final term in termKeys) {
      final list = termsMap[term]!;
      int registered = 0, passed = 0, debt = 0;
      double termQuality = 0;
      int termGraded = 0;
      for (final e in list) {
        final credits = e.course!.credits;
        registered += credits;
        if (e.status == EnrollStatus.passed) passed += credits;
        if (e.status == EnrollStatus.failed) debt += credits;
        if (e.grade4 != null) {
          termQuality += e.grade4! * credits;
          termGraded += credits;
          cumQuality += e.grade4! * credits;
          cumGraded += credits;
        }
      }
      cumPassed += passed;
      final gpa = termGraded == 0 ? 0.0 : termQuality / termGraded;
      final cpa = cumGraded == 0 ? 0.0 : cumQuality / cumGraded;
      final hasGrades = termGraded > 0;

      final flags = <String>[];
      if (hasGrades && registered < CurriculumSeed.minCreditsPerTerm) {
        flags.add('Thiếu tín chỉ');
      }
      if (registered > CurriculumSeed.maxCreditsPerTerm) {
        flags.add('Thừa tín chỉ');
      }
      if (debt > 0) flags.add('Nợ $debt TC');

      terms.add(TermSummary(
        term: term,
        gpa: gpa,
        cpa: cpa,
        registeredCredits: registered,
        passedCredits: passed,
        debtCredits: debt,
        cumulativeCredits: cumPassed,
        flags: flags,
        level: hasGrades ? _levelForGpa(gpa, cpa) : WarnLevel.none,
      ));
    }

    // ---- passed credits per block ----
    final req = blockRequired(courses);
    final passedByBlock = <String, int>{};
    final passedIds = <int>{};
    for (final e in effective) {
      if (e.status == EnrollStatus.passed) {
        passedIds.add(e.courseId);
        passedByBlock[e.course!.block] =
            (passedByBlock[e.course!.block] ?? 0) + e.course!.credits;
      }
    }

    // chosen direction = hướng có nhiều TC đạt nhất
    int? chosenDirection;
    int bestDir = 0;
    for (final d in [1, 2, 3]) {
      final key = 'V.3.$d';
      final p = passedByBlock[key] ?? 0;
      if (p > bestDir) {
        bestDir = p;
        chosenDirection = d;
      }
    }

    final blocks = <BlockProgress>[];
    for (final b in CurriculumSeed.blocks) {
      final key = b['key'] as String;
      final kind = b['kind'] as String;
      final required = req[key] ?? 0;
      final passed = (passedByBlock[key] ?? 0).clamp(0, required);
      blocks.add(BlockProgress(
        key: key,
        name: CurriculumSeed.blockNames[key] ?? key,
        kind: kind,
        required: required,
        passed: passed,
      ));
    }

    // ---- program totals ----
    final total = totalProgramCredits(courses);
    var passedForProgram = 0;
    var directionAdded = false;
    for (final bp in blocks) {
      if (bp.kind == 'direction') {
        if (bp.key == 'V.3.${chosenDirection ?? 0}') {
          passedForProgram += bp.passed.clamp(0, bp.required);
          directionAdded = true;
        }
      } else {
        passedForProgram += bp.passed.clamp(0, bp.required);
      }
    }
    if (!directionAdded) {
      // chưa chọn hướng – vẫn cộng phần đã đạt tốt nhất (nếu có)
      passedForProgram += bestDir.clamp(0, 12);
    }

    // mandatory remaining (bỏ qua học phần điều kiện)
    int mandatoryRemaining = 0;
    for (final c in courses) {
      if (c.mandatory && !c.conditional && !passedIds.contains(c.id)) {
        mandatoryRemaining += c.credits;
      }
    }

    final unpaidDebt = _unpaidDebt(effective);
    final remaining = (total - passedForProgram).clamp(0, total);
    final electiveRemaining =
        (remaining - mandatoryRemaining).clamp(0, remaining);
    final cpa = cumGraded == 0 ? 0.0 : cumQuality / cumGraded;
    final latestGpa = terms.isEmpty ? 0.0 : terms.last.gpa;
    final curSem = currentSemester(student, now: now);

    final academicLevel = _academicLevel(terms, unpaidDebt);
    final warnings = _buildWarnings(
      courses: courses,
      effective: effective,
      terms: terms,
      cpa: cpa,
      passedIds: passedIds,
      unpaidDebt: unpaidDebt,
      currentSem: curSem,
      academicLevel: academicLevel,
      isFinalYear: curSem >= 7,
    );

    return StudentProgress(
      totalProgramCredits: total,
      passedCredits: passedForProgram,
      debtCredits: unpaidDebt,
      remainingCredits: remaining,
      mandatoryRemaining: mandatoryRemaining,
      electiveRemaining: electiveRemaining,
      cpa: cpa,
      latestGpa: latestGpa,
      currentSemesterNo: curSem,
      chosenDirection: chosenDirection,
      terms: terms,
      warnings: warnings,
      blocks: blocks,
    );
  }

  static int _unpaidDebt(List<Enrollment> effective) {
    final passed = <int>{};
    for (final e in effective) {
      if (e.status == EnrollStatus.passed) passed.add(e.courseId);
    }
    final failed = <int, int>{};
    for (final e in effective) {
      if (e.status == EnrollStatus.failed && !passed.contains(e.courseId)) {
        failed[e.courseId] = e.course?.credits ?? 0;
      }
    }
    return failed.values.fold(0, (a, b) => a + b);
  }

  static WarnLevel _levelForGpa(double gpa, double cpa) {
    if (gpa < 0.8 || cpa < 1.2) return WarnLevel.high;
    if (gpa < 1.2 || cpa < 1.5) return WarnLevel.medium;
    if (gpa < 1.5 || cpa < 2.0) return WarnLevel.low;
    return WarnLevel.none;
  }

  /// Kỳ hè (kết thúc bằng '3') – không xét cảnh báo học tập theo quy chế.
  static bool _isSummerTerm(String term) => term.endsWith('3');

  static WarnLevel _levelFromInt(int n) {
    switch (n.clamp(0, 3)) {
      case 3:
        return WarnLevel.high;
      case 2:
        return WarnLevel.medium;
      case 1:
        return WarnLevel.low;
      default:
        return WarnLevel.none;
    }
  }

  /// Mức cảnh báo học tập chính thức, tính dồn qua từng học kỳ chính theo
  /// quy chế đào tạo HUST (dựa trên số tín chỉ trượt trong kỳ và nợ đọng).
  static WarnLevel _academicLevel(List<TermSummary> terms, int unpaidDebt) {
    var level = 0;
    for (final t in terms) {
      if (_isSummerTerm(t.term)) continue;
      final graded = t.passedCredits > 0 || t.debtCredits > 0;
      if (!graded) continue;
      final failed = t.debtCredits;
      if (failed > 16) {
        level += 2; // +2 mức khi trượt > 16 TC
      } else if (failed > 8) {
        level += 1; // +1 mức khi trượt > 8 TC
      } else if (failed <= 4 && (level == 1 || level == 2)) {
        level -= 1; // trượt ≤ 4 TC ở mức 1/2 thì hạ 1 mức
      }
      level = level.clamp(0, 3);
    }
    // Nợ đọng từ đầu khóa > 24 TC → cảnh báo mức 3 (nguy cơ buộc thôi học).
    if (unpaidDebt > 24) level = 3;
    return _levelFromInt(level);
  }

  static List<StudentWarning> _buildWarnings({
    required List<Course> courses,
    required List<Enrollment> effective,
    required List<TermSummary> terms,
    required double cpa,
    required Set<int> passedIds,
    required int unpaidDebt,
    required int currentSem,
    required WarnLevel academicLevel,
    required bool isFinalYear,
  }) {
    final warnings = <StudentWarning>[];
    final graded =
        terms.where((t) => t.passedCredits > 0 || t.debtCredits > 0).toList();

    // Học phần đã thi nhưng chưa đạt (và chưa trả nợ ở lần học khác).
    final failedCourses = <Course>[];
    final failedIds = <int>{};
    for (final e in effective) {
      if (e.status == EnrollStatus.failed &&
          e.course != null &&
          !passedIds.contains(e.courseId) &&
          failedIds.add(e.courseId)) {
        failedCourses.add(e.course!);
      }
    }
    // Học phần đang học lại / đang đăng ký.
    final activeIds = <int>{
      for (final e in effective)
        if (e.status == EnrollStatus.studying ||
            e.status == EnrollStatus.registered)
          e.courseId
    };

    // 1) Cảnh báo học tập chính thức theo quy chế.
    if (academicLevel != WarnLevel.none) {
      final last = graded.isEmpty ? null : graded.last;
      warnings.add(StudentWarning(
        academicLevel,
        'Cảnh báo học tập ${academicLevel.label}',
        last == null
            ? 'Đánh giá cuối học kỳ chính theo quy chế.'
            : 'Kỳ ${last.term}: trượt ${last.debtCredits} TC · CPA ${cpa.toStringAsFixed(2)}',
      ));
    }

    // 2) Nợ tín chỉ đọng – kèm danh sách học phần không đạt cụ thể.
    if (unpaidDebt > 0) {
      warnings.add(StudentWarning(
        unpaidDebt > 24 ? WarnLevel.high : WarnLevel.info,
        'Nợ $unpaidDebt tín chỉ',
        unpaidDebt > 24
            ? 'Nợ đọng > 24 TC – nguy cơ buộc thôi học. Các học phần không đạt:'
            : 'Cần đăng ký học lại $unpaidDebt TC chưa đạt. Các học phần không đạt:',
        courses: [
          for (final c in failedCourses)
            WarningCourse(c.code, c.name, c.credits, 'failed'),
        ],
      ));
    }

    // 3) CPA dưới chuẩn tốt nghiệp – chỉ xét với sinh viên năm cuối.
    if (isFinalYear && cpa > 0 && cpa < 2.0) {
      warnings.add(StudentWarning(
        cpa < 1.5 ? WarnLevel.high : WarnLevel.medium,
        'CPA dưới chuẩn tốt nghiệp',
        'CPA ${cpa.toStringAsFixed(2)} < 2.00 (điều kiện tốt nghiệp).',
      ));
    }

    // 4) Chậm tiến độ đào tạo – kèm danh sách học phần bắt buộc còn thiếu.
    final behindMandatory = courses
        .where((c) =>
            c.mandatory &&
            !c.conditional &&
            c.plannedSemester < currentSem &&
            !passedIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.plannedSemester.compareTo(b.plannedSemester));
    final expected = courses
        .where((c) =>
            c.mandatory && !c.conditional && c.plannedSemester < currentSem)
        .fold(0, (s, c) => s + c.credits);
    final gotMandatory = expected -
        behindMandatory.fold(0, (s, c) => s + c.credits);
    if (behindMandatory.isNotEmpty && gotMandatory < expected * 0.8) {
      warnings.add(StudentWarning(
        WarnLevel.low,
        'Chậm tiến độ đào tạo',
        'Đạt $gotMandatory/$expected TC bắt buộc lẽ ra xong trước kỳ $currentSem. '
            'Học phần bắt buộc còn thiếu so với tiến trình:',
        courses: [
          for (final c in behindMandatory)
            WarningCourse(
              c.code,
              c.name,
              c.credits,
              failedIds.contains(c.id)
                  ? 'failed'
                  : activeIds.contains(c.id)
                      ? 'retaking'
                      : 'missing',
            ),
        ],
      ));
    }
    return warnings;
  }

  /// Gợi ý học phần nên đăng ký cho kỳ tới.
  static List<CourseSuggestion> suggest(
    Student student,
    List<Enrollment> enrollments,
    List<Course> courses, {
    DateTime? now,
    int? chosenDirection,
  }) {
    final passedIds = <int>{};
    final activeIds = <int>{}; // đang học hoặc đang chờ duyệt
    for (final e in enrollments) {
      if (e.approval == Approval.approved &&
          e.status == EnrollStatus.passed) {
        passedIds.add(e.courseId);
      }
      if ((e.status == EnrollStatus.studying ||
              e.status == EnrollStatus.registered) &&
          e.approval != Approval.rejected) {
        activeIds.add(e.courseId);
      }
    }
    final passedCodes = {
      for (final c in courses)
        if (passedIds.contains(c.id)) c.code
    };
    final req = blockRequired(courses);
    final passedByBlock = <String, int>{};
    for (final c in courses) {
      if (passedIds.contains(c.id)) {
        passedByBlock[c.block] = (passedByBlock[c.block] ?? 0) + c.credits;
      }
    }
    final curSem = currentSemester(student, now: now);

    final result = <CourseSuggestion>[];
    for (final c in courses) {
      if (c.conditional) continue;
      if (passedIds.contains(c.id) || activeIds.contains(c.id)) continue;

      // khối tự chọn đã đủ thì thôi
      final kind = blockKind(c.block);
      if (kind != 'mandatory') {
        final need = (req[c.block] ?? 0) - (passedByBlock[c.block] ?? 0);
        if (need <= 0) continue;
        // hướng ngành: chỉ gợi ý hướng đã chọn (nếu có)
        if (kind == 'direction' &&
            chosenDirection != null &&
            c.direction != chosenDirection) {
          continue;
        }
      }

      final prereqMet =
          c.prerequisite == null || passedCodes.contains(c.prerequisite);

      int priority;
      String reason;
      if (c.mandatory) {
        if (c.plannedSemester < curSem) {
          priority = 0;
          reason = 'Bắt buộc – trễ tiến độ (kỳ ${c.plannedSemester})';
        } else if (c.plannedSemester == curSem) {
          priority = 1;
          reason = 'Bắt buộc – đúng kỳ ${c.plannedSemester}';
        } else {
          priority = 4;
          reason = 'Bắt buộc – kỳ dự kiến ${c.plannedSemester}';
        }
      } else {
        final blockName = CurriculumSeed.blockNames[c.block] ?? c.block;
        if (c.plannedSemester <= curSem) {
          priority = 2;
          reason = 'Tự chọn – $blockName';
        } else {
          priority = 5;
          reason = 'Tự chọn – kỳ dự kiến ${c.plannedSemester}';
        }
      }
      if (!prereqMet) priority += 10;

      result.add(CourseSuggestion(
        course: c,
        reason: reason,
        prerequisiteMet: prereqMet,
        priority: priority,
      ));
    }

    result.sort((a, b) {
      if (a.priority != b.priority) return a.priority.compareTo(b.priority);
      return a.course.plannedSemester.compareTo(b.course.plannedSemester);
    });
    return result;
  }
}

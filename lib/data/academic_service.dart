import '../models/academic.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/student.dart';
import 'curriculum_seed.dart';

class AcademicService {
  static final Map<String, String> _blockKinds = {
    for (final b in CurriculumSeed.blocks)
      b['key'] as String: b['kind'] as String,
  };

  // Số TC yêu cầu chỉ phụ thuộc chương trình đào tạo, nên tính một lần cho
  // mỗi danh sách học phần thay vì lặp lại cho từng sinh viên.
  static List<Course>? _primedFor;
  static Map<String, int> _req = const {};
  static int _total = 0;

  static void _prime(List<Course> courses) {
    if (identical(_primedFor, courses)) return;
    final req = <String, int>{};
    for (final b in CurriculumSeed.blocks) {
      final key = b['key'] as String;
      req[key] = b['kind'] == 'mandatory'
          ? courses
              .where((c) => c.block == key && !c.conditional)
              .fold(0, (s, c) => s + c.credits)
          : b['quota'] as int;
    }
    // Tổng TC chương trình: các khối hướng ngành chỉ tính một lần.
    var total = 0;
    var directionCounted = false;
    for (final entry in req.entries) {
      if (blockKind(entry.key) != 'direction') {
        total += entry.value;
      } else if (!directionCounted) {
        total += entry.value;
        directionCounted = true;
      }
    }
    _primedFor = courses;
    _req = req;
    _total = total;
  }

  /// Required credits for every block (mandatory = sum of its courses).
  static Map<String, int> blockRequired(List<Course> courses) {
    _prime(courses);
    return _req;
  }

  static String blockKind(String key) => _blockKinds[key] ?? 'elective';

  /// Total program credits (đếm hướng ngành 1 lần).
  static int totalProgramCredits(List<Course> courses) {
    _prime(courses);
    return _total;
  }

  /// Năm bắt đầu của năm học hiện tại. Lấy từ mã kỳ hiện tại do quản trị đặt
  /// (vd '20261' → năm học 2026–2027); nếu không có thì theo lịch, năm học
  /// mới bắt đầu từ tháng 9.
  static int academicYearStart({String? term, DateTime? now}) {
    final fromTerm = term != null && term.length >= 4
        ? int.tryParse(term.substring(0, 4))
        : null;
    if (fromTerm != null) return fromTerm;
    final d = now ?? DateTime.now();
    return d.month >= 9 ? d.year : d.year - 1;
  }

  /// Học kỳ thứ mấy của sinh viên (1–8) tại kỳ hiện tại. Ví dụ năm học 2026:
  /// mã 26 → năm 1, 25 → năm 2, 24 → năm 3, 23 → năm 4; sang năm học 2027 thì
  /// mã 27 là năm 1. Kỳ 2 và kỳ hè ('…2', '…3') tính là học kỳ thứ hai của năm.
  static int currentSemester(Student s, {String? term, DateTime? now}) {
    final start = academicYearStart(term: term, now: now);
    final int half;
    if (term != null && term.length >= 5) {
      half = term.endsWith('1') ? 1 : 2;
    } else {
      final m = (now ?? DateTime.now()).month;
      half = m >= 9 || m == 1 ? 1 : 2;
    }
    return ((start - s.cohortYear) * 2 + half).clamp(1, 8);
  }

  // ------------------------------------------------------------ học kỳ
  /// Kỳ hè có mã kết thúc bằng '3' (vd '20253').
  static bool isSummerTerm(String term) =>
      term.length >= 5 && term.endsWith('3');

  /// Học kỳ chính mà một kỳ thuộc về khi xử lý học vụ: kết quả kỳ hè được
  /// tính vào học kỳ chính ngay trước nó (Điều 44), vd '20253' → '20252'.
  static String mainTermOf(String term) =>
      isSummerTerm(term) ? '${term.substring(0, term.length - 1)}2' : term;

  /// Tên học kỳ dễ đọc: '20251' → 'HK1 2025–2026', '20253' → 'Hè 2025–2026'.
  static String termLabel(String term) {
    final y = term.length == 5 ? int.tryParse(term.substring(0, 4)) : null;
    if (y == null) return term;
    final years = '$y–${y + 1}';
    switch (term[4]) {
      case '1':
        return 'HK1 $years';
      case '2':
        return 'HK2 $years';
      case '3':
        return 'Hè $years';
      default:
        return term;
    }
  }

  /// Các kỳ sinh viên có thể khai báo: từ năm nhập học tới năm học hiện tại
  /// (mỗi năm có HK1, HK2, hè) cùng các kỳ đã có trong [existing]; mới nhất
  /// đứng trước.
  static List<String> termOptions(Student s, String currentTerm,
      {Iterable<String> existing = const []}) {
    final last = academicYearStart(term: currentTerm);
    final first = s.cohortYear <= last ? s.cohortYear : last;
    final set = <String>{
      for (var y = first; y <= last; y++)
        for (final k in ['1', '2', '3']) '$y$k',
      ...existing,
    };
    return set.toList()..sort((a, b) => b.compareTo(a));
  }

  /// Giới hạn tín chỉ đăng ký mỗi học kỳ chính: tối thiểu 2/3, tối đa 3/2
  /// khối lượng trung bình một học kỳ theo kế hoạch chuẩn (Điều 21).
  static ({int min, int max}) creditLimits(List<Course> courses) {
    final avg =
        totalProgramCredits(courses) / CurriculumSeed.standardSemesters;
    return (min: (avg * 2 / 3).ceil(), max: (avg * 3 / 2).floor());
  }

  // ------------------------------------------------------ xử lý học vụ
  /// Năm đào tạo theo số tín chỉ tích lũy, chương trình chuẩn (Điều 17).
  static int trainingYearFor(int accumulatedCredits) {
    if (accumulatedCredits < 35) return 1;
    if (accumulatedCredits <= 70) return 2;
    if (accumulatedCredits <= 105) return 3;
    if (accumulatedCredits <= 140) return 4;
    if (accumulatedCredits <= 175) return 5;
    return 6;
  }

  /// Ngưỡng CPA bị cảnh báo theo năm đào tạo (Điều 44 khoản 1a).
  static double cpaWarnThreshold(int trainingYear) {
    switch (trainingYear) {
      case 1:
        return 1.2;
      case 2:
        return 1.4;
      case 3:
        return 1.6;
      default:
        return 1.8;
    }
  }

  /// Số lần bị cảnh báo liên tiếp → mức. Quá 2 lần liên tiếp thì thuộc diện
  /// buộc thôi học (Điều 44 khoản 2a).
  static WarnLevel levelForStreak(int streak) {
    if (streak <= 0) return WarnLevel.none;
    if (streak == 1) return WarnLevel.low;
    if (streak == 2) return WarnLevel.medium;
    return WarnLevel.high;
  }

  static StudentProgress compute(
    Student student,
    List<Enrollment> enrollments,
    List<Course> courses, {
    String? term,
    DateTime? now,
  }) {
    // Bỏ dữ liệu cũ bị từ chối và học phần điều kiện (GDTC, GDQP-AN...).
    final effective = enrollments
        .where((e) =>
            e.approval != Approval.rejected &&
            e.course != null &&
            !e.course!.conditional)
        .toList()
      ..sort((a, b) {
        final t = a.term.compareTo(b.term);
        return t != 0 ? t : a.id.compareTo(b.id);
      });

    final termsMap = <String, List<Enrollment>>{};
    for (final e in effective) {
      termsMap.putIfAbsent(mainTermOf(e.term), () => []).add(e);
    }
    final termKeys = termsMap.keys.toList()..sort();
    final limits = creditLimits(courses);

    // Mỗi học phần chỉ tích lũy một lần, lấy lần đạt gần nhất (học cải thiện
    // thì điểm mới thay điểm cũ – Điều 21 khoản 5).
    final passedBest = <int, Enrollment>{};
    final failedCredits = <int, int>{}; // học phần từng bị F → số TC
    var streak = 0;
    var gradedTerms = 0;
    final terms = <TermSummary>[];

    for (final key in termKeys) {
      int registered = 0, passed = 0, failed = 0;
      double termQuality = 0;
      int termGraded = 0;
      for (final e in termsMap[key]!) {
        final credits = e.course!.credits;
        registered += credits;
        if (e.status == EnrollStatus.passed) {
          passed += credits;
          passedBest[e.courseId] = e;
        }
        if (e.status == EnrollStatus.failed) {
          failed += credits;
          failedCredits[e.courseId] = credits;
        }
        // GPA học kỳ tính cả học phần đạt và không đạt (Điều 42 khoản 3).
        if (e.grade4 != null) {
          termQuality += e.grade4! * credits;
          termGraded += credits;
        }
      }

      // CPA chỉ tính các học phần đã tích lũy (Điều 42 khoản 5).
      var accumulated = 0;
      double cumQuality = 0;
      var cumGraded = 0;
      for (final e in passedBest.values) {
        accumulated += e.course!.credits;
        if (e.grade4 != null) {
          cumQuality += e.grade4! * e.course!.credits;
          cumGraded += e.course!.credits;
        }
      }
      var debtNow = 0;
      failedCredits.forEach((id, credits) {
        if (!passedBest.containsKey(id)) debtNow += credits;
      });

      final gpa = termGraded == 0 ? 0.0 : _round2(termQuality / termGraded);
      final cpa = cumGraded == 0 ? 0.0 : _round2(cumQuality / cumGraded);
      final hasGrades = termGraded > 0;

      // Cảnh báo học vụ sau mỗi học kỳ chính có điểm (Điều 44 khoản 1).
      final reasons = <String>[];
      if (hasGrades) {
        final year = trainingYearFor(accumulated);
        final cpaMin = cpaWarnThreshold(year);
        if (cpa < cpaMin) {
          reasons.add('CPA ${cpa.toStringAsFixed(2)} < '
              '${cpaMin.toStringAsFixed(2)} (năm đào tạo thứ $year)');
        }
        final gpaMin = gradedTerms == 0 ? 0.8 : 1.0;
        if (gpa < gpaMin) {
          reasons.add('GPA học kỳ ${gpa.toStringAsFixed(2)} < '
              '${gpaMin.toStringAsFixed(2)}'
              '${gradedTerms == 0 ? ' (học kỳ đầu khóa)' : ''}');
        }
        if (debtNow > 24) {
          reasons.add('Nợ đọng điểm F $debtNow TC > 24 TC');
        }
        if (failed * 2 > registered) {
          reasons.add('Không đạt $failed/$registered TC trong kỳ (> 50%)');
        }
        streak = reasons.isEmpty ? 0 : streak + 1;
        gradedTerms++;
      }

      final flags = <String>[];
      if (limits.max > 0) {
        if (hasGrades && registered < limits.min) flags.add('Thiếu tín chỉ');
        if (registered > limits.max) flags.add('Thừa tín chỉ');
      }
      if (failed > 0) flags.add('Nợ $failed TC');

      terms.add(TermSummary(
        term: key,
        gpa: gpa,
        cpa: cpa,
        registeredCredits: registered,
        passedCredits: passed,
        debtCredits: failed,
        cumulativeCredits: accumulated,
        flags: flags,
        level: hasGrades ? levelForStreak(streak) : WarnLevel.none,
        standing: hasGrades ? GradeScale.standing(gpa) : '',
        warnReasons: reasons,
      ));
    }

    // ---- passed credits per block ----
    final req = blockRequired(courses);
    final passedByBlock = <String, int>{};
    final passedIds = passedBest.keys.toSet();
    for (final e in passedBest.values) {
      passedByBlock[e.course!.block] =
          (passedByBlock[e.course!.block] ?? 0) + e.course!.credits;
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
    final graded = terms.where((t) => t.standing.isNotEmpty).toList();
    final cpa = terms.isEmpty ? 0.0 : terms.last.cpa;
    final latestGpa = graded.isEmpty ? 0.0 : graded.last.gpa;
    final accumulated = terms.isEmpty ? 0 : terms.last.cumulativeCredits;
    final curSem = currentSemester(student, term: term, now: now);

    final academicLevel = levelForStreak(streak);
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
      trainingYear: trainingYearFor(accumulated),
      chosenDirection: chosenDirection,
      academicLevel: academicLevel,
      behindSchedule: warnings.any((w) => w.title == _behindTitle),
      terms: terms,
      warnings: warnings,
      blocks: blocks,
    );
  }

  static double _round2(double v) => (v * 100).roundToDouble() / 100;

  static const _behindTitle = 'Chậm tiến độ đào tạo';

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
    final graded = terms.where((t) => t.standing.isNotEmpty).toList();

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

    // 1) Cảnh báo học vụ chính thức theo Quy chế ĐHQGHN (Điều 44).
    if (academicLevel != WarnLevel.none) {
      final last = graded.lastWhere((t) => t.warnReasons.isNotEmpty);
      final times = academicLevel == WarnLevel.high
          ? 'Thuộc diện buộc thôi học'
          : 'Cảnh báo học vụ lần ${academicLevel == WarnLevel.low ? 1 : 2}';
      warnings.add(StudentWarning(
        academicLevel,
        times,
        '${termLabel(last.term)}: ${last.warnReasons.join('; ')}.'
            '${academicLevel == WarnLevel.high ? ' Bị cảnh báo quá 2 lần liên tiếp.' : ''}',
        official: true,
      ));
    }

    // 2) Nợ tín chỉ đọng – kèm danh sách học phần không đạt cụ thể.
    if (unpaidDebt > 0) {
      warnings.add(StudentWarning(
        WarnLevel.info,
        'Nợ $unpaidDebt tín chỉ',
        unpaidDebt > 24
            ? 'Nợ đọng > 24 TC là một điều kiện cảnh báo học vụ. Các học phần không đạt:'
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
        _behindTitle,
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
    String? term,
    DateTime? now,
    int? chosenDirection,
  }) {
    final passedIds = <int>{};
    final activeIds = <int>{}; // đang học
    for (final e in enrollments) {
      if (e.approval != Approval.rejected &&
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
    final curSem = currentSemester(student, term: term, now: now);

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

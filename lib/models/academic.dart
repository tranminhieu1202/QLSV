import 'course.dart';

/// Severity of a warning shown to faculty / students.
///
/// Cảnh báo học vụ theo Quy chế ĐHQGHN (Điều 44) được tính theo số lần cảnh
/// báo liên tiếp: [low] = lần 1, [medium] = lần 2 liên tiếp, [high] = vượt quá
/// 2 lần liên tiếp (thuộc diện buộc thôi học).
enum WarnLevel { none, info, low, medium, high }

extension WarnLevelX on WarnLevel {
  String get label {
    switch (this) {
      case WarnLevel.none:
        return 'Không';
      case WarnLevel.info:
        return 'Lưu ý';
      case WarnLevel.low:
        return 'Cảnh báo lần 1';
      case WarnLevel.medium:
        return 'Cảnh báo lần 2';
      case WarnLevel.high:
        return 'Buộc thôi học';
    }
  }
}

/// Aggregated academic record of a student for a single main term (kết quả
/// học kỳ phụ/hè được gộp vào học kỳ chính ngay trước nó).
class TermSummary {
  final String term;

  /// Xếp loại học lực theo GPA học kỳ (Điều 45); rỗng khi chưa có điểm.
  final String standing;

  /// Lý do bị cảnh báo học vụ trong kỳ (rỗng nếu không bị cảnh báo).
  final List<String> warnReasons;
  final double gpa;
  final double cpa;
  final int registeredCredits;
  final int passedCredits;
  final int debtCredits;
  final int cumulativeCredits;
  final List<String> flags;
  final WarnLevel level;

  const TermSummary({
    required this.term,
    this.standing = '',
    this.warnReasons = const [],
    required this.gpa,
    required this.cpa,
    required this.registeredCredits,
    required this.passedCredits,
    required this.debtCredits,
    required this.cumulativeCredits,
    required this.flags,
    required this.level,
  });
}

class StudentWarning {
  final WarnLevel level;
  final String title;
  final String detail;

  /// Optional per-course breakdown (e.g. failed / missing courses) shown so
  /// faculty can see exactly which học phần is not passed or còn thiếu.
  final List<WarningCourse> courses;

  /// Cảnh báo học vụ chính thức theo quy chế (các mục khác là lưu ý).
  final bool official;

  const StudentWarning(this.level, this.title, this.detail,
      {this.courses = const [], this.official = false});
}

/// A single course line inside a warning (failed or missing vs curriculum).
class WarningCourse {
  final String code;
  final String name;
  final int credits;
  final String status; // 'failed' | 'missing' | 'retaking'
  const WarningCourse(this.code, this.name, this.credits, this.status);

  String get statusLabel {
    switch (status) {
      case 'failed':
        return 'Không đạt';
      case 'retaking':
        return 'Đang học lại';
      default:
        return 'Còn thiếu (chưa học)';
    }
  }
}

/// Progress within one knowledge block (khối kiến thức).
class BlockProgress {
  final String key;
  final String name;
  final String kind; // mandatory | elective | direction | grad
  final int required;
  final int passed;

  const BlockProgress({
    required this.key,
    required this.name,
    required this.kind,
    required this.required,
    required this.passed,
  });

  int get remaining => (required - passed).clamp(0, required);
  bool get done => passed >= required;
  double get rate => required == 0 ? 1 : (passed / required).clamp(0, 1);
}

/// A recommended course for the upcoming registration term.
class CourseSuggestion {
  final Course course;
  final String reason;
  final bool prerequisiteMet;
  final int priority; // lower = higher priority

  const CourseSuggestion({
    required this.course,
    required this.reason,
    required this.prerequisiteMet,
    required this.priority,
  });
}

/// Overall academic snapshot used across dashboards.
class StudentProgress {
  final int totalProgramCredits;
  final int passedCredits;
  final int debtCredits;
  final int remainingCredits;
  final int mandatoryRemaining;
  final int electiveRemaining;
  final double cpa;
  final double latestGpa;
  final int currentSemesterNo;

  /// Năm đào tạo xếp theo số tín chỉ tích lũy (Điều 17 khoản 2), dùng làm
  /// ngưỡng CPA khi xét cảnh báo học vụ. Khác [yearOfStudy] (theo khóa).
  final int trainingYear;
  final int? chosenDirection; // 1/2/3 hướng ngành đang theo

  /// Cảnh báo học vụ chính thức theo quy chế ĐHQGHN, tính ở học kỳ chính gần
  /// nhất có điểm (khác [worstLevel] vốn gộp cả các lưu ý như nợ tín chỉ, chậm
  /// tiến độ).
  final WarnLevel academicLevel;

  /// Chậm tiến độ: chưa đạt ≥ 80% số TC bắt buộc lẽ ra đã xong.
  final bool behindSchedule;
  final List<TermSummary> terms;
  final List<StudentWarning> warnings;
  final List<BlockProgress> blocks;

  const StudentProgress({
    required this.totalProgramCredits,
    required this.passedCredits,
    required this.debtCredits,
    required this.remainingCredits,
    required this.mandatoryRemaining,
    required this.electiveRemaining,
    required this.cpa,
    required this.latestGpa,
    required this.currentSemesterNo,
    this.trainingYear = 1,
    required this.chosenDirection,
    required this.academicLevel,
    required this.behindSchedule,
    required this.terms,
    required this.warnings,
    required this.blocks,
  });

  /// Sinh viên năm thứ mấy (kỳ 1–2 → năm 1, kỳ 3–4 → năm 2, ...).
  int get yearOfStudy => (currentSemesterNo + 1) ~/ 2;

  double get completionRate =>
      totalProgramCredits == 0 ? 0 : passedCredits / totalProgramCredits;

  WarnLevel get worstLevel {
    var worst = WarnLevel.none;
    for (final w in warnings) {
      if (w.level.index > worst.index) worst = w.level;
    }
    return worst;
  }
}

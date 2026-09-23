import 'course.dart';

/// Enrollment status of a student in a course during a specific term.
enum EnrollStatus { passed, failed, studying, registered }

extension EnrollStatusX on EnrollStatus {
  String get label {
    switch (this) {
      case EnrollStatus.passed:
        return 'Đạt';
      case EnrollStatus.failed:
        return 'Trượt';
      case EnrollStatus.studying:
        return 'Đang học';
      case EnrollStatus.registered:
        return 'Đã ĐK';
    }
  }

  static EnrollStatus fromKey(String k) =>
      EnrollStatus.values.firstWhere((e) => e.name == k,
          orElse: () => EnrollStatus.registered);
}

/// Approval state of a student-initiated course registration.
enum Approval { approved, pending, rejected }

extension ApprovalX on Approval {
  String get label {
    switch (this) {
      case Approval.approved:
        return 'Đã duyệt';
      case Approval.pending:
        return 'Chờ duyệt';
      case Approval.rejected:
        return 'Từ chối';
    }
  }

  static Approval fromKey(String? k) => Approval.values
      .firstWhere((e) => e.name == k, orElse: () => Approval.approved);
}

/// A student's registration + result for one course in one term.
class Enrollment {
  final int id;
  final int studentId;
  final int courseId;
  final String term; // e.g. 20231 (year 2023, semester 1)
  final double? midterm; // điểm giữa kì (hệ 10)
  final double? finalExam; // điểm cuối kì (hệ 10)
  final double? grade10; // điểm tổng kết hệ 10
  final String? gradeLetter; // A, B+, ...
  final double? grade4; // điểm hệ 4
  final EnrollStatus status;
  final Approval approval;

  // joined course info (optional)
  final Course? course;

  const Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.term,
    this.midterm,
    this.finalExam,
    this.grade10,
    this.gradeLetter,
    this.grade4,
    required this.status,
    this.approval = Approval.approved,
    this.course,
  });

  factory Enrollment.fromMap(Map<String, Object?> m, {Course? course}) =>
      Enrollment(
        id: (m['id'] as num).toInt(),
        studentId: (m['student_id'] as num).toInt(),
        courseId: (m['course_id'] as num).toInt(),
        term: m['term'] as String,
        midterm: (m['midterm'] as num?)?.toDouble(),
        finalExam: (m['final_exam'] as num?)?.toDouble(),
        grade10: (m['grade10'] as num?)?.toDouble(),
        gradeLetter: m['grade_letter'] as String?,
        grade4: (m['grade4'] as num?)?.toDouble(),
        status: EnrollStatusX.fromKey(m['status'] as String),
        approval: ApprovalX.fromKey(m['approval'] as String?),
        course: course,
      );
}

/// Helpers to convert a 10-scale grade into letter + 4-scale grade.
class GradeScale {
  /// Tỉ trọng điểm giữa kì trong điểm tổng kết (còn lại là điểm cuối kì).
  static const midtermWeight = 0.3;

  /// Điểm tổng kết hệ 10 từ điểm giữa kì (có thể trống) và điểm cuối kì.
  static double overall(double? midterm, double finalExam) {
    final o = midterm == null
        ? finalExam
        : midterm * midtermWeight + finalExam * (1 - midtermWeight);
    return double.parse(o.toStringAsFixed(1));
  }

  static String letter(double g10) {
    if (g10 >= 9.5) return 'A+';
    if (g10 >= 8.5) return 'A';
    if (g10 >= 8.0) return 'B+';
    if (g10 >= 7.0) return 'B';
    if (g10 >= 6.5) return 'C+';
    if (g10 >= 5.5) return 'C';
    if (g10 >= 5.0) return 'D+';
    if (g10 >= 4.0) return 'D';
    return 'F';
  }

  static double toFour(double g10) {
    if (g10 >= 9.5) return 4.0;
    if (g10 >= 8.5) return 4.0;
    if (g10 >= 8.0) return 3.5;
    if (g10 >= 7.0) return 3.0;
    if (g10 >= 6.5) return 2.5;
    if (g10 >= 5.5) return 2.0;
    if (g10 >= 5.0) return 1.5;
    if (g10 >= 4.0) return 1.0;
    return 0.0;
  }

  static bool isPass(double g10) => g10 >= 4.0;
}

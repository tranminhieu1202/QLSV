import 'course.dart';

/// Enrollment status of a student in a course during a specific term.
enum EnrollStatus { passed, failed, studying, registered }

extension EnrollStatusX on EnrollStatus {
  String get label {
    switch (this) {
      case EnrollStatus.passed:
        return 'Đạt';
      case EnrollStatus.failed:
        return 'Không đạt';
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

/// Trạng thái duyệt của dữ liệu cũ. Sinh viên nay tự khai báo nên mọi bản ghi
/// mới đều là [Approval.approved]; [Approval.rejected] vẫn bị loại khi tính.
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

/// Quy đổi điểm theo Quy chế đào tạo đại học tại ĐHQGHN
/// (QĐ 3626/QĐ-ĐHQGHN ngày 21/10/2022, Điều 41 & 43).
class GradeScale {
  /// Tỉ trọng điểm giữa kì khi sinh viên nhập điểm thành phần (còn lại là
  /// điểm cuối kì). Trọng số thực tế theo đề cương từng học phần; điểm kết thúc
  /// học phần không dưới 60%.
  static const midtermWeight = 0.3;

  /// Điểm học phần hệ 10 từ điểm giữa kì (có thể trống) và điểm cuối kì. Khi
  /// không có điểm giữa kì thì [finalExam] chính là điểm học phần.
  static double overall(double? midterm, double finalExam) {
    final o = midterm == null
        ? finalExam
        : midterm * midtermWeight + finalExam * (1 - midtermWeight);
    return double.parse(o.toStringAsFixed(1));
  }

  static String letter(double g10) {
    if (g10 >= 9.0) return 'A+';
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
    if (g10 >= 9.0) return 4.0;
    if (g10 >= 8.5) return 3.7;
    if (g10 >= 8.0) return 3.5;
    if (g10 >= 7.0) return 3.0;
    if (g10 >= 6.5) return 2.5;
    if (g10 >= 5.5) return 2.0;
    if (g10 >= 5.0) return 1.5;
    if (g10 >= 4.0) return 1.0;
    return 0.0;
  }

  static bool isPass(double g10) => g10 >= 4.0;

  /// Xếp loại học lực theo điểm trung bình chung học kỳ (Điều 45).
  static String standing(double gpa) {
    if (gpa >= 3.6) return 'Xuất sắc';
    if (gpa >= 3.2) return 'Giỏi';
    if (gpa >= 2.5) return 'Khá';
    if (gpa >= 2.0) return 'Trung bình';
    return 'Yếu';
  }
}

class Student {
  final int id;
  final String studentCode;
  final String fullName;
  final String cohort; // e.g. K65
  final String className;
  final String major;
  final int enrollYear;
  final String? advisorId;
  final String? advisorName;
  final int? direction; // hướng ngành V.3 (1/2/3)
  final String status; // active / suspended / graduated
  final String? phone; // số điện thoại
  final String? birthDate; // ngày tháng sinh (yyyy-MM-dd hoặc dd/MM/yyyy)
  final String? hometown; // quê quán
  final String? email; // email cá nhân

  const Student({
    required this.id,
    required this.studentCode,
    required this.fullName,
    required this.cohort,
    required this.className,
    required this.major,
    required this.enrollYear,
    this.advisorId,
    this.advisorName,
    this.direction,
    required this.status,
    this.phone,
    this.birthDate,
    this.hometown,
    this.email,
  });

  /// Năm nhập học suy ra từ mã sinh viên theo quy định của trường: 2 chữ số
  /// đầu là năm vào trường (26xxxxxx → 2026). Trả về null nếu mã không đúng
  /// dạng 8 chữ số.
  static int? enrollYearFromCode(String code) =>
      RegExp(r'^\d{8}$').hasMatch(code) ? 2000 + int.parse(code.substring(0, 2)) : null;

  /// Năm nhập học dùng để tính sinh viên năm thứ mấy: ưu tiên theo mã SV.
  int get cohortYear => enrollYearFromCode(studentCode) ?? enrollYear;

  factory Student.fromMap(Map<String, Object?> m) => Student(
        id: (m['id'] as num).toInt(),
        studentCode: m['student_code'] as String,
        fullName: m['full_name'] as String,
        cohort: m['cohort'] as String,
        className: m['class_name'] as String,
        major: m['major'] as String,
        enrollYear: m['enroll_year'] as int,
        advisorId: m['advisor_id'] as String?,
        advisorName: m['advisor_name'] as String?,
        direction: m['direction'] as int?,
        status: m['status'] as String,
        phone: m['phone'] as String?,
        birthDate: m['birth_date'] as String?,
        hometown: m['hometown'] as String?,
        email: m['email'] as String?,
      );
}

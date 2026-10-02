/// User roles for a single faculty's progress-tracking app.
///
/// The app is a private tool for one khoa's leadership & lecturers. Students
/// freely enter their own registration, grades and personal profile; faculty
/// roles are mostly for monitoring.
///  - [admin]     Quản trị – toàn quyền, phê duyệt thay đổi do trợ lý gửi lên
///  - [dean]      Ban chủ nhiệm khoa – chỉ xem toàn bộ thông tin
///  - [assistant] Trợ lý quản trị – tổng hợp/sửa thông tin, cần quản trị phê duyệt
///  - [advisor]   Cố vấn học tập – chỉ xem sinh viên theo lớp đang cố vấn
///  - [student]   Sinh viên – tự nhập hồ sơ, đăng ký học phần, nhập điểm
enum UserRole { admin, dean, assistant, advisor, student }

extension UserRoleX on UserRole {
  String get key => name;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Quản trị';
      case UserRole.dean:
        return 'Ban chủ nhiệm khoa';
      case UserRole.assistant:
        return 'Trợ lý quản trị';
      case UserRole.advisor:
        return 'Cố vấn học tập';
      case UserRole.student:
        return 'Sinh viên';
    }
  }

  String get shortLabel {
    switch (this) {
      case UserRole.admin:
        return 'Quản trị';
      case UserRole.dean:
        return 'BCN Khoa';
      case UserRole.assistant:
        return 'Trợ lý QT';
      case UserRole.advisor:
        return 'CVHT';
      case UserRole.student:
        return 'Sinh viên';
    }
  }

  bool get isFaculty => this != UserRole.student;

  bool get isAdmin => this == UserRole.admin;

  /// Thêm/sửa/xóa học phần trong chương trình đào tạo (chỉ quản trị).
  bool get canManageCurriculum => this == UserRole.admin;

  /// Thêm sinh viên / phân công cố vấn (quản trị trực tiếp, trợ lý cần duyệt).
  bool get canManageStudents =>
      this == UserRole.admin || this == UserRole.assistant;

  /// Sửa hồ sơ thông tin sinh viên (quản trị trực tiếp, trợ lý cần duyệt).
  bool get canEditStudentInfo =>
      this == UserRole.admin || this == UserRole.assistant;

  /// Trợ lý quản trị: mọi thay đổi phải chờ quản trị phê duyệt.
  bool get changesNeedApproval => this == UserRole.assistant;

  /// Phê duyệt các thay đổi do trợ lý gửi lên (chỉ quản trị).
  bool get canApproveChanges => this == UserRole.admin;

  /// Mở / đóng kỳ đăng ký học phần (chỉ quản trị).
  bool get canManageRegistrationPeriod => this == UserRole.admin;

  /// Xem toàn bộ sinh viên (cố vấn chỉ xem SV lớp mình phụ trách).
  bool get canViewAllStudents =>
      this == UserRole.admin ||
      this == UserRole.dean ||
      this == UserRole.assistant;

  /// Sinh viên tự đăng ký học phần & nhập điểm/hồ sơ của mình.
  bool get canRegisterCourses => this == UserRole.student;

  static UserRole fromKey(String key) => UserRole.values.firstWhere(
        (r) => r.name == key,
        orElse: () => UserRole.student,
      );
}

class AppUser {
  final String id;
  final String username;
  final UserRole role;
  final String fullName;
  final String? studentCode; // set when role == student
  final String? phone;
  final String? email;

  const AppUser({
    required this.id,
    required this.username,
    required this.role,
    required this.fullName,
    this.studentCode,
    this.phone,
    this.email,
  });

  factory AppUser.fromMap(Map<String, Object?> m) => AppUser(
        id: m['id'] as String,
        username: (m['username'] as String?) ?? '',
        role: UserRoleX.fromKey(m['role'] as String),
        fullName: (m['full_name'] as String?) ?? '',
        studentCode: m['student_code'] as String?,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
      );
}

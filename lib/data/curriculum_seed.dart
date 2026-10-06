/// Official training program – Ngành Quản trị trường học (cấu trúc khối
/// kiến thức; danh sách học phần nằm trong bảng `courses` trên Supabase).
/// Nguồn: Phụ lục 13, Quyết định số 2676/QĐ-ĐHGD ngày 24/10/2025,
/// Trường Đại học Giáo dục. Áp dụng từ khóa tuyển sinh 2025.
class CurriculumSeed {
  static const String major = 'Quản trị trường học';
  static const String faculty = 'Khoa Quản lý Giáo dục';
  static const String decision = 'QĐ 2676/QĐ-ĐHGD ngày 24/10/2025';

  /// Số học kỳ chính theo kế hoạch học tập chuẩn (4 năm). Giới hạn TC đăng ký
  /// mỗi kỳ tính từ đây – xem `AcademicService.creditLimits`.
  static const int standardSemesters = 8;

  /// Human-readable names for each knowledge block.
  static const Map<String, String> blockNames = {
    'I': 'I. Khối kiến thức chung',
    'II.1': 'II. Kiến thức theo lĩnh vực (bắt buộc)',
    'II.2': 'II. Kiến thức theo lĩnh vực (tự chọn)',
    'III.1': 'III. Kiến thức theo khối ngành (bắt buộc)',
    'III.2': 'III. Kiến thức theo khối ngành (tự chọn)',
    'IV.1': 'IV. Kiến thức theo nhóm ngành (bắt buộc)',
    'IV.2': 'IV. Kiến thức theo nhóm ngành (tự chọn)',
    'V.1': 'V. Kiến thức ngành (bắt buộc)',
    'V.2': 'V. Kiến thức ngành (tự chọn chung)',
    'V.3.1': 'V.3. Hướng ngành 1: Quản trị hành chính nhà trường',
    'V.3.2': 'V.3. Hướng ngành 2: Quản trị nhân lực và đào tạo',
    'V.3.3': 'V.3. Hướng ngành 3: Phát triển và quản lý chương trình giáo dục',
    'V.4': 'V.4. Thực tập nghiệp vụ',
    'V.4G': 'V.4. Khóa luận / Học phần thay thế tốt nghiệp',
  };

  /// Requirement per block. kind: mandatory | elective | direction | grad.
  /// [quota] is the required credits for non-mandatory blocks
  /// (mandatory blocks require every course).
  static const List<Map<String, Object>> blocks = [
    {'key': 'I', 'kind': 'mandatory', 'quota': 0},
    {'key': 'II.1', 'kind': 'mandatory', 'quota': 0},
    {'key': 'II.2', 'kind': 'elective', 'quota': 3},
    {'key': 'III.1', 'kind': 'mandatory', 'quota': 0},
    {'key': 'III.2', 'kind': 'elective', 'quota': 7},
    {'key': 'IV.1', 'kind': 'mandatory', 'quota': 0},
    {'key': 'IV.2', 'kind': 'elective', 'quota': 9},
    {'key': 'V.1', 'kind': 'mandatory', 'quota': 0},
    {'key': 'V.2', 'kind': 'elective', 'quota': 6},
    {'key': 'V.3.1', 'kind': 'direction', 'quota': 12},
    {'key': 'V.3.2', 'kind': 'direction', 'quota': 12},
    {'key': 'V.3.3', 'kind': 'direction', 'quota': 12},
    {'key': 'V.4', 'kind': 'mandatory', 'quota': 0},
    {'key': 'V.4G', 'kind': 'grad', 'quota': 6},
  ];
}

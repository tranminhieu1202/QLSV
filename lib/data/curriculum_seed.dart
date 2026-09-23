/// Official training program – Ngành Quản trị trường học.
/// Nguồn: Phụ lục 13, Quyết định số 2676/QĐ-ĐHGD ngày 24/10/2025,
/// Trường Đại học Giáo dục. Áp dụng từ khóa tuyển sinh 2025.
class CurriculumSeed {
  static const String major = 'Quản trị trường học';
  static const String faculty = 'Khoa Quản lý Giáo dục';
  static const String decision = 'QĐ 2676/QĐ-ĐHGD ngày 24/10/2025';

  static const int minCreditsPerTerm = 14;
  static const int maxCreditsPerTerm = 28;

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

  /// [code, name, credits, mandatory, planned, semText, block, direction,
  ///  conditional, oriented]
  static const List<List<Object?>> courses = [
    // ---------------- I. Khối kiến thức chung (21 TC) ----------------
    ['PHI1006', 'Triết học Mác – Lênin', 3, 1, 1, '1', 'I', null, 0, 0],
    ['PEC1008', 'Kinh tế chính trị Mác – Lênin', 2, 1, 1, '1', 'I', null, 0, 0],
    ['PHI1002', 'Chủ nghĩa xã hội khoa học', 2, 1, 3, '3', 'I', null, 0, 0],
    ['HIS1001', 'Lịch sử Đảng Cộng sản Việt Nam', 2, 1, 4, '4', 'I', null, 0, 0],
    ['POL1001', 'Tư tưởng Hồ Chí Minh', 2, 1, 2, '2', 'I', null, 0, 0],
    ['THL1057', 'Nhà nước và Pháp luật đại cương', 2, 1, 2, '2', 'I', null, 0, 0],
    ['FLF1101', 'Ngoại ngữ B1', 5, 1, 2, '2-4', 'I', null, 0, 0],
    ['VNU1001', 'Nhập môn công nghệ số và ứng dụng trí tuệ nhân tạo', 3, 1, 2, '2', 'I', null, 0, 0],
    ['TMT2100', 'Kĩ năng bổ trợ', 3, 1, 3, '3-7', 'I', null, 1, 0],
    ['PES1001', 'Giáo dục thể chất', 4, 1, 2, '2-7', 'I', null, 1, 0],
    ['DEF1001', 'Giáo dục quốc phòng – an ninh', 8, 1, 2, '2-3', 'I', null, 1, 0],

    // ------------- II.1 Kiến thức theo lĩnh vực - bắt buộc -------------
    ['PSE2008', 'Tâm lí học giáo dục', 4, 1, 1, '1', 'II.1', null, 0, 0],
    ['EAM3002', 'Nhập môn Thống kê ứng dụng trong giáo dục', 3, 1, 2, '2', 'II.1', null, 0, 0],
    ['PSE2004', 'Phương pháp nghiên cứu khoa học trong giáo dục', 3, 1, 2, '2', 'II.1', null, 0, 0],
    ['EDM2013', 'Nhập môn Khoa học quản lý trong giáo dục', 2, 1, 1, '1', 'II.1', null, 0, 0],
    ['EDT2001', 'Nhập môn Công nghệ giáo dục', 2, 1, 1, '1', 'II.1', null, 0, 0],
    ['EAM2052', 'Nhập môn đo lường và đánh giá trong giáo dục', 2, 1, 1, '1', 'II.1', null, 0, 0],
    ['TMT3013', 'Đạo đức nghề nghiệp trong lĩnh vực giáo dục', 4, 1, 1, '1-8', 'II.1', null, 0, 0],

    // ------------- II.2 Kiến thức theo lĩnh vực - tự chọn (3/9) --------
    ['PSE2006', 'Tư vấn tâm lý học đường', 3, 0, 3, '3', 'II.2', null, 0, 0],
    ['PSE2009', 'Nhập môn Khoa học giáo dục', 3, 0, 2, '2', 'II.2', null, 0, 1],
    ['EDM2002', 'Quản lý hành chính nhà nước và quản lý ngành giáo dục và đào tạo', 3, 0, 2, '2', 'II.2', null, 0, 0],

    // ------------- III.1 Kiến thức theo khối ngành - bắt buộc ----------
    ['MNS2064', 'Hành chính học đại cương', 3, 1, 3, '3', 'III.1', null, 0, 0],
    ['SCA1002', 'Đại cương về Quản trị trường học', 3, 1, 3, '3', 'III.1', null, 0, 0],
    ['SCA1006', 'Lý thuyết hành chính trong các tổ chức giáo dục', 3, 1, 4, '4', 'III.1', null, 0, 0],

    // ------------- III.2 Kiến thức theo khối ngành - tự chọn (7/17) ----
    ['EDM1006', 'Xã hội học giáo dục', 2, 0, 3, '3', 'III.2', null, 0, 1],
    ['EDM2003', 'Kinh tế học giáo dục', 3, 0, 3, '3', 'III.2', null, 0, 1],
    ['EDM1002', 'Tư duy thiết kế cho việc lãnh đạo và học tập', 2, 0, 3, '3', 'III.2', null, 0, 0],
    ['SCA2014', 'Quản trị truyền thông và quan hệ công chúng trong nhà trường', 3, 0, 3, '3', 'III.2', null, 0, 0],
    ['SCA3013', 'Giám sát hoạt động dạy học và giáo dục trong nhà trường', 3, 0, 3, '3', 'III.2', null, 0, 1],
    ['SCA1007', 'Nghiên cứu so sánh hệ thống đa cấp trong quản trị nhà trường', 3, 0, 3, '3', 'III.2', null, 0, 0],
    ['SCA3035', 'Xây dựng môi trường giáo dục', 2, 0, 3, '3', 'III.2', null, 0, 1],

    // ------------- IV.1 Kiến thức theo nhóm ngành - bắt buộc -----------
    ['SCA2001', 'Ứng dụng tâm lý học trong quản trị nhà trường', 3, 1, 4, '4', 'IV.1', null, 0, 0],
    ['EDM2004', 'Lý luận quản lý và quản lý giáo dục', 3, 1, 4, '4', 'IV.1', null, 0, 0],
    ['SCA2015', 'Quản trị chương trình nhà trường', 3, 1, 5, '5', 'IV.1', null, 0, 0],

    // ------------- IV.2 Kiến thức theo nhóm ngành - tự chọn (9/18) -----
    ['SCA2004', 'Quản trị chiến lược trong nhà trường', 3, 0, 5, '5', 'IV.2', null, 0, 1],
    ['SCA2006', 'Ứng dụng công nghệ thông tin trong quản trị nhà trường', 3, 0, 4, '4', 'IV.2', null, 0, 0],
    ['SCA2008', 'Xây dựng văn hóa nhà trường', 3, 0, 4, '4', 'IV.2', null, 0, 1],
    ['SCA2009', 'Kỹ năng quản trị trường học 1', 3, 0, 4, '4', 'IV.2', null, 0, 1],
    ['SCA2010', 'Kỹ năng quản trị trường học 2', 3, 0, 4, '4', 'IV.2', null, 0, 0],
    ['SCA2011', 'Kỹ năng quản trị trường học 3', 3, 0, 4, '4', 'IV.2', null, 0, 0],

    // ------------- V.1 Kiến thức ngành - bắt buộc (21) ----------------
    ['SCA3018', 'Quản trị và phát triển nguồn nhân lực trong nhà trường', 3, 1, 5, '5', 'V.1', null, 0, 0],
    ['SCA3019', 'Quản trị tài chính trong nhà trường', 3, 1, 6, '6', 'V.1', null, 0, 0],
    ['SCA3020', 'Quản trị cơ sở vật chất trong nhà trường', 3, 1, 5, '5', 'V.1', null, 0, 0],
    ['SCA3021', 'Quản trị chất lượng và trách nhiệm giải trình trong giáo dục', 3, 1, 7, '7', 'V.1', null, 0, 0],
    ['SCA3022', 'Tiếng Anh chuyên ngành Quản trị trường học', 3, 1, 5, '5', 'V.1', null, 0, 0],
    ['SCA3009', 'Quản trị thương hiệu và Marketing của nhà trường', 3, 1, 6, '6', 'V.1', null, 0, 0],
    ['SCA3017', 'Kỹ năng quản trị nhà trường hiệu quả', 3, 1, 6, '6', 'V.1', null, 0, 0],

    // ------------- V.2 Kiến thức ngành - tự chọn chung (6/12) ---------
    ['EDM3009', 'Huy động cộng đồng phát triển giáo dục', 3, 0, 5, '5', 'V.2', null, 0, 1],
    ['SCA3010', 'Lãnh đạo sáng tạo', 3, 0, 6, '6', 'V.2', null, 0, 1],
    ['EDM2006', 'Hệ thống giáo dục quốc dân và cơ sở pháp lý trong quản lý giáo dục', 3, 0, 5, '5', 'V.2', null, 0, 0],
    ['SCA3016', 'Hệ thống thông tin quản trị nhà trường', 3, 0, 6, '6', 'V.2', null, 0, 0],

    // ------------- V.3.1 Hướng ngành 1 (12/24) -----------------------
    ['SCA3002', 'Chính sách và thực thi quản trị trường học', 3, 0, 7, '7', 'V.3.1', 1, 0, 0],
    ['SCA2012', 'Kỹ thuật điều hành nhà trường', 3, 0, 7, '7', 'V.3.1', 1, 0, 1],
    ['SCA3033', 'Quản lý và thực thi văn bản hành chính nhà nước trong lĩnh vực giáo dục', 3, 0, 7, '7', 'V.3.1', 1, 0, 1],
    ['SCA3023', 'Văn thư lưu trữ quản trị trường học', 3, 0, 7, '7', 'V.3.1', 1, 0, 1],
    ['SCA3024', 'Nghi thức văn phòng và lễ tân', 3, 0, 8, '8', 'V.3.1', 1, 0, 1],
    ['SCA3025', 'Quản trị tổ chức sự kiện', 3, 0, 8, '8', 'V.3.1', 1, 0, 0],
    ['SCA3026', 'Kỹ năng soạn thảo văn bản hành chính', 3, 0, 7, '7', 'V.3.1', 1, 0, 0],
    ['SCA3027', 'Truyền thông và xây dựng thương hiệu nhà trường', 3, 0, 7, '7', 'V.3.1', 1, 0, 0],

    // ------------- V.3.2 Hướng ngành 2 (12/24) -----------------------
    ['SCA3007', 'Tư vấn hướng nghiệp trong nhà trường', 3, 0, 7, '7', 'V.3.2', 2, 0, 1],
    ['SCA3008', 'Quản trị dự án trong giáo dục', 3, 0, 7, '7', 'V.3.2', 2, 0, 1],
    ['SCA3028', 'Quản trị phát triển chuyên môn giáo viên', 3, 0, 7, '7', 'V.3.2', 2, 0, 1],
    ['SCA3029', 'Tạo động lực trong tổ chức giáo dục', 3, 0, 7, '7', 'V.3.2', 2, 0, 1],
    ['SCA3030', 'Quản trị sự thay đổi trong tổ chức giáo dục', 3, 0, 8, '8', 'V.3.2', 2, 0, 1],
    ['SCA3031', 'Hành vi tổ chức', 3, 0, 7, '7', 'V.3.2', 2, 0, 1],
    ['EDM3011', 'Văn hóa tổ chức và truyền thông nội bộ trong trường học', 3, 0, 7, '7', 'V.3.2', 2, 0, 0],
    ['EDM3013', 'Phân tích và quản trị thực hiện công việc', 3, 0, 8, '8', 'V.3.2', 2, 0, 0],

    // ------------- V.3.3 Hướng ngành 3 (12/24) -----------------------
    ['TMT3009', 'Lý luận dạy học', 3, 0, 7, '7', 'V.3.3', 3, 0, 0],
    ['PSE2005', 'Tổ chức các hoạt động giáo dục trong nhà trường', 3, 0, 7, '7', 'V.3.3', 3, 0, 0],
    ['EDM3014', 'Thiết kế và phát triển chương trình giảng dạy', 3, 0, 7, '7', 'V.3.3', 3, 0, 1],
    ['EDM3015', 'Huy động cộng đồng phát triển chương trình giáo dục nhà trường', 3, 0, 7, '7', 'V.3.3', 3, 0, 1],
    ['EDM3016', 'Khởi nghiệp trong giáo dục', 3, 0, 8, '8', 'V.3.3', 3, 0, 1],
    ['EDM3017', 'Thực thi chương trình giáo dục trong nhà trường', 3, 0, 8, '8', 'V.3.3', 3, 0, 0],
    ['SCA3032', 'Đánh giá chương trình giáo dục', 3, 0, 7, '7', 'V.3.3', 3, 0, 1],
    ['SCA3034', 'Phân tích chương trình giáo dục', 3, 0, 7, '7', 'V.3.3', 3, 0, 1],

    // ------------- V.4 Thực tập & Tốt nghiệp -------------------------
    ['SCA3050', 'Thực tập nghiệp vụ 1', 3, 1, 6, '6', 'V.4', null, 0, 0],
    ['SCA3051', 'Thực tập nghiệp vụ 2', 4, 1, 7, '7', 'V.4', null, 0, 0],
    ['SCA4003', 'Khóa luận tốt nghiệp', 6, 0, 8, '8', 'V.4G', null, 0, 0],
    ['SCA4004', 'Thực hành quản trị trường học', 3, 0, 8, '8', 'V.4G', null, 0, 0],
    ['SCA4005', 'Nghiệp vụ Quản lý hành chính trong cơ sở giáo dục', 3, 0, 8, '8', 'V.4G', null, 0, 0],
  ];
}

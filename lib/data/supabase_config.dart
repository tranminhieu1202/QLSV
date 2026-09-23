/// Cấu hình kết nối Supabase.
///
/// Điền URL + anon key của project (Supabase Studio → Project Settings → API).
/// Với local dev (`supabase start`), giá trị mặc định thường là:
///   url    = http://127.0.0.1:54321
///   anonKey = (chuỗi in ra ở terminal khi chạy `supabase start`)
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54321',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Tên đăng nhập của app là MSSV (sinh viên) hoặc username (giảng viên);
  /// Supabase Auth dùng email nên ta map về email nội bộ.
  static const String facultyEmailDomain = 'qlgd.edu.vn';
  static const String studentEmailDomain = 'sv.qlgd.edu.vn';

  /// Chuyển tên đăng nhập người dùng nhập thành email đăng nhập Supabase.
  static String toEmail(String usernameOrEmail) {
    final u = usernameOrEmail.trim();
    if (u.contains('@')) return u;
    final isStudentCode = RegExp(r'^\d+$').hasMatch(u);
    return '$u@${isStudentCode ? studentEmailDomain : facultyEmailDomain}';
  }
}

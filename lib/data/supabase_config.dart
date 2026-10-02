/// Cấu hình kết nối Supabase (dùng CHUNG cho mọi máy Win + Mac).
///
/// Điền URL + anon key của CLOUD project (Dashboard → Project Settings → API),
/// rồi commit/push — cả hai máy chỉ cần `git pull` là đồng nhất, không phải
/// truyền tham số mỗi lần chạy.
///  - anon key là khóa CÔNG KHAI, an toàn để commit (bảo mật do RLS đảm nhiệm).
///    Với project dùng khóa mới, đây là "Publishable key" (sb_publishable_...).
///  - service_role / secret key (sb_secret_...) TUYỆT ĐỐI không đưa vào đây
///    (chỉ dùng trong Edge Function, Supabase tự inject).
///  - Có thể tạm ghi đè khi chạy: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xvyomegeavqizpnqptmb.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_FB0S5F2F8pAA1AOfMzCwwg_p5VzpeXW',
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

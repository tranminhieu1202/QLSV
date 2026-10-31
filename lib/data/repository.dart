import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/academic.dart';
import '../models/course.dart';
import '../models/enrollment.dart';
import '../models/student.dart';
import '../models/user.dart';
import 'academic_service.dart';
import 'curriculum_seed.dart';
import 'supabase_config.dart';

/// Pairs a student with their computed academic progress.
class StudentWithProgress {
  final Student student;
  final StudentProgress progress;
  StudentWithProgress(this.student, this.progress);
}

class AuditEntry {
  final String ts;
  final String actorName;
  final String role;
  final String action;
  final String detail;
  final String? studentCode;
  AuditEntry(this.ts, this.actorName, this.role, this.action, this.detail,
      this.studentCode);
  factory AuditEntry.fromMap(Map<String, Object?> m) => AuditEntry(
        m['ts'] as String,
        (m['actor_name'] as String?) ?? '',
        (m['role'] as String?) ?? '',
        m['action'] as String,
        m['detail'] as String,
        m['student_code'] as String?,
      );
}

/// A single proposed edit to a student profile field.
class ProfileChange {
  final String field; // column name
  final String label; // human label
  final String? oldValue;
  final String? newValue;
  const ProfileChange(this.field, this.label, this.oldValue, this.newValue);
}

/// A pending profile change waiting for admin (quản trị) approval.
class ChangeRequest {
  final int id;
  final int studentId;
  final String studentCode;
  final String studentName;
  final String field;
  final String fieldLabel;
  final String? oldValue;
  final String? newValue;
  final String requestedBy;
  final String requestedRole;
  final String ts;
  final String status;
  ChangeRequest({
    required this.id,
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    required this.field,
    required this.fieldLabel,
    required this.oldValue,
    required this.newValue,
    required this.requestedBy,
    required this.requestedRole,
    required this.ts,
    required this.status,
  });
  factory ChangeRequest.fromMap(Map<String, Object?> m) => ChangeRequest(
        id: (m['id'] as num).toInt(),
        studentId: (m['student_id'] as num).toInt(),
        studentCode: m['student_code'] as String,
        studentName: (m['student_name'] as String?) ?? '',
        field: m['field'] as String,
        fieldLabel: m['field_label'] as String,
        oldValue: m['old_value'] as String?,
        newValue: m['new_value'] as String?,
        requestedBy: (m['requested_by'] as String?) ?? '',
        requestedRole: (m['requested_role'] as String?) ?? '',
        ts: (m['created_at'] as String?) ?? '',
        status: m['status'] as String,
      );
}

/// Ném khi tài khoản đã bị quản trị khóa (active = false).
class AccountLockedException implements Exception {
  const AccountLockedException();
}

/// Supabase Auth tạm chặn vì quá nhiều lần đăng nhập (HTTP 429) – thường do
/// cả lớp đăng nhập cùng lúc qua chung một địa chỉ IP (Wi-Fi trường).
class LoginRateLimitedException implements Exception {
  const LoginRateLimitedException();
}

/// Đúng mật khẩu nhưng tài khoản chưa có hồ sơ (profiles) trên hệ thống.
class MissingProfileException implements Exception {
  const MissingProfileException();
}

/// Lỗi phía máy chủ xác thực, không phải do sai tên đăng nhập / mật khẩu.
class LoginServerException implements Exception {
  const LoginServerException(this.message);
  final String message;
}

/// Read/write access to the Supabase (PostgreSQL) backend. RLS enforces which
/// rows each role may touch; this layer only shapes the queries.
class Repository {
  Repository(this._sb);
  final SupabaseClient _sb;

  static const defaultTerm = '20261';

  List<Map<String, Object?>> _rows(List<dynamic> rows) =>
      rows.map((r) => Map<String, Object?>.from(r as Map)).toList();

  /// PostgREST trả tối đa `max_rows` (1000) dòng mỗi lần; đọc theo trang để
  /// không bị cắt bớt dữ liệu khi khoa có nhiều sinh viên / bản ghi điểm.
  /// [query] phải có `order` ổn định để phân trang không trùng/sót.
  static const _pageSize = 1000;
  Future<List<Map<String, Object?>>> _fetchAll(
      PostgrestTransformBuilder<PostgrestList> Function() query) async {
    final out = <Map<String, Object?>>[];
    for (var from = 0;; from += _pageSize) {
      final page = await query().range(from, from + _pageSize - 1);
      out.addAll(_rows(page));
      if (page.length < _pageSize) return out;
    }
  }

  /// Xóa các bộ nhớ đệm; gọi khi dữ liệu dùng chung thay đổi (xem
  /// `AppState.bumpData`).
  void invalidateCaches() {
    _courseCache = null;
    _progressCache.clear();
  }

  // ------------------------------------------------------------------ auth
  Future<AppUser?> login(String username, String password) async {
    final email = SupabaseConfig.toEmail(username);
    try {
      final res =
          await _sb.auth.signInWithPassword(email: email, password: password);
      final uid = res.user?.id;
      if (uid == null) return null;
      final row =
          await _sb.from('profiles').select().eq('id', uid).maybeSingle();
      if (row == null) {
        await _sb.auth.signOut();
        throw const MissingProfileException();
      }
      final user = AppUser.fromMap(Map<String, Object?>.from(row));
      if (!user.active) {
        await _sb.auth.signOut();
        throw const AccountLockedException();
      }
      return user;
    } on AuthApiException catch (e) {
      if (e.statusCode == '429' || e.code == 'over_request_rate_limit') {
        throw const LoginRateLimitedException();
      }
      // 400 / invalid_credentials => sai email/mật khẩu.
      if (e.statusCode == '400' || e.code == 'invalid_credentials') {
        return null;
      }
      throw LoginServerException(e.message);
    }
    // Lỗi mạng / project Supabase tạm dừng sẽ ném tiếp để báo "không kết nối".
  }

  Future<void> signOut() => _sb.auth.signOut();

  /// Phiên đăng nhập Supabase còn lưu trên máy (tự làm mới token).
  bool get hasSession => _sb.auth.currentSession != null;

  /// Phát sự kiện khi phiên bị đăng xuất / hết hạn không làm mới được.
  Stream<AuthState> get authChanges => _sb.auth.onAuthStateChange;

  /// Người dùng hiện tại tự đổi mật khẩu của mình.
  Future<String?> changeOwnPassword(String newPassword) async {
    try {
      await _sb.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  /// Quản trị đặt lại mật khẩu cho một sinh viên (qua Edge Function service role).
  Future<String?> resetStudentPassword({
    required Student student,
    String? newPassword,
    required AppUser actor,
  }) async {
    try {
      final res = await _sb.functions.invoke('reset-student-password', body: {
        'studentCode': student.studentCode,
        if (newPassword != null && newPassword.isNotEmpty)
          'password': newPassword,
      });
      final data = res.data;
      if (data is Map && data['ok'] == true) {
        await addAudit(actor, 'Đặt lại mật khẩu',
            'Đặt lại mật khẩu cho ${student.studentCode}',
            studentCode: student.studentCode);
        return null;
      }
      return (data is Map && data['error'] is String)
          ? data['error'] as String
          : 'Không đặt lại được mật khẩu.';
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['error'] is String) return d['error'] as String;
      return 'Chưa đặt lại được mật khẩu: Edge Function '
          'reset-student-password chưa được deploy lên cloud.';
    }
  }

  /// Danh sách tài khoản cán bộ (không phải sinh viên) cho màn quản lý.
  Future<List<AppUser>> facultyAccounts() async {
    final rows = await _sb
        .from('profiles')
        .select()
        .neq('role', 'student')
        .order('role')
        .order('full_name');
    return _rows(rows).map(AppUser.fromMap).toList();
  }

  /// Quản trị tạo tài khoản cán bộ (BCN khoa / trợ lý QT / CVHT) qua Edge Function.
  Future<String?> createStaff({
    required String username,
    required String fullName,
    required UserRole role,
    String? password,
    String? phone,
    String? email,
    required AppUser actor,
  }) async {
    try {
      final res = await _sb.functions.invoke('create-staff', body: {
        'username': username.trim(),
        'fullName': fullName.trim(),
        'role': role.key,
        if (password != null && password.isNotEmpty) 'password': password,
        'phone': phone?.trim(),
        'email': email?.trim(),
      });
      final data = res.data;
      if (data is Map && data['ok'] == true) {
        await addAudit(actor, 'Thêm tài khoản',
            '${role.label} · ${fullName.trim()} (${username.trim()})');
        return null;
      }
      if (data is Map && data['error'] is String) return data['error'] as String;
      return 'Không tạo được tài khoản.';
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['error'] is String) return d['error'] as String;
      return 'Chưa tạo được tài khoản: Edge Function create-staff chưa được '
          'deploy lên cloud.';
    }
  }

  /// Lấy hồ sơ của người dùng đang đăng nhập.
  Future<AppUser?> currentProfile() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return null;
    final row =
        await _sb.from('profiles').select().eq('id', uid).maybeSingle();
    return row == null ? null : AppUser.fromMap(Map<String, Object?>.from(row));
  }

  /// Người dùng tự cập nhật thông tin cá nhân (họ tên / liên hệ) của mình.
  Future<String?> updateOwnProfile(Map<String, Object?> fields) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return 'Chưa đăng nhập.';
    if (fields.isEmpty) return null;
    try {
      await _sb.from('profiles').update(fields).eq('id', uid);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  /// Tải ảnh đại diện (PNG đã thu nhỏ) của chính mình lên Storage và lưu
  /// đường dẫn vào hồ sơ. Trả về thông báo lỗi hoặc null nếu thành công.
  Future<String?> uploadOwnAvatar(Uint8List png) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return 'Chưa đăng nhập.';
    final path = '$uid/avatar.png';
    try {
      await _sb.storage.from('avatars').uploadBinary(
            path,
            png,
            fileOptions:
                const FileOptions(contentType: 'image/png', upsert: true),
          );
      // Thêm tham số phiên bản để ảnh mới không bị cache cũ che mất.
      final url = '${_sb.storage.from('avatars').getPublicUrl(path)}'
          '?v=${DateTime.now().millisecondsSinceEpoch}';
      return updateOwnProfile({'avatar_url': url});
    } on StorageException catch (e) {
      if (e.message.toLowerCase().contains('bucket not found')) {
        return 'Chưa có kho ảnh "avatars" trên Supabase – cần chạy migration '
            '20261007090007_avatars.sql.';
      }
      return 'Không tải được ảnh lên: ${e.message}';
    }
  }

  /// Xóa ảnh đại diện của chính mình.
  Future<String?> removeOwnAvatar() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return 'Chưa đăng nhập.';
    try {
      await _sb.storage.from('avatars').remove(['$uid/avatar.png']);
    } on StorageException catch (_) {
      // Ảnh không còn trên Storage thì vẫn xóa đường dẫn trong hồ sơ.
    }
    return updateOwnProfile({'avatar_url': null});
  }

  // ------------------------------------------------- quản lý tài khoản (admin)
  Future<String?> _studentUserId(String code) async {
    final row = await _sb
        .from('students')
        .select('user_id')
        .eq('student_code', code)
        .maybeSingle();
    return row?['user_id'] as String?;
  }

  /// Xóa tài khoản đăng nhập (auth user) qua Edge Function.
  Future<String?> deleteAuthUser({String? userId, String? studentCode}) async {
    try {
      final res = await _sb.functions.invoke('delete-user', body: {
        'userId': userId,
        'studentCode': studentCode,
      });
      final data = res.data;
      if (data is Map && data['ok'] == true) return null;
      if (data is Map && data['error'] is String) return data['error'] as String;
      return 'Không xóa được tài khoản.';
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['error'] is String) return d['error'] as String;
      return 'Edge Function delete-user chưa được deploy.';
    }
  }

  /// Khóa / mở khóa đăng nhập của một tài khoản (giữ nguyên dữ liệu).
  Future<String?> setProfileActive(
      String userId, bool active, AppUser actor) async {
    if (userId == actor.id) return 'Không thể tự khóa tài khoản của mình.';
    await _sb.from('profiles').update({'active': active}).eq('id', userId);
    await addAudit(actor, active ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
        'Tài khoản $userId ${active ? "được mở khóa" : "bị khóa"}');
    return null;
  }

  /// Khóa / mở khóa đăng nhập của sinh viên (giữ hồ sơ & điểm).
  Future<String?> setStudentLoginActive(
      Student s, bool active, AppUser actor) async {
    final uid = await _studentUserId(s.studentCode);
    if (uid == null) return 'Sinh viên chưa có tài khoản đăng nhập.';
    await _sb.from('profiles').update({'active': active}).eq('id', uid);
    await addAudit(actor, active ? 'Mở khóa đăng nhập' : 'Khóa đăng nhập',
        '${s.studentCode} · ${s.fullName}', studentCode: s.studentCode);
    return null;
  }

  /// Xóa hẳn tài khoản cán bộ (đăng nhập + hồ sơ).
  Future<String?> deleteFacultyAccount(AppUser u, AppUser actor) async {
    if (u.id == actor.id) return 'Không thể tự xóa tài khoản của mình.';
    await deleteAuthUser(userId: u.id); // best effort (service role)
    await _sb.from('profiles').delete().eq('id', u.id); // chặn đăng nhập
    await addAudit(actor, 'Xóa tài khoản',
        '${u.role.label} · ${u.fullName} (${u.username})');
    return null;
  }

  /// Xóa sinh viên: tài khoản đăng nhập (nếu có) + hồ sơ + điểm (cascade).
  Future<String?> deleteStudent(Student s, AppUser actor) async {
    final uid = await _studentUserId(s.studentCode);
    if (uid != null) {
      await deleteAuthUser(studentCode: s.studentCode);
      await _sb.from('profiles').delete().eq('id', uid);
    }
    await _sb.from('students').delete().eq('id', s.id);
    await addAudit(actor, 'Xóa sinh viên', '${s.studentCode} · ${s.fullName}',
        studentCode: s.studentCode);
    return null;
  }

  // -------------------------------------------------------------- settings
  Future<String> _get(String key, String fallback) async {
    final row =
        await _sb.from('settings').select('value').eq('key', key).maybeSingle();
    return (row?['value'] as String?) ?? fallback;
  }

  Future<void> _set(String key, String value) async {
    await _sb.from('settings').upsert({'key': key, 'value': value});
  }

  Future<String> currentTerm() => _get('current_term', defaultTerm);

  Future<void> setCurrentTerm(String term, AppUser actor) async {
    await _set('current_term', term);
    await addAudit(actor, 'Đổi kỳ hiện tại', 'Kỳ học hiện tại: $term');
  }

  // -------------------------------------------------------------- students
  Future<List<Student>> students({
    String? advisorId,
    String? search,
    String? cohort,
    String? status,
  }) async {
    final rows = await _fetchAll(() {
      var q = _sb.from('student_overview').select();
      if (advisorId != null) q = q.eq('advisor_id', advisorId);
      if (cohort != null && cohort.isNotEmpty) q = q.eq('cohort', cohort);
      if (status != null && status.isNotEmpty) q = q.eq('status', status);
      if (search != null && search.trim().isNotEmpty) {
        final s = search.trim();
        q = q.or('full_name.ilike.%$s%,student_code.ilike.%$s%');
      }
      return q.order('student_code');
    });
    return rows.map(Student.fromMap).toList();
  }

  Future<Student?> studentByCode(String code) async {
    final row = await _sb
        .from('student_overview')
        .select()
        .eq('student_code', code)
        .maybeSingle();
    return row == null ? null : Student.fromMap(Map<String, Object?>.from(row));
  }

  /// Danh sách cố vấn học tập để phân công cho sinh viên.
  Future<List<AppUser>> advisors() async {
    final rows = await _sb
        .from('profiles')
        .select()
        .eq('role', 'advisor')
        .eq('active', true)
        .order('full_name');
    return _rows(rows).map(AppUser.fromMap).toList();
  }

  /// Các lớp đã có, dùng để gợi ý khi thêm sinh viên mới.
  Future<List<String>> classNames() async {
    final rows = await _fetchAll(
        () => _sb.from('students').select('class_name').order('id'));
    final set = <String>{
      for (final r in rows)
        if (r['class_name'] != null) r['class_name'] as String
    };
    return set.toList()..sort();
  }

  /// Sinh mã số sinh viên kế tiếp cho một năm nhập học, theo dạng của trường:
  /// 2 số cuối năm + '01' + số thứ tự 4 chữ số (vd 26011102).
  Future<String> suggestStudentCode(int enrollYear) async {
    final prefix = '${(enrollYear % 100).toString().padLeft(2, '0')}01';
    final rows = await _sb
        .from('students')
        .select('student_code')
        .like('student_code', '$prefix%')
        .order('student_code', ascending: false)
        .limit(1);
    var seq = 1;
    if (rows.isNotEmpty) {
      final last = rows.first['student_code'] as String;
      final tail = last.length >= 4 ? last.substring(last.length - 4) : last;
      seq = (int.tryParse(tail) ?? 0) + 1;
    }
    return '$prefix${seq.toString().padLeft(4, '0')}';
  }

  /// Tiền tố báo "đã tạo hồ sơ nhưng chưa tạo được tài khoản đăng nhập".
  static const warnNoAccountPrefix = '__WARN__';

  /// Thêm sinh viên mới. Khi [createAccount] = true, gọi Edge Function
  /// `create-student` (service role) để tạo luôn tài khoản đăng nhập. Nếu
  /// function chưa deploy / không gọi được, vẫn tạo hồ sơ và trả về cảnh báo
  /// (chuỗi bắt đầu bằng [warnNoAccountPrefix]); ngược lại chỉ chèn hồ sơ.
  Future<String?> addStudent({
    required String studentCode,
    required String fullName,
    required String cohort,
    required String className,
    required int enrollYear,
    String? advisorId,
    int? direction,
    String? phone,
    String? birthDate,
    String? hometown,
    String? email,
    required AppUser actor,
    bool createAccount = true,
  }) async {
    final code = studentCode.trim();
    if (code.isEmpty) return 'Vui lòng nhập mã số sinh viên.';

    if (createAccount) {
      try {
        final res = await _sb.functions.invoke('create-student', body: {
          'studentCode': code,
          'fullName': fullName.trim(),
          'cohort': cohort.trim(),
          'className': className.trim(),
          'enrollYear': enrollYear,
          'advisorId': advisorId,
          'direction': direction,
          'phone': phone?.trim(),
          'birthDate': birthDate?.trim(),
          'hometown': hometown?.trim(),
          'email': email?.trim(),
        });
        final data = res.data;
        if (data is Map && data['ok'] == true) {
          await addAudit(actor, 'Thêm sinh viên',
              '$code · ${fullName.trim()} ($cohort · $className)',
              studentCode: code);
          return null;
        }
        // Lỗi nghiệp vụ do function trả về (vd trùng mã) -> báo thẳng.
        if (data is Map && data['error'] is String) return data['error'] as String;
        return 'Không tạo được sinh viên.';
      } on FunctionException catch (e) {
        final d = e.details;
        if (d is Map && d['error'] is String) return d['error'] as String;
        // Function chưa deploy / không gọi được -> tạo hồ sơ, kèm cảnh báo.
        final err = await _insertStudentRecord(
          code: code,
          fullName: fullName,
          cohort: cohort,
          className: className,
          enrollYear: enrollYear,
          advisorId: advisorId,
          direction: direction,
          phone: phone,
          birthDate: birthDate,
          hometown: hometown,
          email: email,
          actor: actor,
        );
        if (err != null) return err;
        return '$warnNoAccountPrefixĐã thêm hồ sơ sinh viên nhưng CHƯA tạo'
            ' được tài khoản đăng nhập (Edge Function create-student chưa được'
            ' deploy). Hãy deploy rồi tạo tài khoản sau.';
      }
    }

    return _insertStudentRecord(
      code: code,
      fullName: fullName,
      cohort: cohort,
      className: className,
      enrollYear: enrollYear,
      advisorId: advisorId,
      direction: direction,
      phone: phone,
      birthDate: birthDate,
      hometown: hometown,
      email: email,
      actor: actor,
    );
  }

  Future<String?> _insertStudentRecord({
    required String code,
    required String fullName,
    required String cohort,
    required String className,
    required int enrollYear,
    String? advisorId,
    int? direction,
    String? phone,
    String? birthDate,
    String? hometown,
    String? email,
    required AppUser actor,
  }) async {
    final dup = await _sb
        .from('students')
        .select('id')
        .eq('student_code', code)
        .maybeSingle();
    if (dup != null) return 'Mã số sinh viên đã tồn tại.';

    await _sb.from('students').insert({
      'student_code': code,
      'full_name': fullName.trim(),
      'cohort': cohort.trim(),
      'class_name': className.trim(),
      'major': CurriculumSeed.major,
      'enroll_year': enrollYear,
      'advisor_id': advisorId,
      'direction': direction,
      'status': 'active',
      'phone': phone?.trim(),
      'birth_date': birthDate?.trim(),
      'hometown': hometown?.trim(),
      'email': email?.trim(),
    });
    await addAudit(actor, 'Thêm sinh viên',
        '$code · ${fullName.trim()} ($cohort · $className)',
        studentCode: code);
    return null;
  }

  /// Cập nhật trực tiếp hồ sơ sinh viên (quản trị, hoặc sinh viên sửa hồ sơ
  /// của chính mình). [fields] là map cột → giá trị mới.
  Future<void> updateStudentProfile({
    required Student student,
    required Map<String, Object?> fields,
    required AppUser actor,
  }) async {
    if (fields.isEmpty) return;
    await _sb.from('students').update(fields).eq('id', student.id);
    await addAudit(actor, 'Cập nhật hồ sơ',
        'Cập nhật thông tin sinh viên ${student.studentCode}',
        studentCode: student.studentCode);
  }

  /// Trợ lý quản trị đề xuất sửa hồ sơ – lưu vào hàng chờ quản trị phê duyệt.
  Future<void> requestProfileChanges({
    required Student student,
    required List<ProfileChange> changes,
    required AppUser actor,
  }) async {
    if (changes.isEmpty) return;
    await _sb.from('change_requests').insert([
      for (final ch in changes)
        {
          'student_id': student.id,
          'student_code': student.studentCode,
          'field': ch.field,
          'field_label': ch.label,
          'old_value': ch.oldValue,
          'new_value': ch.newValue,
          'requested_by': actor.id,
          'requested_role': actor.role.key,
        }
    ]);
    await addAudit(actor, 'Đề xuất sửa hồ sơ',
        'Đề xuất cập nhật ${changes.length} thông tin của '
            '${student.studentCode} (chờ quản trị duyệt)',
        studentCode: student.studentCode);
  }

  Future<List<ChangeRequest>> pendingChangeRequests() async {
    final rows = await _sb
        .from('change_requests')
        .select('*, students(full_name)')
        .eq('status', 'pending')
        .order('id', ascending: false);
    return rows.map((r) {
      final m = Map<String, Object?>.from(r as Map);
      final st = r['students'];
      m['student_name'] = st is Map ? st['full_name'] : null;
      return ChangeRequest.fromMap(m);
    }).toList();
  }

  Future<int> pendingChangeCount() async {
    final rows =
        await _sb.from('change_requests').select('id').eq('status', 'pending');
    return rows.length;
  }

  Future<void> decideChangeRequest({
    required ChangeRequest req,
    required bool approve,
    required AppUser actor,
  }) async {
    await _sb
        .from('change_requests')
        .update({'status': approve ? 'approved' : 'rejected'}).eq('id', req.id);
    if (approve) {
      await _sb
          .from('students')
          .update({req.field: req.newValue}).eq('id', req.studentId);
    }
    await addAudit(
      actor,
      approve ? 'Duyệt sửa hồ sơ' : 'Từ chối sửa hồ sơ',
      '${approve ? "Duyệt" : "Từ chối"} cập nhật ${req.fieldLabel} của '
          '${req.studentCode}',
      studentCode: req.studentCode,
    );
  }

  // --------------------------------------------------------------- courses
  List<Course>? _courseCache;
  Future<List<Course>> courses() async {
    if (_courseCache != null) return _courseCache!;
    final rows = await _sb
        .from('courses')
        .select()
        .order('block')
        .order('mandatory', ascending: false)
        .order('planned_semester')
        .order('code');
    _courseCache = _rows(rows).map(Course.fromMap).toList();
    return _courseCache!;
  }

  Future<Map<int, Course>> coursesById() async {
    final list = await courses();
    return {for (final c in list) c.id: c};
  }

  Future<void> addCourse(Course c, AppUser actor) async {
    await _sb.from('courses').insert(c.toMap());
    _courseCache = null;
    await addAudit(
        actor, 'Thêm học phần', '${c.code} · ${c.name} (${c.credits} TC)');
  }

  Future<void> updateCourse(int id, Course c, AppUser actor) async {
    await _sb.from('courses').update(c.toMap()).eq('id', id);
    _courseCache = null;
    await addAudit(actor, 'Sửa học phần', '${c.code} · ${c.name}');
  }

  Future<String?> deleteCourse(Course c, AppUser actor) async {
    final used = await _sb
        .from('enrollments')
        .select('id')
        .eq('course_id', c.id)
        .limit(1);
    if (used.isNotEmpty) {
      return 'Không thể xóa: đã có sinh viên đăng ký/học học phần này.';
    }
    await _sb.from('courses').delete().eq('id', c.id);
    _courseCache = null;
    await addAudit(actor, 'Xóa học phần', '${c.code} · ${c.name}');
    return null;
  }

  // ----------------------------------------------------------- enrollments
  Future<List<Enrollment>> enrollmentsForStudent(int studentId) async {
    final byId = await coursesById();
    final rows =
        await _sb.from('enrollments').select().eq('student_id', studentId);
    final list = _rows(rows)
        .map((r) => Enrollment.fromMap(r,
            course: byId[(r['course_id'] as num).toInt()]))
        .toList();
    list.sort((a, b) {
      final t = a.term.compareTo(b.term);
      if (t != 0) return t;
      return (a.course?.code ?? '').compareTo(b.course?.code ?? '');
    });
    return list;
  }

  // ------------------------------------------------- tự khai báo học tập
  // Sinh viên chỉ nhập điểm học phần hệ 10 [grade10] (null = đang học). Máy
  // chủ (trigger apply_grade) lưu nó vào grade10 và tính điểm chữ, hệ 4, trạng
  // thái. Cột midterm luôn để trống: không còn nhập điểm thành phần.

  /// Sinh viên tự khai báo đã/đang học [course] ở [term], kèm điểm nếu có.
  /// Không cần duyệt; điểm chữ, hệ 4 và trạng thái do máy chủ tính.
  Future<String?> declareCourse({
    required Student student,
    required Course course,
    required String term,
    double? grade10,
    required AppUser actor,
  }) async {
    try {
      await _sb.from('enrollments').insert({
        'student_id': student.id,
        'course_id': course.id,
        'term': term,
        'status': 'studying',
        'approval': 'approved',
        'midterm': null,
        'final_exam': _grade(grade10),
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        return 'Học phần ${course.code} đã được khai báo ở kỳ $term.';
      }
      return 'Không lưu được: ${e.message}';
    }
    await addAudit(actor, 'Khai báo học phần',
        '${course.code} · ${course.name} (kỳ $term)${_gradeText(grade10)}',
        studentCode: student.studentCode);
    return null;
  }

  /// Sửa kỳ học và/hoặc điểm của một học phần đã khai báo.
  Future<String?> updateDeclaration({
    required Enrollment e,
    required String term,
    double? grade10,
    required AppUser actor,
    String? studentCode,
  }) async {
    try {
      await _sb.from('enrollments').update({
        'term': term,
        'midterm': null,
        'final_exam': _grade(grade10),
      }).eq('id', e.id);
    } on PostgrestException catch (err) {
      if (err.code == '23505') {
        return 'Học phần ${e.course?.code ?? ''} đã được khai báo ở kỳ $term.';
      }
      return 'Không lưu được: ${err.message}';
    }
    await addAudit(actor, 'Sửa khai báo học phần',
        '${e.course?.code ?? ''} (kỳ $term)${_gradeText(grade10)}',
        studentCode: studentCode);
    return null;
  }

  Future<void> deleteDeclaration(Enrollment e, AppUser actor,
      {String? studentCode}) async {
    await _sb.from('enrollments').delete().eq('id', e.id);
    await addAudit(actor, 'Xóa khai báo học phần',
        '${e.course?.code ?? ''} (kỳ ${e.term})',
        studentCode: studentCode);
  }

  static double? _grade(double? v) =>
      v == null ? null : double.parse(v.toStringAsFixed(1));

  static String _gradeText(double? grade10) {
    if (grade10 == null) return '';
    final g = _grade(grade10)!;
    return ' · điểm ${g.toStringAsFixed(1)} (${GradeScale.letter(g)})';
  }

  // -------------------------------------------------------------- audit
  Future<void> addAudit(AppUser actor, String action, String detail,
      {String? studentCode}) async {
    await _sb.from('audit_log').insert({
      'actor_id': actor.id,
      'actor_name': actor.fullName,
      'role': actor.role.key,
      'action': action,
      'detail': detail,
      'student_code': studentCode,
    });
  }

  Future<List<AuditEntry>> recentAudit(
      {String? studentCode, int limit = 60}) async {
    var q = _sb.from('audit_log').select();
    if (studentCode != null) q = q.eq('student_code', studentCode);
    final rows = await q.order('id', ascending: false).limit(limit);
    return _rows(rows).map(AuditEntry.fromMap).toList();
  }

  // ------------------------------------------------------------ statistics
  /// Kết quả [studentsWithProgress] theo phạm vi cố vấn, dùng chung giữa các
  /// màn hình (Tổng quan, Sinh viên, Cảnh báo, Báo cáo) cho tới lần
  /// [invalidateCaches] kế tiếp.
  final Map<String?, Future<List<StudentWithProgress>>> _progressCache = {};

  Future<List<StudentWithProgress>> studentsWithProgress({
    String? advisorId,
    String? search,
    String? cohort,
  }) {
    final cacheable = (search == null || search.trim().isEmpty) &&
        (cohort == null || cohort.isEmpty);
    if (!cacheable) {
      return _loadProgress(
          advisorId: advisorId, search: search, cohort: cohort);
    }
    final future = _progressCache[advisorId] ??=
        _loadProgress(advisorId: advisorId);
    // Không giữ lại lỗi (vd mất mạng) để lần sau thử tải lại.
    future.catchError((Object _) {
      if (identical(_progressCache[advisorId], future)) {
        _progressCache.remove(advisorId);
      }
      return const <StudentWithProgress>[];
    });
    return future;
  }

  Future<List<StudentWithProgress>> _loadProgress({
    String? advisorId,
    String? search,
    String? cohort,
  }) async {
    final studs =
        await students(advisorId: advisorId, search: search, cohort: cohort);
    if (studs.isEmpty) return [];
    final courseList = await courses();
    final term = await currentTerm();
    final byId = {for (final c in courseList) c.id: c};

    // Lọc theo từng nhóm id để URL không quá dài, mỗi nhóm đọc theo trang.
    const chunk = 200;
    final ids = studs.map((s) => s.id).toList();
    final byStudent = <int, List<Enrollment>>{};
    for (var i = 0; i < ids.length; i += chunk) {
      final part = ids.sublist(i, (i + chunk).clamp(0, ids.length));
      final rows = await _fetchAll(() => _sb
          .from('enrollments')
          .select()
          .inFilter('student_id', part)
          .order('id'));
      for (final raw in rows) {
        final e = Enrollment.fromMap(raw,
            course: byId[(raw['course_id'] as num).toInt()]);
        byStudent.putIfAbsent(e.studentId, () => []).add(e);
      }
    }
    return studs
        .map((s) => StudentWithProgress(s,
            AcademicService.compute(s, byStudent[s.id] ?? const [], courseList,
                term: term)))
        .toList();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository.dart';
import '../models/user.dart';

/// Holds the authenticated session, shared services and a global "data
/// revision" used to keep every open screen in sync across roles.
class AppState extends ChangeNotifier {
  /// [repo] chỉ truyền khi kiểm thử (repository giả).
  AppState(SupabaseClient sb, {Repository? repo})
    : repo = repo ?? Repository(sb) {
    // Phiên bị thu hồi ở nơi khác (đổi mật khẩu, token hết hạn...) thì quay
    // về màn đăng nhập.
    _authSub = this.repo.authChanges.listen((s) {
      if (s.event == AuthChangeEvent.signedOut && _user != null) {
        _user = null;
        this.repo.invalidateCaches();
        notifyListeners();
      }
    });
  }

  final Repository repo;
  StreamSubscription<AuthState>? _authSub;

  static const _kRemember = 'remember_login';
  static const _kLastUsername = 'last_username';

  /// Đang khôi phục phiên đã ghi nhớ khi mở app.
  bool _restoring = true;
  bool get restoring => _restoring;

  /// Lựa chọn "Ghi nhớ đăng nhập" lần trước (mặc định bật).
  bool rememberLogin = true;

  /// Tên đăng nhập lần trước, điền sẵn ở màn đăng nhập.
  String lastUsername = '';

  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Cố vấn học tập chỉ xem sinh viên mình phụ trách; vai trò khác xem tất cả.
  String? get advisorScope =>
      _user?.role == UserRole.advisor ? _user!.id : null;

  String? _loginError;
  String? get loginError => _loginError;
  bool _busy = false;
  bool get busy => _busy;

  /// Bumped whenever any user changes data anywhere in the app.
  int _dataRevision = 0;
  int get dataRevision => _dataRevision;
  DateTime lastSync = DateTime.now();

  /// Kỳ học hiện tại do quản trị đặt; quyết định sinh viên năm thứ mấy.
  String currentTerm = Repository.defaultTerm;

  /// Gọi một lần khi mở app: nếu người dùng đã chọn ghi nhớ và phiên trên
  /// máy còn hiệu lực thì vào thẳng ứng dụng, không cần nhập lại mật khẩu.
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      rememberLogin = prefs.getBool(_kRemember) ?? true;
      lastUsername = prefs.getString(_kLastUsername) ?? '';
      if (!repo.hasSession) return;
      if (!rememberLogin) {
        await repo.signOut();
        return;
      }
      final u = await repo.currentProfile();
      if (u == null || !u.active) {
        await repo.signOut();
        if (u != null) {
          _loginError = 'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị.';
        }
        return;
      }
      _user = u;
      await refreshSettings();
    } catch (_) {
      // Mất mạng: giữ phiên để lần sau thử lại, tạm thời đăng nhập thủ công.
      _loginError = 'Không kết nối được máy chủ để khôi phục phiên đăng nhập.';
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<bool> login(
    String username,
    String password, {
    bool remember = true,
  }) async {
    _busy = true;
    _loginError = null;
    notifyListeners();
    try {
      final u = await repo.login(username, password);
      if (u == null) {
        _loginError = 'Sai tên đăng nhập hoặc mật khẩu.';
        return false;
      }
      _user = u;
      rememberLogin = remember;
      lastUsername = username.trim();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kRemember, remember);
        await prefs.setString(_kLastUsername, lastUsername);
      } catch (_) {
        // Không ghi được tùy chọn thì vẫn đăng nhập bình thường.
      }
      await refreshSettings();
      return true;
    } catch (e) {
      _loginError = switch (e) {
        AccountLockedException() =>
          'Tài khoản đã bị khóa. Vui lòng liên hệ quản trị.',
        LoginRateLimitedException() =>
          'Đăng nhập quá nhiều lần trong thời gian ngắn (có thể do nhiều '
              'người dùng chung mạng). Vui lòng thử lại sau vài phút.',
        MissingProfileException() =>
          'Tài khoản chưa có hồ sơ trên hệ thống. Vui lòng liên hệ quản trị.',
        LoginServerException(:final message) =>
          'Máy chủ đăng nhập báo lỗi: $message',
        _ => 'Không kết nối được máy chủ. Kiểm tra mạng hoặc trạng thái '
            'project Supabase (có thể đang tạm dừng).',
      };
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshSettings() async {
    currentTerm = await repo.currentTerm();
  }

  /// Người dùng tự cập nhật thông tin cá nhân; làm mới phiên để UI đổi theo.
  Future<String?> updateMyProfile(Map<String, Object?> fields) async {
    final err = await repo.updateOwnProfile(fields);
    if (err != null) return err;
    final u = await repo.currentProfile();
    if (u != null) _user = u;
    notifyListeners();
    return null;
  }

  /// Đổi / xóa ảnh đại diện của chính mình ([png] = null để xóa).
  Future<String?> setMyAvatar(Uint8List? png) async {
    final err = png == null
        ? await repo.removeOwnAvatar()
        : await repo.uploadOwnAvatar(png);
    if (err != null) return err;
    final u = await repo.currentProfile();
    if (u != null) _user = u;
    await bumpData(); // danh sách / hồ sơ sinh viên hiển thị ảnh mới
    return null;
  }

  /// Signal that shared data changed – all listening screens will reload.
  Future<void> bumpData() async {
    repo.invalidateCaches();
    await refreshSettings();
    _dataRevision++;
    lastSync = DateTime.now();
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null; // trước signOut để listener không xử lý lần nữa
    await repo.signOut();
    repo.invalidateCaches();
    _loginError = null;
    notifyListeners();
  }

  /// Đặt người dùng trực tiếp, chỉ dùng trong kiểm thử giao diện.
  @visibleForTesting
  void debugSetUser(AppUser u) {
    _user = u;
    _restoring = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

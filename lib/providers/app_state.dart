import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository.dart';
import '../models/user.dart';

/// Holds the authenticated session, shared services and a global "data
/// revision" used to keep every open screen in sync across roles.
class AppState extends ChangeNotifier {
  AppState(SupabaseClient sb) : repo = Repository(sb);

  final Repository repo;

  AppUser? _user;
  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;

  String? _loginError;
  String? get loginError => _loginError;
  bool _busy = false;
  bool get busy => _busy;

  /// Bumped whenever any user changes data anywhere in the app.
  int _dataRevision = 0;
  int get dataRevision => _dataRevision;
  DateTime lastSync = DateTime.now();

  String currentTerm = Repository.defaultTerm;
  bool regOpen = false;

  Future<bool> login(String username, String password) async {
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
      await refreshSettings();
      return true;
    } catch (e) {
      _loginError = 'Không kết nối được máy chủ. Kiểm tra mạng hoặc trạng thái '
          'project Supabase (có thể đang tạm dừng).';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshSettings() async {
    currentTerm = await repo.currentTerm();
    regOpen = await repo.regOpen();
  }

  /// Signal that shared data changed – all listening screens will reload.
  Future<void> bumpData() async {
    await refreshSettings();
    _dataRevision++;
    lastSync = DateTime.now();
    notifyListeners();
  }

  Future<void> logout() async {
    await repo.signOut();
    _user = null;
    _loginError = null;
    notifyListeners();
  }
}

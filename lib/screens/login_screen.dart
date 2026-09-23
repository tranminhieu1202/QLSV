import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _demoStudent;

  @override
  void initState() {
    super.initState();
    _loadDemoStudent();
  }

  Future<void> _loadDemoStudent() async {
    final code = await context.read<AppState>().repo.demoStudentCode();
    if (mounted) setState(() => _demoStudent = code);
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() =>
      context.read<AppState>().login(_userCtrl.text, _passCtrl.text);

  void _fill(String u) {
    _userCtrl.text = u;
    _passCtrl.text = '123456';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          // On small / short screens show only the login form so the
          // branding panel never forces a vertical overflow.
          final showBranding = c.maxWidth >= 900;
          if (!showBranding) {
            return _formPanel(scrollable: true);
          }
          return Row(
            children: [
              Expanded(flex: 5, child: _brandingPanel()),
              Expanded(flex: 4, child: _formPanel(scrollable: true)),
            ],
          );
        },
      ),
    );
  }

  Widget _brandingPanel() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, color: Colors.white, size: 72),
              const SizedBox(height: 24),
              const Text(
                'HỆ THỐNG QUẢN LÝ ĐÀO TẠO',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    height: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                'Trường Đại học Giáo dục · Ngành Quản trị trường học\n'
                'Theo dõi tiến trình đào tạo 4 năm – 8 học kỳ',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                    height: 1.5),
              ),
              const SizedBox(height: 40),
              _feature(Icons.timeline, 'Chương trình & tiến trình đào tạo'),
              _feature(Icons.app_registration, 'Đăng ký học phần & gợi ý'),
              _feature(Icons.warning_amber, 'Cảnh báo tín chỉ & học tập'),
              _feature(Icons.sync, 'Đồng bộ Quản trị – BCN Khoa – CVHT – Sinh viên'),
            ],
          ),
        ),
      );

  Widget _formPanel({required bool scrollable}) {
    final state = context.watch<AppState>();
    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Đăng nhập',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Vui lòng nhập tài khoản được cấp.',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 28),
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (state.loginError != null) ...[
              const SizedBox(height: 12),
              Text(state.loginError!,
                  style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: state.busy ? null : _submit,
                child: state.busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('ĐĂNG NHẬP',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 12),
            const Text('Tài khoản demo (mật khẩu: 123456)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _demoChip('admin', 'Quản trị'),
                _demoChip('dean', 'BCN Khoa'),
                _demoChip('assistant', 'Trợ lý QT'),
                _demoChip('advisor1', 'CVHT'),
                if (_demoStudent != null)
                  _demoChip(_demoStudent!, 'Sinh viên'),
              ],
            ),
          ],
        ),
      ),
    );
    return Center(
      child: scrollable ? SingleChildScrollView(child: form) : form,
    );
  }

  Widget _feature(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ],
        ),
      );

  Widget _demoChip(String username, String label) => ActionChip(
        avatar: const Icon(Icons.login, size: 16),
        label: Text('$label · $username'),
        onPressed: () => _fill(username),
      );
}

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
  late bool _remember;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _remember = state.rememberLogin;
    _userCtrl.text = state.lastUsername;
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() => context
      .read<AppState>()
      .login(_userCtrl.text, _passCtrl.text, remember: _remember);

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
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset('assets/images/logo.png',
                    width: 96, height: 96),
              ),
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
              _feature(Icons.edit_note, 'Sinh viên tự khai báo học phần & điểm'),
              _feature(Icons.warning_amber, 'Cảnh báo học vụ theo quy chế ĐHQGHN'),
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
              autofocus: _userCtrl.text.isEmpty,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                prefixIcon: Icon(Icons.person_outline),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              autofocus: _userCtrl.text.isNotEmpty,
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
            const SizedBox(height: 4),
            CheckboxListTile(
              value: _remember,
              onChanged: (v) => setState(() => _remember = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Ghi nhớ đăng nhập trên máy này'),
              subtitle: const Text(
                  'Lần sau mở ứng dụng không cần nhập lại. Bỏ chọn nếu dùng '
                  'máy chung.',
                  style: TextStyle(fontSize: 12)),
            ),
            if (state.loginError != null) ...[
              const SizedBox(height: 12),
              Text(state.loginError!,
                  style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: 16),
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
}

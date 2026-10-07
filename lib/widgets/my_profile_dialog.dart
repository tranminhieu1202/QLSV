import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'user_avatar.dart';

/// Cho tài khoản đang đăng nhập tự đổi ảnh đại diện và sửa thông tin cá nhân
/// (họ tên + liên hệ). Sinh viên sửa hồ sơ ở Cổng sinh viên nên chỉ đổi ảnh.
class MyProfileDialog extends StatefulWidget {
  const MyProfileDialog({super.key});

  @override
  State<MyProfileDialog> createState() => _MyProfileDialogState();
}

class _MyProfileDialogState extends State<MyProfileDialog> {
  late final AppState _state = context.read<AppState>();
  late final _name = TextEditingController(text: _state.user?.fullName ?? '');
  late final _phone = TextEditingController(text: _state.user?.phone ?? '');
  late final _email = TextEditingController(text: _state.user?.email ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Họ tên không được để trống.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await _state.updateMyProfile({
      'full_name': name,
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
    });
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.ok,
        content: Text('Đã cập nhật thông tin cá nhân.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = _state.user;
    final isStudent = u != null && !u.role.isFaculty;
    return AlertDialog(
      title: const Text('Thông tin cá nhân'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (u != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Tài khoản: ${u.username} · ${u.role.label}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
            const AvatarEditor(),
            const Divider(height: 28),
            if (isStudent)
              const Text(
                'Họ tên, ngày sinh, liên hệ… của sinh viên được sửa ở mục '
                '"Sửa hồ sơ" trong Cổng sinh viên.',
                style: TextStyle(color: AppColors.textMuted),
              )
            else ...[
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email cá nhân'),
                onSubmitted: (_) => _save(),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(isStudent ? 'Đóng' : 'Hủy'),
        ),
        if (!isStudent)
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
      ],
    );
  }
}

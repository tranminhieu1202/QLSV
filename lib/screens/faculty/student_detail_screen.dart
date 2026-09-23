import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/student.dart';
import '../../models/user.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_edit_dialog.dart';
import '../../widgets/student_progress_view.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key, required this.student});
  final Student student;

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Student _student = widget.student;

  Future<void> _reload() async {
    final s = await context
        .read<AppState>()
        .repo
        .studentByCode(_student.studentCode);
    if (mounted && s != null) setState(() => _student = s);
  }

  Future<void> _editInfo() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ProfileEditDialog(student: _student),
    );
    if (saved == true && mounted) {
      await context.read<AppState>().bumpData();
      await _reload();
    }
  }

  Future<void> _resetPassword() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đặt lại mật khẩu?'),
        content: Text('Mật khẩu của ${_student.studentCode} sẽ được '
            'đặt lại về “123456”.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Đặt lại')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final state = context.read<AppState>();
    final err = await state.repo
        .resetStudentPassword(student: _student, actor: state.user!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: err == null ? AppColors.ok : AppColors.danger,
      content: Text(err ?? 'Đã đặt lại mật khẩu về “123456”.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = _student;
    final role = context.read<AppState>().user!.role;
    final canEdit = role.canEditStudentInfo;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hồ sơ SV · ${s.studentCode}'),
        actions: [
          if (role.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: _resetPassword,
                icon: const Icon(Icons.lock_reset, color: Colors.white),
                label: const Text('Đặt lại MK',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          if (canEdit)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _editInfo,
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text('Sửa thông tin',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(s),
            const SizedBox(height: 16),
            Expanded(
              child: StudentProgressView(
                student: s,
                canEditGrades: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(Student s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary,
              child: Text(
                s.fullName.characters.last,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.fullName,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      _info('MSSV', s.studentCode),
                      _info('Lớp', s.className),
                      _info('Khóa', s.cohort),
                      _info('Ngành', s.major),
                      _info('CVHT', s.advisorName ?? '-'),
                      _info('Ngày sinh', s.birthDate ?? '-'),
                      _info('Số điện thoại', s.phone ?? '-'),
                      _info('Quê quán', s.hometown ?? '-'),
                      _info('Email cá nhân', s.email ?? '-'),
                      _info('Trạng thái', _statusLabel(s.status)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );

  String _statusLabel(String s) {
    switch (s) {
      case 'graduated':
        return 'Đã tốt nghiệp';
      case 'suspended':
        return 'Đình chỉ';
      default:
        return 'Đang học';
    }
  }
}

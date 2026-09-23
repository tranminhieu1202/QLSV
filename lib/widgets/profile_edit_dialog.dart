import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/student.dart';
import '../models/user.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

/// Editable profile fields shared by the student portal and faculty detail.
const _editableFields = <(String, String)>[
  ('phone', 'Số điện thoại'),
  ('birth_date', 'Ngày sinh'),
  ('hometown', 'Quê quán'),
  ('email', 'Email cá nhân'),
];

String? _currentValue(Student s, String field) {
  switch (field) {
    case 'phone':
      return s.phone;
    case 'birth_date':
      return s.birthDate;
    case 'hometown':
      return s.hometown;
    case 'email':
      return s.email;
  }
  return null;
}

/// Dialog for editing a student's personal contact fields.
///
/// When the actor is a role whose changes need approval (trợ lý quản trị), the
/// edits are queued for admin approval instead of being applied immediately.
class ProfileEditDialog extends StatefulWidget {
  const ProfileEditDialog({super.key, required this.student});
  final Student student;

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  late final Map<String, TextEditingController> _ctrls = {
    for (final f in _editableFields)
      f.$1: TextEditingController(text: _currentValue(widget.student, f.$1))
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final actor = state.user!;
    final changes = <ProfileChange>[];
    final direct = <String, Object?>{};
    for (final f in _editableFields) {
      final old = _currentValue(widget.student, f.$1)?.trim() ?? '';
      final now = _ctrls[f.$1]!.text.trim();
      if (old == now) continue;
      changes.add(ProfileChange(f.$1, f.$2, old.isEmpty ? null : old,
          now.isEmpty ? null : now));
      direct[f.$1] = now.isEmpty ? null : now;
    }
    if (changes.isEmpty) {
      Navigator.pop(context, false);
      return;
    }
    setState(() => _saving = true);
    final needsApproval = actor.role.changesNeedApproval;
    if (needsApproval) {
      await state.repo.requestProfileChanges(
          student: widget.student, changes: changes, actor: actor);
    } else {
      await state.repo.updateStudentProfile(
          student: widget.student, fields: direct, actor: actor);
    }
    if (!mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.ok,
      content: Text(needsApproval
          ? 'Đã gửi đề xuất sửa hồ sơ – chờ quản trị phê duyệt.'
          : 'Đã cập nhật hồ sơ.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final needsApproval =
        context.read<AppState>().user!.role.changesNeedApproval;
    return AlertDialog(
      title: const Text('Chỉnh sửa thông tin cá nhân'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final f in _editableFields) ...[
                TextField(
                  controller: _ctrls[f.$1],
                  keyboardType: f.$1 == 'phone'
                      ? TextInputType.phone
                      : f.$1 == 'email'
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                  decoration: InputDecoration(
                    labelText: f.$2,
                    hintText: f.$1 == 'birth_date' ? 'vd 20/09/2004' : null,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (needsApproval)
                const Text(
                  'Thay đổi của trợ lý quản trị cần được quản trị phê duyệt '
                  'trước khi có hiệu lực.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(needsApproval ? 'Gửi đề xuất' : 'Lưu'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/student.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_edit_dialog.dart';
import '../../widgets/student_progress_view.dart';

class StudentPortalScreen extends StatefulWidget {
  const StudentPortalScreen({super.key, required this.studentCode});
  final String studentCode;

  @override
  State<StudentPortalScreen> createState() => _StudentPortalScreenState();
}

class _StudentPortalScreenState extends State<StudentPortalScreen> {
  Student? _student;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<AppState>().repo;
    final s = await repo.studentByCode(widget.studentCode);
    if (!mounted) return;
    setState(() {
      _student = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rev = context.watch<AppState>().dataRevision;
    if (_loading) return const Center(child: CircularProgressIndicator());
    final s = _student;
    if (s == null) {
      return const Center(child: Text('Không tìm thấy hồ sơ sinh viên.'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(s),
        const SizedBox(height: 16),
        Expanded(
          child: StudentProgressView(
              key: ValueKey('progress-$rev'),
              student: s,
              canEditGrades: true),
        ),
      ],
    );
  }

  Future<void> _editProfile(Student s) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ProfileEditDialog(student: s),
    );
    if (saved == true && mounted) {
      await context.read<AppState>().bumpData();
      await _load();
    }
  }

  Widget _header(Student s) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              child: Text(s.fullName.characters.last,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.fullName} · ${s.studentCode}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      _info('Lớp', s.className),
                      _info('Khóa', s.cohort),
                      _info('Ngành', s.major),
                      _info('Cố vấn học tập', s.advisorName ?? '-'),
                      _info('Ngày sinh', s.birthDate ?? '-'),
                      _info('Số điện thoại', s.phone ?? '-'),
                      _info('Quê quán', s.hometown ?? '-'),
                      _info('Email cá nhân', s.email ?? '-'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _editProfile(s),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Sửa hồ sơ'),
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
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/user.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/revision_reload.dart';

/// Nhật ký hoạt động – thể hiện việc đồng bộ dữ liệu giữa các vai trò.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with RevisionReload {
  List<AuditEntry> _items = [];
  bool _loading = true;

  Future<void> _load() async {
    final state = context.read<AppState>();
    final code =
        state.user!.role == UserRole.student ? state.user!.studentCode : null;
    final items = await state.repo.recentAudit(studentCode: code);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    watchRevision(_load);
    final state = context.watch<AppState>();
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Nhật ký hoạt động & đồng bộ',
          subtitle:
              'Đồng bộ lần cuối: ${DateFormat('HH:mm:ss dd/MM/yyyy').format(state.lastSync)}',
          trailing: OutlinedButton.icon(
            onPressed: () => state.bumpData(),
            icon: const Icon(Icons.sync),
            label: const Text('Đồng bộ ngay'),
          ),
        ),
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('Chưa có hoạt động nào.'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _tile(_items[i]),
                ),
        ),
      ],
    );
  }

  Widget _tile(AuditEntry e) {
    final role = UserRoleX.fromKey(e.role);
    final icon = _iconFor(e.action);
    DateTime? ts;
    try {
      ts = DateTime.parse(e.ts);
    } catch (_) {}
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _colorFor(e.action).withValues(alpha: 0.15),
        child: Icon(icon, color: _colorFor(e.action), size: 20),
      ),
      title: Text(e.detail),
      subtitle: Text('${e.actorName} · ${role.label}'
          '${e.studentCode != null ? " · SV ${e.studentCode}" : ""}'),
      trailing: Text(
        ts != null ? DateFormat('HH:mm dd/MM').format(ts) : '',
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      ),
    );
  }

  IconData _iconFor(String action) {
    if (action.contains('điểm')) return Icons.grade;
    if (action.contains('Duyệt')) return Icons.check_circle;
    if (action.contains('Từ chối')) return Icons.cancel;
    if (action.contains('Đăng ký') || action.contains('Hủy')) {
      return Icons.app_registration;
    }
    if (action.contains('học phần')) return Icons.menu_book;
    if (action.contains('kỳ đăng ký') || action.contains('kỳ')) {
      return Icons.event;
    }
    return Icons.history;
  }

  Color _colorFor(String action) {
    if (action.contains('Từ chối') || action.contains('Xóa')) {
      return AppColors.danger;
    }
    if (action.contains('Duyệt') || action.contains('Mở')) return AppColors.ok;
    if (action.contains('điểm')) return AppColors.accent;
    return AppColors.info;
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Màn quản trị: xem và tạo tài khoản cán bộ cấp dưới (BCN khoa / trợ lý QT / CVHT).
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<AppUser> _accounts = [];
  bool _loading = true;
  int _rev = -1;

  Future<void> _load() async {
    final repo = context.read<AppState>().repo;
    final data = await repo.facultyAccounts();
    if (!mounted) return;
    setState(() {
      _accounts = data;
      _loading = false;
    });
  }

  Future<void> _add() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _StaffDialog(),
    );
    if (saved == true && mounted) {
      await context.read<AppState>().bumpData();
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: color, content: Text(msg)));
  }

  Future<void> _toggleActive(AppUser u) async {
    final state = context.read<AppState>();
    final err = await state.repo.setProfileActive(u.id, !u.active, state.user!);
    if (!mounted) return;
    if (err != null) {
      _snack(err, AppColors.danger);
      return;
    }
    await state.bumpData();
  }

  Future<void> _delete(AppUser u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: Text('Xóa vĩnh viễn tài khoản “${u.fullName}” (${u.username})? '
            'Không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final state = context.read<AppState>();
    final err = await state.repo.deleteFacultyAccount(u, state.user!);
    if (!mounted) return;
    if (err != null) {
      _snack(err, AppColors.danger);
      return;
    }
    _snack('Đã xóa tài khoản ${u.username}.', AppColors.ok);
    await state.bumpData();
  }

  @override
  Widget build(BuildContext context) {
    final rev = context.watch<AppState>().dataRevision;
    if (rev != _rev) {
      _rev = rev;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Quản lý tài khoản',
          subtitle: '${_accounts.length} tài khoản cán bộ',
          trailing: ElevatedButton.icon(
            onPressed: _add,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Thêm tài khoản'),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _accounts.isEmpty
              ? const Center(child: Text('Chưa có tài khoản cán bộ nào.'))
              : Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    itemCount: _accounts.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _tile(_accounts[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _tile(AppUser u) {
    final me = context.read<AppState>().user;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: u.active ? AppColors.primary : AppColors.textMuted,
        child: Text(u.fullName.characters.last,
            style: const TextStyle(color: Colors.white)),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(u.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          if (!u.active) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('Đã khóa',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
      subtitle: Text([
        u.role.label,
        'Đăng nhập: ${u.username}',
        if ((u.phone ?? '').isNotEmpty) 'SĐT: ${u.phone}',
        if ((u.email ?? '').isNotEmpty) u.email!,
      ].join(' · ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(u.role.shortLabel,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          if (u.id != me?.id)
            PopupMenuButton<String>(
              tooltip: 'Thao tác',
              onSelected: (v) {
                if (v == 'toggle') {
                  _toggleActive(u);
                } else if (v == 'delete') {
                  _delete(u);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'toggle',
                    child:
                        Text(u.active ? 'Khóa đăng nhập' : 'Mở khóa')),
                const PopupMenuItem(
                    value: 'delete', child: Text('Xóa tài khoản')),
              ],
            ),
        ],
      ),
    );
  }
}

/// Dialog tạo tài khoản cán bộ mới.
class _StaffDialog extends StatefulWidget {
  const _StaffDialog();

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  final _username = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  UserRole _role = UserRole.dean;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final username = _username.text.trim();
    final name = _name.text.trim();
    if (username.isEmpty || name.isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên đăng nhập và họ tên.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final state = context.read<AppState>();
    final err = await state.repo.createStaff(
      username: username,
      fullName: name,
      role: _role,
      phone: _phone.text,
      email: _email.text,
      actor: state.user!,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.ok,
        content: Text('Đã tạo tài khoản $username (mật khẩu mặc định 123456).')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm tài khoản cán bộ'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Vai trò'),
                items: const [
                  DropdownMenuItem(
                      value: UserRole.dean, child: Text('Ban chủ nhiệm khoa')),
                  DropdownMenuItem(
                      value: UserRole.assistant, child: Text('Trợ lý quản trị')),
                  DropdownMenuItem(
                      value: UserRole.advisor, child: Text('Cố vấn học tập')),
                ],
                onChanged: (v) => setState(() => _role = v ?? UserRole.dean),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'Tên đăng nhập',
                  helperText: 'Đăng nhập bằng tên này · mật khẩu mặc định 123456',
                ),
              ),
              const SizedBox(height: 12),
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
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ],
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
              : const Text('Tạo tài khoản'),
        ),
      ],
    );
  }
}

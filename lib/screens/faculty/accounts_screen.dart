import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/revision_reload.dart';
import '../../widgets/user_avatar.dart';

/// Màn quản trị: xem và tạo tài khoản cán bộ cấp dưới (BCN khoa / trợ lý QT / CVHT).
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen>
    with RevisionReload {
  List<AppUser> _accounts = [];
  Map<String, String> _classAdvisors = {}; // lớp → id CVHT
  List<String> _classes = [];
  bool _loading = true;

  Future<void> _load() async {
    final repo = context.read<AppState>().repo;
    final data = await repo.facultyAccounts();
    final ca = await repo.classAdvisors();
    final classes = await repo.classNames();
    if (!mounted) return;
    setState(() {
      _accounts = data;
      _classAdvisors = ca;
      _classes = classes;
      _loading = false;
    });
  }

  List<String> _classesOf(AppUser u) => [
        for (final e in _classAdvisors.entries)
          if (e.value == u.id) e.key
      ]..sort();

  Future<void> _assignClasses(AppUser u) async {
    final names = {for (final a in _accounts) a.id: a.fullName};
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _ClassAssignDialog(
        advisor: u,
        classes: _classes,
        assigned: _classAdvisors,
        advisorNames: names,
      ),
    );
    if (result == null || !mounted) return;
    final state = context.read<AppState>();
    final err = await state.repo.setAdvisorClasses(u, result, state.user!);
    if (!mounted) return;
    if (err != null) {
      _snack(err, AppColors.danger);
      return;
    }
    _snack(
        result.isEmpty
            ? '${u.fullName} không còn phụ trách lớp nào.'
            : 'Đã phân lớp ${(result.toList()..sort()).join(', ')} cho ${u.fullName}.',
        AppColors.ok);
    await state.bumpData();
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
    watchRevision(_load);
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
      leading: UserAvatar(
        name: u.fullName,
        url: u.avatarUrl,
        color: u.active ? AppColors.primary : AppColors.textMuted,
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
        if (u.role == UserRole.advisor)
          _classesOf(u).isEmpty
              ? 'Chưa phân lớp'
              : 'Lớp: ${_classesOf(u).join(', ')}',
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
          if (u.role == UserRole.advisor) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => _assignClasses(u),
              icon: const Icon(Icons.class_outlined, size: 18),
              label: const Text('Phân lớp'),
            ),
          ],
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

/// Chọn các lớp CVHT phụ trách. Trả về tập lớp đã chọn, null khi hủy.
class _ClassAssignDialog extends StatefulWidget {
  const _ClassAssignDialog({
    required this.advisor,
    required this.classes,
    required this.assigned,
    required this.advisorNames,
  });

  final AppUser advisor;
  final List<String> classes;
  final Map<String, String> assigned; // lớp → id CVHT hiện tại
  final Map<String, String> advisorNames;

  @override
  State<_ClassAssignDialog> createState() => _ClassAssignDialogState();
}

class _ClassAssignDialogState extends State<_ClassAssignDialog> {
  late final Set<String> _selected = {
    for (final e in widget.assigned.entries)
      if (e.value == widget.advisor.id) e.key
  };
  late final List<String> _all = {
    ...widget.classes,
    ...widget.assigned.keys,
  }.toList()
    ..sort();
  final _newCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _newCtrl.dispose();
    super.dispose();
  }

  void _addNew() {
    final c = _newCtrl.text.trim();
    if (c.isEmpty) return;
    setState(() {
      if (!_all.contains(c)) _all..add(c)..sort();
      _selected.add(c);
      _newCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _filter.trim().toLowerCase();
    final shown = _all.where((c) => c.toLowerCase().contains(q)).toList();
    return AlertDialog(
      title: Text('Phân lớp cho ${widget.advisor.fullName}'),
      content: SizedBox(
        width: 480,
        height: 460,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tích các lớp CVHT phụ trách. Mọi sinh viên của lớp (kể cả sinh '
              'viên thêm sau) tự được gán CVHT này; CVHT chỉ xem được sinh '
              'viên các lớp mình phụ trách.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm lớp',
              ),
              onChanged: (v) => setState(() => _filter = v),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: shown.isEmpty
                  ? const Center(child: Text('Chưa có lớp nào.'))
                  : ListView(
                      children: [
                        for (final c in shown) _classTile(c),
                      ],
                    ),
            ),
            const Divider(),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _newCtrl,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'Lớp mới (chưa có sinh viên)',
                  ),
                  onSubmitted: (_) => _addNew(),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _addNew,
                icon: const Icon(Icons.add),
                label: const Text('Thêm'),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: Text('Lưu (${_selected.length} lớp)'),
        ),
      ],
    );
  }

  Widget _classTile(String c) {
    final owner = widget.assigned[c];
    final other = owner != null && owner != widget.advisor.id;
    final checked = _selected.contains(c);
    return CheckboxListTile(
      dense: true,
      value: checked,
      title: Text(c),
      subtitle: other
          ? Text(
              checked
                  ? 'Sẽ chuyển từ ${widget.advisorNames[owner] ?? 'CVHT khác'}'
                  : 'Đang thuộc ${widget.advisorNames[owner] ?? 'CVHT khác'}',
              style: TextStyle(
                  fontSize: 12,
                  color: checked ? AppColors.warn : AppColors.textMuted))
          : null,
      onChanged: (v) => setState(() {
        if (v == true) {
          _selected.add(c);
        } else {
          _selected.remove(c);
        }
      }),
    );
  }
}

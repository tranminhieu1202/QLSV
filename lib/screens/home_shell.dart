import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/my_profile_dialog.dart';
import 'activity_screen.dart';
import 'faculty/accounts_screen.dart';
import 'faculty/curriculum_screen.dart';
import 'faculty/dashboard_screen.dart';
import 'faculty/registration_screen.dart';
import 'faculty/students_screen.dart';
import 'faculty/warnings_screen.dart';
import 'student/student_portal_screen.dart';
import 'student/student_registration_screen.dart';

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;
  const _NavItem(this.icon, this.selectedIcon, this.label, this.page);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  List<_NavItem> _itemsFor(AppUser user) {
    final role = user.role;
    if (role.isFaculty) {
      return [
        const _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Tổng quan',
            DashboardScreen()),
        const _NavItem(
            Icons.groups_outlined, Icons.groups, 'Sinh viên', StudentsScreen()),
        const _NavItem(Icons.warning_amber_outlined, Icons.warning_amber,
            'Cảnh báo', WarningsScreen()),
        const _NavItem(Icons.menu_book_outlined, Icons.menu_book, 'CT đào tạo',
            CurriculumScreen()),
        if (role.canManageRegistrationPeriod)
          const _NavItem(Icons.app_registration_outlined,
              Icons.app_registration, 'Kỳ đăng ký & duyệt', RegistrationScreen()),
        if (role.isAdmin)
          const _NavItem(Icons.manage_accounts_outlined,
              Icons.manage_accounts, 'Tài khoản', AccountsScreen()),
        const _NavItem(
            Icons.history_outlined, Icons.history, 'Hoạt động', ActivityScreen()),
      ];
    }
    // student
    final code = user.studentCode!;
    return [
      _NavItem(Icons.home_outlined, Icons.home, 'Trang chủ',
          StudentPortalScreen(studentCode: code)),
      _NavItem(Icons.app_registration_outlined, Icons.app_registration,
          'Đăng ký học phần', StudentRegistrationScreen(studentCode: code)),
      const _NavItem(Icons.menu_book_outlined, Icons.menu_book, 'CT đào tạo',
          CurriculumScreen()),
      const _NavItem(
          Icons.history_outlined, Icons.history, 'Hoạt động', ActivityScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user!;
    final items = _itemsFor(user);
    if (_index >= items.length) _index = 0;

    return Scaffold(
      body: Row(
        children: [
          _SideRail(
            user: user,
            items: items,
            index: _index,
            onSelect: (i) => setState(() => _index = i),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(user: user, title: items[_index].label),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: items[_index].page,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideRail extends StatelessWidget {
  const _SideRail({
    required this.user,
    required this.items,
    required this.index,
    required this.onSelect,
  });

  final AppUser user;
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 244,
      color: AppColors.primaryDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Row(
              children: const [
                Icon(Icons.school, color: AppColors.accent, size: 30),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('QLGD EDU',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      Text('Quản lý đào tạo',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          for (var i = 0; i < items.length; i++) _railItem(i, items[i]),
          const Spacer(),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                Text(user.role.label,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _railItem(int i, _NavItem d) {
    final selected = i == index;
    return Material(
      color:
          selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: selected ? AppColors.accent : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(selected ? d.selectedIcon : d.icon,
                  color: selected ? AppColors.accent : Colors.white70, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(d.label,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.user, required this.title});
  final AppUser user;
  final String title;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (state.regOpen ? AppColors.ok : AppColors.textMuted)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Kỳ ${state.currentTerm} · ${state.regOpen ? "Mở ĐK" : "Đóng ĐK"}',
              style: TextStyle(
                  color: state.regOpen ? AppColors.ok : AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Đồng bộ dữ liệu',
            onPressed: () => state.bumpData(),
            icon: const Icon(Icons.sync, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'logout') {
                await state.logout();
              } else if (v == 'profile') {
                await showDialog<bool>(
                  context: context,
                  builder: (_) => const MyProfileDialog(),
                );
              } else if (v == 'password') {
                await showDialog<bool>(
                  context: context,
                  builder: (_) => const ChangePasswordDialog(),
                );
              }
            },
            itemBuilder: (_) => [
              if (user.role.isFaculty)
                const PopupMenuItem(
                    value: 'profile', child: Text('Thông tin cá nhân')),
              const PopupMenuItem(
                  value: 'password', child: Text('Đổi mật khẩu')),
              const PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(user.fullName.characters.last,
                      style: const TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(user.role.label,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

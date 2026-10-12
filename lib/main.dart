import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/supabase_config.dart';
import 'data/update_service.dart';
import 'providers/app_state.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(Supabase.instance.client)..restoreSession(),
      child: const QlgdApp(),
    ),
  );
}

class QlgdApp extends StatefulWidget {
  const QlgdApp({super.key});

  @override
  State<QlgdApp> createState() => _QlgdAppState();
}

class _QlgdAppState extends State<QlgdApp> {
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    if (UpdateService.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
    }
  }

  Future<void> _checkUpdate() async {
    final info = await UpdateService().check();
    final ctx = _navKey.currentContext;
    if (info != null && ctx != null && ctx.mounted) {
      showDialog(context: ctx, builder: (_) => UpdateDialog(info: info));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'Hệ thống Quản lý Đào tạo – Khoa QLGD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Consumer<AppState>(
        builder: (context, state, _) => state.restoring
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : state.isLoggedIn
                ? const HomeShell()
                : const LoginScreen(),
      ),
    );
  }
}

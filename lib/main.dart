import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data/supabase_config.dart';
import 'providers/app_state.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(Supabase.instance.client),
      child: const QlgdApp(),
    ),
  );
}

class QlgdApp extends StatelessWidget {
  const QlgdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hệ thống Quản lý Đào tạo – Khoa QLGD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Consumer<AppState>(
        builder: (context, state, _) =>
            state.isLoggedIn ? const HomeShell() : const LoginScreen(),
      ),
    );
  }
}

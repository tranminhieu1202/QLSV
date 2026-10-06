import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

/// Tải (lại) dữ liệu của màn hình mỗi khi [AppState.dataRevision] thay đổi,
/// kể cả lần hiển thị đầu tiên – nên màn hình không cần tự gọi tải trong
/// `initState`.
mixin RevisionReload<T extends StatefulWidget> on State<T> {
  int? _loadedRev;

  /// Gọi ở đầu `build`; lên lịch [load] khi revision khác lần tải trước.
  void watchRevision(Future<void> Function() load) {
    final rev = context.watch<AppState>().dataRevision;
    if (rev == _loadedRev) return;
    _loadedRev = rev;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) load();
    });
  }
}

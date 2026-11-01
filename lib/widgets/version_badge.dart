import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Nhãn phiên bản ở góc dưới bên phải mọi màn hình (vd "Phiên bản 1.1.9"),
/// để người dùng biết mình đang chạy bản nào khi báo lỗi hay cập nhật.
class VersionBadge extends StatefulWidget {
  const VersionBadge({super.key});

  @override
  State<VersionBadge> createState() => _VersionBadgeState();
}

class _VersionBadgeState extends State<VersionBadge> {
  static Future<String>? _version;

  @override
  void initState() {
    super.initState();
    _version ??= PackageInfo.fromPlatform()
        .then((p) => p.version)
        .catchError((Object _) => '');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _version,
      builder: (context, snap) {
        final v = snap.data ?? '';
        if (v.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Phiên bản $v',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              decoration: TextDecoration.none,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}

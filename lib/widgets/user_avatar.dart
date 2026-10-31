import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Ảnh đại diện tròn; chưa có ảnh (hoặc ảnh lỗi) thì hiện chữ cái cuối của tên.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.url,
    this.radius = 20,
    this.color = AppColors.primary,
  });

  final String name;
  final String? url;
  final double radius;
  final Color color;

  /// Chữ cái đầu của tên (từ cuối) – bỏ phần trong ngoặc và ký tự không phải
  /// chữ: "TS. Nguyễn Quốc Toàn (Quản trị)" → "T".
  static String initialOf(String name) {
    final words = name
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => RegExp(r'\p{L}', unicode: true).hasMatch(w))
        .toList();
    if (words.isEmpty) return '?';
    final letter = RegExp(r'\p{L}', unicode: true).firstMatch(words.last)!;
    return letter.group(0)!.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initial = Text(
      initialOf(name),
      style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w600),
    );
    final hasUrl = url != null && url!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: hasUrl
          ? ClipOval(
              child: Image.network(
                url!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => initial,
              ),
            )
          : initial,
    );
  }
}

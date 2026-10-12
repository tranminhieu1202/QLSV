import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
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

/// Khối đổi ảnh đại diện của tài khoản đang đăng nhập: chọn ảnh từ máy, cắt
/// vuông, thu nhỏ còn 256×256 rồi tải lên ngay.
class AvatarEditor extends StatefulWidget {
  const AvatarEditor({super.key});

  @override
  State<AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends State<AvatarEditor> {
  static const _maxInputBytes = 10 * 1024 * 1024;
  static const _size = 256;
  bool _busy = false;
  String? _error;

  Future<void> _pick() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Ảnh',
        extensions: ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'gif'],
        uniformTypeIdentifiers: ['public.image'],
      ),
    ]);
    if (file == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxInputBytes) {
        throw const FormatException('Ảnh quá lớn (tối đa 10 MB).');
      }
      await _save(await _squarePng(bytes));
    } on FormatException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail('Không đọc được tệp ảnh này.');
    }
  }

  Future<void> _save(Uint8List? png) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await context.read<AppState>().setMyAvatar(png);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
  }

  void _fail(String msg) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = msg;
    });
  }

  /// Cắt phần vuông ở giữa ảnh và thu về [_size]×[_size] PNG.
  static Future<Uint8List> _squarePng(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final src = (await codec.getNextFrame()).image;
    final side = src.width < src.height ? src.width : src.height;
    final rect = Rect.fromLTWH(
      (src.width - side) / 2,
      (src.height - side) / 2,
      side.toDouble(),
      side.toDouble(),
    );
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      src,
      rect,
      const Rect.fromLTWH(0, 0, _size * 1.0, _size * 1.0),
      Paint()..filterQuality = FilterQuality.high,
    );
    final out = await recorder.endRecording().toImage(_size, _size);
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    src.dispose();
    out.dispose();
    if (data == null) throw const FormatException('Không xử lý được ảnh.');
    return data.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null) return const SizedBox.shrink();
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
    return Row(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            UserAvatar(name: user.fullName, url: user.avatarUrl, radius: 36),
            if (_busy)
              const SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(strokeWidth: 3)),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pick,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(hasAvatar ? 'Đổi ảnh' : 'Tải ảnh lên'),
                  ),
                  if (hasAvatar)
                    TextButton(
                      onPressed: _busy ? null : () => _save(null),
                      child: const Text('Xóa ảnh'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _error ?? 'PNG/JPG, ảnh được cắt vuông và lưu ngay.',
                style: TextStyle(
                    fontSize: 12,
                    color: _error != null
                        ? AppColors.danger
                        : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

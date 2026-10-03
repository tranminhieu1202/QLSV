import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/update_service.dart';
import '../theme/app_theme.dart';

/// Hộp thoại báo có bản mới: tải & cài installer, hoặc mở trang Releases.
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.info});
  final UpdateInfo info;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final _svc = UpdateService();
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _install() async {
    setState(() {
      _downloading = true;
      _error = null;
    });
    try {
      await _svc.downloadAndRun(widget.info,
          onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      // downloadAndRun gọi exit(0) nên thường không tới đây.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _error = 'Tải thất bại: $e';
      });
    }
  }

  Future<void> _openPage() async {
    await launchUrl(Uri.parse(widget.info.pageUrl),
        mode: LaunchMode.externalApplication);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canInstall = Platform.isWindows && widget.info.installerUrl != null;
    return AlertDialog(
      title: Text('Có bản cập nhật ${widget.info.version}'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Phiên bản mới đã sẵn sàng. Nên cập nhật để nhận tính '
                'năng và sửa lỗi mới nhất.'),
            if (widget.info.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Thay đổi:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.tableHeader,
                    borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(
                    child: Text(widget.info.notes,
                        style: const TextStyle(fontSize: 13))),
              ),
            ],
            if (_downloading) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _progress == 0 ? null : _progress),
              const SizedBox(height: 4),
              Text('Đang tải ${(_progress * 100).toStringAsFixed(0)}%...',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _downloading ? null : () => Navigator.pop(context),
          child: const Text('Để sau'),
        ),
        TextButton(
          onPressed: _downloading ? null : _openPage,
          child: const Text('Mở trang'),
        ),
        if (canInstall)
          ElevatedButton(
            onPressed: _downloading ? null : _install,
            child: const Text('Tải & cài'),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/report_export.dart';
import '../data/report_service.dart';
import '../theme/app_theme.dart';

/// Xuất [data] ra file theo định dạng [format], báo kết quả bằng SnackBar
/// (kèm nút mở file vừa lưu).
Future<void> runExport(
    BuildContext context, ReportData data, ExportFormat format) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final path = await ReportExporter.export(data, format);
    if (path == null) return; // người dùng hủy
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Text('Đã xuất ${data.rows.length} sinh viên ra $path'),
      action: SnackBarAction(
        label: 'Mở file',
        onPressed: () => launchUrl(Uri.file(path)),
      ),
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(
      backgroundColor: AppColors.danger,
      content: Text('Xuất ${format.label} thất bại: $e'),
    ));
  }
}

/// Nút "Xuất" mở menu chọn Excel / PDF. [report] tạo nội dung báo cáo tại thời
/// điểm bấm để luôn khớp với bộ lọc hiện tại.
class ExportMenuButton extends StatelessWidget {
  const ExportMenuButton({super.key, required this.report, this.enabled = true});

  final ReportData Function() report;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ExportFormat>(
      enabled: enabled,
      tooltip: 'Xuất danh sách đang hiển thị',
      onSelected: (f) => runExport(context, report(), f),
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: ExportFormat.excel,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.table_chart_outlined, color: AppColors.ok),
            title: Text('Xuất Excel (.xlsx)'),
          ),
        ),
        PopupMenuItem(
          value: ExportFormat.pdf,
          child: ListTile(
            dense: true,
            leading:
                Icon(Icons.picture_as_pdf_outlined, color: AppColors.danger),
            title: Text('Xuất PDF'),
          ),
        ),
      ],
      child: IgnorePointer(
        child: OutlinedButton.icon(
          onPressed: enabled ? () {} : null,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Xuất'),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/academic.dart';
import '../models/enrollment.dart';
import '../theme/app_theme.dart';

Color warnColor(WarnLevel level) {
  switch (level) {
    case WarnLevel.none:
      return AppColors.ok;
    case WarnLevel.info:
      return AppColors.info;
    case WarnLevel.low:
      return AppColors.warn;
    case WarnLevel.medium:
      return const Color(0xFFEF6C00);
    case WarnLevel.high:
      return AppColors.danger;
  }
}

/// Small colored chip used for warning levels / statuses.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, this.text});
  final WarnLevel level;
  final String? text;

  @override
  Widget build(BuildContext context) {
    final c = warnColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(
        text ?? level.label,
        style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

/// Reusable stat card for dashboards.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: c),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                  if (subtitle case final s?)
                    Text(s, style: TextStyle(color: c, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header block used at the top of content pages.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: const TextStyle(color: AppColors.textMuted)),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Nhãn trạng thái học phần (Đạt / Trượt / Đang học).
class EnrollStatusChip extends StatelessWidget {
  const EnrollStatusChip(this.status, {super.key});
  final EnrollStatus status;

  @override
  Widget build(BuildContext context) {
    final c = switch (status) {
      EnrollStatus.passed => AppColors.ok,
      EnrollStatus.failed => AppColors.danger,
      EnrollStatus.studying => AppColors.info,
      EnrollStatus.registered => AppColors.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12)),
      child: Text(status.label,
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

/// Giữ bảng rộng ít nhất [minWidth]; khi cửa sổ hẹp hơn (vd MacBook) thì cuộn
/// ngang thay vì ép các cột co đến mức tràn. Cần chiều cao bị chặn.
class HorizontalOverflow extends StatefulWidget {
  const HorizontalOverflow(
      {super.key, required this.minWidth, required this.child});
  final double minWidth;
  final Widget child;

  @override
  State<HorizontalOverflow> createState() => _HorizontalOverflowState();
}

class _HorizontalOverflowState extends State<HorizontalOverflow> {
  final _ctrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth >= widget.minWidth) return widget.child;
      return Scrollbar(
        controller: _ctrl,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _ctrl,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: widget.minWidth,
            height: box.maxHeight,
            child: widget.child,
          ),
        ),
      );
    });
  }
}

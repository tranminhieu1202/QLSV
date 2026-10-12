import 'package:flutter/material.dart';

import '../data/report_service.dart';
import '../theme/app_theme.dart';

/// Ô tiêu đề cột kiểu Excel: bấm tên cột để sắp xếp (bấm lại để đảo chiều),
/// nút ▾ mở menu sắp xếp A→Z / Z→A và (nếu có) lọc theo giá trị của cột.
class SortFilterHeader extends StatelessWidget {
  const SortFilterHeader({
    super.key,
    required this.label,
    this.column,
    this.order,
    this.onSort,
    this.filterValues,
    this.filterSelected = const {},
    this.onFilter,
  });

  final String label;

  /// Cột dùng để sắp xếp; null = cột không sắp xếp được.
  final ReportColumn? column;
  final ReportOrder? order;
  final ValueChanged<ReportOrder>? onSort;

  /// Các giá trị để lọc (vd danh sách lớp); null = cột không có bộ lọc.
  final List<String>? filterValues;

  /// Giá trị đang chọn; rỗng = không lọc (hiện tất cả).
  final Set<String> filterSelected;
  final ValueChanged<Set<String>>? onFilter;

  bool get _sorted => column != null && order?.column == column;
  bool get _filtered => filterSelected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final col = column;
    const style = TextStyle(fontWeight: FontWeight.w600);
    if (col == null || onSort == null) {
      return Text(label, style: style, overflow: TextOverflow.ellipsis);
    }
    // Ô quá hẹp không chứa nổi mũi tên + nút ▾: chỉ hiện tên, không tràn.
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth < 48) {
        return Text(label, style: style, overflow: TextOverflow.ellipsis);
      }
      return _full(context, col, style);
    });
  }

  Widget _full(BuildContext context, ReportColumn col, TextStyle style) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: InkWell(
            onTap: () => onSort!(_sorted
                ? order!.reversed
                : ReportOrder(col, ascending: true)),
            child: Text(label,
                style: style.copyWith(
                    color: _sorted ? AppColors.primary : null),
                overflow: TextOverflow.ellipsis,
                maxLines: 1),
          ),
        ),
        if (_sorted)
          Icon(order!.ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14, color: AppColors.primary),
        SizedBox(width: 20, height: 20, child: _menu(context, col)),
      ],
    );
  }

  Widget _menu(BuildContext context, ReportColumn col) {
    // Nút ▾ mặc định chiếm 40–48px, ở cột hẹp sẽ đè mất tên cột.
    return SizedBox(
      width: 22,
      height: 24,
      child: _menuButton(context, col),
    );
  }

  Widget _menuButton(BuildContext context, ReportColumn col) {
    return PopupMenuButton<String>(
      tooltip: 'Sắp xếp / lọc theo $label',
      padding: EdgeInsets.zero,
      iconSize: 16,
      icon: Icon(
        _filtered ? Icons.filter_alt : Icons.arrow_drop_down,
        size: 16,
        color: _filtered ? AppColors.primary : AppColors.textMuted,
      ),
      onSelected: (v) async {
        switch (v) {
          case 'asc':
            onSort!(ReportOrder(col, ascending: true));
          case 'desc':
            onSort!(ReportOrder(col, ascending: false));
          case 'filter':
            final picked = await showDialog<Set<String>>(
              context: context,
              builder: (_) => _ValueFilterDialog(
                title: label,
                values: filterValues!,
                selected: filterSelected,
              ),
            );
            if (picked != null) onFilter!(picked);
          case 'clear':
            onFilter!(const {});
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'asc',
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.arrow_upward, size: 18),
            title: Text('Sắp xếp ${col.ascLabel}'),
          ),
        ),
        PopupMenuItem(
          value: 'desc',
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.arrow_downward, size: 18),
            title: Text('Sắp xếp ${col.descLabel}'),
          ),
        ),
        if (filterValues != null && onFilter != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'filter',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.filter_alt_outlined, size: 18),
              title: Text('Lọc giá trị…'),
            ),
          ),
          if (_filtered)
            PopupMenuItem(
              value: 'clear',
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.filter_alt_off_outlined, size: 18),
                title: Text('Bỏ lọc "$label"'),
              ),
            ),
        ],
      ],
    );
  }
}

/// Hộp chọn giá trị để lọc (giống bộ lọc cột của Excel).
class _ValueFilterDialog extends StatefulWidget {
  const _ValueFilterDialog({
    required this.title,
    required this.values,
    required this.selected,
  });

  final String title;
  final List<String> values;
  final Set<String> selected;

  @override
  State<_ValueFilterDialog> createState() => _ValueFilterDialogState();
}

class _ValueFilterDialogState extends State<_ValueFilterDialog> {
  late final Set<String> _checked =
      widget.selected.isEmpty ? {...widget.values} : {...widget.selected};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = [
      for (final v in widget.values)
        if (q.isEmpty || v.toLowerCase().contains(q)) v,
    ];
    final allChecked = shown.every(_checked.contains);
    return AlertDialog(
      title: Text('Lọc theo ${widget.title}'),
      content: SizedBox(
        width: 320,
        height: 380,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            CheckboxListTile(
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('(Chọn tất cả)',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              value: allChecked,
              onChanged: (on) => setState(() => on == true
                  ? _checked.addAll(shown)
                  : _checked.removeAll(shown)),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  for (final v in shown)
                    CheckboxListTile(
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(v.isEmpty ? '(Trống)' : v),
                      value: _checked.contains(v),
                      onChanged: (on) => setState(() =>
                          on == true ? _checked.add(v) : _checked.remove(v)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _checked.isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    // Chọn tất cả = không lọc.
                    _checked.length == widget.values.length
                        ? <String>{}
                        : _checked,
                  ),
          child: const Text('Đồng ý'),
        ),
      ],
    );
  }
}
